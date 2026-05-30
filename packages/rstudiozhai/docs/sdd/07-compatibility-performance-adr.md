# ADR-002 兼容性、效率和性能决策

## 状态

Accepted.

## 背景

RStudio Desktop 的公开 CLI 更偏向启动、版本、日志和诊断，不适合作为完整 IDE 自动化 API。RStudio 插件开发最稳定的入口是 R 包 Addin、`rstudioapi`、Project Templates、Snippets、Connections、Jobs、Terminal 与 Quarto CLI。

本项目要兼顾：

- 对 RStudio Desktop 升级友好。
- 对普通 Windows 用户安装友好。
- 对 AI 调用和文件写入保持安全。
- 对长任务和大上下文保持性能可控。

## 决策

### 1. 第一阶段不 fork RStudio

采用：

```text
R package + RStudio Addin + rstudioapi + Shiny/miniUI
```

拒绝第一阶段 fork RStudio 本体，原因：

- RStudio 本体技术栈复杂，构建和分发成本高。
- 完整 UI 汉化涉及许可证、签名、升级兼容和重新打包。
- 插件生态空缺可以先通过官方入口覆盖。

### 2. 核心逻辑不依赖 RStudio 运行时

核心函数必须能在普通 Rscript 中测试：

- `collect_environment_report()`
- `build_ai_task_request()`
- `invoke_ai_provider()`
- `format_workbench_result()`

RStudio 相关能力放在适配层：

- `collect_rstudio_context()`
- `run_workbench()`
- `create_workbench_app()`

### 3. Provider 适配器替代厂商绑定

AI 服务通过函数注入：

```r
run_workbench(provider_fun = my_provider)
```

Provider 必须返回统一 shape：

```r
list(
  ok = TRUE,
  content = "...",
  proposed_files = list(),
  warnings = character(),
  raw = NULL
)
```

这样后续可以接 OpenAI、本地模型、企业网关，Addin UI 不需要重写。

第一阶段默认 provider 是 `local_chinese_provider()`：

- 不需要密钥。
- 不访问网络。
- 不写文件。
- 不执行代码。
- 作为外部 AI 不可用时的兜底能力。

外部 AI provider 采用适配器而不是直接把 SDK 写进核心逻辑：

- OpenAI Responses provider 使用 `httr2` 和 `jsonlite`，仅在调用时需要。
- API key 从环境变量或显式参数读取。
- 模型名从环境变量或显式参数读取，不在包内追逐“最新模型”。
- HTTP transport 可注入，用于测试、代理网关和未来中间件。

### 4. 上下文默认裁剪

`collect_rstudio_context(max_chars = 12000L)` 默认裁剪当前文档内容。

原因：

- 避免一次把大文件塞进 AI 请求。
- 控制 token 成本和响应延迟。
- 降低隐私风险。

### 5. 写文件和执行代码默认需要确认

`build_ai_task_request()` 默认：

```r
allow_code_execution = FALSE
require_user_confirmation = TRUE
```

原因：

- AI 建议可以自动生成，但落地执行必须可控。
- 后续中间件/MCP 模式也必须继承这条边界。

### 6. 长任务不在 UI 线程里做

Quarto 渲染、项目扫描、R CMD check、包安装、AI 批处理属于长任务。

策略：

- 第一阶段只在 UI 中生成请求和显示结果。
- 第二阶段把长任务放入 Jobs、Rscript 子进程或本地任务队列。
- 任务输出写日志，UI 只显示摘要和链接。

### 7. Quarto 生成和渲染分离

`.qmd` 文件生成是轻量任务，可以同步完成。

Quarto 渲染可能涉及 Pandoc、执行代码块、读取数据和生成图表，因此必须独立封装为 `render_quarto_report()`，后续再接 RStudio Jobs。

### 8. Jobs 适配必须有 fallback

RStudio Jobs 是理想入口，但测试、Rscript、CI 和非 RStudio 环境都没有 Jobs Pane。

因此 `run_quarto_render_job()` 的策略是：

- RStudio Jobs 可用：使用 `rstudioapi::jobRunScript()`。
- Jobs 不可用：使用当前 R 的 `Rscript`。
- 测试：注入 `runner`，验证契约而不是启动真实 IDE。

### 9. Project Templates 只做脚手架，不做安装器

Project Template 负责创建目录和 starter 文件。

它不负责安装包、不初始化远程服务、不保存 API key，原因是模板创建发生在用户刚开始项目时，副作用越少越兼容。

### 10. 中文知识库先使用包内静态表

术语、命令入口和常见错误解释使用 `inst/extdata/knowledge/` 中的 CSV。

原因：

- 离线可用。
- 可测试。
- 不需要数据库或服务端。
- 未来可以替换为 SQLite、向量索引或企业知识库，但当前公开契约不变。

### 11. 数据连接不保存密码

Connections 和 DBI 代码生成只提供连接骨架。

密码只能来自：

- `rstudioapi::askForPassword()`
- 环境变量，例如 `DB_PASSWORD`

这样可以兼容本地开发、企业环境变量注入和未来密钥管理工具。

### 12. Snippets 安装显式触发

RStudio snippets 写入用户配置目录，属于用户状态。

因此包只内置 snippets 文件，并提供 `install_rstudio_snippets()`；默认不自动安装、不覆盖已有文件。

## 后果

收益：

- 与 RStudio 升级解耦。
- 测试速度快。
- 用户安装路径简单。
- 后续可平滑扩展到中间件和 MCP。

代价：

- 无法替换 RStudio 原生菜单和全部界面文本。
- Addin UI 的嵌入深度低于本体插件。
- 复杂后台任务需要第二阶段再补任务队列。

## 验证方式

- `Rscript tests/base/run-tests.R`
- `pkgload::load_all("."); testthat::test_dir("tests/testthat")`
- `R CMD check --no-manual --no-build-vignettes`
- 安装包后确认 `run_workbench` 可在 namespace 中找到。
