# EMBERVEIL — Sprint 2 Plan（Town/Dungeon 地图可玩核心）

> Epic 来源：`production/epics/epic-09-feature-ui-town-dungeon.md`
> 设计契约：`design/gdd/town-dungeon.md`（已就绪，Route A）· `design/gdd/world-nodes.md` · `design/ux/ux-spec.md` · `docs/architecture/main-architecture.md`
> Owner：engineering-lead（程基岩 / chengji）· 引擎：Godot 4.3（gl_compatibility / WebGL2 / HTML5）· 审核：FULL
> 本次 S2-IMPL-01 为**规划+拆分+风险评估**（含 GDD §8 的 GAP-1~10 落位）；**实现代码等主理人二次派单**。

---

## 1. Sprint 目标

在 Sprint 1「可 boot、CI 绿、后台逻辑 + 纯函数战斗 + 安全存档」地基之上，做出 **Town/Dungeon 地图可玩核心**——
一条完整可玩回路 `Boot → Title → New Run → Town → Sage 进地牢 → CombatRoom 遇敌 → Battle → FloorClear → 回城`，
让主理人能做「垂直切片可玩走查」确认核心循环「好玩」。

> 路线确认（主理人）：**用 Godot 4 真做 Town/Dungeon 地图（路线 A）**。

---

## 2. 范围内（Sprint 2 首冲刺）

| 区域 | Epic / Story | GAP 落位 | 为什么 |
|------|--------------|----------|--------|
| World 骨架 | **E9.1**（⛔） | GAP-1/2/3/4 | World 常驻 + 真实场景切换 + 访问器 + 无参续层 |
| Town | **E9.2** | — | Hearthmoor 节点图 5 节点：Sage（进地牢）+ Shrine（存档）+ Inn（满血）；Market/Barracks 锁 |
| Dungeon | **E9.3** | GAP-2/5/6/7/11 | 4 层节点步进 + CombatRoom 遇敌 + FloorClear；内容扩写 |
| 战斗衔接 | **E9.4**（⛔） | GAP-8/9/11 | CombatController 驱动真实循环 + Party 组装/回写 + XP 平分配队 |
| 回城/存档 | **E9.5** | 决策 2.6 | 回城 + 安全节点落盘正确性（续档永落 Town） |
| 移动/输入 | **E9.6** | — | ux-spec §3 逻辑动作 + SettingsManager/InputMap；44px/reduced-motion/焦点 |
| 数值锁定 | **E8**（并行后置） | — | 锁定真实战斗/敌人/编队数值，经 `content/` 落地（不阻塞管道） |
| 内容数据 | **E6**（扩展） | GAP-5/6/7 | 重写 dungeons/新增 encounters/扩展 enemies；New Run 默认组队（GAP-9） |
| 测试脚手架 | **E7**（扩展） | — | 垂直切片冒烟 + 战斗循环确定性 + 回城安全存档夹具（quality-lead 填断言） |

---

## 3. 范围外（推后 / 其他 Epic）

- Town 完整经济 UI：Market 买卖、Barracks 组队、Ward Codex 施法 dock（E2-I / E2-K / E2-J，Later）。
- Dungeon 深度：PuzzleRoom 完整解谜演出、RewardRoom 开箱、BossRoom 完整过场（E9.3 深度子项，非首冲刺 MVP）。
- 5 指令全手感打磨（Skill/Elemental/Defend/Item/Run 完整平衡与表现，E3-F/G 收口 + E8 锁数值）。
- 多城镇 / Overworld / Driftwing（L3+）。
- 任何网络/云/账号/登录（纯离线铁律，L4+ 才考虑，且须新 Epic）。

---

## 4. 交付增量与顺序（建议）

