# RStudio 插件生态开发路线

## 目标

把前期分析出的 RStudio 二次开发空缺落成可迭代产品，而不是停留在报告层面。

本项目第一产品定义为：RStudio 中文 AI 工作台。

它包含四条互相支撑的产品线：

1. 中文增强：术语表、中文错误解释、中文命令索引、中文项目模板。
2. AI 工作台：选区解释、报错解释、代码生成、测试生成、报告生成。
3. 环境体检：R、RStudio、Quarto、R 包、Python、Git、PATH、日志诊断。
4. 中间件预备层：把 Rscript、Quarto、Git、项目结构扫描封装成稳定任务接口。

## 开发切片

### Slice 1：可安装 Addin

用户故事：

作为 RStudio 用户，我可以从 Addins 菜单打开中文 AI 工作台，不需要修改 RStudio 本体。

验收标准：

- R 包能通过 `R CMD check`。
- `inst/rstudio/addins.dcf` 注册 `run_workbench`。
- 缺少运行依赖时给出中文诊断，不崩成不可读错误。
- Addin UI 构造函数可以在 Rscript/testthat 中测试。

当前状态：

- 已实现 `run_workbench()`。
- 已实现 `create_workbench_app()`，用于把 UI 构造和启动解耦。
- 已补 testthat 契约测试。
- 已实现 `collect_rstudio_extension_status()`，可只读验收 Addin、Project Template、Connections、Snippets 安装状态。
- 已将扩展验收接入 CLI/MCP，便于外部 Agent 和人工验收使用。
- 纠偏新增：已增加可见入口安装器 `install_rstudio_visible_entry()`，用于向用户 `.Rprofile` 安装启动中文提示并安装 snippets，避免“包已安装但 RStudio 打开后肉眼无变化”的交付失败。

### Slice 2：上下文采集

用户故事：

作为用户，我选中一段 R 代码后，AI 能知道当前选区、当前文件、当前项目路径，并且不会无限上传整个项目。

验收标准：

- 通过 `rstudioapi` 读取当前 project、document、selection。
- 在非 RStudio 环境返回稳定 shape，便于测试。
- 文档内容默认裁剪，防止超长上下文影响性能和隐私。

当前状态：

- 已实现 `collect_rstudio_context(max_chars = 12000L)`。
- 已实现上下文裁剪。

### Slice 3：环境体检器

用户故事：

作为新手用户，我可以一键看到 RStudio/R/Quarto/R 包状态，并得到中文修复建议。

验收标准：

- 报告包含 R、RStudio、Quarto、关键 R 包。
- 缺包时返回可机器识别的建议 code。
- 输出 Markdown-like 文本，后续可渲染成 HTML。

当前状态：

- 已实现 `collect_environment_report()`。
- 已实现 `format_environment_report()`。
- 已实现 `suggest_environment_actions()`。

### Slice 4：AI Provider 适配

用户故事：

作为开发者，我可以替换 AI 服务，而不改 Addin UI 和核心任务契约。

验收标准：

- AI 请求通过 `build_ai_task_request()` 统一生成。
- Provider 必须返回统一 response shape。
- Provider response 进入 UI 前必须校验。
- 写文件、执行代码默认需要用户确认。

当前状态：

- 已实现 `build_ai_task_request()`。
- 已实现 `invoke_ai_provider()`。
- 已实现 mock provider。
- 已实现 `local_chinese_provider()`，无 API key 时也能给出中文规则型建议。

新增状态：

