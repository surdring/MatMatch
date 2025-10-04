# AI开发者交接清单

**项目名称**: MatMatch - 智能物料查重系统  
**交接日期**: 2025-10-04  
**当前阶段**: Phase 1-2已完成，Phase 3进行中（Task 3.1已完成）

---

## 📦 交接文档包

### 🎯 必须提供的核心文档

#### 1. **设计和规范文档**（最重要）

| 文档 | 路径 | 用途 | 优先级 |
|------|------|------|--------|
| 需求规格说明 | `specs/main/requirements.md` | 业务需求、用户故事、验收标准 | ⭐⭐⭐ |
| 技术设计文档 | `specs/main/design.md` | 系统架构、技术选型、算法设计 | ⭐⭐⭐ |
| 任务分解文档 | `specs/main/tasks.md` | 项目进度、任务划分、验收标准 | ⭐⭐⭐ |
| 开发者入职指南 | `docs/developer_onboarding_guide.md` | 新开发者学习路径和规范 | ⭐⭐⭐ |

#### 2. **项目概览文档**

| 文档 | 路径 | 用途 | 优先级 |
|------|------|------|--------|
| 项目README | `README.md` | 项目介绍、快速开始、核心算法 | ⭐⭐ |
| 配置指南 | `docs/configuration_guide.md` | 完整的环境和数据库配置 | ⭐⭐⭐ |

#### 3. **实施日志**（了解历史）

| 文档 | 路径 | 用途 | 优先级 |
|------|------|------|--------|
| Phase 0完成日志 | `.gemini_logs/2025-10-03/` | 基础设施建设历史 | ⭐ |
| Task 1.3实施日志 | `.gemini_logs/2025-10-04/15-00-00-Task1.3完整实施过程日志.md` | ETL管道实施过程 | ⭐⭐ |
| Task 1.3完成报告 | `.gemini_logs/2025-10-04/14-00-00-Task1.3完成总结报告.md` | Phase 1成果总结 | ⭐⭐ |
| 硬编码修正日志 | `.gemini_logs/2025-10-04/18-00-00-移除硬编码数据量修正.md` | 重要架构决策 | ⭐⭐ |
| Task 2.1实施日志 | `.gemini_logs/2025-10-04/19-00-00-Task2.1通用物料处理器实现.md` | UniversalMaterialProcessor实现 | ⭐⭐ |
| Task 2.2实施日志 | `.gemini_logs/2025-10-04/22-00-00-Task2.2相似度计算器实现.md` | SimilarityCalculator实现 | ⭐⭐ |
| Phase 2完成报告 | `.gemini_logs/2025-10-04/Phase2完成总结报告.md` | Phase 2成果总结 | ⭐⭐⭐ |

---

## 🗂️ 关键代码模块

### 已完成的代码（可复用）

#### 数据层
```
backend/models/
├── base.py                    # 基础类和Mixin（时间戳、软删除、同步状态）
├── materials.py               # 7张核心表的ORM模型
└── __init__.py

backend/database/
├── session.py                 # 数据库会话管理（异步）
└── __init__.py
```

#### Oracle连接层
```
backend/adapters/
├── oracle_adapter.py          # 轻量级Oracle连接适配器
└── __init__.py                # OracleConnectionAdapter类

backend/core/
├── config.py                  # 配置管理（数据库、Oracle、ETL）
└── __init__.py
```

#### ETL数据管道
```
backend/etl/
├── etl_pipeline.py            # ETL主管道（E-T-L三阶段）
├── material_processor.py      # SimpleMaterialProcessor（对称处理算法）
├── etl_config.py              # ETL配置
├── exceptions.py              # ETL异常定义
└── __init__.py
```

#### 核心算法模块 ⭐ Phase 2新增
```
backend/core/
├── processors/
│   ├── material_processor.py     # UniversalMaterialProcessor（527行）
│   └── __init__.py
├── calculators/
│   ├── similarity_calculator.py  # SimilarityCalculator（503行）
│   └── __init__.py
├── schemas/
│   └── material_schemas.py       # Pydantic数据模型
└── config.py                      # 配置管理
```

#### 工具脚本
```
backend/scripts/
├── run_etl_full_sync.py              # 全量同步
├── verify_etl_symmetry.py            # 对称性验证
├── check_oracle_total_count.py      # Oracle数据检查
└── truncate_materials_master.py     # 数据清空工具
```