1. **管道地基（Day 1–3）：** E9.1（World 常驻 + `_swap_world_child` 真实切换 + `get_run_state/get_world_state` + `enter_dungeon` 无参续层 GAP-1/3/4）+ 并行起 E9.4 的 `BattleQueue`/`CombatController` 头（headless 可验）。
2. **战斗回路（Day 2–5）：** E9.4（GAP-8/9/11：CombatController 驱动真实战斗 + `build_party_combatants`/`sync_to_run_state` + `apply_battle_xp` + 确定性种子；收口 BattleResolver 5 指令）+ 集成测试绿。
3. **Town（Day 3–6）：** E9.2（Hearthmoor 节点图 5 节点 + Sage/Shrine/Inn 可交互）+ E9.6 接入 Town 输入。
4. **Dungeon（Day 5–8）：** E9.3（GAP-5/6/7 内容扩写 + 4 层节点步进 + CombatRoom 触发 E9.4 + FloorClear）+ content 重写。
5. **回城/存档（Day 6–8）：** E9.5（回城 + 安全节点落盘正确性 + party wipe 续档永落 Town）+ 安全存档夹具。
6. **打磨/无障碍（Day 7–10）：** E9.6 全场景输入 + 44px/reduced-motion/palette 闸；E8 数值经 content 落地。
7. **走查（Day 9–10）：** 垂直切片冒烟扩展为全回路；主理人「可玩走查」。

---

## 5. 与 E8 数值锁（epic-08-balance-spike）的关系

**结论：E8 与 Sprint 2 首冲刺「并行、后置锁数值」，不阻塞管道。**

- Sprint 1 战斗*结构*已落地；数值为占位/数据驱动（ADR-003）。GDD §6 给出初值（affinity 1.5/0.67/1.0、variance ±10%、普通敌 xpValue 8–25、Boss ~120、level cap 20）。
- Sprint 2 首冲刺用占位数值即可跑通回路；E8 在走查前把锁定数值写入 `content/`（零代码改动）。
- E9.3 内容（dungeons/encounters/enemies）先建「结构 + 占位数值」，E8 再覆写，避免两边各写一份。
- `PartyManager.derive_stats` 占位公式（Sprint1）待 E8 替换为真实成长曲线；`ProgressionManager.xp_for_level=100*level` 已锁定（见 GAP-10）。

---

## 6. 实现风险评估（关键缺口 + GAP 落位，research）

> 实测读取 `scene_manager.gd`/`world_director.gd`/`save_manager.gd`/`party_manager.gd`/`progression_manager.gd`/
> `battle_fsm.gd`/`enemy_ai.gd`/`battle_resolver.gd`/`rng_service.gd`、`Battle.tscn`、`content/*.json`、`project.godot`，
> 并对照 `design/gdd/town-dungeon.md` §8 GAP 表。

### 6.1 已确认缺口 → 已分配 GAP（本冲刺修）
| # | 缺口（实测） | GAP | 归属 Story | 修复动作 |
|---|--------------|-----|-----------|----------|
| 1 | SceneManager 仅更 `_current_node` 字符串，无真实切换；World.tscn 空占位 | **GAP-1** | E9.1 | `WorldDirector._swap_world_child` 实例 Town/Dungeon 为 World 子节点 |
| 2 | 逐房间态无持久字段（房间光标/已清房） | **GAP-2** | E9.1/E9.3 | 作 Dungeon session 态（不进存档），防脏续档跳房 |
| 3 | `_run_state` 私有，场景脚本无访问器 | **GAP-3** | E9.1 | `SceneManager.get_run_state()`/`get_world_state()` 只读 |
| 4 | `enter_dungeon(floor_idx=0)` 永远第 0 层 | **GAP-4** | E9.1 | 无参续到 `worldState.dungeon.floorIdx`（修 bug） |
| 5 | `dungeons.json` 仅 stub（无 rooms） | **GAP-5** | E9.3 | 扩写 4 层 × `RoomDef` |
| 6 | 无 `EncounterDef` / `content/encounters.json` | **GAP-6** | E9.3 | 新增 `EncounterDef{id,enemyIds,isBoss,xpValue,drops}` |
| 7 | `enemies.json` 缺 `xpValue` 且仅 2 敌 | **GAP-7** | E9.3 | 补 xpValue + ~6 敌 + Boss `Sigil-Twisted Warden` |
| 8 | `ProgressionManager` 无配队-wide XP + 写回 | **GAP-8** | E9.4 | `apply_battle_xp(total_xp, party)` |
| 9 | `PartyManager` 无 `build_party_combatants`/`sync_to_run_state` | **GAP-9** | E9.4 | 新增两方法 |
| 10 | XP 曲线冲突（doc 20*l^1.35 vs 代码 100*level） | **GAP-10** | 已拍板 | **以代码 `100*level` 为准**；`progression.md` 留 balance spike 由 design 侧修订 |
| 11 | 战斗种子逐次尝试差异 | **GAP-11** | E9.3/E9.4 | `seed+floorIdx*100+roomIdx*10+(isBoss?1:0)` 已确定 |
| 12 | BattleFSM 仅结构；`CombatController`/`BattleQueue` 不存在；`Battle.tscn` 空占位 | — | E9.4 | 新建 `combat_controller.gd`+`battle_queue.gd` 并接入 Battle.tscn |
| 13 | `BattleResolver` 仅 Attack；`RNGService` API 命名漂移（`draw_*` 非 `next_*`） | — | E9.4 | 补全 5 指令（保持纯函数）；集成用 `draw_range`/`draw_int` |
| 14 | `RunState.party` 默认 `[]`（New Run 需默认组队，否则战斗无 combatants） | GAP-9 衍生 | E9.4/E6 | New Run 经 `PartyManager` 默认组 4 职业（GDD 决策：固定 4 职业，由 `build_party_combatants` 在战斗时组装） |

