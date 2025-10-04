# 任务分解文档: 智能物料查重工具

**版本:** 1.0
**状态:** 待执行  
**关联需求:** `specs/main/requirements.md` (v2.1)  
**关联设计:** `specs/main/design.md` (v2.0)  

## 1. 概述

本文档基于已批准的需求规格说明书v2.1和技术设计文档v2.0，将智能物料查重工具的开发工作分解为具体的、可执行的任务。所有任务遵循S.T.I.R.开发周期（Spec → Test → Implement → Review）。

### 🎯 已完成基础设施 (Phase 0)

基于**Oracle真实ERP物料数据**，项目已完成以下关键基础设施建设：
- **✅ 数据分析基础**：完整的Oracle ERP数据分析和分类体系
- **✅ 规则引擎**：高置信度(88%-98%)的属性提取规则，支持全角半角字符处理
- **✅ 词典系统**：完整的同义词词典，包含大小写变体和字符标准化
- **✅ AI知识库分类**：基于Oracle真实数据动态生成的分类关键词
- **✅ 算法实现**：Hash表标准化、正则表达式结构化、Trigram相似度算法
- **✅ 工具链**：从数据分析到PostgreSQL导入的完整自动化流程
- **✅ 测试验证**：SQL/Python双导入对称性验证，确保数据一致性

**性能基准**（基于当前数据验证）：
- 数据规模: Oracle物料数据（动态增长）
- 规则质量: 多条规则，置信度88%-98%
- 词典覆盖: 同义词词典（动态维护）
- 分类数量: AI知识库分类（动态生成）
- 处理性能: ≥5000条/分钟
- 匹配精度: 91.2%准确率，85%召回率（持续优化）

### 1.1 项目里程碑

| 里程碑 | 描述 | 预期完成时间 | 关键交付物 |
|--------|------|-------------|-----------|
| **M0: 基础设施** | ✅ 已完成 | 已完成 | 规则引擎、词典系统、算法库、测试工具 |
| **M1: 数据管道** | 完成数据库设计和ETL管道 | Week 1-2 | PostgreSQL数据库、ETL脚本、Oracle适配器 |
| **M2: 核心算法集成** | 集成已完成算法到生产系统 | Week 3-4 | 通用处理器、相似度计算器 |
| **M3: API服务** | 完成后端API和业务逻辑 | Week 5-6 | FastAPI服务、API文档 |
| **M4: 前端界面** | 实现用户界面和交互 | Week 7-8 | Vue.js前端应用 |
| **M5: 集成测试** | 系统集成和性能优化 | Week 9-10 | 完整系统、测试报告 |

## 2. 任务分解

### 📊 Phase 1: 数据基础建设 (M1) ✅ 已完成

#### Task 1.1: PostgreSQL数据库设计与实现 ✅ 已完成
**优先级:** P0 (关键路径)  
**预估工作量:** 3天  
**负责人:** 后端开发  
**依赖关系:** 无  
**状态:** ✅ 已完成 (2025-10-03)

**Spec (规格):**
- 基于design.md第2.3节设计，创建完整的PostgreSQL数据库结构
- 实现materials_master、material_categories、measurement_units等核心表
- 创建extraction_rules、synonyms、knowledge_categories等规则管理表
- 设置适当的索引和约束（pg_trgm GIN索引、JSONB索引等）

**Test (测试标准):**
- [x] 所有表结构符合设计文档规范
- [x] 主键、外键约束正确设置
- [x] pg_trgm索引创建成功，查询性能 ≤ 500ms
- [x] 支持JSONB属性存储和查询
- [x] 数据库连接池配置正确
- [x] knowledge_categories表使用TEXT[]类型存储关键词

**Implement (实现要点):**
- ✅ 使用SQLAlchemy ORM定义模型 (`backend/models/materials.py`)
- ✅ 创建数据库迁移脚本 (`backend/database/migrations.py`)
- ✅ 配置连接池和查询优化 (`backend/core/config.py`)
- ✅ 实现SQL/Python双导入方案，确保数据一致性
- ✅ 实现对称性验证工具 (`backend/scripts/verify_symmetry.py`)
- ✅ 创建集成测试脚本 (`database/run_full_import_verification.py`)

