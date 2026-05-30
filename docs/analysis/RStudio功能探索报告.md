# RStudio 功能与二次开发入口探索报告

调查对象：RStudio Desktop `2026.05.0+218`

本机路径：

- RStudio: `C:\Program Files\RStudio\rstudio.exe`
- RStudio 应用资源：`C:\Program Files\RStudio\resources\app`
- R: `C:\Program Files\R\R-4.6.0`
- Quarto: `C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe`

结论先说：

RStudio Desktop 不是一个面向外部自动化的“完整 CLI 产品”，它的命令行入口偏启动、诊断、日志和版本信息。真正适合二次开发的口子主要有四类：

1. R 包 Addins：最正式、最稳的插件入口。
2. `rstudioapi`：从 R 代码控制 IDE 文档、终端、项目、命令、作业、主题、Viewer 等。
3. Project Templates / Connection Snippets / Connections Contract：适合做项目脚手架、数据源集成、中间件。
4. Quarto / Shiny / Plumber / rsconnect / renv / reticulate：不是 RStudio 插件本体，但 RStudio 对这些生态有强集成，适合做周边产品。

## 1. 本机安装结构

RStudio Desktop 当前是 Electron 外壳 + 本地 R session 后端 + 内置 Web UI 的结构。

关键文件：

- `rstudio.exe`：Electron 桌面入口。
- `resources\app\package.json`：显示产品名、版本、Electron 依赖与源码仓库。
- `resources\app\SOURCE`：指向当前版本源码 commit。
- `resources\app\bin\rsession.exe`：RStudio 的 R 后端 session。
- `resources\app\bin\rpostback.exe`：内部 postback 命令工具。
- `resources\app\bin\diagnostics.exe`：诊断信息工具。
- `resources\app\bin\quarto\bin\quarto.exe`：内置 Quarto CLI。
- `resources\app\R\modules`：RStudio session 侧 R 模块，共 87 个 `.R` 文件。
- `resources\app\resources\schema\user-prefs-schema.json`：用户设置 schema，约 290 个偏好项。
- `resources\app\resources\schema\user-state-schema.json`：用户状态 schema，约 31 个状态项。

当前版本源码：

```text
https://github.com/rstudio/rstudio/tree/89f6cef5d8593410108e06a82f290fd952d506c1
```

许可证：

RStudio Desktop 开源版本使用 AGPL-3.0。后续如果要改 RStudio 本体或分发衍生版本，需要认真看 AGPL 义务；如果只是写 R 包插件、外部工具、中间件，风险小很多。

## 2. 官方功能全景

官方 2026.05.0 用户指南把 RStudio 功能分成这些大类：

- Accessibility：简化界面、屏幕阅读器支持。
- User Interface：窗格布局、文件管理、主题、命令面板。
- Code：R Console、Projects、执行代码、诊断、调试、代码折叠、代码导航。
- Data：Data Viewer、本地数据导入、Connections Pane、Connection Snippets、Connections Contract。
- Tools：Terminal、Jobs、Version Control、GitHub Copilot、Posit Assistant。
- Productivity：文本编辑器、RStudio Addins、代码片段、自定义快捷键、Project Templates、自定义设置。
- Computational Documents：Visual Editor、Quarto Integration。
- Deploy：连接发布账号、发布内容。
- Package Development：R 包开发。
- Environments：管理 R、包仓库、renv、Python。
- Troubleshooting：启动问题、重置状态、日志、诊断报告。