### 6.2 已闭合的设计歧义（原风险评估项，GDD 已定）
- **原 R2 战斗种子/nonce**：闭合——GDD §3.5 给出 `rng.seed(run_state.seed + floorIdx*100 + roomIdx*10 + (isBoss?1:0))`。
- **原 R3 地图模型**：闭合——Town=节点图（决策 2.1）、Dungeon=节点步进（决策 2.2）、地牢内无随机遭遇（决策 2.3）。
- **原 R6 content 缺口**：现为显式 GAP-5/6/7，字段契约已定。
- **原 R7 EventBus 信号名**：闭合——`battle_event`（phase5 改名）。
- **原 R8 WorldDirector 所有权争议**：闭合——GDD §8.2(a) 选「SceneManager 持 `_run_state` + 加只读访问器（GAP-3），WorldDirector 经访问器读写并负责场景交换」；无需双源重构。

### 6.3 残留风险
- **R1**：`BattleResolver` 仅 Attack，Skill/Elemental/Defend/Item/Run 需收口（E3-F/G）；切片 MVP 用 Attack+EnemyAI 跑通，**不阻塞垂直切片**。
- **R4**：PuzzleRoom/BossRoom 完整演出超首冲刺 MVP；切片 MVP = Floor1 仅 CombatRoom，其余为 E9.3 深度子项（GDD 已给交互契约）。
- **R7**：测试用例归 quality-lead；本 Epic 只搭测试脚手架（文件/夹具），不填断言。
- **数值**：地牢/敌人/编队数值为初值/占位，E8 锁后写 content（零代码改动）；`derive_stats` 占位公式待 E8 替换。

---

## 7. 新增 / 修改文件清单（实现派单时据此建文件）

**新增文件**
- `scenes/town/Town.tscn` + `src/world/town_controller.gd`（E9.2）
- `scenes/dungeon/Dungeon.tscn` + `src/world/dungeon_controller.gd`（E9.3）
- `src/battle/combat_controller.gd`（E9.4，Battle.tscn 内每战实例化）
- `src/battle/battle_queue.gd`（E9.4，共享回合队列，解 B4）
- `content/encounters.json`（E9.3，GAP-6）
- `src/world/map_input.gd`（E9.6，Town/Dungeon 共用输入路由）
- `tests/integration/test_return_to_town_safe_save.gd`（E9.5 脚手架，quality-lead 填断言）

