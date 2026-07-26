# EMBERVEIL — Sprint 2 QA Plan（质量保障计划）

> **Owner:** quality-lead（严守真 / Yan Soujin） · **Date:** 2026-07-26
> **Sprint:** Sprint 2（Town/Dungeon 地图可玩核心，Route A）
> **Engine/Platform:** Godot 4.3（gl_compatibility / WebGL2 / HTML5），Web/小游戏，纯离线单机
> **下游消费者：** engineering-lead（实现 + CI）、主理人（放行回顾）
> **依据文档：**
> - `production/sprint-2-plan.md`（§4 交付顺序、§8 退出标准）
> - `production/epics/epic-09-feature-ui-town-dungeon.md`（E9.1~E9.6 拆分、GAP-1~12）
> - `design/gdd/town-dungeon.md`（场景级契约、§3.5 战斗种子硬契约、§8.5 七接口点）
> - `design/gdd/world-nodes.md` / `design/ux/ux-spec.md` / `docs/architecture/main-architecture.md`
> - `tests/qa/sprint-1-qa-plan.md`、`tests/qa/sprint-1-smoke-spec.md`（结构/风格模板）
> - 上游 `docs/architecture/adr/ADR-002`（战斗确定性）、ADR-003（数据驱动）、ADR-004（安全存档）

---

## 0. 质量策略摘要（读前必读）

Sprint 2 在 Sprint 1「可 boot、CI 绿、后台逻辑 + 纯函数战斗 + 安全存档」地基之上，做出**可玩的 Town/Dungeon 地图核心**——一条完整回路 `Boot→Title→NewRun→Town→Sage 进地牢→CombatRoom 遇敌→Battle 胜→FloorClear→回城`。

**本计划只产出测试策略与规格（不写游戏代码）**，严格照 `tests/qa/sprint-1-qa-plan.md` 的结构与风格。核心增量相对 Sprint 1 有三处：

1. **CI 闸升级为 6 道**（G/A/S/M/R/P），见 §1。Sprint 1 的 5 道闸（godot headless / GUT / asset_audit / palette_validator / content_lint / RNG lint）在本计划中归并为 **G(单测 GUT) / A(架构评审) / S(静态·style) / M(烟雾) / R(回归) / P(性能)**；原 G1 boot 健康并入 M 前置，原 G3/G4/G5/G6 静态检查并入 S。
2. **垂直切片冒烟**从「boot→save」扩展到完整可玩回路（含 Sage 续层、CombatRoom 遇敌、Battle 实时循环、Boss 掉 Stone Sigil），见 `tests/qa/sprint-2-smoke-spec.md`。
3. **四大关键风险**（战斗确定性 / Battle 叠加层不序列化 / 续档永落 Town / 占位数值待 E8 覆写）逐条给缓解，见 §4。

> ⚠️ **Sprint 2 起始态**：Sprint 1 `tests/` 脚手架（含 `test_boot_to_save.gd`、`test_combat_fsm_determinism.gd` 等 stub）已就位。本计划对标的 E9 实现**尚未落地**（实现等主理人二次派单）。下文所有 ⛔ 验证方法目前「由 stub/脚手架对标，待实现到达即成为回归门」；功能未实现前，其 ⛔ 项判为 **CONCERNS/NOT-YET**（非正式失败）。

---

## 1. CI 六道闸映射（G / A / S / M / R / P）

> 每道闸给出：覆盖的 E9 故事、PASS 判据、阻塞项（任一项失败 ⇒ 该闸红灯，阻断合并，需主理人书面豁免）。
> 对应 `production/sprint-2-plan.md` §8 退出标准「CI 闸绿」与「IP 闸」。

### 1.1 G — 单测（GUT unit + integration）