#### 测试代码
```
backend/tests/
├── test_etl_pipeline.py                          # ETL管道核心功能测试
├── test_etl_edge_cases.py                        # 边界情况测试
├── test_symmetric_processing.py                 # 对称处理测试
├── test_oracle_adapter_refactored.py             # Oracle适配器测试
├── test_universal_material_processor.py          # ⭐ UniversalMaterialProcessor（21个测试）
├── test_similarity_calculator.py                 # ⭐ SimilarityCalculator（26个测试）
└── integration/                                  # ⭐ Phase 2集成测试
    ├── test_similarity_performance.py            #    性能测试（9个测试）
    └── test_similarity_accuracy.py               #    准确率测试（5个测试）
```

---

## 🔑 关键知识点

### 1. 对称处理原则（核心概念）⭐⭐⭐

**定义**: ETL离线处理和在线API查询使用完全相同的算法。

**为什么重要**:
- 确保数据一致性
- 保证查询结果可预测
- 简化系统维护

**实现方式**:
- `SimpleMaterialProcessor`类封装4步处理算法
- ETL管道的Transform阶段使用此类
- 未来的在线API也将使用此类

**验证方法**:
- 运行`verify_etl_symmetry.py`脚本
- 目标：≥99.9%一致性
- 当前结果：100%一致性（1000样本验证）

### 2. 4步处理流程⭐⭐⭐

```python
# backend/etl/material_processor.py: SimpleMaterialProcessor

async def process(self, material_data: Dict[str, Any]) -> Dict[str, Any]:
    # Step 1: 类别检测（基于1,594个分类关键词）
    category = await self._detect_category(name, spec)
    
    # Step 2: 文本规范化（全角半角、大小写、标点符号）
    normalized_name = self._normalize_text(name)
    normalized_spec = self._normalize_text(spec)
    
    # Step 3: 同义词替换（基于27,408个词典）
    standardized_name = await self._apply_synonyms(normalized_name)
    standardized_spec = await self._apply_synonyms(normalized_spec)
    
    # Step 4: 属性提取（基于6条正则表达式规则）
    extracted = await self._extract_attributes(standardized_spec, category)
    
    return processed_material
```

### 3. E-T-L三阶段架构⭐⭐

```python
# backend/etl/etl_pipeline.py: ETLPipeline

async def run_full_sync(self):
    # Extract: 从Oracle提取数据（多表JOIN）
    materials = await self._extract_materials_batch(batch_size, offset)
    
    # Transform: 对称处理
    processed = await self._process_batch(materials)
    
    # Load: 批量写入PostgreSQL
    await self._load_batch(processed)
```

### 4. 数据库设计要点⭐⭐

**7张核心表**:
1. `materials_master` - 物料主表（已同步Oracle数据）
2. `material_categories` - 物料分类（已同步）
3. `measurement_units` - 计量单位（已同步）
4. `extraction_rules` - 属性提取规则（6条）
5. `synonyms` - 同义词词典（27,408条）
6. `knowledge_categories` - 知识分类（1,594条）
7. `etl_job_logs` - ETL任务日志

**关键设计**:
- `SyncStatusMixin`: 同步状态管理（source_system, sync_status, last_sync_at）
- `TimestampMixin`: 时间戳管理（created_at, updated_at）
- `SoftDeleteMixin`: 软删除支持（deleted, deleted_at）
- JSONB字段: `structured_attributes`存储提取的属性

### 5. 重要架构决策⭐

**决策1**: ETL应导入所有状态的物料数据
- ❌ 错误：`WHERE enablestate = 2`（只导入已启用）
- ✅ 正确：无过滤条件（导入所有状态）
- **原因**: 业务过滤由应用层处理，数据层保持完整性

**决策2**: Task 1.2定位为轻量级通用适配器
- **职责**: 连接管理、通用查询执行、缓存、重试
- **不负责**: 业务查询逻辑（如多表JOIN）
- **原因**: 可复用性，未来可用于其他Oracle查询场景

**决策3**: 避免硬编码数据量
- ❌ 错误：文档中写"168,409条"
- ✅ 正确：写"Oracle ERP全部物料基础数据"
- **原因**: 数据是动态变化的，文档描述能力而非瞬时状态

---

## 🎯 下一个开发者应该知道的

### Phase 2已完成成果 ✅ 可参考复用

#### Task 2.1: UniversalMaterialProcessor ✅ 已完成
**已完成代码**:
- `backend/core/processors/material_processor.py`（527行）
- `backend/tests/test_universal_material_processor.py`（21个测试，100%通过）

