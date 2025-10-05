# 技术设计文档: 缓存、性能与一致性检查

版本: 1.3
状态: 草稿
关联需求: specs/caching_and_performance/requirements.md (v2.3)

## 1. 概述
本文档旨在将已批准的需求转化为具体的技术实现方案。它将详细定义一个分层缓存系统（持久
化+内存），并重构核心验证流程以支持多种验证模式（规则、交集、差异）。设计将优先保证
性能、健壮性和数据一致性。

## 2. 后端设计 (Rust)

### 2.1 核心依赖
- sqlx: 用于与SQLite进行异步交互。
- tokio: 用于管理异步任务和线程安全。
- once_cell: 用于初始化全局的内存缓存状态。

### 2.1 核心依赖
- sqlx: 用于与SQLite进行异步交互。
- tokio: 用于管理异步任务和线程安全。
- once_cell: 用于初始化全局的内存缓存状态。

### 2.2 新增模块: cache_manager.rs
我将创建一个新的 src-tauri/src/cache_manager.rs
模块，它将是所有缓存逻辑的唯一负责人。
- 职责:
    - 初始化SQLite数据库连接池。
    - 在首次运行时，创建所需的数据表（如 file_a_data, file_b_data, metadata）。
- (修订) API 详细签名与文档:
```rust
  // cache_manager.rs

  /// 代表文件A或文件B的枚举
  pub enum FileSlot { A, B }


    /// # 检查缓存有效性
    /// 通过对比文件中记录的元数据（修改时间、大小）与当前文件的元数据，判断持久化缓存是否仍然有效。
/// ## 参数
/// - pool: &SqlitePool - 数据库连接池。
/// - slot: &FileSlot - 要检查的文件槽位（A或B）。
/// - path: &Path - 原始文件的当前路径。
/// ## 返回
/// - Result<bool, sqlx::Error>: 如果缓存有效，返回 Ok(true)；无效或不存在则返回Ok(false)。pub async fn check_validity(pool: &SqlitePool, slot: &FileSlot, path: &Path) ->Result<bool, sqlx::Error>;


    /// # 写入数据到持久化缓存
    /// 将预处理后的数据行写入指定文件槽位的SQLite表中，并更新元数据表。
    /// ## 参数
    /// - pool: &SqlitePool - 数据库连接池。
    /// - slot: &FileSlot - 要写入的文件槽位（A或B）。
    /// - path: &Path - 原始文件的路径，用于提取元数据。
    /// - data: Vec<RowData> - 要写入的数据。
    /// ## 返回
    /// - Result<(), sqlx::Error>: 写入成功或失败。
    pub async fn write_cache(pool: &SqlitePool, slot: &FileSlot, path: &Path, data:Vec<RowData>) -> Result<(), sqlx::Error>;


    /// # 从持久化缓存读取数据
    /// 从指定文件槽位的SQLite表中读取所有数据行。
    /// ## 参数
    /// - pool: &SqlitePool - 数据库连接池。
    /// - slot: &FileSlot - 要读取的文件槽位（A或B）。
    /// ## 返回
    /// - Result<Vec<RowData>, sqlx::Error>: 成功时返回数据行向量。
    pub async fn read_cache(pool: &SqlitePool, slot: &FileSlot) ->Result<Vec<RowData>, sqlx::Error>;


    /// # 清理持久化缓存
    /// 删除指定文件槽位在数据库中的所有相关数据（数据表和元数据记录）。
    /// ## 参数
    /// - pool: &SqlitePool - 数据库连接池。
    /// - slot: &FileSlot - 要清理的文件槽位（A或B）。
    /// ## 返回
    /// - Result<(), sqlx::Error>: 清理成功或失败。
    pub async fn clear_cache(pool: &SqlitePool, slot: &FileSlot) -> Result<(),sqlx::Error>;
 ```