| E9 故事 | 单测 / 集成用例（对标 `tests/unit/`、`tests/integration/`） | PASS 判据 | 阻塞项（⛔） |
|----|----|----|----|
| **E9.1** World 骨架 | `test_scene_manager_accessors.gd`：`get_run_state()`/`get_world_state()` 返回与 `_run_state` 等价（GAP-3）；`test_world_swap.gd`：`_swap_world_child` 后 World 树仅 1 个 Town/Dungeon 实例、Battle overlay 增删无泄漏 | 访问器返回只读副本；World 下无重复子场景 | World 未常驻、Battle overlay 泄漏 |
| **E9.1/E9.4** 续层 | `test_enter_dungeon_continuation.gd`：`enter_dungeon()` 无参续到 `worldState.dungeon.floorIdx`（GAP-4），非恒 0 | 无参进入落到存档 floorIdx | 永远第 0 层（GAP-4 复现） |
| **E9.2** Town | `test_town_locked_nodes.gd`：Market/Barracks 面板打开被拒（灰显+toast）；`test_town_viewport.gd`：360×640 下 5 节点 ≥44×44px（复用 `test_viewport_layout`） | 锁节点不可激活；布局达标 | 锁节点误激活、<44px |
| **E9.3** Dungeon | `test_dungeon_cursor.gd`：`_move_cursor` 不能跳过未清房（GAP-2 session 态）；`test_puzzle_reset.gd`：Puzzle 错序 ⇒ 整组重置、无软锁（决策 2.4）；`test_seed_formula.gd`：同 `(seed,floorIdx,roomIdx,isBoss)` ⇒ 同 battle seed（GAP-11） | 光标不跳房；错序重置；种子一致 | 跳房、整组不重置、种子漂移 |
| **E9.4** 战斗衔接 | `test_battle_queue.gd`：序=SPD 降序、同速 slot 升序、死亡跳过（解 B4）；`test_build_party_combatants.gd`：返回 4 名我方 Combatant（GAP-9）；`test_apply_battle_xp.gd`：`apply_battle_xp(120,party)` 按 `100*level` 平分升级、不双存派生（GAP-8/GAP-10）；`test_combat_fsm_determinism.gd`（复用）：固定 `(seed,actions)` ⇒ 同 `log`+胜负 | 队列序正确；4 combatant；XP 按代码曲线；确定性绿 | 队列错、combatant=0、XP 错曲线、非确定 |
| **E9.5** 回城/存档 | `test_return_to_town_safe_save.gd`（脚手架，QA 填断言）：回城不重置 `clearedFloors`；wipe 后 `currentNode=="town"` 且 floorIdx 保留（决策 2.6）；Boss 胜 ⇒ `bossDefeated=true`+安全落盘 | clearedFloors 保留；wipe→Town；Boss attune 落盘 | 回城清进度、wipe 落非 Town |
| **E9.6** 输入 | `test_map_input_remap.gd`：改 `controlRemap` ⇒ `InputMap` 实际事件变更（复用 `test_settings_manager`） | 重映射即时生效 | 重映射不生效 |

- **G 闸 PASS**：上述全部用例绿，无 ⛔ 失败。
- **G 闸阻塞项（红灯）**：任一 ⛔ 项失败（World 未常驻、GAP-4 续层失效、Battle 确定性漂移、XP 曲线错、wipe 不落 Town 等）。

### 1.2 A — 架构评审（人工 review 门，非纯自动）

| E9 故事 | 评审点（对齐 `main-architecture.md` §2.2/§2.3、ADR-002/004） | PASS 判据 | 阻塞项（⛔） |
|----|----|----|----|
| **E9.1** | `World.tscn` 为常驻根；`_swap_world_child` 实例/移除 Town/Dungeon 为 World 子节点（GAP-1）；RunState 不被 reload | 场景树审查：World 常驻、Town/Dungeon 为子节点、RunState 常驻 | World 改为整页重载、双源重构 |
| **E9.4** | `Battle.tscn` 为**叠加层** `get_tree().get_root().add_child()`，**绝不序列化 mid-battle**（S6/架构 §2.2）；`CombatController` 在 `Battle.tscn` 内每战实例化（非 autoload） | 代码评审：Battle 不在 SceneManager 持久栈、add_child 到 root | Battle 被序列化 / 进存档栈（save-scum 风险） |
| **E9.5** | 安全节点集合 = {Town 进入, FloorClear, Sigil-attune, Quest-complete, Shrine}；mid-combat 绝不写盘 | 代码评审：公开写盘仅 `save_at_safe_node()`；战斗中 `save()` 被拦/ no-op | 安全节点集合外写盘、战中写盘 |
| **E9 全** | 状态变更只在 `BattleResolver`/managers；`EventBus` 仅 UI 通知（架构 §2.4） | 评审确认 handler 无逻辑副作用 | EventBus handler 改状态 |