- 已实现 OpenAI Responses API provider adapter。
- 已实现 OpenAI-compatible Chat Gateway provider，可接本地 Ollama/vLLM/LiteLLM 或企业内网代理，API key 可选。
- 已实现环境变量配置读取。
- 已实现可注入 HTTP transport，测试不依赖真实网络。
- 已实现 Provider Registry，Addin、CLI、MCP 共用 provider 列表、状态检查和解析逻辑。
- Addin UI 已加入 provider 选择和配置状态提示。
- Addin UI 已加入 provider 配置页，支持 OpenAI 和 compatible chat 的模型、base URL、可选密钥会话内配置。
- 已实现 provider 模型探测：Addin、CLI、MCP 可只读调用 `/models` 检查本地模型或企业网关连通性。
- 已实现模型探测结果回填：Addin 可从探测结果选择模型并写回当前会话的模型输入框。
- 已实现 provider 探测中文修复建议：缺模型、连不上服务、401/403、404、空模型列表都能给出下一步。
- 已实现 provider 联调报告切片：聚合 provider 配置状态、模型探测、中文修复建议、环境体检和扩展安装验收，作为本地模型/企业网关接入前的只读验收入口。
- 已将 provider 联调报告接入 Addin 配置页、`provider-report` CLI 命令和 `rstudiozhai_provider_report` MCP 工具。
- 已实现网关预设与人工联调清单：Ollama、LM Studio、Xinference、vLLM、LiteLLM、DeepSeek、DashScope Qwen、SiliconFlow、智谱 GLM、Moonshot Kimi、企业兼容网关可一键填充当前会话配置，并生成只读验收步骤。
- 已将网关预设/清单接入 Addin 配置页、`provider-presets` / `provider-checklist` CLI 命令和 MCP 工具。
- 已实现 Provider 兼容性矩阵，覆盖离线 provider、OpenAI Responses、本地网关、云端兼容网关和企业兼容网关，并接入 Addin、`provider-compatibility` CLI 命令和 MCP。

下一步：

- 做真实本地模型或企业网关的实机联调记录。
- 后续可增加更多国产模型网关预设和模型参数建议，但仍保持密钥不落盘。

### Slice 5：Quarto 中文报告工厂

用户故事：

作为数据分析用户，我可以把当前脚本或数据分析结果生成中文 Quarto 报告草稿。

验收标准：

- 使用内置 Quarto CLI 或系统 Quarto。
- 生成 `.qmd` 模板，不直接覆盖用户文件。
- 渲染任务进入 Jobs 或外部进程。
- 渲染失败时用中文解释错误。

状态：

- 已实现 `.qmd` 草稿生成。
- 已实现 RStudio Jobs / Rscript fallback 的渲染适配层。
- 下一步补 RStudio 内实机点击验收和渲染失败中文解释。

### Slice 6：项目模板库

用户故事：

作为新手用户，我可以一键创建统计分析项目、Shiny 项目、R 包项目、课程项目。

验收标准：

- 通过 RStudio Project Templates 接入。
- 每个模板包含 README、renv 策略、示例脚本、Quarto 报告。
- 模板命名和目录结构稳定。

状态：

- 已实现 `create_zh_ai_project()`。
- 已添加 `inst/rstudio/templates/project/rstudiozhai-analysis.dcf`。
- 下一步可以继续补参数化向导，比如是否启用 renv、是否创建示例数据。

### Slice 7：中间件 / MCP Server

用户故事：

作为 AI Agent 或外部自动化系统，我可以安全调用 R 项目的诊断、测试、渲染、结构读取能力。

验收标准：

- 不依赖 RStudio 内部未公开 API。
- 本地 API 有显式 allowlist。
- 文件写入需要确认或工作区边界。
- 长任务有日志和超时。

状态：

- 已开始实现本地 JSON/CLI 中间件。
- 已定义命令 allowlist、统一 envelope、结构化错误、写文件显式授权。
- 已覆盖 diagnostics、knowledge、ai-task、quarto-draft、connection-template 起步命令。
- 已实现 `project-scan`：只读扫描项目结构、识别 R 包/RStudio/Quarto/Shiny/testthat 标记，默认不读取正文并跳过重目录。
- 已开始 MCP Server 原型：通过 stdio 暴露 `rstudiozhai_` 前缀工具，复用同一命令契约，不重新发明业务层。
- 下一步可以接入 Codex/Claude Desktop 等 MCP 客户端做实机联调。

