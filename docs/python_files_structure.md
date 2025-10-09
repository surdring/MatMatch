# Python文件结构说明文档

**文档版本**: v1.0  
**最后更新**: 2025-10-08  
**维护者**: AI-DEV  
**基于**: Python文件冗余分析报告 (2025-10-08)

---

## 📋 文档目的

本文档提供项目中所有Python文件的完整结构说明，帮助开发者快速了解：
1. 每个Python文件的职责和用途
2. 文件之间的依赖关系
3. 推荐的使用场景和注意事项

---

## 📊 文件统计总览

| 目录 | Python文件数 | 主要职责 | 状态 |
|-----|------------|---------|------|
| `backend/api/` | 17 | API接口层 | ✅ 生产就绪 |
| `backend/core/` | 6 | 核心业务逻辑 | ✅ 生产就绪 |
| `backend/etl/` | 5 | ETL数据管道 | ✅ 生产就绪 |
| `backend/tests/` | 18 | 自动化测试 | ✅ 完整覆盖 |
| `backend/scripts/` | 3 | 运维工具 | ✅ 生产就绪 |
| `backend/adapters/` | 2 | 数据源适配器 | ✅ 生产就绪 |
| `backend/models/` | 3 | 数据模型 | ✅ 生产就绪 |
| `backend/database/` | 3 | 数据库管理 | ✅ 生产就绪 |
| `database/` | 7 | 独立数据工具链 | ✅ 生产就绪 |
| **根目录** | 3 | 系统启动脚本 | ✅ 生产就绪 |
| `temp/` | 8 | 临时开发工具 | ⚠️ 开发调试用 |

**总计**: 约75个Python文件

---

## 🗂️ 详细文件说明

### 1. 根目录启动脚本 (3个)

#### 1.1 系统启动与管理

| 文件 | 用途 | 使用场景 | 依赖 |
|-----|------|---------|------|
| **`start_all.py`** | 系统全面启动器 | 开发/生产环境启动 | 知识库、后端服务 |
| **`run_complete_pipeline.py`** | 完整ETL流程 | 全量数据同步 | Oracle、PostgreSQL、知识库 |
| **`run_incremental_pipeline.py`** | 增量ETL流程 | 定时增量同步 | Oracle、PostgreSQL、知识库 |

#### 📘 使用说明

**`start_all.py` - 系统启动器**
```bash
# 功能：检查知识库 → 必要时生成知识库 → 启动后端服务
python start_all.py

# 执行流程：
# 1. 检查知识库是否存在（PostgreSQL中的3张表）
# 2. 如果缺失，自动调用知识库生成脚本
# 3. 启动FastAPI后端服务（uvicorn）
```

**`run_complete_pipeline.py` - 完整ETL**
```bash
# 功能：清空表 → 全量同步 → 生成知识库
python run_complete_pipeline.py

# 适用场景：
# - 首次部署
# - 数据结构变更
# - 数据质量问题修复后的重建
```

**`run_incremental_pipeline.py` - 增量ETL**
```bash
# 功能：仅同步变更数据 → 更新知识库
python run_incremental_pipeline.py

# 适用场景：
# - 日常定时同步（推荐）
# - Windows任务计划程序调度
# - 节省资源和时间
```

---

### 2. 后端核心业务代码 (`backend/core/`) - 6个文件

#### 2.1 配置管理

| 文件 | 职责 | 关键类/函数 | 配置项 |
|-----|------|----------|-------|
| **`config.py`** | 统一配置中心 | `Settings` (Pydantic) | 数据库、服务器、知识库、日志 |

**配置说明**：
- 使用Pydantic的`BaseSettings`进行环境变量管理
- 支持`.env`文件和环境变量
- 所有模块通过此文件获取配置（单一事实来源）

#### 2.2 物料处理器 (`processors/`)

| 文件 | 处理器类 | 使用场景 | 依赖 |
|-----|---------|---------|------|
| **`material_processor.py`** | `UniversalMaterialProcessor` | API在线查询 | PostgreSQL知识库 |
| **`processing_utils.py`** | 处理工具函数 | 文本标准化、属性提取 | - |

