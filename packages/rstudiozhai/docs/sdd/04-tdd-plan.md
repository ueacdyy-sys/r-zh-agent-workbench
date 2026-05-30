# TDD 测试计划

## 测试原则

来自桌面 SKILL库测试技能的约束：

- 测用户可观察行为，不测私有实现细节。
- 少 mock，只在外部边界 mock。
- 先测契约，再测实现。
- 每个 bug 都补回归测试。

## 第一阶段测试

### TEST-001 环境报告结构

给定当前机器环境，调用 `collect_environment_report()`：

- 返回 list。
- 包含 `r`、`rstudio`、`quarto`、`packages`、`suggestions`。
- R 检查应为 ok。

### TEST-002 缺包建议

给定不存在的包名：

- `collect_environment_report()` 应标记 missing。
- `suggestions` 应包含安装建议。

### TEST-003 AI 请求校验

给定空 task：

- `build_ai_task_request()` 应报错。

给定正常 task：

- 返回可序列化 list。
- 默认 `require_user_confirmation` 为 TRUE。

### TEST-004 Provider mock

给定 mock provider：

- `invoke_ai_provider()` 应返回 ok。
- content 非空。

给定坏 provider：

- 应返回 ok = FALSE 或抛出清晰错误。

### TEST-005 RStudio 上下文结构

给定普通 Rscript 或 RStudio session：

- `collect_rstudio_context()` 必须返回稳定 list。
- 必须包含 `available`、`project_path`、`active_document`。
- 非 RStudio 环境不能抛错。

### TEST-006 Addin app 构造

给定 UI 依赖已安装：

- `check_workbench_dependencies()` 返回 ok。
- `create_workbench_app()` 返回 `ui` 和 `server`。
- 该测试不启动真实 RStudio 窗口。

### TEST-007 Workbench response 展示

给定 provider response：

- `format_workbench_result()` 展示 content。
- 有 warnings 时展示警告。
- 有 proposed_files 时展示文件名。

### TEST-008 本地中文 Provider

给定合法 `AiTaskRequest`：

- `local_chinese_provider()` 返回 ok。
- 返回内容包含用户任务。
- provider 为 local 时不产生“真实大模型”误导。

给定非法 request：

- 应抛出清晰错误。

### TEST-009 Quarto 报告草稿

给定任务和 AI 结果：

- `build_quarto_report_content()` 返回包含 YAML front matter 的 `.qmd` 内容。
- `create_quarto_report()` 写出 `.qmd` 文件。
- 默认不渲染、不覆盖已有文件。

### TEST-010 Jobs 适配

给定已有 `.qmd`：

- `create_quarto_render_job_script()` 写出 R 渲染脚本。
- `run_quarto_render_job()` 可使用自定义 runner。
- 测试不依赖真实 RStudio 窗口。

### TEST-011 Project Template

给定临时目录：

- `create_zh_ai_project()` 创建项目骨架。
- DCF metadata 的 `Binding` 指向导出函数。
- 生成 README、R 脚本、Quarto 草稿。

### TEST-012 中文知识库

给定术语、命令或 R 报错：

- `lookup_rstudio_term()` 能返回术语命中。
- `search_rstudio_commands()` 能返回命令入口。
- `explain_r_error()` 能返回中文错误解释。
- `local_chinese_provider()` 的输出包含知识库命中结果。

### TEST-013 OpenAI Responses Provider

给定合法配置和 mock HTTP transport：

- `openai_responses_provider()` 构造 `/responses` 请求。
- payload 包含 model、instructions、input、max_output_tokens。
- instructions 保留用户确认和禁止冒充执行的安全边界。
- response 被折回 `AiTaskResponse`。

给定缺少 key 或 model：

- provider 应拒绝调用。

### TEST-013B Provider Registry

给定 provider catalog：

- `list_ai_providers()` 返回 local、mock、openai_responses、compatible_chat。
- metadata 包含 provider、label、needs_network、needs_config、description。
- OpenAI provider 和 compatible chat provider 标记需要配置和网络。

