---
name: powershell
description: 在 Windows PowerShell 7 中写可靠的命令和 .ps1 脚本，避开从 bash/Linux 迁移过来的陷阱：引号与参数传递、编码与行尾、JSON 深度、原生命令退出码、路径与字面量、别名差异。当需要在 Windows 上执行 shell 命令、编写或调试 PowerShell 脚本、或 bash 命令在 PowerShell 中行为不符预期时使用。
---

# PowerShell 可靠执行

先假设“bash 的写法在这里不成立”，再按下面改。具体代码见 `references/recipes.md`。

## 核心规则

1. 一律 `pwsh -NoProfile -File <script>` 运行脚本；不要在 PowerShell 里嵌套 `powershell -Command`。
2. 原生命令的参数用数组或 `--%` 传递，不要让 PowerShell 重新解析引号。
3. 路径用反斜杠；含 `[` `]` 的路径一律加 `-LiteralPath`。
4. 判断存在用 `Test-Path -LiteralPath`，不要拼字符串后直接 `Get-Item`。
5. 输出非 ASCII 前先设 `[Console]::OutputEncoding = [Text.UTF8Encoding]::new()`。
6. 写文件显式指定编码：`-Encoding utf8`。PS 7 无 BOM，PS 5.1 会带 BOM。
7. `.ps1` 脚本保持纯 ASCII。无 BOM 的中文注释会让 PS 5.1 按 ANSI 解析并报语法错误。
8. `ConvertTo-Json` 默认深度只有 2，嵌套结构必须显式 `-Depth`。
9. 原生命令看 `$LASTEXITCODE`；cmdlet 要加 `-ErrorAction Stop` 才会被 `try/catch` 抓住。
10. 不要用 `curl` / `wget` 别名，写 `curl.exe`。
11. `&&` / `||` 只在 PS 7 可用；兼容 5.1 时用 `if ($LASTEXITCODE -eq 0)`。
12. 变量名大小写不敏感：参数 `$Name` 会和 `foreach ($name ...)` 冲突。
13. 没有 `chmod`；权限问题看执行策略（`Get-ExecutionPolicy`）和 ACL。
14. 命令输出是对象不是文本：先 `Select-Object` 取字段，再决定怎么展示。

## 验证习惯

- 写完 `.ps1` 先跑一次，不要只做语法检查。
- 涉及编码、路径、JSON 的改动，用一条真实数据验证输出，而不是看代码推断。
- 脚本要同时考虑 PS 7 和 PS 5.1：`pwsh` 与 `powershell` 各跑一次。

## 常见误区

| 写法 | 实际行为 |
| --- | --- |
| `curl https://...` | PS 5.1 是 `Invoke-WebRequest` 别名，不是 curl |
| `$x > out.txt` | PS 5.1 写 UTF-16LE；PS 7 写 UTF-8 |
| `Get-Content $p` | 返回行数组，不是整段文本；要整段用 `-Raw` |
| `$a | ConvertTo-Json` | 默认深度 2，深层字段会被截断 |
| `try { 外部命令 } catch` | 原生命令失败不抛异常，只看 `$LASTEXITCODE` |
| `ls` / `rm` / `cat` | 都是别名，参数语义与 bash 不同 |
