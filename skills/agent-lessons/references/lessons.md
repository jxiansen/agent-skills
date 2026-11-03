# 已蒸馏的经验

只放已经落地的条目；原始记录在 `$env:USERPROFILE\.agents\lessons-inbox.md`。

上次蒸馏：2026-11-03

| 日期 | 问题 | 根因 | 去向 |
| --- | --- | --- | --- |
| 2026-11-03 | `.ps1` 在 PS 5.1 下解析失败 | 无 BOM 的 UTF-8 被按 ANSI 读取，中文注释破坏语法 | `powershell` skill：脚本保持纯 ASCII |
| 2026-11-03 | `-Section services` 被当成过滤器 | `$Name` 参数与 `foreach ($name ...)` 同名，PowerShell 大小写不敏感 | `powershell` skill：参数与循环变量不要同名 |
| 2026-11-03 | 非 ASCII 输出乱码 | 控制台编码为 gb2312 | AGENTS.md「Shell 输出」：先设 UTF-8 |
| 2026-11-03 | WSL agent 未拿到新技能，但 `agents` 字段已记录 | 安装时 WSL 关机，写入被静默跳过 | 本文：安装后跑 `magpie library sync` 并核对 `applied` |

## 待观察

- 暂无。新的候选项先进 inbox，攒够再蒸馏。
