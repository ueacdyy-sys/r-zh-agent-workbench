# GitHub 仓库设置建议

## Repository Name

```text
r-zh-agent-workbench
```

## Description

```text
Chinese AI workbench, localizer, and product research for RStudio-compatible R workflows.
```

## Topics

```text
r
rstudio
rstudio-addin
quarto
ai-agent
chinese
localization
data-analysis
openai-compatible
mcp
```

## About

Homepage 可以先留空。等后续有 GitHub Pages 或文档站再设置。

## Features

建议开启：

- Issues
- Pull Requests
- Discussions
- Wiki 可不开，文档优先放在仓库内。

## Branch Protection

alpha 阶段可以先不开强保护。等有协作者后再设置：

- Require pull request before merging
- Require status checks to pass
- Require conversation resolution

## GitHub Pages

后续可以把 `docs/analysis/*.html` 做成 Pages，但首发不建议直接开 Pages，因为这些 HTML 是研究材料，不是正式产品文档。更稳的顺序：

1. 先发布仓库。
2. 再整理 `docs/site`。
3. 最后开启 Pages。