### 2.3 全局状态 (内存缓存)
我将在后端定义一个全局、线程安全的内存缓存实例。
```rust
// 伪代码
use once_cell::sync::Lazy;
use std::sync::Mutex;

struct AppState {
in_memory_cache: Mutex<HashMap<FileSlot, InMemoryCache>>,
}

static APP_STATE: Lazy<AppState> = Lazy::new(AppState::default);


// FileSlot 是一个枚举 { A, B }
// InMemoryCache 是一个包含 HashMap<String, Vec<RowData>> 和其他元数据的结构体
 ```
- 这个全局状态将在应用启动时初始化。
- 它的作用是长久持有从持久化缓存（SQLite）加载的数据，供 start_validation
  命令瞬时调用。

### 2.4 DTO 与 命令 (Commands) 重构
- DTO (`dto.rs`):
    - ValidationMode 枚举将被正式定义，并导出给前端：
    ```rust
      #[derive(serde::Serialize, serde::Deserialize, Clone, Debug, ts_rs::TS)]
      #[ts(export)]
      pub enum KeyConsistencySubMode { Intersection, Difference }


      #[derive(serde::Serialize, serde::Deserialize, Clone, Debug, ts_rs::TS)]
      #[ts(export)]
      pub enum ValidationMode {
          RuleBased,
          KeyConsistency { sub_mode: KeyConsistencySubMode },
      }
    ```
    - ProjectConfig 结构体将增加 validation_mode: ValidationMode 字段。
    - 报告 DTO 定义:
    ```rust
      // 用于“交集”模式的报告结构
      #[derive(serde::Serialize, serde::Deserialize, Clone, Debug, ts_rs::TS)]
      #[ts(export)]
      pub struct MatchReport {
          pub file_a_data: HashMap<String, String>,
          pub file_b_data: HashMap<String, String>,
      }


      // 用于“差异”模式的报告结构
      #[derive(serde::Serialize, serde::Deserialize, Clone, Debug, ts_rs::TS)]
      #[ts(export)]
      pub struct DifferenceReport {
          // 只包含A文件中，在B文件中找不到键的行
          pub unique_to_a: Vec<HashMap<String, String>>,
      }
    ```


- 命令 (`commands.rs`):
    - (废弃) get_headers 命令将被移除。
    - (新增) select_file(file_slot: FileSlot, path: String) -> Result<Vec<String>,
      String>:
        - 这是新的核心入口，它将编排整个缓存加载流程。
        - 逻辑:
            1. 调用 cache_manager::clear_cache 清理对应槽位的旧缓存（持久化+内存）。
            2. 调用 cache_manager::check_validity 检查持久化缓存。
            3. 如果无效，则从头读取Excel/CSV，调用 cache_manager::write_cache
               写入持久化缓存。
            4. 调用 cache_manager::read_cache 从持久化缓存中读取数据。
            5. 将读取到的数据存入全局的内存缓存。
            6. 返回文件头给前端。
    - (重构) start_validation(config: ProjectConfig) -> Result<serde_json::Value,
      String>:
        - 此函数不再执行任何IO操作，返回类型变为通用的 serde_json::Value
          以支持多种报告结构。
        - 逻辑:
            1. 直接从全局内存缓存中获取文件A和文件B的数据。
            2. 根据 config.validation_mode 的值，进入不同的处理分支（规则/交集/差异）。
            3. 计算并返回相应的结果（ViolationReport, MatchReport, DifferenceReport）。

### 2.5 错误处理与回退机制
- 缓存失效回退: 在 select_file 命令中，如果任何缓存操作（check_validity, read_cache,
  write_cache）失败，系统将记录一条详细错误日志，然后自动回退到直接从原始Excel/CSV文件
  读取数据的无缓存模式来完成当次操作，从而保证核心功能在缓存系统异常时依然可用。
- 数据库连接:
  对数据库连接失败，本次设计采取快速失败策略，不进行重试，直接进入上述的回退机制。
