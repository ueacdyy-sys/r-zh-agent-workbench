# 发布流程

本文档说明公开发布前应执行的通用流程，不记录本机调试过程或临时验证日志。

## 发布前检查

1. 确认仓库不包含 RStudio 安装目录、修改后的 RStudio 资源文件、Posit Assistant 文件、用户状态、密钥或本机缓存。
2. 运行本地发布前检查：

```powershell
.\scripts\Test-ReleaseReadiness.ps1
```

3. 如果只需要在登录 GitHub 前检查本地内容，可以使用：

```powershell
.\scripts\Test-ReleaseReadiness.ps1 -SkipGitHubAuth
```

4. 确认 `README.md`、`LICENSE`、`NOTICE`、`SECURITY.md` 和 `CONTRIBUTING.md` 均已更新。
5. 确认 release notes 只描述公开版本包含的能力、限制和许可边界。

## 发布到 GitHub

登录 GitHub CLI 后，可使用发布脚本创建远端仓库、推送分支和推送标签：

```powershell
.\scripts\Publish-To-GitHub.ps1 -RepoName r-zh-agent-workbench -Visibility public
```

需要同时创建 GitHub Release 时：

```powershell
.\scripts\Publish-To-GitHub.ps1 -RepoName r-zh-agent-workbench -Visibility public -CreateRelease
```

## 发布边界

- 本项目不是 Posit 或 RStudio 官方项目。
- 本项目不分发 RStudio 二进制、修改后的 RStudio 资源文件或 Posit Assistant 组件。
- `localizer` 是面向本地已安装 RStudio 的实验性工具，使用前应先运行 inspect。
- `packages/rstudiozhai` 是主产品线，适合持续迭代、开源和商业化扩展。
