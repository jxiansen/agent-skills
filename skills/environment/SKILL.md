---
name: environment
description: 查询当前 Windows 工作站的运行环境，包括操作系统、PowerShell、硬件、磁盘空间、工具链版本和路径、WSL 状态、代理设置及相关配置路径。当任务依赖精确的本地版本、已安装工具、资源状态或环境漂移时使用；也适用于“当前环境、工具版本、磁盘空间、WSL 状态、代理配置”等中文请求。不用于通用软件安装建议。
---

# 环境查询

当精确的本地环境事实会影响回答时使用本 skill。不要根据记忆或过期快照猜测易变信息。

## 使用流程

1. 需要背景信息时，读取 `$env:USERPROFILE\.agents\ENVIRONMENT.md`。
2. 查询当前值时，只运行需要的部分：

   ```powershell
   pwsh -NoProfile -File "$env:USERPROFILE\.config\magpie\library\skills\environment\scripts\env-info.ps1" -Section toolchain
   ```

3. 可用部分：`os`、`hardware`、`shell`、`toolchain`、`disk`、`wsl`、`network`、`config` 和 `all`。
   多个部分可以用逗号分隔。
4. 脚本结果与快照不一致时，以实时脚本结果为准，并说明哪些是实时值、哪些来自历史快照。
5. 不要为了回答环境问题而安装、升级或重新配置工具。
6. 控制输出范围，优先使用 `-Section`，不要总是查询 `all`。

脚本默认返回 JSON。只有需要给人阅读时才使用 `-Format Text`。

Magpie 可能通过 `.codex\skills\environment` 或 `.config\opencode\skills\environment`
暴露本 skill；上面的 Magpie 库路径才是规范位置。
