# Phase 5 · Sprint 1 — 主理人门控（设计评审 + 范围检查）

**项目**：EMBERVEIL（Godot 4 WebGL2 / Web 小游戏 / 纯离线单机）
**评审人**：主理人 游承峰 ｜ **日期**：2026-07-26
**结论**：**PASS（附条件）** —— 静态核验全绿；A3(头less boot)/G(GUT 执行)/E(palette_validator) 三道门须在 GitHub Actions 实跑通过后才算最终放行。

---

## 1. Sprint 1 范围确认（无溢出）

| Epic | 内容 | 状态 |
|------|------|------|
| E1 脚手架 | project.godot(gl_compatibility) / export_presets.cfg / CLAUDE.md / 5 场景骨架 | ✅ |
| E2 Autoloads | 12 autoload + RNGService(class_name)；settings 存储=全局 `emberveil.settings.v1` 权威 + `RunState.settings` 镜像 | ✅ |
| E3 战斗 FSM | PreBattle→…→PostBattle；纯函数 `BattleResolver.resolve_action`；可种子化 RNGService 确定性；数值 content 占位 | ✅ |
| E4 Save/Load | localStorage 单槽 / 安全节点存档 / New Run 确认 / schemaVersion=1 + crc32 / settings 前向填充 | ✅ |
| E5/E6 审计·数据 | content/*.json 占位 def；AssetRegistry.validate_atlas 落实 3 条资产硬约束 | ✅ |
| E7 测试框架·CI | 15 GUT 用例 + 3 CI 辅助脚本；CI 6 道闸（godot headless / GUT / asset_audit / palette_validator / content_lint / RNG lint） | ✅ authored |

纯离线护栏全程生效（无云/账号/网络/远程配置；EventBus 仅 UI）。无 feature UI（Town/Dungeon/Codex/Barracks）越界。

---

## 2. 门控状态

| 门 | 项 | 本环境静态核验 | 须 GA 实跑 |
|----|----|----------------|-----------|
| A 脚手架 | A1 gl_compatibility | ✅ check_project_cfg PASS | |
| | A2 CLAUDE.md | ✅ check_claude_md PASS | |
| | A3 headless boot→Title | ⏳ 无 godot | ✅ 须跑 |
| | A4 布局/目录 | ✅ check_layout PASS（assets/ 可选 warn） | |
| B autoloads | 12+RNGService / settings 存储 / textScale clamp / 前向填充 | ✅ 静态 + 测试已写 | ⏳ GUT 执行 |
| C 战斗确定性 | BattleResolver 纯函数 / FSM / RNG lint | ✅ RNG_LINT_CLEAN | ⏳ GUT 执行 |
| D 存档 | roundtrip / migration / CRC / safe-node / R1 前向填充 | ✅ 静态 + 测试已写 | ⏳ GUT 执行 |
| E 资产审计 | asset_audit（无资产，空过） | ✅ | ⏳ palette_validator(godot) |
| F content_lint | 21 defs 无重复 id | ✅ [PASS] | |
| G GUT 烟雾 | 15 用例 + 3 工具 | ✅ authored | ⏳ 须 godot 跑 |
| IP 护栏 | 无 FF1/crystal；Underdog Stage 结构；Ward-Sigil 原创 shape | ✅ 静态 | |

**本环境硬限制**：非 git 仓库、无 godot 二进制、无 addons/gut → A3/G/E 与完整 CI **只能在 GA `push` 后跑**。此处仅做到静态 + python 工具级核验。

---

## 3. 主理人独立核验记录（信任但验证）

- **直接修（成员子代理运行时中断时）**：`jobs.json` 第 4 职业 `lumen`→`skirmisher`（真实重复 id bug，令 F 门红）；`ci.yml` RNG lint 加 `|grep -vE '^\s*#'` 跳注释。复跑 content_lint=[PASS]、RNG lint 干净。
- **读源码确认缺口属实并路由修复**（engineering-lead-2）：A1 `settings_manager.set_value` 无 textScale clamp；A2 `battle_resolver` 写 HP 无 `max(0,…)` 地板；C2 `save_manager` 加载层未做 settings 前向填充（OQ4 裁定未落地，R1 旧档回归风险）。三处均已修。
- **抓到会崩的 bug**：`save_manager.gd` 曾把 `_forward_fill_settings` **定义了两次**（GDScript 重复函数定义 → autoload 解析失败 → A3 headless boot 必挂）。成员自报「收口完成」但没跑 godot 漏掉。已换新实例修掉（删重复定义 + 删 L84 冗余调用），复读确认恰 1 个定义。`main-architecture.md:171` 残留旧信号名 `combat_action_resolved` 一并改为 `battle_event`。
- **收口后复跑**：A1/A2/A4/F 全绿；B/C/D 测试已按真实 API 编写并与 G1/G2/G3 修复对齐（clamp / HP 地板 / 前向填充契约）。

---

## 4. CONCERNS（非阻塞，须跟踪）

1. **GUT/headless 从未在真环境执行** —— 本环境无 godot。A3/G/E 三道门必须 GA 跑通才算真正绿；成员自报「完成」不可作放行依据（本次重复函数 bug 即教训）。
2. **OQ2 content_lint 深度校验未实现**（stats≥1 / MP 4–10 / resonance≤5 / level cap 20）—— 加上会令占位数值变红，留 E8 数值锁定时再做。
3. **推后项**：B4 BattleQueue 工具类（C2 队列序目前 test 侧各实现）、B5 AssetRegistry 重复 id 守卫（暂靠 F 门 content_lint 兜底）、B3 `next_variance` 命名。
4. **assets/ 目录仍缺** —— Sprint 1 无美术资产，A4 已放宽 assets/ 为可选；美术导入后该目录才计入。
5. **E8 数值锁定 + feature UI**（Town/Dungeon/Codex/Barracks）不在 Sprint 1，推 Sprint 2+。
6. **音频阮和鸣 Phase 6**；**IP 人工评审（OQ6）退退出时**由 art-director + design-strategist 共签 `design/reviews/ip-clearance-sprint1.md`。

---

## 5. 退出裁决

- Sprint 1 **静态门全绿**，范围无溢出，**允许进入「垂直切片可玩走查」**确认核心循环「好玩」。
- **最终放行条件**：GA 实跑 A3(headless boot)/G(GUT 全绿)/E(palette_validator) 三道门通过后，主理人签 Sprint 1 完成。
- 下一步：垂直切片可玩走查（手测或 GA）+ Sprint 2 规划（E8 数值锁 + feature UI 起步）。
