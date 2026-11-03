---
name: agent-lessons
description: 把对话里踩过的坑沉淀成可复用约束，并定期蒸馏、去重、淘汰过期规则。当任务中出现可复现的错误、返工或用户纠正，用户说“记一下这个坑”“沉淀经验”“蒸馏 lessons”，或需要维护 AGENTS.md 与技能库时使用。
---

# 经验沉淀

目标：让一次踩坑变成长期有效的约束，同时不让规则腐烂。

## 两个阶段，分开做

| 阶段 | 时机 | 写到哪 |
| --- | --- | --- |
| 记录 | 出错的当下，只追加不整理 | `$env:USERPROFILE\.agents\lessons-inbox.md` |
| 蒸馏 | 每周或每月，集中做 | 按下方分层落到对应位置，并更新 `references/lessons.md` |

**记录时不要直接改 AGENTS.md，也不要改 magpie 库里的技能副本。** 库副本一改，`magpie library skill update` 就会拒绝更新，旧版本只能进备份。

## 记录格式（四字段，缺一不收）

```md
## 2026-11-03 用 curl 拿到的是 Invoke-WebRequest 对象
- 症状：把响应当文本解析，字段全空
- 根因：Windows PowerShell 5.1 的 curl 是别名
- 规则：外部 HTTP 一律写 curl.exe
- 检查：命令里出现裸 curl 即命中
```

## 蒸馏时先分类

| 类型 | 落点 | 例子 |
| --- | --- | --- |
| 易变事实 | `ENVIRONMENT.md`，重新生成而不是手改 | 版本、路径、端口、代理 |
| 操作知识 | 对应 skill（如 `powershell`） | 引号、编码、JSON 深度 |
| 能机器判定 | 脚本、hook、preflight | 禁用 `rm -rf`、提交前构建 |
| 不变量 | `AGENTS.md` | 工具归属、验证闸门 |
| 一次性 | 丢弃 | 拼写错误、偶发网络失败 |

## 进入 AGENTS.md 的门槛

- 复发 ≥ 2 次，或单次代价极高（丢数据、误发布、长时间返工）
- 可证伪：“不要用 `rm -rf`”可判定；“注意路径安全”不可判定，不收
- 必须写明检查方式
- 同一事实只在一处定义，其他位置引用而不是复制

## 蒸馏步骤

1. 读 inbox，按根因聚类；同一根因的多条合并成一条。
2. 逐条分类落到对应层；能写成脚本的优先写脚本。
3. 更新 `references/lessons.md`，只保留已蒸馏的条目和去向。
4. 清空 inbox，保留模板。
5. 仓库 commit + push；技能有改动时 `magpie library skill update agent-lessons`；instructions 有改动时 `magpie library sync`。
6. 验证：`magpie library skill update` 无报错，agent 侧文件已更新。

## 反模式

- 一次事故就加一条全局规则
- 只加不删；AGENTS.md 超过 120 行先做减法
- 把版本号、绝对路径写进 AGENTS.md
- 同一规则在多个地方重复
- 规则没有检查手段
- 把原始事故直接贴进 AGENTS.md

## 维护节奏

- 每次出错：记 inbox，不打断当前任务
- 每周：快速蒸馏一次，只处理能明确分类的
- 每月：删过期规则、检查 120 行上限、确认每条规则仍有检查方式
