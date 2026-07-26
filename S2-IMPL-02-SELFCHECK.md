# S2-IMPL-02 自验报告 — EMBERVEIL Sprint 2 Town/Dungeon 可玩核心

> 角色：engineering-lead（程基岩）。环境无 Godot，仅用 Python 静态自检 + 读源码。
> 结论：**静态自检 OVERALL: PASS**（19/19 符号检查、括号平衡 OK、内容交叉引用 OK）。
> **未 git commit**（归主理人）。

## 1. 文件清单

### 新增（New）
| 文件 | 说明 |
|---|---|
| `scenes/town/Town.tscn` | Town 节点图场景（5 节点按钮 + MapInput） |
| `src/world/town_controller.gd` | E9.2 Hearthmoor 控制器（Rest/Sage/Shrine 可交互，Shop/Barracks 锁，决策 2.8） |
| `scenes/dungeon/Dungeon.tscn` | Dungeon 4 层场景（Info + Rooms 容器 + MapInput） |
| `src/world/dungeon_controller.gd` | E9.3/E9.4/E9.5 控制器（房间轨道、光标、战斗衔接、回城、安全存档、谜题） |
| `src/battle/combat_controller.gd` | E9.4 每战实例化的战斗循环驱动（纯函数 BattleResolver + EnemyAI） |
| `src/battle/battle_queue.gd` | E9.4 共享回合队列（SPD 降序、slot 升序、死亡跳过） |
| `content/encounters.json` | **GAP-6**：5 个 EncounterDef（sw_f0..f3_combat + sw_f3_boss） |
| `src/world/map_input.gd` | E9.6 共享输入路由（ux-spec §3 逻辑动作） |
| `tests/integration/test_return_to_town_safe_save.gd` | E9.5 脚手架（quality-lead 填断言，R7） |
| `tools/s2_selfcheck.py` | 本次静态自检脚本（可复跑） |

### 修改（Modified）
| 文件 | 改动 |
|---|---|
| `scenes/world/World.tscn` | 建成常驻根 + `WorldMount` 挂载点（GAP-1 支撑） |
| `scenes/battle/Battle.tscn` | 挂 `combat_controller.gd` 为根脚本 + `setup()` 入口（E9.4） |

### 已确认在仓库现状中**无需修改**即已闭合（原任务列为“修改”但实测已满足）
- `src/autoloads/scene_manager.gd`：已有 `get_run_state()` / `get_world_state()`（**GAP-3**）。
- `src/autoloads/world_director.gd`：已有 `_swap_world_child()`（**GAP-1**）、`enter_dungeon()` 无参续层（**GAP-4**）、`return_to_town()`（**E9.5**）。
- `src/autoloads/party_manager.gd`：已有 `build_party_combatants()` / `sync_to_run_state()`（**GAP-9**）、New Run 默认 4 职业（**GAP-12**）。
- `src/autoloads/progression_manager.gd`：已有 `apply_battle_xp()` 按 `100*level`（**GAP-8 / GAP-10**）。
- `src/combat/battle_resolver.gd`：已有 Attack/Skill/Elemental/Defend/Item/Run 五指令纯函数（**R1 切片 MVP**）。
- `content/dungeons.json`：已是 4 层 × RoomDef（**GAP-5**）；`content/enemies.json`：已 6 敌 + Boss 带 `xpValue`（**GAP-7**）。
> 这些文件 GAP 已在仓库当前态闭合；为避免回归，本次**未改动**它们。

