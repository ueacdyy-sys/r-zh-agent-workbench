# 接口契约

## EnvironmentReport

```text
EnvironmentReport
  generated_at: string
  r:
    ok: logical
    version: string
    home: string
  rstudio:
    ok: logical
    path: string
    version: string
  quarto:
    ok: logical
    path: string
    version: string
  packages:
    name: string
    installed: logical
  suggestions:
    code: string
    message: string
```

## AiTaskRequest

```text
AiTaskRequest
  task: string
  mode: string
  provider: string
  context: named list
  safety:
    allow_code_execution: logical
    require_user_confirmation: logical
  metadata:
    created_at: string
    client: string
```

## RStudioContext

```text
RStudioContext
  available: logical
  reason: optional string
  project_path: string
  active_document:
    id: string
    path: string
    contents: string
    selection: string
```

约束：

- 在普通 Rscript 中也必须返回稳定结构。
- `contents` 必须有长度上限，避免把大文件直接塞进 AI 请求。
- `selection` 优先作为 AI 上下文。

## AiTaskResponse

```text
AiTaskResponse
  ok: logical
  content: string
  proposed_files: list
  warnings: character vector
  raw: any
```

## Error shape

内部函数遇到可恢复错误时返回结构化结果；不可恢复的开发错误才 `stop()`。

```text
error
  code: string
  message: string
  details: list
```

## Provider contract

AI provider 是一个 R 函数：

```r
provider_fun <- function(request) {
  list(
    ok = TRUE,
    content = "中文回答",
    proposed_files = list(),
    warnings = character(),
    raw = NULL
  )
}
```

约束：

- 必须返回 list。
- 必须包含 `ok`。
- 成功时必须包含非空 `content`。
- provider 返回内容默认不执行。

## LocalProvider contract

```text
local_chinese_provider(request)
  input: AiTaskRequest
  output: AiTaskResponse
```

约束：

- 不调用外部网络。
- 不写文件。
- 不执行代码。
- 输出中文解释和下一步建议。
- 作为真实 AI Provider 的离线基线和失败兜底。

## QuartoReport contract

```text
create_quarto_report(task, ai_result, output_dir, title, include_environment, overwrite)
  returns:
    ok: logical
    path: string
    title: string
    rendered: logical
    render_output: string
```

约束：

- 只生成 `.qmd`，不默认渲染。
- 默认不覆盖已有文件。
- 渲染由 `render_quarto_report()` 单独执行。
- 报告内容必须包含用户任务、AI 工作台结果和可选环境体检。

## QuartoRenderJob contract

```text
run_quarto_render_job(report_path, name, working_dir, script_path, runner)
  returns:
    ok: logical
    mode: "rstudio_job" | "rscript" | "custom_runner"
    script: string
    value: any
    output: string
```

约束：

- `create_quarto_render_job_script()` 只生成脚本，不执行。
- RStudio Jobs 可用时使用 `rstudioapi::jobRunScript()`。
- Jobs 不可用时用 Rscript fallback。
- `runner` 是测试边界，不应泄漏到业务契约之外。

## ProjectTemplate contract

```text
create_zh_ai_project(path, project_name, include_quarto, include_renv_note, ...)
  returns:
    ok: logical
    path: string
    files: character vector
```

约束：

- 函数必须可由 RStudio Project Template DCF 的 `Binding` 字段找到。
- 默认生成 `README.md`、`R/analysis.R`、`scripts/setup.R`、`reports/analysis.qmd`。
- 不写入密钥、不安装包、不自动执行外部命令。

## KnowledgeBase contract

```text
lookup_rstudio_term(query, max_results)
search_rstudio_commands(query, max_results)
explain_r_error(message, max_results)
summarize_knowledge_for_query(query, error_message)
```

约束：

- 数据来自包内 `inst/extdata/knowledge/`，不依赖网络。
- 查询必须返回 data frame 或空 data frame，不返回不稳定对象。
- 空查询应被拒绝。
- 本地 Provider 可以引用知识库结果，但不得执行知识库内容。

## ExternalProvider contract

```text
openai_responses_provider(request, api_key, model, base_url, http_post, ...)
  input: AiTaskRequest
  output: AiTaskResponse
```

约束：

- `api_key` 默认从 `OPENAI_API_KEY` 读取。
- `model` 默认从 `RSTUDIOZHAI_OPENAI_MODEL` 读取。
- 不在包内硬编码唯一模型。
- `http_post` 可注入，便于测试、企业网关和未来中间件复用。
- 第三方响应通过 `extract_openai_response_text()` 抽取为字符串后再进入 `AiTaskResponse`。
- raw response 可以保存在 `raw$response`，但不得包含 API key。

## CompatibleChatGateway contract