### Slice 12：项目上下文扫描

用户故事：

作为 AI 插件或中间件调用方，我需要先理解当前 R 项目的结构、关键入口和技术栈，但不能默认读取整个项目或进入重目录。

验收标准：

- 扫描结果包含文件列表、扩展名统计、R 包/RStudio/Quarto/Shiny/testthat/renv 等关键标记。
- 默认跳过 `.git`、`.Rproj.user`、`renv/library`、`node_modules`、Quarto 输出和 R check 目录。
- 默认不读取文件正文；显式授权后只读取受 `max_bytes` 限制的小文本预览。
- CLI/MCP 可调用，审计日志不记录文件正文。

当前状态：

- 已实现 `collect_project_scan()` 和 `format_project_scan()`。
- 已接入 `project-scan` 命令和 `rstudiozhai_project_scan` MCP 工具。
- 已补 TDD 覆盖目录排除、正文读取限制、命令目录、MCP 和审计不泄露正文。

### Slice 11：策略与审计

用户故事：

作为企业或团队用户，我需要知道 AI 工作台何时尝试执行命令、写文件、调用 provider，以及是否被策略拦截。

验收标准：

- 写文件命令默认必须 `allow_write = TRUE`。
- 审计日志默认不写，显式 `audit_path` 或环境变量开启后才写 JSONL。
- 审计日志不得记录 API key、password、token、secret。
- 审计日志不得记录完整 task、selection、ai_result 等大文本。
- CLI/MCP 可以读取审计事件。

当前状态：

- 已实现统一 policy 检查。
- 已实现 JSONL 审计写入、读取和 Markdown-like 摘要。
- 已接入 `audit-log` 命令和 `rstudiozhai_audit_log` MCP 工具。

### Slice 8：中文知识库

用户故事：

作为中文用户，我可以用中文理解 RStudio 术语、命令入口和常见 R 报错，而不需要先知道英文菜单名。

验收标准：

- 术语表可查询。
- 命令入口可查询。
- 常见 R 报错可匹配并给出中文建议。
- 本地 Provider 会引用知识库结果。

当前状态：

- 已实现 `lookup_rstudio_term()`。
- 已实现 `search_rstudio_commands()`。
- 已实现 `explain_r_error()`。
- 已接入 `local_chinese_provider()` 和 Addin 知识库页。

### Slice 9：Connections 与数据连接

用户故事：

作为数据分析用户，我可以从 RStudio New Connection 或工作台生成安全的数据库连接代码，而不把密码写进脚本。

验收标准：

- 包含 RStudio Connection Snippets。
- 支持 SQLite、PostgreSQL、ODBC 起步模板。
- 连接代码使用 password prompt 或环境变量。

当前状态：

- 已添加 `inst/rstudio/connections.dcf`。
- 已添加 `inst/rstudio/connections/` snippets。
- 已实现 `build_dbi_connection_code()`。

### Slice 10：Code Snippets

用户故事：

作为用户，我可以把常用的工作台代码片段安装进 RStudio snippets，提高重复工作效率。

验收标准：

- 包内有可共享 snippets。
- 安装函数默认不覆盖用户已有 snippets。
- 覆盖时可以备份。

当前状态：

- 已添加 `inst/snippets/r.snippets`。
- 已实现 `install_rstudio_snippets()`。

## 桌面 SKILL 库采用原则

本路线应用了桌面 `SKILL库` 中的开发类和架构类技能包：

- `api-and-interface-design`：先定义任务请求和 provider 响应契约；第三方响应进入 UI 前必须校验。
- `kent-dodds-testing-lens`：测试用户可观察行为和外部契约，而不是 UI 内部状态。
- `performance-optimization`：先限制上下文、避免 UI 线程长任务，后续有证据再优化。
- `clean-architecture`：RStudio、Shiny、AI Provider、Quarto 都是外层细节；核心请求契约和诊断逻辑保持可测试。