**Review (验收标准):**
- ✅ 数据库结构review通过
- ✅ 性能测试达标（已验证6条规则、38,068个同义词、1,594个分类）
- ✅ 代码review无重大问题
- ✅ 对称性验证100%通过

**交付物:**
- `backend/models/materials.py` - ORM模型定义
- `backend/database/migrations.py` - 数据库迁移脚本
- `database/postgresql_import_*.sql` - SQL导入脚本
- `database/run_full_import_verification.py` - 集成测试脚本
- `backend/scripts/verify_symmetry.py` - 对称性验证脚本

---

#### Task 1.2: 轻量级Oracle连接适配器 ✅ 已完成
**优先级:** P0 (关键路径)  
**预估工作量:** 1天（简化重构）  
**负责人:** 后端开发  
**依赖关系:** 无  
**状态:** ✅ 已完成 (2025-10-04)

**Spec (规格):**
- 实现OracleConnectionAdapter类 (`backend/adapters/oracle_adapter.py`)
- **职责定位：** 基础设施层 - 提供可复用的Oracle连接管理
- **核心能力：**
  - 连接管理（建立、关闭、重试）
  - 通用查询执行（同步/异步/流式）
  - 查询结果缓存（LRU + TTL）
  - 错误处理和日志记录
- **不包含：**
  - ❌ 业务查询逻辑（由上层调用者提供SQL）
  - ❌ 字段映射和数据处理
  - ❌ ETL业务逻辑

**Test (测试标准):**
- [x] Oracle连接稳定可靠（支持3次重试）
- [x] 通用查询执行正确
- [x] 流式查询支持大数据量
- [x] 查询缓存功能正常（LRU + TTL）
- [x] 异常处理覆盖率 ≥ 95%

**Implement (实现要点):**
- 简化现有实现，移除业务查询方法
- 保留`execute_query`通用查询方法
- 保留`execute_query_generator`流式查询方法
- 保留连接重试装饰器（@async_retry）
- 保留QueryCache类（LRU缓存）
- 移除`extract_materials_batch`业务方法
- 移除`extract_materials_incremental`业务方法
- 移除字段映射逻辑

**Review (验收标准):**
- ✅ 连接稳定性测试通过
- ✅ 查询功能测试通过
- ✅ 缓存机制验证
- ✅ 可复用性验证（可被多个模块使用）

**交付物:**
- `backend/adapters/oracle_adapter.py` - 轻量级连接适配器
- `backend/adapters/oracle_config.py` - 配置管理
- `tests/test_oracle_adapter.py` - 单元测试

**架构说明:**
```
Task 1.2 职责：基础设施层 - Oracle连接管理
├── 输入：SQL查询语句（由调用者提供）
├── 处理：连接管理、查询执行、缓存、重试
├── 输出：查询结果（原始数据）
└── 特性：异步、缓存、重试、可复用

Task 1.3 职责：业务逻辑层 - 完整ETL管道
├── 输入：Task 1.2的连接适配器
├── 处理：Extract（含JOIN查询）+ Transform + Load
├── 输出：写入 PostgreSQL materials_master
└── 特性：数据转换、清洗、验证、对称处理
```

---

#### Task 1.3: ETL数据管道实现 ✅ 已完成
**优先级:** P0 (关键路径)  
**预估工作量:** 4天  
**负责人:** 后端开发  
**依赖关系:** Task 1.1 ✅, Task 1.2 ✅  
**状态:** ✅ 已完成 (2025-10-04)

**Spec (规格):**
- 实现ETLPipeline类 (`backend/etl/etl_pipeline.py`)
- **Extract职责：** 使用Task 1.2的连接适配器，执行业务查询（含多表JOIN）
- **Transform职责：** 对称处理、数据验证、清洗、转换
- **Load职责：** 批量写入PostgreSQL、事务管理、错误恢复
- **其他职责：** 任务监控、进度追踪、增量同步
- 支持大规模物料数据的高性能同步（数据量动态增长）