- **A 闸 PASS**：上述评审点全部通过且留有 review 记录（`production/qa/reviews/`）。
- **A 闸阻塞项**：Battle 叠加层被序列化 ⇒ **S 级**（D4 破裂，可 save-scum）；World 双源重构 ⇒ 阻塞实现合并。

### 1.3 S — 静态 / style（静态检查 + 资源/内容/风格闸门）

| 子类 | 工具 / 脚本（复用 Sprint 1 的 `tools/`） | 覆盖的 ⛔ | PASS 判据 | 阻塞项（⛔） |
|----|----|----|----|----|
| **RNG lint** | `grep -rnE 'randi|randf|OS\.rand' src/combat src/battle` | GAP-11 / C4（战斗无全局 RNG） | 零命中；战斗仅注入 `RNGService` | 全局 RNG 泄漏 ⇒ 确定性破 |
| **content-lint** | `tools/content_lint.py` + `gut content_lint.gd` | GAP-5/6/7（4 层 Room 合法、encounter 命中、xpValue 齐全） | `dungeons.json` 4 层 × `RoomDef` 合法；`encounterId` 均命中 `encounters.json`；`enemies.json` 含 `xpValue`+~6 敌+Boss；无 `smoke_encounter` 残留 | 内容不完整、引用悬空 |
| **palette_validator** | `tools/palette_validator.gd` + `content/palette.json` | E（全局调色板 ≤48 色） | 调色板 ≤48 | >48 色 ⇒ IP/预算风险 |
| **asset_audit** | `tools/asset_audit.py` | E（atlas/纹理/预算 ≤4×1024²、≤16MB、WebP/PNG） | 预算内、格式合规 | 超预算 |
| **gdformat / style** | `gdformat --check src/` + 命名约定 lint | 代码风格一致性 | 零格式违规 | 大量格式违规 |
| **IP 令牌 grep**（自动部分） | `grep -rniE 'se_|ff1|ffix|square_enix|final_fantasy|crystal' src/ content/ assets/` | IP 红线 | 零命中 | 任意命中 ⇒ S（IP 违规） |

- **S 闸 PASS**：全部静态闸绿灯、无 `smoke_encounter` 残留、IP 令牌零命中。
- **S 闸阻塞项**：全局 RNG 泄漏、内容完整性失败、`smoke_encounter` 未删、调色板 >48、IP 令牌命中。

> ⚠️ 复用 Sprint 1 OQ1/OQ2 的开放项：`content_lint.py` 当前仅扫 JSON 且不校验必填/数值范围。**E9.3 落地 `content/` 为 `.json`（GAP-5/6/7）**，故本冲刺 F 类闸可覆盖；若工程改为 `.tres` 需先解决 OQ1（见 §7 OQ1）。

### 1.4 M — 烟雾（垂直切片可玩回路）

- **规格文件**：`tests/qa/sprint-2-smoke-spec.md`（逐条钉死 `tests/smoke/test_vertical_slice.gd` 断言）。
- **覆盖链路**：`Boot→Title→NewRun→Town→Sage 进地牢→CombatRoom 遇敌→Battle 胜→FloorClear→回城→安全存档`。
- **PASS 判据**：§1–§10 全步断言通过，且无 S 级失败（续档永落 Town、Battle 不序列化、战斗确定性、IP 闸门全绿）。
- **阻塞项（⛔）**：任一链路节点不可达（如 Sage「进入地牢」不可点、CombatRoom 不触发、Battle 不结束、FloorClear 不存档）⇒ 整体 FAIL。Battle 确定性漂移或战中写盘 ⇒ **S 级**。

