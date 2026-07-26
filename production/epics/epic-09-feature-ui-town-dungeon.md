# Epic E9 — Town / Dungeon 地图（Feature UI 垂直切片）

**目标：** 在 Sprint 1 已落地的「后台逻辑 + 纯函数战斗 + 安全存档」地基之上，做出**可玩的 Town/Dungeon 地图核心**：
WWORLD 常驻承载 Town↔Dungeon↔Battle 切换；Hearthmoor 节点图 5 节点可交互；The Sundered Ward 4 层
节点步进地图；遇敌固定触发、经 CombatFSM/CombatController 衔接 BattleResolver 纯函数；回城与 FloorClear
走安全节点存档落盘；移动与输入复用 ux-spec §3 逻辑动作 + SettingsManager/InputMap。
**Owning systems：** S5（World Nodes）· S2（战斗衔接）· S6（安全存档）· 跨切面（输入/无障碍）。
**Depends on：** E1·E2（autoloads，含 SceneManager/WorldDirector/SaveManager/SettingsManager/PartyManager/ProgressionManager）·
E3（BattleResolver/BattleFSM/EnemyAI 结构）· E4（SaveManager 安全节点）· E6（content 数据）· E7（测试脚手架/CI）。
**引擎：** Godot 4.3（gl_compatibility，WebGL2，HTML5）· **纯离线单机** · **审核档：FULL**。
**设计契约源：** `design/gdd/town-dungeon.md`（已就绪，Route A）· 上游 `world-nodes.md` / `ux-spec.md` / `main-architecture.md`。

> 本 Epic 是 `epic-02` 中 E2-L（Town）、E2-M（Dungeon）的「Later」项被提升为 Sprint 2 首冲刺可玩核心。
> 设计 GDD 已锁选型：**Town=节点图**、**Dungeon=节点步进**、**地牢内无随机遭遇**（战斗仅 CombatRoom/BossRoom）、
> **Battle 叠加层永不序列化**、**续档永落 Town**、**XP 曲线以代码 `xp_for_level=100*level` 为准**（GAP-10）。
> 本文件把 GDD §8 的 GAP-1~9 修复**纳入各 Story 验收与依赖**，GAP-10 已拍板。

---

## 0. 范围（垂直切片）

**第一冲刺聚焦「Town/Dungeon 地图可玩核心」**——跑通一条完整回路：
`Boot → Title → New Run → Town(Hearthmoor) → Sage 接任务进地牢 → CombatRoom 遇敌 → Battle → FloorClear → 回城`。

| 切片内（MVP 深度） | 切片外（本 Epic 后续 / 其他 Epic） |
|---|---|
| World 常驻 + 真实场景切换（E9.1，含 GAP-1/2/3/4） | Market/Barracks/Codex 完整经济 UI（E2-I/E2-K/E2-J，Later） |
| Town 节点图：Sage（进地牢）+ Shrine（存档）+ Inn（满血）可交互；Market/Barracks 锁（E9.2） | Town 全节点商店/雇佣深度（E2-K） |
| Dungeon 4 层节点步进 + CombatRoom 遇敌 + FloorClear（E9.3，含 GAP-2/5/6/7） | PuzzleRoom/BossRoom 完整演出打磨（E9.3 深度子项，见 §5 R4） |
| 战斗：CombatController 驱动真实循环（Attack+EnemyAI）+ XP 回写（E9.4，含 GAP-8/9/11） | 5 指令全实现（Skill/Elemental/Defend/Item/Run 完整，E3-F/G 收口） |
| 回城 + 安全节点存档落盘（E9.5） | 多城镇/Overworld（L3+） |
| 移动与输入：节点 tap + 焦点导航 + InputMap（E9.6） | 网格自由探索（GDD 决策 2.2 已否决） |

---

## 1. Story 列表

