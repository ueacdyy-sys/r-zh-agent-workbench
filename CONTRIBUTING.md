# Contributing

欢迎贡献，但请先守住边界：这个仓库做兼容 RStudio 工作流的中文工具，不做官方冒名发行版。

## 可接受贡献

- R 包 Addin 功能、测试、文档。
- 汉化词表补充和版本验证记录。
- 更安全的本地补丁、备份、恢复、检查脚本。
- 中文 RStudio 使用教程、错误解释、Quarto 报告模板。
- AI provider 适配器、模型探测、脱敏和审计能力。

## 不接受贡献

- RStudio 安装包、改版二进制、改后的 `.cache.js` 或用户安装目录文件。
- Posit Assistant 二进制、反编译产物、绕过授权或复制官方服务的代码。
- 真实 API key、OAuth token、账号、客户数据或本机私密日志。
- 使用 `RStudio 中文官方版`、`Posit 官方` 等会造成混淆的命名。

## 本地检查

R 包检查：

```powershell
cd packages\rstudiozhai
& "C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe" tests\base\run-tests.R
```

密钥扫描：

```powershell
rg -n --hidden "api[_-]?key|secret|token|password|Authorization|Bearer|oauth|access_token" .
```
