# R Zh Agent Workbench

面向 RStudio 工作流的中文 AI 数据分析工作台、汉化补丁器和产品研究资料。

本仓库不是 Posit 或 RStudio 官方项目，也不分发 RStudio 二进制文件、修改后的 RStudio 资源文件或 Posit Assistant 组件。它只开源我们自己写的 R 包、PowerShell 工具、中文词表、验证记录和分析文档。

## 第一性原理

RStudio 用户真正买单的不是“一个按钮”或“一个翻译词表”，而是这条链路变短：

```text
数据接入 -> 环境可用 -> 写代码 -> 运行调试 -> 解释结果 -> 生成报告 -> 团队复用
```

所以本仓库按三层拆分：

- `packages/rstudiozhai`: RStudio Addin / R 包，提供中文项目医生、AI provider 适配、Quarto 报告、Connections、Snippets、CLI/MCP 原型。
- `localizer`: 版本限定的 RStudio 中文化补丁器，默认用运行时 overlay，带版本检查、备份和移除，不发布改版 RStudio。
- `docs/analysis`: 真实反馈、功能空缺、AI Agent IDE 方向和商业化边界分析。

## 推荐使用顺序

1. 先安装并试用 `packages/rstudiozhai`，这是最安全、最适合公开发布的主产品线。
2. 再按需使用 `localizer`，它是实验性本地补丁，不保证跨 RStudio 版本稳定。
3. 用 `docs/analysis` 做产品路线、商业化和二次开发决策。

## 安装 R 包 Addin

开发态安装：

```r
install.packages("remotes")
remotes::install_local("packages/rstudiozhai")
```

在 RStudio 中重启后，通过 `Addins` 菜单打开中文 AI 工作台。

## 使用汉化补丁器

先只检查，不修改：

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Inspect
```

安装运行时中文 overlay：

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Install
```

移除 overlay：

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Remove
```

当前词表来自本地 RStudio `2026.05.0+218` 的实测汉化工作。其他版本请先 `Inspect`，不要跳过版本检查。

## 开源与商业化边界

- 本仓库代码采用 MIT License，可开源、可商用、可二次开发。
- RStudio 本体是 AGPLv3 或 Posit 商业授权；如果分发修改版 RStudio，需要遵守 AGPL 和商标要求。
- Posit Assistant 是 Posit 自有 AI 功能/服务，不是本仓库可复制分发的开源组件。
- 不要把本仓库包装为“RStudio 中文官方版”。

更多细节见 [docs/open-source-boundaries.md](docs/open-source-boundaries.md)。

## 仓库状态

这是从本地实验台整理出的首个开源仓库骨架。已清理内容包括：

- RStudio 备份缓存、改后缓存和安装目录资源。
- R 包构建产物、`.Rcheck` 目录和压缩包。
- 用户状态、OAuth、密钥和本机配置。

后续发布前应再做一次完整测试和 GitHub Actions 验证。
