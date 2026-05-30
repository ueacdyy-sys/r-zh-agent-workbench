# rstudiozhai: RStudio 中文 AI 工作台

这是一个面向 RStudio Desktop 工作流的中文 AI 工作台 R 包。它是独立社区项目，不是 Posit 或 RStudio 官方项目。

目标不是 fork RStudio 本体，而是优先使用官方稳定入口：

- RStudio Addins
- `rstudioapi`
- Project Templates
- Jobs / Terminal
- Quarto CLI
- Connections Contract

当前阶段采用 SDD/TDD：

- SDD：先写需求规格、架构边界、接口契约和技术决策，再实现。
- TDD：先写可运行测试，逐步补实现；测试关注用户可观察行为和外部契约。

## 当前最小能力

- 生成本机 RStudio/R/Quarto/R 包环境诊断报告。
- 定义中文 AI 工作台的任务请求契约。
- 支持可插拔 AI Provider 函数，默认使用本地中文规则型 provider；保留 mock provider 作为测试替身。
- 提供 RStudio Addin 入口，并把 UI 构造与启动解耦，方便测试。
- 通过 `rstudioapi` 采集当前项目、当前文件和选区上下文；非 RStudio 环境返回稳定结构。
- 可以生成 Quarto `.qmd` 报告草稿，渲染步骤与生成步骤解耦。
- 可以通过 RStudio Jobs 或 Rscript fallback 渲染 Quarto 报告。
- 提供 RStudio Project Template，生成可复现分析项目骨架。
- 内置中文知识库：RStudio 术语、常用命令入口、常见 R 报错解释。
- 提供 OpenAI Responses API provider adapter；默认不硬编码模型，使用环境变量或显式参数。
- 提供 OpenAI-compatible Chat Gateway provider，可接本地 Ollama/vLLM/LiteLLM 或企业内网代理，API key 可选。
- 提供 Provider Registry：Addin、CLI、MCP 共用 provider 列表、配置状态检查和 provider 选择逻辑。
- 提供 Addin 内 provider 配置页，支持模型、base URL、endpoint 和可选 API key 的会话内配置。
- 提供 provider 模型探测：只读调用 `/models` 检查本地模型或企业网关连通性。
- 支持把探测到的模型回填到 Addin 当前会话的模型输入框，不写环境变量或项目文件。
- provider 探测失败时输出中文修复建议，覆盖缺模型、连不上服务、401/403、404 和空模型列表。
- 提供本地/企业网关联调报告：聚合 provider 状态、安全配置摘要、模型探测、中文修复建议、环境体检和 RStudio 扩展验收，且不泄露 API key。
- 提供 Ollama、LM Studio、Xinference、vLLM、LiteLLM、DeepSeek、DashScope Qwen、SiliconFlow、智谱 GLM、Moonshot Kimi、企业 OpenAI-compatible 网关预设和人工联调清单，帮助用户先完成安全接入验收。
- 提供 Provider 兼容性矩阵，结构化列出离线 provider、OpenAI Responses、本地网关、云端兼容网关、企业网关的能力差异和下一步。
- 提供 RStudio 扩展安装验收报告：检查 Addin、Project Template、Connections、Snippets 的真实安装状态。
- 提供可治理的 RStudio 可见入口安装器：可向用户 `.Rprofile` 写入带标记的启动中文提示，并可备份、重复执行、卸载。
- 提供只读项目扫描：识别 R 包、RStudio Project、Quarto、Shiny、testthat、renv 等结构，默认不读取文件正文。
- 提供可选 JSONL 审计日志和统一写文件 policy，便于企业/团队场景追踪 CLI/MCP/Addin 命令。
- 提供 RStudio Connection Snippets 和安全 DBI 连接代码生成。
- 提供 RStudio R snippets，安装到用户目录必须显式调用，不自动写用户配置。
- 提供本地 JSON/CLI 中间件命令层，服务后续 MCP Server、外部 Agent 和企业自动化。
- 提供 stdio MCP Server 原型，暴露 `rstudiozhai_` 前缀工具给外部 AI Agent。
- 使用 `testthat` 覆盖 AI 契约、环境体检、Addin 构造和上下文采集。

## 为什么先做 R 包 Addin

RStudio Desktop 的 `rstudio.exe` 有 CLI，但主要用于版本、日志和诊断。要做真实二次开发，最稳的方式是 R 包 Addin + `rstudioapi`。这样不需要修改 RStudio 本体，兼容性、升级风险和分发成本都更好。

## 快速验证

在本目录运行：

```powershell
& "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" tests/base/run-tests.R
```

开发态 testthat 验证：