**关键特性**:
- ✅ 动态知识库加载（从PostgreSQL）
- ✅ 5秒TTL缓存机制
- ✅ 4步对称处理流程
- ✅ 处理透明化（返回processing_steps）
- ✅ 类别提示支持

**性能指标**:
- 对称处理一致性: 100%（1000样本验证）
- 单次处理时间: <50ms

#### Task 2.2: SimilarityCalculator ✅ 已完成
**已完成代码**:
- `backend/core/calculators/similarity_calculator.py`（503行）
- `backend/tests/test_similarity_calculator.py`（26个单元测试）
- `backend/tests/integration/test_similarity_performance.py`（9个性能测试）
- `backend/tests/integration/test_similarity_accuracy.py`（5个准确率测试）

**关键特性**:
- ✅ 多字段加权相似度（40% name + 30% desc + 20% attr + 10% cat）
- ✅ PostgreSQL pg_trgm索引优化
- ✅ JSONB属性相似度计算
- ✅ LRU+TTL缓存机制
- ✅ 批量查询支持
- ✅ 权重动态调整

**性能指标**:
- 平均响应时间: 116.76ms（目标≤500ms）
- Top-10准确率: 100%（目标≥90%）
- Top-1准确率: 98%

**实施日志参考**:
- `.gemini_logs/2025-10-04/19-00-00-Task2.1通用物料处理器实现.md`
- `.gemini_logs/2025-10-04/22-00-00-Task2.2相似度计算器实现.md`
- `.gemini_logs/2025-10-04/Phase2完成总结报告.md` ⭐ 强烈推荐

### Phase 3任务进度

#### Task 3.1: FastAPI核心服务框架 ✅ 已完成
**完成日期**: 2025-10-04

**已交付代码**:
- ✅ `backend/api/main.py` - FastAPI主应用（173行）
- ✅ `backend/api/exceptions.py` - 自定义异常类（118行）
- ✅ `backend/api/exception_handlers.py` - 全局异常处理器（203行）
- ✅ `backend/api/dependencies.py` - 依赖注入系统（211行）
- ✅ `backend/api/middleware.py` - 中间件体系（154行）
- ✅ `backend/api/routers/health.py` - 健康检查路由（192行）

**测试覆盖**:
- ✅ `backend/tests/test_api_framework.py` - 19个单元测试（100%通过）
- ✅ `backend/tests/integration/test_api_integration.py` - 15个集成测试（100%通过）

**性能指标**:
- 测试通过率: 100% (45/45)
- 健康检查响应: <50ms
- 并发处理: 10个并发无问题
- 警告修复: 从21个降到0个

**参考文档**:
- `.gemini_logs/2025-10-04/Task_3.1_完成报告.md` ⭐ 详细报告
- `.gemini_logs/2025-10-04/会话日志_Task3.1完成.md` ⭐ 完整过程

#### Task 3.2: 批量查重API实现
**参考文档**:
- `specs/main/design.md` 第2.1节 - /api/materials/batch-search
- `specs/main/requirements.md` 用户故事1和2

**关键点**:
- 集成Phase 2已完成的核心算法
- 支持Excel文件解析（openpyxl）
- 批量处理和进度反馈
- 异步任务队列

---

## 📋 环境和配置

### 必要的环境信息

#### 1. 虚拟环境

**虚拟环境路径**：`D:\develop\python\MatMatch\venv`

```bash
# 激活虚拟环境
# Windows:
.\venv\Scripts\activate
# 或使用完整路径:
D:\develop\python\MatMatch\venv\Scripts\activate

# Linux/Mac:
source venv/bin/activate
```

#### 2. 数据库连接

需要在 `backend/.env` 文件中配置以下连接信息：

**PostgreSQL**（本地开发，主数据库）:
```env
# backend/.env
DATABASE_URL=postgresql+asyncpg://postgres:your_password@localhost:5432/matmatch
```

**Oracle ERP**（生产数据源）:
```env
# backend/.env
ORACLE_HOST=your_oracle_host
ORACLE_PORT=1521
ORACLE_SERVICE_NAME=your_service
ORACLE_USERNAME=your_username
ORACLE_PASSWORD=your_password
```

#### 3. 依赖安装

```bash
# 激活虚拟环境（见上方）
.\venv\Scripts\activate  # Windows

# 安装后端依赖
pip install -r backend/requirements.txt

# 安装数据库工具依赖
pip install -r database/requirements.txt
```

