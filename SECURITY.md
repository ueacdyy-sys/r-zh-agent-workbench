# Security Policy

## Scope

请报告以下问题：

- 汉化补丁脚本可能破坏 RStudio 安装、误删文件或无法恢复。
- AI provider、CLI、MCP、审计日志泄露密钥或敏感数据。
- RStudio 项目扫描读取了超出声明范围的源码、依赖缓存或用户目录。
- 数据库连接片段把密码写入项目文件或日志。

## Default Principles

- 默认不读取文件正文，除非用户显式开启。
- 默认不写入用户配置，除非用户显式执行安装命令。
- 默认不回显 API key、OAuth token、连接密码。
- 本地补丁必须有版本检查、备份、移除或恢复路径。

## Reporting

如果公开 issue 会暴露密钥或客户数据，请先移除敏感信息后再提交最小复现。
