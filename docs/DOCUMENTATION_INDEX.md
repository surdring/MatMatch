# 项目文档索引

**项目**: MatMatch - 智能物料查重系统  
**最后更新**: 2025-10-04

---

## 🎯 新AI开发者入职（3份核心文档）

如果你是新加入的AI开发助手，**只需要这3份文档**即可快速上手：

| # | 文档 | 路径 | 用途 | 阅读时长 |
|---|------|------|------|----------|
| 1️⃣ | **开发者入职指南** | `docs/developer_onboarding_guide.md` | 学习路径、文档清单、关键概念 | 30分钟 |
| 2️⃣ | **交接清单** | `docs/handover_checklist.md` | 代码模块、关键知识点、验证步骤 | 20分钟 |
| 3️⃣ | **技术设计文档** | `specs/main/design.md` | 系统架构、算法设计、接口定义 | 2-3小时 |

**阅读顺序**: 1️⃣ → 2️⃣ → 3️⃣

---

## 📚 完整文档体系

### 🎯 Tier 1: 核心规范文档（必读）

| 文档 | 路径 | 内容 | 维护频率 |
|------|------|------|----------|
| **需求规格说明** | `specs/main/requirements.md` | 业务需求、用户故事、验收标准、术语表 | 每个里程碑 |
| **技术设计文档** | `specs/main/design.md` | 系统架构、技术选型、数据库设计、API定义、算法原理 | 每个里程碑 |
| **任务分解文档** | `specs/main/tasks.md` | 项目里程碑、任务划分、S.T.I.R.规范、验收标准 | 每周 |

### 📖 Tier 2: 入职和交接文档（推荐）

| 文档 | 路径 | 内容 | 目标读者 |
|------|------|------|----------|
| **开发者入职指南** | `docs/developer_onboarding_guide.md` | 文档清单、学习路径、关键概念、开发规范 | 新开发者 |
| **交接清单** | `docs/handover_checklist.md` | 代码模块、关键知识点、环境配置、验证步骤 | 新AI-DEV |
| **文档索引** | `docs/DOCUMENTATION_INDEX.md`（本文件） | 所有文档的导航和说明 | 所有人 |

### 📘 Tier 3: 项目说明文档（参考）

| 文档 | 路径 | 内容 | 目标读者 |
|------|------|------|----------|
| **项目README** | `README.md` | 项目概述、快速开始、核心算法、项目结构 | 所有人 |
| **环境配置** | `README.md` 第1-2节 | 环境设置、依赖安装、数据库配置 | 开发者 |

### 📋 Tier 4: 实施日志（历史记录）

| 目录 | 内容 | 用途 |
|------|------|------|
| `.gemini_logs/2025-10-03/` | Phase 0基础设施建设日志 | 了解知识库构建过程 |
| `.gemini_logs/2025-10-04/` | Phase 1数据管道实施日志 | 了解ETL管道实现细节 |

**重要日志文件**:
- `15-00-00-Task1.3完整实施过程日志.md` - ETL管道完整实施过程
- `14-00-00-Task1.3完成总结报告.md` - Phase 1成果总结
- `18-00-00-移除硬编码数据量修正.md` - 重要架构决策

---

## 🔍 按任务类型查找文档

### 如果你要开发 **Phase 2 - 核心算法**

**必读文档**:
1. `specs/main/design.md` 第2.2.1-2.2.2节（UniversalMaterialProcessor、SimilarityCalculator）
2. `backend/etl/material_processor.py`（已实现的SimpleMaterialProcessor）
3. `.gemini_logs/2025-10-04/15-00-00-Task1.3完整实施过程日志.md`（对称处理实现）

**关键概念**:
- 对称处理原则
- 4步处理流程
- pg_trgm三元组算法

---

### 如果你要开发 **Phase 3 - API服务**

**必读文档**:
1. `specs/main/design.md` 第2.1节（API Endpoint定义）
2. `specs/main/requirements.md` 用户故事1-2（批量查重功能）
3. `backend/models/materials.py`（数据模型）

**关键概念**:
- FastAPI框架
- Pydantic Schema
- 批量文件处理
- 异步处理

---

### 如果你要开发 **Phase 4 - 前端界面**

**必读文档**:
1. `specs/main/design.md` 第3节（前端设计）
2. `specs/main/design.md` 第3.3节（数据流与交互逻辑）
3. `specs/main/requirements.md` 用户故事1-4（UI交互需求）

**关键概念**:
- Vue.js 3 + Vite
- Pinia状态管理
- Element Plus组件