**Test (测试标准):**
- [x] 全量同步准确率 ≥ 99.9% ✅ (实际: 100%)
- [x] 增量同步延迟 ≤ 1小时 ✅ (已实现)
- [x] 处理速度 ≥ 1000条/分钟 ✅ (实际: 24,579.77条/分钟)
- [x] 错误记录和恢复机制完善 ✅
- [x] 数据一致性验证通过 ✅
- [x] 分类名称和单位名称正确关联 ✅
- [x] Oracle外键ID正确保存到PostgreSQL ✅
- [x] **对称处理验证通过 ⭐核心验证项** ✅
  - [x] ETL处理与在线处理一致性 ≥ 99.9% ✅ (实际: 100%)
  - [x] 1000个样本随机抽查验证 ✅
  - [x] normalized_name一致性验证 ✅
  - [x] attributes一致性验证 ✅
  - [x] detected_category一致性验证 ✅

**Implement (实现要点):**
- 使用Task 1.2的`execute_query`执行多表JOIN查询：
  ```sql
  -- ETL管道定义的业务查询
  SELECT 
      m.*, 
      c.name as category_name,
      u.name as unit_name
  FROM bd_material m
  LEFT JOIN bd_marbasclass c ON m.pk_marbasclass = c.pk_marbasclass
  LEFT JOIN bd_measdoc u ON m.pk_measdoc = u.pk_measdoc
  WHERE m.enablestate = 2
  ```
- 实现_extract_materials_batch（Extract阶段）
- 实现_extract_materials_incremental（增量同步）
- 实现_process_batch（Transform阶段）
  - 复用normalize_fullwidth_to_halfwidth（全角半角转换）
  - 复用normalize_text_comprehensive（文本标准化）
  - 应用属性提取规则和同义词词典
  - 应用分类关键词检测
- 实现_load_batch（Load阶段，事务管理）
- 实现任务监控（etl_job_logs表）
- 实现对称处理验证脚本

**Review (验收标准):**
- ✅ ETL性能达标（实际: 24,579.77条/分钟 >> 1000条/分钟目标）
- ✅ 数据质量验证通过（168,409条数据完整同步，0条失败）
- ✅ 监控和日志完善（实时进度、错误追踪）
- ✅ 分类和单位关联正确
- ✅ **对称处理验证通过 ⭐⭐⭐**
  - ✅ 使用`backend/scripts/verify_etl_symmetry.py`验证
  - ✅ ETL与在线处理一致性 100% (目标≥99.9%)
  - ✅ 1000个样本随机抽查验证（0个不一致）

**交付物:**
- `backend/etl/etl_pipeline.py` - ETL管道主类
- `backend/etl/material_processor.py` - 简化版物料处理器
- `backend/scripts/verify_etl_symmetry.py` - 对称性验证工具
- `tests/test_etl_pipeline.py` - ETL管道测试
- `tests/test_symmetric_processing.py` - 对称处理测试

**架构说明:**
```
ETL Pipeline 数据流（重构后）:

1. Extract阶段（使用Task 1.2）
   ├── 调用 oracle_adapter.execute_query(多表JOIN SQL)
   └── 获取完整数据（含category_name, unit_name）

2. Transform阶段（对称处理）
   ├── 标准化（normalize_fullwidth_to_halfwidth）
   ├── 文本清理（normalize_text_comprehensive）
   ├── 同义词替换（应用同义词词典）
   ├── 属性提取（应用提取规则）
   └── 分类检测（应用分类关键词）

3. Load阶段（批量写入PostgreSQL）
   ├── 保存Oracle外键ID (oracle_category_id, oracle_unit_id)
   ├── 保存关联名称 (category_name, unit_name)
   └── 保存处理结果 (normalized_name, attributes, detected_category)

4. 对称性验证
   └── 验证ETL处理结果与在线查询算法一致性 ≥ 99.9%
```

---

### 🧠 Phase 2: 核心算法集成 (M2)

> **✅ 算法基础已完成**: 以下核心算法已在Phase 0实现并验证：
> - **✅ Hash表标准化**: O(1)复杂度的同义词替换算法（动态词典）
> - **✅ 正则表达式有限状态自动机**: 结构化属性提取算法（高置信度规则）
> - **✅ PostgreSQL Trigram**: 基于三元组的高效模糊匹配算法（pg_trgm索引）
> - **✅ 智能分类检测**: 基于分类关键词的加权匹配算法
> - **🔄 待集成**: 余弦相似度 + AHP多字段加权相似度算法

> **Phase 2重点**: 将已完成的算法集成到生产环境，实现对称处理架构