### 1.5 R — 回归（Sprint 1 用例 + E9 新增）

| 来源 | 回归用例（复用 Sprint 1 脚手架） | PASS 判据 | 阻塞项（⛔） |
|----|----|----|----|
| Sprint 1 地基 | `test_save_roundtrip.gd`（D1/D2/D3）、`test_safe_node_write.gd`（D4）、`test_combat_fsm_determinism.gd`（C3）、`test_affinity.gd`（B5）、`test_rng_service.gd`（B2） | 全部绿，Sprint 1 ⛔ 不被破 | Sprint 1 ⛔ 回归失败 |
| E9 新增 | `test_return_to_town_safe_save.gd`、`test_seed_formula.gd`、`test_apply_battle_xp.gd` | 绿 | 见 §1.1 |
| 跨冲刺风险 | R2（种子化影响复现）、R5（安全节点被绕过）回归用例 | 绿 | 确定性破 / 安全节点被绕过 |

- **R 闸 PASS**：Sprint 1 全回归用例 + E9 新增用例全绿。
- **R 闸阻塞项**：任一 Sprint 1 ⛔ 因 E9 改动而回归失败。

### 1.6 P — 性能（WebGL2 HTML5 预算）

| 评估面 | 手段 | PASS 判据 | 阻塞项（⛔） |
|----|----|----|----|
| 启动健康 | `godot --headless --quit` 退出 0；CI 日志 `TITLE_REACHED` 在超时内（建议 ≤30s） | headless 退出码=0、无 import error、Boot→Title 在限内 | 启动超时 / import error |
| 垂直切片帧预算 | 烟雾中插桩：CombatRoom→Battle→FloorClear 期间无长帧；WebGL2 下内存 ≤ 预算（≤16MB 资产 + 合理运行时） | 切片内无 >100ms 卡顿；内存不超预算 | 长帧卡顿、OOM |
| 叠加层开销 | 单测/集成：每战 `RNGService`/`BattleFSM`/`CombatController` 实例后正确 `free`（无泄漏） | 战斗 overlay 退场后实例数回 0 | Battle 实例泄漏 |

- **P 闸 PASS**：启动限时、切片无长帧、Battle 实例无泄漏。
- **P 闸阻塞项**：启动超时、内存超预算/OOM、Battle 实例泄漏累积。

---

## 2. Sprint 2 测试矩阵（E9 × 测试类型）

> 对齐 `tests/` 脚手架（`unit/`、`integration/`、`smoke/`）。"已有 stub"= 文件已存在对标 API；"待建"= 本计划建议新增（实现到达即钉死为回归门）。

