# 智能物料查重工具 - 技术文档

## 📋 项目概述

本项目是一个基于结构化解析与模糊匹配的智能物料查重工具，旨在解决ERP系统中因物料描述不规范导致的重复编码问题。通过"对称处理"的核心原则和一系列数据驱动的算法，实现对海量物料数据的高效、精准查重。

**当前进度**：
- ✅ **Phase 0 - 数据基础设施（已完成）**：基于Oracle真实ERP数据的规则引擎、词典系统和AI知识库的构建，并验证了核心算法的有效性
- ✅ **Phase 1 - 数据管道（已完成）**：完成PostgreSQL数据库设计、Oracle连接适配器、ETL全量同步管道（处理速度>24,000条/分钟，对称处理100%一致性）
- ✅ **Phase 2 - 核心算法集成（已完成）**：UniversalMaterialProcessor和SimilarityCalculator实现（平均响应116ms，Top-10准确率100%）
- 🔄 **Phase 3 - API服务开发（进行中，33%完成）**：FastAPI核心框架已完成（Task 3.1 ✅），批量查重API开发中

## 🚀 快速开始 (面向开发者)

### 1. 环境设置

```bash
# 1. 激活虚拟环境
# Windows:
.\venv\Scripts\activate

# Linux/Mac:
source venv/bin/activate

# 2. 安装所有依赖
pip install -r backend/requirements.txt
pip install -r database/requirements.txt

# 3. 配置数据库连接
# 创建 backend/.env 文件并填入数据库配置
# 详见: docs/configuration_guide.md
```

> 📖 **详细配置说明**: 请参考 [`docs/configuration_guide.md`](docs/configuration_guide.md) 获取完整的配置指南，包括：
> - 虚拟环境路径和激活方法
> - PostgreSQL和Oracle数据库配置
> - 完整的环境变量配置模板
> - 配置验证和常见问题解决

### 2. 初始化数据库（首次设置）

#### 方案A：使用一键验证脚本（推荐）
项目提供了一键验证脚本，可以自动化完成知识库的生成、导入和对称性验证。

```bash
# 在 database/ 目录下运行
cd database

# 执行一键完整测试（推荐）
python run_full_import_verification.py

# 或者使用批处理脚本 (Windows)
run_full_verification.bat
```
此步骤会自动在PostgreSQL数据库中创建并填充`extraction_rules`, `synonyms`, `knowledge_categories`等核心知识库表。

#### 方案B：使用ETL全量同步（生产环境推荐）✅
如果需要从Oracle ERP同步完整的物料数据到PostgreSQL：

```bash
# 在项目根目录下运行
.\venv\Scripts\python.exe backend\scripts\run_etl_full_sync.py --batch-size 1000

# 验证对称处理一致性
.\venv\Scripts\python.exe backend\scripts\verify_etl_symmetry.py --sample-size 1000
```

**ETL同步性能指标**：
- 处理速度：>24,000条/分钟
- 数据来源：Oracle ERP全部物料基础数据
- 失败率：目标<1%
- 对称处理一致性：目标≥99.9%

### 3. 运行后端服务 ✅ 可用

```bash
# 启动FastAPI开发服务器
cd backend
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000

# 访问API文档
# Swagger UI: http://localhost:8000/docs
# ReDoc: http://localhost:8000/redoc
# 健康检查: http://localhost:8000/health
```

## 🧮 核心算法原理

本项目的查重机制基于以下经过真实数据验证的核心算法：

### 1. 三步处理流程算法

#### ① 标准化算法：基于哈希表的字符串替换
- **原理**: 使用哈希表(dict)存储同义词映射关系，实现O(1)时间复杂度查找。
- **实现**: 遍历包含**27,408**条记录的同义词词典，进行字符串替换。
- **覆盖范围**: 包括全角/半角字符、大小写变体、常见别名等。
- **示例**: `"不锈钢" → "304"`, `"SS304" → "304"`, `"Ｍ８＊２０" → "M8x20"`

#### ② 结构化算法：正则表达式有限状态自动机
- **原理**: 使用预编译的正则表达式模式，基于有限状态自动机进行属性提取。
- **规则基础**: 基于Oracle真实ERP数据的统计分析，生成了**6条**核心提取规则，置信度高达**88%-98%**。
- **示例**: `(M|Ｍ)(\d+)[×*xX×＊ｘＸ](\d+)` 匹配 `"Ｍ８×２０"` → `{thread_diameter: 8, length: 20}`

