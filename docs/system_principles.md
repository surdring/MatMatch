# 智能物料查重工具 - 核心原理与规则管理指南

**版本:** 1.0  
**更新日期:** 2025-10-02  

## 1. 系统核心原理

### 1.1 整体架构原理

智能物料查重工具基于**"对称处理"**的核心设计原则，通过三个关键步骤实现智能查重：

```
原始物料描述 → 数据标准化 → 结构化提取 → 相似度计算 → 查重结果
```

#### 1.1.1 对称处理原则 (Symmetrical Processing)
**核心思想：** 无论是离线ETL处理存量数据，还是在线API处理用户查询，都必须使用完全相同的算法流程。

**实现方式：**
- 统一的`UniversalMaterialProcessor`类处理所有物料
- 相同的同义词词典和提取规则
- 一致的标准化和结构化算法
- 确保比较基准的绝对一致性

**意义：** 保证查重结果的准确性和可靠性，避免因处理差异导致的误判。

### 1.2 数据标准化原理

#### 1.2.1 同义词标准化
**原理：** 将不同表达方式的相同概念统一为标准形式。

**示例：**
```
"不锈钢" → "304"
"SS304" → "304" 
"stainless steel" → "304"
"六角螺栓" → "内六角螺栓"
"Allen bolt" → "内六角螺栓"
```

**技术实现：**
```python
class SynonymDictionary:
    def __init__(self):
        self.synonyms = {
            "304": ["不锈钢", "SS304", "stainless steel", "304不锈钢"],
            "内六角螺栓": ["六角螺栓", "Allen bolt", "六角头螺栓"],
            # ... 更多同义词组
        }
    
    def standardize(self, text: str) -> str:
        """将文本中的同义词替换为标准形式"""
        for standard, synonyms in self.synonyms.items():
            for synonym in synonyms:
                text = text.replace(synonym, standard)
        return text
```

#### 1.2.2 多层次标准化策略

1. **词汇层面标准化**
   - 材质标准化：不锈钢 → 304
   - 品牌标准化：斯凯孚 → SKF
   - 单位标准化：毫米 → mm

2. **语义层面标准化**
   - 功能同义：球阀 ↔ 球形阀门
   - 规格同义：M8*20 ↔ M8×20

3. **格式层面标准化**
   - 去除多余空格和特殊字符
   - 统一大小写规则
   - 标准化数字格式

### 1.3 结构化提取原理

#### 1.3.1 基于正则表达式的属性提取
**原理：** 使用预定义的正则表达式模式，从标准化后的文本中提取关键属性。

**核心提取规则：**
```python
EXTRACTION_RULES = {
    "size_metric": {
        "pattern": r"M(\d+)(?:[*×x](\d+(?:\.\d+)?))?",
        "description": "公制螺纹规格",
        "examples": ["M8", "M10*1.5", "M20×2.5"],
        "confidence": 0.95
    },
    "diameter": {
        "pattern": r"(?:DN|Φ|φ|直径)(\d+(?:\.\d+)?)",
        "description": "公称直径",
        "examples": ["DN50", "Φ25", "直径100"],
        "confidence": 0.90
    },
    "material": {
        "pattern": r"(304|316L?|201|430|碳钢|合金钢)",
        "description": "材质类型",
        "examples": ["304", "316L", "碳钢"],
        "confidence": 0.92
    }
}
```

#### 1.3.2 智能类别检测
**原理：** 基于关键词匹配和上下文分析，自动识别物料类别。

**类别检测算法：**
```python
CATEGORY_KEYWORDS = {
    "bearing": {
        "primary": ["轴承", "bearing"],
        "secondary": ["深沟球", "圆锥滚子", "推力球"],
        "brands": ["SKF", "FAG", "NSK", "斯凯孚"],
        "confidence_threshold": 0.85
    },
    "bolt": {
        "primary": ["螺栓", "螺丝", "bolt", "screw"],
        "secondary": ["内六角", "外六角", "十字槽"],
        "specifications": ["M8", "M10", "M12"],
        "confidence_threshold": 0.90
    }
}
```

### 1.4 相似度计算原理

#### 1.4.1 多字段加权相似度算法
**原理：** 综合考虑物料的多个维度，计算加权相似度得分。

