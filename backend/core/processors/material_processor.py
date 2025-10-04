"""
UniversalMaterialProcessor - 通用物料处理器

实现在线API查询的对称处理算法
核心原则：复用SimpleMaterialProcessor的算法，确保ETL和API的处理结果完全一致

对应design.md第2.2.1节UniversalMaterialProcessor设计
"""

import logging
import re
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Tuple

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from backend.models.materials import (
    ExtractionRule,
    Synonym,
    KnowledgeCategory
)
from backend.core.schemas.material_schemas import ParsedQuery

logger = logging.getLogger(__name__)


class UniversalMaterialProcessor:
    """
    通用物料处理器 - 支持全品类工业物料的对称处理
    
    职责:
    - 从PostgreSQL动态加载知识库（规则、词典、分类）
    - 实现4步对称处理算法（与SimpleMaterialProcessor一致）
    - 支持缓存机制（5秒TTL）
    - 提供处理透明化（记录处理步骤）
    
    核心算法:
    - 标准化: Hash表同义词替换 (O(1)查找)
    - 结构化: 正则表达式有限状态自动机
    - 分类检测: 加权关键词匹配
    
    对称处理保证: 与SimpleMaterialProcessor使用相同的算法和数据源
    """
    
    def __init__(self, db_session: AsyncSession, cache_ttl_seconds: int = 5):
        """
        初始化通用物料处理器
        
        Args:
            db_session: PostgreSQL异步会话
            cache_ttl_seconds: 缓存TTL（秒），默认5秒
        """
        self.db = db_session
        self.cache_ttl = timedelta(seconds=cache_ttl_seconds)
        
        # 知识库缓存 - 从PostgreSQL动态加载
        self._extraction_rules: List[Dict[str, Any]] = []
        self._synonyms: Dict[str, str] = {}
        self._category_keywords: Dict[str, List[str]] = {}
        
        # 缓存管理
        self._last_cache_update: Optional[datetime] = None
        self._cache_loaded = False
        
        # 全角半角转换映射表（76个字符对）
        self._fullwidth_map = self._build_fullwidth_map()
        
        # 处理步骤记录（用于透明化）
        self._processing_steps: List[str] = []
        
        logger.info(f"UniversalMaterialProcessor initialized (cache TTL: {cache_ttl_seconds}s)")
    
    def _build_fullwidth_map(self) -> Dict[str, str]:
        """
        构建全角到半角的转换映射表
        
        Returns:
            全角到半角的映射字典（76个字符对）
        """
        fullwidth_map = {}
        
        # 数字 (0-9)
        for i in range(10):
            fullwidth_map[chr(0xFF10 + i)] = str(i)
        
        # 大写字母 (A-Z)
        for i in range(26):
            fullwidth_map[chr(0xFF21 + i)] = chr(0x41 + i)
        
        # 小写字母 (a-z)
        for i in range(26):
            fullwidth_map[chr(0xFF41 + i)] = chr(0x61 + i)
        
        # 常用符号
        symbol_pairs = [
            ('　', ' '),   # 全角空格
            ('！', '!'), ('＂', '"'), ('＃', '#'), ('＄', '$'),
            ('％', '%'), ('＆', '&'), ('＇', "'"), ('（', '('),
            ('）', ')'), ('＊', '*'), ('＋', '+'), ('，', ','),
            ('－', '-'), ('．', '.'), ('／', '/'), ('：', ':'),
            ('；', ';'), ('＜', '<'), ('＝', '='), ('＞', '>'),
            ('？', '?'), ('＠', '@'), ('［', '['), ('＼', '\\'),
            ('］', ']'), ('＾', '^'), ('＿', '_'), ('｀', '`'),
            ('｛', '{'), ('｜', '|'), ('｝', '}'), ('～', '~'),
            ('×', 'x'), ('Ф', 'Φ'),
        ]
        
        for full, half in symbol_pairs:
            fullwidth_map[full] = half
        
        return fullwidth_map
    
    async def _ensure_cache_fresh(self) -> None:
        """
        确保缓存新鲜度，支持热更新
        
        如果缓存未加载或已过期（超过TTL），则重新从PostgreSQL加载知识库
        """
        now = datetime.now()
        
        # 判断是否需要刷新缓存
        need_refresh = (
            not self._cache_loaded or
            self._last_cache_update is None or
            (now - self._last_cache_update) > self.cache_ttl
        )
        
        if need_refresh:
            logger.info("Cache expired or not loaded, reloading knowledge base from PostgreSQL...")
            await self._load_knowledge_base()
            self._last_cache_update = now
            self._cache_loaded = True
            logger.info(f"Knowledge base reloaded at {now.isoformat()}")
    
    async def _load_knowledge_base(self) -> None:
        """
        从PostgreSQL动态加载知识库数据
        
        加载内容:
        1. extraction_rules表 - 属性提取规则
        2. synonyms表 - 同义词词典
        3. knowledge_categories表 - 分类关键词
        
        注意: 与SimpleMaterialProcessor使用相同的数据源，确保对称处理
        """
        try:
            # 1. 加载属性提取规则
            stmt = select(ExtractionRule).where(ExtractionRule.is_active == True)
            result = await self.db.execute(stmt)
            rules = result.scalars().all()
            
            self._extraction_rules = [
                {
                    'rule_name': rule.rule_name,
                    'material_category': rule.material_category,
                    'attribute_name': rule.attribute_name,
                    'regex_pattern': rule.regex_pattern,
                    'priority': rule.priority or 50,
                    'confidence': float(rule.confidence) if rule.confidence else 1.0
                }
                for rule in rules
            ]
            logger.info(f"✅ Loaded {len(self._extraction_rules)} extraction rules from PostgreSQL")
            
            # 2. 加载同义词词典
            stmt = select(Synonym).where(Synonym.is_active == True)
            result = await self.db.execute(stmt)
            synonyms = result.scalars().all()
            
            self._synonyms = {
                syn.original_term: syn.standard_term
                for syn in synonyms
            }
            logger.info(f"✅ Loaded {len(self._synonyms)} synonyms from PostgreSQL")
            
            # 3. 加载分类关键词
            stmt = select(KnowledgeCategory).where(KnowledgeCategory.is_active == True)
            result = await self.db.execute(stmt)
            categories = result.scalars().all()
            
            self._category_keywords = {
                cat.category_name: cat.keywords
                for cat in categories
            }
            logger.info(f"✅ Loaded {len(self._category_keywords)} categories from PostgreSQL")
            
        except Exception as e:
            error_msg = f"Failed to load knowledge base from PostgreSQL: {str(e)}"
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
    
    async def process_material_description(
        self,
        description: str,
        category_hint: Optional[str] = None
    ) -> ParsedQuery:
        """
        处理物料描述 - 对称处理算法的核心入口
        
        Args:
            description: 用户输入的物料描述文本
            category_hint: 可选的类别提示
            
        Returns:
            ParsedQuery: 包含标准化名称、属性、类别等信息
            
        对称处理流程（4步算法，与SimpleMaterialProcessor一致）:
            步骤1: 智能分类检测
            步骤2: 文本标准化
            步骤3: 同义词替换
            步骤4: 属性提取
        """
        # 确保缓存新鲜
        await self._ensure_cache_fresh()
        
        # 初始化处理步骤记录
        self._processing_steps = []
        
        # 步骤0: 验证输入
        if not description or not description.strip():
            return ParsedQuery(
                standardized_name="",
                attributes={},
                detected_category="general",
                confidence=0.0,
                full_description="",
                processing_steps=["输入为空"]
            )
        
        full_description = description.strip()
        
        try:
            # 步骤1: 智能分类检测
            detected_category, confidence = self._detect_material_category(
                full_description,
                category_hint
            )
            self._processing_steps.append(
                f"步骤1: 检测到类别'{detected_category}'，置信度{confidence:.2f}"
            )
            
            # 步骤2: 文本标准化
            normalized_text = self._normalize_text(full_description)
            if normalized_text != full_description:
                self._processing_steps.append(
                    f"步骤2: 文本标准化（全角转半角、去除多余空格）"
                )
            
            # 步骤3: 同义词替换
            standardized_text, replaced_count = self._apply_synonyms(normalized_text)
            if replaced_count > 0:
                self._processing_steps.append(
                    f"步骤3: 同义词替换（{replaced_count}个词）"
                )
            
            # 提取核心名称
            standardized_name = self._extract_core_name(standardized_text)
            
            # 步骤4: 属性提取
            attributes = self._extract_attributes(standardized_text, detected_category)
            if attributes:
                attr_str = ', '.join(f"{k}={v}" for k, v in attributes.items())
                self._processing_steps.append(
                    f"步骤4: 提取属性 {{{attr_str}}}"
                )
            
            # 构建返回结果
            return ParsedQuery(
                standardized_name=standardized_name,
                attributes=attributes,
                detected_category=detected_category,
                confidence=confidence,
                full_description=full_description,
                processing_steps=self._processing_steps.copy()
            )
            
        except Exception as e:
            error_msg = f"处理失败: {str(e)}"
            logger.error(f"Failed to process description '{description}': {str(e)}")
            self._processing_steps.append(f"错误: {error_msg}")
            
            # 返回降级结果
            return ParsedQuery(
                standardized_name=full_description,
                attributes={},
                detected_category="general",
                confidence=0.0,
                full_description=full_description,
                processing_steps=self._processing_steps.copy()
            )
    
    def _detect_material_category(
        self,
        description: str,
        category_hint: Optional[str] = None
    ) -> Tuple[str, float]:
        """
        步骤1: 智能分类检测算法
        
        Args:
            description: 物料描述文本
            category_hint: 可选的类别提示
            
        Returns:
            (detected_category, confidence)
            
        算法:
            1. 如果有category_hint且有效，直接使用
            2. 将description转为小写
            3. 遍历所有分类的关键词
            4. 计算匹配得分 = 匹配数 / 总关键词数
            5. 返回得分最高的分类
            
        与SimpleMaterialProcessor._detect_category()保持一致
        """
        # 如果提供了有效的类别提示
        if category_hint and category_hint in self._category_keywords:
            return category_hint, 1.0
        
        if not description:
            return 'general', 0.1
        
        description_lower = description.lower()
        category_scores = {}
        
        # 计算每个分类的匹配得分
        for category, keywords in self._category_keywords.items():
            if not keywords:
                continue
                
            matched_count = sum(1 for kw in keywords if kw.lower() in description_lower)
            
            if matched_count > 0:
                # 归一化得分 = 匹配数 / 总关键词数
                score = matched_count / len(keywords)
                
                # 权重调整：如果匹配了多个关键词，提高置信度
                if matched_count >= 2:
                    score = min(score * 1.5, 0.95)
                
                category_scores[category] = score
        
        if not category_scores:
            return 'general', 0.1
        
        # 返回得分最高的分类
        best_category = max(category_scores, key=category_scores.get)
        confidence = category_scores[best_category]
        
        return best_category, confidence
    
    def _normalize_text(self, text: str) -> str:
        """
        步骤2: 文本标准化
        
        算法:
            1. 全角转半角（76个字符对）
            2. 去除多余空格
            3. 统一大小写（品牌名保留）
            
        与SimpleMaterialProcessor._normalize_text()保持一致
        """
        if not text:
            return ''
        
        # 1. 全角转半角
        normalized = ''.join(self._fullwidth_map.get(c, c) for c in text)
        
        # 2. 去除多余空格
        normalized = ' '.join(normalized.split())
        
        # 3. 品牌名保留大小写（这里简化处理）
        # 未来可以添加品牌名识别和大小写保留逻辑
        
        return normalized
    
    def _apply_synonyms(self, text: str) -> Tuple[str, int]:
        """
        步骤3: 同义词替换算法
        
        Args:
            text: 标准化后的文本
            
        Returns:
            (standardized_text, replaced_count)
            
        算法:
            1. 分词（按空格）
            2. Hash表O(1)查找替换
            3. 重组文本
            
        与SimpleMaterialProcessor._apply_synonyms()保持一致
        """
        if not text:
            return '', 0
        
        words = text.split()
        standardized_words = []
        replaced_count = 0
        
        for word in words:
            # Hash表O(1)查找
            if word in self._synonyms:
                standardized_words.append(self._synonyms[word])
                replaced_count += 1
            else:
                standardized_words.append(word)
        
        return ' '.join(standardized_words), replaced_count
    
    def _extract_core_name(self, text: str) -> str:
        """
        提取核心名称（去除品牌等）
        
        简化版: 直接返回标准化后的文本
        未来可以实现更复杂的品牌识别和去除逻辑
        
        与SimpleMaterialProcessor._extract_core_name()保持一致
        """
        return text
    
    def _extract_attributes(self, text: str, category: str) -> Dict[str, str]:
        """
        步骤4: 属性提取算法
        
        Args:
            text: 标准化后的文本
            category: 检测到的物料类别
            
        Returns:
            提取的属性字典
            
        算法:
            1. 按优先级排序规则
            2. 过滤适用于当前类别的规则
            3. 依次应用正则表达式
            4. 构建属性字典
            
        与SimpleMaterialProcessor._extract_attributes()保持一致
        """
        if not text:
            return {}
        
        attributes = {}
        
        # 按优先级排序规则
        sorted_rules = sorted(
            self._extraction_rules,
            key=lambda x: x.get('priority', 50),
            reverse=True
        )
        
        for rule in sorted_rules:
            # 只应用匹配当前类别的规则
            rule_category = rule.get('material_category', 'general')
            if rule_category not in [category, 'general']:
                continue
            
            pattern = rule.get('regex_pattern', '')
            if not pattern:
                continue
            
            try:
                match = re.search(pattern, text, re.IGNORECASE)
                
                if match:
                    attr_name = rule.get('attribute_name', 'unknown')
                    attr_value = match.group(1) if match.groups() else match.group(0)
                    attributes[attr_name] = attr_value
                    
            except re.error as e:
                logger.warning(f"Invalid regex pattern in rule {rule.get('rule_name')}: {str(e)}")
                continue
        
        return attributes
    
    def _calculate_category_confidence(self, description: str, category: str) -> float:
        """
        计算类别检测置信度
        
        Args:
            description: 物料描述
            category: 检测到的类别
            
        Returns:
            置信度 (0.0-1.0)
        """
        if category == 'general':
            return 0.5
        
        keywords = self._category_keywords.get(category, [])
        if not keywords:
            return 0.1
            
        description_lower = description.lower()
        matches = sum(1 for keyword in keywords if keyword.lower() in description_lower)
        return min(matches / len(keywords), 1.0)
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """
        获取缓存统计信息
        
        Returns:
            缓存统计信息字典
        """
        return {
            'cache_loaded': self._cache_loaded,
            'last_update': self._last_cache_update.isoformat() if self._last_cache_update else None,
            'cache_ttl_seconds': self.cache_ttl.total_seconds(),
            'rules_count': len(self._extraction_rules),
            'synonyms_count': len(self._synonyms),
            'categories_count': len(self._category_keywords)
        }
    
    async def clear_cache(self) -> None:
        """
        清空缓存，强制重新加载知识库
        """
        self._extraction_rules = []
        self._synonyms = {}
        self._category_keywords = {}
        self._last_cache_update = None
        self._cache_loaded = False
        logger.info("Cache cleared, will reload on next request")