给定 provider 配置：

- `provider_config_status()` 能判断 OpenAI 是否缺少 `OPENAI_API_KEY` 或 `RSTUDIOZHAI_OPENAI_MODEL`。
- 状态输出不得泄露 API key。
- `resolve_ai_provider()` 只支持内置 provider 或显式注入 provider，不动态查找任意函数。

给定 Addin UI：

- UI 中有 provider 选择和 provider 状态展示。
- 运行任务时用用户选择的 provider，而不是启动时固定值。

### TEST-013C Compatible Chat Gateway Provider

给定本地或企业 OpenAI-compatible Chat Completions 网关配置：

- `get_compatible_chat_config()` 读取 `RSTUDIOZHAI_GATEWAY_*` 配置并规范化 URL。
- API key 可选；本地网关无 key 时仍可通过配置校验。
- 缺少 model 或 base_url 时返回清晰错误。
- `build_compatible_chat_payload()` 使用 `messages`，并保留中文输出、禁止冒充执行、写入前确认等安全指令。
- `extract_compatible_chat_response_text()` 能抽取常见 chat completions 响应。
- `compatible_chat_provider()` 通过可注入 HTTP transport 调用网关，不把 API key 写入 raw。
- Provider Registry 能列出 `compatible_chat`，状态输出不得泄露密钥。

### TEST-013D Provider 配置向导

给定 Addin 或宿主应用传入的表单值：

- `provider_config_fields()` 返回可渲染的 provider 配置字段元数据，并标记 secret 字段。
- `build_provider_config()` 能从内存 values 构造 OpenAI 和 compatible chat 配置。
- `provider_config_status_from_values()` 能检查配置状态且不泄露密钥。
- `provider_from_config()` 返回绑定配置的 provider 函数，不写环境变量和项目文件。
- Addin UI 暴露 provider 配置页、模型/base URL/key 输入和配置状态输出。

### TEST-013E Provider 模型探测

给定 OpenAI-compatible provider 配置：

- `extract_provider_model_ids()` 能抽取常见 `/models` 响应里的模型 ID。
- `probe_provider_models()` 只读调用 `/models`，返回结构化 ok/count/models/error。
- 探测失败返回 `ok = FALSE` 和错误码，不让底层异常直接打断 UI。
- probe result 和 Markdown 输出不得包含 API key。
- `provider-probe` 命令出现在 allowlist，且标记为只读。
- MCP 暴露 `rstudiozhai_provider_probe` 工具。
- Addin 配置页有模型探测按钮和结果输出。

### TEST-013F Provider 模型选择回填

给定成功的模型探测结果：

- `provider_model_choices()` 将模型列表转成稳定的 UI choices。
- `apply_provider_model_choice()` 能按 provider 更新 OpenAI 或 compatible chat 的模型字段。
- 空模型、失败探测或不支持远程模型列表的 provider 不改变配置。
- Addin 配置页暴露模型选择框和“使用选中模型”按钮。
- 回填只影响当前会话输入值，不写环境变量或项目文件。

### TEST-013G Provider 探测修复建议

给定失败或空结果的 provider 探测：

- `suggest_provider_probe_actions()` 返回 data frame，包含 code、message、action。
- 缺模型配置时建议填写模型名或先探测模型列表。
- connection refused / failed to connect 时建议启动 Ollama/vLLM/LiteLLM 或核对企业网关。
- 401/403 时建议检查 API key。
- 404 时建议检查 `/models` 端点和 base URL。
- 成功但模型列表为空时建议检查网关响应结构或本地模型是否已拉取。
- `format_provider_probe()` 必须包含“修复建议”区块。

### TEST-013H Provider 联调报告

给定本地或企业 OpenAI-compatible 网关配置：