#### ③ 相似度算法：PostgreSQL pg_trgm三元组算法
- **原理**: 将字符串分解为3字符的组合(trigram)，通过计算集合的交并比（Jaccard相似度）来判断相似性。
- **优势**: 对拼写错误、字符顺序变化、部分缺失等情况具有良好的鲁棒性。
- **示例**: `"不锈钢螺栓"` 和 `"304螺栓"` 在标准化后，其trigram交集较大，相似度得分会较高。

### 2. 智能分类检测算法：基于关键词权重的分类器

- **原理**: 基于加权关键词匹配的朴素分类器，为输入的物料描述动态预测其所属类别。
- **数据驱动**: 分类器所用的**1,594个**分类及其关键词，全部是在运行时通过分析Oracle 2,523个官方分类下的真实数据动态生成的，而非硬编码。
- **算法**: `类别得分 = Σ(关键词匹配次数 / 类别总关键词数)`，选择得分最高的分类作为预测结果。
- **作用**: 实现类别特定的规则应用和相似度计算加权，是提升查重精度的关键。

### 3. 多字段加权算法：基于加权融合的相似度计算

- **原理**: 综合考虑物料的多个维度信息，通过加权求和的方式计算最终的综合相似度得分。
- **权重分配**: `总相似度 = 0.4 * 名称相似度 + 0.3 * 描述相似度 + 0.2 * 属性相似度 + 0.1 * 类别相似度`。该权重由业务专家经验结合AHP层次分析法确定。
- **数据库实现**: 该算法直接在PostgreSQL中通过SQL语句实现，以利用`pg_trgm`的`similarity()`函数和GIN索引，获得毫秒级的查询性能。

## 📊 项目完成情况总结

### ✅ Phase 1: 数据库与ETL管道（已完成）

#### 1. PostgreSQL数据库设计（Task 1.1）✅
- **7张核心表**: materials_master, material_categories, measurement_units, extraction_rules, synonyms, knowledge_categories, etl_job_logs
- **完整索引**: pg_trgm GIN索引、JSONB索引、复合索引
- **数据来源**: Oracle ERP全部物料基础数据（230,421条）
- **对称性验证**: SQL导入 vs Python导入 100%一致

#### 2. 轻量级Oracle连接适配器（Task 1.2）✅
- **核心功能**: 连接管理、通用查询执行、流式查询、查询缓存
- **重试机制**: 支持3次自动重试，指数退避
- **缓存策略**: LRU + TTL缓存（300秒TTL）
- **兼容性**: 支持Oracle thick mode（兼容老版本）

#### 3. ETL全量同步管道（Task 1.3）✅ ⭐
- **处理速度**: **>24,000条/分钟**（远超目标1000条/分钟）
- **数据来源**: Oracle ERP全部物料基础数据（包含所有状态）
- **失败率目标**: <1%
- **对称处理一致性**: ≥99.9% ✅ 已验证100%
- **架构**: Extract（多表JOIN） → Transform（对称处理） → Load（批量写入）

### ✅ Phase 2: 核心算法集成（已完成）

#### 4. 通用物料处理器（Task 2.1）✅ 100%完成
- **核心实现**: UniversalMaterialProcessor类（527行）
- **处理算法**: 4步对称处理（类别检测 → 标准化 → 同义词 → 属性提取）
- **知识库加载**: 从PostgreSQL动态加载（支持热更新，5秒TTL）
- **单元测试**: 21/21通过（0.70秒）
- **对称性验证**: 与SimpleMaterialProcessor 100%一致
- **交付日期**: 2025-10-04

#### 5. 相似度计算器（Task 2.2）✅ 100%完成
- **核心实现**: SimilarityCalculator类（503行）
- **算法**: 多字段加权相似度（name 40% + desc 30% + attr 20% + cat 10%）
- **性能优化**: pg_trgm GIN索引 + JSONB运算符
- **缓存机制**: LRU + TTL（60秒，1000条容量）
- **单元测试**: 26/26通过（0.53秒）
- **集成测试**: 14/14通过（性能+准确率）
- **性能指标**: 平均116.76ms（目标≤500ms）
- **准确率指标**: Top-10准确率100%（目标≥90%）
- **交付日期**: 2025-10-04

