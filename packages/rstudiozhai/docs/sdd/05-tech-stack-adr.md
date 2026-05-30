# ADR-001 技术栈选择

## 状态

Accepted.

## 背景

目标是在 RStudio 的插件生态和二次开发生态空缺中开发产品。核心约束：

- 要兼容现有 RStudio Desktop。
- 要用官方稳定入口。
- 要支持中文 AI 能力。
- 要能渐进扩展到数据源、报告、模板和后台任务。

## 决策

第一阶段采用：

```text
R package + RStudio Addin + rstudioapi + Shiny/miniUI + provider adapters
```

## 理由

- RStudio Addin 是官方插件入口。
- `rstudioapi` 能读写当前文档、控制 Terminal、Jobs、Viewer、项目和命令。
- Shiny/miniUI 是 RStudio Addin 的常见交互 UI 方案。
- Provider adapter 可以兼容不同 AI 服务，避免厂商锁定。
- 不 fork RStudio 本体，升级风险低。

## 备选方案

### RStudio 本体 fork

拒绝，原因：

- AGPL 合规和分发成本高。
- RStudio 技术栈复杂，维护成本高。
- 第一阶段不需要这么深。

### 独立 Node/TypeScript 服务端

暂缓，原因：

- 会增加安装和进程管理复杂度。
- 当前核心能力用 R package 足够。
- 后续需要流式 AI、多用户队列、企业知识库时再引入。

### MCP Server

后续考虑，原因：

- 适合让 AI Agent 调用 RStudio 项目工具。
- 但第一阶段先把 RStudio 内用户体验做通。

## 性能决策

- 不在 UI 线程做长任务。
- Quarto 渲染和批处理进入 Jobs 或外部进程。
- AI 上下文需要裁剪。
- 环境体检保持轻量。

## 兼容性决策

- 所有外部依赖运行前检测。
- 依赖缺失给中文提示。
- 不使用 RStudio 内部非公开函数。
- 核心逻辑不依赖 RStudio 环境，可用 Rscript 测试。