- `collect_provider_integration_report()` 返回 provider、registry、status、安全配置摘要、probe、suggestions、overall_ok。
- 报告原始结构和 Markdown 输出不得包含 API key、password、token、secret。
- `probe_fun` 可注入，测试不依赖真实网络。
- 探测失败时报告必须包含 `suggest_provider_probe_actions()` 的中文修复建议。
- 可选包含 `collect_environment_report(packages = "stats")` 和 `collect_rstudio_extension_status()` 的只读上下文。
- `provider-report` 命令出现在 allowlist，且标记为只读。
- MCP 暴露 `rstudiozhai_provider_report` 工具，并标记为 read-only、open-world。
- Addin 配置页有一键生成联调报告按钮和结果输出。

### TEST-013I Provider 网关预设与人工联调清单

给定内置网关预设：

- `provider_gateway_presets()` 返回 data frame，至少包含 Ollama、vLLM、LiteLLM、企业兼容网关。
- `provider_values_from_gateway_preset()` 能生成 compatible chat 的会话内配置值。
- `collect_provider_integration_checklist()` 返回安全的人工验收步骤和后续 `provider-report` 命令提示。
- 联调清单原始结构和 Markdown 输出不得包含 API key。
- `provider-presets`、`provider-checklist` 命令出现在 allowlist，且标记为只读。
- MCP 暴露 `rstudiozhai_provider_presets` 和 `rstudiozhai_provider_checklist` 工具。
- Addin 配置页提供预设选择、应用预设按钮、生成联调清单按钮和结果输出。

### TEST-013J Provider 兼容性矩阵

给定 provider 和网关预设：

- `provider_compatibility_matrix()` 返回稳定 data frame，覆盖 local、mock、openai_responses、Ollama、vLLM、LiteLLM、DeepSeek、DashScope Qwen、SiliconFlow、智谱 GLM、Moonshot Kimi 等目标。
- 矩阵包含 target、target_type、provider、preset、base_url、endpoint、requires_api_key、supports_model_probe、supports_chat_completions、supports_responses、recommended_use、next_step。
- `filter_provider_compatibility_matrix()` 可按 target_type 过滤。
- `format_provider_compatibility_matrix()` 输出可读 Markdown-like 文本，并给出后续 `provider-checklist` / `provider-report` 路径。
- `provider-compatibility` 命令出现在 allowlist，且标记为只读。
- MCP 暴露 `rstudiozhai_provider_compatibility` 工具。
- Addin 配置页提供兼容性矩阵按钮、target_type 过滤和结果输出。

### TEST-006B RStudio 扩展安装验收

给定已安装包：

- `collect_rstudio_extension_status()` 能找到包目录、RStudio、addin DCF、project template DCF、connections DCF、snippets。
- Addin `Binding` 指向导出函数 `run_workbench`。
- Project Template `Binding` 指向导出函数 `create_zh_ai_project`。
- 至少能列出 SQLite、PostgreSQL、ODBC 连接片段。
- `format_rstudio_extension_status()` 输出中文验收报告。
- `rstudio-extension-status` 命令可通过 CLI/MCP 调用。
- `collect_rstudio_extension_status()` 报告用户 `.Rprofile` 启动提示和用户 snippets 的可见入口状态。

### TEST-014 Connections

给定连接模板：

- `list_connection_templates()` 返回 SQLite、PostgreSQL、ODBC。
- `read_connection_snippet()` 能读到包内 snippet。
- `build_dbi_connection_code()` 不硬编码密码。

### TEST-015 RStudio Snippets

给定 bundled snippets：

- `read_bundled_rstudio_snippets()` 能读到 `rzdiag`、`rzreport`。
- `rstudio_user_snippet_path()` 返回平台约定路径。
- `install_rstudio_snippets()` 只写入显式 target，默认不覆盖。
- `install_rstudio_startup_banner()` 能向 `.Rprofile` 写入带标记的启动提示，重复执行不重复写入，并能 clean remove。

### TEST-016 Workbench 中间件 / CLI

给定命令目录：

- `available_workbench_commands()` 返回稳定 allowlist。
- 写文件命令必须标记 `mutates_files = TRUE`。

给定命令调用：