### E9.1 · World 场景骨架（resident + 真实场景切换；含 GAP-1/2/3/4）
- **目标：** `World.tscn` 成为常驻根；`WorldDirector` 真正实例/移除 Town/Dungeon 为 World 子节点；`SceneManager` 加只读访问器；`enter_dungeon` 无参续层；逐房间态作为 Dungeon session 态（不进存档）。
- **User Story：** 作为玩家，我希望进入世界后 Town/Dungeon 是连续的一座城、而非整页重载，这样存档一致、无 save-scum。
- **Ref：** main-arch §2.2；town-dungeon §8.2(a)/§8.4(GAP-1/2/3/4)；ux-spec §2.1/§2.2。
- **DoD（含 GAP 修复）：**
  - `SceneManager` 新增 `get_run_state() -> Dictionary`（返回 `_run_state.duplicate(true)` 只读副本）、`get_world_state() -> Dictionary`（返回 `_run_state["worldState"]`）——**GAP-3**。
  - `WorldDirector` 新增 `_swap_world_child(scene_path, params)`：移除当前 Town/Dungeon 子节点、实例新场景并作为 `World.tscn` 子节点加入（架构 §2.2 常驻）——**GAP-1**。
  - `WorldDirector.enter_dungeon(floor_idx: int = -1)`：**无参时续到 `worldState.dungeon.floorIdx`**（原为永远 0 的 bug）——**GAP-4**；`go_to` 内部逻辑不变。
  - `World.tscn` 从空占位建成常驻根（WorldRoot 挂载点 + Battle overlay 层）。
  - **GAP-2**：逐房间光标/`clearedRoomIds` 作为 Dungeon 场景 session 状态（不写存档），避免脏续档跳房。
  - Battle 仍 `get_tree().get_root().add_child()` 叠加（**绝不序列化 mid-battle**，S6）。
- **验收（可测试）：**
  1. 集成（headless）：`Title→NewRun→World(Town)` 到达 Town；`WorldDirector.enter_dungeon()`（无参）实例 Dungeon 且 `floorIdx` 取自 `worldState.dungeon.floorIdx`（非恒 0）。
  2. 单测：`SceneManager.get_world_state()` 返回与 `_run_state["worldState"]` 等价的字典（GAP-3）。
  3. 集成：`_swap_world_child` 后 World 树下仅 1 个 Town 或 Dungeon 实例；Battle overlay 增/删无泄漏/重复。
  4. 单测：mid-combat 不触发任何 save（复用 E4-D 契约）。
- **涉及新增/修改文件：**
  - 修改 `src/autoloads/scene_manager.gd`（GAP-3 访问器）
  - 修改 `src/autoloads/world_director.gd`（GAP-1 `_swap_world_child`、GAP-4 无参续层）
  - 修改 `scenes/world/World.tscn`（建成常驻根 + 挂载点）
  - 新增 `scenes/town/Town.tscn`、`scenes/dungeon/Dungeon.tscn`（骨架，内容由 E9.2/E9.3 填充）
- **依赖：** E2（autoloads）、E4（安全节点）、E7（测试）、GDD `town-dungeon.md`。
- **Sprint：** 2 · **⛔ Blocker：** 是 · **Depends：** E1,E2,E4,E7。

### E9.2 · Town 场景 Hearthmoor（节点图 5 节点 + tap + Sage 进地牢 + Shrine 存档）
- **目标：** 按 GDD 决策 2.1 建成 Hearthmoor **节点图**（单屏 5 节点，中心对称；Ward-Sigil 形状+标签）；Sage 接任务后开放地牢入口；Shrine 为手动安全节点；Inn 满血；Market/Barracks 锁。
- **User Story：** 作为玩家，我希望在安全的 Town 里接任务、存档、休整，再进地牢，这样节奏与风险清晰。
- **Ref：** town-dungeon §2.1/§3.1/§4.1；world-nodes §2/§6；ux-spec §5.5；art-bible §7.3。
- **DoD：**
  - `Town.tscn` + `Town.gd`：5 节点 `Control`（≥44×44px，形状+文字标签）；`ui_up/down/left/right` 移焦点环、`ui_accept` 激活 → 打开叠加面板（不切场景）。
  - 节点动作（GDD §3.1 `TownNode{id,displayName,sigilShape,action}`）：`rest`→满血+toast；`sage`→任务面板+「进入地牢」按钮（仅 `questAccepted && !bossDefeated` 可用）→ `WorldDirector.enter_dungeon()`；`shrine`→确认→`SaveManager.save(run_state, true)`（安全节点）+ toast+微光；`shop`/`barracks`→锁（置灰、「即将开放」）。
  - 读世界态经 `SceneManager.get_world_state()`（GAP-3）；`reducedMotion` 仅 fade；`colorblindAssist` 叠加轮廓。
