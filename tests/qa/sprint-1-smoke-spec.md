# EMBERVEIL — Sprint 1 Smoke Test Spec（烟雾测试规格）

> **Owner:** quality-lead（严守真 / Yan Soujin） · **Date:** 2026-07-26
> **对齐：** `docs/architecture/main-architecture.md` §6（Boot→Title→Town→Dungeon→Combat→win→safe-node Save）
> **实现对标：** `tests/smoke/test_boot_to_save.gd`（已有 stub，本规格逐条钉死其断言）
> **运行：** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`（CI 第 2 步 G2 道闸）
> **判定：** 任一步骤断言失败 ⇒ 整体 **FAIL**（建议性门控，最终放行由主理人定）；全步 PASS ⇒ **PASS**。

---

## 0. 范围与前置

**范围**：纯离线、单机的"能跑到安全节点存档"快乐路径。覆盖 checklist **G ⛔（smoke harness）** 与 A/C/D 的启动健康面。
**不覆盖**（本冲刺不验）：战斗数值平衡（占位，E8 锁）、Town/Dungeon 功能 UI（Sprint 2+）、音频（AudioBus 占位）。

### 0.1 前置（harness 准备）
- `localStorage` 清空（调用 `SaveManager.clear_for_test()`，确保无残留存档/设置）。
- 项目以 `gl_compatibility`（WebGL2）headless 启动；无网络可达。
- 断言框架：GUT（`extends GutTest`）。

### 0.2 通用辅助断言（每步复用）
- `assert_offline()` — 见 §8，纯离线铁律。
- `assert_ip_clean()` — 见 §9，IP 护栏。
- `assert_save_key(key)` — 断言 `localStorage` 含指定键且为合法 JSON（`emberveil.save.v1` / `emberveil.settings.v1`）。

### 0.3 退出映射
| 冲刺退出标准项 | 本规格覆盖 |
|----|----|
| G smoke `test_boot_to_save.gd` 过 CI | 全流程 §1–§7 |
| A/B/C/D ⛔ 全绿（启动健康面） | §1 Boot/Title、§4 Town save、§6 Combat FSM 可达、§7 safe-node |
| IP gate 过 | §9（自动令牌部分）+ 人工评审（见 QA Plan §6/OQ6） |

---

## 1. Boot（启动）

- **前置状态**：`localStorage` 清空；进程冷启动。
- **触发动作**：`godot --headless` 加载 `Boot.tscn`；`SettingsManager` 与 `SaveManager` 按 `main-arch §2.1` 顺序初始化。
- **预期断言（机器可校验）**：
  1. `SceneManager.current_node()` ∈ `["Boot", "Title"]`（启动解析到 Title 路径）。
  2. `SettingsManager` autoload 非 null 且已读取 `emberveil.settings.v1`（全局键；无存档时取 DEFAULTS）。
  3. `SaveManager` autoload 非 null；无存档时 `SaveManager.load()` 返回空/默认。
  4. 未触发任何写盘（启动为只读）。
- **离线断言**：`assert_offline()` 通过（启动无网络/云/账号调用）。
- **失败即判**：任一断言失败 ⇒ FAIL（A1/C 启动健康）。

## 2. Title Reached（到达标题）

- **前置状态**：§1 完成，`Boot` 已读取 settings/save。
- **触发动作**：等待 Boot ready；`SceneManager.go_to("Title")`。
- **预期断言**：
  1. `SceneManager.current_node() == "Title"`。
  2. 无存档时，`Title` 的 `Continue` 控件灰显/隐藏（`Continue` 仅在存档存在时可用，见 D5）。
  3. `Title` 场景树无 `login`/`account`/`cloud`/`signin` 节点或文案（纯离线铁律，ux-spec §7）。
- **离线断言**：`assert_offline()` 通过；§0.2 的 `Continue` 显隐符合离线模型。
- **失败即判**：`current_node != "Title"` ⇒ FAIL；`Continue` 误显 ⇒ A 级（体验/功能）。

## 3. New Run Confirm（新建存档确认，纯离线）

- **前置状态**：`Title`，无存档。
- **触发动作**：点 `New Run` → 出现确认对话框 → 确认 `SceneManager.new_run_confirmed()`。
- **预期断言**：
  1. **未确认前**，`new_run()` 被拒（单槽不被静默覆盖，D5）：调用未确认路径 ⇒ 单槽 `emberveil.save.v1` 不变。
  2. 确认后，生成全新 `RunState` 且 `schemaVersion == CURRENT`、`seed` 已赋值、`worldState.currentNode == "town"`。
  3. 全程**无**登录/账号/云 UI 或调用（纯离线；ux-spec §7）。
  4. `emberveil.settings.v1` 全局键存在且为扩展 schema（phase4-gate 3.1：含 `controlRemap`/`subtitle` 等字段或 DEFAULTS 前向填充）。
- **离线断言**：`assert_offline()`；无 `Auth`/`Session`/`Token` 概念。
- **失败即判**：未确认即覆盖 ⇒ S（数据丢失风险）；出现账号 UI ⇒ S（违反纯离线铁律）。

## 4. Town（进入城镇 = 安全节点存档）

- **前置状态**：§3 已 `new_run_confirmed()`，位于 `Town`。
- **触发动作**：`SceneManager.go_to("Town")`。
- **预期断言**：
  1. `SceneManager.current_node() == "Town"`。
  2. 进入 Town 触发安全节点存档：`SaveManager.was_written_at_safe_node() == true`。
  3. `localStorage` 键 `emberveil.save.v1` 已写入且为合法 JSON（断言 schemaVersion、party、worldState.currentNode=="town"）。
  4. 存档中**无** `battleState` 键（安全节点不含战斗态，D4）。
- **离线断言**：`assert_offline()`；存档仅落 `localStorage`。
- **失败即判**：`current_node != "Town"` ⇒ FAIL；进 Town 未存档 ⇒ A（D4 安全节点缺口）。

## 5. Dungeon Floor（进入地下城楼层）

- **前置状态**：§4 已抵 `Town` 且已安全存档。
- **触发动作**：`SceneManager.go_to("Dungeon", {"floorIdx": 0})`。
- **预期断言**：
  1. `SceneManager.current_node() == "Dungeon"`。
  2. `worldState.dungeon.dungeonId == "sundered_ward"`（E6 MVP 地下城）。
  3. `worldState.dungeon.floorIdx == 0`。
  4. 进入 Dungeon **不应**立即写盘（仅 Town-enter/floor-clear 等安全节点写；进入即写属实现选择，但不得在中战斗写）——本步断言 `emberveil.save.v1` 的 `worldState.currentNode` 仍为 `town`（除非设计将"进入地城"也列为安全节点；见 OQ，当前按 ux-spec §2.2 仅 Town-enter 触发 safe save）。
- **离线断言**：`assert_offline()`。
- **失败即判**：dungeonId/floorIdx 不符 ⇒ A（E6 数据缺失）；误写盘 ⇒ A（D4）。

## 6. Combat Win（战斗胜利，overlay + FSM 可达，战中不存档）

- **前置状态**：§5 已抵 `Dungeon` floor 0。
- **触发动作**：`var result = SceneManager.enter_combat_and_resolve("smoke_encounter", "win")`。
- **预期断言**：
  1. 战斗为 **overlay** 添加（非场景交换）：`Battle.tscn` 为 `World.tscn` 子节点 / 叠加层，`Battle` 不在 `SceneManager` 持久场景栈中（架构 §2.2）。
  2. FSM 各相可达并遍历：`PreBattle→PlayerSelect→ResolveAction→Animate→CheckEnd→PostBattle`（断言战斗 `log` 含各相标记，或 `combat_ended(win)` 触发；C2）。
  3. `result == "win"`；`combat_ended(win)` 触发 `ProgressionManager` 记 XP（B6/E3-G 收尾）。
  4. **战中不存档**：战斗进行期间 `emberveil.save.v1` 键内容不变（无 `battleState` 落入）；战斗为确定性（同 seed 可复现，C3，由集成测试覆盖，本步仅断言"无中战斗写盘"）。
  5. 战斗结束 overlay 被移除，回到 `World`（Town/Dungeon）。
- **离线断言**：`assert_offline()`；战斗随机仅经 `RNGService`（无全局 RNG，C4 由 CI lint 守）。
- **失败即判**：overlay 被序列化/战中写盘 ⇒ S（D4 破裂，可 save-scum）；FSM 某相不可达 ⇒ A（C2）；result 非 win ⇒ A（脚本化战斗应可控胜）。

## 7. Floor Clear → Safe-Node Save（清层存档，战斗态缺席）

- **前置状态**：§6 战斗胜利、回 `World`。
- **触发动作**：`SceneManager.clear_floor(0)`。
- **预期断言**：
  1. 清层触发安全节点存档：`SaveManager.was_written_at_safe_node() == true`。
  2. reload 后 `RunState` 中 **无** `battleState` 键（D4：战中态绝不持久化）。
  3. `worldState.dungeon.clearedFloors` 含 `0`；`worldState.currentNode` ∈ `["town","dungeon"]`。
  4. `SaveManager.load()` 非空且 `worldState.currentNode` 合法（与 §4/§5 一致）。
- **离线断言**：`assert_offline()`；reload 仅读 `localStorage`。
- **失败即判**：清层未存档 ⇒ A（D4）；reload 含 `battleState` ⇒ S（D4 破裂）。

## 8. 纯离线断言 `assert_offline()`（铁律，每步复用）

> 对齐 ux-spec §7、main-arch §1.1（Analytics 默认关、无云/账号）。

- **运行时断言（烟雾内）**：
  1. 当前场景树中**无** `HTTPRequest` 节点实例。
  2. **无** `WebSocketPeer` 实例、`WebSocket` 连接。
  3. `Title`/`Boot` 场景树中**无**名称/文案含 `login`/`account`/`cloud`/`signin`/`session`/`token` 的节点。
- **静态断言（CI 级，建议并入 G5 或独立 step）**：
  4. `grep -rnE 'OS\.request|HTTPClient|WebSocket|JavaScriptBridge|fetch\(' src/` ⇒ 零命中（纯离线，无网络栈调用）。
  5. `Analytics` 若存在，默认 `enabled=false`（无遥测默认关）。
- **失败即判**：任意命中 ⇒ **S**（违反纯离线铁律，主理人决策级）。

## 9. IP 护栏断言 `assert_ip_clean()`（铁律，每步复用）

> 对齐 main-arch 首段 IP 规则、ux-spec §0/§10。无 SE/FF1 资产、布局、字体、商标；仅 Ward-Sigil + Underdog Stage。

- **自动断言（机器可校验）**：
  1. `grep -rniE 'se_|ff1|ffix|square_enix|final_fantasy|crystal' src/ content/ assets/` ⇒ 零命中（禁止 FF1 水晶图标等 1:1 克隆残留与 SE 引用）。
  2. `content/` 下存在 7 个 Ward-Sigil 字形资源，且两两 `silhouette` 哈希不同（形状为 ID 通道，art-bible §7.3；E5-D）。
  3. `Battle.tscn` 节点含 `EnemyArc`/`PartyBand`/`CommandDock`（Underdog Stage 结构）；**无**名为 `FF1EnemyRow`/`PartyLeftColumn` 等 FF1 式布局节点。
- **人工评审门（不在自动 CI）**：
  4. Underdog Stage **构图观感**（敌弧在上、我方带居中下、命令 dock 左下，非 FF1 全宽底栏）——由 art-director + design-strategist 评审签字（见 QA Plan §6 / OQ6）。
  5. 7 字形**无一匹配** FF1 元素图标——同上评审门。
- **失败即判**：自动命中（#1–#3 任一失败）⇒ **S**（IP 违规，阻塞发布）；人工门未签 ⇒ 退出标准"IP gate 过"不成立，须主理人裁决。

---

## 10. 总体 PASS/FAIL 汇总

| 步骤 | 关键 ⛔ 映射 | 失败定级 |
|----|----|----|
| §1 Boot | A1/C 启动 | FAIL(S/A) |
| §2 Title | A3*/D5 | FAIL(A) |
| §3 New Run | D5 + 纯离线 | S（误覆盖/账号 UI） |
| §4 Town | D4 safe-node | A |
| §5 Dungeon | E6 数据 | A |
| §6 Combat | C2/C3/D4 overlay | S（战中写盘）/A（FSM） |
| §7 Floor Clear | D4 safe-node + reload | S（含 battleState）/A |
| §8 Offline | 用户决策 | S |
| §9 IP | 主理人 IP 规则 | S |

**判定**：§1–§9 全步断言通过且无 S 级失败 ⇒ **smoke PASS**，可作为 Sprint 1 退出的 G 道闸绿灯。任一 S 级失败 ⇒ 整体 **FAIL**，阻断合并，需主理人裁决是否豁免（质量门为建议性）。

---

*End of Sprint 1 Smoke Spec. 本规格逐条钉死 `tests/smoke/test_boot_to_save.gd` 的断言；实现到达后该 stub 据本规格补满即成为 CI 回归门。IP 人工评审门见 QA Plan §6/OQ6。*