### 🔄 Phase 3: API服务开发（进行中，33%完成）

#### 6. FastAPI核心服务框架（Task 3.1）✅ 100%完成
- **核心实现**: FastAPI应用框架（8个核心文件）
- **异常体系**: 5种自定义异常类 + 全局处理器
- **依赖注入**: 会话管理 + 版本控制 + 健康检查
- **中间件**: CORS + 请求ID + 日志记录
- **健康检查**: 4个端点（/, /health, /health/readiness, /health/liveness）
- **单元测试**: 19/19通过
- **集成测试**: 15/15通过
- **总测试**: 45/45通过（100%）
- **交付日期**: 2025-10-04

### 📈 性能指标

| 指标 | 目标 | 验证结果 |
|------|------|----------|
| 处理速度 | ≥1000条/分钟 | ✅ 已验证>24,000条/分钟 |
| 对称处理一致性 | ≥99.9% | ✅ 已验证100%（1000样本） |
| 数据完整性 | 100% | ✅ 支持全部状态数据 |
| 错误处理 | 完善 | ✅ 事务回滚+错误恢复 |

### 🎯 关键算法验证

- ✅ **4步对称处理算法**: 类别检测 → 文本规范化 → 同义词替换 → 属性提取
- ✅ **知识库加载**: 6条规则、27,408个同义词、1,594个分类关键词
- ✅ **多表JOIN查询**: Oracle三表关联（bd_material + bd_marbasclass + bd_measdoc）
- ✅ **事务管理**: 批量写入 + 自动回滚 + 错误恢复

## 📁 项目结构

```
MatMatch/
├── backend/             # FastAPI后端服务模块
│   ├── adapters/        # 数据源适配器 ✅ (已完成)
│   │   └── oracle_adapter.py  # 轻量级Oracle连接适配器
│   ├── api/             # FastAPI应用 ✅ (框架已完成)
│   │   ├── main.py              # FastAPI主应用
│   │   ├── exceptions.py        # 自定义异常类
│   │   ├── exception_handlers.py # 全局异常处理器
│   │   ├── dependencies.py      # 依赖注入系统
│   │   ├── middleware.py        # 中间件体系
│   │   └── routers/            # API路由
│   │       └── health.py        # 健康检查路由
│   ├── core/            # 核心业务逻辑 ✅ (已完成)
│   │   ├── processors/          # 物料处理器
│   │   ├── calculators/         # 相似度计算器
│   │   └── schemas/            # Pydantic数据模型
│   ├── database/        # 数据库会话与迁移 ✅ (已完成)
│   ├── etl/             # ETL数据管道 ✅ (已完成)
│   │   ├── etl_pipeline.py      # ETL主管道类
│   │   ├── material_processor.py # 对称处理算法
│   │   ├── etl_config.py        # ETL配置
│   │   └── exceptions.py        # ETL异常定义
│   ├── models/          # SQLAlchemy ORM模型 ✅ (已完成)
│   ├── scripts/         # 后端相关脚本 ✅ (已完成)
│   │   ├── run_etl_full_sync.py      # ETL全量同步脚本
│   │   ├── verify_etl_symmetry.py    # 对称性验证脚本
│   │   └── add_last_sync_at_field.py # 数据库迁移脚本
│   └── tests/           # 单元测试与集成测试 ✅ (已完成)
│       ├── test_api_framework.py     # API框架单元测试
│       └── integration/              # 集成测试
│           └── test_api_integration.py # API集成测试
├── database/            # 数据工具链与知识库生成模块 ✅ (已完成)
│   ├── material_knowledge_generator.py  # 统一的知识库生成脚本
│   ├── generate_sql_import_script.py    # SQL生成脚本
│   ├── run_full_import_verification.py  # 一键测试脚本
│   └── ...
├── specs/               # 需求与设计文档 (Kiro Spec)
│   ├── main/requirements.md
│   ├── main/design.md
│   └── main/tasks.md
├── docs/                # 项目其他文档
├── .gemini_logs/        # AI开发日志
│   └── 2025-10-04/      # Task 1.3完整实施日志
└── README.md            # 项目主入口文档
```

## 📞 联系方式

如有问题，请联系信息自动化部郑学恩。