**核心特性**：
- **动态知识库加载**：从PostgreSQL加载，支持热更新
- **5秒TTL缓存机制**：自动刷新知识库
- **4步对称处理流程**：
  1. 类别检测
  2. 标准化（去停用词、全角转半角）
  3. 同义词替换
  4. 属性提取
- **处理透明化**：返回`processing_steps`，便于调试
- **类别提示支持**：`category_hint`参数提高准确率

**性能指标**：
- 单次处理时间：<50ms
- 对称处理一致性：100%（与ETL处理器一致）
- 知识库规模：6条规则、27,408个同义词、1,594个分类

#### 2.3 相似度计算器 (`calculators/`)

| 文件 | 计算器类 | 算法 | 使用场景 |
|-----|---------|------|---------|
| **`similarity_calculator.py`** | `SimilarityCalculator` | 混合型（模糊+精确） | 物料查重 |
| **`similarity_config.py`** | `SimilarityConfig` | 权重配置 | 相似度调优 |

**混合型算法说明**：
```python
最终得分 = (
    name_similarity_score * 0.6 +    # 物料名称模糊匹配（pg_trgm）
    exact_match_bonus +              # 属性精确匹配加分（JSONB）
    penalty                          # 类别不匹配惩罚
)
```

**权重配置**（可调优）：
- `name_weight`: 0.6（名称相似度权重）
- `exact_match_bonus`: 0.15（每个属性精确匹配加分）
- `category_penalty`: 0.2（类别不匹配惩罚）
- `threshold`: 0.55（相似度阈值）

#### 2.4 数据模型 (`schemas/`)

| 文件 | 数据结构 | 用途 |
|-----|---------|------|
| **`material_schema.py`** | `MaterialBase`, `MaterialQuery` | 物料数据模型 |
| **`query_schema.py`** | `QueryRequest`, `QueryResponse` | API请求/响应 |

---

### 3. ETL数据管道 (`backend/etl/`) - 5个文件

#### 3.1 ETL核心引擎

| 文件 | 核心类 | 职责 | 状态 |
|-----|-------|------|------|
| **`etl_pipeline.py`** | `ETLPipeline` | ETL主流程编排 | ✅ 生产就绪 |
| **`material_processor.py`** | `SimpleMaterialProcessor` | ETL离线处理 | ✅ 对称处理 |
| **`etl_config.py`** | `ETLConfig` | ETL配置管理 | ✅ 生产就绪 |
| **`exceptions.py`** | ETL异常类 | 错误处理 | ✅ 完整 |

#### 📘 ETLPipeline详细说明

**主要方法**：

| 方法 | 功能 | 使用场景 |
|-----|------|---------|
| `run_full_sync()` | 全量同步 | 清空表+全量导入 |
| `run_incremental_sync()` | 增量同步 | 仅同步变更（基于`MODIFYDATE`） |
| `extract_from_oracle()` | 数据抽取 | 从Oracle ERP提取数据 |
| `transform()` | 数据转换 | 调用`SimpleMaterialProcessor`标准化 |
| `load_to_postgresql()` | 数据加载 | 批量写入PostgreSQL |

**核心流程图**：
```
Oracle ERP → extract → transform (SimpleMaterialProcessor) → load → PostgreSQL
                          ↓
                    [对称处理算法]
                          ↓
            与UniversalMaterialProcessor保持一致
```

#### 3.2 对称处理原则

**两个处理器的关系**：

| 处理器 | 场景 | 处理时机 | 数据来源 |
|-------|------|---------|---------|
| `SimpleMaterialProcessor` | ETL离线 | 定时批量 | Oracle ERP |
| `UniversalMaterialProcessor` | API在线 | 实时查询 | 用户输入 |