**相似度公式：**
```
总相似度 = w1×名称相似度 + w2×描述相似度 + w3×属性相似度 + w4×类别相似度

其中：w1 + w2 + w3 + w4 = 1.0
```

**技术实现（基于PostgreSQL pg_trgm）：**
```sql
SELECT 
    m.*,
    (
        0.4 * SIMILARITY(m.normalized_name, %s) +
        0.3 * SIMILARITY(m.full_description, %s) +
        0.2 * (m.attributes <-> %s::jsonb) +
        0.1 * CASE WHEN m.detected_category = %s THEN 1.0 ELSE 0.0 END
    ) AS similarity_score
FROM materials_master m
WHERE 
    m.normalized_name %% %s OR 
    m.full_description %% %s OR
    m.attributes ? %s
ORDER BY similarity_score DESC
LIMIT 50;
```

#### 1.4.2 相似度权重配置原则
- **名称相似度 (40%)：** 最重要，直接反映物料本质
- **描述相似度 (30%)：** 补充细节信息
- **属性相似度 (20%)：** 结构化属性匹配
- **类别相似度 (10%)：** 确保同类物料优先

## 2. 管理员规则设定原理

### 2.1 规则管理的核心原则

#### 2.1.1 渐进式优化原则
**原理：** 从基础规则开始，根据实际数据和用户反馈逐步优化。

**实施步骤：**
1. **基础规则建立**：基于常见模式创建初始规则
2. **数据驱动优化**：分析真实数据，发现新模式
3. **用户反馈集成**：根据查重结果反馈调整规则
4. **持续监控改进**：定期评估规则效果，持续优化

#### 2.1.2 分层管理原则
**原理：** 将规则按照复杂度和重要性分层管理。

**分层结构：**
```
L1: 基础规则层
├── 通用尺寸规格提取
├── 基本材质识别
└── 常见单位标准化

L2: 专业规则层
├── 行业特定术语
├── 品牌型号识别
└── 复杂规格解析

L3: 高级规则层
├── 上下文相关规则
├── 异常情况处理
└── 自定义业务规则
```

### 2.2 同义词词典设定原则

#### 2.2.1 数据驱动构建原则
**原理：** 基于真实ERP数据分析，发现同义词模式。

**构建流程：**
```python
def build_synonym_dictionary(oracle_data):
    """基于真实数据构建同义词词典"""
    
    # 1. 数据预处理
    cleaned_data = preprocess_material_names(oracle_data)
    
    # 2. 模式识别
    patterns = identify_synonym_patterns(cleaned_data)
    
    # 3. 聚类分析
    synonym_groups = cluster_similar_terms(patterns)
    
    # 4. 专家验证
    validated_groups = expert_validation(synonym_groups)
    
    # 5. 词典生成
    return generate_dictionary(validated_groups)
```

#### 2.2.2 分类别词典管理
**原理：** 不同物料类别使用专门的同义词词典。

**示例结构：**
```json
{
  "bearing_synonyms": {
    "深沟球轴承": ["深沟球", "radial ball bearing", "单列深沟球轴承"],
    "圆锥滚子轴承": ["圆锥滚子", "tapered roller bearing", "圆锥轴承"]
  },
  "bolt_synonyms": {
    "内六角螺栓": ["六角螺栓", "Allen bolt", "内六角头螺栓"],
    "十字槽螺丝": ["十字螺丝", "Phillips screw", "十字头螺丝"]
  },
  "valve_synonyms": {
    "球阀": ["球形阀", "ball valve", "球形阀门"],
    "闸阀": ["闸板阀", "gate valve", "楔式闸阀"]
  }
}
```

### 2.3 提取规则设定原则

#### 2.3.1 高置信度优先原则
**原理：** 优先使用置信度高的规则，确保提取准确性。

**规则评估标准：**
```python
def evaluate_rule_confidence(rule, test_data):
    """评估规则置信度"""
    correct_extractions = 0
    total_extractions = 0
    
    for material in test_data:
        extracted = apply_rule(rule, material.description)
        if extracted:
            total_extractions += 1
            if validate_extraction(extracted, material.ground_truth):
                correct_extractions += 1
    
    confidence = correct_extractions / total_extractions if total_extractions > 0 else 0
    return confidence

# 置信度分级
CONFIDENCE_LEVELS = {
    "高置信度": confidence >= 0.95,
    "中置信度": 0.85 <= confidence < 0.95,
    "低置信度": 0.70 <= confidence < 0.85,
    "不可用": confidence < 0.70
}
```