#### 4. 知识库初始化

```bash
# 方法1：使用一键验证脚本（推荐）
cd database
python run_full_import_verification.py

# 方法2：手动初始化
python database/init_postgresql_rules.py
```

#### 5. 数据同步

```bash
# 全量同步Oracle物料数据
.\venv\Scripts\python.exe backend\scripts\run_etl_full_sync.py --batch-size 1000
```

---

## ✅ 交接验证清单

### 新开发者应该完成的验证步骤

- [ ] 1. 阅读`developer_onboarding_guide.md`
- [ ] 2. 阅读`specs/main/requirements.md`核心需求
- [ ] 3. 阅读`specs/main/design.md`第2.0节核心算法
- [ ] 4. 阅读`specs/main/tasks.md`了解当前进度
- [ ] 5. 设置开发环境（Python、PostgreSQL、虚拟环境）
- [ ] 6. 运行知识库初始化脚本
- [ ] 7. 测试数据库连接
- [ ] 8. 运行已有测试用例（`pytest backend/tests/`）
- [ ] 9. 浏览已完成的代码模块
- [ ] 10. 阅读你要承担的任务的详细设计

### 验证命令

```bash
# 1. 测试PostgreSQL连接
python -c "from backend.database.session import get_session; import asyncio; asyncio.run(get_session().__anext__())"

# 2. 测试Oracle连接
.\venv\Scripts\python.exe backend\scripts\check_oracle_total_count.py

# 3. 运行测试
pytest backend/tests/ -v

# 4. 检查知识库数据
python -c "
from backend.database.session import get_session
from sqlalchemy import text
import asyncio

async def check():
    async with get_session() as session:
        result = await session.execute(text('SELECT COUNT(*) FROM synonyms'))
        print(f'同义词数量: {result.scalar()}')
        result = await session.execute(text('SELECT COUNT(*) FROM extraction_rules'))
        print(f'提取规则数量: {result.scalar()}')
        result = await session.execute(text('SELECT COUNT(*) FROM knowledge_categories'))
        print(f'分类关键词数量: {result.scalar()}')

asyncio.run(check())
"
```

---

## 🚨 常见问题和注意事项

### 问题1: Oracle连接失败
**错误**: `DPY-3010: connections to this database server version are not supported in thin mode`

**解决**:
- Oracle thick mode已启用（`oracledb.init_oracle_client()`）
- 确保安装了Oracle Instant Client
- 检查DSN配置是否正确

### 问题2: PostgreSQL表不存在
**错误**: `relation "xxx" does not exist`

**解决**:
- 运行数据库迁移脚本
- 检查`backend/models/`中的模型定义
- 使用SQLAlchemy的`Base.metadata.create_all()`创建表

### 问题3: 对称处理验证失败
**错误**: 一致性低于99.9%

**解决**:
- 检查SimpleMaterialProcessor的实现
- 确保知识库数据完整
- 查看`.gemini_logs/`中的实施日志了解正确实现

### 问题4: ETL性能低
**指标**: 处理速度<1000条/分钟

**优化**:
- 增大批处理大小（`batch_size`）
- 检查数据库连接池配置
- 使用`asyncio.gather`并发处理
- 参考已实现的ETL管道（>24,000条/分钟）

---

## 📞 支持和反馈

### 如何获取帮助

1. **优先查阅文档**
   - 设计文档可能已有答案
   - 实施日志记录了类似问题的解决方案

2. **查看已有代码**
   - 参考类似功能的实现
   - 复用已验证的模式和算法

3. **记录问题和解决方案**
   - 在`.gemini_logs/`中创建日志
   - 更新文档避免后续重复问题

---

## 📚 推荐学习资源

### 技术文档
- SQLAlchemy 2.0: https://docs.sqlalchemy.org/
- FastAPI: https://fastapi.tiangolo.com/
- PostgreSQL pg_trgm: https://www.postgresql.org/docs/current/pgtrgm.html
- Pydantic: https://docs.pydantic.dev/

### 项目特定
- 对称处理详细规范: `specs/main/design.md` 附录
- S.T.I.R.开发方法: `specs/main/tasks.md` 第2.2节

---

**交接完成标志**: 新开发者能够独立完成一个小型任务（如添加一个新的API endpoint或扩展一个算法）

**项目进度**: Phase 0-3.1已完成（50%），Phase 3.2-5待开发（50%）

**文档版本**: 1.2  
**最后更新**: 2025-10-04（Phase 3.1完成后更新）

