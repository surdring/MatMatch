# Task 4.2: 物料查重功能完善 - S.T.I.R. 开发日志

**任务编号**: Task 4.2  
**开始时间**: 2025-10-05 15:00  
**负责人**: AI助手  
**预估工作量**: 3天  
**依赖关系**: Task 4.1 ✅  
**状态**: 🔄 进行中

---

## 📋 S.T.I.R. 开发循环

### Phase 1: Spec (规格说明) 🔄 进行中

#### 1.1 任务目标

完善 MatMatch 项目的核心功能 - 物料批量查重，提供完整、友好、高效的用户体验。

#### 1.2 当前状态分析

**已完成（Task 4.1）**:
- ✅ 基础的 MaterialSearch.vue 页面（327行）
- ✅ 文件上传组件（使用 Element Plus Upload）
- ✅ 列名配置表单
- ✅ 基础的结果展示（Collapse + Table）
- ✅ Material Store 状态管理
- ✅ API 层封装（materialApi.batchSearch）

**待完善**:
- ⏸️ 文件上传体验优化
- ⏸️ 结果展示可视化
- ⏸️ 解析过程透明化
- ⏸️ 结果导出功能
- ⏸️ 错误处理优化

#### 1.3 功能规格详细设计

##### 1.3.1 文件上传组件优化

**组件名称**: `FileUpload.vue`

**功能需求**:
1. **拖拽上传**
   - 支持拖拽 Excel 文件到指定区域
   - 拖拽时显示视觉反馈
   - 支持点击上传

2. **文件验证**
   - 文件类型验证（.xlsx, .xls）
   - 文件大小验证（≤10MB）
   - 文件内容预览（前5行）

3. **上传进度**
   - 实时显示上传进度（0-100%）
   - 显示上传速度
   - 支持取消上传

4. **列名配置**
   - 智能列名检测（自动识别）
   - 手动列名指定（支持列名/索引/Excel字母）
   - 列名预览（显示检测到的列）
   - 必需字段验证（名称、规格型号、单位）

**Props**:
```typescript
interface FileUploadProps {
  maxSize?: number        // 最大文件大小（MB），默认10
  accept?: string[]       // 接受的文件类型，默认['.xlsx', '.xls']
  autoDetect?: boolean    // 是否自动检测列名，默认true
}
```

**Emits**:
```typescript
interface FileUploadEmits {
  (e: 'upload', file: File, columns: ColumnConfig): void
  (e: 'cancel'): void
  (e: 'error', error: Error): void
}
```

##### 1.3.2 结果展示组件

**组件名称**: `ResultsDisplay.vue`

**功能需求**:
1. **结果概览**
   - 总处理数量
   - 成功/失败数量
   - 平均相似度
   - 处理耗时

2. **结果列表**
   - 分页展示（每页20条）
   - 支持筛选（有匹配/无匹配）
   - 支持排序（按行号/相似度）
   - 支持搜索（按物料名称）

3. **单条结果展示**
   - 输入数据展示
   - 解析结果展示（标准化、分类、属性）
   - 匹配物料列表（Top 10）
   - 相似度可视化（进度条/雷达图）

**Props**:
```typescript
interface ResultsDisplayProps {
  results: BatchSearchResult[]
  totalProcessed: number
  processingTime: number
  pageSize?: number       // 每页数量，默认20
}
```

##### 1.3.3 解析结果展示组件

**组件名称**: `ParsedQueryDisplay.vue`

**功能需求**:
1. **标准化结果**
   - 原始输入
   - 标准化后的名称
   - 标准化规则说明

2. **分类检测**
   - 检测到的分类
   - 分类置信度
   - 分类关键词匹配

3. **属性提取**
   - 提取的属性列表（规格、型号、材质等）
   - 属性来源规则
   - 属性置信度

**Props**:
```typescript
interface ParsedQueryDisplayProps {
  parsedQuery: {
    normalized_name: string
    detected_category: string
    extracted_attributes: Record<string, any>
  }
  inputData: {
    material_name: string
    specification: string
    unit_name: string
  }
}
```

##### 1.3.4 匹配结果组件

**组件名称**: `MatchResultItem.vue`

**功能需求**:
1. **物料信息展示**
   - ERP编码
   - 物料名称
   - 规格型号
   - 单位
   - 分类

2. **相似度展示**
   - 总体相似度（进度条）
   - 分项相似度（名称、描述、属性、分类）
   - 相似度雷达图

3. **操作按钮**
   - 查看详情
   - 复制编码
   - 标记为正确/错误

