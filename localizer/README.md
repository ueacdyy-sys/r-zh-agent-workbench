# RStudio 中文化补丁器

这是一个版本限定的本地补丁器，用来把已经安装在本机的 RStudio Desktop 做中文 overlay。

当前实测版本：

```text
RStudio 2026.05.0+218
```

## 为什么不用旧脚本

早期实验脚本对 GWT cache 做大量字符串替换，虽然能覆盖更多区域，但风险更高，曾出现界面交互异常。因此开源仓库里默认提供更保守的运行时 overlay：

- 只改 `rstudio.nocache.js`，并插入带 marker 的独立脚本块。
- 安装前备份，移除时只删除 marker 区块。
- 默认检查 RStudio 版本。
- 词表来自 TSV，避免把改后的 RStudio 资源直接提交到仓库。

## 检查

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Inspect
```

## 安装

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Install
```

安装后重启 RStudio。

## 移除

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Remove
```

## 恢复备份

安装和移除都会在 `%LOCALAPPDATA%\RStudioZhLocalizer\backups` 创建备份。如果需要完全恢复某个备份：

```powershell
powershell -ExecutionPolicy Bypass -File .\localizer\tools\Invoke-RStudioZhLocalization.ps1 -Mode Restore -BackupFile "C:\path\to\rstudio.nocache.js.20260530164500.bak"
```

## 文件说明

- `dictionary/rstudio-2026.05.0-zh-CN.tsv`: 当前中文词表。
- `evidence/patch-records`: 本地汉化过程的补丁记录，仅用于追溯。
- `tools/Invoke-RStudioZhLocalization.ps1`: 开源版安全补丁器。

## 风险提示

这是实验工具，不是官方语言包。RStudio 更新后文件结构和前端加载逻辑可能变化，必须先 `Inspect` 再安装。