**关键特性**：
- ✅ **相同算法**：两个处理器使用完全相同的标准化算法
- ✅ **相同知识库**：共享PostgreSQL中的知识库（3张表）
- ✅ **一致性验证**：通过`test_symmetric_processing.py`保证100%一致

**为什么需要两个处理器？**
1. **性能考虑**：ETL批量处理不需要缓存，API查询需要缓存
2. **依赖隔离**：ETL可独立运行，不依赖API服务
3. **可测试性**：两个处理器可独立测试

---

### 4. API接口层 (`backend/api/`) - 17个文件

#### 4.1 主应用

| 文件 | 职责 | 核心内容 |
|-----|------|---------|
| **`main.py`** | FastAPI应用入口 | 路由注册、中间件、异常处理 |
| **`dependencies.py`** | 依赖注入 | 数据库会话、处理器实例 |
| **`middleware.py`** | 请求中间件 | 日志、性能监控、CORS |
| **`exceptions.py`** | 自定义异常 | API异常类定义 |
| **`exception_handlers.py`** | 异常处理器 | 统一错误响应格式 |

#### 4.2 API路由 (`routers/`)

| 文件 | 路由前缀 | 核心端点 | 功能 |
|-----|---------|---------|------|
| **`materials.py`** | `/api/v1/materials` | `/batch-search`, `/{erp_code}`, `/search` | 物料查重和查询 |
| **`admin.py`** | `/api/v1/admin` | 规则/同义词/分类/ETL/缓存管理 | 管理后台API（15个端点）🔐 |
| **`health.py`** | `/health` | `/`, `/readiness`, `/liveness` | 健康检查 |

**核心端点说明**：

```python
# 批量查询（Excel上传）
POST /api/v1/materials/batch-search
files: {"file": "物料清单.xlsx"}
params: {
    "query_column": "物料描述",
    "limit": 10
}

# 查询单个物料
GET /api/v1/materials/{erp_code}

# 查找相似物料
GET /api/v1/materials/{erp_code}/similar

# 关键词搜索
GET /api/v1/materials/search?keyword=不锈钢

# 管理后台API（需要认证）🔐
POST /api/v1/admin/extraction-rules  # 创建提取规则
GET /api/v1/admin/synonyms  # 查询同义词
POST /api/v1/admin/cache/refresh  # 刷新缓存
```

#### 4.3 数据模型 (`schemas/`)

| 文件 | 数据结构 | 用途 |
|-----|---------|------|
| **`material_schemas.py`** | `MaterialResponse`, `MaterialDetailResponse` | 物料查询响应 |
| **`batch_search_schemas.py`** | `BatchSearchRequest`, `BatchSearchResponse` | 批量查重 |
| **`admin_schemas.py`** | `ExtractionRuleCreate`, `SynonymCreate` | 管理后台Schema |

#### 4.4 业务服务 (`services/`)

| 文件 | 服务类 | 职责 |
|-----|-------|------|
| **`file_processing_service.py`** | `FileProcessingService` | 批量处理、Excel解析 |
| **`material_query_service.py`** | `MaterialQueryService` | 物料查询业务逻辑 |
| **`admin_service.py`** | `AdminService` | 管理后台业务逻辑（885行）🔐 |

#### 4.5 工具类 (`utils/`)

| 文件 | 功能 | 核心函数 |
|-----|------|---------|
| **`column_detection.py`** | 智能列名检测 | `detect_columns()`, `fuzzy_match_column()` |

#### 4.6 认证与授权 (`dependencies_auth.py`) 🔐

**核心功能**：
- API Token认证（Bearer + X-API-Key）
- 权限验证（role检查）
- IP白名单验证（可选）
- 操作审计日志
- 访问频率限制（60次/分钟）

**核心函数**：
```python
async def verify_admin_token() -> dict:
    """验证管理员Token"""
    
async def verify_ip_whitelist() -> bool:
    """验证IP白名单"""
    
async def require_admin_auth() -> dict:
    """组合依赖 - 完整认证"""
    
class AuditLogger:
    """操作审计日志"""
    @staticmethod
    async def log_admin_action(...)
```