- **验收（可测试）：**
  1. 布局：360×640 下 5 节点均 ≥44×44px 且可见（复用 `test_viewport_layout` 契约）。
  2. 集成：Sage「进入地牢」仅在 `questAccepted && !bossDefeated` 可用；否则禁用。
  3. 集成：Shrine tap → 一次 `save_event` 且 localStorage 落盘（safe-node）；Inn tap → 全队 HP/MP 复位（经 PartyManager/ProgressionManager 派生值）。
  4. 单测：Market/Barracks 面板打开被拒（锁）。
- **涉及新增/修改文件：** 新增 `scenes/town/Town.tscn`、`src/world/town_controller.gd`（或 `Town.gd`）。
- **依赖：** E9.1（World/Town 实例）、E4（SaveManager）、E2-F（PartyManager/ProgressionManager）、GAP-3（访问器）。
- **Sprint：** 2 · **⛔ Blocker：** 否 · **Depends：** E9.1,E4。

### E9.3 · Dungeon 4 层节点步进地图（含 GAP-2/5/6/7 + 战斗种子）
- **目标：** 实现 The Sundered Ward 4 层 **节点步进**地图（GDD 决策 2.2）：每层 Room 轨道 `Combat→Puzzle(ember→frost→storm)→Reward`，F4 末加 `Boss`；CombatRoom 固定触发遇敌；FloorClear 安全存档；逐房态为 session（GAP-2）。
- **User Story：** 作为玩家，我希望地牢一层一层步进推进、遇敌即战、清层即存，这样「一层=一个完整节拍」。
- **Ref：** town-dungeon §2.2/§3.2/§3.3/§4.2/§8.4(GAP-2/5/6/7)；world-nodes §3/§4/§6。
- **DoD（含 GAP 内容修复）：**
  - `Dungeon.tscn` + `Dungeon.gd`：持有当前层 Room 序列；`ui_left/right` 移动房间光标（仅前进越过已清房，GAP-2 光标为 session 态）、`ui_up/down` 房内交互预留（谜题选石）；`ui_accept`/tap 进房。
  - Room 触发：`combat`/`boss`→固定启动 Battle 叠加层；`puzzle`→Ember→Frost→Storm 三石（错序整组重置，决策 2.4，fade-only）；`reward`→首通开箱（`chestsOpened` 去重）。
  - **GAP-5**：`content/dungeons.json` 重写为 `DungeonDef{id,name,floors[FloorDef{idx,rooms[RoomDef{id,type,encounterId,puzzleOrder,reward}]}]}`（4 层，F1–F3 三房、F4 四房含 boss）。
  - **GAP-6**：新增 `content/encounters.json`（`EncounterDef{id,enemyIds,isBoss,xpValue,drops}`），地牢房间 `encounterId` 引用之。
  - **GAP-7**：`content/enemies.json` 补 `xpValue` 字段 + 补齐 ~6 敌（Huskling/Frostmote/Stoneling/Storm-foe/+1 普通）+ Boss `Sigil-Twisted Warden`（xpValue~120）。
  - **战斗种子（GAP-11 闭合）**：`rng.seed(run_state.seed + floorIdx*100 + roomIdx*10 + (isBoss?1:0))`，确定性、可 replay。
- **验收（可测试）：**
  1. content-lint：4 层 Room 合法、BossRoom 仅末层、`encounterId` 均命中 `encounters.json`、敌人 `xpValue` 齐全（GAP-5/6/7）。
  2. 集成：进入 F0 CombatRoom → 经 E9.4 发起战斗 → 胜利 → `WorldDirector.clear_floor(0)` → `clearedFloors` 含 0 且安全节点落盘。
  3. 单测：`_move_cursor` 不能跳过未清房；Puzzle 错序→整组重置（无软锁，决策 2.4）。
  4. 集成（确定性）：同 `(seed, floorIdx, roomIdx, isBoss)` ⇒ 同 battle seed（GAP-11）。
- **涉及新增/修改文件：**
  - 新增 `scenes/dungeon/Dungeon.tscn`、`src/world/dungeon_controller.gd`
  - 修改 `content/dungeons.json`（GAP-5）、新增 `content/encounters.json`（GAP-6）、修改 `content/enemies.json`（GAP-7）
- **依赖：** E9.1（World/Dungeon 实例）、E9.4（CombatRoom→战斗）、E6（数据）、GDD `town-dungeon.md`。
- **Sprint：** 2 · **⛔ Blocker：** 否 · **Depends：** E9.1,E9.4。