- 内存缓存一致性:
  内存缓存的数据来源永远是“持久化缓存（SQLite）”或“原始文件”。select_file
  命令的原子化设计确保了在加载数据到内存缓存之前，其数据源已经过有效性检查或刚刚被重建
  ，从而在设计上保证了数据一致性。
- 错误分类: 在回退机制中，所有缓存相关的 sqlx::Error
  将被归类为“可恢复错误”，触发回退到无缓存模式。而像文件路径不存在、格式不支持等问题，
  将被归类为“不可恢复错误”，直接向前端报告失败。

## 3. 前端设计 (Vue.js + Pinia)

### 3.1 全局状态管理 (projectStore.ts)
- 新增State:
    - validationMode: ValidationMode: 存储当前选择的顶层验证模式，默认为 RuleBased。
    - keyConsistencySubMode: KeyConsistencySubMode: 存储一致性检查的子模式，默认为
      Intersection。
    - isCaching: boolean: 用于显示“正在预处理/缓存中...”的加载提示，默认为 false。
    - cachingText: string: 上述加载提示的文本。
- Action变更:
    - fetchHeaders 将被重构为 selectFile(fileSlot: 'A' | 'B')。此 action 会调用 Tauri
      的 dialog.open 获取文件路径，然后调用后端的 select_file 命令，并在此过程中管理
      isCaching 状态。

### 3.2 组件结构 (Configurator.vue)
- 新增UI控件:
    - 在“验证规则”折叠项的上方，将新增一个“验证模式”的 el-form-item。
    - 内部包含一个顶层的 el-radio-group，绑定
      store.validationMode，选项为“规则验证”和“关联键一致性检查”。
    - 在此下方，将是一个仅当选中“关联键一致性检查”时才显示的、第二层的
      el-radio-group，绑定 store.keyConsistencySubMode，选项为“交集”和“差异”。
- UI风格:
    - 所有新UI控件都将严格遵循“扁平化、现代感”的设计。例如，使用 plain 或 text 类型的
      el-button，卡片和表单项使用最简的边框和阴影，并保持充足的留白。

## 4. 设计决策与风险回应
- 分层缓存:
  “持久化+内存”的分层设计，旨在平衡首次加载速度和后续重复操作的极致性能，满足 AC 3.1.3
  的要求。
- 命令合并: 将文件选择、缓存处理、获取表头等多个步骤合并到单一的 select_file
  命令中，可以简化前端的状态管理，让后端原子化地完成一组关联操作，降低了前后端状态不一
  致的风险。
- 风险回应:
    - SQLite并发: sqlx 自带异步连接池，且我们的设计是每个文件槽位对应不同的表，前端操作
      也是单线程的，因此常规使用下并发冲突风险低。
    - 缓存膨胀: 本次设计通过“更换文件即清理”的策略，解决了会话期间的膨胀问题。长期的磁
      盘空间管理，将作为记录在案的未来优化点。
    - 用户体验: 通过两级联动的Radio
      Group，在UI上清晰地表达了模式的层级关系，并只在需要时展示子选项，避免了信息过载，满足
      AC 3.4.1 的要求。

## 5. 安全考量 (Security Considerations)

### 5.1 文件路径验证
- 在后端的 select_file 命令接收到前端传递的 path 字符串后，必须进行严格的验证。
- 策略: 验证该路径是否在预期的、安全的工作目录范围内，防止路径遍历（Path Traversal）
  攻击。在Tauri的配置中，我们会限制文件系统访问的范围，并在此基础上进行二次校验。

### 5.2 SQL注入防护
- 策略: 所有与SQLite数据库的交互，都必须使用 sqlx 的参数化查询功能（例如 sqlx::query!
  宏或 sqlx::query_as! 宏）。
- 禁止: 严禁手动拼接SQL字符串。sqlx 会自动处理输入的转义，从根本上杜绝SQL注入的风险。

### 5.3 内存缓存访问控制
- 策略: 后端的全局内存缓存实例将使用 tokio::sync::Mutex 进行包装。
- 保证: 这确保了在任何时候，只有一个线程能够访问和修改内存缓存，从而避免了并发访问导
  致的数据竞争和状态不一致问题。