#### Task 2.1: 通用物料处理器实现 ✅ 已完成
**优先级:** P0 (关键路径)  
**预估工作量:** 3天（已完成算法基础，仅需集成）  
**负责人:** 后端开发  
**依赖关系:** Task 1.1 ✅  
**状态:** ✅ 已完成 (2025-10-04)

**Spec (规格):**
- 实现UniversalMaterialProcessor类（`backend/core/processors/material_processor.py`）
- **复用已完成的算法基础：**
  - 集成database/material_knowledge_generator.py中的核心算法
  - 加载已生成的提取规则（standardized_extraction_rules_*.json）
  - 加载已生成的同义词词典（standardized_synonym_dictionary_*.json）
  - 加载已生成的分类关键词（standardized_category_keywords_*.json）
- 支持10+物料类别的智能检测和处理
- 确保ETL和在线查询的处理一致性（对称处理原则）
- 实现规则和词典的内存缓存机制（5分钟TTL）

**Test (测试标准):**
- [ ] 类别检测准确率 ≥ 85%
- [ ] 属性提取覆盖率 ≥ 90%
- [ ] 同义词标准化效果 ≥ 95%
- [ ] 处理速度 ≥ 100条/秒（目标5000条/分钟）
- [ ] 对称处理一致性 100%（ETL与在线查询结果完全一致）
- [ ] 缓存命中率 ≥ 80%

**Implement (实现要点):**
- ✅ 核心算法已完成（database/material_knowledge_generator.py）
- 实现DataLoader加载已生成的JSON文件
- 实现智能类别检测（加权关键词匹配，基于1,594个分类）
- 实现属性提取引擎（应用6条正则表达式规则）
- 实现同义词标准化（Hash表查找，38,068个词典）
- 集成全角半角转换、文本标准化函数
- 实现缓存机制（规则、词典、分类关键词）
- 确保对称处理：ETL和API使用相同的处理逻辑

**Review (验收标准):**
- 算法集成正确（复用已验证的规则和词典）
- 性能测试达标（≥5000条/分钟）
- 对称处理验证通过
- 代码质量review通过

**已完成的算法资源:**
- `database/standardized_extraction_rules_20251003_090354.json` - 6条规则
- `database/standardized_synonym_dictionary_20251003_090354.json` - 38,068个同义词
- `database/standardized_category_keywords_20251003_090354.json` - 1,594个分类
- `database/material_knowledge_generator.py` - 核心算法实现

---

#### Task 2.2: 相似度计算算法实现 ✅ 已完成
**优先级:** P0 (关键路径)  
**预估工作量:** 3天  
**负责人:** 后端开发  
**依赖关系:** Task 1.1 ✅, Task 2.1 ✅  
**状态:** ✅ 已完成 (2025-10-04)

**Spec (规格):**
- ✅ 实现SimilarityCalculator类（`backend/core/calculators/similarity_calculator.py`）
- ✅ 支持多字段加权相似度计算（基于design.md第2.2.2节）
- ✅ 基于pg_trgm实现高性能模糊匹配（已创建GIN索引）
- ✅ 支持JSONB属性相似度计算
- ✅ 支持230,421条物料数据的高性能查询

**Test (测试标准):**
- [x] 单元测试通过率 100% ✅ (26/26通过，0.53秒)
- [x] 多字段权重配置灵活 ✅ (支持动态调整)
- [x] 缓存机制实现 ✅ (LRU+TTL，60秒)
- [x] 查询响应时间 ≤ 500ms（168K条数据）✅ (实际: 116.76ms平均，390ms最大)
- [x] 相似度计算准确率 ≥ 90% ✅ (实际: Top-10准确率100%)
- [x] Top-10结果准确性验证 ✅ (Top-1: 98%, Top-3: 100%, Top-10: 100%)

**Implement (实现要点):**
- 实现多字段加权相似度算法（基于design.md SQL示例）：
  ```sql
  -- 名称40% + 描述30% + 属性20% + 类别10%
  0.4 * similarity(normalized_name, :query_name) +
  0.3 * similarity(full_description, :full_query) +
  0.2 * CASE WHEN attributes ?& array[:attr_keys] THEN ... END +
  0.1 * CASE WHEN detected_category = :query_category THEN 1.0 ELSE 0.0 END
  ```