## 2. 硬契约落实对照
1. World 常驻 + `_swap_world_child` 增删 Town/Dungeon 子节点，RunState 不重载（GAP-1）。✓
2. `SceneManager.get_run_state()/get_world_state()` 只读访问器（GAP-3）。✓（现状）
3. `enter_dungeon()` 无参续到 `worldState.dungeon.floorIdx`（GAP-4）。✓（现状）
4. Dungeon 4 层固定 CombatRoom/BossRoom，无随机遭遇；光标不跳未清房（GAP-2）；Puzzle 错序整组重置（决策 2.4）；Boss 掉 Stone Sigil。✓（dungeon_controller）
5. `Battle.tscn` 叠加层 `get_tree().get_root().add_child()`，绝不 mid-battle 写盘；CombatController 每战实例化。✓（combat_controller queue_free + 不调 SaveManager）
6. 战斗确定性纯函数 `resolve_action(state,action,rng)`；种子 `seed + floorIdx*100 + roomIdx*10 + (isBoss?1:0)`（GAP-11/ADR-002）。✓（`_battle_seed` 字面公式已静态校验通过）
7. `ProgressionManager.apply_battle_xp(total_xp, party)` 按 `100*level`（GAP-8/10）。✓（现状）
8. `build_party_combatants()/sync_to_run_state()` 返回 4 名我方（GAP-9）；New Run 默认 4 职业（GAP-12）。✓（现状）
9. Town S2 仅 {Rest,Sage,Shrine} 可交互，Shop/Barracks 锁（决策 2.8）。✓
10. 续档永落 Town（决策 2.6）；安全节点={Town进入,FloorClear,Sigil-attune,Shrine}。✓
11. 视口/44px/调色板/reduced-motion/Ward-Sigil 形状+标签：按钮 ≥44px（Town 180×48、Dungeon 220×44）；Ward-Sigil 用 `sigilShape` 令牌 + 文本标签（形状+标签，非仅颜色）；reduced-motion 默认 fade（当前 UI 无闪烁动画）。调色板≤48 与 360×640 由 CI（palette_validator/asset_audit）闸，未在主控逻辑内强制。
12. 数值占位（E8 后置覆写），结构先建（ADR-003 数据驱动）。✓

## 3. 自检结果（tools/s2_selfcheck.py）
- 符号/契约检查：**19/19 PASS**（含两个 autoload GAP 回归守卫）。
- 种子公式字面串：`floor_idx * 100` / `room_idx * 10` / `(1 if is_boss else 0)` 均在 `dungeon_controller.gd` 出现。✓
- 括号平衡（.gd，跳过字符串/注释）：OK。
- 内容交叉引用：dungeons.json 的 encounterId 全部命中 encounters.json；encounters 的 enemyIds 全部命中 enemies.json；所有敌人含 `xpValue`；Boss 房含 `sigilId`；存在 `sigil_twisted_warden`。✓

## 4. 不确定项 / 待主理人/质量负责人确认
1. **无运行时验证**：环境无 Godot，无法跑 GUT/headless boot。场景实例化、焦点导航、战斗循环时序仅经静态分析，未经运行。建议 CI 接入 `godot --headless -s addons/gut/gut_cmdln.gd` 实跑。
2. **Ward-Sigil 形状为占位**：当前以 `sigilShape` 令牌 + 文本标签满足“形状+标签（非仅颜色）”契约；真实 Ward-Sigil 矢量艺术为原创 IP 美术交付物，本冲刺未产出（非代码资产）。
3. **战斗同步解析**：`CombatController.setup()` 内同步跑完整战斗循环（满足“绝不 mid-battle 序列化”且确定性）。真实 UI 接入时建议改为按 tick/信号驱动，但当前 MVP 与 headless 验证一致。
4. **worldState.questAccepted 加法字段**：为落地决策 2.8 的 Sage 门控，向 `worldState` 增 `questAccepted`（additive，SaveManager.migrate 向前填充，不破坏锁定序列化）。属对锁定 schema 的微小扩展，需 design 侧知会。
5. **集成测试为脚手架**（R7）：断言已接但本次未运行；quality-lead 据 §8 验收项填实。
6. **E8 数值占位**：dungeons/enemies/encounters 数值为占位，balance spike 会经 content 覆写（零代码改动，ADR-003）。

## 5. 关键实现决策
- **XP 回写顺序修正**：`_on_battle_resolved` 采用 `record_ally_outcome` → `sync_to_run_state` → `apply_battle_xp`（apply_battle_xp 为最终写入者，确保遭遇 XP 不丢），规避了“sync 覆盖 apply 结果”的潜在顺序 bug。
- **房间光标不跳未清房**（GAP-2）：`_move_cursor` 以 `_frontier()`（首个未清房索引）为上限；离开/错序谜题均重置 session 态，不进存档。
- **Boss 禁用 Run**：由 `BattleResolver` 在 `isBoss` 时 no-op（combat §7）。
- **谜题焦点跟随**：正确点石后焦点环自动移到下一期望石，提示与焦点一致；错误元素仍整组重置（决策 2.4）。
