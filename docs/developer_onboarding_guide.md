# 开发者入职指南

**适用对象**: 加入项目的新AI开发助手或人类开发者  
**最后更新**: 2025-10-04

---

## 📚 必读文档清单

### 🎯 第一优先级 - 核心设计文档（必读）

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
- **用途**: 了解项目进度、任务划分、验收标准
- **重点关注**:
  - 第1.1节：项目里程碑和当前进度
  - 第2节：具体任务分解（S.T.I.R.方法）
  - 你要承担的具体任务的完整描述
  - 依赖关系和交付物清单

---

### 📖 第二优先级 - 项目概览（推荐）

#### 4. **项目README**
- **文件**: `README.md`
- **用途**: 快速了解项目、环境设置、快速开始
- **重点关注**:
  - 项目概述和当前进度
  - 核心算法原理（简化版）
  - 快速开始步骤
  - 项目结构说明

#### 5. **已完成任务的实施日志**
- **目录**: `.gemini_logs/2025-10-04/`
- **关键文件**:
  - **Phase 1日志**:
    - `15-00-00-Task1.3完整实施过程日志.md` - Phase 1的完整实施过程
    - `14-00-00-Task1.3完成总结报告.md` - Phase 1任务成果
    - `18-00-00-移除硬编码数据量修正.md` - 重要的架构决策和修正
  - **Phase 2日志** ⭐ 新增:
    - `19-00-00-Task2.1通用物料处理器实现.md` - UniversalMaterialProcessor实现过程
    - `22-00-00-Task2.2相似度计算器实现.md` - SimilarityCalculator实现过程
    - `Phase2完成总结报告.md` - Phase 2完整成果总结（推荐必读）
- **用途**: 了解项目历史、已解决的问题、架构决策

---

### 🔧 第三优先级 - 代码和实现（参考）

#### 6. **已完成的核心代码**

**数据层**:
- `backend/models/materials.py` - ORM模型定义（7张核心表）
- `backend/models/base.py` - 基础类和Mixin
- `backend/database/session.py` - 数据库会话管理

**Oracle连接层**:
- `backend/adapters/oracle_adapter.py` - 轻量级Oracle连接适配器
- `backend/core/config.py` - 配置管理

**ETL数据管道**:
- `backend/etl/etl_pipeline.py` - ETL主管道（E-T-L三阶段）
- `backend/etl/material_processor.py` - SimpleMaterialProcessor（对称处理算法）
- `backend/etl/etl_config.py` - ETL配置
- `backend/etl/exceptions.py` - ETL异常定义

**核心算法模块** ⭐ Phase 2新增:
- `backend/core/processors/material_processor.py` - UniversalMaterialProcessor（527行）
- `backend/core/calculators/similarity_calculator.py` - SimilarityCalculator（503行）
- `backend/core/schemas/material_schemas.py` - Pydantic数据模型

**工具脚本**:
- `backend/scripts/run_etl_full_sync.py` - 全量同步脚本
- `backend/scripts/verify_etl_symmetry.py` - 对称性验证脚本
- `backend/scripts/check_oracle_total_count.py` - Oracle数据检查

**测试代码**:
- **ETL测试**:
  - `backend/tests/test_etl_pipeline.py` - ETL管道核心功能测试
  - `backend/tests/test_etl_edge_cases.py` - 边界情况测试
  - `backend/tests/test_symmetric_processing.py` - 对称处理测试
- **Phase 2测试** ⭐ 新增:
  - `backend/tests/test_universal_material_processor.py` - 21个单元测试
  - `backend/tests/test_similarity_calculator.py` - 26个单元测试
  - `backend/tests/integration/test_similarity_performance.py` - 9个性能测试
  - `backend/tests/integration/test_similarity_accuracy.py` - 5个准确率测试

---

## 🎓 学习路径建议

### 新开发者（第一天）

1. **阅读顺序**:
   ```
   README.md (30分钟)
   → specs/main/requirements.md (1小时)
   → specs/main/design.md 第2.0节核心算法 (1小时)
   → specs/main/tasks.md 项目进度和你的任务 (1小时)
   ```

2. **环境设置**:
   - 📖 **完整配置指南**: [`docs/configuration_guide.md`](configuration_guide.md)
   - 虚拟环境激活：`.\venv\Scripts\activate` (Windows)
   - 数据库配置：创建`backend/.env`文件
   - 运行知识库初始化脚本
   - 验证数据库连接

3. **代码探索**:
   - 浏览已完成任务的代码结构
   - 运行已有的测试用例
   - 查看实施日志了解实现细节

### 开始开发（第二天起）

1. **深入阅读**:
   - 你的任务相关的design.md详细章节
   - 依赖任务的交付物和接口
   - 相关的实施日志

2. **代码实践**:
   - 创建你的任务分支
   - 编写Spec（规格说明）
   - 编写Test（测试用例）
   - 实现代码（Implementation）
   - 代码审查（Review）

---

## 📋 不同任务类型的文档重点

### 如果你要开发 **Phase 2 - 核心算法集成** ✅ 已完成

