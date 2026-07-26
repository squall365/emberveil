# EMBERVEIL — Sprint 2 Smoke Test Spec（烟雾测试规格 · 垂直切片）

> **Owner:** quality-lead（严守真 / Yan Soujin） · **Date:** 2026-07-26
> **对齐：** `production/epics/epic-09-feature-ui-town-dungeon.md` §0 范围、`design/gdd/town-dungeon.md` §3.5（战斗种子硬契约）、§8.5（七接口点）
> **实现对标：** `tests/smoke/test_vertical_slice.gd`（新增，本规格逐条钉死其断言）
> **运行：** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`（CI M 道闸）
> **判定：** 任一步骤断言失败 ⇒ 整体 **FAIL**（建议性门控，最终放行由主理人定）；全步 PASS ⇒ **PASS**。

---

## 0. 范围与前置

**范围**：纯离线、单机的「Town/Dungeon 可玩核心」垂直切片完整回路，覆盖 checklist **G(冒烟) ⛔** 与 E9 全部 6 故事的启动健康/可达性面：
`Boot → Title → New Run → Town(Hearthmoor) → Sage 进地牢 → CombatRoom 遇敌 → Battle 胜 → FloorClear → 回城 → 安全存档`。
**不覆盖**（本冲刺不验）：PuzzleRoom/BossRoom 完整演出打磨（推后，决策 2.4 交互契约可达即可）、5 指令全手感平衡（MVP 用 Attack+EnemyAI，E9.4 DoD）、Market/Barracks/Codex 完整经济 UI（锁）、数值平衡（占位，E8 锁）。

### 0.1 前置（harness 准备）
- `localStorage` 清空（调用 `SaveManager.clear_for_test()`，确保无残留存档/设置）。
- 项目以 `gl_compatibility`（WebGL2）headless 启动；无网络可达。
- 断言框架：GUT（`extends GutTest`）。
- 默认 `RunState.seed` 已赋值（GAP-12：New Run 用 4 默认职业种子化 `party`，`party` 绝不为 `[]`）。

### 0.2 通用辅助断言（每步复用）
- `assert_offline()` — 见 §12，纯离线铁律。
- `assert_ip_clean()` — 见 §12，IP 护栏自动部分。
- `assert_save_key(key)` — 断言 `localStorage` 含指定键且为合法 JSON（`emberveil.save.v1` / `emberveil.settings.v1`）。
- `assert_no_battle_state_in_save()` — reload 后 `RunState` 无 `battleState` 键（架构 §2.2 / D4）。

### 0.3 退出映射
| Sprint 2 退出标准项 | 本规格覆盖 |
|----|----|
| 垂直切片跑通（CI M 道闸） | 全流程 §1–§10 |
| E9.1 World 常驻 + 真实切换（GAP-1/3/4） | §5（`enter_dungeon` 无参续层）、§9（回城） |
| E9.2 Town 节点图 5 节点 | §4（Sage/Shrine/Inn 可交互、Market/Barracks 锁） |
| E9.3 Dungeon 4 层节点步进 + CombatRoom 触发 | §5/§6 |
| E9.4 CombatController 驱动真实循环 + 确定性（GAP-11） | §6/§7/§11 |
| E9.5 安全节点存档 + 续档永落 Town（决策 2.6） | §8/§9/§10 |
| E9.6 输入 ≥44px / reduced-motion | §4/§12 IP |
| IP 闸过 | §12（自动令牌）+ 人工评审（见 QA Plan §6/OQ6） |

---

## 1. Boot（启动）
- **前置状态**：`localStorage` 清空；进程冷启动。
- **触发动作**：`godot --headless` 加载 `Boot.tscn`；autoloads 按 `main-arch §2.1` 顺序初始化。
- **期望断言**：
  1. `SceneManager.current_node()` ∈ `["Boot", "Title"]`。
  2. `SettingsManager` / `SaveManager` autoload 非 null。
  3. 启动为只读，未触发任何写盘。
- **离线断言**：`assert_offline()` 通过。
- **失败即判**：任一断言失败 ⇒ FAIL（A1/C 启动健康）。

## 2. Title Reached（到达标题）
- **前置状态**：§1 完成。
- **触发动作**：等待 Boot ready；`SceneManager.go_to("Title")`。
- **期望断言**：
  1. `SceneManager.current_node() == "Title"`。
  2. 无存档时 `Continue` 控件灰显/隐藏（D5）。
  3. 场景树无 `login`/`account`/`cloud`/`signin` 节点或文案（纯离线）。
- **离线断言**：`assert_offline()` 通过。
- **失败即判**：`current_node != "Title"` ⇒ FAIL；`Continue` 误显 ⇒ A。

## 3. New Run Confirm（新建存档确认 + 默认 4 人组队，GAP-12）
- **前置状态**：`Title`，无存档。
- **触发动作**：点 `New Run` → 确认对话框 → `SceneManager.new_run_confirmed()`。
- **期望断言**：
  1. 未确认前 `new_run()` 被拒（单槽不被静默覆盖，D5）。
  2. 确认后生成全新 `RunState`：`schemaVersion == CURRENT`、`seed` 已赋值、`worldState.currentNode == "town"`。
  3. **GAP-12**：`RunState.party` 含 **4 名默认职业**（Vanguard / Channeler / Skirmisher / Warden 各一），**绝不为 `[]`**（否则进地牢无 combatants，垂直切片卡死，决策 2.7）。
  4. 全程无登录/账号/云 UI（纯离线）。
- **离线断言**：`assert_offline()`；无 `Auth`/`Session`/`Token` 概念。
- **失败即判**：未确认即覆盖 ⇒ S（数据丢失）；出现账号 UI ⇒ S（违反纯离线）；`party==[]` ⇒ **S**（垂直切片卡死，决策 2.7 破裂）。

## 4. Town（Hearthmoor 节点图，E9.2）
- **前置状态**：§3 已 `new_run_confirmed()`，抵达 `Town`。
- **触发动作**：`SceneManager.go_to("Town")`；渲染 5 节点 `Control`。
- **期望断言**：
  1. `SceneManager.current_node() == "Town"`。
  2. **进入 Town 触发安全节点存档**：`SaveManager.was_written_at_safe_node() == true`；`emberveil.save.v1` 合法 JSON。
  3. **5 节点布局**（360×640）：`Rest`/`Shop`/`Barracks`/`Sage`/`Shrine` 均可见且 ≥44×44px（`test_viewport_layout` 契约）。
  4. **可交互**（E9.2 / 决策 2.8）：`Rest`(Inn 满血)、`Sage`(任务面板)、`Shrine`(手动安全存档) 可激活。
  5. **锁定**（E9.2 / 决策 2.8）：`Shop`(Market)、`Barracks` 灰显 + tap 弹 toast「即将开放」，**面板不可打开**。
  6. 存档中无 `battleState` 键（D4）。
- **离线断言**：`assert_offline()`；存档仅落 `localStorage`。
- **失败即判**：`current_node != "Town"` ⇒ FAIL；进 Town 未存档 ⇒ A（D4）；锁节点误激活 ⇒ A；节点 <44px ⇒ B（44px 铁律）；`party==[]` ⇒ S。

## 5. Sage 进入地牢（E9.1 续层 + E9.2 门控 + GAP-4/12）
- **前置状态**：§4 已抵 Town 且已安全存档；`questAccepted && !bossDefeated`。
- **触发动作**：Sage 面板「进入地牢」按钮（仅门控条件满足时可用）→ `WorldDirector.enter_dungeon()`（无参）。
- **期望断言**：
  1. **门控**：`questAccepted && !bossDefeated` 为真时按钮可用；否则禁用（E9.2 验收 #2）。
  2. `SceneManager.current_node() == "Dungeon"`。
  3. **GAP-4 续层**：`enter_dungeon()` 无参续到 `worldState.dungeon.floorIdx`（首跑为 0，非恒 0 bug）；`World` 树下仅 1 个 Dungeon 实例（`_swap_world_child`，GAP-1）。
  4. 进入 Dungeon **不应**立即写盘（Floor 进入非安全节点，决策 2.6）；`worldState.currentNode` 仍为 `town`（进入地牢不改 currentNode 持久态，仅在 World 子场景切换）。
- **离线断言**：`assert_offline()`。
- **失败即判**：门控失效（未接任务即可进地牢）⇒ A；`current_node != "Dungeon"` ⇒ FAIL；`floorIdx` 恒 0（GAP-4 复现）⇒ A；World 下多实例 ⇒ A（GAP-1）。

## 6. CombatRoom 遇敌 → Battle 启动（E9.3 + E9.4 + GAP-11）
- **前置状态**：§5 已进入 Dungeon floor 0，房间光标落在 F0 `combat` 房（`sw_f0_combat`）。
- **触发动作**：`ui_accept`/tap 进入 CombatRoom → `Dungeon._start_battle(encounterId, false)` → 实例化 `Battle.tscn` 叠加层。
- **期望断言**：
  1. **固定触发**：CombatRoom 进房即启动 Battle（决策 2.3，无随机遭遇）；`BattleState.isBoss == false`。
  2. **叠加层非场景交换**：`Battle.tscn` 为 `World.tscn`/root 叠加层（`get_tree().get_root().add_child`）；**不在** `SceneManager` 持久场景栈（架构 §2.2 / S6）。
  3. **我方 4 combatants**：`PartyManager.build_party_combatants()` 返回 4 名（GAP-9）；敌方由 `EncounterDef.enemyIds`→`enemies.json` 组装（GAP-6/7）。
  4. **种子确定性（GAP-11）**：`rng.seed((run_state.seed + floorIdx*100 + roomIdx*10 + (isBoss?1:0)) & 0x7FFFFFFF)`，且为 `RNGService.new()` 每战实例化（非 autoload）。
  5. **战中不写盘**：战斗进行期间 `emberveil.save.v1` 不变、无 `battleState` 落入。
- **离线断言**：`assert_offline()`；战斗随机仅经 `RNGService`（无全局 RNG，CI RNG lint 守）。
- **失败即判**：未遇敌/不触发 ⇒ A（决策 2.3）；Battle 被序列化/进存档栈 ⇒ **S**（D4 破裂，save-scum）；combatants=0 ⇒ **S**（垂直切片卡死）；种子漏 `?1:0` 或烧额外 RNG ⇒ A（确定性破）。

## 7. Battle 胜（E9.4 真实循环 + XP 回写，GAP-8/9/11）
- **前置状态**：§6 Battle 已启动（Attack+EnemyAI 真实循环）。
- **触发动作**：脚本化动作序列驱动 `CombatFSM` 直至 `combat_ended("win")`；`Dungeon._on_battle_resolved(result)`。
- **期望断言**：
  1. FSM 各相可达并遍历：`PreBattle→PlayerSelect→ResolveAction→Animate→CheckEnd→(loop|PostBattle)`（C2）。
  2. `result == "win"`；`combat_ended("win")` 触发 `ProgressionManager.apply_battle_xp(result.enemy_xp, rs.party)`（GAP-8）。
  3. **GAP-8/10**：XP 按 `xp_for_level = 100*level` 代码曲线平分 4 英雄并写回 `run_state.party`（level/xp/hp/mp）；派生字段不重复存储。
  4. **GAP-9**：`PartyManager.sync_to_run_state(rs)` 写回 level/xp/hp/mp。
  5. 战斗结束 overlay 被移除，回到 `World`（Dungeon）。
- **离线断言**：`assert_offline()`。
- **失败即判**：FSM 某相不可达 ⇒ A（C2）；result 非 win（脚本化可控胜失败）⇒ A；XP 曲线错（非 `100*level`）⇒ A（GAP-10 破裂）；combatants 未写回 ⇒ A（GAP-9）。

## 8. FloorClear → 安全节点存档（E9.3 + E9.5）
- **前置状态**：§7 Battle 胜、回 `World`，房间标记 cleared（session）。
- **触发动作**：`WorldDirector.clear_floor(0)`（全层房间清完 → 自动安全节点存档）。
- **期望断言**：
  1. 清层触发安全节点存档：`SaveManager.was_written_at_safe_node() == true`。
  2. `worldState.dungeon.clearedFloors` 含 `0`；`floorIdx` 推进到下一层起点（房间光标重置）。
  3. reload 后 `RunState` **无** `battleState` 键（D4）。
  4. `SaveManager.load()` 非空且 `worldState.currentNode` 合法（与 §4/§5 一致）。
- **离线断言**：`assert_offline()`；reload 仅读 `localStorage`。
- **失败即判**：清层未存档 ⇒ A（D4）；reload 含 `battleState` ⇒ **S**（D4 破裂）。

## 9. 回城（续档永落 Town，决策 2.6 / E9.5）
- **前置状态**：§8 FloorClear 已安全存档；地牢进度 `clearedFloors=[0]`、`floorIdx=1`。
- **触发动作**：`WorldDirector.return_to_town()` → `_swap_world_child` 回 Town；回城即安全节点。
- **期望断言**：
  1. `SceneManager.current_node() == "Town"`；`World` 树下仅 1 个 Town 实例。
  2. **进度保留**：回城**不重置** `clearedFloors`（= [0]）；`floorIdx` 保留（= 1），下次经 Sage 续层（GAP-4）。
  3. **续档永落 Town**：`SaveManager.load()` 后 `currentNode` 恒 `"town"`（决策 2.6）；地牢进度由 `floorIdx/clearedFloors` 保留。
- **离线断言**：`assert_offline()`。
- **失败即判**：`current_node != "Town"` ⇒ FAIL；`clearedFloors` 被清 ⇒ A（R3）；`currentNode != "town"` 持久 ⇒ **S**（决策 2.6 破裂，脏续档）。

## 10. 安全存档校验（reload 无战斗态，D4 / S6）
- **前置状态**：§9 已回城且回城即安全存档。
- **触发动作**：`SaveManager.load()` 取最后安全点 → 还原 `RunState`。
- **期望断言**：
  1. `SaveManager.load()` 成功，`worldState.currentNode == "town"`、`clearedFloors == [0]`、`floorIdx == 1`。
  2. **`assert_no_battle_state_in_save()`**：还原的 `RunState` 无 `battleState` 键（Battle 叠加层绝不序列化）。
  3. `emberveil.save.v1` 为合法 JSON、checksum 校验通过（ADR-004）。
- **离线断言**：`assert_offline()`。
- **失败即判**：reload 含 `battleState` ⇒ **S**（D4 破裂）；checksum 失败 ⇒ S（存档损坏）；`currentNode != "town"` ⇒ S（决策 2.6）。

---

## 11. 战斗确定性校验（GAP-11 / ADR-002 / GDD §3.5）

> 独立校验步：同 `(seed, floorIdx, roomIdx, isBoss)` ⇒ 同 battle seed ⇒ 同战斗结果。垂直切片「可玩 + 可测 + 可 replay」的基石。

- **前置状态**：任意 `RunState`（含 `seed`）、已知 `(floorIdx, roomIdx, isBoss)`。
- **触发动作**：
  1. 计算 `nonce = floorIdx*100 + roomIdx*10 + (isBoss ? 1 : 0)`。
  2. 计算 `battleSeed = (run_state.seed + nonce) & 0x7FFFFFFF`。
  3. `rng = RNGService.new(); rng.seed(battleSeed)`。
  4. 同 `(seed, floorIdx, roomIdx, isBoss, action list)` 跑两遍战斗。
- **期望断言**：
  1. **公式一致**：实现中的种子组合 == `seed + floorIdx*100 + roomIdx*10 + (isBoss?1:0)`（漏 `?1:0` 判失败）；`& 0x7FFFFFFF` 截断生效。
  2. **可复现**：两遍同输入 ⇒ 完全相同 `log` + 相同胜负（哈希相等）。
  3. **唯一性**：同一次 run 内同一房间坐标 `(floorIdx, roomIdx, isBoss)` 唯一（每层房间序列固定、已清房跳过）⇒ nonce 唯一 ⇒ 非冲突。
  4. **非持久**：`battleNonce` 不进存档、不读 `OS/Time`、不烧全局 RNG（RNG lint 绿）。
  5. **跨 wipe 复现**：wipe 后 `SaveManager.load()` 回层边界安全点，再进同房 ⇒ 同坐标 ⇒ 同 nonce ⇒ 同战（满足 ADR-002「(seed, action 序列) ⇒ 同结果」）。
- **失败即判**：两遍 `log`/胜负不同 ⇒ **S**（确定性破，GAP-11/ADR-002 失败）；nonce 写进存档或读 `OS.rand` ⇒ **S**（R2/R2 风险触发）。

---

## 12. IP 合规闸清单（铁律，每步复用 `assert_offline()` / `assert_ip_clean()`）

> 原创 IP：Ward-Sigil 形状+标签语 + Underdog Stage 构图。**无** FF1/SE 资产/音频/布局/字体/商标。

- **自动断言（机器可校验）**：
  1. **无 FF1/SE 引用**：`grep -rniE 'se_|ff1|ffix|square_enix|final_fantasy|crystal' src/ content/ assets/` ⇒ 零命中（禁 FF1 水晶图标等克隆残留 + SE 引用）。
  2. **无 FF1/SE 音频**：`grep -rniE 'ff1_|se_|ff_' assets/audio/` ⇒ 零命中；无 FF1 式 chiptune 音色文件。
  3. **调色板 ≤48 色**：`tools/palette_validator.gd` + `content/palette.json` ⇒ 全局调色板 ≤48（E 预算）。
  4. **≥44×44px 命中**：`test_viewport_layout.gd`（复用）⇒ 360×640 下 Town 5 节点 / Dungeon 房间光标 / 谜题 3 石均 ≥44×44px。
  5. **reduced-motion fade-only**：转场/反馈断言无 `blink`/`shake`/`flash`；`reducedMotion` 开启时仅 fade 不闪（ux-spec §6.3）。
  6. **Ward-Sigil 形状+标签（不只颜色）**：`SigilDrawer` 单测 7 字形互异；Town 节点 / 谜题石含 `displayName` 文本标签；`colorblindAssist` 时叠加轮廓（§4.3 / §4.2）。
  7. **7 字形资源**：`content/` 下 7 个 Ward-Sigil 字形资源，两两 `silhouette` 哈希不同（形状为 ID 通道）。
  8. **纯离线**：`assert_offline()` ⇒ 场景树无 `HTTPRequest`/`WebSocketPeer`、无 `login`/`account`/`cloud` 节点、`grep -rnE 'HTTPClient|WebSocket|JavaScriptBridge|fetch\(' src/` 零命中。
- **人工评审门（不在自动 CI）**：
  9. **Underdog Stage 构图观感**（敌弧在上、我方带居中下、命令 dock 左下，非 FF1 全宽底栏）——art-director + design-strategist 签字（QA Plan §6/OQ6）。
  10. **7 字形无一匹配 FF1 元素图标**——同上评审门。
  11. **Boss 掉 Stone Sigil 表现**用原创 Ward-Sigil 语义，非 FF1「水晶」语义。
- **失败即判**：自动命中（#1–#8 任一失败）⇒ **S**（IP 违规，阻塞发布）；人工门未签 ⇒ 退出标准「IP gate 过」不成立，须主理人裁决。

---

## 13. 总体 PASS/FAIL 汇总

| 步骤 | 关键 ⛔ 映射 | 失败定级 |
|----|----|----|
| §1 Boot | A1/C 启动 | FAIL(S/A) |
| §2 Title | A3*/D5 | FAIL(A) |
| §3 New Run | D5 + GAP-12（4 人组队） | S（误覆盖/账号 UI/`party==[]`） |
| §4 Town | D4 safe-node + E9.2 节点图 + 44px | A（未存档/锁节点误激活）/B（<44px） |
| §5 Sage 进地牢 | GAP-4 续层 + E9.2 门控 + GAP-1 | A（门控/续层/多实例） |
| §6 CombatRoom 遇敌 | GAP-11 种子 + S6 overlay | **S**（Battle 序列化/战中写盘）/A（确定性破/combatants=0） |
| §7 Battle 胜 | C2 + GAP-8/9/10 XP 回写 | A（FSM/XP 曲线/GAP-9） |
| §8 FloorClear | D4 safe-node + clearedFloors | A（未存档）/S（含 battleState） |
| §9 回城 | 决策 2.6 续档永落 Town | FAIL(A)/**S**（`currentNode!=town`） |
| §10 安全存档 | D4 + ADR-004 | **S**（含 battleState/checksum 失败） |
| §11 战斗确定性 | GAP-11/ADR-002 | **S**（非确定） |
| §12 IP 合规 | 主理人 IP 规则 | **S**（IP 违规）/人工门未签 |

**判定**：§1–§12 全步断言通过、无 S 级失败、IP 自动闸零命中 ⇒ **smoke PASS**，可作为 Sprint 2 退出的 **M 道闸**绿灯。任一 S 级失败 ⇒ 整体 **FAIL**，阻断合并，需主理人裁决是否豁免（质量门为建议性）。

---

*End of Sprint 2 Smoke Spec. 本规格逐条钉死 `tests/smoke/test_vertical_slice.gd` 的断言；实现到达后该 stub 据本规格补满即成为 CI 回归门。IP 人工评审门见 QA Plan §6/OQ6。Boss 掉 Stone Sigil 表现须用原创 Ward-Sigil 语义（见 §12 #11）。*