### E9.4 · 遇敌触发 → CombatFSM 衔接（含 GAP-8/9/11；Attack+EnemyAI 真实循环）
- **目标：** 把「遇敌」接成**真实可跑的战斗循环**：`CombatController`（在 `Battle.tscn` 内每战实例化）驱动 `BattleFSM` 相位 + `BattleQueue` 回合序 + `BattleResolver` 纯函数 + `EnemyAI`；BattleState 由 `PartyManager.build_party_combatants()` + 编队敌人组装；胜利后 `ProgressionManager.apply_battle_xp` 平分配队并写回；种子确定性（GAP-11）。
- **User Story：** 作为玩家，我希望遇敌后进入确定性回合战斗、打赢拿 XP、失败回安全存档，这样战斗与进度连贯。
- **Ref：** town-dungeon §3.5/§8.2(b)(c)/§8.4(GAP-8/9/11)；main-arch §2.3/§3；ADR-002。
- **DoD（含 GAP 修复）：**
  - 新增 `src/battle/combat_controller.gd`（`Battle.tscn` 内每战实例化）：构建 `BattleState{combatants,queue,turnPointer,phase,log,isBoss}`；按 `BattleFSM` 相位推进；玩家回合取 UI `Action`，敌方回合取 `EnemyAI.choose_action`；逐 Action 调 `BattleResolver.resolve_action(state,action,rng)`；emit `EventBus.battle_event`；结束 emit `progression_event` 并回调 `_on_battle_resolved`。
  - 新增 `src/battle/battle_queue.gd`（解决 phase5 CONCERN #3 / B4）：SPD 降序、同速 slot 升序、跳过 HP≤0；单测覆盖。
  - 收口 `BattleResolver`：`Skill/Elemental/Defend/Item/Run` 路径（完成 E3-F/G；**切片 MVP 用 Attack+EnemyAI 跑通循环**，其余为深度扩展，保持纯函数 + 仅注入 RNGService，RNG lint 不破）。
  - **GAP-9**：`PartyManager.build_party_combatants()`（由 `all_members()`+`derive_stats()`+装备修正+当前 hp/mp 组装 4 名我方 Combatant）、`sync_to_run_state(run_state)`（level/xp/hp/mp 写回）。
  - **GAP-8**：`ProgressionManager.apply_battle_xp(total_xp, party)`（按 `xp_for_level=100*level` **代码为准**，GAP-10；平分配队 + 写回 `run_state.party`）。
  - `Dungeon.gd._start_battle` 组装 BattleState（我方 `build_party_combatants` + 敌方由 `EncounterDef.enemyIds`→`enemies.json`）、`rng.seed(...)` 确定性、`battle.setup(state,rng,self)`、`add_child` Battle 叠加层、`_on_battle_resolved(result)` 回写 XP/掉落/房间清/Stone 解锁/FloorClear。
- **验收（可测试）：**
  1. 集成（headless，复用 `test_combat_fsm_determinism.gd` 模式）：固定 `(seed, floorIdx, roomIdx, isBoss, action list)` ⇒ 完全相同 `log` + 胜负。
  2. 单测：`BattleQueue` 序 = SPD 降序、同速 slot 升序、死亡跳过（契约同 `test_combat_fsm_phases.gd`）。
  3. 单测（GAP-9）：`build_party_combatants()` 返回 4 名我方 Combatant，字段含 HP/maxHP/ATK/DEF/MAG/RES/SPD/affinity；`sync_to_run_state` 写回 level/xp 且派生值不重复存储。
  4. 单测（GAP-8）：`apply_battle_xp(120, party)` 按 `100*level` 曲线平分升级；不直接改存档 blob 的派生字段（E4-A）。
  5. 集成：敌人编队取自 `content/encounters.json`；`BattleResolver` 仍无全局 RNG（CI RNG lint 绿）；Boss 房 `Run` 禁用（combat §7）。
- **涉及新增/修改文件：**
  - 新增 `src/battle/combat_controller.gd`、`src/battle/battle_queue.gd`
  - 修改 `src/combat/battle_resolver.gd`（补全 5 指令路径）、`scenes/battle/Battle.tscn`（挂 CombatController + setup 入口）、`scenes/dungeon/Dungeon.tscn`/`.gd`（`_start_battle`/`_on_battle_resolved`）
  - 修改 `src/autoloads/party_manager.gd`（GAP-9）、`src/autoloads/progression_manager.gd`（GAP-8）