**已完成的参考代码**:
- ✅ `backend/core/processors/material_processor.py` - UniversalMaterialProcessor（527行）
- ✅ `backend/core/calculators/similarity_calculator.py` - SimilarityCalculator（503行）
- ✅ `backend/tests/test_universal_material_processor.py` - 21个单元测试
- ✅ `backend/tests/test_similarity_calculator.py` - 26个单元测试
- ✅ `backend/tests/integration/test_similarity_performance.py` - 9个性能测试
- ✅ `backend/tests/integration/test_similarity_accuracy.py` - 5个准确率测试

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

**Task 3.2 待开发** 📍:
- 📄 `specs/main/design.md` 第2.1节 - API Endpoint定义
- 📄 `specs/main/design.md` 第2.2.3节 - FileProcessingService
- 📄 `specs/main/requirements.md` 用户故事1和2 - 批量查重功能
- 📄 `backend/models/materials.py` - 数据模型定义

**关键理解**:
- FastAPI框架使用（已搭建完成）
- Pydantic Schema定义（参考已完成的health.py）
- 批量文件处理流程
- 异步处理和进度反馈
- 复用UniversalMaterialProcessor和SimilarityCalculator

### 如果你要开发 **Phase 4 - 前端界面**

**必读**:
- ✅ `specs/main/design.md` 第3节 - 前端设计
- ✅ `specs/main/design.md` 第3.3节 - 数据流与交互逻辑
- ✅ `specs/main/requirements.md` 用户故事1-4 - UI交互需求

**关键理解**:
- Vue.js 3 + Vite技术栈
- Pinia状态管理
- Element Plus UI组件
- 文件上传和结果展示组件

---

## 🔑 关键概念速查

### 核心概念

1. **对称处理（Symmetric Processing）** ⭐⭐⭐
   - **定义**: ETL离线处理和在线API查询使用完全相同的算法
   - **目的**: 确保数据一致性和可预测性
   - **验证**: 对称性验证脚本，目标≥99.9%一致性
   - **实现**: SimpleMaterialProcessor类

2. **4步处理流程**
   - **Step 1**: 类别检测（基于1,594个分类关键词）
   - **Step 2**: 文本规范化（全角半角、大小写、标点符号）
   - **Step 3**: 同义词替换（基于27,408个词典）
   - **Step 4**: 属性提取（基于6条正则表达式规则）

3. **E-T-L三阶段**
   - **Extract**: 从Oracle提取数据（多表JOIN）
   - **Transform**: 对称处理、数据清洗、验证
   - **Load**: 批量写入PostgreSQL（事务管理）

4. **S.T.I.R.开发方法**
   - **Spec**: 编写规格说明（输入输出、接口、数据流）
   - **Test**: 编写测试用例（核心功能、边界情况）
   - **Implement**: 实现代码
   - **Review**: 代码审查和验收

### 技术栈

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

## 📊 项目当前状态

### ✅ 已完成（Phase 0 + Phase 1 + Phase 2 + Phase 3.1）

**Phase 0 + Phase 1: 数据基础设施**
- ✅ PostgreSQL数据库设计（7张表）
- ✅ Oracle连接适配器（轻量级、可复用）
- ✅ ETL全量同步管道（>24,000条/分钟）
- ✅ 对称处理算法（SimpleMaterialProcessor）
- ✅ 知识库（6条规则、27,408个同义词、1,594个分类）
- ✅ 数据导入（168,409条物料数据）

**Phase 2: 核心算法集成** ✅ 2025-10-04完成
- ✅ **Task 2.1**: UniversalMaterialProcessor（527行，21个测试通过）
- ✅ **Task 2.2**: SimilarityCalculator（503行，26个单元测试+14个集成测试通过）
- ✅ 性能验证：平均116.76ms，远超500ms目标
- ✅ 准确率验证：Top-10准确率100%，远超90%目标

**Phase 3: API服务开发** 🔄 2025-10-04开始（33%完成）
- ✅ **Task 3.1**: FastAPI核心服务框架（45个测试100%通过）
  - ✅ FastAPI主应用框架
  - ✅ 自定义异常体系
  - ✅ 全局异常处理器
  - ✅ 依赖注入系统
  - ✅ 中间件体系（CORS + 请求ID + 日志）
  - ✅ 健康检查路由（4个端点）

### 🔜 待开发（Phase 3.2-5）

- 📍 **Task 3.2**: 批量查重API实现（下一个任务）
- 🔜 **Task 4.1**: Vue.js前端框架搭建
- 🔜 **Task 4.2**: 前端核心组件开发

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

---

## 💬 沟通和协作

### 问题反馈

1. **技术问题**
   - 优先查阅设计文档和实施日志
   - 查看已有代码的实现方式
   - 记录问题和解决方案

2. **设计决策**
   - 重大架构变更需要讨论
   - 记录决策原因和备选方案
   - 更新设计文档

3. **进度汇报**
   - 定期更新任务状态
   - 及时报告阻塞问题
   - 记录实施过程日志

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
   - 更新tasks.md任务状态
   - 更新README.md（如需要）
   - 生成完成总结报告
```

---

## 📞 联系方式

**项目负责人**: 信息自动化部郑学恩

**注意事项**:
- 保持代码和文档的一致性
- 遵循对称处理原则
- 注重性能和可维护性
- 记录重要决策和修正

---

**文档版本**: 1.1  
**最后更新**: 2025-10-04（Phase 2完成后更新）  
**维护者**: 项目团队  
**项目进度**: Phase 0-2已完成（40%），Phase 3-5待开发（60%）

