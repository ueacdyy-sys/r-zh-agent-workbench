# 开源与商业化边界

## 一句话结论

可以商业化，也可以开源，但必须区分三种东西：

| 层级 | 我们发布什么 | 许可证/边界 | 商业化方式 |
| --- | --- | --- | --- |
| R 包 Addin | 自己写的 R 包、Addin、provider、CLI/MCP 原型 | MIT | 可做开源版、企业版、部署服务、模板服务 |
| 汉化补丁器 | 词表、补丁脚本、备份/恢复工具、验证记录 | MIT，且不分发 RStudio 二进制 | 可做安装服务、版本适配、企业内部分发工具 |
| RStudio 本体二开 | 如果 fork RStudio 源码并发布修改版 | RStudio 本体 AGPLv3 或 Posit 商业授权；另有商标限制 | 可收费，但修改版分发/网络使用要遵守 AGPL 源码义务 |

## 不应做的事

- 不发布改过的 RStudio 安装包。
- 不上传本机 `C:\Program Files\RStudio` 下的改后资源。
- 不把 Posit Assistant 当成可复制开源组件。
- 不使用会造成官方混淆的产品名。

## 可以做的事

- 发布 R 包 Addin，让用户通过 `remotes::install_github()` 安装。
- 发布本地补丁器，让用户在自己电脑上对已安装 RStudio 应用汉化。
- 发布 AI provider 网关，让用户接本地模型、企业代理或自带 key。
- 发布教程、词表、验证截图和分析文档。

## Posit Assistant 的位置

Posit Assistant 是 RStudio 新版本里的官方 AI 能力入口，但本地安装包带有 Posit EULA。它可以作为竞品/兼容目标研究，不能作为本仓库的可复制源码资产。

本仓库的 AI 方向应该避开“复制官方 Assistant”，转向：

- 中文错误解释和环境诊断。
- BYOK、本地模型和企业模型网关。
- 数据连接、字段解释、SQL/R 代码生成。
- Quarto 中文报告工厂。
- 审计、脱敏和企业治理。