**安全文档**：`backend/api/ADMIN_API_SECURITY.md`（285行）

---

### 5. 数据源适配器 (`backend/adapters/`) - 2个文件

| 文件 | 适配器类 | 数据源 | 用途 |
|-----|---------|-------|------|
| **`oracle_adapter.py`** | `OracleAdapter` | Oracle ERP | ETL数据抽取 |

**核心方法**：
```python
class OracleAdapter:
    async def fetch_materials(self, since: datetime = None):
        """
        从Oracle提取物料数据
        
        参数:
        - since: 增量同步起始时间（可选）
        
        返回:
        - List[Dict]: 物料数据列表
        """
        pass
    
    async def get_total_count(self) -> int:
        """获取物料总数"""
        pass
```

**连接配置**（从`backend/core/config.py`）：
```python
ORACLE_USER = "your_user"
ORACLE_PASSWORD = "your_password"
ORACLE_DSN = "host:port/service_name"
```

---

### 6. 数据库管理 (`backend/database/`) - 3个文件

| 文件 | 职责 | 核心类/函数 |
|-----|------|----------|
| **`session.py`** | 数据库会话管理 | `get_db()`, `AsyncSession` |
| **`migrations.py`** | 数据库迁移 | `create_tables()`, `create_indexes()` |

**会话管理**：
```python
# 依赖注入方式
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

# 使用示例
@app.get("/api/v1/materials")
async def search_materials(db: AsyncSession = Depends(get_db)):
    # 使用db进行数据库操作
    pass
```

**数据库迁移**：
```python
# 创建表结构
await migrations.create_tables()

# 创建索引（GIN索引用于模糊查询）
await migrations.create_indexes_concurrent()
```

---

### 7. 数据模型定义 (`backend/models/`) - 3个文件

| 文件 | 模型类 | 对应表 | 用途 |
|-----|-------|-------|------|
| **`material.py`** | `Material` | `materials` | 物料主表 |
| **`knowledge_base.py`** | `CategoryKeyword`, `SynonymDictionary`, `ExtractionRule` | 知识库3张表 | 知识库 |

**Material模型**：
```python
class Material(Base):
    __tablename__ = "materials"
    
    id = Column(Integer, primary_key=True)
    erp_code = Column(String(100), unique=True, index=True)
    description = Column(Text)
    standardized_name = Column(Text, index=True)  # GIN索引
    attributes = Column(JSONB)  # 结构化属性
    category = Column(String(100), index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
```

**知识库模型**：
```python
class CategoryKeyword(Base):
    """类别关键词表"""
    __tablename__ = "category_keywords"
    category = Column(String, primary_key=True)
    keywords = Column(JSONB)  # List[str]

class SynonymDictionary(Base):
    """同义词字典表"""
    __tablename__ = "synonym_dictionary"
    standard_term = Column(String, primary_key=True)
    synonyms = Column(JSONB)  # List[str]
    category = Column(String)

class ExtractionRule(Base):
    """属性提取规则表"""
    __tablename__ = "extraction_rules"
    category = Column(String, primary_key=True)
    rules = Column(JSONB)  # Dict[str, Any]
```

---

### 8. 自动化测试 (`backend/tests/`) - 18个文件

#### 8.1 单元测试

| 文件 | 测试对象 | 测试数量 | 覆盖率 |
|-----|---------|---------|-------|
| **`test_universal_material_processor.py`** | `UniversalMaterialProcessor` | 21个测试 | 100% |
| **`test_similarity_calculator.py`** | `SimilarityCalculator` | 15个测试 | 100% |
| **`test_oracle_adapter.py`** | `OracleAdapter` | 8个测试 | 100% |
| **`test_database.py`** | 数据库操作 | 12个测试 | 100% |
| **`test_etl_pipeline.py`** | `ETLPipeline` | 18个测试 | 100% |
| **`test_etl_incremental_sync.py`** | 增量同步 | 10个测试 | 100% |
| **`test_etl_edge_cases.py`** | ETL边界情况 | 12个测试 | 100% |
| **`test_symmetric_processing.py`** | 对称处理一致性 | 5个测试 | 100% |