**Props**:
```typescript
interface MatchResultItemProps {
  match: MaterialResult
  rank: number            // 排名（1-10）
  showDetails?: boolean   // 是否展开详情
}
```

##### 1.3.5 结果导出功能

**功能需求**:
1. **导出格式**
   - Excel格式（.xlsx）
   - 包含输入数据
   - 包含匹配结果（Top 3）
   - 包含相似度得分

2. **导出内容**
   - Sheet 1: 查重结果汇总
   - Sheet 2: 详细匹配列表
   - Sheet 3: 统计分析

3. **导出选项**
   - 导出全部结果
   - 导出筛选后的结果
   - 导出指定行

**实现方案**:
- 使用 `xlsx` 库（SheetJS）
- 前端生成 Excel 文件
- 自动下载

##### 1.3.6 错误处理优化

**错误类型**:
1. **文件错误**
   - 文件格式错误
   - 文件大小超限
   - 文件内容为空
   - 文件解析失败

2. **列名错误**
   - 必需列缺失
   - 列名不存在
   - 列名重复

3. **网络错误**
   - 请求超时
   - 网络中断
   - 服务器错误

4. **数据错误**
   - 数据格式错误
   - 数据验证失败

**错误处理策略**:
- 友好的错误提示
- 错误原因说明
- 修复建议
- 重试机制

#### 1.4 UI/UX 设计

##### 1.4.1 页面布局

```
┌─────────────────────────────────────────────────────┐
│  物料批量查重                                        │
│  上传Excel文件，自动识别并查找相似物料               │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  📁 文件上传                          [重新上传]     │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │  📤                                          │   │
│  │  拖拽Excel文件到此处，或点击上传             │   │
│  │  支持 .xlsx, .xls 格式，最大10MB             │   │
│  └─────────────────────────────────────────────┘   │
│                                                       │
│  📋 列名配置（可选，留空自动检测）                   │
│  物料名称列: [____________]  提示: 例如 "物料名称" 或 A │
│  规格型号列: [____________]  提示: 例如 "规格型号" 或 B │
│  单位列:     [____________]  提示: 例如 "单位" 或 C     │
│                                                       │
│  [开始查重]                                          │
│                                                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  上传进度: 45% ████████████░░░░░░░░░░░░░░░           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  ✅ 查重完成                                         │
│  共处理 100 条记录，成功率 95%，耗时 28.5秒          │
├─────────────────────────────────────────────────────┤
│  [导出结果] [筛选] [排序]                  [搜索框]  │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ▼ 行1: 六角螺栓 M8*20 304          找到5个匹配      │
│     ┌─────────────────────────────────────────┐     │
│     │ 📊 解析结果:                             │     │
│     │ 标准化名称: 六角螺栓 M8X20 304不锈钢     │     │
│     │ 检测分类: 螺栓螺钉                       │     │
│     │ 提取属性: 规格=M8, 长度=20mm, 材质=304   │     │
│     └─────────────────────────────────────────┘     │
│     ┌─────────────────────────────────────────┐     │
│     │ 🎯 匹配物料:                             │     │
│     │ 1. ERP001 | 六角螺栓M8*20 304 | 相似度 95%│     │
│     │ 2. ERP002 | 六角螺栓M8X20 304 | 相似度 92%│     │
│     │ 3. ERP003 | 六角螺栓M8-20 304 | 相似度 88%│     │
│     └─────────────────────────────────────────┘     │
│                                                       │
│  ▼ 行2: 深沟球轴承 6205-2RS          找到3个匹配      │
│     ...                                              │
│                                                       │
│  [1] 2 3 4 5 ... 10                                  │
└─────────────────────────────────────────────────────┘
```

##### 1.4.2 交互流程

```
用户操作流程:
1. 进入页面 → 看到上传区域
2. 拖拽/选择文件 → 文件验证 → 显示文件信息
3. （可选）配置列名 → 实时预览列检测结果
4. 点击"开始查重" → 显示上传进度 → 显示处理进度
5. 查重完成 → 显示结果概览 → 展开查看详细结果
6. 筛选/排序/搜索结果 → 查看匹配详情
7. 导出结果 → 下载Excel文件
```

##### 1.4.3 视觉设计

**颜色方案**:
- 主色: #409EFF（蓝色）- 操作按钮、链接
- 成功: #67C23A（绿色）- 成功状态、高相似度
- 警告: #E6A23C（橙色）- 警告状态、中等相似度
- 危险: #F56C6C（红色）- 错误状态、低相似度
- 信息: #909399（灰色）- 辅助信息

**图标使用**:
- 📁 文件上传
- 📤 拖拽上传
- 📋 列配置
- 📊 解析结果
- 🎯 匹配结果
- ✅ 成功
- ⚠️ 警告
- ❌ 错误

