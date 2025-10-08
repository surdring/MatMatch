# 开发者入职指南

**项目**: MatMatch - 智能物料查重系统  
**适用对象**: 加入项目的新AI开发助手或人类开发者  
**最后更新**: 2025-10-08  
**文档版本**: 2.2

---

## 📖 目录

1. [快速开始（3分钟版）](#-快速开始3分钟版)
2. [学习路径](#-学习路径)
3. [核心文档体系](#-核心文档体系)
4. [关键代码模块详解](#️-关键代码模块详解)
5. [关键知识点深度解析](#-关键知识点深度解析)
6. [重要架构决策](#-重要架构决策)
7. [项目当前状态](#-项目当前状态)
8. [环境配置完全指南](#-环境配置完全指南)
9. [交接验证清单](#-交接验证清单)
10. [常见问题和注意事项](#-常见问题和注意事项)
11. [开发规范](#-开发规范)
12. [按任务类型查找文档](#-按任务类型查找文档)
13. [快速开始模板](#-快速开始模板)

---

## 🚀 快速开始（3分钟版）

### 如果你只有3分钟，只需要这3份核心文档：

| # | 文档 | 路径 | 用途 | 阅读时长 |
|---|------|------|------|----------|
| 1️⃣ | **需求规格说明** | `specs/main/requirements.md` | 了解需求 | 1小时 |
| 2️⃣ | **技术设计文档** | `specs/main/design.md` | 了解架构 | 2-3小时 |
| 3️⃣ | **任务分解文档** | `specs/main/tasks.md` ⭐ | 了解当前进度和性能优化 | 1小时 |

**阅读顺序**: 1️⃣ → 2️⃣ → 3️⃣

**补充文档**：
- `README.md` - 项目概述和快速使用指南 (30分钟)
- `.gemini_logs/` - 详细的开发过程日志（按需查阅）

**⚠️ 文档管理原则（单一事实来源）**：
- ✅ 所有进度信息都在 `tasks.md` 中维护
- ✅ 所有架构信息都在 `design.md` 中维护
- ✅ 所有需求信息都在 `requirements.md` 中维护
- ❌ 不要创建 `STATUS.md`、`PROGRESS.md`、`TODO.md` 等冗余文档

---

## 🎓 学习路径

### 第一天：快速上手（3-4小时）

**推荐学习顺序**:
```
1. README.md - 项目概述                              (30分钟)
   ↓
2. specs/main/requirements.md - 核心需求             (1小时)
   ↓
3. specs/main/design.md 第2.0节 - 核心算法原理      (1小时)
   ↓
4. specs/main/tasks.md - 项目进度和你的任务         (1小时)
```

**环境设置**:
- 📖 **完整配置指南**: [`docs/configuration_guide.md`](configuration_guide.md)
- 虚拟环境激活：`.\venv\Scripts\activate` (Windows)
- 数据库配置：创建`backend/.env`文件
- 运行知识库初始化脚本
- 验证数据库连接

**代码探索**:
- 浏览已完成任务的代码结构
- 运行已有的测试用例
- 查看实施日志了解实现细节

### 第二天：深入理解（4-6小时）

**深入阅读**:
```
1. specs/main/design.md - 你的任务相关章节        (2小时)
   ↓
2. 浏览已完成的代码模块                           (1小时)
   ↓
3. 阅读相关实施日志                               (1小时)
   ↓
4. 环境设置和验证                                 (1-2小时)
```

**重点关注**:
- 你的任务相关的design.md详细章节
- 依赖任务的交付物和接口
- 相关的实施日志

### 第三天起：开始开发

**代码实践**:
```
1. 编写Spec（规格说明）
   - 输入输出定义
   - 依赖接口
   - 数据流描述
   - 性能要求

2. 编写Test（测试用例）
   - 核心功能测试（5-8个）
   - 边界情况测试（5-7个）
   - 集成测试（如需要）

3. 实现代码
   - 创建文件结构
   - 实现核心逻辑
   - 编写测试
   - 代码审查

4. Review（验收）
   - 运行所有测试
   - 性能基准测试
   - 代码质量检查
   - 文档完善
```

---

## 📚 核心文档体系

### 🎯 Tier 1: 核心规范文档（必读）

| 文档 | 路径 | 内容 | 维护频率 |
|------|------|------|----------|
| **需求规格说明** | `specs/main/requirements.md` | 业务需求、用户故事、验收标准、术语表 | 每个里程碑 |
| **技术设计文档** | `specs/main/design.md` | 系统架构、技术选型、数据库设计、API定义、算法原理 | 每个里程碑 |
| **任务分解文档** | `specs/main/tasks.md` ⭐ | 项目里程碑、任务划分、S.T.I.R.规范、验收标准 | 每周 |

#### 1. **需求规格说明书**
- **文件**: `specs/main/requirements.md`
- **用途**: 了解项目的业务需求、用户故事、验收标准
- **重点关注**:
  - 第2节：用户故事和使用场景
  - 第3节：功能需求（FR-*编号）
  - 第4节：非功能需求（性能、安全、可维护性）
  - 附录A：业务术语表

#### 2. **技术设计文档**
- **文件**: `specs/main/design.md`
- **用途**: 理解系统架构、技术选型、核心算法
- **重点关注**:
  - 第1.1节：已完成基础设施集成指南
  - 第2节：后端设计（API、核心算法、数据库）
  - 第2.0节：核心算法原理（必读！）
  - 第2.2节：核心业务逻辑类设计
  - 第2.3节：数据库表结构设计
  - 第3节：前端设计（如果开发前端）
  - 附录：对称处理详细规范

#### 3. **任务分解文档**
- **文件**: `specs/main/tasks.md`
- **用途**: 了解项目进度、任务划分、验收标准（单一事实来源 SSOT）
- **重点关注**:
  - 第1.1节：项目里程碑和当前进度
  - 第2节：具体任务分解（S.T.I.R.方法）
  - 你要承担的具体任务的完整描述
  - 依赖关系和交付物清单

### 📖 Tier 2: 项目说明文档（推荐）

| 文档 | 路径 | 内容 | 目标读者 |
|------|------|------|----------|
| **项目README** | `README.md` | 项目概述、快速开始、核心算法、项目结构 | 所有人 |
| **配置指南** | `docs/configuration_guide.md` | 完整的环境和数据库配置 | 开发者 |

#### 4. **项目README**
- **文件**: `README.md`
- **用途**: 快速了解项目、环境设置、快速开始
- **重点关注**:
  - 项目概述和当前进度
  - 核心算法原理（简化版）
  - 快速开始步骤
  - 项目结构说明

### 📋 Tier 3: 实施日志（历史记录）

| 目录 | 内容 | 用途 |
|------|------|------|
| `.gemini_logs/2025-10-03/` | Phase 0基础设施建设日志 | 了解知识库构建过程 |
| `.gemini_logs/2025-10-04/` | Phase 1-3数据管道和API实施日志 | 了解ETL和API实现细节 |

#### 5. **已完成任务的实施日志**
- **目录**: `.gemini_logs/2025-10-04/`
- **关键文件**:
  - **Phase 1日志**:
    - `15-00-00-Task1.3完整实施过程日志.md` - Phase 1的完整实施过程
    - `14-00-00-Task1.3完成总结报告.md` - Phase 1任务成果
    - `18-00-00-移除硬编码数据量修正.md` - 重要的架构决策和修正
  - **Phase 2日志** ⭐:
    - `19-00-00-Task2.1通用物料处理器实现.md` - UniversalMaterialProcessor实现过程
    - `22-00-00-Task2.2相似度计算器实现.md` - SimilarityCalculator实现过程
    - `Phase2完成总结报告.md` - Phase 2完整成果总结（推荐必读）
  - **Phase 3日志** ⭐:
    - `23-00-00-Task3.1-FastAPI核心服务框架实施.md` - FastAPI框架实现
    - `24-00-00-Task3.2-批量查重API实施.md` - 批量查重API实现
- **用途**: 了解项目历史、已解决的问题、架构决策

---

## 🗂️ 关键代码模块详解

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

**文件说明**:
- `backend/models/materials.py` - ORM模型定义（7张核心表）
- `backend/models/base.py` - 基础类和Mixin
- `backend/database/session.py` - 数据库会话管理

#### Oracle连接层
```
backend/adapters/
├── oracle_adapter.py          # 轻量级Oracle连接适配器
└── __init__.py                # OracleConnectionAdapter类

backend/core/
├── config.py                  # 配置管理（数据库、Oracle、ETL）
└── __init__.py
```

**文件说明**:
- `backend/adapters/oracle_adapter.py` - 轻量级Oracle连接适配器
- `backend/core/config.py` - 配置管理

#### ETL数据管道
```
backend/etl/
├── etl_pipeline.py            # ETL主管道（E-T-L三阶段）
├── material_processor.py      # SimpleMaterialProcessor（对称处理算法）
├── etl_config.py              # ETL配置
├── exceptions.py              # ETL异常定义
└── __init__.py
```

**文件说明**:
- `backend/etl/etl_pipeline.py` - ETL主管道（E-T-L三阶段）
- `backend/etl/material_processor.py` - SimpleMaterialProcessor（对称处理算法）
- `backend/etl/etl_config.py` - ETL配置
- `backend/etl/exceptions.py` - ETL异常定义

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

**文件说明**:
- `backend/core/processors/material_processor.py` - UniversalMaterialProcessor（527行）
- `backend/core/calculators/similarity_calculator.py` - SimilarityCalculator（503行）
- `backend/core/schemas/material_schemas.py` - Pydantic数据模型

#### API服务层 ⭐ Phase 3新增
```
backend/api/
├── main.py                        # FastAPI主应用
├── exceptions.py                  # 自定义异常类
├── exception_handlers.py          # 全局异常处理器
├── dependencies.py                # 依赖注入系统
├── middleware.py                  # 中间件体系
├── routers/
│   ├── health.py                  # 健康检查路由
│   └── materials.py               # 物料查重路由
├── services/
│   └── file_processing_service.py # 文件处理服务
├── schemas/
│   └── batch_search_schemas.py    # 批量查重Schema
└── utils/
    └── column_detection.py        # 列名检测工具
```

#### 工具脚本
```
backend/scripts/
├── run_etl_full_sync.py              # 全量同步
├── verify_etl_symmetry.py            # 对称性验证
├── check_oracle_total_count.py      # Oracle数据检查
└── truncate_materials_master.py     # 数据清空工具
```

**文件说明**:
- `backend/scripts/run_etl_full_sync.py` - 全量同步脚本
- `backend/scripts/verify_etl_symmetry.py` - 对称性验证脚本
- `backend/scripts/check_oracle_total_count.py` - Oracle数据检查

#### 测试代码
```
backend/tests/
├── test_etl_pipeline.py                          # ETL管道核心功能测试
├── test_etl_edge_cases.py                        # 边界情况测试
├── test_symmetric_processing.py                 # 对称处理测试
├── test_oracle_adapter_refactored.py             # Oracle适配器测试
├── test_universal_material_processor.py          # ⭐ UniversalMaterialProcessor（21个测试）
├── test_similarity_calculator.py                 # ⭐ SimilarityCalculator（26个测试）
├── test_api_framework.py                         # ⭐ API框架测试（19个测试）
├── test_batch_search_api.py                      # ⭐ 批量查重API测试（28个测试）
└── integration/                                  # ⭐ 集成测试
    ├── test_similarity_performance.py            #    性能测试（9个测试）
    ├── test_similarity_accuracy.py               #    准确率测试（5个测试）
    └── test_api_integration.py                   #    API集成测试（15个测试）
```

---

## 🔑 关键知识点深度解析

### 1. 对称处理原则（Symmetric Processing）⭐⭐⭐

**定义**: ETL离线处理和在线API查询使用完全相同的算法。

**为什么重要**:
- ✅ 确保数据一致性
- ✅ 保证查询结果可预测
- ✅ 简化系统维护

**实现方式**:
- `SimpleMaterialProcessor`类封装4步处理算法
- ETL管道的Transform阶段使用此类
- 在线API通过`UniversalMaterialProcessor`也使用此类

**验证方法**:
- 运行`verify_etl_symmetry.py`脚本
- 目标：≥99.9%一致性
- 当前结果：100%一致性（1000样本验证）

**参考文档**: 
- `specs/main/design.md` 附录A - 对称处理详细规范

### 2. 4步处理流程 ⭐⭐⭐

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

**关键数据**:
- **Step 1**: 类别检测（基于1,594个分类关键词）
- **Step 2**: 文本规范化（全角半角、大小写、标点符号）
- **Step 3**: 同义词替换（基于27,408个词典）
- **Step 4**: 属性提取（基于6条正则表达式规则）

**参考文档**: 
- `specs/main/design.md` 第2.0节 - 核心算法原理

### 3. E-T-L三阶段架构 ⭐⭐

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

**三阶段说明**:
- **Extract**: 从Oracle提取数据（多表JOIN）
- **Transform**: 对称处理、数据清洗、验证
- **Load**: 批量写入PostgreSQL（事务管理）

**参考文档**: 
- `specs/main/design.md` 第2.2.4节 - ETL设计

### 4. 数据库设计要点 ⭐⭐

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

**参考文档**: 
- `specs/main/design.md` 第2.3节 - 数据库表结构设计
- `backend/models/base.py` - Mixin设计
- `backend/models/materials.py` - 现有表定义

### 5. S.T.I.R.开发方法 ⭐⭐

- **Spec**: 编写规格说明（输入输出、接口、数据流）
- **Test**: 编写测试用例（核心功能、边界情况）
- **Implement**: 实现代码
- **Review**: 代码审查和验收

**参考文档**: 
- `specs/main/tasks.md` 第2.2节 - S.T.I.R.规范

### 6. 技术栈

**后端**:
- Python 3.11+
- FastAPI（Web框架）
- SQLAlchemy 2.0+（异步ORM）
- PostgreSQL 14+（主数据库）
- Oracle Database（数据源）
- Pydantic（配置和验证）

**前端（待开发）**:
- Vue.js 3
- Vite
- Element Plus
- Pinia（状态管理）

**算法**:
- PostgreSQL pg_trgm（三元组模糊匹配）
- 正则表达式（属性提取）
- Hash表（同义词替换）

---

## 📌 重要架构决策

### 决策1: ETL应导入所有状态的物料数据
- ❌ **错误**：`WHERE enablestate = 2`（只导入已启用）
- ✅ **正确**：无过滤条件（导入所有状态）
- **原因**: 业务过滤由应用层处理，数据层保持完整性

### 决策2: Task 1.2定位为轻量级通用适配器
- **职责**: 连接管理、通用查询执行、缓存、重试
- **不负责**: 业务查询逻辑（如多表JOIN）
- **原因**: 可复用性，未来可用于其他Oracle查询场景

### 决策3: 避免硬编码数据量
- ❌ **错误**：文档中写"168,409条"
- ✅ **正确**：写"Oracle ERP全部物料基础数据"
- **原因**: 数据是动态变化的，文档描述能力而非瞬时状态

**参考日志**:
- `.gemini_logs/2025-10-04/18-00-00-移除硬编码数据量修正.md`

---

## 📊 项目当前状态

### ✅ 已完成（Phase 0-3）

#### Phase 0 + Phase 1: 数据基础设施
- ✅ PostgreSQL数据库设计（7张表）
- ✅ Oracle连接适配器（轻量级、可复用）
- ✅ ETL全量同步管道（>24,000条/分钟）
- ✅ 对称处理算法（SimpleMaterialProcessor）
- ✅ 知识库（6条规则、27,408个同义词、1,594个分类）
- ✅ 数据导入（Oracle ERP全部物料基础数据）

#### Phase 2: 核心算法集成 ✅ 2025-10-04完成

**Task 2.1: UniversalMaterialProcessor** ✅ 100%完成
- ✅ **核心实现**: `backend/core/processors/material_processor.py`（527行）
- ✅ **单元测试**: `backend/tests/test_universal_material_processor.py`（21个测试，100%通过，0.70秒）
- ✅ **完成时间**: 2025-10-04 21:00

**关键特性**:
- ✅ 动态知识库加载（从PostgreSQL，支持热更新）
- ✅ 5秒TTL缓存机制（自动刷新）
- ✅ 4步对称处理流程（类别检测 → 标准化 → 同义词 → 属性提取）
- ✅ 处理透明化（返回processing_steps，便于调试）
- ✅ 类别提示支持（category_hint参数）
- ✅ 缓存管理方法（get_cache_stats, clear_cache）

**性能指标**:
- 对称处理一致性: 100%（与SimpleMaterialProcessor，1000样本验证）
- 单次处理时间: <50ms
- 知识库: 6条规则、27,408个同义词、1,594个分类

**Task 2.2: SimilarityCalculator** ✅ 100%完成
- ✅ **核心实现**: `backend/core/calculators/similarity_calculator.py`（503行）
- ✅ **单元测试**: `backend/tests/test_similarity_calculator.py`（26个单元测试，100%通过，0.53秒）
- ✅ **集成测试**: 
  - `backend/tests/integration/test_similarity_performance.py`（9个性能测试）
  - `backend/tests/integration/test_similarity_accuracy.py`（5个准确率测试）
- ✅ **完成时间**: 2025-10-04 23:00

**关键特性**:
- ✅ 多字段加权相似度算法（name 40% + description 30% + attributes 20% + category 10%）
- ✅ PostgreSQL pg_trgm索引优化（GIN索引预筛选 + JSONB运算符）
- ✅ JSONB属性相似度计算（共同属性值相似度）
- ✅ LRU+TTL缓存机制（60秒TTL，1000条容量）
- ✅ 批量查询支持（异步并发优化）
- ✅ 权重动态调整（运行时可配置）

**性能指标**:
- ✅ 平均响应时间: 116.76ms（目标≤500ms，超额达成）
- ✅ Top-10准确率: 100%（目标≥90%，超额达成）
- ✅ Top-1准确率: 98%
- ✅ 索引利用率: ≥95%

**实施日志**:
- ✅ `.gemini_logs/2025-10-04/19-00-00-Task2.1通用物料处理器实现.md`
- ✅ `.gemini_logs/2025-10-04/22-00-00-Task2.2相似度计算器实现.md`
- ✅ `.gemini_logs/2025-10-04/Phase2完成总结报告.md` ⭐ 强烈推荐

#### Phase 3: API服务开发 ✅ 2025-10-05（100%完成）

**Task 3.1: FastAPI核心服务框架** ✅ 100%完成
- ✅ **核心实现**（8个核心文件，1,051行）:
  - `backend/api/main.py` - FastAPI主应用（173行）
  - `backend/api/exceptions.py` - 自定义异常类（118行）
  - `backend/api/exception_handlers.py` - 全局异常处理器（203行）
  - `backend/api/dependencies.py` - 依赖注入系统（211行）
  - `backend/api/middleware.py` - 中间件体系（154行）
  - `backend/api/routers/health.py` - 健康检查路由（192行）
- ✅ **完成时间**: 2025-10-04

**核心功能**:
- ✅ FastAPI应用初始化和配置
- ✅ 数据库连接依赖注入（UniversalMaterialProcessor、SimilarityCalculator）
- ✅ CORS跨域配置（允许 http://localhost:3000）
- ✅ 全局异常处理（5种自定义异常 + 统一错误响应格式）
- ✅ 请求日志中间件（请求ID追踪、耗时记录）
- ✅ 健康检查端点（4个端点：/、/health、/health/readiness、/health/liveness）
- ✅ API文档自动生成（Swagger UI + ReDoc）

**测试覆盖**:
- ✅ `backend/tests/test_api_framework.py` - 19个单元测试（100%通过）
- ✅ `backend/tests/integration/test_api_integration.py` - 15个集成测试（100%通过）
- ✅ **总测试**: 45/45（100%通过率）

**性能指标**:
- ✅ 测试通过率: 100% (45/45)
- ✅ 健康检查响应: <50ms
- ✅ 并发处理: 10个并发无问题
- ✅ 警告修复: 从21个降到0个

**参考文档**:
- `.gemini_logs/2025-10-04/23-00-00-Task3.1-FastAPI核心服务框架实施.md` ⭐

**Task 3.2: 批量查重API** ✅ 100%完成
- ✅ **核心实现**（4个核心文件，1,073行）:
  - `backend/api/routers/materials.py` - 批量查重路由（216行）
  - `backend/api/services/file_processing_service.py` - 文件处理服务（319行）
  - `backend/api/schemas/batch_search_schemas.py` - 批量查重Schema（253行）
  - `backend/api/utils/column_detection.py` - 智能列名检测工具（285行）
- ✅ **测试基础设施**: `backend/tests/fixtures/excel_fixtures.py`（269行）
- ✅ **完成时间**: 2025-10-05
- ✅ **实施用时**: 5小时（预估8小时，提前完成）

**核心功能**:
- ✅ Excel文件上传接收（支持.xlsx/.xls）
- ✅ 文件格式验证和安全检查（类型/大小/内容验证）
- ✅ **智能列名检测**（4种方式）:
  - 方式1: 用户手动指定（精确控制）
  - 方式2: 系统自动检测（便捷性，默认）
  - 方式3: 列索引/Excel列标识（无标题行）
  - 方式4: 混合模式（灵活性）
- ✅ **必需字段验证**（名称、规格型号、单位）
- ✅ 批量物料描述解析和组合
- ✅ 对称处理（调用UniversalMaterialProcessor）
- ✅ 相似度查询（调用SimilarityCalculator）
- ✅ 批量结果封装和返回
- ✅ 错误处理和进度反馈

**关键特性**:
- ✅ Excel文件解析（支持.xlsx和.xls，使用pandas + openpyxl/xlrd）
- ✅ 智能列名检测（自动检测、手动指定、模糊匹配、列索引）
- ✅ 必填字段验证（名称、规格型号、单位3个字段必需）
- ✅ 灵活列名匹配（不区分大小写、去除空格、模糊匹配、优先级匹配）
- ✅ 批量处理和错误处理（单行失败不影响整体）
- ✅ 集成UniversalMaterialProcessor和SimilarityCalculator

**测试覆盖**:
- ✅ `backend/tests/test_batch_search_api.py` - 28个测试（100%通过）
  - 文件验证测试（7个）
  - 必填列验证测试（15个）⭐
  - 数据处理测试（6个）

**性能指标**:
- ✅ 测试通过率: 100% (28/28)
- ✅ 处理速度目标: ≥ 3条/秒（100条 ≤ 30秒）
- ✅ 内存使用目标: ≤ 512MB
- ✅ 并发支持目标: 5个并发请求

**依赖问题修复**:
- ❌ `python-Levenshtein` 在Python 3.13编译失败
- ✅ 替换为 `rapidfuzz>=3.8.0`（性能更好，兼容性强）
- ✅ 新增 `xlrd==2.0.1`（.xls文件支持）
- ✅ 新增 `python-multipart==0.0.20`（FastAPI文件上传）

**参考文档**:
- `.gemini_logs/2025-10-04/24-00-00-Task3.2-批量查重API实施.md` ⭐ 详细的实施规范

**Task 3.3: 其他API端点实现** ✅ 100%完成
- ✅ **核心实现**（3个核心文件，880行）:
  - `backend/api/schemas/material_schemas.py` - 物料查询Schema（263行，10个模型）
  - `backend/api/services/material_query_service.py` - 物料查询服务（219行，6个方法）
  - `backend/api/routers/materials.py` - 新增5个API端点（+398行）
- ✅ **完成时间**: 2025-10-05
- ✅ **实施用时**: 3小时（预估3天，大幅提前）

**核心功能**:
- ✅ GET /api/v1/materials/{erp_code} - 查询单个物料
- ✅ GET /api/v1/materials/{erp_code}/details - 查询完整详情
- ✅ GET /api/v1/materials/{erp_code}/similar - 查找相似物料
- ✅ GET /api/v1/materials/search - 关键词搜索
- ✅ GET /api/v1/categories - 分类列表

**性能测试结果** ⭐:
- ✅ 查询单个物料: 23.63ms（目标200ms，**提前88%**）
- ✅ 查询完整详情: 4.40ms（目标300ms，**提前99%**）
- ✅ 搜索物料: 4.80ms（目标500ms，**提前99%**）
- ✅ 获取分类列表: 4.21ms（目标200ms，**提前98%**）
- ✅ 查找相似物料: 163.88ms（目标500ms，**提前67%**）

**关键修复**:
- ✅ 修复`ServiceUnavailableException`参数错误（4处）
- ✅ 修复`UniversalMaterialProcessor`方法调用（`_load_knowledge_base()`）
- ✅ 修复路由前缀重复问题
- ✅ 添加缺失的异常类（`MaterialNotFoundError`, `ValidationError`）

**参考文档**:
- `.gemini_logs/2025-10-05/Task3.3-完成总结.md` ⭐ 完整的实施报告
- `.gemini_logs/2025-10-05/Task3.3-性能测试完成.md` ⭐ 性能测试详情

**最近Bug修复** (2025-10-08):
- ✅ 前端查重结果刷新问题：修复文件选择和批量查重开始时结果未清空的问题
- ✅ 单位和分类显示问题：修复ERP相似物料的unit_name和category_name显示
- ✅ 分类检测优化：改进关键词生成算法，提升分类检测准确率
- ✅ 查重判定逻辑：修复使用full_description进行语义等价对比

**测试工具**:
- ✅ `backend/scripts/generate_batch_test_excel.py` - 批量查重测试数据生成器
  - 覆盖7大场景：完全重复、疑似重复、高度相似、不重复、分类检测、边界情况、复杂规格
  - 包含20+测试用例，适用于全流程验证

**Task 4.4: 快速查询功能** ✅ 100%完成
- ✅ **核心实现**: `frontend/src/components/MaterialSearch/QuickQueryForm.vue`（237行）
- ✅ **主页面集成**: `frontend/src/views/MaterialSearch.vue` - Tab切换功能（~103行新增）
- ✅ **完成时间**: 2025-10-07

**核心功能**:
- ✅ el-tabs标签页切换（批量查重 / 快速查询 ⚡）
- ✅ 单条物料输入表单（名称、规格型号、单位、分类）
- ✅ Element Plus表单验证（3个必填字段）
- ✅ 临时Excel文件自动生成（使用xlsx库）
- ✅ 复用批量查重逻辑（materialStore.uploadAndSearch）

**关键特性**:
- ✅ 快速实现（4小时，符合预估）
- ✅ 代码复用率高（≥90%）
- ✅ 用户体验统一
- ✅ 维护成本低
- ✅ 完整的TypeScript类型支持
- ✅ 详细的测试点注释（[T.1.1]-[T.2.4]）

**性能指标**:
- 查询响应时间: <1秒 ✅（目标: ≤1秒）
- 代码复用率: ≥90% ✅（目标: ≥80%）
- 新增代码量: ~340行

### 🔜 待开发（Phase 5）

- 🔜 **Task 4.5**: 管理后台功能实现（可选）
- 🔜 **Task 5.1**: 系统集成测试（推荐下一步）

---

## 📋 环境配置完全指南

### 1. 虚拟环境

**虚拟环境路径**: `D:\develop\python\MatMatch\venv`（项目根目录下的venv文件夹）

```bash
# 激活虚拟环境
# Windows:
.\venv\Scripts\activate

# 或使用完整路径:
D:\develop\python\MatMatch\venv\Scripts\activate

# Linux/Mac:
source venv/bin/activate
```

### 2. 数据库连接

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

### 3. 依赖安装

```bash
# 激活虚拟环境（见上方）
.\venv\Scripts\activate  # Windows

# 安装后端依赖
pip install -r backend/requirements.txt

# 安装数据库工具依赖
pip install -r database/requirements.txt
```

### 4. 知识库初始化

```bash
# 方法1：使用一键验证脚本（推荐）
cd database
python run_full_import_verification.py

# 方法2：手动初始化
python database/init_postgresql_rules.py
```

### 5. 数据同步

```bash
# 全量同步Oracle物料数据
.\venv\Scripts\python.exe backend\scripts\run_etl_full_sync.py --batch-size 1000
```

**详细配置指南**: 参见 `docs/configuration_guide.md`

---

## ✅ 交接验证清单

### 新开发者应该完成的验证步骤

- [ ] 1. 阅读本文档（`developer_onboarding_guide.md`）
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

# 3. 运行所有测试
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

### 问题5: Python依赖安装失败
**错误**: `Failed to build installable wheels`

**解决**:
- 确保使用正确的Python版本（3.11+）
- 使用虚拟环境
- 参考`requirements.txt`中的版本约束

---

## 🎯 开发规范

### 代码规范

1. **遵循已有代码风格**
   - 使用类型注解（Type Hints）
   - 异步优先（async/await）
   - 详细的docstring文档
   - 遵循PEP 8代码规范

2. **命名约定**
   - 类名：PascalCase（如`MaterialProcessor`）
   - 函数/方法：snake_case（如`process_material`）
   - 常量：UPPER_SNAKE_CASE（如`MAX_BATCH_SIZE`）
   - 私有方法：前缀下划线（如`_internal_method`）

3. **错误处理**
   - 使用自定义异常类
   - 详细的错误消息
   - 适当的日志记录
   - 优雅的失败和恢复

### 文档规范

1. **代码注释**
   - 复杂逻辑必须注释
   - 为什么（Why）比什么（What）更重要
   - 关联到设计文档的章节

2. **Git提交**
   - 清晰的提交消息
   - 关联到任务编号
   - 小步提交，频繁推送

3. **测试要求**
   - 核心功能测试覆盖率≥95%
   - 边界情况测试
   - 集成测试
   - 性能测试（如有要求）

### 沟通和协作

**问题反馈**:

1. **技术问题**
   - 优先查阅设计文档和实施日志
   - 查看已有代码的实现方式
   - 记录问题和解决方案

2. **设计决策**
   - 重大架构变更需要讨论
   - 记录决策原因和备选方案
   - 更新设计文档

3. **进度汇报**
   - 定期更新`specs/main/tasks.md`任务状态
   - 及时报告阻塞问题
   - 记录实施过程日志

---

## 🔍 按任务类型查找文档

### 如果你要开发 **Phase 2 - 核心算法集成** ✅ 已完成

**已完成的参考代码**:
- ✅ `backend/core/processors/material_processor.py` - UniversalMaterialProcessor（527行）
- ✅ `backend/core/calculators/similarity_calculator.py` - SimilarityCalculator（503行）
- ✅ `backend/tests/test_universal_material_processor.py` - 21个单元测试
- ✅ `backend/tests/test_similarity_calculator.py` - 26个单元测试
- ✅ `backend/tests/integration/test_similarity_performance.py` - 9个性能测试
- ✅ `backend/tests/integration/test_similarity_accuracy.py` - 5个准确率测试

**必读文档**:
1. `specs/main/design.md` 第2.2.1-2.2.2节（UniversalMaterialProcessor、SimilarityCalculator）
2. `backend/etl/material_processor.py`（已实现的SimpleMaterialProcessor）
3. `.gemini_logs/2025-10-04/15-00-00-Task1.3完整实施过程日志.md`（对称处理实现）

**关键概念**:
- 对称处理原则
- 4步处理流程
- pg_trgm三元组算法

**实施日志**:
- ✅ `.gemini_logs/2025-10-04/19-00-00-Task2.1通用物料处理器实现.md`
- ✅ `.gemini_logs/2025-10-04/22-00-00-Task2.2相似度计算器实现.md`
- ✅ `.gemini_logs/2025-10-04/Phase2完成总结报告.md`

**关键成果**:
- 对称处理一致性：100%（1000样本验证）
- 查询性能：平均116.76ms（目标≤500ms）
- Top-10准确率：100%（目标≥90%）

### 如果你要开发 **Phase 3 - API服务** 🔄 进行中

**Task 3.1 已完成** ✅:
- ✅ `backend/api/main.py` - FastAPI主应用
- ✅ `backend/api/exceptions.py` - 自定义异常类
- ✅ `backend/api/exception_handlers.py` - 全局异常处理器
- ✅ `backend/api/dependencies.py` - 依赖注入系统
- ✅ `backend/api/middleware.py` - 中间件体系
- ✅ `backend/api/routers/health.py` - 健康检查路由
- ✅ 45个测试全部通过（19个单元测试 + 15个集成测试）

**Task 3.2 已完成** ✅:
- ✅ `backend/api/routers/materials.py` - 批量查重路由
- ✅ `backend/api/services/file_processing_service.py` - 文件处理服务
- ✅ `backend/api/schemas/batch_search_schemas.py` - 批量查重Schema
- ✅ `backend/api/utils/column_detection.py` - 智能列名检测
- ✅ 28个测试全部通过

**Task 3.3 已完成** ✅:
- ✅ `backend/api/schemas/material_schemas.py` - 物料查询Schema
- ✅ `backend/api/services/material_query_service.py` - 物料查询服务
- ✅ `backend/api/routers/materials.py` - 5个新API端点
- ✅ 5个性能测试全部通过（响应时间远低于目标值）

**必读文档**:
1. `specs/main/design.md` 第2.1节（API Endpoint定义）
2. `specs/main/requirements.md` 用户故事1-2（批量查重功能）
3. `backend/models/materials.py`（数据模型）

**关键概念**:
- FastAPI框架
- Pydantic Schema
- 批量文件处理
- 异步处理

**关键理解**:
- FastAPI框架使用（已搭建完成）
- Pydantic Schema定义（参考已完成的health.py和material_schemas.py）
- 批量文件处理流程
- 异步处理和进度反馈
- 复用UniversalMaterialProcessor和SimilarityCalculator
- RESTful API设计规范
- 服务层和路由层分离

### 如果你要开发 **Phase 4 - 前端界面**

**必读**:
- ✅ `specs/main/design.md` 第3节 - 前端设计
- ✅ `specs/main/design.md` 第3.3节 - 数据流与交互逻辑
- ✅ `specs/main/requirements.md` 用户故事1-4 - UI交互需求

**关键概念**:
- Vue.js 3 + Vite
- Pinia状态管理
- Element Plus组件

**关键理解**:
- Vue.js 3 + Vite技术栈
- Pinia状态管理
- Element Plus UI组件
- 文件上传和结果展示组件

### 如果你要进行 **数据库扩展**

**必读文档**:
1. `specs/main/design.md` 第2.3节（数据库表结构）
2. `backend/models/base.py`（Mixin设计）
3. `backend/models/materials.py`（现有表定义）

**关键概念**:
- SQLAlchemy 2.0异步ORM
- Mixin继承（时间戳、软删除、同步状态）
- JSONB字段使用

### 如果你要优化 **ETL性能**

**必读文档**:
1. `backend/etl/etl_pipeline.py`（ETL主管道）
2. `.gemini_logs/2025-10-04/14-00-00-Task1.3完成总结报告.md`（性能基准）
3. `specs/main/design.md` 第2.2.4节（ETL设计）

**关键概念**:
- E-T-L三阶段
- 批量处理
- 异步并发
- 连接池优化

---

## 🚀 快速开始模板

### 开始新任务的标准流程

```markdown
1. 创建任务日志文件
   .gemini_logs/YYYY-MM-DD/HH-MM-SS-TaskX.X任务名称.md

2. 编写Spec（规格说明）
   - 输入输出定义
   - 依赖接口
   - 数据流描述
   - 性能要求

3. 编写Test（测试用例）
   - 核心功能测试（5-8个）
   - 边界情况测试（5-7个）
   - 集成测试（如需要）

4. 实现代码
   - 创建文件结构
   - 实现核心逻辑
   - 编写测试
   - 代码审查

5. Review（验收）
   - 运行所有测试
   - 性能基准测试
   - 代码质量检查
   - 文档完善

6. 更新文档
   - 更新specs/main/tasks.md任务状态
   - 更新README.md（如需要）
   - 生成完成总结报告
```

---

## 📚 推荐学习资源

### 技术文档
- SQLAlchemy 2.0: https://docs.sqlalchemy.org/
- FastAPI: https://fastapi.tiangolo.com/
- PostgreSQL pg_trgm: https://www.postgresql.org/docs/current/pgtrgm.html
- Pydantic: https://docs.pydantic.dev/

### 项目特定
- 对称处理详细规范: `specs/main/design.md` 附录A
- S.T.I.R.开发方法: `specs/main/tasks.md` 第2.2节

---

## 🔑 快速参考

### 核心概念文档位置

| 概念 | 文档位置 |
|------|----------|
| **对称处理原则** | `specs/main/design.md` 附录A / 本文档第5.1节 |
| **4步处理流程** | `specs/main/design.md` 第2.0节 / 本文档第5.2节 |
| **E-T-L架构** | `specs/main/design.md` 第2.2.4节 / 本文档第5.3节 |
| **S.T.I.R.方法** | `specs/main/tasks.md` 第2.2节 / 本文档第5.5节 |
| **数据库设计** | `specs/main/design.md` 第2.3节 / 本文档第5.4节 |
| **API设计** | `specs/main/design.md` 第2.1节 |

### 关键代码位置

| 功能 | 代码文件 |
|------|----------|
| **对称处理算法** | `backend/etl/material_processor.py` |
| **通用物料处理器** | `backend/core/processors/material_processor.py` |
| **相似度计算器** | `backend/core/calculators/similarity_calculator.py` |
| **ETL管道** | `backend/etl/etl_pipeline.py` |
| **Oracle适配器** | `backend/adapters/oracle_adapter.py` |
| **ORM模型** | `backend/models/materials.py` |
| **配置管理** | `backend/core/config.py` |
| **数据库会话** | `backend/database/session.py` |
| **FastAPI主应用** | `backend/api/main.py` |
| **物料查询服务** | `backend/api/services/material_query_service.py` |
| **物料查询Schema** | `backend/api/schemas/material_schemas.py` |

---

## 📞 联系方式

**项目负责人**: 信息自动化部郑学恩

**获取帮助**:

1. **优先查阅文档**
   - 设计文档可能已有答案
   - 实施日志记录了类似问题的解决方案

2. **查看已有代码**
   - 参考类似功能的实现
   - 复用已验证的模式和算法

3. **记录问题和解决方案**
   - 在`.gemini_logs/`中创建日志
   - 更新文档避免后续重复问题

**注意事项**:
- 保持代码和文档的一致性
- 遵循对称处理原则
- 注重性能和可维护性
- 记录重要决策和修正

---

## 📊 文档更新记录

| 日期 | 更新内容 | 影响范围 |
|------|----------|----------|
| 2025-10-08 | 前端交互优化和Bug修复完成 | 本文档v2.2、tasks.md |
| 2025-10-05 | Task 3.3完成，Phase 3全部完成 | 本文档v2.1、tasks.md |
| 2025-10-05 | 合并三个入职文档为一个 | 本文档v2.0 |
| 2025-10-04 | Task 3.1-3.2完成，更新Phase 3状态 | 本文档、tasks.md |
| 2025-10-04 | Phase 2完成，更新核心算法状态 | 本文档、design.md |
| 2025-10-04 | 创建开发者入职和交接文档 | 本文档v1.0 |
| 2025-10-04 | 修正硬编码数据量问题 | README.md、ETL脚本 |
| 2025-10-04 | Task 1.3完成，更新Phase 1状态 | tasks.md、design.md |

---

**交接完成标志**: 新开发者能够独立完成一个小型任务（如添加一个新的API endpoint或扩展一个算法）

**项目进度**: Phase 0-4已完成（90%），Phase 5待开发（10%）

**文档版本**: 2.2  
**最后更新**: 2025-10-08（更新前端Bug修复和测试工具）  
**维护者**: 项目团队
