# 需求规格

## 功能需求

### FR-000 本地可用基线

系统在没有外部 AI API key 时，仍应能给出中文规则型诊断和建议。

验收：

- 本地 provider 不上传代码。
- 本地 provider 不执行代码。
- 外部 AI provider 只能作为可替换适配器接入。

### FR-001 环境诊断

系统应能检查：

- R 版本和路径。
- RStudio 版本和路径。
- Quarto 版本和路径。
- 常用 R 包是否安装。
- 后续建议动作。

验收：

- 在没有额外 R 包的环境中也能运行。
- 输出结构化对象。
- 能格式化成中文 Markdown。

### FR-002 AI 任务请求

系统应定义一个稳定请求契约，用于表达用户希望 AI 完成的任务。

最小字段：

- `task`：用户任务。
- `context`：当前文档、报错、项目路径、环境报告等上下文。
- `mode`：explain、edit、generate、diagnose。
- `provider`：mock、openai、local、custom。

验收：

- 空任务应被拒绝。
- 请求对象应可序列化。
- provider 可替换。

### FR-003 RStudio Addin 入口

系统应提供 RStudio Addin 入口函数。

验收：

- 包内存在 `inst/rstudio/addins.dcf`。
- Addin 入口函数可被 R 调用。
- 如果 UI 依赖缺失，应给出清晰提示，而不是崩溃。

### FR-004 SDD/TDD 工程规范

系统应包含：

- 产品愿景。
- 需求规格。
- 架构设计。
- 接口契约。
- TDD 测试计划。
- 技术栈决策。

验收：

- 文档位于 `docs/sdd/`。
- 测试位于 `tests/`。
- 每个核心能力至少有一个自动化测试。

### FR-005 Quarto 报告草稿

系统应能根据任务和 AI 结果生成 `.qmd` 报告草稿。

验收：

- 报告生成不等于渲染；渲染是长任务，应独立执行。
- 默认不覆盖已有文件。
- 报告内容包含任务、AI 结果和可选环境体检。

### FR-006 长任务 / Jobs 适配

系统应能把 Quarto 渲染这类长任务封装为可运行脚本。

验收：

- 在 RStudio 中优先使用 Jobs API。
- 在非 RStudio 环境中使用 Rscript fallback。
- Jobs adapter 必须可以通过自定义 runner 测试，不依赖真实 IDE 窗口。

### FR-007 Project Template

系统应提供 RStudio Project Template，帮助用户创建中文 AI 工作台友好的分析项目。

验收：

- 包内存在 `inst/rstudio/templates/project/*.dcf`。
- template binding 指向导出的 R 函数。
- 生成项目包含 README、R 目录、data 目录、reports 目录、Quarto 分析草稿。

### FR-008 中文知识库

系统应提供本地中文知识库，服务于中文语言增强和 AI Provider。

验收：

- 能查询 RStudio 术语。
- 能查询 RStudio 常用命令入口。
- 能解释常见 R 报错。
- 本地 Provider 应把知识库命中结果加入回答。
- 知识库不依赖网络。

### FR-009 外部 AI Provider 适配

系统应能接入外部 AI Provider，同时不把具体厂商 SDK 绑死在核心逻辑里。

验收：

- Provider 接收 `AiTaskRequest`，返回 `AiTaskResponse`。
- API key 只能来自环境变量或显式参数，不写入项目文件。
- 模型名不硬编码为唯一默认值，应来自环境变量或显式参数。
- HTTP 传输必须可注入，测试不依赖真实网络。
- 第三方响应必须校验和抽取，不能直接把不可信结构传入 UI。

### FR-010 数据连接与 Connections

系统应提供 RStudio Connection Snippets 和安全 DBI 连接代码生成。

验收：

- 包内存在 `inst/rstudio/connections.dcf`。
- 包内存在 `inst/rstudio/connections/` snippet 文件。
- 生成 DBI 代码时不得硬编码数据库密码。
- 支持 SQLite、PostgreSQL、ODBC 三类起步连接模板。

### FR-011 RStudio Code Snippets

系统应提供可共享的 RStudio R snippets，帮助用户快速插入工作台常用代码。

验收：

- 包内存在 `inst/snippets/r.snippets`。
- 能读取 bundled snippets。
- 能计算用户 snippet 路径。
- 安装 snippets 必须显式调用，默认不覆盖已有文件。

## 非功能需求

### NFR-001 兼容性

- 第一阶段兼容 Windows + RStudio Desktop。
- 不修改 RStudio 安装目录。
- 不依赖 RStudio 内部非公开 `.rs.*` 函数。

### NFR-002 性能

- 环境诊断应在 5 秒内完成常规检查。
- AI 调用走异步或后台任务，不阻塞主 IDE。
- 大上下文必须截断和摘要，避免把整个项目塞给模型。

### NFR-003 安全

- 不把 API key 写入代码或日志。
- 外部 AI 返回内容视为不可信，默认只展示，不自动执行。
- 代码修改必须先展示 diff 或明确用户动作。

### NFR-004 可维护性

- 核心业务逻辑不依赖 Shiny、RStudio UI 或外部 AI SDK。
- 外部系统通过 adapter 接入。
- 先用 mock provider 和本地规则型 provider 写测试，再接真实 provider。