| E9 故事 | 单测（G: unit/） | 集成（G: integration/） | 烟雾（M） | 静态/内容（S） |
|------|----|----|----|----|
| **E9.1 World 骨架** | `test_scene_manager_accessors.gd`(GAP-3,待建) · `test_world_swap.gd`(GAP-1,待建) | `test_world_boot_to_town.gd`(Title→NewRun→Town,待建) · `test_enter_dungeon_continuation.gd`(GAP-4,待建) | `test_vertical_slice.gd` §5 | gdformat · 架构评审 A |
| **E9.2 Town** | `test_town_locked_nodes.gd`(待建) · `test_town_viewport.gd`(复用 `test_viewport_layout`) | `test_sage_enter_dungeon_gate.gd`(questAccepted&&!bossDefeated,待建) · `test_shrine_save.gd`(待建) · `test_inn_full_heal.gd`(待建) | §4 | palette_validator |
| **E9.3 Dungeon** | `test_dungeon_cursor.gd`(GAP-2,待建) · `test_puzzle_reset.gd`(决策2.4,待建) · `test_seed_formula.gd`(GAP-11,待建) | `test_f0_combat_to_clear.gd`(F0 Combat→clear_floor,待建) · `test_content_lint_dungeon.gd`(GAP-5/6/7) | §6 | content_lint(GAP-5/6/7) |
| **E9.4 战斗衔接** | `test_battle_queue.gd`(B4,待建) · `test_build_party_combatants.gd`(GAP-9,待建) · `test_apply_battle_xp.gd`(GAP-8/10,待建) · `test_combat_fsm_determinism.gd`(复用) | `test_headless_battle_loop.gd`(Attack+EnemyAI 真实循环,待建) | §7 | RNG lint(GAP-11) |
| **E9.5 回城/存档** | `test_return_to_town_safe_save.gd`(脚手架,QA填断言) | 同上（与 E9.4 复用 `_on_battle_resolved` 路径） | §8/§9 | 架构评审 A |
| **E9.6 输入** | `test_map_input_remap.gd`(复用 `test_settings_manager`) | `test_keyboard_touch_traverse.gd`(遍历 5 节点/房间光标,待建) | §4/§6 输入 | `test_viewport_layout`(44px) |

**新增文件建议**：`tests/smoke/test_vertical_slice.gd`（M 闸主体）、`tests/integration/test_return_to_town_safe_save.gd`（E9.5 脚手架）、上表「待建」单测/集成。
**复用 Sprint 1**：`test_boot_to_save.gd`、`test_combat_fsm_determinism.gd`、`test_affinity.gd`、`test_save_roundtrip.gd`、`test_viewport_layout.gd`（待建但已规划）、`test_settings_manager.gd`（待建但已规划）。

---

## 3. Sprint 2 回归风险

> 即「E9 改动可能引入的回归点」。每条给：风险面、触发场景、检测手段、缓解。

### R1 — 战斗确定性漂移（最高风险，GAP-11 / ADR-002）
- **面**：`battleNonce = floorIdx*100 + roomIdx*10 + (isBoss?1:0)`，组合 `rng.seed((seed+nonce)&0x7FFFFFFF)`。任意额外 RNG 抽（initiative tie-break、variance）或 nonce 组合不稳定 ⇒ 同输入不同战。
- **触发**：`resolve_action` 前后新增 `rng.next()`；`BattleQueue` 平局解算烧额外 RNG；nonce 写成 `seed + floorIdx*100 + roomIdx*10 + isBoss`（漏 `?1:0`）。
- **检测**：`test_seed_formula.gd`（G 闸）钉死 formula；`test_combat_fsm_determinism.gd`（C3）固定 seed=42 两遍同 `log`；RNG lint 守 `src/combat`+`src/battle`。
- **缓解**：确定性测试即回归门；nonce 组合在实现中稳定且注释（GDD §3.5）；RNG lint 防全局 RNG 泄漏。

### R2 — Battle 叠加层被序列化（save-scum 风险，S 级）
- **面**：架构 §2.2 规定 Battle 为叠加层、`add_child` 到 root、**永不被序列化**。若 Battle 被放进 SceneManager 持久场景栈或存档 ⇒ 可存档刷。
- **触发**：`_start_battle` 误用 `SceneManager.go_to("Battle")`；存档序列化误含 `battleState`。
- **检测**：A 闸架构评审；烟雾 §7/§8 断言 reload 后**无** `battleState` 键；`test_safe_node_write.gd`（D4）断言战中写盘被拦。
- **缓解**：公开写盘仅 `save_at_safe_node()`；Battle overlay 增删走 `get_tree().get_root().add_child/remove_child`；CI 评审。

