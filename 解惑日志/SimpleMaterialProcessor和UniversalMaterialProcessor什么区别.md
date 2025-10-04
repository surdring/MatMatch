## 📊 SimpleMaterialProcessor vs UniversalMaterialProcessor

### **核心区别对比表**

| 维度 | **SimpleMaterialProcessor** ✅ 已实现 | **UniversalMaterialProcessor** 🔜 待实现 |
|------|-------------------------------------|----------------------------------------|
| **使用场景** | ETL离线批处理 | 在线API实时查询 |
| **输入数据** | Oracle原始数据（Dict格式） | 用户上传的物料描述（String） |
| **输出类型** | `MaterialsMaster` ORM对象 | `ParsedQuery` Pydantic模型 |
| **知识库加载** | 一次性加载（ETL启动时） | 动态加载 + 缓存（5秒TTL） |
| **缓存策略** | 简单内存缓存 | 带TTL的自动刷新缓存 |
| **处理透明化** | 无（内部使用） | 有（返回processing_steps） |
| **类别检测** | 基础版 | 增强版（支持置信度阈值） |
| **属性提取** | 单一类别 | 支持类别特定规则 |
| **同义词替换** | 简单分词匹配 | 支持品牌识别和保留 |
| **对称处理** | ✅ 核心算法实现 | ✅ 完全复用（确保一致性） |

---

### **1️⃣ SimpleMaterialProcessor（已实现）**

#### **定位**
```python
"""简化版物料处理器 - 为ETL离线批处理设计"""
```

#### **职责范围**
- ✅ **ETL Transform阶段专用**
- ✅ 处理Oracle批量数据
- ✅ 生成`MaterialsMaster`对象用于入库
- ✅ 实现4步对称处理算法核心逻辑

#### **关键特点**
```python
# 1. 输入：Oracle原始数据字典
data = {
    'erp_code': 'MAT001',
    'material_name': '六角螺栓',
    'specification': 'M8*20',
    'model': '304',
    # ... 其他Oracle字段
}

# 2. 输出：MaterialsMaster ORM对象
material: MaterialsMaster = processor.process_material(data)

# 3. 包含的字段
material.normalized_name      # 标准化名称
material.attributes          # 提取的属性（JSONB）
material.detected_category   # 检测到的类别
material.category_confidence # 置信度
```

#### **使用示例（ETL管道中）**
```python
# backend/etl/etl_pipeline.py
class ETLPipeline:
    def __init__(self, ...):
        self.processor = SimpleMaterialProcessor(pg_session)
    
    async def _process_batch(self, batch: List[Dict]) -> List[MaterialsMaster]:
        """Transform阶段：对称处理"""
        processed = []
        for raw_data in batch:
            # 使用SimpleMaterialProcessor
            material = self.processor.process_material(raw_data)
            processed.append(material)
        return processed
```

---

### **2️⃣ UniversalMaterialProcessor（待实现）**

#### **定位**
```python
"""通用物料处理器 - 为在线API实时查询设计"""
```

#### **职责范围**
- 🔜 **在线API查询专用**
- 🔜 处理用户输入的物料描述文本
- 🔜 生成`ParsedQuery`对象用于相似度计算
- 🔜 提供处理透明化（返回处理步骤）
- 🔜 支持动态规则和词典（热更新）

#### **关键特点**
```python
# 1. 输入：用户输入的文本描述
description = "六角螺栓 M8*20 304不锈钢"

# 2. 输出：ParsedQuery Pydantic模型
parsed_query: ParsedQuery = await processor.process_material_description(
    description=description,
    category_hint=None  # 可选的类别提示
)

# 3. 包含的字段（更丰富）
parsed_query.standardized_name   # 标准化名称
parsed_query.attributes          # 提取的属性
parsed_query.detected_category   # 检测到的类别
parsed_query.confidence          # 置信度
parsed_query.full_description    # 构建的完整描述
parsed_query.processing_steps    # 处理步骤记录（透明化）⭐
```

#### **增强功能**

##### **1. 处理透明化**
```python
parsed_query.processing_steps = [
    "步骤1: 检测到类别'螺栓螺钉'，置信度0.85",
    "步骤2: 全角转半角 '６' → '6'",
    "步骤3: 同义词替换 '不锈钢' → '304'",
    "步骤4: 提取属性 {'规格': 'M8*20', '材质': '304'}"
]
```