#### 8.2 API测试

| 文件 | 测试范围 | 测试数量 | 状态 |
|-----|---------|---------|------|
| **`test_api_framework.py`** | API框架基础 | 19个测试 | ✅ |
| **`test_material_query_api.py`** | 物料查询API | 43个测试 | ✅ |
| **`test_batch_search_api.py`** | 批量查重API | 28个测试 | ✅ |
| **`test_admin_extraction_rules_api.py`** | 提取规则管理API | 13个测试 | ✅ |
| **`test_admin_synonyms_api.py`** | 同义词管理API | 18个测试 | ✅ |
| **`test_admin_categories_etl_api.py`** | 分类和ETL监控API | 13个测试 | ✅ |
| **`test_admin_concurrency_performance.py`** | 管理后台并发性能 | 5个测试 | ⚠️ 2个失败 |

#### 8.3 集成测试 (`integration/`)

| 文件 | 测试场景 | 测试数量 | 运行时间 |
|-----|---------|---------|---------|
| **`test_api_integration.py`** | 端到端API集成 | 10个测试 | ~5秒 |
| **`test_similarity_performance.py`** | 相似度性能测试 | 3个测试 | ~10秒 |
| **`test_similarity_accuracy.py`** | 相似度准确性测试 | 8个测试 | ~3秒 |

#### 8.4 测试夹具 (`fixtures/`)

| 文件 | 提供的夹具 | 用途 |
|-----|----------|------|
| **`excel_fixtures.py`** | Excel测试数据 | 批量查重测试 |

**运行测试**：
```bash
# 运行所有测试
pytest backend/tests/

# 运行单元测试
pytest backend/tests/ -m "not integration"

# 运行集成测试
pytest backend/tests/integration/

# 查看覆盖率
pytest --cov=backend --cov-report=html
```

---

### 9. 运维工具脚本 (`backend/scripts/`) - 3个文件

| 文件 | 用途 | 使用场景 |
|-----|------|---------|
| **`check_system_health.py`** | 系统健康检查 | 监控、告警 |
| **`clear_cache.py`** | 清理缓存 | 故障排查 |
| **`database_backup.py`** | 数据库备份 | 定时备份 |

**使用示例**：
```bash
# 检查系统健康状态
python backend/scripts/check_system_health.py

# 清理处理器缓存
python backend/scripts/clear_cache.py

# 数据库备份
python backend/scripts/database_backup.py --output backup_20251008.sql
```

---

### 10. 独立数据工具链 (`database/`) - 7个文件

#### 10.1 核心工具

| 文件 | 职责 | 依赖配置 | 状态 |
|-----|------|---------|------|
| **`material_knowledge_generator.py`** | 知识库生成引擎 | `oracle_config.py` | ✅ 核心 |
| **`generate_and_import_knowledge.py`** | 一键生成并导入 | `oracle_config.py` | ✅ 推荐使用 |
| **`check_oracle_tables.py`** | Oracle表结构检查 | `oracle_config.py` | ✅ 诊断工具 |
| **`test_oracle_connection.py`** | 测试Oracle连接 | `oracle_config.py` | ✅ 诊断工具 |
| **`test_postgresql_connection.py`** | 测试PostgreSQL连接 | 环境变量 | ✅ 诊断工具 |
| **`oracle_config.py`** | Oracle配置和SQL | - | ✅ 配置中心 |
| **`oracledb_connector.py`** | Oracle连接器 | `oracle_config.py` | ✅ 底层驱动 |

#### 10.2 知识库生成流程

**`material_knowledge_generator.py` - 核心生成引擎**

**生成内容**：
1. **类别关键词**（Category Keywords）
   - 从Oracle物料分类表提取
   - 生成文件：`standardized_category_keywords_*.json`

