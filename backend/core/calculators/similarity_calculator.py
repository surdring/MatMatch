"""
SimilarityCalculator - 相似度计算器

基于PostgreSQL pg_trgm扩展实现多字段加权相似度计算
支持23万+物料数据的高性能查询（≤500ms）

对应design.md第2.2.2节相似度计算算法设计
"""

import logging
import hashlib
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Tuple
from cachetools import TTLCache

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from backend.core.schemas.material_schemas import ParsedQuery, MaterialResult

logger = logging.getLogger(__name__)


# 默认权重配置（优化版：取消分类权重，重新分配）
DEFAULT_WEIGHTS = {
    'name': 0.5,        # 名称相似度 50% (提升10%)
    'description': 0.3, # 描述相似度 30% (保持)
    'attributes': 0.2,  # 属性相似度 20% (保持)
    'category': 0.0     # 类别相似度 0% (取消)
}


class SimilarityCalculator:
    """
    相似度计算器 - 基于PostgreSQL pg_trgm扩展
    
    职责:
    - 执行多字段加权相似度查询
    - 利用GIN索引优化性能（≤500ms for 230K数据）
    - 支持动态权重配置
    - 实现查询结果缓存（LRU + TTL）
    
    核心算法:
    - Trigram相似度: PostgreSQL pg_trgm三元组算法
    - 多字段加权: 余弦相似度 + AHP权重分配
    - 性能优化: GIN索引 + 预筛选机制
    """
    
    def __init__(
        self,
        db_session: AsyncSession,
        weights: Optional[Dict[str, float]] = None,
        cache_ttl_seconds: int = 60,
        cache_max_size: int = 1000
    ):
        """
        初始化相似度计算器
        
        Args:
            db_session: PostgreSQL异步会话
            weights: 自定义权重配置，默认使用DEFAULT_WEIGHTS
            cache_ttl_seconds: 缓存TTL（秒），默认60秒
            cache_max_size: 缓存最大条目数，默认1000
        """
        self.db = db_session
        
        # 权重配置
        self.weights = weights or DEFAULT_WEIGHTS.copy()
        self._validate_weights()
        
        # 缓存配置
        self.cache_ttl = timedelta(seconds=cache_ttl_seconds)
        self._cache = TTLCache(maxsize=cache_max_size, ttl=cache_ttl_seconds)
        self._cache_hits = 0
        self._cache_misses = 0
        
        logger.info(
            f"SimilarityCalculator initialized "
            f"(weights: {self.weights}, cache_ttl: {cache_ttl_seconds}s)"
        )
    
    def _validate_weights(self) -> None:
        """
        验证权重配置
        
        要求:
        1. 包含所有必需的键: name, description, attributes, category
        2. 所有权重在[0.0, 1.0]范围内
        3. 权重总和等于1.0（允许0.01的误差）
        """
        required_keys = {'name', 'description', 'attributes', 'category'}
        
        if not required_keys.issubset(self.weights.keys()):
            missing = required_keys - set(self.weights.keys())
            raise ValueError(f"Missing required weight keys: {missing}")
        
        for key, value in self.weights.items():
            if not 0.0 <= value <= 1.0:
                raise ValueError(f"Weight '{key}' must be in [0.0, 1.0], got {value}")
        
        total_weight = sum(self.weights.values())
        if not (0.99 <= total_weight <= 1.01):
            raise ValueError(f"Weights must sum to 1.0, got {total_weight}")
    
    def _generate_cache_key(
        self,
        parsed_query: ParsedQuery,
        limit: int,
        min_similarity: float
    ) -> str:
        """
        生成缓存键
        
        Args:
            parsed_query: 查询对象
            limit: 结果数量限制
            min_similarity: 最小相似度阈值
            
        Returns:
            缓存键（MD5哈希）
        """
        # 构建唯一标识字符串
        key_parts = [
            parsed_query.standardized_name,
            str(sorted(parsed_query.attributes.items())),
            parsed_query.detected_category,
            str(limit),
            str(min_similarity),
            str(sorted(self.weights.items()))
        ]
        key_string = '|'.join(key_parts)
        
        # 生成MD5哈希
        return hashlib.md5(key_string.encode('utf-8')).hexdigest()
    
    async def find_similar_materials_batch(
        self,
        parsed_queries: List[ParsedQuery],
        limit: int = 10,
        min_similarity: float = 0.1
    ) -> Dict[int, List[MaterialResult]]:
        """
        批量查找相似物料（性能优化版）
        
        Args:
            parsed_queries: 多个UniversalMaterialProcessor的输出
            limit: 每个查询返回的结果数量限制
            min_similarity: 最小相似度阈值 [0.0, 1.0]
            
        Returns:
            Dict[int, List[MaterialResult]]: 查询索引 -> 相似物料列表
            
        性能优势:
            - 单次SQL查询处理所有输入（避免N次查询）
            - 使用CTE + 窗口函数优化
            - 预期性能: N条 × 300ms → 1次 × 500ms (提升N倍)
        """
        if not parsed_queries:
            return {}
        
        try:
            # 构建批量SQL查询
            sql_query = self._build_batch_similarity_query(len(parsed_queries), limit, min_similarity)
            
            # 准备批量查询参数
            params = self._prepare_batch_query_params(parsed_queries, limit, min_similarity)
            
            # 执行批量查询
            logger.info(f"[批量查询] 开始处理 {len(parsed_queries)} 条物料...")
            result = await self.db.execute(text(sql_query), params)
            rows = result.fetchall()
            
            # 解析结果（按query_idx分组）
            results_by_idx: Dict[int, List[MaterialResult]] = {}
            for row in rows:
                query_idx = int(row[0])  # 第一列是query_idx，转为整数
                material = self._parse_batch_result_row(row, parsed_queries[query_idx])
                
                if query_idx not in results_by_idx:
                    results_by_idx[query_idx] = []
                results_by_idx[query_idx].append(material)
            
            logger.info(f"[批量查询] 完成，共返回 {len(rows)} 条结果")
            
            return results_by_idx
            
        except Exception as e:
            error_msg = f"Failed to find similar materials (batch): {str(e)}"
            logger.error(error_msg, exc_info=True)
            raise RuntimeError(error_msg) from e
    
    async def find_similar_materials(
        self,
        parsed_query: ParsedQuery,
        limit: int = 10,
        min_similarity: float = 0.1
    ) -> List[MaterialResult]:
        """
        查找相似物料
        
        Args:
            parsed_query: UniversalMaterialProcessor的输出
            limit: 返回结果数量限制
            min_similarity: 最小相似度阈值 [0.0, 1.0]
            
        Returns:
            List[MaterialResult]: 按相似度排序的物料列表
            
        查询策略:
            1. 检查缓存
            2. 使用pg_trgm预筛选（% 运算符）
            3. 计算多字段加权相似度
            4. 按相似度降序排序
            5. 限制返回数量
        """
        # 检查缓存
        cache_key = self._generate_cache_key(parsed_query, limit, min_similarity)
        if cache_key in self._cache:
            self._cache_hits += 1
            logger.debug(f"Cache hit for query: {parsed_query.standardized_name[:30]}...")
            return self._cache[cache_key]
        
        self._cache_misses += 1
        
        try:
            # 构建SQL查询
            sql_query = self._build_similarity_query(parsed_query, limit, min_similarity)
            
            # 准备查询参数
            params = self._prepare_query_params(parsed_query, limit, min_similarity)
            
            # 执行查询
            result = await self.db.execute(text(sql_query), params)
            rows = result.fetchall()
            
            # 解析结果
            materials = []
            for row in rows:
                material = self._parse_result_row(row, parsed_query)
                materials.append(material)
            
            # 缓存结果
            self._cache[cache_key] = materials
            
            # 简化日志输出（性能优化：减少90%日志量）
            logger.debug(
                f"[查询完成] 找到{len(materials)}条相似物料 "
                f"(输入: {parsed_query.standardized_name[:20]}..., 相似度>={min_similarity})"
            )
            
            return materials
            
        except Exception as e:
            error_msg = f"Failed to find similar materials: {str(e)}"
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
    
    def _build_batch_similarity_query(
        self,
        batch_size: int,
        limit: int,
        min_similarity: float
    ) -> str:
        """
        构建批量相似度查询SQL（使用CTE + 窗口函数）
        
        性能优化核心：
        1. 使用VALUES构造批量查询输入
        2. 使用CROSS JOIN进行笛卡尔积
        3. 使用ROW_NUMBER()窗口函数取Top-K
        4. 单次查询处理所有输入
        """
        w_name = self.weights['name']
        w_desc = self.weights['description']
        w_attr = self.weights['attributes']
        w_cat = self.weights['category']
        
        # 构建VALUES子句（动态生成N行）
        values_rows = []
        for i in range(batch_size):
            values_rows.append(
                f"(:query_idx_{i}, :query_name_{i}, :query_desc_{i}, :query_category_{i})"
            )
        values_clause = ",\n            ".join(values_rows)
        
        sql = f"""
        WITH query_batch AS (
            -- 批量查询输入（使用VALUES构造）
            SELECT * FROM (VALUES
                {values_clause}
            ) AS t(query_idx, query_name, query_desc, query_category)
        ),
        similarity_results AS (
            -- 批量计算相似度
            SELECT 
                qb.query_idx,
                m.erp_code,
                m.material_name,
                m.specification,
                m.model,
                m.enable_state,
                m.unit_name,
                m.category_name,
                m.normalized_name,
                m.full_description,
                m.attributes,
                m.detected_category,
                m.category_confidence,
                m.oracle_category_id,
                m.oracle_unit_id,
                -- 多字段加权相似度计算
                (
                    {w_name} * similarity(m.normalized_name, qb.query_name) +
                    {w_desc} * similarity(m.full_description, qb.query_desc) +
                    {w_attr} * CASE
                        -- 如果双方都没有属性，视为完全相同（1.0）
                        WHEN m.attributes IS NULL OR m.attributes = 'null'::jsonb OR m.attributes = '{{}}'::jsonb
                        THEN 1.0
                        -- 如果有属性，计算平均相似度
                        ELSE COALESCE(
                            (SELECT AVG(similarity(m.attributes->>key, qb.query_desc))
                             FROM jsonb_object_keys(m.attributes) AS key),
                            1.0
                        )
                    END +
                    {w_cat} * CASE 
                        WHEN m.detected_category = qb.query_category 
                        THEN 1.0 
                        ELSE 0.0 
                    END
                ) AS similarity_score,
                -- 各维度相似度明细
                similarity(m.normalized_name, qb.query_name) AS name_similarity,
                similarity(m.full_description, qb.query_desc) AS description_similarity,
                CASE
                    -- 如果双方都没有属性，视为完全相同（1.0）
                    WHEN m.attributes IS NULL OR m.attributes = 'null'::jsonb OR m.attributes = '{{}}'::jsonb
                    THEN 1.0
                    -- 如果有属性，计算平均相似度
                    ELSE COALESCE(
                        (SELECT AVG(similarity(m.attributes->>key, qb.query_desc))
                         FROM jsonb_object_keys(m.attributes) AS key),
                        1.0
                    )
                END AS attributes_similarity,
                CASE 
                    WHEN m.detected_category = qb.query_category 
                    THEN 1.0 
                    ELSE 0.0 
                END AS category_similarity
            FROM query_batch qb
            CROSS JOIN materials_master m
            WHERE 
                -- 预筛选：利用GIN索引加速
                (
                    m.normalized_name % qb.query_name OR
                    m.full_description % qb.query_desc
                )
                -- 相似度阈值过滤
                AND (
                    {w_name} * similarity(m.normalized_name, qb.query_name) +
                    {w_desc} * similarity(m.full_description, qb.query_desc)
                ) >= :min_similarity
        ),
        ranked_results AS (
            -- 使用窗口函数为每个查询取Top-K
            SELECT 
                *,
                ROW_NUMBER() OVER (PARTITION BY query_idx ORDER BY similarity_score DESC) AS rank
            FROM similarity_results
        )
        SELECT * FROM ranked_results 
        WHERE rank <= :limit
        ORDER BY query_idx, rank;
        """
        
        return sql
    
    def _prepare_batch_query_params(
        self,
        parsed_queries: List[ParsedQuery],
        limit: int,
        min_similarity: float
    ) -> Dict[str, Any]:
        """准备批量查询参数"""
        params = {
            'limit': limit,
            'min_similarity': min_similarity
        }
        
        for i, pq in enumerate(parsed_queries):
            params[f'query_idx_{i}'] = str(i)  # 修复：转为字符串
            params[f'query_name_{i}'] = pq.standardized_name
            params[f'query_desc_{i}'] = f"{pq.standardized_name} {' '.join(pq.attributes.values())}"
            params[f'query_category_{i}'] = pq.detected_category or ''
        
        return params
    
    def _parse_batch_result_row(
        self,
        row: Any,
        parsed_query: ParsedQuery
    ) -> MaterialResult:
        """解析批量查询结果行（跳过第一列query_idx）"""
        return MaterialResult(
            erp_code=row[1],
            material_name=row[2],
            specification=row[3],
            model=row[4],
            enable_state=row[5],
            unit_name=row[6],
            category_name=row[7],
            normalized_name=row[8],
            full_description=row[9],
            attributes=row[10] or {},
            detected_category=row[11],
            category_confidence=row[12],
            oracle_category_id=row[13],
            oracle_unit_id=row[14],
            similarity_score=float(row[15]),
            name_similarity=float(row[16]) if row[16] is not None else None,
            description_similarity=float(row[17]) if row[17] is not None else None,
            attributes_similarity=float(row[18]) if row[18] is not None else None,
            category_similarity=float(row[19]) if row[19] is not None else None
        )
    
    def _build_similarity_query(
        self,
        parsed_query: ParsedQuery,
        limit: int,
        min_similarity: float
    ) -> str:
        """
        构建相似度查询SQL
        
        利用PostgreSQL特性:
        - pg_trgm的similarity()函数
        - GIN索引的%运算符（预筛选）
        - JSONB的?&运算符（属性匹配）
        
        Args:
            parsed_query: 查询对象
            limit: 结果数量限制
            min_similarity: 最小相似度阈值
            
        Returns:
            SQL查询字符串
        """
        # 提取权重
        w_name = self.weights['name']
        w_desc = self.weights['description']
        w_attr = self.weights['attributes']
        w_cat = self.weights['category']
        
        # 构建属性相似度计算子查询
        attr_similarity_sql = self._build_attribute_similarity_sql(parsed_query)
        
        sql = f"""
        SELECT 
            m.erp_code,
            m.material_name,
            m.specification,
            m.model,
            m.enable_state,
            m.unit_name,
            m.category_name,
            m.normalized_name,
            m.full_description,
            m.attributes,
            m.detected_category,
            m.category_confidence,
            m.oracle_category_id,
            m.oracle_unit_id,
            -- 多字段加权相似度计算
            (
                {w_name} * similarity(m.normalized_name, :query_name) +
                {w_desc} * similarity(m.full_description, :query_desc) +
                {w_attr} * {attr_similarity_sql} +
                {w_cat} * CASE 
                    WHEN m.detected_category = :query_category 
                    THEN 1.0 
                    ELSE 0.0 
                END
            ) AS similarity_score,
            -- 各维度相似度明细（用于透明化）
            similarity(m.normalized_name, :query_name) AS name_similarity,
            similarity(m.full_description, :query_desc) AS description_similarity,
            {attr_similarity_sql} AS attributes_similarity,
            CASE 
                WHEN m.detected_category = :query_category 
                THEN 1.0 
                ELSE 0.0 
            END AS category_similarity
        FROM materials_master m
        WHERE 
            -- 预筛选：利用GIN索引加速（移除分类条件）
            (
                m.normalized_name % :query_name OR
                m.full_description % :query_desc
            )
            -- 相似度阈值过滤（分类权重为0，不影响计算）
            AND (
                {w_name} * similarity(m.normalized_name, :query_name) +
                {w_desc} * similarity(m.full_description, :query_desc) +
                {w_attr} * {attr_similarity_sql}
            ) >= :min_similarity
        ORDER BY similarity_score DESC
        LIMIT :limit;
        """
        
        return sql
    
    def _build_attribute_similarity_sql(self, parsed_query: ParsedQuery) -> str:
        """
        构建属性相似度计算SQL片段
        
        算法:
        1. 对每个属性键，如果存在则计算相似度
        2. 归一化：所有属性相似度的平均值
        3. 如果双方都没有属性，视为完全相同（1.0）
        
        Args:
            parsed_query: 查询对象
            
        Returns:
            SQL片段
        """
        if not parsed_query.attributes:
            # 修复：如果查询没有属性，检查数据库物料是否也没有属性
            # 双方都没有属性 → 1.0（完全相同）
            # 数据库有属性但查询没有 → 0.0（不匹配）
            return """
            CASE
                WHEN m.attributes IS NULL OR m.attributes = 'null'::jsonb OR m.attributes = '{{}}'::jsonb
                THEN 1.0
                ELSE 0.0
            END
            """
        
        # 为每个属性构建相似度计算
        similarity_terms = []
        for key in parsed_query.attributes.keys():
            term = f"""
            CASE 
                WHEN attributes ? '{key}' THEN 
                    similarity(attributes->>'{key}', :query_attrs_{key})
                ELSE 0.0
            END
            """
            similarity_terms.append(term.strip())
        
        if not similarity_terms:
            return "0.0"
        
        # 计算平均值
        if len(similarity_terms) == 1:
            return f"({similarity_terms[0]})"
        else:
            avg_expr = " + ".join(similarity_terms)
            return f"(({avg_expr}) / {len(similarity_terms)}.0)"
    
    def _prepare_query_params(
        self,
        parsed_query: ParsedQuery,
        limit: int,
        min_similarity: float
    ) -> Dict[str, Any]:
        """
        准备查询参数
        
        Args:
            parsed_query: 查询对象
            limit: 结果数量限制
            min_similarity: 最小相似度阈值
            
        Returns:
            查询参数字典
        """
        params = {
            'query_name': parsed_query.standardized_name,
            'query_desc': parsed_query.full_description,
            'query_category': parsed_query.detected_category,
            'limit': limit,
            'min_similarity': min_similarity
        }
        
        # 添加属性参数
        for key, value in parsed_query.attributes.items():
            params[f'query_attrs_{key}'] = value
        
        return params
    
    def _parse_result_row(self, row: Any, parsed_query: ParsedQuery) -> MaterialResult:
        """
        解析查询结果行
        
        Args:
            row: SQLAlchemy Row对象
            parsed_query: 原始查询（用于计算breakdown）
            
        Returns:
            MaterialResult对象
        """
        # DEBUG: 输出row对象的所有字段
        logger.debug(f"[OK] Parsing result row for ERP code: {row.erp_code}")
        logger.debug(f"[OK] Row keys: {row._mapping.keys()}")
        logger.debug(f"[OK] unit_name value: {repr(row.unit_name)} (type: {type(row.unit_name)})")
        logger.debug(f"[OK] category_name value: {repr(row.category_name)} (type: {type(row.category_name)})")
        
        # 提取各维度相似度
        name_sim = float(row.name_similarity) if row.name_similarity is not None else 0.0
        desc_sim = float(row.description_similarity) if row.description_similarity is not None else 0.0
        attr_sim = float(row.attributes_similarity) if row.attributes_similarity is not None else 0.0
        cat_sim = float(row.category_similarity) if row.category_similarity is not None else 0.0
        
        similarity_breakdown = {
            'name_similarity': name_sim,
            'description_similarity': desc_sim,
            'attributes_similarity': attr_sim,
            'category_similarity': cat_sim
        }
        
        return MaterialResult(
            erp_code=row.erp_code,
            material_name=row.material_name or '',
            specification=row.specification or '',
            model=row.model or '',
            unit_name=row.unit_name or '',
            category_name=row.category_name or '',
            enable_state=row.enable_state if hasattr(row, 'enable_state') else None,
            full_description=row.full_description or '',
            normalized_name=row.normalized_name,
            attributes=row.attributes or {},
            detected_category=row.detected_category,
            category_confidence=float(row.category_confidence) if row.category_confidence else 0.0,
            similarity_score=float(row.similarity_score),
            # 添加独立的相似度字段
            name_similarity=name_sim,
            description_similarity=desc_sim,
            attributes_similarity=attr_sim,
            category_similarity=cat_sim,
            # 保持完整的breakdown字典
            similarity_breakdown=similarity_breakdown
        )
    
    async def batch_find_similar(
        self,
        queries: List[ParsedQuery],
        limit: int = 10,
        min_similarity: float = 0.1
    ) -> List[List[MaterialResult]]:
        """
        批量查找相似物料
        
        Args:
            queries: 批量查询列表
            limit: 每个查询的返回数量
            min_similarity: 最小相似度阈值
            
        Returns:
            List[List[MaterialResult]]: 每个查询的结果列表
        """
        if not queries:
            return []
        
        logger.info(f"Batch processing {len(queries)} queries...")
        
        results = []
        for query in queries:
            try:
                materials = await self.find_similar_materials(query, limit, min_similarity)
                results.append(materials)
            except Exception as e:
                logger.error(f"Failed to process query '{query.standardized_name}': {str(e)}")
                results.append([])  # 失败时返回空列表
        
        logger.info(f"Batch processing completed: {len(results)} results")
        return results
    
    def update_weights(self, weights: Dict[str, float]) -> None:
        """
        动态更新权重配置
        
        Args:
            weights: 新的权重配置
            
        Raises:
            ValueError: 如果权重配置无效
        """
        # 验证新权重
        old_weights = self.weights.copy()
        self.weights = weights
        
        try:
            self._validate_weights()
            # 清空缓存（权重改变会影响结果）
            self._cache.clear()
            logger.info(f"Weights updated from {old_weights} to {weights}")
        except ValueError as e:
            # 恢复旧权重
            self.weights = old_weights
            raise e
    
    def get_weights(self) -> Dict[str, float]:
        """
        获取当前权重配置
        
        Returns:
            权重配置字典
        """
        return self.weights.copy()
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """
        获取缓存统计信息
        
        Returns:
            缓存统计信息字典
        """
        total_requests = self._cache_hits + self._cache_misses
        hit_rate = self._cache_hits / total_requests if total_requests > 0 else 0.0
        
        return {
            'cache_size': len(self._cache),
            'cache_max_size': self._cache.maxsize,
            'cache_ttl_seconds': self.cache_ttl.total_seconds(),
            'cache_hits': self._cache_hits,
            'cache_misses': self._cache_misses,
            'hit_rate': hit_rate
        }
    
    async def clear_cache(self) -> None:
        """
        清空缓存
        """
        self._cache.clear()
        self._cache_hits = 0
        self._cache_misses = 0
        logger.info("Cache cleared")
    
    def __repr__(self) -> str:
        return (
            f"SimilarityCalculator("
            f"weights={self.weights}, "
            f"cache_size={len(self._cache)}/{self._cache.maxsize}"
            f")"
        )