参考：[RStudio User Guide 2026.05.0](https://docs.posit.co/ide/user/)

## 3. CLI 接口调查

### 3.1 `rstudio.exe` 支持的参数

本机 `rstudio.exe --help` 输出：

```text
--version
--version-json
--run-diagnostics
--log-level=ERROR|WARNING|INFO|DEBUG|TRACE
--log-dir
--session-delay
--session-exit
--startup-delay
--help
```

实测：

```text
rstudio.exe --version
2026.05.0+218
```

```json
{
  "electron": "41.5.0",
  "chrome": "146.0.7680.216",
  "node": "24.15.0",
  "rstudio": "2026.05.0+218"
}
```

判断：

- 有 CLI，但不是产品级自动化 CLI。
- 适合做版本检测、健康检查、日志采集、诊断报告。
- 不适合直接当“控制 IDE 所有功能”的入口。

### 3.2 `rpostback.exe`

本机 `rpostback.exe --help` 输出：

```text
--command arg
--argument arg
--help
--test-config
--config-file arg
```

判断：

- 这是 RStudio 内部通信/回调工具，不建议作为稳定产品 API。

### 3.3 `diagnostics.exe` 与 `--run-diagnostics`

`diagnostics.exe --help` 实际输出会读取这些路径：

- `C:\Users\Administrator\AppData\Local\RStudio\log\rdesktop.log`
- `C:\Users\Administrator\AppData\Local\RStudio\log\rsession-Administrator.log`
- `C:\Users\Administrator\AppData\Local\RStudio\log\positai.log`
- `C:\Users\Administrator\AppData\Roaming\RStudio\rstudio-prefs.json`
- `C:\ProgramData\RStudio\rstudio-prefs.json`
- `C:\Users\Administrator\AppData\Local\RStudio\rstudio-desktop.json`

`rstudio.exe --run-diagnostics` 可以启动 R session 并输出 R 启动过程、R_HOME、PATH、连接端口等信息。

判断：

- 很适合做“RStudio 环境体检器”。
- 可以包装成一个新手友好的诊断产品：检查 R、R 包、Rtools、Quarto、Python、Jupyter、Git、PATH、日志。

### 3.4 `quarto.exe`

RStudio 内置 Quarto：

```text
quarto.exe --version
1.9.37
```

`quarto.exe --help` 支持：

- `render`
- `preview`
- `serve`
- `create`
- `use`
- `add`
- `update`
- `remove`
- `convert`
- `pandoc`
- `typst`
- `run`
- `list`
- `install`
- `uninstall`
- `tools`
- `publish`
- `check`
- `call`
- `help`

实测 `quarto.exe check`：

- Quarto OK
- Pandoc `3.8.3` OK
- Deno `2.4.5` OK
- Typst `0.14.2` OK
- Chrome found
- R `4.6.0` OK
- 但 R 包 `knitr` / `rmarkdown` 未安装
- Jupyter 未安装
- TinyTeX 未安装

注意：

- `quarto.cmd` 在 `C:\Program Files\...` 这种带空格路径下本机实测会找错路径。
- 后续中间件应直接调用 `quarto.exe`，不要调用 `quarto.cmd`。

## 4. RStudio 内部模块调查

`resources\app\R\modules` 下有 87 个模块，覆盖：

- Automation
- Assistant / Chat / Copilot
- Breakpoints / Debugging
- Build
- CodeTools / Completion / Diagnostics
- Connections / DataImport / DataViewer
- Environment / ObjectExplorer
- Files / Help / Packages
- Jobs
- Plumber / Shiny
- Python / Reticulate
- Quarto / R Markdown / Notebook
- RSConnect
- RAddins
- Renv / Packrat
- Source / SQL / Stan
- Themes / Tutorial / UserCommands

通过简单扫描：

- `.rs.addFunction` 约 1048 个内部函数。
- `.rs.addJsonRpcHandler` 约 120 个内部 JSON-RPC handler。
- `.rs.addGlobalFunction` 4 个：`rstudioDiagnosticsReport`、`debugSource`、`registerShinyDebugHook`、`knit_with_parameters`。

判断：

- RStudio 内部功能非常丰富，但大多不是稳定外部 API。
- 可以作为研究产品机会的“能力地图”。
- 真正对外稳定的入口仍应优先走 `rstudioapi`、Addins、Project Templates、Connection Contract。

## 5. `rstudioapi`：最关键的二开 API

`rstudioapi` 是 RStudio 官方 R 包接口。它能让 R 代码与 RStudio IDE 交互。

官方参考：[rstudioapi Reference](https://rstudio.github.io/rstudioapi/reference/index.html)

主要能力：

- Terminal：创建、激活、发送命令、读取 buffer、杀掉 terminal。
- Documents：读取当前文档、插入文本、替换文本、设置光标、打开/关闭/保存文件。
- R Session：重启 session、发送代码到 Console。
- Dialogs：弹窗、选择文件/目录、询问密码/secret。
- Projects：打开项目、初始化项目、获取当前项目路径。
- Themes：添加、转换、应用、移除主题。
- Jobs：创建任务、更新进度、写输出、运行脚本为后台任务。
- Launcher：Workbench 相关远程任务能力。
- Helper：读写偏好、Viewer、保存图、source markers、Project Template、执行命令、命令回调。

特别重要的 API：

- `executeCommand(commandId)`：执行 RStudio 内部命令。
- `registerCommandCallback(commandId, callback)`：监听某个命令。
- `registerCommandStreamCallback(callback)`：监听所有命令流。
- `getActiveDocumentContext()`：读取当前打开文档。
- `insertText()` / `modifyRange()` / `setDocumentContents()`：修改当前文档。
- `terminalCreate()` / `terminalSend()` / `terminalExecute()`：控制 RStudio Terminal。
- `jobAdd()` / `jobRunScript()` / `jobSetProgress()`：控制 Jobs pane。

官方说明：`executeCommand()` 可以调用大多数菜单命令和许多按钮命令，但异步执行，不返回完成状态。

参考：[executeCommand](https://rstudio.github.io/rstudioapi/reference/executeCommand.html)

## 6. IDE Command IDs：命令面板/菜单动作清单

官方有 RStudio IDE Commands 表，命令 ID 可以被 `rstudioapi::executeCommand()` 使用。

参考：[RStudio IDE Commands](https://docs.posit.co/ide/server-pro/rstudio_ide_commands/rstudio_ide_commands.html)

典型命令：

- 面板切换：`activateConsole`、`activateFiles`、`activatePackages`、`activatePlots`、`activateConnections`、`activateBackgroundJobs`
- 构建包：`buildFull`、`buildSourcePackage`、`buildBinaryPackage`、`checkPackage`、`roxygenizePackage`
- 数据导入：`importDatasetFromCsvUsingReadr`、`importDatasetFromXLS`、`importDatasetFromSAV`、`importDatasetFromStata`
- 文档：`knitDocument`、`knitWithParameters`、`insertChunkR`、`insertChunkPython`、`insertChunkSQL`、`insertSection`
- Shiny/Plumber：`shinyRunInPane`、`shinyRunInBrowser`、`plumberRunInPane`、`plumberRunInBrowser`
- Terminal：`openNewTerminalAtEditorLocation`、`sendToTerminal`、`interruptTerminal`
- 发布：`rsconnectDeploy`、`rsconnectManageAccounts`
- Quarto：`serveQuartoSite`、`touchQuartoDoc`
- UI：`openDeveloperConsole`、`paneLayout`、`restoreDefaultPaneAndTabLayout`

产品机会：

- 做一个“RStudio 自动化插件”：用户点按钮，插件内部调用 command IDs。
- 做“工作流录制器”：用 `registerCommandStreamCallback()` 记录用户点过哪些命令，再生成脚本/教程/自动化模板。
- 做“新手任务面板”：把 RStudio 的复杂菜单压缩成几个中文按钮。

## 7. Addins：RStudio 官方插件机制

官方定义：

RStudio Addins 是让 R 函数可以在 RStudio 内交互执行的机制，可通过快捷键、Command Palette 或 Addins 菜单运行。

参考：[RStudio Addins](https://docs.posit.co/ide/user/ide/guide/productivity/add-ins.html)

Addin 分两类：

1. 文本宏：快速插入/转换文本。
2. Shiny Gadgets：用 Shiny 做交互 UI，再修改文档、项目、数据或运行工作流。

注册方式：

RStudio Addins 通过 R 包分发。包内创建：

```text
inst/rstudio/addins.dcf
```

字段：

```text
Name: 插件名称
Description: 插件说明
Binding: R 函数名
Interactive: true/false
```

官方建议依赖：

```text
rstudioapi
shiny
miniUI
```

本机现状：

这些包目前还没装：`rstudioapi`、`shiny`、`miniUI`、`devtools`、`usethis`、`roxygen2`、`rmarkdown`、`knitr`、`renv`、`plumber`、`rsconnect`、`reticulate`。

判断：

- 这是我们后续最应该优先走的二开路线。
- 不需要改 RStudio 本体，分发也更轻。
- 能做 UI、能读写编辑器、能调 R、能调系统命令，足够做很多产品。

## 8. Project Templates：项目脚手架入口

RStudio 支持自定义项目模板，用于 New Project wizard。

参考：[Project Templates](https://docs.posit.co/ide/user/ide/guide/productivity/project-templates.html)

分发方式：

- 通过 R 包分发。
- 在包里提供模板函数和 DCF 元数据。

路径示例：

```text
inst/rstudio/templates/project/hello_world.dcf
```

核心字段：

- `Binding`：创建项目时调用的 R 函数。
- `Title`：在 New Project 界面显示的标题。
- `Subtitle` / `Caption` / `Icon`：展示信息。
- `OpenFiles`：项目创建后自动打开的文件。

支持输入控件：

- `CheckboxInput`
- `SelectInput`
- `TextInput`
- `FileInput`

产品机会：

- 一键创建“数据分析项目模板”。
- 一键创建“科研论文 Quarto 项目模板”。
- 一键创建“Shiny Dashboard 模板”。
- 一键创建“Plumber API 服务模板”。
- 一键创建“教学/实验报告模板”。

这个入口非常适合新手产品，因为用户不用懂文件结构。

## 9. Connections：数据源中间件入口

RStudio 的 Connections 有两种扩展方法：

1. Connection Snippets：提供连接代码模板。
2. Connections Contract：让 R 包把数据源结构暴露给 RStudio Connections Pane。

参考：

- [Connection Snippets](https://docs.posit.co/ide/user/ide/guide/data/connection-snippets.html)
- [Connections Contract](https://docs.posit.co/ide/user/ide/guide/data/connection-contracts.html)
- [Connections Pane](https://docs.posit.co/ide/user/ide/guide/data/data-connections.html)

Connection Snippets：

- Desktop 版通过 R 包分发。
- 包内路径：

```text
inst/rstudio/connections.dcf
inst/rstudio/connections/
```

Connections Contract：

R 包通过 `getOption("connectionObserver")` 通知 RStudio：

- `connectionOpened()`
- `connectionUpdated()`
- `connectionClosed()`

可以提供：

- 连接类型、显示名、host、图标
- 重新连接代码
- 断开函数
- 对象类型层级
- 对象列表
- 字段列表
- 预览数据
- 自定义 actions

产品机会：

- 给国产数据库、Excel 文件夹、CSV 数据湖、本地 SQLite、DuckDB、API 数据源做 RStudio Connections 插件。
- 做“知识库/实验数据源浏览器”：让 RStudio 像数据库浏览器一样看本地数据资产。
- 做“公司内部数据源连接包”：安装一个 R 包后，RStudio 的 Connections Pane 自动出现可连接数据源。

## 10. Data Viewer 与数据导入

Data Viewer 能查看 data frame 和矩形数据结构，也支持 list/JSON 对象。

能力：

- `View(x)` 打开。
- 排序。
- 过滤。
- 搜索。
- 自动刷新。
- 显示列标签。
- 对大行数使用虚拟滚动。
- 对嵌套 list/JSON 展示结构，并能生成提取元素的 R 代码。

参考：[Data Viewer](https://docs.posit.co/ide/user/ide/guide/data/data-viewer.html)

本地数据导入支持：

- Text / CSV
- Excel
- SPSS / SAS / Stata

参考：[Local Data](https://docs.posit.co/ide/user/ide/guide/data/data-local.html)

产品机会：

- 做“导入向导增强”：自动识别编码、列类型、中文字段、日期格式。
- 做“数据清洗 Addin”：从 Data Viewer 选字段后生成 `dplyr` 代码。
- 做“JSON/嵌套对象浏览器增强”：把 RStudio 当前能看但不够产品化的能力做成更强 UI。

## 11. Jobs：后台任务入口

RStudio 支持把长时间 R 脚本跑到独立 R session。

参考：[RStudio Jobs](https://docs.posit.co/ide/user/ide/guide/tools/jobs.html)

能力：

- 从 UI 启动 Background Job。
- `.R` 文件里 Source as Background Job。
- clean session 运行。
- 可复制全局环境给 job。
- 可把 job 结果复制回主 session。
- Jobs pane 显示输出和进度。
- `rstudioapi::jobRunScript()` 可脚本化创建 job。
- `jobAdd()` 等 API 可把任何长任务接入 Jobs pane。

产品机会：

- 做“任务队列 Addin”：批量跑脚本、参数网格、模型训练、批量渲染 Quarto。
- 做“本地工作流中间件”：用 RStudio Jobs pane 显示进度，后台由 R/Python/CLI 跑。
- 做“科研实验运行器”：参数、日志、结果文件、RStudio UI 状态统一管理。

## 12. Terminal：内置终端入口

RStudio Terminal 是 IDE 内的系统 shell。

参考：[Terminal](https://docs.posit.co/ide/user/ide/guide/tools/terminal.html)

能力：

- 多 terminal。
- 命名 terminal。
- 从编辑器发送选中代码/当前行到 terminal。
- 可运行 Python REPL、shell 脚本、Git、系统工具。
- `rstudioapi` 可以创建 terminal、发送命令、读取 buffer、杀掉 terminal。

产品机会：

- 做“命令按钮化”：把复杂命令封装成 RStudio Addin 按钮，执行时发到 Terminal。
- 做“项目启动器”：一键打开多个命名终端，比如 API、前端、数据任务。
- 做“教学辅助”：每一步命令自动发送并解释输出。

## 13. Quarto / R Markdown / Visual Editor

RStudio 对 Quarto 支持很强。

参考：

- [Quarto Integration](https://docs.posit.co/ide/user/ide/guide/documents/quarto-project.html)
- [Visual Editor](https://docs.posit.co/ide/user/ide/guide/documents/visual-editor.html)

能力：

- 新建 Quarto 文档/项目。
- Render / Preview。
- Render on Save。
- Viewer pane 预览。
- Quarto render 作为 Background Job 运行。
- 支持 HTML、PDF、Word、网站、书、演示等。
- Visual Editor 支持 Pandoc Markdown、表格、引用、交叉引用、脚注、div/span、公式、代码单元内联输出。

本机状态：

- 内置 Quarto `1.9.37` 可用。
- R 包 `knitr`、`rmarkdown` 未安装。
- TinyTeX 未安装。
- Jupyter 未安装。

产品机会：

- 做“科研写作模板 Addin”。
- 做“报告生成器”：中文 UI 收集参数，生成 `.qmd`，调用 Quarto 渲染。
- 做“批量报告中间件”：读 Excel/CSV，多参数批量 render。
- 做“引用/Zotero 辅助”：围绕 Visual Editor、Zotero state、bibliography 生成工具。

## 14. Shiny / Plumber / 发布

RStudio 内置模板包括：

- `resources\templates\shiny\app.R`
- `resources\templates\shiny\ui.R`
- `resources\templates\shiny\server.R`
- `resources\templates\plumber\plumber.R`

相关命令：

- `shinyRunInPane`
- `shinyRunInBrowser`
- `plumberRunInPane`
- `plumberRunInBrowser`

发布能力：

- RStudio 有 Push-button deployment。
- 支持 Posit Connect、shinyapps.io、RPubs。
- `rsconnect` 包可程序化发布。

参考：

- [Publishing](https://docs.posit.co/ide/user/ide/guide/publish/publishing.html)
- [Connecting](https://docs.posit.co/ide/user/ide/guide/publish/connecting.html)

产品机会：

- 做“Shiny 应用脚手架 + 一键运行/发布”。
- 做“Plumber API 脚手架 + 本地调试面板”。
- 做“发布前检查器”：包依赖、文件依赖、密钥、路径、数据文件。

## 15. Python / reticulate

RStudio 通过 `reticulate` 集成 Python。

参考：[Python in RStudio](https://docs.posit.co/ide/user/ide/guide/environments/py/python.html)

能力：

- 打开 `.py` 文件并像 R 脚本一样交互执行。
- RStudio 使用 reticulate Python REPL。
- R/Python 对象可互相访问。
- Environment pane 可显示 Python 对象。
- 可以设置默认 Python。
- 可发现 PATH、virtualenv、conda、pyenv、`/opt/python` 中的 Python。
- `RETICULATE_PYTHON` 可控制默认 Python。

本机状态：

- Python 3.11.9 可用。
- R 包 `reticulate` 未安装。
- Jupyter 未安装。

产品机会：

- 做 R + Python 混合项目模板。
- 做 Python 环境诊断器。
- 做“RStudio 里的 Python 项目启动器”。
- 做本地 `.venv` 与 reticulate 的自动绑定工具。

## 16. 包开发

RStudio 包开发能力：

- Build pane。
- Clean and Install。
- `R CMD check`。
- Build source/binary package。
- roxygen 文档辅助。
- devtools/usethis/testthat 集成。
- Rcpp/C++ 高亮和错误导航。

参考：[Writing Packages](https://docs.posit.co/ide/user/ide/guide/pkg-devel/writing-packages.html)

本机状态：

- Rtools 未安装。
- `devtools`、`usethis`、`roxygen2`、`testthat`、`knitr` 均未安装。

产品机会：

- 做“R 包开发新手助手”：自动检查 Rtools、DESCRIPTION、NAMESPACE、roxygen、tests。
- 做“Addin 生成器”：一键生成 RStudio Addin 包骨架。
- 做“项目模板生成器”：一键生成 Project Template 包。

## 17. 偏好设置与配置文件

本地配置位置：

- 用户状态：`C:\Users\Administrator\AppData\Local\RStudio\rstudio-desktop.json`
- 用户偏好：`C:\Users\Administrator\AppData\Roaming\RStudio\rstudio-prefs.json`
- 系统偏好：`C:\ProgramData\RStudio\rstudio-prefs.json`
- 快捷键：`C:\Users\Administrator\AppData\Roaming\RStudio\keybindings\`

本机 `user-prefs-schema.json` 约 290 项，覆盖：

- R session 启动、workspace、history
- CRAN/Bioconductor mirror
- Terminal shell
- Pane layout
- Editor、补全、诊断、缩进、保存
- R Markdown / Quarto / Visual mode
- Shiny / Plumber viewer type
- Publishing
- Jobs
- Git/SVN
- Package build
- Data viewer
- Accessibility
- Python
- Assistant / Copilot
- Formatter / Air formatter

环境变量可控制部分行为：

- `RS_NO_SPLASH`
- `RSTUDIO_DISABLE_CHECK_FOR_UPDATES`
- `RSTUDIO_DISABLE_EXTERNAL_PUBLISH`
- `RSTUDIO_DISABLE_PACKAGES`
- `RSTUDIO_DISABLE_PACKAGE_INSTALL_PROMPT`
- `RSTUDIO_DISABLE_POSIT_ASSISTANT`
- `RSTUDIO_DISABLE_PUBLISH`
- `RSTUDIO_DISABLE_WHATS_NEW`

参考：[Environment variables](https://docs.posit.co/ide/user/ide/reference/environment-variables.html)

产品机会：

- 做“RStudio 设置同步器”。
- 做“新手推荐配置一键应用”。
- 做“项目级配置生成器”：例如自动设置 CRAN 镜像、Terminal、Python、render 选项。

## 18. 内部 Automation 入口

本地源码里存在 `--run-automation`、`--automation-agent`、`--automation-report-file` 等参数，也有 `SessionAutomation*.R` 模块。

观察到：

- 它会使用 WebSocket / Chromium DevTools Protocol。
- 它安装或依赖 `testthat`、`websocket`、`processx` 等 R 包。
- 输出 JUnit-style report。
- 明显偏 RStudio 自己的自动化测试框架。

判断：

- 这是很有研究价值的内部入口。
- 不建议作为第一版产品依赖的稳定 API。
- 可用于我们自己做 UI 自动化探索、测试和逆向理解。

## 19. 当前机器还缺的 RStudio 开发生态包

本机 R 目前只有基础包，缺少开发 RStudio 插件常用包：

```text
rstudioapi: FALSE
shiny: FALSE
miniUI: FALSE
devtools: FALSE
usethis: FALSE
roxygen2: FALSE
rmarkdown: FALSE
knitr: FALSE
quarto: FALSE
renv: FALSE
plumber: FALSE
rsconnect: FALSE
reticulate: FALSE
```

后续如果要真正开始开发，建议分批安装：

第一批，Addin 最小集：

```r
install.packages(c("rstudioapi", "shiny", "miniUI"))
```

第二批，R 包开发：

```r
install.packages(c("devtools", "usethis", "roxygen2", "testthat"))
```

第三批，文档/发布/项目：

```r
install.packages(c("knitr", "rmarkdown", "renv", "plumber", "rsconnect", "reticulate"))
```

是否安装 Rtools 要看是否需要编译包；先不急。

## 20. 最值得做产品的方向排序

### A. RStudio Addin 插件包

优势：

- 官方支持。
- 入口清晰。
- 分发简单。
- 不改 RStudio 本体。
- 可操作当前文档、Console、Terminal、Jobs、Viewer。

适合产品：

- 中文新手面板。
- 数据清洗代码生成器。
- Quarto 报告生成器。
- Addin/Package 项目脚手架。
- R + Python 环境诊断器。

### B. RStudio 工作流录制器

基于：

- `registerCommandStreamCallback()`
- `registerCommandCallback()`
- IDE Commands

适合产品：

- 记录用户操作。
- 生成教学教程。
- 生成自动化脚本。
- 分析用户在哪些 RStudio 功能卡住。

风险：

- 命令执行是异步的。
- 不一定知道命令是否完成。

### C. 数据源中间件

基于：

- Connection Snippets
- Connections Contract
- `connectionObserver`

适合产品：

- 企业数据库连接包。
- 本地数据目录/SQLite/DuckDB 浏览器。
- API 数据源转 RStudio Connections Pane。
- 统一数据资产入口。

### D. Project Template 产品

基于：

- `inst/rstudio/templates/project/*.dcf`
- 模板函数

适合产品：

- 科研项目模板。
- 教学项目模板。
- Shiny App 模板。
- Plumber API 模板。
- Quarto 网站/报告模板。

### E. 外部环境体检器

基于：

- `rstudio.exe --version-json`
- `rstudio.exe --run-diagnostics`
- `quarto.exe check`
- Rscript 检测包
- 日志路径

适合产品：

- 一键检测 RStudio 能不能用。
- 一键告诉用户缺什么包。
- 一键生成发给老师/开发者的诊断报告。

### F. Quarto 批量报告中间件

基于：

- `quarto.exe render`
- RStudio Project
- `.qmd` 模板
- Jobs pane 或外部进程

适合产品：

- 批量生成实验报告。
- 批量生成教学材料。
- 批量渲染数据报告。

## 21. 不建议优先做的方向

### 直接改 RStudio 本体

原因：

- AGPL 合规成本高。
- Electron + C++ + GWT + R session 复杂度高。
- 打包难，升级难。

适合以后深度定制时再考虑。

### 依赖内部 `.rs.*` 函数

原因：

- 很强，但非稳定公共 API。
- 升级版本可能变。

可以研究，不建议第一版产品依赖。

### 把 `rstudio.exe` 当完整 CLI

原因：

- 它目前只适合版本、日志、诊断、启动调试。
- IDE 动作更适合通过 `rstudioapi` 和 command IDs 调用。

## 22. 下一步建议

如果下一目标是“真正开始编程产品”，建议从最小闭环开始：

1. 安装 `rstudioapi`、`shiny`、`miniUI`。
2. 创建一个 R 包骨架。
3. 注册一个最小 RStudio Addin。
4. Addin 做三件事之一：
   - 读取当前文档并插入文本。
   - 打开一个 Shiny Gadget。
   - 在 Jobs pane 跑一个后台脚本。
5. 再决定产品方向：新手助手、报告生成器、数据源连接器、工作流录制器。

我的推荐第一试验项目：

```text
RStudio 新手工作台 Addin
```

第一版只做 5 个按钮：

- 检查环境
- 新建标准项目
- 安装常用包
- 生成 Quarto 报告模板
- 一键运行并导出诊断报告

这条路最符合 RStudio 现有能力，也最适合后续扩成产品。