2. **同义词字典**（Synonym Dictionary）
   - 从物料描述中智能提取
   - 使用规则：`"不銹鋼" → "不锈钢"`, `"SUS304" → "304不锈钢"`
   - 生成文件：`standardized_synonym_dictionary_*.json`

3. **属性提取规则**（Extraction Rules）
   - 正则表达式规则，用于提取尺寸、规格等
   - 生成文件：`standardized_extraction_rules_*.json`

**使用方式**：
```bash
# 方法1：直接运行生成器
python database/material_knowledge_generator.py

# 方法2：一键生成并导入（推荐）
python database/generate_and_import_knowledge.py
```

#### 10.3 诊断工具

**检查Oracle连接**：
```bash
python database/test_oracle_connection.py
# 输出：✅ Oracle连接成功 / ❌ 连接失败：[错误信息]
```

**检查PostgreSQL连接**：
```bash
python database/test_postgresql_connection.py
# 输出：✅ PostgreSQL连接成功 / ❌ 连接失败：[错误信息]
```

**检查Oracle表结构**：
```bash
python database/check_oracle_tables.py
# 输出：表名、列数、行数、关键字段列表
```

#### 10.4 配置文件说明

**`oracle_config.py`**
```python
# Oracle连接配置
ORACLE_CONFIG = {
    "user": "your_user",
    "password": "your_password",
    "dsn": "host:port/service_name"
}

# SQL查询语句（用于知识库生成）
MATERIAL_QUERY = """
    SELECT 物料编码, 物料名称, 规格型号, ...
    FROM bd_material
    WHERE 审核状态 = '已审核'
"""
```

**注意**：`database/` 工具链独立于后端服务，使用自己的配置文件。

---

### 11. 临时开发工具 (`temp/`) - 8个文件 ⚠️

| 文件 | 用途 | 状态 | 建议 |
|-----|------|------|------|
| **`check_attributes.py`** | 检查属性提取结果 | 临时 | ⚠️ 调试用 |
| **`check_current_data.py`** | 检查当前数据状态 | 临时 | ⚠️ 调试用 |
| **`check_db.py`** | 快速数据库查询 | 临时 | ⚠️ 调试用 |
| **`check_normalized_name.py`** | 检查标准化结果 | 临时 | ⚠️ 调试用 |
| **`generate_standardized_rules.py`** | 生成标准化规则 | 临时 | ⚠️ 调试用 |
| **`intelligent_rule_generator.py`** | 智能规则生成器 | 临时 | ⚠️ 调试用 |
| **`test_normalize_spec.py`** | 测试规格标准化 | 临时 | ⚠️ 调试用 |

**⚠️ 重要说明**：
- 这些文件是临时开发调试工具，不应在生产环境使用
- 不保证代码质量和维护性
- 建议定期清理

---

## 🔗 文件依赖关系图

### 核心依赖链

```
启动脚本层:
    start_all.py
        ↓
    ├─→ database/generate_and_import_knowledge.py  # 如果知识库不存在
    └─→ backend/api/main.py  # 启动FastAPI服务

API服务层:
    backend/api/main.py
        ↓
    ├─→ backend/api/routers/*  # 路由注册
    ├─→ backend/api/dependencies.py  # 依赖注入
    └─→ backend/api/middleware.py  # 中间件

业务逻辑层:
    backend/api/services/material_service.py
        ↓
    ├─→ backend/core/processors/material_processor.py  # 处理器
    ├─→ backend/core/calculators/similarity_calculator.py  # 计算器
    └─→ backend/database/session.py  # 数据库会话

数据访问层:
    backend/database/session.py
        ↓
    └─→ backend/models/*  # SQLAlchemy模型

ETL数据管道:
    run_complete_pipeline.py / run_incremental_pipeline.py
        ↓
    └─→ backend/etl/etl_pipeline.py
            ↓
        ├─→ backend/adapters/oracle_adapter.py  # Oracle抽取
        ├─→ backend/etl/material_processor.py  # 数据转换
        └─→ backend/database/session.py  # PostgreSQL加载

知识库生成:
    database/generate_and_import_knowledge.py
        ↓
    └─→ database/material_knowledge_generator.py
            ↓
        ├─→ database/oracle_config.py  # Oracle配置
        └─→ database/oracledb_connector.py  # Oracle连接
```

