# Task 4.2: 物料查重功能完善 - 子任务拆分

**创建时间**: 2025-10-05 16:45  
**目的**: 将 Task 4.2 待完成的工作细化为更小的、可管理的子任务

---

## 📋 原任务 Task 4.2 现状

**当前状态**: 部分完成 (20%)

**已完成 (Task 4.2)**:
- ✅ 安装依赖（xlsx, file-saver）
- ✅ Excel 工具函数（excelUtils.ts - 241行）
- ✅ 文件上传 Composable（useFileUpload.ts - 135行）
- ✅ Excel 导出 Composable（useExcelExport.ts - 198行）
- ✅ 结果筛选 Composable（useResultFilter.ts - 147行）

**待完成工作** (80%):
- ⏸️ 11个 Vue 组件（预估 1,500+ 行代码）
- ⏸️ 页面集成和优化
- ⏸️ 测试和性能优化

---

## 🎯 子任务拆分

###  ⏸️ 待开始
**优先级:** P0 (关键路径)  
**预估工作量:** 1天  
**负责人:** 前端开发  
**依赖关系:** Task 4.2 ✅  

#### Spec (规格)
- 创建独立的 FileUpload.vue 组件
- 实现拖拽上传功能
- 实现文件预览（前5行数据）
- 实现上传进度显示
- 实现列名配置界面（ColumnConfig.vue）
- 实现智能列名检测和提示

#### Test (测试标准)
- [ ] 拖拽上传功能正常
- [ ] 文件类型验证正确（.xlsx, .xls）
- [ ] 文件大小验证正确（≤10MB）
- [ ] 文件预览显示正常
- [ ] 列名检测准确率 ≥ 90%
- [ ] 列名配置交互流畅
- [ ] 错误提示友好

#### Implement (实现要点)
**创建 FileUpload.vue 组件** (约200行):
- 使用 Element Plus Upload 组件
- 集成 useFileUpload composable
- 实现拖拽区域样式
- 实现文件信息展示

**创建 ColumnConfig.vue 组件** (约150行):
- 智能列名检测结果展示
- 手动列名配置表单
- 列名验证和提示
- 预览数据表格

**创建 UploadProgress.vue 组件** (约100行):
- 进度条展示
- 速度和剩余时间估算
- 取消上传按钮

#### Review (验收标准)
- UI/UX 美观友好
- 交互流程顺畅
- 错误处理完善
- 组件可复用性好

#### 预期交付
- `frontend/src/components/MaterialSearch/FileUpload.vue` (约200行)
- `frontend/src/components/MaterialSearch/ColumnConfig.vue` (约150行)
- `frontend/src/components/MaterialSearch/UploadProgress.vue` (约100行)

---

### Task 4.2.2: 结果展示组件开发 ⏸️ 待开始
**优先级:** P0 (关键路径)  
**预估工作量:** 1天  
**负责人:** 前端开发  
**依赖关系:** Task 4.2 ✅, Task 4.2.1 (可并行)

#### Spec (规格)
- 创建结果概览组件（ResultOverview.vue）
- 创建结果列表组件（ResultList.vue）
- 创建单条结果组件（ResultItem.vue）
- 实现分页、筛选、排序、搜索功能
- 实现结果展开/折叠

#### Test (测试标准)
- [ ] 结果概览数据准确
- [ ] 分页功能正常
- [ ] 筛选功能正常（全部/有匹配/无匹配）
- [ ] 排序功能正常（行号/相似度/匹配数）
- [ ] 搜索功能正常
- [ ] 展开/折叠交互流畅
- [ ] 100条结果渲染 ≤ 2秒

#### Implement (实现要点)
**创建 ResultsDisplay.vue 容器组件** (约250行):
- 集成 useResultFilter composable
- 工具栏（筛选、排序、搜索、导出）
- 分页控件

**创建 ResultOverview.vue 组件** (约150行):
- 总处理数量、成功率
- 平均相似度
- 处理耗时
- 统计图表（可选）

**创建 ResultList.vue 组件** (约200行):
- 虚拟滚动（可选，性能优化）
- 结果项列表
- 空状态展示

**创建 ResultItem.vue 组件** (约200行):
- 输入数据展示
- 匹配数量徽章
- 展开/折叠按钮
- 展开后显示详细内容

#### Review (验收标准)
- 数据展示准确完整
- 交互响应迅速
- UI 美观易用
- 性能达标（100条 ≤ 2秒）

#### 预期交付
- `frontend/src/components/MaterialSearch/ResultsDisplay.vue` (约250行)
- `frontend/src/components/MaterialSearch/ResultOverview.vue` (约150行)
- `frontend/src/components/MaterialSearch/ResultList.vue` (约200行)
- `frontend/src/components/MaterialSearch/ResultItem.vue` (约200行)