### R3 — 续档不落 Town（决策 2.6 破裂）
- **面**：`SaveManager.load()` 后 `currentNode` 必须恒 `"town"`；地牢进度由 `worldState.dungeon.floorIdx/clearedFloors` 保留。若「Floor 进入」被误标为安全节点 ⇒ 脏续档、跳层。
- **触发**：`enter_dungeon` 内部误调 `save_at_safe_node`；wipe 后回错节点。
- **检测**：`test_return_to_town_safe_save.gd`（G/R 闸）：wipe ⇒ `currentNode=="town"` 且 floorIdx 保留；烟雾 §9 断言回城 `currentNode=="town"`。
- **缓解**：安全节点集合严格 = {Town 进入, FloorClear, Sigil-attune, Quest-complete, Shrine}；Floor 进入**非**安全节点（O-2 不采纳）。

### R4 — 占位数值被 E8 与 E9 各写一份（O-5 / GAP-10）
- **面**：E9.3 内容与 E8 balance spike 都碰 `content/` 数值 ⇒ 冲突、双源。
- **触发**：E9.3 用「结构 + 占位数值」写 `dungeons.json`/`enemies.json`/`encounters.json` 后，E8 又独立写一份最终数值未对齐。
- **检测**：content_lint（S 闸）校验数值范围（stats≥1、MP 4–10、xpValue 8–25、Boss~120）；`xp_for_level=100*level` 代码锁（GAP-10）单测钉死。
- **缓解**：流程约定——E9.3 先写结构+占位，E8 再经 `content/` 覆写（ADR-003 零代码改动）；**切勿两边各写一份**；XP 曲线以代码 `100*level` 为准（GAP-10 已拍板，`progression.md` 旧 `20*l^1.35` 留 E8 统一修订）。

### R5 — 逐房间 session 态污染续档（GAP-2）
- **面**：`currentRoomIdx`/`clearedRoomIds` 为 Dungeon 场景 session 态（不进存档）。若误持久化 ⇒ 脏续档跳房。
- **触发**：房间光标被写进 `RunState.worldState`；跨会话恢复后房间态错位。
- **检测**：`test_dungeon_cursor.gd`（G 闸）断言光标仅 session；content_lint 断言 `RunState` schema 无逐房间字段。
- **缓解**：房间态仅存 Dungeon 场景内存；安全点只在层边界，wipe 回上一层重打。

---

## 4. 四大关键风险与缓解（任务指定）

> 任务要求显式覆盖的四项。每条给「为什么是风险 + 验证 + 缓解」。

### 4.1 战斗确定性（seed 可复现）— GAP-11 / ADR-002 / GDD §3.5
- **风险**：垂直切片「好玩」的前提是战斗可复现、可测试、可 replay。nonce 派生公式或 RNG 注入任一不稳 ⇒ 同房不同战，确定性测试破、回放失效。
- **硬契约**：`nonce = floorIdx*100 + roomIdx*10 + (isBoss ? 1 : 0)`；`rng.seed((run_state.seed + nonce) & 0x7FFFFFFF)`；nonce **派生非持久**，不存计数器、不进存档。
- **验证**：`test_seed_formula.gd`（公式单测）+ `test_combat_fsm_determinism.gd`（同 `(seed,actions)` ⇒ 同 `log`/胜负）+ RNG lint（无全局 RNG）。
- **缓解**：确定性测试为 G/R 回归门；nonce 组合实现稳定且注释；逐次尝试差异留未来（持久 `battleAttempt`，当前不采纳）。

### 4.2 Battle 叠加层不序列化 — S6 / 架构 §2.2
- **风险**：Battle 一旦进存档栈或存档 blob ⇒ 可存档刷（save-scum），破坏防 scum 设计。
- **验证**：A 闸架构评审（Battle `add_child` 到 root、不在 SceneManager 栈）+ 烟雾 §7/§8 断言 reload 无 `battleState` 键 + `test_safe_node_write.gd`（D4）。
- **缓解**：公开写盘仅 `save_at_safe_node()`；战斗中 `save()` 被拦/no-op；Battle overlay 增删走 root。