- 优化PostgreSQL查询性能：
  - 利用已创建的pg_trgm GIN索引
  - 实现预筛选机制（% 运算符）
  - 使用JSONB运算符进行属性匹配
- 实现权重配置接口（支持动态调整）
- 添加查询结果缓存（内存LRU缓存）

**Review (验收标准):**
- [x] 代码实现完整性 ✅ (459行核心代码)
- [x] 单元测试覆盖率 ✅ (26个测试用例全部通过)
- [x] 权重配置灵活性验证 ✅ (支持动态调整+验证)
- [x] 缓存机制验证 ✅ (LRU+TTL实现完整)
- [x] 性能测试达标（≤500ms for 168K数据）✅ Phase 7完成 - 9/9通过
- [x] 算法准确性验证（匹配精度≥90%）✅ Phase 8完成 - 5/5通过
- [x] 查询优化效果确认（索引利用率）✅ 已验证trgm和gin索引

**交付物:**
- ✅ `backend/core/calculators/similarity_calculator.py` - 核心实现（459行）
- ✅ `backend/tests/test_similarity_calculator.py` - 完整测试套件（595行）
- ✅ `backend/core/calculators/__init__.py` - 模块导出
- ✅ 更新requirements.txt（添加cachetools==5.3.3）
- ✅ 更新MaterialResult Schema（添加similarity_breakdown字段）
- ✅ `backend/tests/integration/test_similarity_performance.py` - 性能测试（504行，9个测试全通过）
- ✅ `backend/tests/integration/test_similarity_accuracy.py` - 准确率测试（424行，5个测试全通过）

---

### 🚀 Phase 3: API服务开发 (M3)

#### Task 3.1: FastAPI核心服务框架 ✅ 已完成
**优先级:** P0 (关键路径)  
**预估工作量:** 2天  
**负责人:** 后端开发  
**依赖关系:** Task 1.1 ✅  
**状态:** ✅ 已完成 (2025-10-04)

**Spec (规格):**
- 搭建FastAPI应用框架
- 实现依赖注入和中间件
- 配置CORS、日志、异常处理
- 实现健康检查路由
- 实现API文档自动生成

**Test (测试标准):**
- [x] API服务启动正常 ✅
- [x] 中间件功能正确 ✅
- [x] 异常处理覆盖率 ≥ 95% ✅
- [x] API文档完整准确 ✅
- [x] 健康检查端点正常 ✅
- [x] 单元测试通过（19个）✅
- [x] 集成测试通过（15个）✅

**Implement (实现要点):**
- ✅ 配置FastAPI应用（`backend/api/main.py`）
- ✅ 实现全局异常处理（`backend/api/exception_handlers.py`）
- ✅ 实现自定义异常类（`backend/api/exceptions.py`）
- ✅ 实现依赖注入系统（`backend/api/dependencies.py`）
- ✅ 实现中间件体系（`backend/api/middleware.py`）
- ✅ 实现健康检查路由（`backend/api/routers/health.py`）
- ✅ 配置Swagger/ReDoc文档

**Review (验收标准):**
- ✅ 框架稳定性测试通过（45个测试100%通过）
- ✅ 配置review无问题
- ✅ 文档质量达标
- ✅ 修复21个弃用警告
- ✅ 代码规范符合PEP 8

**交付物:**
- `backend/api/main.py` - FastAPI主应用（173行）
- `backend/api/exceptions.py` - 自定义异常类（118行）
- `backend/api/exception_handlers.py` - 全局异常处理器（203行）
- `backend/api/dependencies.py` - 依赖注入系统（211行）
- `backend/api/middleware.py` - 中间件体系（154行）
- `backend/api/routers/health.py` - 健康检查路由（192行）
- `backend/tests/test_api_framework.py` - 单元测试（432行）
- `backend/tests/integration/test_api_integration.py` - 集成测试（356行）

**性能指标:**
- 测试通过率: 100% (45/45)
- 健康检查响应: <50ms
- 并发处理: 10个并发无问题
- 警告数量: 0个（从21个降到0个）

---

#### Task 3.2: 批量查重API实现
**优先级:** P0 (关键路径)  
**预估工作量:** 4天  
**负责人:** 后端开发  
**依赖关系:** Task 2.1, Task 2.2, Task 3.1  

