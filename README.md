# 智能物料查重工具 - MatMatch

## 📋 项目概述

本项目是一个基于结构化解析与模糊匹配的智能物料查重工具，旨在解决ERP系统中因物料描述不规范导致的重复编码问题。通过"对称处理"的核心原则和一系列数据驱动的算法，实现对海量物料数据的高效、精准查重。

**当前进度**: Phase 0-4已完成（100%），Phase 5待开发（0%）

> 📖 **详细进度和任务分解**: 查看 [`specs/main/tasks.md`](specs/main/tasks.md) ⭐ 单一事实来源（SSOT）

**核心特性**:
- ✅ **高性能**: 批量查重≤3秒/30条，查询响应<120ms
- ✅ **高准确率**: Top-10准确率100%，对称处理一致性100%
- ✅ **数据驱动**: 27,408个同义词、1,594个分类、6条提取规则
- ✅ **完整全栈**: FastAPI后端 + Vue.js前端 + 管理后台
- ✅ **用户友好**: 拖拽上传、智能检测、3步向导、Excel导出

---

## 🚀 快速开始

> 📖 **新开发者入职**: 请先阅读 [`docs/developer_onboarding_guide.md`](docs/developer_onboarding_guide.md) 获取完整的入职指南（学习路径、关键概念、代码模块、环境配置、验证清单等）。

### 1. 环境设置（快速版）

```bash
# 1. 激活虚拟环境
.\venv\Scripts\activate  # Windows
# 或 source venv/bin/activate  # Linux/Mac

# 2. 安装依赖
pip install -r backend/requirements.txt
pip install -r database/requirements.txt

# 3. 配置数据库连接
# 创建 backend/.env 文件并填入数据库配置
```

> 📖 **详细配置说明**: [`docs/configuration_guide.md`](docs/configuration_guide.md) - 包含虚拟环境、PostgreSQL、Oracle配置、环境变量模板、常见问题解决等。

### 2. 初始化数据库（首次设置）

```bash
# 方案A：初始化知识库（推荐用于开发环境）
cd database
python run_full_import_verification.py

# 方案B：从Oracle ERP全量同步（生产环境）
.\venv\Scripts\python.exe backend\scripts\run_etl_full_sync.py --batch-size 1000
```

### 3. 运行后端服务

```bash
# 启动FastAPI开发服务器
cd backend
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000

# 访问API文档
# Swagger UI: http://localhost:8000/docs
# 健康检查: http://localhost:8000/health
```

---

## 🧮 核心算法原理（概述）

本项目的查重机制基于以下经过真实数据验证的核心算法：

### 1. 对称处理（Symmetric Processing）
**ETL离线处理和在线API查询使用完全相同的算法**，确保数据一致性。

**4步处理流程**:
1. **类别检测** - 基于1,594个分类关键词
2. **文本规范化** - 全角半角、大小写、标点符号
3. **同义词替换** - 基于27,408个词典
4. **属性提取** - 基于6条正则表达式规则（置信度88%-98%）

### 2. 多字段加权相似度算法
```
总相似度 = 0.4 × 名称相似度 + 0.3 × 描述相似度 + 0.2 × 属性相似度 + 0.1 × 类别相似度
```

**技术实现**:
- **PostgreSQL pg_trgm**: 三元组模糊匹配（Trigram + GIN索引）
- **JSONB运算符**: 结构化属性相似度计算
- **LRU+TTL缓存**: 查询性能优化

### 3. 性能指标

| 指标 | 目标 | 实际表现 |
|------|------|----------|
| ETL处理速度 | ≥1,000条/分钟 | ✅ >24,000条/分钟 |
| 查询响应时间 | ≤500ms | ✅ 平均116.76ms |
| Top-10准确率 | ≥90% | ✅ 100% |
| 对称处理一致性 | ≥99.9% | ✅ 100% |

> 📖 **详细算法说明和代码示例**: [`specs/main/design.md`](specs/main/design.md) 第2.0节 - 核心算法原理

---

## 📊 项目架构

### 核心模块

```
MatMatch/
├── backend/              # 后端服务 ✅ Phase 0-3完成
│   ├── api/              # FastAPI服务（15个管理API + 6个查询API）
│   ├── core/             # 核心算法
│   │   ├── processors/   # UniversalMaterialProcessor（527行）
│   │   └── calculators/  # SimilarityCalculator（503行）
│   ├── etl/              # ETL数据管道（>24,000条/分钟）
│   ├── models/           # SQLAlchemy ORM（7张表）
│   └── tests/            # 170+测试用例（95%+通过率）
├── frontend/             # 前端应用 ✅ Phase 4完成
│   ├── src/
│   │   ├── views/        # MaterialSearch（999行）、Admin（109行）
│   │   ├── components/   # 文件上传、列配置、管理后台组件
│   │   ├── stores/       # Pinia状态管理（material、admin、user）
│   │   ├── api/          # API客户端（21个端点）
│   │   └── utils/        # Excel工具、Composables
│   └── package.json      # 294个npm包
├── database/             # 知识库生成工具 ✅
├── specs/                # 需求与设计文档
│   ├── main/requirements.md  # 业务需求
│   ├── main/design.md        # 技术设计
│   └── main/tasks.md         # 项目进度 ⭐ SSOT
└── docs/                 # 项目文档
    ├── developer_onboarding_guide.md  # 入职指南（v2.6）
    ├── python_files_structure.md      # 文件结构说明
    └── configuration_guide.md         # 配置指南
```

