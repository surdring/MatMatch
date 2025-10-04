"""
SimpleMaterialProcessor - 简化版物料处理器

实现对称处理算法的完整流程:
1. 智能分类检测
2. 文本标准化
3. 同义词替换
4. 属性提取

注意: 为Task 2.1的UniversalMaterialProcessor预留接口
"""

import re
import logging
from datetime import datetime
from typing import Dict, Any, List, Tuple, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text

from backend.models.materials import (
    MaterialsMaster,
    ExtractionRule,
    Synonym,
    KnowledgeCategory
)
from .exceptions import ProcessingError

logger = logging.getLogger(__name__)


class SimpleMaterialProcessor:
    """
    简化版物料处理器 - 对称处理算法实现
    
    职责:
    - 加载知识库数据（提取规则、同义词、分类关键词）
    - 实现4步对称处理算法
    - 生成MaterialsMaster ORM对象
    
    为UniversalMaterialProcessor预留接口
    """
    
    def __init__(self, pg_session: AsyncSession):
        """
        初始化处理器
        
        Args:
            pg_session: PostgreSQL异步会话
        """
        self.pg_session = pg_session
        
        # 知识库缓存
        self.extraction_rules: List[Dict[str, Any]] = []
        self.synonyms: Dict[str, str] = {}
        self.category_keywords: Dict[str, List[str]] = {}
        
        # 全角半角转换映射表（76个字符对）
        self._fullwidth_map = self._build_fullwidth_map()
        
        # 初始化状态
        self._knowledge_base_loaded = False
        
        logger.info("SimpleMaterialProcessor initialized")
    
    def _build_fullwidth_map(self) -> Dict[str, str]:
        """构建全角到半角的转换映射表"""
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
            ('！', '!'),
            ('＂', '"'),
            ('＃', '#'),
            ('＄', '$'),
            ('％', '%'),
            ('＆', '&'),
            ('＇', "'"),
            ('（', '('),
            ('）', ')'),
            ('＊', '*'),
            ('＋', '+'),
            ('，', ','),
            ('－', '-'),
            ('．', '.'),
            ('／', '/'),
            ('：', ':'),
            ('；', ';'),
            ('＜', '<'),
            ('＝', '='),
            ('＞', '>'),
            ('？', '?'),
            ('＠', '@'),
            ('［', '['),
            ('＼', '\\'),
            ('］', ']'),
            ('＾', '^'),
            ('＿', '_'),
            ('｀', '`'),
            ('｛', '{'),
            ('｜', '|'),
            ('｝', '}'),
            ('～', '~'),
            ('×', 'x'),
            ('Ф', 'Φ'),
        ]
        
        for full, half in symbol_pairs:
            fullwidth_map[full] = half
        
        return fullwidth_map
    
    async def load_knowledge_base(self) -> None:
        """
        从PostgreSQL加载知识库数据
        
        加载:
        - extraction_rules: 属性提取规则
        - synonyms: 同义词词典
        - knowledge_categories: 分类关键词
        """
        try:
            logger.info("Loading knowledge base from PostgreSQL...")
            
            # 1. 加载提取规则
            stmt = select(ExtractionRule).where(ExtractionRule.is_active == True)
            result = await self.pg_session.execute(stmt)
            rules = result.scalars().all()
            
            self.extraction_rules = [
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
            logger.info(f"✅ Loaded {len(self.extraction_rules)} extraction rules")
            
            # 2. 加载同义词
            stmt = select(Synonym).where(Synonym.is_active == True)
            result = await self.pg_session.execute(stmt)
            synonyms = result.scalars().all()
            
            self.synonyms = {
                syn.original_term: syn.standard_term
                for syn in synonyms
            }
            logger.info(f"✅ Loaded {len(self.synonyms)} synonyms")
            
            # 3. 加载分类关键词
            stmt = select(KnowledgeCategory).where(KnowledgeCategory.is_active == True)
            result = await self.pg_session.execute(stmt)
            categories = result.scalars().all()
            
            self.category_keywords = {
                cat.category_name: cat.keywords
                for cat in categories
            }
            logger.info(f"✅ Loaded {len(self.category_keywords)} categories")
            
            self._knowledge_base_loaded = True
            logger.info("Knowledge base loaded successfully")
            
        except Exception as e:
            error_msg = f"Failed to load knowledge base: {str(e)}"
            logger.error(error_msg)
            raise ProcessingError(error_msg) from e
    
    def process_material(self, data: Dict[str, Any]) -> MaterialsMaster:
        """
        处理单条物料数据 - 对称处理算法核心方法
        
        Args:
            data: Oracle提取的原始数据（含JOIN字段）
            
        Returns:
            MaterialsMaster ORM对象（含对称处理结果）
            
        对称处理流程（4步算法）:
            步骤0: 构建完整描述
            步骤1: 智能分类检测
            步骤2: 文本标准化
            步骤3: 同义词替换
            步骤4: 属性提取
        """
        if not self._knowledge_base_loaded:
            raise ProcessingError("Knowledge base not loaded. Call load_knowledge_base() first.")
        
        try:
            # 步骤0: 构建完整描述
            full_description = self._build_full_description(data)
            
            # 步骤1: 智能分类检测（使用原始描述）
            detected_category, confidence = self._detect_category(full_description)
            
            # 步骤2: 文本标准化
            normalized_text = self._normalize_text(full_description)
            
            # 步骤3: 同义词替换
            standardized_text = self._apply_synonyms(normalized_text)
            normalized_name = self._extract_core_name(standardized_text)
            
            # 步骤4: 属性提取
            attributes = self._extract_attributes(standardized_text, detected_category)
            
            # 构建MaterialsMaster对象
            material = MaterialsMaster(
                # Oracle原始字段
                erp_code=data.get('erp_code'),
                material_name=data.get('material_name'),
                specification=data.get('specification'),
                model=data.get('model'),
                english_name=data.get('english_name'),
                english_spec=data.get('english_spec'),
                short_name=data.get('short_name'),
                mnemonic_code=data.get('mnemonic_code'),
                memo=data.get('memo'),
                enable_state=data.get('enable_state', 2),
                
                # Oracle时间字段
                oracle_created_time=self._parse_oracle_datetime(data.get('oracle_created_time')),
                oracle_modified_time=self._parse_oracle_datetime(data.get('oracle_modified_time')),
                
                # Oracle外键ID
                oracle_category_id=data.get('oracle_category_id'),
                oracle_unit_id=data.get('oracle_unit_id'),
                oracle_org_id=data.get('oracle_org_id'),
                
                # JOIN获取的关联名称
                # 注意: 这些字段需要确认是否在MaterialsMaster模型中存在
                # category_name=data.get('category_name'),
                # unit_name=data.get('unit_name'),
                
                # 对称处理输出 ⭐⭐⭐
                normalized_name=normalized_name,
                full_description=full_description,
                attributes=attributes,
                detected_category=detected_category,
                category_confidence=float(confidence),
                
                # 处理状态
                last_processed_at=datetime.now(),
                sync_status='synced',
                last_sync_at=datetime.now()
            )
            
            return material
            
        except Exception as e:
            error_msg = f"Failed to process material {data.get('erp_code', 'UNKNOWN')}: {str(e)}"
            logger.error(error_msg)
            raise ProcessingError(error_msg) from e
    
    def _build_full_description(self, data: Dict[str, Any]) -> str:
        """
        构建完整描述
        
        组合: material_name + specification + model
        """
        parts = []
        
        if data.get('material_name'):
            parts.append(str(data['material_name']))
        if data.get('specification'):
            parts.append(str(data['specification']))
        if data.get('model'):
            parts.append(str(data['model']))
        
        return ' '.join(parts) if parts else ''
    
    def _detect_category(self, description: str) -> Tuple[str, float]:
        """
        步骤1: 智能分类检测算法
        
        Args:
            description: 物料描述文本
            
        Returns:
            (detected_category, confidence)
            
        算法:
            1. 将description转为小写
            2. 遍历所有分类的关键词
            3. 计算匹配得分 = 匹配数 / 总关键词数
            4. 返回得分最高的分类
        """
        if not description:
            return 'general', 0.1
        
        description_lower = description.lower()
        category_scores = {}
        
        # 计算每个分类的匹配得分
        for category, keywords in self.category_keywords.items():
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
    
    def _apply_synonyms(self, text: str) -> str:
        """
        步骤3: 同义词替换算法
        
        算法:
            1. 分词（按空格）
            2. Hash表O(1)查找替换
            3. 重组文本
        """
        if not text:
            return ''
        
        words = text.split()
        standardized_words = []
        
        for word in words:
            # Hash表O(1)查找
            if word in self.synonyms:
                standardized_words.append(self.synonyms[word])
            else:
                standardized_words.append(word)
        
        return ' '.join(standardized_words)
    
    def _extract_core_name(self, text: str) -> str:
        """
        提取核心名称（去除品牌等）
        
        简化版: 直接返回标准化后的文本
        未来可以实现更复杂的品牌识别和去除逻辑
        """
        # TODO: 实现品牌识别和去除
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
        """
        if not text:
            return {}
        
        attributes = {}
        
        # 按优先级排序规则
        sorted_rules = sorted(
            self.extraction_rules,
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
    
    def _parse_oracle_datetime(self, time_str: Any) -> Optional[datetime]:
        """
        解析Oracle时间字符串
        
        支持格式:
        - datetime对象
        - ISO格式字符串
        - Oracle格式字符串
        """
        if not time_str:
            return None
        
        if isinstance(time_str, datetime):
            return time_str
        
        if isinstance(time_str, str):
            # 尝试多种格式
            formats = [
                '%Y-%m-%d %H:%M:%S',
                '%Y-%m-%d %H:%M:%S.%f',
                '%Y/%m/%d %H:%M:%S',
                '%Y-%m-%dT%H:%M:%S',
                '%Y-%m-%dT%H:%M:%S.%f',
            ]
            
            for fmt in formats:
                try:
                    return datetime.strptime(time_str, fmt)
                except ValueError:
                    continue
        
        return None

