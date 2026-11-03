---
name: environment
description: 查询当前 Windows 工作站的运行环境，包括操作系统、PowerShell、硬件、磁盘空间、工具链版本和路径、WSL 状态、Windows 服务状态、代理设置及相关配置路径。当任务依赖精确的本地版本、已安装工具、资源状态或环境漂移时使用；也适用于“当前环境、工具版本、磁盘空间、WSL 状态、代理配置”等中文请求。不用于通用软件安装建议。
---

# 环境查询

当精确的本地环境事实会影响回答时使用本 skill。不要根据记忆或过期快照猜测易变信息。

## 使用流程

1. 需要背景信息时，读取 `$env:USERPROFILE\.agents\ENVIRONMENT.md`；文件不存在就跳过。
2. 查询当前值时，先定位本 skill 再运行，只查需要的部分：

   ```powershell
   $skill = @(
       "$env:USERPROFILE\.config\magpie\library\skills",
       "$env:USERPROFILE\.agents\skills"
   ) | ForEach-Object { Get-ChildItem $_ -Directory -Filter 'environment*' -ErrorAction SilentlyContinue } |
       Where-Object { Test-Path (Join-Path $_.FullName 'scripts\env-info.ps1') } |
       Select-Object -First 1
   if (-not $skill) { throw 'scripts/env-info.ps1 not found under any skills folder' }
   & (Join-Path $skill.FullName 'scripts\env-info.ps1') -Section toolchain
   ```

   技能可能被改名、链接或复制到 agent 自己的 skills 目录，不要写死某一条路径。
3. 可用部分：`os`、`hardware`、`shell`、`toolchain`、`disk`、`wsl`、`network`、`config`、`services`。
   多个用逗号分隔，例如 `-Section os,disk`。
4. 查具体服务用 `-Section services -Name <名称片段>`；不带 `-Name` 时返回总数、运行数和“自动启动却没在跑”的服务。
5. 脚本结果与快照不一致时，以实时结果为准，并说明哪些是实时值、哪些来自历史快照。
6. 不要为了回答环境问题而安装、升级或重新配置工具。
7. 控制输出范围，优先 `-Section`，不要总是查 `all`（约 3 秒、4 KB）。

脚本默认返回 JSON；只有需要给人阅读时才用 `-Format Text`。

回报时用表格或短列表，只列被问到的项，不要原样粘贴整段 JSON。