> 📖 **详细代码模块说明**: [`docs/developer_onboarding_guide.md`](docs/developer_onboarding_guide.md) 第4节

---

## 📚 文档导航

### 🎯 核心文档（必读）

| 文档 | 用途 | 阅读时长 |
|------|------|----------|
| [`specs/main/requirements.md`](specs/main/requirements.md) | 业务需求、用户故事、验收标准 | 1小时 |
| [`specs/main/design.md`](specs/main/design.md) | 系统架构、算法设计、API定义 | 2-3小时 |
| [`specs/main/tasks.md`](specs/main/tasks.md) ⭐ | **项目进度**、任务分解、验收标准 | 1小时 |

### 📖 开发者文档

| 文档 | 用途 |
|------|------|
| [`docs/developer_onboarding_guide.md`](docs/developer_onboarding_guide.md) | 新开发者完整入职指南（学习路径、关键概念、代码模块、环境配置、验证清单、常见问题） |
| [`docs/configuration_guide.md`](docs/configuration_guide.md) | 完整的环境和数据库配置指南 |
| [`.gemini_logs/2025-10-04/`](.gemini_logs/2025-10-04/) | 历史实施日志和架构决策记录 |

### 🚀 快速导航

**我想...**
- **了解项目进度** → [`specs/main/tasks.md`](specs/main/tasks.md)
- **开始开发** → [`docs/developer_onboarding_guide.md`](docs/developer_onboarding_guide.md)
- **配置环境** → [`docs/configuration_guide.md`](docs/configuration_guide.md)
- **理解算法** → [`specs/main/design.md`](specs/main/design.md) 第2.0节
- **查看API** → 启动服务后访问 http://localhost:8000/docs

---

## 🎓 技术栈

**后端**:
- Python 3.11+ / FastAPI / SQLAlchemy 2.0+ (异步ORM)
- PostgreSQL 14+ (主数据库) + Oracle (数据源)
- Pydantic (配置和验证)

**前端** ✅:
- Vue.js 3.4.21 / Vite 5.2.8 / TypeScript 5.4.0
- Element Plus 2.6.3 / Pinia 2.1.7 / Vue Router 4.3.0
- Axios 1.6.8 / xlsx (SheetJS)

**算法**:
- PostgreSQL pg_trgm (三元组模糊匹配)
- 正则表达式 (属性提取)
- Hash表 (同义词替换)

---

## 📈 项目里程碑

| Phase | 状态 | 完成时间 | 核心成果 |
|-------|------|----------|----------|
| Phase 0 | ✅ 完成 | 2025-10-03 | 知识库构建（6规则+27,408同义词+1,594分类） |
| Phase 1 | ✅ 完成 | 2025-10-04 | ETL管道（>24,000条/分钟，100%一致性） |
| Phase 2 | ✅ 完成 | 2025-10-04 | 核心算法（116ms响应，100%准确率） |
| Phase 3 | ✅ 完成 | 2025-10-08 | FastAPI完整API（21个端点，95.7%测试通过） |
| Phase 4 | ✅ 完成 | 2025-10-09 | Vue.js前端（~8,000行，8次优化迭代） |
| Phase 5 | 📅 待开发 | - | 系统集成测试 + 生产部署 |

> 📖 **详细完成情况和验收标准**: [`specs/main/tasks.md`](specs/main/tasks.md)

---

## 🧪 测试覆盖

| 模块 | 测试类型 | 通过率 | 测试数量 |
|------|----------|--------|----------|
| ETL管道 | 单元测试 + 边界测试 | 100% | 45个 |
| 核心算法 | 单元测试 + 集成测试 | 100% | 61个 |
| API框架 | 单元测试 + 集成测试 | 100% | 45个 |
| 批量查重API | 单元测试 | 100% | 28个 |
| 管理后台API | 单元测试 | 95.7% | 46个 |
| **总计** | - | **99.1%** | **225个** |

```bash
# 运行所有测试
pytest backend/tests/ -v

# 查看测试覆盖率
pytest backend/tests/ --cov=backend --cov-report=html
```

---

## 📞 联系方式

**项目负责人**: 信息自动化部郑学恩

**获取帮助**:
1. 查阅 [`docs/developer_onboarding_guide.md`](docs/developer_onboarding_guide.md) 常见问题部分
2. 查看 [`.gemini_logs/`](.gemini_logs/) 历史实施日志
3. 联系项目负责人

---

**项目进度**: Phase 0-3.2已完成（67%）  
**最后更新**: 2025-10-05  
**文档版本**: 2.0