#### 2.3.2 规则冲突解决原则
**原理：** 当多个规则匹配同一文本时，使用优先级和置信度解决冲突。

**冲突解决策略：**
1. **置信度优先**：选择置信度最高的规则
2. **特异性优先**：选择更具体的规则
3. **上下文相关**：考虑物料类别上下文
4. **人工审核**：复杂冲突提交专家审核

### 2.4 管理员操作界面设计原则

#### 2.4.1 可视化管理原则
**原理：** 提供直观的可视化界面，降低管理复杂度。

**界面功能：**
```
规则管理界面
├── 规则列表展示
│   ├── 规则名称和描述
│   ├── 置信度指标
│   ├── 使用频率统计
│   └── 最后更新时间
├── 规则编辑器
│   ├── 正则表达式编辑
│   ├── 实时测试功能
│   ├── 示例数据验证
│   └── 置信度计算
└── 效果预览
    ├── 提取结果预览
    ├── 影响范围分析
    └── A/B测试对比
```

#### 2.4.2 版本控制原则
**原理：** 所有规则变更都有版本记录，支持回滚操作。

**版本管理功能：**
```python
class RuleVersionManager:
    def __init__(self):
        self.versions = {}
    
    def create_version(self, rule_id, rule_content, operator, description):
        """创建新版本"""
        version = {
            'version_id': generate_version_id(),
            'rule_content': rule_content,
            'operator': operator,
            'timestamp': datetime.now(),
            'description': description,
            'status': 'active'
        }
        
        if rule_id not in self.versions:
            self.versions[rule_id] = []
        
        self.versions[rule_id].append(version)
        return version['version_id']
    
    def rollback_to_version(self, rule_id, version_id):
        """回滚到指定版本"""
        # 实现版本回滚逻辑
        pass
```

## 3. 质量保证原则

### 3.1 数据质量监控
**原理：** 持续监控规则和词典的效果，及时发现问题。

**监控指标：**
- **准确率**：正确提取/总提取次数
- **召回率**：正确提取/应该提取次数
- **覆盖率**：规则匹配的物料比例
- **冲突率**：规则冲突的频率

### 3.2 A/B测试原则
**原理：** 新规则上线前进行A/B测试，验证改进效果。

**测试流程：**
1. **基线建立**：记录当前规则的性能指标
2. **测试设计**：设计对照组和实验组
3. **效果评估**：比较两组的查重准确率
4. **统计显著性**：确保改进具有统计意义
5. **全量发布**：测试通过后全量发布

### 3.3 专家审核机制
**原理：** 重要规则变更需要领域专家审核确认。

**审核流程：**
```
规则提交 → 自动测试 → 专家审核 → 业务验证 → 正式发布
```

## 4. 最佳实践建议

### 4.1 规则设定最佳实践

1. **从简单开始**：先建立基础规则，再逐步完善
2. **数据驱动**：基于真实数据分析制定规则
3. **小步快跑**：频繁小幅调整，避免大规模变更
4. **充分测试**：每次变更都要充分测试
5. **文档记录**：详细记录规则变更原因和效果

### 4.2 词典管理最佳实践

1. **分类管理**：按物料类别分别管理词典
2. **定期更新**：根据新数据定期更新词典
3. **质量控制**：建立词典质量评估机制
4. **用户反馈**：收集用户反馈持续改进
5. **备份恢复**：定期备份，支持快速恢复

### 4.3 系统维护最佳实践

1. **性能监控**：持续监控系统性能指标
2. **日志分析**：定期分析系统日志发现问题
3. **容量规划**：根据数据增长规划系统容量
4. **安全更新**：及时更新系统安全补丁
5. **灾备演练**：定期进行灾备恢复演练

---

**总结：** 智能物料查重工具通过"对称处理"原则确保数据处理一致性，通过数据驱动的规则管理实现持续优化，通过可视化界面降低管理复杂度，最终实现高准确率的智能物料查重功能。