```text
compatible_chat_provider(request, api_key, model, base_url, endpoint, http_post, ...)
  input: AiTaskRequest
  output: AiTaskResponse
```

约束：

- 面向本地或企业 OpenAI-compatible Chat Completions 网关，比如 Ollama、vLLM、LiteLLM 或内部代理。
- `model` 必须来自 `RSTUDIOZHAI_GATEWAY_MODEL` 或显式参数，不在包内硬编码。
- `base_url` 默认可指向本机 OpenAI-compatible 网关，但企业部署可以改为内网 URL。
- `api_key` 可选，本地网关允许为空；如果存在也不得写入 raw response、审计日志或状态输出。
- 请求使用 `messages` 契约，system message 必须保留中文输出、不得声称已执行代码、写入前需确认等安全边界。
- `http_post` 可注入，便于测试、本地中间件和企业代理复用。
- 第三方响应通过 `extract_compatible_chat_response_text()` 抽取为字符串后再进入 `AiTaskResponse`。

## ProviderRegistry contract

```text
list_ai_providers()
provider_config_status(provider, config)
resolve_ai_provider(provider, provider_fun)
provider_choice_labels()
```

约束：

- Provider 元数据必须稳定返回 data frame，供 Addin、CLI、MCP 共用。
- `local` 和 `mock` 不需要网络、不需要密钥。
- `openai_responses` 只读取环境变量或显式参数，不把 API key 写入项目文件。
- `compatible_chat` 支持本地模型和企业网关，API key 可选但 model 必须配置。
- 配置状态可以告诉用户缺少哪些环境变量，但不得回显密钥值。
- 自定义 provider 必须显式通过 `provider_fun` 注入，不从字符串动态查找任意函数。
- Addin UI 只能通过 registry 选择 provider，避免 UI 和 provider 实现耦合。

## ProviderConfig contract

```text
provider_config_fields()
build_provider_config(provider, values)
provider_config_status_from_values(provider, values)
provider_from_config(provider, config, http_post)
```

约束：

- 配置值可以来自 Addin 表单、CLI 宿主或环境变量，但不得写入项目文件。
- API key、token 等 secret 字段只在当前 R 会话内传给 provider，不得出现在 `format_provider_status()` 输出。
- `provider_from_config()` 返回绑定配置的 provider 函数，供 Addin 运行任务时使用。
- 只支持内置 provider 的显式配置，不根据字符串动态查找任意函数。
- HTTP transport 仍可注入，便于 TDD、企业代理和离线验证。

## ProviderProbe contract

```text
probe_provider_models(provider, config, http_get, timeout_seconds)
extract_provider_model_ids(response)
format_provider_probe(probe)
provider_model_choices(probe)
apply_provider_model_choice(provider, values, selected_model)
suggest_provider_probe_actions(probe)
```

约束：

- 只读调用 provider 的模型列表端点，默认不执行 AI 任务、不写文件。
- 对 OpenAI-compatible provider 使用 `base_url + "/models"`。
- HTTP GET 可注入，便于 TDD、离线验证和企业代理。
- 支持常见 `data[].id`、`models[].name`、`models[].model` 响应结构。
- API key 只作为请求头使用，不进入 probe result、Markdown 输出或审计日志。
- 探测失败返回结构化 `ok = FALSE`、`error$code`、`error$message`，不让底层异常直接泄露到 UI。
- `provider-probe` 命令和 MCP 工具均标记为只读，但属于 open-world 网络能力。
- 探测到的模型可以转换成 UI 选择项，再回填到对应 provider 的内存配置值。
- 模型回填只更新当前 Addin 会话，不写环境变量或项目文件。
- 探测失败或模型列表为空时必须返回中文修复建议，覆盖缺模型、连不上本地/企业网关、401/403、404 和空模型列表等常见场景。

## ProviderIntegrationReport contract

```text
collect_provider_integration_report(provider, values, config, include_environment, include_extension, probe_fun, timeout_seconds)
  returns:
    generated_at: string
    provider: string
    overall_ok: logical
    registry: list
    status: provider_config_status result
    config:
      provider: string
      has_api_key: logical
      model: string
      base_url: string
      endpoint: string
    probe:
      result: ProviderProbe result
      suggestions: data frame
    environment: optional EnvironmentReport
    extension: optional RStudioExtensionStatus
    markdown: string
```

约束：

