# agent-skills

个人 agent 技能集合，通过 [magpie](https://usemagpie.ai) 的 Library 分发：每个子目录是一个技能（含 `SKILL.md`），magpie 记录来源仓库和 commit，可以检查更新并一键拉取。

## 技能

| 技能 | 用途 |
| --- | --- |
| `environment` | 查询当前 Windows 工作站的运行环境：操作系统、PowerShell、硬件、磁盘、工具链版本与路径、WSL 状态、代理设置 |

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
pwsh -NoProfile -File .\skills\environment\scripts\env-info.ps1 -Section all -Format Text
```

`-Section` 可取 `os`、`hardware`、`shell`、`toolchain`、`disk`、`wsl`、`network`、`config`、`all`，多个用逗号分隔。默认输出 JSON。

想验证“被 agent 调用”的形态，可以在 magpie 的 Library 页面从本地文件夹添加这个技能（链接安装，改文件即生效），微调完再移除。

## 安装到 magpie

1. push 到 GitHub。
2. magpie → Library → Skills → 安装，粘贴：

   ```
   https://github.com/<owner>/<repo>/tree/main/skills/environment
   ```

3. 勾选要分发的 agent（如 `codex`、`opencode`、`fx`，WSL 里的 agent 会拿到副本）。

**安装前先移除同名的本地技能**，否则 magpie 会并排装成 `environment-<owner>`，而 `SKILL.md` 里的脚本路径写死了 `...\skills\environment\...`：

```powershell
magpie library skill rm environment
```

私有仓库：在 Settings → Network and sharing 填 GitHub token（fine-grained，只读 `Contents` 即可），或设 `GITHUB_TOKEN` / `GH_TOKEN`。不要把 token 写进 URL，magpie 会拒绝带凭据的地址。

## 更新

改这里 → push → 拉取新版本：

```powershell
magpie library skill update environment
```

不要直接编辑 `~/.config/magpie/library/skills/environment/`：本地内容与记录的 hash 不一致后，更新会被拒绝（需要 `--replace-edits` 强推），被替换的版本进备份。把库里的副本当只读。

## 备注

- `SKILL.md` 的第一步会读 `~/.agents/ENVIRONMENT.md`。那是本机快照，不随仓库分发；新机器上不存在时应跳过这一步。
- WSL 里的 agent 拿到的是副本，跟随 `magpie library sync` 更新。
- 技能文件夹名必须保持 `environment`，脚本路径依赖它。