##### **2. 动态缓存机制**
```python
class UniversalMaterialProcessor:
    def __init__(self, db_session: AsyncSession):
        self._rules_cache = {}
        self._synonyms_cache = {}
        self._last_cache_update = None
        self._cache_ttl = 5  # 5秒TTL
    
    async def _ensure_cache_fresh(self):
        """确保缓存新鲜度（支持热更新）"""
        if (not self._last_cache_update or 
            datetime.now() - self._last_cache_update > timedelta(seconds=self._cache_ttl)):
            await self._reload_knowledge_base()
```

##### **3. 类别特定处理**
```python
# 根据检测到的类别，应用不同的规则
async def _apply_category_synonyms(self, text: str, category: str) -> str:
    """应用类别特定的同义词词典"""
    synonyms = await self._get_active_synonyms(category)
    # 只替换适用于该类别的同义词
    ...

async def _extract_category_attributes(self, text: str, category: str) -> Dict[str, str]:
    """基于类别特定的动态规则提取属性"""
    rules = await self._get_active_extraction_rules(category)
    # 只应用适用于该类别的规则
    ...
```

---

### **3️⃣ 对称处理的保证机制**

#### **核心原则**
```python
# SimpleMaterialProcessor和UniversalMaterialProcessor
# 必须使用完全相同的4步算法！

# ✅ 相同的算法流程
步骤1: 智能分类检测
步骤2: 文本标准化（全角半角、去空格）
步骤3: 同义词替换（Hash表O(1)查找）
步骤4: 属性提取（正则表达式）

# ✅ 相同的知识库
- 同一个extraction_rules表
- 同一个synonyms表
- 同一个knowledge_categories表

# ✅ 验证方法
运行 backend/scripts/verify_etl_symmetry.py
目标: ≥99.9%一致性
```

#### **复用策略**
```python
# UniversalMaterialProcessor将复用SimpleMaterialProcessor的核心方法
class UniversalMaterialProcessor(SimpleMaterialProcessor):
    """
    继承SimpleMaterialProcessor，增强为API服务
    
    复用的方法:
    - _normalize_text()        # 文本标准化
    - _apply_synonyms()        # 同义词替换
    - _extract_attributes()    # 属性提取
    - _detect_category()       # 分类检测
    
    新增的方法:
    - _ensure_cache_fresh()    # 缓存管理
    - _record_processing_step() # 透明化记录
    - process_material_description() # API入口
    """
```

---

### **4️⃣ 使用场景对比**

#### **SimpleMaterialProcessor使用场景**
```python
# 场景: ETL全量同步
async def etl_full_sync():
    processor = SimpleMaterialProcessor(pg_session)
    await processor.load_knowledge_base()  # 一次性加载
    
    # 批量处理20万条数据
    async for batch in extract_from_oracle():
        materials = [processor.process_material(data) for data in batch]
        await bulk_insert(materials)
```

#### **UniversalMaterialProcessor使用场景**
```python
# 场景: 在线API批量查重
@app.post("/api/v1/materials/batch_search_from_file")
async def batch_search_from_file(file: UploadFile):
    processor = UniversalMaterialProcessor(db_session)
    calculator = SimilarityCalculator(db_session)
    
    # 读取Excel
    df = pd.read_excel(file.file)
    
    results = []
    for _, row in df.iterrows():
        # 对称处理
        parsed_query = await processor.process_material_description(
            description=row['物料描述']
        )
        
        # 相似度查询
        similar_materials = await calculator.find_similar_materials(
            parsed_query=parsed_query,
            limit=10
        )
        
        results.append({
            'input': row['物料描述'],
            'parsed_query': parsed_query,  # ⭐ 处理透明化
            'results': similar_materials
        })
    
    return results
```

---

### **5️⃣ 总结**

| 处理器 | 核心定位 | 关键价值 |
|--------|---------|---------|
| **SimpleMaterialProcessor** | ETL离线处理器 | ✅ 实现对称处理算法核心逻辑<br>✅ 为UniversalMaterialProcessor提供基础 |
| **UniversalMaterialProcessor** | API在线处理器 | ✅ 复用对称处理算法<br>✅ 增加动态缓存和透明化<br>✅ 适配在线查询场景 |

**关键关系**：
```
SimpleMaterialProcessor（已实现）
    ↓ 提供核心算法
UniversalMaterialProcessor（待实现）
    ↓ 继承/复用
确保对称处理一致性 ✅