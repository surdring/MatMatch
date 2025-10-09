# MatMatch 脚本使用指南

## 📁 脚本组织结构

```
MatMatch/
├── 智能启动.bat              ⭐ 主启动入口（推荐使用）
├── 停止服务.bat              停止所有服务
├── 检查服务状态.bat          查看服务运行状态
│
├── scripts/                  🔧 启动和管理脚本
│   ├── 启动前端.bat          单独启动前端（精简版）
│   ├── 启动后端.bat          单独启动后端（精简版）
│   ├── 迁移准备-导出数据.bat    项目迁移 - 导出数据库
│   ├── 迁移准备-导入数据.bat    项目迁移 - 导入数据库
│   ├── 更新主机IP配置.bat       一键更新IP配置
│   └── README.md             本文档
│
├── backend/
│   ├── scripts/              🐍 Python工具脚本（开发工具）
│   │   ├── generate_batch_test_excel.py     生成批量测试Excel
│   │   ├── generate_test_excel.py           生成单个测试Excel
│   │   ├── init_database.py                 初始化数据库
│   │   └── run_symmetry_test.bat            对称性测试
│   └── 启动后端.bat          ⚠️ 建议删除（已移至 scripts/）
│
└── frontend/
    └── 启动前端.bat          ⚠️ 建议删除（已移至 scripts/）
```

## 📂 目录说明

### 根目录脚本
- **智能启动.bat** - 主启动入口，智能检测端口、PostgreSQL，提供交互式菜单 ⭐
- **停止服务.bat** - 一键停止前后端服务
- **检查服务状态.bat** - 查看服务运行状态和端口占用

### scripts/ - 启动和管理脚本目录
存放**前后端启动脚本**和**项目管理工具**

**启动脚本：**
- `启动前端.bat` - 单独启动前端服务
- `启动后端.bat` - 单独启动后端服务

**迁移工具：**
- `迁移准备-导出数据.bat` - 从旧主机导出数据库
- `迁移准备-导入数据.bat` - 在新主机导入数据库
- `更新主机IP配置.bat` - 一键更新IP配置文件

### backend/scripts/ - Python工具脚本
存放**开发和测试工具**，如数据库初始化、测试数据生成等

**工具清单：**
- `generate_batch_test_excel.py` - 生成批量查重测试Excel
- `generate_test_excel.py` - 生成单条查询测试Excel
- `init_database.py` - 初始化数据库表结构
- `run_symmetry_test.bat` - 运行对称性测试

---

## 🚀 快速开始

### ⭐ 推荐：使用智能启动

```bash
# 双击运行根目录下的：
智能启动.bat
```

**智能功能：**
- ✅ 自动检测端口占用（8000, 3000）
- ✅ 自动检测 PostgreSQL 状态
- ✅ 智能询问是否重启已运行的服务
- ✅ 支持直接打开浏览器（服务已运行时）
- ✅ 一键启动前后端服务

**交互选项：**
- `[1]` 停止现有服务并重新启动
- `[2]` 直接打开浏览器访问（不重启）
- `[3]` 退出

---

## 📋 详细使用说明

### 1️⃣ 一键智能启动（推荐）

**使用场景：** 日常开发，首次启动或重启

**步骤：**
```bash
智能启动.bat
```

**自动完成：**
- ✅ 检查 PostgreSQL（未运行会提示）
- ✅ 检查端口占用（8000, 3000）
- ✅ 智能询问是否重启（如已运行）
- ✅ 启动后端API (8000端口)
- ✅ 启动前端界面 (3000端口)
- ✅ 自动打开浏览器

---

### 2️⃣ 单独启动后端

**使用场景：** 前端使用其他工具开发，只需要后端API

**步骤：**
```bash
启动服务.bat
选择 [2]

# 或直接运行
scripts\启动后端.bat
```

**访问：**
- API: http://localhost:8000
- 文档: http://localhost:8000/docs

---

### 3️⃣ 单独启动前端

**使用场景：** 后端已启动，只需重启前端

**步骤：**
```bash
启动服务.bat
选择 [3]

# 或直接运行
scripts\启动前端.bat
```

**访问：**
- 前端: http://localhost:3000

---

### 4️⃣ 停止服务

```bash
停止服务.bat
```

**自动停止：**
- 前端服务 (3000端口)
- 后端服务 (8000端口)

---

### 5️⃣ 检查服务状态

```bash
检查服务状态.bat
```

**显示信息：**
- 前端运行状态 + PID
- 后端运行状态 + PID
- PostgreSQL 状态

---

## 🔧 故障排查

### ❌ 端口已被占用

**现象：** 启动时提示端口 8000 或 3000 被占用