---

## 🎯 推荐使用场景

### 场景1：首次部署系统

**步骤**：
```bash
1. 检查数据库连接
   python database/test_oracle_connection.py
   python database/test_postgresql_connection.py

2. 运行完整ETL流程
   python run_complete_pipeline.py

3. 启动系统（自动检查并生成知识库）
   python start_all.py
```

### 场景2：日常增量同步

**步骤**：
```bash
1. 运行增量ETL（通常由Windows任务计划程序调度）
   python run_incremental_pipeline.py

2. 系统自动更新知识库（5秒TTL缓存自动刷新）
```

### 场景3：开发调试

**步骤**：
```bash
1. 运行单元测试
   pytest backend/tests/test_universal_material_processor.py -v

2. 运行集成测试
   pytest backend/tests/integration/ -v

3. 使用临时工具检查数据
   python temp/check_current_data.py
```

### 场景4：故障排查

**步骤**：
```bash
1. 检查系统健康状态
   python backend/scripts/check_system_health.py

2. 检查Oracle表结构
   python database/check_oracle_tables.py

3. 清理处理器缓存
   python backend/scripts/clear_cache.py

4. 查看日志
   cat backend/logs/app.log
   cat database/logs/etl.log
```

---

## 📝 开发规范

### 1. 文件命名规范

**模块文件**：
- ✅ `material_processor.py` - 清晰的模块名
- ❌ `processor.py` - 太模糊

**测试文件**：
- ✅ `test_material_processor.py` - 与被测试模块对应
- ❌ `test_processor.py` - 不够具体

### 2. 文件职责单一性

每个Python文件应该有明确的单一职责：
- ✅ `similarity_calculator.py` - 只负责相似度计算
- ❌ 在一个文件中混合处理、计算、数据库操作

### 3. 避免循环依赖

**正确的依赖方向**：
```
上层（API） → 中层（业务逻辑） → 下层（数据访问）
```

**错误示例**：
```
❌ models/material.py 导入 api/schemas/material_schemas.py
   （数据层不应依赖API层）
```

### 4. 配置管理

**统一配置中心**：
- ✅ 所有配置从 `backend/core/config.py` 读取
- ❌ 在代码中硬编码配置值

**例外**：
- `database/` 工具链独立运行，使用 `database/oracle_config.py`

---

## 🚨 常见问题

### Q1: 两个物料处理器有什么区别？

**A**: 
- `backend/etl/material_processor.py` - `SimpleMaterialProcessor` - ETL离线批量处理
- `backend/core/processors/material_processor.py` - `UniversalMaterialProcessor` - API在线实时处理
- **关键**：两者使用相同算法，保证对称处理一致性

### Q2: 知识库存储在哪里？

**A**: 知识库存储在PostgreSQL的3张表中：
- `category_keywords` - 类别关键词
- `synonym_dictionary` - 同义词字典
- `extraction_rules` - 属性提取规则

### Q3: 如何更新知识库？

**A**: 有两种方式：
1. **自动更新**：运行 `run_incremental_pipeline.py`，ETL流程会自动重新生成知识库
2. **手动更新**：运行 `database/generate_and_import_knowledge.py`

### Q4: 为什么有 `database/oracle_config.py` 和 `backend/core/config.py` 两个配置文件？

**A**: 
- `database/oracle_config.py` - 用于独立的数据工具链（知识库生成脚本）
- `backend/core/config.py` - 用于后端服务和ETL管道
- **原因**：`database/` 工具链需要独立运行，不依赖后端服务

### Q5: 临时测试脚本（根目录的 `test_*.py`）能删除吗？

**A**: ✅ 可以删除。这些是早期的手动测试脚本，功能已被 `backend/tests/` 中的正式自动化测试覆盖。