- 只读聚合本地/企业 AI 网关联调状态，不执行 AI 任务、不写文件。
- 不返回 `api_key`、password、token、secret 或 Authorization 等敏感值。
- `probe_fun` 必须可注入，测试和离线验收不得依赖真实网络。
- 第三方或注入 probe 结果进入报告前必须脱敏。
- `overall_ok` 只由 provider 配置状态和模型探测结果决定；环境和扩展状态作为排障上下文，不阻断 provider 判定。
- Markdown 输出必须包含 provider 状态、安全配置摘要、模型探测结果、中文修复建议，以及可选环境/扩展报告。
- `provider-report` CLI 命令和 `rstudiozhai_provider_report` MCP 工具均标记为只读；由于可能探测网关，MCP 标记为 open-world。
- Addin 配置页可以一键生成联调报告，但不落盘、不写环境变量。

## ProviderGatewayPreset contract

```text
provider_gateway_presets()
  returns data frame:
    preset: string
    label: string
    provider: string
    base_url: string
    endpoint: string
    requires_api_key: logical
    default_model: string
    description: string

provider_values_from_gateway_preset(preset, model, base_url, endpoint, api_key)
  returns:
    gateway_api_key: string
    gateway_model: string
    gateway_base_url: string
    gateway_endpoint: string

collect_provider_integration_checklist(preset, model, base_url, endpoint, api_key, include_report_command)
  returns:
    preset: string
    provider: string
    values: safe compatible-chat config values
    steps: data frame
    markdown: string
```

约束：

- 预设只覆盖 OpenAI-compatible Chat Gateway，不影响 `openai_responses` 官方 API provider。
- 内置预设至少包含 Ollama、vLLM、LiteLLM 和企业兼容网关。
- 预设输出不得包含真实密钥；只有 `provider_values_from_gateway_preset()` 在调用者显式传入时返回当前会话内配置值。
- 联调清单是只读人工验收材料，不启动服务、不执行网络探测、不写文件。
- 联调清单可以生成后续 `provider-report` 命令参数提示，但不得把 API key 写进 Markdown。
- `provider-presets`、`provider-checklist` CLI 命令和对应 MCP 工具均为只读、非 open-world。
- Addin 配置页可以应用预设到当前会话输入框；不写环境变量或项目文件。

## ProviderCompatibilityMatrix contract

```text
provider_compatibility_matrix()
  returns data frame:
    target: string
    target_type: "offline" | "openai_api" | "local_gateway" | "cloud_gateway" | "enterprise_gateway"
    provider: string
    preset: string
    label: string
    base_url: string
    endpoint: string
    requires_api_key: logical
    needs_network: logical
    supports_model_probe: logical
    supports_chat_completions: logical
    supports_responses: logical
    default_model: string
    recommended_use: string
    next_step: string

filter_provider_compatibility_matrix(matrix, target_type)
format_provider_compatibility_matrix(matrix)
```

约束：

- 矩阵是只读能力目录，不执行网络探测、不调用模型、不写文件。
- 矩阵必须覆盖离线 provider、OpenAI Responses API、内置本地网关预设、云端兼容网关预设和企业兼容网关预设。
- 新增网关只能追加行或追加可选字段，不改变已有列语义。
- `provider-compatibility` CLI 命令和 `rstudiozhai_provider_compatibility` MCP 工具均为只读、非 open-world。
- Addin 配置页可以查看兼容性矩阵并按 target_type 过滤，但不能从矩阵直接执行外部命令。

## Connections contract

```text
list_connection_templates()
read_connection_snippet(id)
build_dbi_connection_code(kind, variable, use_password_prompt)
```

约束：

- Connection snippets 存放在 `inst/rstudio/connections/`。
- `connections.dcf` 存放在 `inst/rstudio/connections.dcf`。
- 生成连接代码不得硬编码密码。
- 密码来源只能是 `rstudioapi::askForPassword()` 或环境变量。

## CodeSnippets contract

```text
read_bundled_rstudio_snippets(language)
rstudio_user_snippet_path(language)
install_rstudio_snippets(language, target, overwrite, backup)
```

约束：

- bundled snippets 只读。
- 安装到用户目录必须显式调用。
- 默认不覆盖已有 snippet 文件。
- 覆盖时默认创建备份。

## Workbench app contract

```text
create_workbench_app(provider_fun, provider_name, context_collector)
  returns:
    ui: Shiny UI object
    server: Shiny server function
```

约束：

- 构造函数不启动 Shiny，不依赖 RStudio 窗口。
- `run_workbench()` 只负责依赖检查、创建 viewer、启动 gadget。
- 这样 Addin UI 可以进入 `testthat`，不需要手工点击才能发现基础错误。

## RStudioExtensionStatus contract

```text
collect_rstudio_extension_status()
  returns:
    overall_ok: logical
    package:
      installed: logical
      path: string
      version: string
    rstudio:
      ok: logical
      path: string
      version: string
    addin:
      ok: logical
      path: string
      binding: string
      binding_exported: logical
    project_template:
      ok: logical
      path: string
      binding: string
      binding_exported: logical
    connections:
      ok: logical
      path: string
    snippets:
      ok: logical
      path: string
    connection_snippets: list
    suggestions: list
```