**修改文件**
- `scenes/world/World.tscn`（E9.1：建常驻根 + 挂载点）
- `src/autoloads/scene_manager.gd`（E9.1：GAP-3 `get_run_state`/`get_world_state`）
- `src/autoloads/world_director.gd`（E9.1：GAP-1 `_swap_world_child`、GAP-4 无参续层；E9.5：`return_to_town`）
- `src/autoloads/party_manager.gd`（E9.4：GAP-9 `build_party_combatants`/`sync_to_run_state`）
- `src/autoloads/progression_manager.gd`（E9.4：GAP-8 `apply_battle_xp`）
- `src/combat/battle_resolver.gd`（E9.4：补全 5 指令路径，保持纯函数）
- `scenes/battle/Battle.tscn`（E9.4：挂 CombatController + `setup(state,rng,cb)` 入口）
- `content/dungeons.json`（E9.3：GAP-5 扩写 4 层 RoomDef）
- `content/enemies.json`（E9.3：GAP-7 补 xpValue + ~6 敌 + Boss）
- `scenes/town/Town.tscn`/`scenes/dungeon/Dungeon.tscn`（E9.6：接 `map_input`）
- `content/items.json`/`equipment.json`（E9.3：按需补，已 stub）

**设计侧（非本 Epic 代码）**
- `design/gdd/progression.md` §2：将 `20*l^1.35` 同步修订为与代码 `100*level` 一致（GAP-10，balance spike 时由 design-strategist 处理）。

---

## 8. 退出标准（全须为真）

- [ ] **垂直切片跑通**（CI 集成/冒烟）：`Boot→Title→NewRun→Town→Sage 进地牢→CombatRoom 遇敌→Battle 胜→FloorClear→回城` 每节点可达。
- [ ] **E9.1** World 常驻 + 真实切换（GAP-1）；`get_run_state/get_world_state` 可用（GAP-3）；`enter_dungeon()` 无参续层（GAP-4）；Battle overlay 增/删无泄漏、mid-combat 不写盘。
- [ ] **E9.4** CombatController 驱动真实战斗循环（Attack+EnemyAI），确定性测试绿（GAP-11）；`PartyManager.build_party_combatants`/`sync_to_run_state`（GAP-9）、`ProgressionManager.apply_battle_xp`（GAP-8，按 `100*level`）落地。
- [ ] **E9.5** 安全节点存档：Town 进入 / FloorClear / Boss-attune / Shrine / quest 完成落盘；party wipe 回 Town 上次安全点、只丢当前层（决策 2.6）。
- [ ] **E9.2/E9.3** Town 节点图 5 节点（Sage/Shrine/Inn 可交互、Market/Barracks 锁）+ Dungeon 4 层节点步进（GAP-5 dungeons / GAP-6 encounters / GAP-7 enemies）+ FloorClear。
- [ ] **E9.6** 输入走 ux-spec §3 + SettingsManager/InputMap；360×640 下交互元素 ≥44×44px。
- [ ] **CI 闸绿：** godot headless boot、GUT（战斗循环确定性 + 回城安全存档）、asset_audit、palette_validator(≤48)、content-lint(4 层 Room 合法 + encounter 命中 + xpValue)、RNG lint（战斗无全局 RNG）。
- [ ] **E8 数值经 content 落地**（Sprint 2 后期）、**IP 闸**：Underdog Stage + Ward-Sigil 形状+标签，无 FF1/SE 表达（design-strategist + art-director 共签）。

---

## 9. Traceability
| 本计划 | 上游 |
|--------|------|
| Sprint 2 目标 | phase5-sprint1-gate §5（垂直切片可玩走查）、主理人路线 A |
| E9.* Story + GAP 落位 | epic-09、town-dungeon.md §8（GAP-1~11）、main-arch §2.2/§2.3/§3、ux-spec §2/§3、world-nodes §2/§3/§4/§6/§7 |
| E8 关系 | epic-08、phase5 CONCERN #2 |
| 风险评估 | 实测 scene_manager/world_director/save_manager/party_manager/progression_manager/battle_fsm/enemy_ai/battle_resolver/rng_service/content/* + town-dungeon.md §8 |

*End of Sprint 2 Plan. Downstream: engineering-lead（实现，待二次派单）、design-strategist（GAP-10 doc 同步）、quality-lead（测试断言）。原创 IP 合规。*
