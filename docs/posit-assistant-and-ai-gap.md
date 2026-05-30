# Posit Assistant 与本项目 AI 空缺

## 结论

Posit Assistant 已经是 RStudio 新版本里的官方 AI 能力入口。本项目不应该复制它、打包它或绕过它的许可，而应该围绕它没有覆盖好的区域做独立产品。

## 已确认边界

- Posit Assistant 是 Posit 提供的 AI 功能和服务，不是本仓库可分发的开源组件。
- 本机安装的 Posit Assistant 包含独立 EULA，不能把它当作 MIT/AGPL 资源复制进仓库。
- RStudio 的 Assistant 入口和协议可以作为兼容目标研究，但不要把私有 helper 当公开 SDK 承诺。
- 本仓库只发布自己写的 provider、R 包、CLI/MCP 原型、词表和补丁工具。

## 第一性原理判断

官方 Assistant 的目标是让 RStudio 用户获得通用 AI 代码助手。中文商业机会不在“再做一个低配聊天框”，而在以下链路：

```text
中文用户痛点 -> RStudio 上下文 -> 企业/本地模型 -> 可审计操作 -> 可交付报告
```

## 本项目应该抢的空位

1. 中文项目医生
   - R/RStudio/Quarto/包/Git/Python/LaTeX 诊断。
   - 中文原因、修复命令、复现报告。

2. BYOK 与企业模型网关
   - OpenAI-compatible、本地 Ollama/vLLM/LiteLLM、国产云、企业代理。
   - 密钥脱敏、模型探测、失败建议。

3. 数据连接助手
   - DBI/ODBC 连接模板、字段解释、SQL/dbplyr 代码生成。
   - 不把密码写入项目文件。

4. Quarto 中文报告工厂
   - 面向中文交付物，而不是只回答代码问题。
   - 覆盖渲染失败、缺包、LaTeX、Jupyter 等常见断点。

5. 审计与治理
   - 命令、provider、模型、成功/失败状态可追踪。
   - 不记录 API key、token、password、长选区正文。

## 发布话术

推荐：

> 一个独立的 RStudio 工作流中文 AI 工作台，提供中文项目诊断、企业模型网关、Quarto 报告和实验性本地汉化工具。

避免：

> RStudio 官方中文 AI 版。

> Posit Assistant 替代版。

> 内置破解/改造 Posit Assistant。