- 未知命令返回 `ok = FALSE` 和 `UNKNOWN_COMMAND`。
- `diagnostics`、`knowledge`、`ai-task` 返回统一 envelope。
- `quarto-draft` 未显式 `allow_write = TRUE` 时不得写文件。
- `connection-template` 生成的 DBI 代码不得硬编码密码。

给定 CLI 参数：

- `parse_workbench_cli_args()` 支持 `--params-json`。
- `encode_workbench_json()` 输出可解析 JSON。
- `workbench_cli_main()` 不重复业务逻辑，只调用命令执行层。

### TEST-017 MCP Server 原型

给定 MCP 工具目录：

- `mcp_tool_definitions()` 返回带 `rstudiozhai_` 前缀的工具名。
- 写文件工具必须标记 `readOnlyHint = FALSE`，但不标记 destructive。
- 每个工具都包含 `inputSchema`。

给定 JSON-RPC 请求：

- `initialize` 返回 serverInfo、capabilities.tools 和协议版本。
- `tools/list` 返回工具定义。
- `tools/call` 调用底层 `run_workbench_command()`。
- 写文件未授权时返回 tool result 的 `isError = TRUE`。
- 未知协议方法返回 `-32601`，通知消息不输出响应。

### TEST-018 Policy 与审计日志

给定写文件命令：

- 未显式 `allow_write = TRUE` 时由统一 policy 拦截，不写文件。
- 如果传入 `audit_path`，被拦截事件也写入审计 JSONL。

给定 AI task：

- 审计日志记录 command、ok、provider、mode、error_code 等必要元数据。
- 审计日志不得包含 API key、password、token、secret。
- 审计日志不得包含完整 task、selection、ai_result，只记录类型和长度。

给定 audit-log 命令：

- 能读取最近审计事件。
- 可输出结构化 data frame 和中文/Markdown-like 摘要。

### TEST-019 Project Scan 项目扫描

给定一个临时 R/RStudio 项目：

- `collect_project_scan()` 返回稳定 list，包含 root、limits、summary、markers、files、markdown。
- 默认跳过 `.git`、`.Rproj.user`、`renv/library`、`node_modules`。
- 默认不读取文件正文；显式 `include_text = TRUE` 时只读取小文本文件。
- 大文件被 `max_bytes` 拦截，二进制文件不进入文本预览。
- `project-scan` 命令出现在 allowlist，且标记为只读。
- MCP 暴露 `rstudiozhai_project_scan` 工具。
- 审计日志不记录扫描到的文件正文。

## 已落地测试

- `tests/base/run-tests.R`
- `tests/testthat/test-ai-contracts.R`
- `tests/testthat/test-addin.R`
- `tests/testthat/test-diagnostics.R`
- `tests/testthat/test-connections.R`
- `tests/testthat/test-compatible-chat-provider.R`
- `tests/testthat/test-jobs.R`
- `tests/testthat/test-knowledge.R`
- `tests/testthat/test-local-provider.R`
- `tests/testthat/test-openai-provider.R`
- `tests/testthat/test-provider-config.R`
- `tests/testthat/test-provider-model-choice.R`
- `tests/testthat/test-provider-probe.R`
- `tests/testthat/test-provider-probe-suggestions.R`
- `tests/testthat/test-provider-integration-report.R`
- `tests/testthat/test-provider-gateway-presets.R`
- `tests/testthat/test-provider-compatibility-matrix.R`
- `tests/testthat/test-provider-registry.R`
- `tests/testthat/test-policy-audit.R`
- `tests/testthat/test-project-scan.R`
- `tests/testthat/test-project-template.R`
- `tests/testthat/test-quarto-report.R`
- `tests/testthat/test-rstudio-extension-status.R`
- `tests/testthat/test-snippets.R`
- `tests/testthat/test-middleware.R`
- `tests/testthat/test-mcp.R`

## 后续测试

- RStudio 内手工验收。
- Quarto 渲染实机集成测试。
- RStudio Jobs 实机点击验收。
- AI provider contract tests。