### 4.3 续档永落 Town — 决策 2.6
- **风险**：F4 通关或 wipe 后若 `currentNode` 非 `"town"` ⇒ 续档落错节点、跳层、脏续档。
- **验证**：`test_return_to_town_safe_save.gd`（wipe⇒`town`+floorIdx 保留，G/R 闸）+ 烟雾 §9（回城 `currentNode=="town"`）+ `SaveManager.load()` 单测。
- **缓解**：安全节点集合严格不含「Floor 进入」；`SaveManager.load()` 后 `currentNode` 恒 `"town"`；地牢进度由 `floorIdx/clearedFloors` 经 Sage 续层（O-2 不采纳内续档）。

### 4.4 占位数值待 E8 覆写 — O-5 / GAP-10
- **风险**：Sprint 2 用占位数值跑通回路，若 E9 与 E8 各写一份数值 ⇒ 冲突、双源、平衡漂移。
- **验证**：content_lint（S 闸）数值范围校验；`xp_for_level=100*level` 代码锁单测（GAP-10）；`derive_stats` 占位公式待 E8 替换。
- **缓解**：E9.3 先写「结构 + 占位」、E8 再经 `content/` 覆写（ADR-003 零代码改动）；XP 曲线以代码为准（GAP-10 已拍板）；`progression.md` 旧公式留 E8 统一修订，本冲刺不主动改。

---

## 5. Bug 分级标准与 Triage 流程

> 复用 Sprint 1 QA Plan §4 分级（S/A/B/C）与 Triage 流程，Sprint 2 不另起炉灶。摘要如下：

| 级 | 名称 | 定义 | Sprint 2 典型示例 |
|----|----|----|----|
| **S** | Blocker（阻塞发布） | 任意 ⛔ 项失败；CI 任一道闸红灯；IP 违规；存档损坏可被加载；纯离线被破；Battle 被序列化（save-scum）；战斗非确定 | 调色板 >48、全局 RNG 泄漏、FF1 令牌残留、Battle 进存档、nonce 漂移、wipe 不落 Town |
| **A** | 功能缺陷 | 破坏某 E9 验收或核心契约，无可行绕过 | Sage 进地牢不门控、GAP-4 续层失效、XP 错曲线、锁节点误激活、FloorClear 不存档 |
| **B** | 体验 | 功能可用但不达标 | reduced-motion 仍有轻微闪烁、节点 <44px、text-scale 1.25 裁剪标签 |
| **C** | 建议 | 打磨/命名/文档 | 命名不一致、注释缺失、文档 typo |

**Triage 流程**：① reporter 在 `production/qa/bugs/` 建单（severity + 复现步骤 + 上下文）；② QA lead 确认 severity 并指派 priority（P0=S 立即修 / P1=A 本冲刺修或主理人豁免 / P2=B backlog / P3=C backlog）；③ S 阻断合并、A 本冲刺修或主理人书面豁免；④ 任何 S 降级或 ⛔ 豁免须主理人（游承峰）签字；质量门为**建议性门控**——判定给主理人，最终放行由用户定。

---

## 6. IP 护栏验证

> 原创 IP 铁律：无 Square Enix / FF1 资产、布局、字体、商标；仅 Ward-Sigil 语 + Underdog Stage。复用 Sprint 1 §6，Sprint 2 增量见下方「Sprint 2 新增」。