---

## 📚 相关文档

- **开发者入职指南**: `docs/developer_onboarding_guide.md`
- **系统原理文档**: `docs/system_principles.md`
- **系统工作流程**: `docs/system_workflow.md`
- **脚本使用手册**: `docs/系统脚本使用手册.md`
- **需求规格说明**: `specs/main/requirements.md`
- **技术设计文档**: `specs/main/design.md`
- **任务分解文档**: `specs/main/tasks.md`

---

---

## 📦 前端文件结构 (`frontend/src/`) - Vue.js应用

### 核心组件和页面

| 文件 | 行数 | 职责 | 状态 |
|-----|------|------|------|
| **`views/Home.vue`** | 120行 | 首页（5个统计项、功能特性展示） | ✅ 生产就绪 |
| **`views/MaterialSearch.vue`** | 999行 | 物料查重主页面（3步向导、结果展示） | ✅ 生产就绪 |
| **`views/Admin.vue`** | 109行 | 管理后台主页面（Tab切换框架） | ✅ 生产就绪 |
| **`components/MaterialSearch/FileUpload.vue`** | ~200行 | 文件上传组件（拖拽、预览） | ✅ 生产就绪 |
| **`components/MaterialSearch/ColumnConfig.vue`** | 390行 | 列名配置组件（智能检测） | ✅ 生产就绪 |
| **`components/MaterialSearch/QuickQueryForm.vue`** | 237行 | 快速查询表单 | ✅ 生产就绪 |
| **`components/Admin/RuleManager.vue`** | 415行 | 规则管理组件 | ✅ 生产就绪 |
| **`components/Admin/SynonymManager.vue`** | 440行 | 同义词管理组件 | ✅ 生产就绪 |
| **`components/Admin/CategoryManager.vue`** | 360行 | 分类管理组件 | ✅ 生产就绪 |
| **`components/Admin/ETLMonitor.vue`** | 415行 | ETL监控组件 | ✅ 生产就绪 |

### 状态管理 (Pinia Stores)

| 文件 | Actions数量 | 职责 |
|-----|-----------|------|
| **`stores/material.ts`** | ~10个 | 物料查询、批量查重状态管理 |
| **`stores/admin.ts`** | 15个 | 管理后台业务逻辑（规则、同义词、分类、ETL） |
| **`stores/user.ts`** | ~5个 | 用户认证、Token管理 |

### API客户端

| 文件 | 端点数量 | 职责 |
|-----|---------|------|
| **`api/request.ts`** | - | Axios封装（拦截器、错误处理） |
| **`api/material.ts`** | 6个 | 物料查询API |
| **`api/admin.ts`** | 15个 | 管理后台API |

### 工具函数和Composables

| 文件 | 行数 | 核心函数 |
|-----|------|---------|
| **`utils/excelUtils.ts`** | 241行 | Excel解析、列检测、数据预览 |
| **`composables/useFileUpload.ts`** | 135行 | 文件上传逻辑 |
| **`composables/useExcelExport.ts`** | 198行 | Excel导出逻辑 |
| **`composables/useResultFilter.ts`** | 147行 | 结果筛选、排序、分页 |

**前端总代码量**: ~8,000行（包含组件、Store、工具函数）

---

## 🔄 文档更新记录

| 日期 | 版本 | 更新内容 | 维护者 |
|-----|------|---------|-------|
| 2025-10-09 | v1.3 | 添加前端文件结构说明（Task 4.1-4.5完成） | AI-DEV |
| 2025-10-09 | v1.2 | 更新Task 4.5管理后台前端完成状态，Phase 4完成100% | AI-DEV |
| 2025-10-08 | v1.1 | 更新Task 3.4管理后台API完成状态，添加认证授权说明 | AI-DEV |
| 2025-10-08 | v1.0 | 初始版本，基于Python文件冗余分析报告 | AI-DEV |

---

**维护者**: AI-DEV  
**下次审查**: 重大功能迭代后或项目完成时