## 6. 性能与监控考量

### 6.1 性能指标监控
- 策略: 后端将使用 tracing crate 来发射结构化的日志事件。
- 监控点:
    - cache_check: 记录持久化缓存检查的结果（hit 或 miss）。
    - cache_build_duration: 记录从原始文件预处理并写入SQLite所花费的时间。
    - validation_duration: 记录核心验证逻辑（交集/差异/规则）的执行时间。
- 目的: 这些指标将为未来的性能分析和优化提供关键数据。

### 6.2 内存管理
- 策略: 本次迭代的内存缓存不设硬性的大小限制。但会在创建内存缓存后，记录一条日志以估
  算其占用的内存大小。
- 未来: 更复杂的内存管理，如LRU淘汰算法、分页加载等，将被记录为技术债，待未来版本根据
  实际需求实现。

### 6.3 进度反馈
- 策略: 本次迭代的长时间操作（如缓存构建）将通过一个简单的布尔状态（isCaching）在前端
  显示一个通用的加载动画。
- 未来: 后端 select_file 命令的接口设计将为未来的进度条功能预留扩展性（例如，通过Taur
  i的事件系统发送进度更新），但本次不作实现。

## 7. 替代功能方案

### 7.1 会话级状态保持
**实现方案**:
- 使用浏览器localStorage保存当前会话配置
- 在用户关闭应用前自动保存验证规则、文件选择等配置信息
- 下次启动应用时自动恢复上次会话状态

**技术优势**:
- 实现简单，技术风险低
- 避免文件路径失效问题
- 提供基本的配置记忆功能
- 与缓存系统协同工作，提升用户体验

### 7.2 配置模板功能
**实现方案**:
- 预设常用验证规则模板（如基础数据验证、关联键检查等）
- 用户可快速应用模板配置，减少重复设置
- 支持自定义模板保存和复用

**业务价值**:
- 比完整项目保存更实用
- 降低用户学习成本
- 提高配置效率
- 特别适合重复性验证场景

### 7.3 增强验证报告导出
**优先级调整**:
- 将原本用于保存/加载功能的开发资源转向报告导出功能
- 支持多种格式导出（CSV、Excel、PDF）
- 增强报告的可读性和实用性
- 提供报告模板定制功能

**技术实现**:
- 后端生成结构化报告数据
- 前端提供多种导出格式选择
- 支持报告样式自定义
- 集成到验证结果展示界面

### 7.4 替代方案技术设计
**会话状态保持实现**:
```typescript
// 前端实现示例
const saveSessionState = (config: ProjectConfig) => {
  localStorage.setItem('currentSession', JSON.stringify({
    validationMode: config.validationMode,
    keyConsistencySubMode: config.keyConsistencySubMode,
    rules: config.rules,
    timestamp: Date.now()
  }));
};

const loadSessionState = (): Partial<ProjectConfig> => {
  const saved = localStorage.getItem('currentSession');
  return saved ? JSON.parse(saved) : {};
};
```

**配置模板系统**:
- 模板存储：使用JSON格式存储模板配置
- 模板管理：提供模板创建、编辑、删除功能
- 模板应用：一键应用模板，自动填充验证配置

### 7.5 实施路线图
**第一阶段：立即执行（本周内）**
1. 实现会话级状态保持功能
2. 设计配置模板数据结构
3. 规划报告导出功能架构

**第二阶段：界面优化（下周）**
1. 集成会话状态到现有UI
2. 实现配置模板管理界面
3. 优化报告导出用户体验

**第三阶段：功能增强（下月）**
1. 完善配置模板功能
2. 实现高级报告导出
3. 用户体验优化和性能调优

**风险评估与缓解**
- **技术风险**：替代方案复杂度可控，技术实现成熟
- **用户接受度**：提供更实用的功能，用户接受度高
- **项目进度**：简化功能范围，提高交付质量
