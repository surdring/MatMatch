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


# 默认权重配置（基于业务专家经验 + AHP层次分析法）
DEFAULT_WEIGHTS = {
    'name': 0.4,        # 名称相似度 40%
    'description': 0.3, # 描述相似度 30%
    'attributes': 0.2,  # 属性相似度 20%
    'category': 0.1     # 类别相似度 10%
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
            
            logger.info(
                f"Found {len(materials)} similar materials for "
                f"'{parsed_query.standardized_name[:30]}...' (similarity >= {min_similarity})"
            )
            
            return materials
            
        except Exception as e:
            error_msg = f"Failed to find similar materials: {str(e)}"
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
    
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
            erp_code,
            material_name,
            specification,
            model,
            normalized_name,
            full_description,
            attributes,
            detected_category,
            category_confidence,
            oracle_category_id,
            oracle_unit_id,
            -- 多字段加权相似度计算
            (
                {w_name} * similarity(normalized_name, :query_name) +
                {w_desc} * similarity(full_description, :query_desc) +
                {w_attr} * {attr_similarity_sql} +
                {w_cat} * CASE 
                    WHEN detected_category = :query_category 
                    THEN 1.0 
                    ELSE 0.0 
                END
            ) AS similarity_score,
            -- 各维度相似度明细（用于透明化）
            similarity(normalized_name, :query_name) AS name_similarity,
            similarity(full_description, :query_desc) AS description_similarity,
            {attr_similarity_sql} AS attributes_similarity,
            CASE 
                WHEN detected_category = :query_category 
                THEN 1.0 
                ELSE 0.0 
            END AS category_similarity
        FROM materials_master
        WHERE 
            -- 预筛选：利用GIN索引加速
            (
                normalized_name % :query_name OR
                full_description % :query_desc OR
                detected_category = :query_category
            )
            -- 启用状态过滤
            AND enable_state = 2
            -- 相似度阈值过滤
            AND (
                {w_name} * similarity(normalized_name, :query_name) +
                {w_desc} * similarity(full_description, :query_desc) +
                {w_attr} * {attr_similarity_sql} +
                {w_cat} * CASE 
                    WHEN detected_category = :query_category 
                    THEN 1.0 
                    ELSE 0.0 
                END
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
        
        Args:
            parsed_query: 查询对象
            
        Returns:
            SQL片段
        """
        if not parsed_query.attributes:
            return "0.0"
        
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
        # 提取相似度明细
        similarity_breakdown = {
            'name_similarity': float(row.name_similarity),
            'description_similarity': float(row.description_similarity),
            'attributes_similarity': float(row.attributes_similarity),
            'category_similarity': float(row.category_similarity)
        }
        
        return MaterialResult(
            erp_code=row.erp_code,
            material_name=row.material_name or '',
            specification=row.specification or '',
            model=row.model or '',
            normalized_name=row.normalized_name,
            full_description=row.full_description,
            attributes=row.attributes or {},
            detected_category=row.detected_category,
            category_confidence=float(row.category_confidence) if row.category_confidence else 0.0,
            similarity_score=float(row.similarity_score),
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