---

### 如果你要进行 **数据库扩展**

**必读文档**:
1. `specs/main/design.md` 第2.3节（数据库表结构）
2. `backend/models/base.py`（Mixin设计）
3. `backend/models/materials.py`（现有表定义）

**关键概念**:
- SQLAlchemy 2.0异步ORM
- Mixin继承（时间戳、软删除、同步状态）
- JSONB字段使用

---

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

## 🎓 学习路径

### 第一天：快速上手（3-4小时）

```
1. docs/developer_onboarding_guide.md        (30分钟)
   ↓
2. README.md 项目概述                         (30分钟)
   ↓
3. specs/main/requirements.md 核心需求       (1小时)
   ↓
4. specs/main/design.md 第2.0节核心算法      (1小时)
   ↓
5. specs/main/tasks.md 项目进度和你的任务    (1小时)
```

### 第二天：深入理解（4-6小时）

```
1. specs/main/design.md 你的任务相关章节     (2小时)
   ↓
2. 浏览已完成的代码模块                       (1小时)
   ↓
3. 阅读相关实施日志                           (1小时)
   ↓
4. 环境设置和验证                             (1-2小时)
```

### 第三天起：开始开发

```
1. 编写Spec（规格说明）
2. 编写Test（测试用例）
3. 实现代码
4. Review（代码审查和验收）
```

---

## 📊 文档更新记录

| 日期 | 更新内容 | 影响文档 |
|------|----------|----------|
| 2025-10-04 | 创建开发者入职和交接文档 | 本索引、入职指南、交接清单 |
| 2025-10-04 | 修正硬编码数据量问题 | README.md、ETL脚本 |
| 2025-10-04 | Task 1.3完成，更新Phase 1状态 | tasks.md、design.md、README.md |
| 2025-10-03 | Task 1.1-1.2完成 | tasks.md、design.md |
| 2025-10-02 | Phase 0基础设施完成 | README.md、requirements.md |

---

## 🔑 快速参考

### 核心概念文档位置

| 概念 | 文档位置 |
|------|----------|
| **对称处理原则** | `specs/main/design.md` 附录A / `docs/developer_onboarding_guide.md` 第5.1节 |
| **4步处理流程** | `specs/main/design.md` 第2.0节 / `docs/developer_onboarding_guide.md` 第5.2节 |
| **E-T-L架构** | `specs/main/design.md` 第2.2.4节 / `docs/developer_onboarding_guide.md` 第5.3节 |
| **S.T.I.R.方法** | `specs/main/tasks.md` 第2.2节 / `docs/developer_onboarding_guide.md` 第9节 |
| **数据库设计** | `specs/main/design.md` 第2.3节 / `docs/handover_checklist.md` 第4.4节 |
| **API设计** | `specs/main/design.md` 第2.1节 |

### 关键代码位置

| 功能 | 代码文件 |
|------|----------|
| **对称处理算法** | `backend/etl/material_processor.py` |
| **ETL管道** | `backend/etl/etl_pipeline.py` |
| **Oracle适配器** | `backend/adapters/oracle_adapter.py` |
| **ORM模型** | `backend/models/materials.py` |
| **配置管理** | `backend/core/config.py` |
| **数据库会话** | `backend/database/session.py` |

---

## 💡 文档使用建议

### 对于新AI开发助手

1. **第一次接触项目**: 阅读`developer_onboarding_guide.md`
2. **准备接手任务**: 阅读`handover_checklist.md`
3. **开始编码**: 参考`design.md`对应章节
4. **遇到问题**: 查阅实施日志（`.gemini_logs/`）

### 对于项目负责人

1. **分配任务**: 提供`handover_checklist.md` + `design.md`对应章节
2. **验收工作**: 参考`tasks.md`中的验收标准
3. **了解进度**: 查看`tasks.md`任务状态

### 对于文档维护者

1. **定期更新**: `tasks.md`（每周）、`design.md`（每个里程碑）
2. **记录日志**: 在`.gemini_logs/`中创建实施日志
3. **同步更新**: 重大架构变更需同步更新多份文档

---

## 📞 获取帮助

### 文档问题
- 文档不清晰 → 提出具体问题，记录在日志中
- 文档缺失 → 根据需要创建新文档
- 文档过时 → 更新对应文档并记录变更

### 技术问题
- 优先查阅设计文档和实施日志
- 参考已有代码的实现方式
- 记录问题和解决方案

---

**索引版本**: 1.0  
**最后更新**: 2025-10-04  
**维护者**: 项目团队