#### 1.5 性能要求

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 文件上传响应 | ≤ 1秒 | 文件选择后立即显示信息 |
| 列名检测 | ≤ 500ms | 自动检测列名 |
| 结果渲染 | ≤ 2秒 | 100条结果渲染完成 |
| 分页切换 | ≤ 300ms | 页面切换响应 |
| 导出Excel | ≤ 5秒 | 100条结果导出 |
| 内存占用 | ≤ 200MB | 处理100条结果 |

#### 1.6 技术选型

**核心库**:
- `xlsx` (SheetJS) - Excel文件处理
- `echarts` 或 `chart.js` - 数据可视化（可选）
- Element Plus 组件 - UI组件

**工具函数**:
- 文件读取: `FileReader API`
- Excel解析: `xlsx.read()`
- Excel生成: `xlsx.writeFile()`
- 数据格式化: `dayjs`

#### 1.7 组件结构

```
src/
├── components/
│   ├── MaterialSearch/
│   │   ├── FileUpload.vue           # 文件上传组件
│   │   ├── ColumnConfig.vue         # 列名配置组件
│   │   ├── UploadProgress.vue       # 上传进度组件
│   │   ├── ResultsDisplay.vue       # 结果展示组件
│   │   ├── ResultOverview.vue       # 结果概览组件
│   │   ├── ResultList.vue           # 结果列表组件
│   │   ├── ResultItem.vue           # 单条结果组件
│   │   ├── ParsedQueryDisplay.vue   # 解析结果展示
│   │   ├── MatchResultList.vue      # 匹配列表组件
│   │   ├── MatchResultItem.vue      # 匹配项组件
│   │   ├── SimilarityChart.vue      # 相似度图表（可选）
│   │   └── ExportButton.vue         # 导出按钮组件
│   └── Common/
│       ├── EmptyState.vue           # 空状态组件
│       └── ErrorState.vue           # 错误状态组件
├── composables/
│   ├── useFileUpload.ts             # 文件上传逻辑
│   ├── useColumnDetection.ts        # 列名检测逻辑
│   ├── useExcelExport.ts            # Excel导出逻辑
│   └── useResultFilter.ts           # 结果筛选逻辑
└── utils/
    ├── excelUtils.ts                # Excel工具函数
    ├── formatUtils.ts               # 格式化工具
    └── validationUtils.ts           # 验证工具
```

#### 1.8 输入输出定义

**输入**:
- Excel文件（.xlsx, .xls）
- 列名配置（可选）

**输出**:
- 查重结果列表
- 解析结果详情
- 匹配物料列表
- 导出的Excel文件

#### 1.9 依赖接口

**后端API**:
- ✅ POST /api/v1/materials/batch-search - 批量查重（已实现）

**响应格式**:
```typescript
interface BatchSearchResponse {
  success: boolean
  total_processed: number
  results: BatchSearchResult[]
  detected_columns?: {
    material_name: string
    specification: string
    unit_name: string
  }
  skipped_rows?: number[]
  processing_time: number
}
```

---

### Phase 2: Test (测试设计) ⏸️ 待开始

#### 2.1 测试策略

**单元测试**:
- [ ] FileUpload 组件测试
- [ ] ColumnConfig 组件测试
- [ ] ResultsDisplay 组件测试
- [ ] ParsedQueryDisplay 组件测试
- [ ] MatchResultItem 组件测试
- [ ] useFileUpload composable 测试
- [ ] useExcelExport composable 测试
- [ ] excelUtils 工具函数测试

**集成测试**:
- [ ] 文件上传流程测试
- [ ] 列名检测流程测试
- [ ] 结果展示流程测试
- [ ] 导出功能测试

**E2E 测试**:
- [ ] 完整查重流程测试
- [ ] 错误处理测试
- [ ] 性能测试

#### 2.2 测试用例

**文件上传测试**:
- [ ] 正常上传 .xlsx 文件
- [ ] 正常上传 .xls 文件
- [ ] 拒绝非Excel文件
- [ ] 拒绝超大文件（>10MB）
- [ ] 显示上传进度
- [ ] 取消上传

**列名检测测试**:
- [ ] 自动检测标准列名
- [ ] 自动检测模糊列名
- [ ] 手动指定列名
- [ ] 手动指定列索引
- [ ] 手动指定Excel字母
- [ ] 验证必需列

**结果展示测试**:
- [ ] 显示结果概览
- [ ] 分页展示结果
- [ ] 筛选有匹配/无匹配
- [ ] 排序结果
- [ ] 搜索结果
- [ ] 展开/折叠详情