- **依赖：** E3（BattleFSM/BattleResolver/EnemyAI）、E9.1（Battle 叠加层）、E9.3（编队/敌人数据 + 房间触发）、E6、E8（数值锁定，可并行后置）。
- **Sprint：** 2 · **⛔ Blocker：** 是 · **Depends：** E3,E9.1,E9.3。

### E9.5 · 回城 + 安全节点存档落盘（复用 SaveManager，续档永落 Town）
- **目标：** 打通「地牢→回城」与「清层/Boss/失败→安全节点存档」落盘正确性；party wipe 回上次安全点（Town），只丢当前层。
- **User Story：** 作为玩家，我希望清层或回城后进度确实存下、且失败只丢当前层（无 save-scum），这样进度可信。
- **Ref：** town-dungeon §4.2/§5/§7/§8.2(d)/§8.4(决策 2.6)；save-load §2/§4/§7；ux-spec §2.2。
- **DoD：**
  - `WorldDirector.return_to_town()`：`_swap_world_child` 回 Town；回城即安全节点（`SceneManager.go_to("Town")` 已带 save，GAP-1/3 支撑）。
  - `_reload_last_safe_save()`：wipe → `SaveManager.load()` → `PartyManager.restore`/`WardCodex.restore` → `WorldDirector.enter_town()`（决策 2.6，续档永落 Town）。
  - 安全节点集合（ux-spec §2.2）：Town 进入 / FloorClear / Sigil-attune / Quest-complete / Shrine 手动；mid-combat 绝不写。
  - `RunState.worldState.dungeon` 字段已覆盖 `floorIdx/clearedFloors/foundSigils/chestsOpened/bossDefeated`（复用 E4 schema，无需改 schema）。
- **验收（可测试）：**
  1. 集成：`clear_floor(0)` 后 `SaveManager.load()` 还原 `clearedFloors=[0]`、`currentNode=town`；中途 Battle 退出 → reload 回到进战前安全点（无 mid-combat 残留）。
  2. 单测：回城不重置 `clearedFloors`（进度保留，world-nodes §7）；wipe 后 `currentNode=="town"` 且 `floorIdx` 保留（续层，GAP-4/决策 2.6）。
  3. 集成：Boss 胜利 → `WardCodex.attune("stone")` + `bossDefeated=true` + 安全节点落盘（sigil-attune 是安全节点）。
- **涉及新增/修改文件：**
  - 修改 `src/autoloads/world_director.gd`（`return_to_town`）
  - 新增 `tests/integration/test_return_to_town_safe_save.gd`（**脚手架**，quality-lead 填断言，R7）
- **依赖：** E9.1/E9.3（回城/清层路径）、E4（SaveManager）、E9.2（Shrine）、E9.4（boss attune）。
- **Sprint：** 2 · **⛔ Blocker：** 否 · **Depends：** E9.1,E9.3,E4,E9.4。

### E9.6 · 移动与输入（复用 ux-spec §3 逻辑动作 + SettingsManager/InputMap）
- **目标：** Town/Dungeon 移动与选择统一走 ux-spec §3 逻辑动作（`ui_up/down/left/right`、`ui_accept`、`ui_cancel`），接入 `SettingsManager.persistent controlRemap` + `InputMap`；触摸永远可用。
- **User Story：** 作为玩家，我希望 Town/Dungeon 里用键盘/触摸都能稳定导航与选择，且按键重映射生效，这样无障碍达标。
- **Ref：** town-dungeon §4.1/§4.2（输入映射）；ux-spec §3/§3.4；accessibility §4 #6/#3；E2-A（SettingsManager）。
- **DoD：**
  - 新增 `src/world/map_input.gd`（Town/Dungeon 共用输入路由）：焦点导航 `ui_*`、激活 `ui_accept`、返回/暂停 `ui_cancel`；节点/房间 `focus`+tap 双层触发；Dungeon 的 `ui_left/right`→房间光标、`ui_up/down`→房内交互（与 E9.2/E9.3 协同）。
  - 复用 `SettingsManager._apply_to_input_map()`（boot 已应用）；`controlRemap` 改立即生效。
  - `reducedMotion` 仅 fade；`textScale` 1.0–1.25 不裁切核心 HUD；所有交互元素 ≥44×44px。
