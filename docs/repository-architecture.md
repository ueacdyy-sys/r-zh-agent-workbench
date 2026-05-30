# 仓库架构

## 目录职责

```text
r-zh-agent-workbench/
  packages/rstudiozhai/   RStudio Addin / R 包主产品
  localizer/              RStudio 本地中文 overlay 工具
  docs/analysis/          功能探索、产品机会和二开路线研究
  docs/assets/            文档截图和演示资产
  scripts/                发布和维护脚本
  .github/workflows/      GitHub Actions 验证
```

## 为什么是 monorepo

本项目目前还处在 alpha 阶段。R 包、汉化补丁器和分析文档强相关，如果过早拆成多个仓库，会让用户看不懂“哪个是主产品、哪个是实验工具”。当前采用单仓库，但边界写清楚：

- `packages/rstudiozhai` 是主线，可商用、可开源、可持续迭代。
- `localizer` 是实验性工具，只对本地已安装 RStudio 打补丁。
- `docs/analysis` 是研究资料，不等同于已完成能力。

## 发布资产原则

允许提交：

- 自写 R 源码、测试、文档。
- 自写 PowerShell 脚本。
- TSV 词表、补丁记录、截图、分析报告。

禁止提交：

- RStudio 安装包、改版二进制、改后 `.cache.js`。
- Posit Assistant 安装目录、二进制、反编译产物。
- 用户状态、OAuth、API key、客户数据。
- 本机备份目录和日志。

## 长期拆仓路径

当功能稳定后，可以拆成三个仓库：

1. `rstudiozhai`
   - R 包 Addin 主线。
2. `rstudio-zh-localizer`
   - 汉化补丁器和词表。
3. `r-agent-workbench-research`
   - 产品研究、教程、截图、路线图。

当前先不拆，是为了保留完整上下文，方便第一批使用者理解各模块之间的关系。