**导出功能测试**:
- [ ] 导出全部结果
- [ ] 导出筛选结果
- [ ] Excel格式正确
- [ ] 数据完整性

#### 2.3 验收标准

**功能性验收**:
- [ ] 文件上传功能正常
- [ ] 列名检测准确率 ≥ 90%
- [ ] 结果展示完整
- [ ] 导出功能正常
- [ ] 错误处理完善

**性能验收**:
- [ ] 文件上传响应 ≤ 1秒
- [ ] 列名检测 ≤ 500ms
- [ ] 结果渲染 ≤ 2秒
- [ ] 导出Excel ≤ 5秒

**用户体验验收**:
- [ ] 操作流程顺畅
- [ ] 错误提示友好
- [ ] 视觉设计美观
- [ ] 响应式布局

---

### Phase 3: Implement (实现) ⏸️ 待开始

#### 3.1 实施步骤

**Step 1: 安装依赖** ⏸️
- [ ] 安装 xlsx 库
- [ ] 安装 file-saver 库（可选）

**Step 2: 创建工具函数** ⏸️
- [ ] excelUtils.ts
- [ ] formatUtils.ts
- [ ] validationUtils.ts

**Step 3: 创建 Composables** ⏸️
- [ ] useFileUpload.ts
- [ ] useColumnDetection.ts
- [ ] useExcelExport.ts
- [ ] useResultFilter.ts

**Step 4: 创建基础组件** ⏸️
- [ ] FileUpload.vue
- [ ] ColumnConfig.vue
- [ ] UploadProgress.vue

**Step 5: 创建结果展示组件** ⏸️
- [ ] ResultsDisplay.vue
- [ ] ResultOverview.vue
- [ ] ResultList.vue
- [ ] ResultItem.vue

**Step 6: 创建详情组件** ⏸️
- [ ] ParsedQueryDisplay.vue
- [ ] MatchResultList.vue
- [ ] MatchResultItem.vue

**Step 7: 创建导出功能** ⏸️
- [ ] ExportButton.vue
- [ ] 导出逻辑实现

**Step 8: 优化 MaterialSearch 页面** ⏸️
- [ ] 集成新组件
- [ ] 优化布局
- [ ] 优化交互

**Step 9: 测试和调试** ⏸️
- [ ] 单元测试
- [ ] 集成测试
- [ ] 性能优化

---

### Phase 4: Review (验收) ⏸️ 待开始

#### 4.1 代码审查清单

- [ ] 组件结构合理
- [ ] 代码规范符合标准
- [ ] TypeScript 类型定义完整
- [ ] 注释和文档完整
- [ ] 无性能问题
- [ ] 无安全隐患

#### 4.2 功能验收清单

- [ ] 所有功能测试通过
- [ ] 性能指标达标
- [ ] 用户体验良好
- [ ] 错误处理完善

#### 4.3 文档验收清单

- [ ] 组件文档完整
- [ ] API 文档更新
- [ ] 用户指南更新

---

## 📊 进度跟踪

| 阶段 | 状态 | 开始时间 | 完成时间 | 耗时 |
|------|------|----------|----------|------|
| Spec | 🔄 进行中 | 2025-10-05 15:00 | - | - |
| Test | ⏸️ 待开始 | - | - | - |
| Implement | ⏸️ 待开始 | - | - | - |
| Review | ⏸️ 待开始 | - | - | - |

---

## 📝 决策记录

### 决策 1: 使用 xlsx (SheetJS) 库
**原因**: 
- 功能强大，支持多种Excel格式
- 纯JavaScript实现，无需后端支持
- 社区活跃，文档完善
- MIT许可证

### 决策 2: 前端生成Excel导出
**原因**:
- 减轻后端压力
- 用户体验更好（即时下载）
- 支持自定义导出格式

### 决策 3: 组件化设计
**原因**:
- 提高代码复用性
- 便于维护和测试
- 清晰的职责划分

---

## 🐛 问题记录

暂无问题

---

## 📚 参考资料

- [SheetJS Documentation](https://docs.sheetjs.com/)
- [Element Plus Upload](https://element-plus.org/zh-CN/component/upload.html)
- [Element Plus Table](https://element-plus.org/zh-CN/component/table.html)
- [Element Plus Collapse](https://element-plus.org/zh-CN/component/collapse.html)
- `specs/main/design.md` 第 3 节 - 前端设计
- `specs/main/requirements.md` - 用户故事2
- `frontend/src/views/MaterialSearch.vue` - 当前实现

---

**下一步**: 完成 Spec 阶段，开始 Implement 实施