| 护栏 | 验证手段 | 自动/人工 | 通过判据 |
|------|----|----|----|
| 无 SE/FF1 资产/引用 | CI grep `src/`、`content/`、`assets/` 对令牌 `se_`/`ff1`/`ffix`/`square_enix`/`final_fantasy`/`crystal` | **自动**（S 闸） | grep 零命中 |
| 无 FF1/SE 音频 | grep `assets/audio/` 对 `ff1_`/`se_`/`ff_` + 人工比对音色 | **自动+人工** | 零命中；无 FF1 式 chiptune 音色 |
| 调色板 ≤48 色 | `tools/palette_validator.gd` + `content/palette.json` | **自动**（S 闸） | ≤48 |
| 交互元素 ≥44×44px | `test_viewport_layout.gd`（Town 5 节点 / Dungeon 房间光标） | **自动**（G 闸） | 360×640 下均 ≥44px |
| reduced-motion fade-only | 单测/人工：转场/反馈无闪/震/blink；`reducedMotion` 仅 fade | **自动+人工** | 无 blink/震屏；仅 fade |
| Ward-Sigil 形状+标签 | `SigilDrawer` 单测（7 字形互异）+ 节点含 `displayName` 文本标签；色盲叠加轮廓 | **自动+人工** | 形状互异 + 文本标签存在；禁只用颜色 |
| Underdog Stage 构图 | 布局断言 + 人工评审 | **人工评审门** | 敌弧在上、我方带居中下、命令 dock 左下；非 FF1 全宽底栏 |
| Boss 掉 Stone Sigil 表现 | 集成：`WardCodex.attune("stone")` + 解锁 Stone 元素；非 FF1 式「水晶」语义 | **自动+人工** | attune 成功、无 FF1 水晶图标 |

**Sprint 2 新增 IP 关注**：Boss `Sigil-Twisted Warden` 掉 **Stone Sigil** 的表现须用原创 Ward-Sigil 语义（形状+标签），**不得**套用 FF1「水晶」图标/命名（IP 令牌 grep 已覆盖 `crystal`）。

---

## 7. 需主理人裁决的开放问题（不自行假设）

- **OQ1（Critical，沿用 S1）— content_lint 格式覆盖。** `content_lint.py` 仅扫 `.json`。E9.3 落地 `content/` 为 `.json`（GAP-5/6/7），故 F 类闸可覆盖；**若工程改 `.tres` 需先解决 OQ1**（落地 `content_lint.gd` 读 Resource，或统一 JSON）。需主理人确认 E9.3 权威内容格式。
- **OQ2（High，沿用 S1）— content_lint 校验深度。** 现有仅查 id 唯一 + 元素引用；不查必填/数值范围。E9.3 落地需扩展校验（`xpValue` 齐全、`reward` 合法、Boss 仅末层）。需裁决：扩展 `content_lint.py` 或正式接受较弱门控。
- **OQ3（Med，Sprint 2 新）— PuzzleRoom/BossRoom 演出推后范围。** 任务明确 Puzzle/Boss 演出推后，但「可交互契约（决策 2.4 错序重置 / Boss 掉 Stone）」须在首冲刺可用。需主理人确认：首冲刺是否仅交付「F1 CombatRoom 可玩 + 谜题/Boss 交互契约可达（无演出打磨）」，演出留后续 sprint。
- **OQ4（Med，Sprint 2 新）— 5 指令全实现范围。** 任务明确「5 指令完整打磨推后」。需确认：首冲刺 MVP 用 `Attack+EnemyAI` 跑通循环（E9.4 DoD），`Skill/Elemental/Defend/Item/Run` 路径**保持纯函数 + 仅注入 RNGService** 但平衡/表现推后（R1 不阻塞垂直切片）。
- **OQ5（Med，Sprint 2 新）— 性能闸阈值。** P 闸「启动 ≤30s / 无 >100ms 长帧 / ≤16MB 资产」为建议初值。需主理人确认 WebGL2 HTML5 目标机型的帧预算与内存上限，据此钉死 P 闸判据。
- **OQ6（Med，沿用 S1）— IP gate 人工评审归属与记录。** Underdog Stage 构图 + Ward-Sigil 形状唯一性为人工评审门。需裁决评审执行人（建议 art-director + design-strategist）与签字产物（如 `design/reviews/ip-clearance-sprint2.md`）。

---

*End of Sprint 2 QA Plan. 下游：engineering-lead 据 §1 六道闸 + §2 矩阵实现/补建用例与 CI；主理人据 §7 裁决开放问题后放行 Sprint 2。IP 人工评审门见 §6/OQ6。*
