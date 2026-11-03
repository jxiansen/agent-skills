# agent-skills

个人 agent 技能集合，通过 [magpie](https://usemagpie.ai) 的 Library 分发：每个子目录是一个技能（含 `SKILL.md`），magpie 记录来源仓库和 commit，可以检查更新并一键拉取。

## 技能

| 技能 | 用途 |
| --- | --- |
| `environment` | 查询当前 Windows 工作站的运行环境：操作系统、PowerShell、硬件、磁盘、工具链、WSL、Windows 服务、代理和配置路径 |

## 结构

```
skills/
└─ environment/
   ├─ SKILL.md
   └─ scripts/
      └─ env-info.ps1
```

## 本地测试

脚本可以独立运行，不必先装进 magpie：

```powershell
pwsh -NoProfile -File .\skills\environment\scripts\env-info.ps1 -Section toolchain
pwsh -NoProfile -File .\skills\environment\scripts\env-info.ps1 -Section services
pwsh -NoProfile -File .\skills\environment\scripts\env-info.ps1 -Section services -Name spool
pwsh -NoProfile -File .\skills\environment\scripts\env-info.ps1 -Section all -Format Text
```

`-Section` 可取 `os`、`hardware`、`shell`、`toolchain`、`disk`、`wsl`、`network`、`config`、`services`、`all`，多个用逗号分隔。默认输出 JSON。

`-Name <片段>` 只用于 `services`：按服务名或显示名模糊匹配，最多返回 50 条。不带时返回服务总数、运行数和“自动启动却没在跑”的清单。

想验证“被 agent 调用”的形态，可以在 magpie 的 Library 页面从本地文件夹添加这个技能（链接安装，改文件即生效），微调完再移除。

## 输出要点

- `os`：`version` / `build` 是内核号，`display_version`（如 `26H2`）加 `ubr` 才是可用于判断补丁级别的组合。
- `wsl`：结构化返回 `default` 和 `distros[]`（`name` / `state` / `version` / `default`）；解析失败时退回 `raw` 原始行。
- `services`：默认给汇总和 `auto_not_running`；带 `-Name` 时返回匹配项。
- 其余 section 字段保持不变。

## 安装到 magpie

1. push 到 GitHub。
2. magpie → Library → Skills → 安装，粘贴：

   ```
   https://github.com/<owner>/<repo>/tree/main/skills/environment
   ```

3. 勾选要分发的 agent（如 `codex`、`opencode`、`fx`，WSL 里的 agent 会拿到副本）。

**安装前先移除同名的本地技能**，否则 magpie 会并排装成 `environment-<owner>`：

```powershell
magpie library skill rm environment
```

`SKILL.md` 里的命令按 `environment*` 前缀自动定位脚本，所以被改名也能跑；但保持 `environment` 最省事。

私有仓库：在 Settings → Network and sharing 填 GitHub token（fine-grained，只读 `Contents` 即可），或设 `GITHUB_TOKEN` / `GH_TOKEN`。不要把 token 写进 URL，magpie 会拒绝带凭据的地址。

## 更新

改这里 → push → 拉取新版本：

```powershell
magpie library skill update environment
```

不要直接编辑 `~/.config/magpie/library/skills/environment/`：本地内容与记录的 hash 不一致后，更新会被拒绝（需要 `--replace-edits` 强推），被替换的版本进备份。把库里的副本当只读。

## 备注

- `SKILL.md` 的第一步会读 `~/.agents/ENVIRONMENT.md`，那是本机快照，不随仓库分发；不存在时跳过。
- WSL 里的 agent 拿到的是副本，跟随 `magpie library sync` 更新。
- 技能目录名保持 `environment` 前缀；改名后自动定位仍然生效，但换成完全无关的名字就找不到了。