约束：

- 只读检查，不启动 RStudio、不写用户配置。
- 解析 RStudio DCF 元数据，确认 Binding 指向包内导出函数。
- 返回真实安装路径，便于人工核对 Addins 菜单、Project Template 和 Connections。
- `format_rstudio_extension_status()` 输出中文验收报告。
- 该能力接入 CLI/MCP，外部 Agent 可以先检查插件接入状态。

## WorkbenchCommand contract

```text
available_workbench_commands()
  returns data frame:
    command: string
    description: string
    mutates_files: logical
    long_running: logical

run_workbench_command(command, params, provider_fun)
  returns:
    ok: logical
    command: string
    data: list
    warnings: character vector
    error:
      code: string
      message: string
      details: list
    metadata:
      created_at: string
      package_version: string
```

约束：

- 命令必须来自显式 allowlist，不调用 RStudio 内部未公开 helper。
- 所有可恢复错误返回统一 envelope，不把底层异常直接暴露给外部 Agent。
- 写文件命令必须要求 `allow_write = TRUE`，默认只读。
- 长任务必须在命令目录里标记 `long_running`，后续可路由到 Jobs 或子进程。
- 中间件输入输出必须可以 JSON 序列化，服务 CLI、Addin、MCP Server 共用。
- `provider-status` 返回 provider 配置状态，不触发外部网络请求。
- `rstudio-extension-status` 返回 RStudio 扩展资源状态，不启动 RStudio。

## ProjectScan contract

```text
collect_project_scan(path, max_files, max_bytes, include_patterns, exclude_dirs, include_text)
  returns:
    root: string
    limits:
      max_files: integer
      max_bytes: integer
      include_text: logical
      include_patterns: character vector
      exclude_dirs: character vector
    summary:
      files_returned: integer
      files_truncated: logical
      directories_scanned: integer
      excluded_dirs: integer
      total_bytes: numeric
      text_files: integer
      skipped_large: integer
      skipped_binary: integer
      by_extension: data frame
    markers: data frame
    files: data frame
    markdown: string
```

约束：

- 默认只读目录结构和文件元数据，不读取文件正文。
- 只有显式 `include_text = TRUE` 时才读取小文本预览。
- 默认跳过 `.git`、`.Rproj.user`、`renv/library`、`node_modules`、Quarto 输出目录和 R check 目录。
- 单文件文本读取必须受 `max_bytes` 限制，大文件和二进制文件不得进入上下文正文。
- 输出必须可 JSON 序列化，供 CLI/MCP/未来 Addin 共用。
- `project-scan` 是只读命令，审计日志不得记录文件正文。

## Policy and audit contract

```text
check_workbench_policy(command, params, catalog)
summarize_audit_params(params)
append_workbench_audit_event(path, event)
read_workbench_audit_log(path, limit)
```

约束：

- 写文件命令必须由统一 policy 检查 `allow_write = TRUE`。
- 默认不写审计日志；只有显式传入 `audit_path` 或设置审计路径时才写 JSONL。
- 审计日志不得记录 API key、password、token、secret、Authorization 等敏感值。
- 审计日志不得记录完整 task、selection、ai_result 等可能包含代码或业务数据的大文本，只记录类型、长度和必要元数据。
- 审计失败不得掩盖原命令结果，但要作为 warning 返回。
- `audit-log` 命令只读读取 JSONL，供 CLI/MCP/企业审计查看。

## Workbench CLI contract

```text
parse_workbench_cli_args(args)
encode_workbench_json(result)
workbench_cli_main(args, output)
```

约束：

- CLI 默认输出 JSON envelope。
- 参数可以来自 `--params-json` 或 `--params-file`。
- 缺少 `jsonlite` 时返回清晰依赖错误。
- CLI 是中间件外壳；核心命令仍由 `run_workbench_command()` 执行，避免重复业务逻辑。

## MCP Server contract

```text
mcp_tool_definitions()
mcp_handle_request(request)
mcp_handle_json_line(line)
mcp_stdio_server(input, output)
```

约束：

- MCP Server 使用 stdio transport，适合本地桌面和单用户开发环境。
- 协议层实现 `initialize`、`ping`、`tools/list`、`tools/call`。
- 工具名使用 `rstudiozhai_` 前缀，避免和其他 MCP Server 冲突。
- 工具调用必须复用 `run_workbench_command()`，不复制业务逻辑。
- 工具错误返回 `isError = TRUE` 的 tool result；协议格式错误才返回 JSON-RPC error。
- Server 不向 stdout 写日志，避免污染 stdio 协议。
- 响应文本默认 JSON，可被外部 Agent 稳定解析；长响应必须截断并提示。