```powershell
& "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" -e "pkgload::load_all('.'); testthat::test_dir('tests/testthat', reporter='summary')"
```

正式包验证：

```powershell
& "C:\Program Files\R\R-4.6.0\bin\x64\R.exe" CMD build .
& "C:\Program Files\R\R-4.6.0\bin\x64\R.exe" CMD check --no-manual --no-build-vignettes rstudiozhai_0.0.1.tar.gz
```

## SDD/TDD 文档

- `docs/sdd/00-product-vision.md`
- `docs/sdd/01-requirements.md`
- `docs/sdd/02-architecture.md`
- `docs/sdd/03-contracts.md`
- `docs/sdd/04-tdd-plan.md`
- `docs/sdd/05-tech-stack-adr.md`
- `docs/sdd/06-ecosystem-roadmap.md`
- `docs/sdd/07-compatibility-performance-adr.md`

## 当前 Provider 策略

默认 provider 是 `local_chinese_provider()`：

- 不需要 API key。
- 不上传代码。
- 适合作为离线基线、快速诊断和真实大模型接入前的兜底能力。

后续接入外部大模型时，可以先检查 provider 状态：

```r
list_ai_providers()
provider_config_status("openai_responses")
provider_config_status("compatible_chat")
```

也可以传入新的 provider 函数：

```r
run_workbench(provider_fun = my_provider, provider_name = "my_provider")
```

Provider 返回值必须符合 `AiTaskResponse` 契约。

OpenAI Responses provider 使用：

```r
Sys.setenv(OPENAI_API_KEY = "...")
Sys.setenv(RSTUDIOZHAI_OPENAI_MODEL = "your-model")
run_workbench(provider_fun = openai_responses_provider, provider_name = "openai_responses")
```

包不会把 API key 写入项目文件；测试通过注入 `http_post` 完成，不需要真实网络。

本地模型或企业网关可以使用 OpenAI-compatible Chat Completions：

```r
Sys.setenv(RSTUDIOZHAI_GATEWAY_BASE_URL = "http://127.0.0.1:11434/v1")
Sys.setenv(RSTUDIOZHAI_GATEWAY_MODEL = "your-local-model")
provider_config_status("compatible_chat")
run_workbench(provider_name = "compatible_chat")
```

如果企业网关需要密钥，再设置 `RSTUDIOZHAI_GATEWAY_API_KEY`；本地网关可以为空。包不会回显或写入该密钥。

Addin UI 现在提供 provider 选择、配置页和配置状态提示；OpenAI 缺少 `OPENAI_API_KEY` / `RSTUDIOZHAI_OPENAI_MODEL`，或 compatible chat 缺少 `RSTUDIOZHAI_GATEWAY_MODEL` 时会先提示缺项，不会回显密钥值。配置页填写的 key 只在当前 R 会话内传给 provider，不写项目文件。

配置页还提供“探测模型”按钮，对 OpenAI-compatible 网关只读调用 `/models`。这一步只检查连通性和模型列表，不执行 AI 任务、不写文件；失败会返回结构化错误，方便后续做中文修复建议。

探测成功后，可以从模型选择框里选择模型并回填到当前 provider 的模型输入框；回填只影响当前 Addin 会话。

探测失败时，输出会包含“修复建议”：例如先启动 Ollama/vLLM/LiteLLM、核对 base URL 是否包含 `/v1`、检查 API key、确认企业网关是否支持 `/models`。

本地模型或企业网关联调前，可以生成只读联调报告：

```r
report <- collect_provider_integration_report(
  "compatible_chat",
  values = list(
    gateway_model = "your-local-model",
    gateway_base_url = "http://127.0.0.1:11434/v1",
    gateway_endpoint = "/chat/completions"
  )
)
cat(format_provider_integration_report(report))
```

报告会显示是否配置模型、base URL、endpoint、是否存在 API key、`/models` 探测结果和中文修复建议；不会回显 key 值。

也可以先查看网关预设并生成只读人工联调清单：

```r
provider_gateway_presets()
checklist <- collect_provider_integration_checklist(
  preset = "ollama",
  model = "your-local-model"
)
cat(format_provider_integration_checklist(checklist))
```

内置预设包含 `ollama`、`lmstudio`、`xinference`、`vllm`、`litellm`、`deepseek`、`dashscope_qwen`、`siliconflow`、`zhipu_glm`、`moonshot_kimi`、`enterprise_compatible`。预设只应用到当前会话输入值，不写环境变量、不写项目文件；清单会给出下一步 `provider-report` 命令提示，但不会把 API key 写进 Markdown。

兼容性矩阵可以用来快速判断目标接入方式：