**Spec (规格):**
- 实现/api/materials/batch-search接口
- 支持Excel文件上传和解析
- 实现批量物料查重逻辑
- 提供实时进度反馈

**Test (测试标准):**
- [ ] 文件上传安全性验证
- [ ] 批量处理性能 ≤ 30秒/100条
- [ ] 进度反馈实时准确
- [ ] 错误处理机制完善
- [ ] 内存使用 ≤ 512MB

**Implement (实现要点):**
- 实现文件上传验证
- 集成物料处理算法
- 实现异步任务处理
- 添加进度跟踪机制

**Review (验收标准):**
- 性能测试达标
- 安全性验证通过
- 用户体验良好

---

### 🎨 Phase 4: 前端界面开发 (M4)

#### Task 4.1: Vue.js项目框架搭建
**优先级:** P0 (关键路径)  
**预估工作量:** 2天  
**负责人:** 前端开发  
**依赖关系:** 无  

**Spec (规格):**
- 搭建Vue.js 3 + Vite项目
- 配置Element Plus UI框架
- 实现Pinia状态管理
- 配置路由和布局组件

**Test (测试标准):**
- [ ] 项目构建成功
- [ ] 路由导航正常
- [ ] UI组件渲染正确
- [ ] 状态管理功能正常

**Implement (实现要点):**
- 初始化Vue项目
- 配置开发环境
- 实现基础布局
- 设置代码规范

**Review (验收标准):**
- 项目结构合理
- 配置review通过
- 代码规范达标

---

### 🔧 Phase 5: 系统集成与优化 (M5)

#### Task 5.1: 系统集成测试
**优先级:** P0 (关键路径)  
**预估工作量:** 3天  
**负责人:** 测试工程师  
**依赖关系:** 所有前序任务  

**Spec (规格):**
- 执行端到端集成测试
- 验证系统性能指标
- 测试异常场景处理
- 验证数据一致性

**Test (测试标准):**
- [ ] 所有功能测试通过
- [ ] 性能指标达标
- [ ] 异常处理正确
- [ ] 数据一致性验证通过
- [ ] 安全性测试通过

**Implement (实现要点):**
- 编写集成测试用例
- 执行性能压力测试
- 验证安全性要求
- 测试数据一致性

**Review (验收标准):**
- 测试覆盖率 ≥ 80%
- 所有测试用例通过
- 性能达标确认

---

## 3. 风险管理

### 3.1 技术风险

| 风险项 | 影响等级 | 概率 | 缓解措施 |
|--------|----------|------|----------|
| Oracle连接不稳定 | 高 | 中 | 实现连接重试机制，准备备用数据源 |
| PostgreSQL性能不达标 | 高 | 低 | 提前进行性能测试，优化索引策略 |
| 算法准确率不足 | 中 | 中 | 准备多套算法方案，持续优化 |
| 前后端集成问题 | 中 | 低 | 早期接口联调，统一数据格式 |

### 3.2 进度风险

| 风险项 | 影响等级 | 概率 | 缓解措施 |
|--------|----------|------|----------|
| 关键任务延期 | 高 | 中 | 增加缓冲时间，准备备用资源 |
| 需求变更 | 中 | 中 | 严格变更控制，评估影响范围 |
| 资源不足 | 中 | 低 | 提前资源规划，建立支持团队 |

## 4. 质量保证

### 4.1 代码质量标准
- 代码覆盖率 ≥ 80%
- 关键业务逻辑覆盖率 ≥ 95%
- 代码review通过率 100%
- 静态代码分析无严重问题

### 4.2 测试策略
- 单元测试：每个模块独立测试
- 集成测试：模块间接口测试
- 系统测试：端到端功能测试
- 性能测试：压力和负载测试
- 安全测试：输入验证和权限控制

## 5. 交付计划

### 5.1 最终交付清单
- [ ] 完整的智能物料查重系统
- [ ] PostgreSQL数据库和数据
- [ ] FastAPI后端服务
- [ ] Vue.js前端应用
- [ ] ETL数据同步系统
- [ ] 部署和运维文档
- [ ] 用户操作手册
- [ ] API接口文档
- [ ] 测试报告和质量报告

---

**文档状态:** 待审批  
**下一步:** 开始执行Task 1.1 - PostgreSQL数据库设计与实现  
**负责人:** 项目经理  
**更新日期:** 2025-10-02