# 架构设计

## 技术栈选择

第一阶段选择：

- 交付形态：R package。
- RStudio 插件入口：RStudio Addin。
- IDE 交互：`rstudioapi`。
- UI：Shiny Gadget + miniUI。
- 后台任务：RStudio Jobs。
- 报告生成：Quarto CLI。
- AI 接入：Provider adapter，不绑定单一厂商；默认本地中文规则型 provider。
- 测试：base R 核心逻辑测试 + `testthat` 契约测试。

暂不选择：

- RStudio 本体 fork。
- Electron 插件注入。
- 独立 Node/TypeScript 服务端。
- 直接依赖内部 `.rs.*` 函数。

## 分层

```text
RStudio Addin / Shiny UI / Terminal / Jobs
              |
          Interface Adapters
              |
           Use Cases
              |
          Domain Contracts
              |
         Provider Interfaces
              |
AI APIs / Quarto / RStudio / Filesystem / R Packages
```

## 模块边界

### Domain

放纯规则和数据契约：

- AI task request。
- Environment report。
- Action suggestions。
- Knowledge base records。

不得依赖：

- Shiny。
- rstudioapi。
- HTTP 客户端。
- RStudio 内部函数。

### Use Cases

编排用户任务：

- `collect_environment_report()`
- `build_ai_task_request()`
- `invoke_ai_provider()`
- `format_environment_report()`
- `lookup_rstudio_term()`
- `search_rstudio_commands()`
- `explain_r_error()`
- `openai_responses_provider()`

### Adapters

连接外部世界：

- RStudio adapter。
- Quarto adapter。
- Jobs adapter。
- Project template adapter。
- AI provider adapter。
- OpenAI Responses adapter。
- File/project adapter。
- Knowledge table reader。
- Connections snippet adapter。
- Code snippet installer。

### Delivery

用户入口：

- RStudio Addin function。
- Shiny Gadget UI。
- RStudio Project Template binding。
- CLI/test runner。

## 兼容性策略

1. 优先使用公开 API。
2. 每个外部工具都先做可用性检测。
3. 依赖缺失时降级提示，不直接失败。
4. RStudio 版本差异通过 adapter 隔离。

## 性能策略

1. 环境检查只做轻量命令。
2. AI 请求上下文先裁剪。
3. 本地规则型 provider 作为无网络、低延迟兜底。
4. 长任务进入 Jobs 或 Terminal。
5. Quarto 渲染通过外部进程运行。

## 架构评分

按桌面 SKILL库 `clean-architecture` 标准，当前目标架构评分：8.8/10。

扣分原因：

- 还没有真实 AI provider adapter。
- 还没有 RStudio 内实机 Addin 点击验证。
- 长任务队列还只是架构预留。

提升到 10/10 的动作：

- 增加真实 provider contract tests。
- 增加 Jobs 集成测试。
- 增加 RStudio 内手工验收清单和截图。
