# MatMatch Frontend

智能物料查重系统 - 前端应用

## 技术栈

- **Vue 3.4+** - 渐进式 JavaScript 框架
- **TypeScript 5.0+** - JavaScript 的超集，提供类型安全
- **Vite 5.0+** - 下一代前端构建工具
- **Element Plus 2.6+** - 基于 Vue 3 的组件库
- **Pinia 2.1+** - Vue 3 的状态管理库
- **Vue Router 4.2+** - Vue 的官方路由管理器
- **Axios 1.6+** - 基于 Promise 的 HTTP 客户端
- **Sass** - CSS 预处理器

## 项目结构

```
frontend/
├── public/                      # 静态资源
├── src/
│   ├── api/                     # API 接口层
│   │   ├── request.ts          # Axios 封装
│   │   ├── material.ts         # 物料相关 API
│   │   └── index.ts            # API 统一导出
│   ├── assets/                  # 资源文件
│   │   └── styles/             # 全局样式
│   │       ├── index.scss      # 主样式文件
│   │       ├── variables.scss  # SCSS 变量
│   │       └── mixins.scss     # SCSS 混入
│   ├── router/                 # 路由配置
│   │   └── index.ts
│   ├── stores/                 # Pinia 状态管理
│   │   ├── material.ts         # 物料状态
│   │   ├── admin.ts            # 管理状态
│   │   ├── user.ts             # 用户状态
│   │   └── index.ts            # Store 统一导出
│   ├── views/                  # 页面组件
│   │   ├── Home.vue            # 首页
│   │   ├── MaterialSearch.vue  # 物料查重页面
│   │   ├── Admin/              # 管理后台页面
│   │   │   └── AdminPanel.vue
│   │   └── NotFound.vue        # 404 页面
│   ├── App.vue                 # 根组件
│   ├── main.ts                 # 入口文件
│   └── env.d.ts                # 环境变量类型
├── .env.development            # 开发环境变量
├── .env.production             # 生产环境变量
├── .eslintrc.cjs               # ESLint 配置
├── .prettierrc.json            # Prettier 配置
├── index.html                  # HTML 模板
├── package.json                # 项目依赖
├── tsconfig.json               # TypeScript 配置
├── vite.config.ts              # Vite 配置
└── README.md                   # 项目文档
```

## 开发指南

### 环境要求

- Node.js >= 18.0.0
- npm >= 9.0.0

### 安装依赖

```bash
cd frontend
npm install
```

### 开发模式

启动开发服务器（默认端口 3000）：

```bash
npm run dev
```

访问 http://localhost:3000

### 构建生产版本

```bash
npm run build
```

构建产物将生成在 `dist/` 目录。

### 预览生产构建

```bash
npm run preview
```

### 代码检查

```bash
# ESLint 检查并自动修复
npm run lint

# Prettier 格式化
npm run format
```

## 环境变量

### 开发环境 (`.env.development`)

```env
VITE_API_BASE_URL=http://localhost:8000
VITE_APP_TITLE=MatMatch - 智能物料查重系统
VITE_USE_MOCK=false
VITE_SHOW_DEBUG=true
```

### 生产环境 (`.env.production`)

```env
VITE_API_BASE_URL=/api
VITE_APP_TITLE=MatMatch - 智能物料查重系统
VITE_USE_MOCK=false
VITE_SHOW_DEBUG=false
```

## 功能特性

### 已实现功能

- ✅ 项目框架搭建
- ✅ Vue Router 路由配置
- ✅ Pinia 状态管理
- ✅ Axios HTTP 客户端封装
- ✅ Element Plus UI 组件集成
- ✅ TypeScript 类型定义
- ✅ 响应式布局
- ✅ 首页展示
- ✅ 物料批量查重页面
- ✅ 管理后台框架

### 待开发功能

- ⏸️ 文件上传组件优化
- ⏸️ 结果展示组件完善
- ⏸️ 管理后台功能实现
- ⏸️ 用户认证功能
- ⏸️ 单元测试
- ⏸️ E2E 测试

## API 接口

### 后端 API 地址

开发环境: `http://localhost:8000`

### 主要接口

- `POST /api/v1/materials/batch-search` - 批量查重
- `GET /api/v1/materials/{erp_code}` - 查询单个物料
- `GET /api/v1/materials/{erp_code}/details` - 查询物料详情
- `GET /api/v1/materials/{erp_code}/similar` - 查询相似物料
- `GET /api/v1/materials/search` - 搜索物料
- `GET /api/v1/categories` - 获取分类列表
- `GET /api/v1/health` - 健康检查

## 代码规范

### TypeScript

- 使用严格模式
- 优先使用 `interface` 而非 `type`
- 避免使用 `any`，使用 `unknown` 代替

### Vue 组件

- 使用 Composition API (`<script setup>`)
- Props 和 Emits 必须定义类型
- 组件名使用 PascalCase
- 文件名使用 PascalCase

### 样式

- 使用 Scoped CSS
- 使用 SCSS 变量和混入
- 遵循 BEM 命名规范

## 性能优化

- ✅ 按需导入 Element Plus 组件
- ✅ 路由懒加载
- ✅ 代码分割（Vendor Chunk）
- ✅ Gzip 压缩
- ✅ 图片懒加载（待实现）

## 浏览器兼容性

- Chrome >= 90
- Firefox >= 88
- Edge >= 90
- Safari >= 14

## 故障排查

### 开发服务器启动失败

1. 检查 Node.js 版本是否 >= 18.0.0
2. 删除 `node_modules` 和 `package-lock.json`，重新安装依赖
3. 检查端口 3000 是否被占用

### API 请求失败

1. 检查后端服务是否启动（http://localhost:8000）
2. 检查 `.env.development` 中的 `VITE_API_BASE_URL` 配置
3. 检查浏览器控制台的网络请求

### 构建失败

1. 运行 `npm run lint` 检查代码错误
2. 运行 `vue-tsc` 检查类型错误
3. 检查 `vite.config.ts` 配置

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目仅供内部使用。

## 联系方式

如有问题，请联系项目维护者。
