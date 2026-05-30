# GitHub 发布清单

## 发布前

- [ ] 根目录不包含 RStudio 安装目录、改后缓存、备份缓存或用户状态。
- [ ] `localizer` 只包含词表、脚本、验证记录，不包含改过的 RStudio 文件。
- [ ] `packages/rstudiozhai` 不包含 `.Rcheck`、`.tar.gz`、日志、临时验证目录。
- [ ] 所有 README 都声明非 Posit/RStudio 官方项目。
- [ ] 运行 R 包测试。
- [ ] 运行密钥扫描。
- [ ] 确认 GitHub CLI 已登录：`gh auth status`。

可重复执行的发布前检查：

```powershell
.\scripts\Test-ReleaseReadiness.ps1
```

如果只是想在 GitHub 登录前检查本地代码：

```powershell
.\scripts\Test-ReleaseReadiness.ps1 -SkipRCheck -SkipLocalizerInspect -SkipGitHubAuth
```

## 创建公开仓库

```powershell
cd C:\Users\Administrator\Desktop\rstudio开发\github\r-zh-agent-workbench
gh auth login
gh repo create r-zh-agent-workbench --public --source . --remote origin --push
```

## 首个 Release 建议

- Tag: `v0.1.0-alpha`
- 标题：`R Zh Agent Workbench v0.1.0-alpha`
- 说明：
  - RStudio Addin 工作台原型。
  - RStudio 2026.05.0+218 中文 overlay 词表和补丁器。
  - 第一性原理产品分析和商业化边界文档。
  - 明确声明不是官方发行版，不包含 RStudio 二进制。