---

### Task 4.2.3: 详细结果展示组件 ⏸️ 待开始
**优先级:** P0 (关键路径)  
**预估工作量:** 0.5天  
**负责人:** 前端开发  
**依赖关系:** Task 4.2 ✅, Task 4.2.2

#### Spec (规格)
- 创建解析结果展示组件（ParsedQueryDisplay.vue）
- 创建匹配列表组件（MatchResultList.vue）
- 创建匹配项组件（MatchResultItem.vue）
- 实现相似度可视化（进度条/雷达图）

#### Test (测试标准)
- [ ] 解析结果展示完整
- [ ] 匹配物料信息准确
- [ ] 相似度展示清晰
- [ ] 操作按钮功能正常（复制编码、查看详情）

#### Implement (实现要点)
**创建 ParsedQueryDisplay.vue 组件** (约200行):
- 标准化结果展示
- 分类检测结果
- 属性提取结果
- 规则说明提示

**创建 MatchResultList.vue 组件** (约150行):
- 匹配物料列表（Top 10）
- 展开/折叠全部
- 排序选项

**创建 MatchResultItem.vue 组件** (约250行):
- 物料基本信息
- 相似度进度条（总体+分项）
- 操作按钮（复制、详情）
- Tooltip 提示

**（可选）创建 SimilarityChart.vue 组件** (约150行):
- 雷达图展示分项相似度
- 使用 ECharts 或 Chart.js

#### Review (验收标准)
- 信息展示清晰易懂
- 相似度可视化直观
- 操作便捷
- 组件性能良好

#### 预期交付
- `frontend/src/components/MaterialSearch/ParsedQueryDisplay.vue` (约200行)
- `frontend/src/components/MaterialSearch/MatchResultList.vue` (约150行)
- `frontend/src/components/MaterialSearch/MatchResultItem.vue` (约250行)
- `frontend/src/components/MaterialSearch/SimilarityChart.vue` (约150行，可选)

---

### Task 4.2.4: Excel 导出功能集成 ⏸️ 待开始
**优先级:** P1 (重要但非关键)  
**预估工作量:** 0.5天  
**负责人:** 前端开发  
**依赖关系:** Task 4.2 ✅, Task 4.2.2 ✅

#### Spec (规格)
- 创建导出按钮组件（ExportButton.vue）
- 集成 useExcelExport composable
- 实现导出选项（全部/筛选后/指定行）
- 实现导出进度提示
- 实现导出成功反馈

#### Test (测试标准)
- [ ] 导出全部结果功能正常
- [ ] 导出筛选后结果功能正常
- [ ] 导出指定行功能正常
- [ ] Excel 文件格式正确（3个Sheet）
- [ ] 数据完整性验证通过
- [ ] 100条结果导出 ≤ 5秒

#### Implement (实现要点)
**创建 ExportButton.vue 组件** (约150行):
- 导出按钮（下拉菜单）
- 导出选项（全部/筛选/选中）
- 进度提示
- 成功/失败通知

**集成 useExcelExport**:
- 调用 exportResults 方法
- 处理导出选项
- 错误处理

**优化导出格式**:
- Sheet 1: 查重结果汇总
- Sheet 2: 详细匹配列表
- Sheet 3: 统计分析

#### Review (验收标准)
- 导出功能稳定可靠
- Excel 格式规范
- 数据完整准确
- 性能达标

#### 预期交付
- `frontend/src/components/MaterialSearch/ExportButton.vue` (约150行)
- 导出格式优化（已在 useExcelExport 中）

---

### Task 4.2.5: MaterialSearch 页面集成和优化 ⏸️ 待开始
**优先级:** P0 (关键路径)  
**预估工作量:** 0.5天  
**负责人:** 前端开发  
**依赖关系:** Task 4.2.1 ✅, Task 4.2.2 ✅, Task 4.2.3 ✅, Task 4.2.4 ✅

#### Spec (规格)
- 集成所有新组件到 MaterialSearch.vue
- 优化页面布局和样式
- 实现完整的查重流程
- 实现错误处理和加载状态
- 实现响应式布局

#### Test (测试标准)
- [ ] 完整查重流程正常（上传 → 配置 → 查重 → 展示 → 导出）
- [ ] 所有组件集成无问题
- [ ] 错误处理完善
- [ ] 加载状态清晰
- [ ] 响应式布局正常（PC/平板/手机）
- [ ] 整体性能达标