**解决：**
1. 脚本会自动询问是否停止旧进程
2. 选择 `Y` 自动停止并重启
3. 或手动运行：`停止服务.bat`

---

### ❌ PostgreSQL 未运行

**现象：** 后端启动失败，提示 PostgreSQL 未运行

**解决：**
1. 打开"服务"管理器（Win+R → `services.msc`）
2. 找到 PostgreSQL 服务
3. 右键 → 启动

---

### ❌ 虚拟环境不存在

**现象：** 后端启动失败，提示找不到 python.exe

**解决：**
```bash
cd D:\develop\python\MatMatch
python -m venv venv
venv\Scripts\activate
pip install -r backend\requirements.txt
```

---

### ❌ node_modules 不存在

**现象：** 前端启动失败

**解决：**
```bash
cd frontend
npm install
```

---

## 📊 脚本对比

| 脚本 | 功能 | 交互性 | 推荐度 |
|-----|------|--------|--------|
| **启动服务.bat** | 菜单式启动 | ✅ 高 | ⭐⭐⭐⭐⭐ |
| scripts/启动前端.bat | 单独启动前端 | ⚠️ 中 | ⭐⭐⭐⭐ |
| scripts/启动后端.bat | 单独启动后端 | ⚠️ 中 | ⭐⭐⭐⭐ |
| 智能启动.bat | 旧版一键启动 | ✅ 高 | ⚠️ 已废弃 |
| backend/启动后端.bat | 旧版后端启动 | ❌ 低 | ⚠️ 已废弃 |
| frontend/启动前端.bat | 旧版前端启动 | ❌ 低 | ⚠️ 已废弃 |

---

## 🗑️ 清理建议

可以安全删除以下旧脚本（已被新脚本替代）：

```bash
# 可删除
智能启动.bat                    → 使用 启动服务.bat 代替
backend\启动后端.bat            → 使用 scripts\启动后端.bat 代替
frontend\启动前端.bat           → 使用 scripts\启动前端.bat 代替
```

---

## 🚢 项目迁移工具

### 迁移场景

当需要将项目迁移到新主机时（如 172.16.100.211），使用以下工具：

### 步骤1: 在旧主机导出数据

```bash
scripts\迁移准备-导出数据.bat
```

**功能：**
- ✅ 自动检查 PostgreSQL 连接
- ✅ 导出数据库（支持 .dump 和 .sql 格式）
- ✅ 显示备份文件大小和位置

**输出：**
- `backup/matmatch_backup_YYYYMMDD.dump` 或 `.sql`

### 步骤2: 复制文件到新主机

需要复制：
1. 数据库备份文件 (`backup/`)
2. 项目代码（排除 `venv/`, `node_modules/`, `__pycache__/`）
3. `.env` 配置文件（如有）

### 步骤3: 在新主机导入数据

```bash
# 1. 创建虚拟环境并安装依赖
python -m venv venv
.\venv\Scripts\activate
pip install -r backend\requirements.txt
pip install -r database\requirements.txt

# 2. 安装前端依赖
cd frontend
npm install
cd ..

# 3. 导入数据库
scripts\迁移准备-导入数据.bat
```

**功能：**
- ✅ 检查 PostgreSQL 服务
- ✅ 自动创建数据库（如不存在）
- ✅ 导入数据并验证

### 步骤4: 更新IP配置

```bash
scripts\更新主机IP配置.bat
```

**功能：**
- ✅ 自动更新 `backend/core/config.py` - CORS配置
- ✅ 自动更新 `backend/api/middleware.py` - 允许来源
- ✅ 自动更新 `docs/项目配置-当前环境.md` - 文档

**配置的新IP：** `172.16.100.211`

### 步骤5: 启动验证

```bash
.\智能启动.bat
```

**访问地址：**
- API文档: http://172.16.100.211:8000/docs
- 前端界面: http://172.16.100.211:3000

### 详细迁移指南

参考完整文档：`docs/项目迁移指南-172.16.100.211.md`

---

## 💡 最佳实践

### 日常开发流程

```bash
# 1. 首次启动（每天）
智能启动.bat

# 2. 前端调试（频繁重启）
Ctrl+C 停止前端
scripts\启动前端.bat

# 3. 后端调试（修改代码）
后端会自动热重载，无需重启

# 4. 结束开发
停止服务.bat
```

---

## 📚 相关文档

- [系统脚本使用手册](../docs/系统脚本使用手册.md)
- [快速使用指南](../快速使用指南.md)
- [自动化定时任务配置指南](../docs/自动化定时任务配置指南.md)

---

**文档版本:** v2.0  
**更新日期:** 2025-10-09  
**维护者:** AI-DEV