```r
matrix <- provider_compatibility_matrix()
cloud <- filter_provider_compatibility_matrix(matrix, target_type = "cloud_gateway")
cat(format_provider_compatibility_matrix(cloud))
```

## 本地 CLI / 中间件

包内提供稳定命令层：

```r
available_workbench_commands()
run_workbench_command("diagnostics", list(packages = "stats"))
run_workbench_command("knowledge", list(query = "quarto"))
run_workbench_command("rstudio-extension-status")
run_workbench_command("project-scan", list(path = getwd(), max_files = 100))
run_workbench_command("provider-probe", list(provider = "compatible_chat"))
run_workbench_command("provider-report", list(provider = "compatible_chat"))
run_workbench_command("provider-presets")
run_workbench_command("provider-checklist", list(preset = "ollama", model = "your-local-model"))
run_workbench_command("provider-compatibility", list(target_type = "cloud_gateway"))
run_workbench_command("audit-log", list(path = "audit.jsonl"))
```

安装后可用脚本入口：

```powershell
& "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" `
  -e "rstudiozhai::workbench_cli_main(c('knowledge', '--params-json', '{\"query\":\"quarto\"}'))"
```

写文件命令默认会被拦截，必须显式传入 `allow_write = TRUE`。这层以后可以直接接 MCP Server，不需要把 RStudio 内部 helper 当公开 API。

## MCP Server 原型

安装后脚本入口：

```powershell
$script = & "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" `
  -e "cat(system.file('scripts', 'rstudiozhai-mcp.R', package='rstudiozhai'))"

'{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' |
  & "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" $script
```

当前 MCP 工具：

- `rstudiozhai_list_commands`
- `rstudiozhai_diagnostics`
- `rstudiozhai_provider_status`
- `rstudiozhai_provider_probe`
- `rstudiozhai_provider_report`
- `rstudiozhai_provider_presets`
- `rstudiozhai_provider_checklist`
- `rstudiozhai_provider_compatibility`
- `rstudiozhai_rstudio_extension_status`
- `rstudiozhai_project_scan`
- `rstudiozhai_audit_log`
- `rstudiozhai_search_knowledge`
- `rstudiozhai_run_ai_task`
- `rstudiozhai_create_quarto_draft`
- `rstudiozhai_connection_template`

MCP Server 复用 `run_workbench_command()`，工具错误以 `isError = TRUE` 返回，协议错误才走 JSON-RPC error。写文件工具仍然必须显式 `allow_write = TRUE`。

## RStudio 扩展验收

安装后可以运行：

```r
status <- collect_rstudio_extension_status()
cat(format_rstudio_extension_status(status))
```

该报告会检查：

- Addin DCF 是否存在，`Binding` 是否指向导出函数 `run_workbench`。
- Project Template DCF 是否存在，`Binding` 是否指向导出函数 `create_zh_ai_project`。
- Connections DCF 和 SQLite/PostgreSQL/ODBC 连接片段是否存在。
- 包内 R snippets 是否存在。
- RStudio Desktop 路径和版本是否可检测。
- 用户 `.Rprofile` 是否已经安装启动中文提示。
- 用户 RStudio snippets 是否已经写入。

如果希望打开 RStudio 时立刻看到中文入口提示，可以运行：

```r
install_rstudio_visible_entry()
```

它会在用户 `.Rprofile` 中写入带标记的启动提示，并安装 R snippets。已有 `.Rprofile` 会先备份；需要撤销时运行：

```r
remove_rstudio_startup_banner()
```

## 策略与审计

写文件命令会先经过统一 policy：没有 `allow_write = TRUE` 会被拒绝。审计日志默认不写，显式传入 `audit_path` 或设置 `RSTUDIOZHAI_AUDIT_LOG` 后才写 JSONL：

```r
run_workbench_command(
  "ai-task",
  list(task = "解释代码", provider = "local", audit_path = "audit.jsonl")
)
run_workbench_command("audit-log", list(path = "audit.jsonl"))
```

审计日志会记录命令、状态、provider、mode、错误码等元数据；API key、password、token、secret 和大段 task/selection/ai_result 不会原样写入日志。

## 项目扫描

`project-scan` 是后续 AI 代码助手和企业中间件的上下文入口。默认只返回文件结构、扩展名统计和关键标记，不读取源码正文；需要小文本预览时必须显式开启：

```r
run_workbench_command(
  "project-scan",
  list(path = getwd(), max_files = 120, max_bytes = 4096, include_text = TRUE)
)
```

扫描会默认跳过 `.git`、`.Rproj.user`、`renv/library`、`node_modules`、Quarto 输出目录和 R check 目录，避免把依赖缓存或历史文件塞进 AI 上下文。