#### Implement (实现要点)
**优化 MaterialSearch.vue 页面** (约500行):
- 集成 FileUpload 组件
- 集成 ColumnConfig 组件
- 集成 ResultsDisplay 组件
- 集成 ExportButton 组件
- 实现状态管理（文件、配置、结果）
- 实现流程控制（步骤切换）
- 实现错误处理（友好提示）
- 实现加载状态（骨架屏/进度条）

**优化样式**:
- 响应式布局
- 深色模式支持（可选）
- 动画过渡

**优化性能**:
- 懒加载组件
- 防抖/节流
- 虚拟滚动（如需要）

#### Review (验收标准)
- 用户体验流畅
- 视觉设计美观
- 功能完整可用
- 性能达标
- 代码质量优秀

#### 预期交付
- 优化后的 `frontend/src/views/MaterialSearch.vue` (约500行)
- 样式文件（如需要）
- 集成测试（手动）

---

## 📊 工作量总结

| 子任务 | 预估工作量 | 依赖关系 | 优先级 | 预期代码量 |
|--------|-----------|---------|--------|-----------|
| Task 4.2 (基础) | 0.5天 | Task 4.1 | P0 | 721行 ✅ |
| Task 4.2.1 | 1天 | Task 4.2 | P0 | 450行 |
| Task 4.2.2 | 1天 | Task 4.2 | P0 | 800行 |
| Task 4.2.3 | 0.5天 | Task 4.2.2 | P0 | 750行 |
| Task 4.2.4 | 0.5天 | Task 4.2.2 | P1 | 150行 |
| Task 4.2.5 | 0.5天 | 全部 | P0 | 500行 |
| **总计** | **4天** | - | - | **3,371行** |

---

## 🎯 实施建议

### 方案 A: 迭代开发（推荐 ⭐⭐⭐⭐⭐）
**优点**: 每次迭代都有可交付成果，风险可控  
**缺点**: 需要多次集成和测试

**迭代计划**:
1. **第一次迭代** (1天): Task 4.2.1 文件上传组件
   - 交付: 完整的文件上传和列名配置功能
   - 里程碑: 用户可以上传文件并配置列名

2. **第二次迭代** (1天): Task 4.2.2 结果展示组件
   - 交付: 完整的结果展示功能
   - 里程碑: 用户可以查看查重结果

3. **第三次迭代** (0.5天): Task 4.2.3 详细结果展示
   - 交付: 解析结果和匹配详情展示
   - 里程碑: 用户可以查看详细的匹配信息

4. **第四次迭代** (0.5天): Task 4.2.4 导出功能
   - 交付: Excel 导出功能
   - 里程碑: 用户可以导出查重结果

5. **第五次迭代** (0.5天): Task 4.2.5 页面集成和优化
   - 交付: 完整的物料查重功能
   - 里程碑: Task 4.2 完成

### 方案 B: 一次性开发
**优点**: 连贯性好，开发效率高  
**缺点**: 风险较高，无中间交付物

**时间表**:
- Day 1: Task 4.2.1 + Task 4.2.2 开始
- Day 2: Task 4.2.2 完成 + Task 4.2.3
- Day 3: Task 4.2.4 + Task 4.2.5
- Day 4: 测试和优化

### 方案 C: 先测试现有功能
**优点**: 快速验证后端 API，确保基础功能正常  
**缺点**: 用户体验较差，需要后续优化

**步骤**:
1. 测试现有的 MaterialSearch.vue 与后端 API 交互
2. 验证批量查重功能的基本流程
3. 根据测试结果决定是否继续开发

---

## 📝 决策建议

**推荐方案**: 方案 C（先测试） + 方案 A（迭代开发）

**理由**:
1. ✅ 基础工具层已完成（Task 4.2）
2. ✅ 后端 API 已完成并测试通过（Task 3.2）
3. ⚠️ 前端组件尚未开发，不确定现有 MaterialSearch.vue 能否正常工作
4. 💡 先测试可以快速验证后端 API，发现潜在问题
5. 💡 迭代开发可以降低风险，每次都有可交付成果

**下一步建议**:
1. 提交当前代码到 GitHub
2. 测试现有的 MaterialSearch.vue 功能
3. 验证后端 API 是否正常工作
4. 根据测试结果决定：
   - 如果基本功能正常 → 开始迭代开发（方案 A）
   - 如果有问题 → 先修复问题，再开始开发

---

**创建者**: AI助手  
**创建时间**: 2025-10-05 16:45  
**相关文档**: 
- `.gemini_logs/2025-10-05/Task4.2-物料查重功能完善.md`
- `specs/main/tasks.md`
- `specs/main/design.md`