- **验收（可测试）：**
  1. 集成：键盘 `ui_up/down/left/right` + `ui_accept` 可遍历并激活 Town 5 节点 / Dungeon 房间光标；触摸 tap 同效。
  2. 单测：改 `controlRemap` 后 `InputMap` 实际事件变更（复用 `test_settings_manager`）。
  3. 布局：360×640 下所有可交互元素 ≥44×44px（复用 `test_viewport_layout`）。
- **涉及新增/修改文件：** 新增 `src/world/map_input.gd`；修改 `Town.tscn`/`Dungeon.tscn`（接 `map_input`）。
- **依赖：** E9.2/E9.3（场景节点）、E2-A（SettingsManager/InputMap）、ux-spec §3。
- **Sprint：** 2 · **⛔ Blocker：** 否 · **Depends：** E9.2,E9.3,E2-A。

---

## 2. 跨切面硬约束（所有故事均须遵守）
- **引擎：** Godot 4.3 / gl_compatibility / WebGL2 / HTML5；单线程 Web（无线程，用协程）。
- **纯离线：** 无网络/账号；存档/设置走 localStorage；Analytics 默认关。
- **无障碍/IP：** 360×640 安全视口；交互元素 ≥44×44px；调色板 ≤48 色；`reducedMotion` 仅 fade 不闪；
  Ward-Sigil **形状+标签**（绝不只用颜色）；Underdog Stage 构图（非 FF1）；原创 IP 合规。
- **确定性：** 战斗仅用注入 `RNGService`（CI RNG lint 禁全局 RNG）；状态变更只在 `BattleResolver`/managers，EventBus 仅 UI 通知；
  战斗种子 = `run_state.seed + floorIdx*100 + roomIdx*10 + (isBoss?1:0)`（GAP-11）。
- **数据驱动：** 内容走 `content/`（ADR-003）；数值为占位/初值，E8 锁后写 content（不硬编码）。
- **续档策略（决策 2.6）：** `SaveManager.load()` 后 `currentNode` 恒 `"town"`；地牢进度由 `worldState.dungeon.floorIdx/clearedFloors` 保留，经 Sage 续层；Floor 进入**不是**安全节点。

## 3. 依赖图（Sprint 2 首冲刺关键路径）
```
E9.1 World骨架(⛔, GAP-1/2/3/4) ──┬─► E9.2 Town(节点图) ──┐
                                  │                         ├─► E9.5 回城+安全存档
                                  └─► E9.3 Dungeon(4层, GAP-2/5/6/7) ◄┤
                                         ▲        │          │
                                         │        └─ E9.4 CombatFSM衔接(⛔, GAP-8/9/11) ──┘
                                         │                ▲
E3 战斗结构 ─────────────────────────────┘                │
E6 content(地牢/敌人/编队, GAP-5/6/7) ─────────────────────┘
E8 数值锁定 ──(并行, 后置锁数值, 不阻塞管道)──┘
E9.6 移动输入 ── 接 E9.2/E9.3 场景 + E2-A
```
- **E9.1 与 E9.4 可并行起步**（二者都是管道；E9.4 战斗循环可 headless 先行验证）。
- **E9.2/E9.3/E9.5 串在 E9.1 之后**；E9.3 触发点依赖 E9.4；E9.6 最后接入并做无障碍打磨。

## 4. 退出标准（Sprint 2 首冲刺全须为真）
- [ ] **垂直切片跑通**（CI 集成/冒烟）：`Boot→Title→NewRun→Town→Sage 进地牢→CombatRoom 遇敌→Battle 胜→FloorClear→回城` 每节点可达。
- [ ] **E9.1** World 常驻 + 真实切换（GAP-1）；`get_run_state/get_world_state` 可用（GAP-3）；`enter_dungeon()` 无参续层（GAP-4）；Battle overlay 增/删无泄漏、mid-combat 不写盘。
- [ ] **E9.4** CombatController 驱动真实战斗循环（Attack+EnemyAI），确定性测试绿（GAP-11）；`PartyManager.build_party_combatants`/`sync_to_run_state`（GAP-9）、`ProgressionManager.apply_battle_xp`（GAP-8，按 `100*level`）落地。
- [ ] **E9.5** 安全节点存档：Town 进入 / FloorClear / Boss-attune / Shrine / quest 完成落盘；party wipe 回 Town 上次安全点、只丢当前层。
- [ ] **E9.3** 4 层节点步进（GAP-5 dungeons.json / GAP-6 encounters.json / GAP-7 enemies.json xpValue+~6 敌+Boss）；CombatRoom 固定触发；FloorClear 安全存档。
- [ ] **E9.2** Town 节点图 5 节点（Sage/Shrine/Inn 可交互，Market/Barracks 锁）。
- [ ] **E9.6** 输入走 ux-spec §3 + SettingsManager/InputMap；360×640 下交互元素 ≥44×44px。
- [ ] **CI 闸绿：** godot headless boot、GUT（战斗循环确定性 + 回城安全存档）、asset_audit、palette_validator(≤48)、content-lint(4 层 Room 合法 + encounter 命中 + xpValue)、RNG lint（战斗无全局 RNG）。
- [ ] **IP 闸：** Underdog Stage + Ward-Sigil 形状+标签；无 FF1/SE 表达（design-strategist + art-director 共签）。

## 5. GAP 映射与风险评估

### GAP → Story 映射（GDD §8.4，主理人已拍板 GAP-10）
| GAP | 内容 | 归属 Story | 处理 |
|-----|------|-----------|------|
| GAP-1 | `go_to` 只更逻辑态，需真实切场景 | **E9.1** | `WorldDirector._swap_world_child` 实例 Town/Dungeon 为 World 子节点 |
| GAP-2 | 逐房间状态无持久字段 | **E9.1/E9.3** | 作为 Dungeon session 态（不进存档），避免脏续档跳房 |
| GAP-3 | `worldState` 私有无访问器 | **E9.1** | `SceneManager.get_run_state()`/`get_world_state()`（只读） |
| GAP-4 | `enter_dungeon` 永远第 0 层 | **E9.1** | 无参续到 `worldState.dungeon.floorIdx`（修 bug） |
| GAP-5 | `dungeons.json` 仅 stub | **E9.3** | 扩写 4 层 × `RoomDef` |
| GAP-6 | 无 `EncounterDef` | **E9.3** | 新增 `content/encounters.json` |
| GAP-7 | `enemies.json` 缺 xpValue + 仅 2 敌 | **E9.3** | 补 xpValue + ~6 敌 + Boss |
| GAP-8 | 无配队-wide XP + 写回 | **E9.4** | `ProgressionManager.apply_battle_xp(total_xp, party)` |
| GAP-9 | 无 `build_party_combatants`/`sync_to_run_state` | **E9.4** | `PartyManager` 加两方法 |
| GAP-10 | XP 曲线冲突（doc 20*l^1.35 vs 代码 100*level） | **决策已下** | **以代码 `100*level` 为准**；`progression.md` 留 balance spike 由 design 侧同步修订 |
| GAP-11 | 战斗种子逐次尝试差异 | **E9.3/E9.4** | 当前 `seed+floorIdx*100+roomIdx*10+(isBoss?1:0)` 已确定；逐尝试差异留未来（持久 attempt 计数） |
| O-1 | `foundSigils` 与 `codex.attunedSigilIds` 冗余 | 设计侧 | 建议 WardCodex 为唯一功能真源（实现沿用现有字段，不新增） |
| O-2 | 地牢内续档 | 不采纳（MVP） | 续档永落 Town（决策 2.6） |
| O-3 | 满进度 Sage 入口 | E9.2 | 禁用/通关回顾（GDD 已定） |

### 残留风险（research）
- **R1**（原）：`BattleResolver` 仅 Attack；Skill/Elemental/Defend/Item/Run 需收口（E3-F/G）。切片 MVP 用 Attack+EnemyAI 跑通；其余为 E9.4 深度子项，**不阻塞垂直切片**。
- **R4**：PuzzleRoom 完整演出 / BossRoom 过场超出首冲刺 MVP；切片 MVP = Floor1 仅 CombatRoom，Puzzle/Boss 为 E9.3 深度子项（GDD 决策 2.2/2.4 已给定交互契约，实现无障碍）。
- **R7**：测试用例归 quality-lead；本 Epic 只搭测试脚手架（文件/夹具），不填断言。
- **R8**（已收敛）：WorldDirector 仍是无状态透传 + 持有 worldState 的争议——GDD 选「SceneManager 持 `_run_state` 并加只读访问器（GAP-3），WorldDirector 经访问器读写并负责场景交换」。**采纳此方案**，无需双源重构。
- **数值**：所有地牢/敌人/编队数值为初值/占位，E8 锁后写 content（零代码改动）；`derive_stats` 占位公式待 E8 替换为真实成长曲线。
