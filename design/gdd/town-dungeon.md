# Town / Dungeon 场景级 GDD — EMBERVEIL (Sprint 2 · Route A)

> File: `design/gdd/town-dungeon.md` · Owner: design-strategist (文策渊 / Vince Coyer)
> Status: Sprint 2 · Review: FULL · Engine: Godot 4 (真做场景，非 HTML 探针)
> Upstream（强约束，必须遵循）:
> - 系统级 GDD：`world-nodes.md`（S5）、`combat.md`(S2)、`elements.md`(S3)、`progression.md`(S4)、`party-jobs.md`(S1)、`save-load.md`(S6)
> - `design/ux/ux-spec.md`（§2 状态图 / §2.2 转换持久化 / §2.3 4 层 sub-flow / §3 输入 / §5 HUD / §6 反馈）—— **硬约束**
> - `docs/architecture/main-architecture.md`（§1.1 模块表 / §2.2 场景树 / §2.4 EventBus / §4 存档 schema）
> - `design/art/art-bible.md`（§2.3 ≤48 色 / §6.2 Underdog Stage / §7 Ward-Sigil / §9 可访问性）、`design/art/accessibility.md`
> - Sprint 1 已落地代码：`src/autoloads/*`、`src/combat/*`、`src/battle/*`、`content/*`
> - IP 红线：原创 Ward-Sigil 符号 + Underdog Stage 构图；**不复制** Square Enix / FF1 任何资产、布局、字体。
> - 工程硬约束：视口 360×640、交互元素 ≥44×44px、调色板 ≤48 色、纯离线（localStorage 单槽）、reduced-motion 默认 fade-only、**元素用形状+标签识别**（不只颜色）。

> **本文档定位**：把 `world-nodes.md` 的「系统级」世界设计落到「场景级」实现规格，使 engineering-lead 能照着写代码。本文档**只做设计，不含任何 Godot 实现代码**；§8 中的伪代码均为「方法签名骨架」，供工程对齐接口用。

---

## 1. 系统概述（目标与范围）

把 MVP 世界（1 个 Town hub + 1 个 Dungeon）从系统抽象降维成**两个可实例化的 Godot 场景**：`Town.tscn`（Hearthmoor，5 节点）与 `Dungeon.tscn`（The Sundered Ward，4 层房间序列）。两者都作为 `World.tscn` 的**常驻子场景**被装载/卸载（架构 §2.2：World 常驻，Town/Dungeon 由 WorldDirector 实例/移除，RunState 不重载 → 杜绝中途 reload 的 save-scum）。

**范围（MVP 锁定）**
- **Town = Hearthmoor**：5 个节点 `Rest`(Inn) / `Shop`(Market) / `Barracks` / `Sage`(Quest) / `Shrine`(Save)。安全区，无随机遭遇。
- **Dungeon = The Sundered Ward**：4 层（MVP 推荐 4）。每层序列 `CombatRoom → PuzzleRoom(ember→frost→storm) → RewardRoom`；第 4 层末尾追加 `BossRoom` = `Sigil-Twisted Warden` → 掉落 **Stone Sigil**（解锁 Stone 元素）。
- **Battle** 作为 `Battle.tscn` **叠加层**启动（add_child 到 root），**永不被序列化**（架构 §2.2、ux-spec §2.2）。
- 本 GDD 明确回答四件事：(1) Town 布局与交互；(2) Dungeon 地图模型/遇敌/谜题/奖励/Boss/FloorClear；(3) 与现有 autoload 的**接口契约**（含伪代码骨架）；(4) **复用清单**（复用 vs 新增）。

**不在本 GDD 范围**：具体数值平衡（属 E8 balance spike，数值均为初值/占位）、L2+ 多镇/overworld、剧情长弧。

---

## 2. 核心规则

### 2.1 Town（Hearthmoor）规则
- 5 节点各自是一个**离散的可点按 Ward-Sigil 风格按钮**（≥44×44px，形状+文字标签）。Tap 节点 → 打开该节点的**叠加面板**（不切场景，保持 World 常驻）。
- `Rest`：免费全回复 HP/MP（设计支柱 Session-Friendly 的「银行进度」节拍）。`Shop`：用金币买/卖装备与道具。`Barracks`：重编队伍（max 1 per job）。`Sage`：接任务 + 「进入地牢」入口（任务已接且地牢未通关时才可用）。`Shrine`：手动存档（安全节点）+ 续档锚点。
- Town 进入即安全节点：Sprint 1 `SceneManager.go_to("Town")` 已自动 `SaveManager.save(_run_state, true)`。

### 2.2 Dungeon（The Sundered Ward）规则
- 每层是**固定房间序列**（非线性图）：F1–F3 = `CombatRoom → PuzzleRoom → RewardRoom`；F4 = `CombatRoom → PuzzleRoom → RewardRoom → BossRoom`。
- 玩家在「房间轨道」上**步进前进**：`ui_left/right` 在当前层房间序列中移动房间光标（prev/next）；`ui_up/down` 预留给房内交互（如谜题选石）。也可直接 Tap 房间进入。
- 只能**向前越过已清房间**；未清房间不可跳过。
- 进入 `CombatRoom` / `BossRoom` **固定触发**战斗（无随机遭遇，见决策 2.3）。
- `PuzzleRoom`：按 `Ember → Frost → Storm` 顺序激活 3 块石；顺序错即**整组重置**（见决策 2.4）。
- `RewardRoom`：开箱得金币/道具（首通唯一，靠 `chestsOpened` 去重）。
- 全层房间清完 → **FloorClear**（安全节点自动存档）→ 进下一层；F4 Boss 击败 → 回城（胜利节拍）。
- **战斗中 HP/MP 跨房间保留**（只在 Town 的 Rest/Shrine 回复），制造地牢内的消耗张力（决策 2.5）。

### 2.3 关键设计决策（选型 + 理由）

> 以下均为**设计推荐**，已给出理由与备选；最终可由主理人拍板覆盖。

**决策 2.1 — Town 用「节点图」而非「俯视街区」**
- 选型：**节点图**（单屏内 5 个可点按节点，中心对称构图：Shrine/Sage 作地标，其余环布）。
- 理由：① 视口 360×640 竖屏，俯视街区需滚动/平移，与 art-bible「低 UI 密度、一个节拍=一个目标」冲突；② 节点图与 `world-nodes` 数据模型 1:1 对应（5 个离散节点=5 个离散动作），映射最干净；③ tap 节点是最简单、最可访问的交互（44×44 按钮，无需移动/碰撞/相机）；④ 俯视街区徒增美术/资产负担（立面 ≤200×240、可走格），在 48 色 / 4 图集 / 16MB 预算下性价比极低；⑤ fade-only 转场与节点 tap 天然契合。
- 备选（否决）：俯视步行街区——工程量与资产成本数倍于节点图，MVP 收益几近于零。

**决策 2.2 — Dungeon 用「节点步进推进」而非「网格自由探索」**
- 选型：**节点步进推进**（每层一条房间轨道，光标步进；非网格、无寻路/碰撞/相机）。
- 理由：① 每层本就是 `CombatRoom→PuzzleRoom→RewardRoom` 的线性序列（world-nodes §2、ux-spec §2.3），网格自由探索是过度设计；② 网格自由探索需路径/碰撞/相机/逐格存档，工程量大且与「一个节拍=一个目标」「session-friendly」相悖；③ `ui_up/down/left/right`（ux-spec §3）可直接映射为「房间光标移动 / 房内交互」；④ 与数据模型 `DungeonDef.floors[Room[]]` 及存档（floorIdx + clearedFloors）天然契合；⑤ 无相机平移→更利于 reduced-motion、更省预算、更可访问。
- 备选（否决）：网格自由探索——MVP 零设计收益，工程风险高。

**决策 2.3 — 地牢内无随机遭遇（战斗仅发生于 CombatRoom / BossRoom）**
- 理由：① 固定 CombatRoom 给出可预测的「一房一节拍」session-friendly 节奏；② 随机遭遇与「安全节点存档防 scum」及确定性 RNG 模型冲突（随机烧 RNG 会破坏 replay 确定性）；③ world-nodes §2 明确 combat 是「房间类型」触发，非随机；④ 契合 reduced-motion / session-friendly。
- 落地：`CombatRoom`/`BossRoom` 进入即 `isBoss=false/true` 的固定遭遇；其余房间类型绝不触发战斗。

**决策 2.4 — 谜题容错 = 任意错序即整组重置（forgiving，无死锁）**
- 理由：① world-nodes §7 规定「谜题不可解→离开房间即重置，无永久锁」；② 整组重置最简单、零软锁风险、对可访问性友好；③ 三石顺序固定（ember→frost→storm），误触任意一块即清掉所有已点亮石并提示「Sigil order disrupted」，玩家从头再来。
- 离开 `PuzzleRoom` 也重置（session 状态）。已通关的谜题房再次进入时门已开，不再重解。

**决策 2.5 — 地牢内 HP/MP 消耗制，仅在 Town 回复**
- 理由：Rest=免费全回复是 MVP「银行进度」节拍；地牢内保留减员制造张力，但安全节点（FloorClear/回城）保证不会无谓损失。战斗中减员跨房间保留，到 Town 才回满。

**决策 2.6 — 续档永落在 Town（遵循 UX 安全节点集合）**
- 当前安全节点集合（ux-spec §2.2）= {Town 进入, FloorClear, Sigil-attune, Quest-complete}。**Floor 进入不是安全节点**。因此 `SaveManager.load()` 后 `currentNode` 永远为 `"town"`，地牢进度由 `worldState.dungeon.floorIdx` 保留，玩家在 Town 经 Sage 重新进入地牢即可续到该层。
- （未来增强可选：把「Floor 进入」也设为安全节点即可实现「地牢内续档」；MVP 不采纳，见 §8 开放项。）

**决策 2.7 — New Run 默认组队 = 固定 4 职业（闭合 E9 接口点 5）**
- 选型：**New Run / 首次进入 Town 时，用 4 名默认英雄（Vanguard / Channeler / Skirmisher / Warden 各一，即 party-jobs §4 默认阵容）种子化 `RunState.party`**。Dungeon 入口前 `RunState.party` **绝不可为 `[]`**（否则 `BattleResolver` 无我方 combatants，垂直切片直接卡死）。
- 责任归属：这是 Title→New Run 流程（或 `SceneManager._default_run_state()` / 新增 `PartyManager.new_run()`）的职责，**不是 Town 场景本身**；但本 GDD 在此锁定契约，使 E9 垂直切片能立刻产出 4 名真实 combatants。
- 落地：`SceneManager._default_run_state()` 当前 `"party": []` 是 **GAP**（见 §8 GAP-12），必须由 New Run 流程在进 Town 前用 4 默认职业填满；Barracks 重编（max 1 per job）在 S2 锁定（见决策 2.8），故 New Run 默认即标准 4 职业阵容。
- 替代（否决）：复用 Barracks 预组作为 New Run 默认——S2 Barracks 锁定，无预组可复用；且垂直切片要求一进地牢就有 4 combatants，必须 New Run 即定型。

**决策 2.8 — Town S2 切片范围：仅 {Rest, Sage, Shrine} 可交互（闭合 E9 接口点 6）**
- 选型：Sprint 2 垂直切片中，Town 5 节点**可交互** = `Rest(Inn)` / `Sage` / `Shrine`；**锁定**（灰显 + tap 弹 toast「即将开放」）= `Shop(Market)` / `Barracks`。
- 理由：地牢垂直切片只需三件套即可跑通「进地牢→战斗→清层→回城」循环——`Rest`(免费全回复，地牢消耗后的恢复点)、`Sage`(接任务+进地牢入口)、`Shrine`(手动安全存档)。`Shop`/`Barracks` 属 progression 深度（买装/重编），S2 仅占位，E9 全量或后续 sprint 再开启。这与 `production/epics/epic-09-...` 的 E9.2 MVP 深度一致。
- 落地点：Town.tscn 中 `Shop`/`Barracks` 节点渲染为灰显 + 不可激活；`Rest`/`Sage`/`Shrine` 走正常叠加面板流程。

**决策 2.9 — 编队数据独立成 `content/encounters.json`（不内联，闭合 E9 接口点 3）**
- 选型：**新建 `content/encounters.json`**，每个 `EncounterDef { id, enemyIds[], isBoss, xpValue, drops }`；`RoomDef.encounterId` 仅存引用 id，**不**把敌人列表内联进 `dungeons.json`。
- 理由：① 编队与地牢布局解耦，同一编队可被多层复用；② 敌人数值来自 `enemies.json`（经 `AssetRegistry`），编队只做「id 列表」组合；③ 符合 ADR-003 数据驱动（加内容=加数据文件，零代码改动）；④ 避免 `dungeons.json` 既描述结构又内联数值导致的双重维护。
- 字段契约见 §3.3；当前 `dungeons.json` 引用的 `smoke_encounter` 是 Sprint1 stub，必须删除（GAP-5/6）。

---

## 3. 数据模型与状态

### 3.1 Town 节点数据（5 个，静态定义于 `content/` 或场景内）
```
TownNode { id, displayName, sigilShape, action }   // action ∈ {rest, shop, barracks, sage, shrine}
// 例：{ id:"rest",   displayName:"Rest (Inn)",     sigilShape:"hearth",  action:"rest" }
//     { id:"shop",   displayName:"Market",         sigilShape:"coin",    action:"shop" }
//     { id:"barracks",displayName:"Barracks",      sigilShape:"banner",  action:"barracks" }
//     { id:"sage",   displayName:"Sage",           sigilShape:"eye",     action:"sage" }
//     { id:"shrine", displayName:"Shrine",         sigilShape:"ward",    action:"shrine" }
```
> 形状为原创 Ward-Sigil 语义符号（非 FF1/SE），配合文字标签（决策：形状+标签，不只颜色）。

### 3.2 Dungeon / Room 数据（扩写 `content/dungeons.json`，闭合 E9 接口点 2）

> **最终 schema（覆盖现有 stub）**：现有 `dungeons.json` 的 `floors:[{idx,encounters,isBoss}]` 与 world-nodes §3 的 `DungeonDef { id, floors[Room[]], bossRoom }` **错位**（无 Room 粒度、encounters 内联、缺 type 枚举）。MVP 必须**整体重写为以下 schema**，并与 world-nodes §3 对齐（GAP-5）。

```
DungeonDef {
  id: "sundered_ward", name: "The Sundered Ward",
  floors: FloorDef[4]
}
FloorDef {
  idx: int,                                   // 0..3
  rooms: RoomDef[]                            // F1–F3: [Combat, Puzzle, Reward];  F4: [Combat, Puzzle, Reward, Boss]
}
RoomDef {
  id: string,                                 // 全局唯一，如 "sw_f0_combat" / "sw_f3_boss"
  type: "combat"|"puzzle"|"reward"|"boss",     // ★ Room type 枚举（world-nodes §3）
  encounterId: string,                        // → EncounterDef.id（type=combat/boss 必填；puzzle/reward 可空）
  puzzleOrder: [element],                     // type=puzzle 用：固定 ["ember","frost","storm"]（形状可读，见 §4.2）
  reward: { gold:int, items:[{id,qty}], sigilId?:string }  // type=reward 用；sigilId 用于特殊奖励（MVP 仅 Boss 掉 Stone，reward 一般无）
}
```
- `bossRoom`：MVP 即 `F4.rooms` 中 `type=="boss"` 的那一间，`DungeonDef` 无需单列 `bossRoom` 字段（由 type 推导）；如需兼容 world-nodes §3 表述，可加 `bossRoomId: "sw_f3_boss"` 冗余指针，但**以 rooms[].type 为真源**。
- `encounterId` 引用 **`content/encounters.json` 的 `EncounterDef`**（见 §3.3，决策 2.9 决定独立文件）。

### 3.3 新增：EncounterDef（战斗编队数据源，闭合 E9 接口点 3）
```
EncounterDef {
  id: string,                 // 如 "sw_f0_combat", "sw_f3_boss"
  enemyIds: [string],         // → enemies.json 的 id 列表
  isBoss: bool,
  xpValue: int,               // 全队共享的总 XP（combat.md §5：sum(enemy.xpValue) 平分）
  drops: { gold:int, items:[{id,qty}] }
}
```
> 敌人数值来自 `content/enemies.json`（经 `AssetRegistry.get_content("enemies")`）。**注意**：现有 `enemies.json` 缺 `xpValue` 字段且仅有 2 个敌人（见 §8 GAP-7），需补齐 ~6 敌 + 1 Boss `Sigil-Twisted Warden`。

### 3.4 WorldState 充分性审查（与 `save-load.md` §3 / 架构 §4 对齐）
现有 `worldState`：
```
worldState {
  currentNode: "town",
  townVisited: bool,
  dungeon: { dungeonId, floorIdx, clearedFloors[], foundSigils[], chestsOpened[], bossDefeated }
}
```
- **足够的部分**：`floorIdx`（续层）、`clearedFloors`（已清层）、`chestsOpened`（奖励去重）、`bossDefeated`（通关判定）均可用。
- **缺口（必须补）**：
  - **逐房间状态**：当前只有层级 `clearedFloors`，没有「当前层内房间光标 / 已清房间」。`currentRoomIdx` 与 `clearedRoomIds` **建议作为 Dungeon 场景的 session 状态（不进存档）**，避免脏状态 bug（见 §8 GAP-2 说明）。理由：安全节点只在层边界，wipe/quit 会回到上一层安全点，整层重打；因此逐房间进度在跨会话时本就会被丢弃，存它反而有「续档跳房」风险。
  - **续层起点**：`enter_dungeon(floor_idx=0)` 现在**硬编码从第 0 层开始**（见 §8 GAP-4），必须改为「无参时续到 `worldState.dungeon.floorIdx`」。
- **冗余提示**：`foundSigils`（worldState）与 `runProgress.codex.attunedSigilIds`（WardCodex 落盘）功能重叠。建议 **WardCodex 为功能唯一真源**，`foundSigils` 仅在需要世界态 UI 时保留（§8 开放项）。

### 3.5 BattleState 构造（战斗启动前由 Dungeon 场景组装）
```
BattleState {
  combatants: Combatant[],    // = 我方(4) + 敌方(编队)
  queue: [combatantId],       // PreBattle 按 SPD 降序（平局：slot 升序 → 种子 RNG 决出）
  turnPointer: 0,
  phase: BattleFSM.Phase.PreBattle,
  log: [],
  isBoss: bool
}
Combatant { id, side(ally|enemy), name, HP, maxHP, MP, maxMP, ATK, DEF, MAG, RES, SPD,
            affinity, aptitude?(我方), aiProfile?(敌方), statusEffects[], xpValue?(敌方) }
```
- 我方 Combatant：由 `PartyManager.build_party_combatants()` 从 `all_members()` + `derive_stats()` + 装备修正 + 当前 hp/mp 组装（**GAP-9**）。New Run 默认 4 英雄见决策 2.7。
- 敌方 Combatant：由 `EncounterDef.enemyIds` → `enemies.json` 组装（**GAP-6/7**）。
- **战斗种子 / battleNonce 契约（闭合 E9 接口点 4，关 ADR-002 可复现）**：
  - **nonce 是「派生的、非持久化的」**：`battleNonce = floorIdx*100 + roomIdx*10 + (isBoss ? 1 : 0)`。**不**存任何计数器、也**不**在存档里自增。
  - **组合方式**：`rng.seed( (run_state.seed + battleNonce) & 0x7FFFFFFF )`，喂给 `RNGService.new()`（每战实例化，非 autoload）。
  - **可复现性论证**：① 同一房间坐标 `(floorIdx, roomIdx, isBoss)` 在同一次 run 内唯一（每层房间序列固定、已清房跳过、整 run 每房至多进一次）→ nonce 唯一；② 战斗**永不序列化**（架构 §2.2），wipe 后 `SaveManager.load()` 回到层边界安全点，再进同一房 → 同样坐标 → 同样 nonce → **同样战斗**，满足 ADR-002「(seed, action 序列) ⇒ 同结果」；③ 不烧全局 RNG、不读 `OS/Time`，纯函数链路。
  - **取舍（显式）**：MVP 不引入「逐次尝试差异」——重打同一房会得到**完全相同**的战斗（含同样 variance 序列）。这对测试/replay 是优点；若未来想要「每次重打略不同」，再加持久化 `worldState.dungeon.battleAttempt`（每战 +1）并入 nonce，**当前不采纳**（见 §8 GAP-11）。
  - **禁止**：切勿用 `run_state.seed` 直接 `rng.seed` 后还去 `rng.next()` 做别的事，或把 nonce 写进存档——会破坏确定性。

---

## 4. 交互与输入（遵循 ux-spec §3 逻辑动作）

### 4.1 Town：tap 节点模型
- 5 个节点按钮均为 `Control`（≥44×44px），`ui_up/down/left/right` 在节点间移动 **parchment glow 焦点环**，`ui_accept` 激活该节点 → 打开对应叠加面板（Rest 直接全回复+toast；Shop/Barracks/Sage/Shrine 打开面板）。
- 所有面板为 `Town.tscn` 上的 `Control` 叠加层（不切场景），关面板即回节点图。`ui_cancel` → Pause 菜单。
- **Sage → Dungeon 触发**：Sage 面板显示任务文本 + 「进入地牢」按钮；按钮仅在 `questAccepted && !bossDefeated` 时可用。确认后 → `WorldDirector.enter_dungeon()`（续到 `floorIdx`）。
- **Shrine 安全存档表现**：tap Shrine → 存档确认对话框 → `SaveManager.save(run_state, true)`（安全节点）→ 「Saved」toast + Shrine 微光（fade-only，ux-spec §6.2）。Town 进入本就自动存档，Shrine 提供玩家显式存档点。

### 4.2 Dungeon：移动 / 房间 / 谜题 / 奖励 / Boss / FloorClear
- **移动模型（对应 ux-spec §3 `ui_up/down/left/right`）**：
  - `ui_left` / `ui_right`：在「房间轨道」上移动房间光标（prev/next）；只能前进越过已清房间，不能跳过未清房间。
  - `ui_up` / `ui_down`：房内交互预留（如 `PuzzleRoom` 内上下选石；非谜题房可 no-op）。
  - 也支持直接 Tap 房间节点进入（焦点环 + 44×44 目标）。
- **进入房间**：焦点落在某房间并 `ui_accept`/tap → 触发该房间系统：
  - `combat` → 固定启动 `Battle.tscn` 叠加层；
  - `puzzle` → 进入谜题交互（3 石）；
  - `reward` → 开箱（首通给金币/道具，写入 `chestsOpened`）；
  - `boss` → 固定启动 `Battle.tscn`（isBoss=true，Run 禁用）。
- **PuzzleRoom 交互契约（闭合 E9 接口点 7，world-nodes §4/§7）**：
  - **3 块石的形状可读 tap 顺序**：3 块石以 **Ward-Sigil 形状 + 文字标签**呈现（ember=flame / frost=snow / storm=bolt，均来自 `sigils.json`），每块 ≥44×44 可点。**要求的激活顺序 `(ember → frost → storm)` 必须对玩家显式可读、且不依赖颜色**——实现方式二选一（或叠加）：① 门/石阵旁常驻显示「下一步该点的 Sigil 形状+标签」提示；② 三石按目标顺序以由暗到亮的 Ward-Sigil 轮廓预排。这样色盲（`colorblindAssist`）与低注意力玩家都能仅靠形状解出（满足 accessibility §9.1「形状+标签，不只颜色」）。
  - **Tap 顺序判定**：按 `RoomDef.puzzleOrder = ["ember","frost","storm"]` 逐块校验；当前应点石被 tap → 点亮（fade/glow，reduced-motion）+ 进度 +1；错序石被 tap → 触发整组重置（见下）+ toast「Sigil order disrupted」。
  - **离房重置规则（硬）**：① 任意错序即**整组重置**（所有已点亮石 fade 熄灭、`_puzzle_progress=0`），玩家从头再来——零软锁（决策 2.4）；② **离开 `PuzzleRoom`（backtrack/进下一房/退出地牢）也重置**，`puzzleOrder` 进度是 **Dungeon 场景 session 状态，不进存档**；③ 已通关的谜题房再次进入时门已开，不再重解、不再重置。
  - 全对（3/3）→ 门 fade 开启 + 房间标记 cleared（session）+ 解锁前进（决策 2.4、ux-spec §2.3）。
- **RewardRoom**：tap 箱 → 发奖励（gold/items），首通唯一（靠 `chestsOpened` 去重）；已开箱再次进入不再给。
- **BossRoom（仅 F4）**：击败 `Sigil-Twisted Warden` → 掉落 Stone Sigil → `WardCodex.attune("stone")`（解锁 Stone 元素）+ `EventBus.codex_updated` 发射 → 大 XP（mini-boss ~120）→ `bossDefeated=true` → 视为该层 FloorClear。
- **FloorClear → 下一层 / 回城**：
  - 全层房间清完（或 Boss 击败）→ `WorldDirector.clear_floor(floor_idx)`（**自动安全节点存档**）→ `floorIdx+1`、重置房间光标到新房首间。
  - F4 通关 → 胜利节拍 → `WorldDirector.enter_town()` 回城（Sage 入口转为禁用/通关回顾）。
- **回城（backtrack）**：地牢内提供「返回 Town」出口（如每层入口或 Pause 菜单）→ `WorldDirector.enter_town()`；地牢进度（clearedFloors/floorIdx）保留，下次 Sage 续层。

### 4.3 通用约束落实
- 所有交互元素 ≥44×44px；元素/状态一律 **形状(Ward-Sigil)+文字标签**（不只颜色），`colorblindAssist` 时叠加轮廓。
- 所有转场/反馈 **fade-only**（reduced-motion 默认开启，绝不闪/震/blink，ux-spec §6.3）。

---

## 5. 进度与成长

- **XP 流（combat → Progression → 存档）**：战斗胜利 → `EncounterDef.xpValue` 作总 XP → `ProgressionManager` 平分给 4 英雄（`add_xp`）→ 写回 `run_state.party`（level/xp/hp/mp）→ **仅在下一个安全节点（FloorClear / Boss-attune / 回城 / Shrine）才 `SaveManager.save`**。战斗中不减员不丢失「已得 XP」——因为未到安全节点前若 wipe，会 reload 上一安全点，符合防 scum 设计。
  - **跨文档冲突（须修）**：`progression.md` §2 写 `xpToNext(l)=round(20*l^1.35)`，但 `main-architecture.md` §6.1 与 Sprint 1 `ProgressionManager.xp_for_level = 100*level` **不一致**。建议**以代码为准锁定 `xp_for_level = 100*level`**，并在 balance spike 同步修订 `progression.md`（见 §8 GAP-10）。
- **Stone Sigil 解锁**：Boss 胜利 → `WardCodex.attune("stone")` → Stone 元素法术对所有 `aptitude[stone]>0` 的英雄可用（Vanguard 0.3 / Warden 0.5 / Channeler 1.0 / Skirmisher 0.4）。这是「发现=力量」节拍。
- **金币/道具**：来自 combat drops 与 RewardRoom 箱，经 `run_progress` 持久化。
- **等级/共鸣上限**：level cap 20、resonance cap 5（+50% 上限），防 power-creep（progression §7）。

---

## 6. 内容清单（MVP）

**Town / Hearthmoor（5 节点）**：Rest(Inn) / Shop(Market) / Barracks / Sage / Shrine。

**Dungeon / The Sundered Ward（4 层）**：
| 层 | 房间序列（RoomDef.type） | 备注 |
|---|---|---|
| F1 | combat → puzzle(ember→frost→storm) → reward | 入门编队 |
| F2 | combat → puzzle → reward | 强化编队 |
| F3 | combat → puzzle → reward | 强化编队 |
| F4 | combat → puzzle → reward → **boss** | Boss=`Sigil-Twisted Warden` → Stone Sigil |

**敌人（需补齐 `content/enemies.json`，含 `xpValue`）**：`Huskling`(physical) / `Frostmote`(Frost-affinity) / `Stoneling`(Stone-affinity, 高 DEF) / Storm-affinity 敌 / +1 普通敌 / **Boss `Sigil-Twisted Warden`**（xpValue~120）。现有 stub 仅 2 个且无 xpValue（见 §8 GAP-7）。

**EncounterDef（需新增 `content/encounters.json`）**：`sw_f0_combat`…`sw_f3_combat`、`sw_f3_boss` 等，含 enemyIds/isBoss/xpValue/drops。

**新增/扩写内容文件**：`content/encounters.json`（新）、`content/dungeons.json`（扩写为 4 层 rooms）、`content/enemies.json`（补 xpValue + 敌人）、`content/items.json`/`equipment.json`（已有 stub，按需补）。

---

## 7. 边界与平衡（edge case & 初值）

- **谜题误触**：任意错序 → 已点亮石整组 fade 重置 + toast「Sigil order disrupted」；玩家重来。离开房间同样重置。已通谜题房再进不再重解（门已开）。
- **重复 tap 同一石 / 多 tap**：点亮集合去重；集满 3 块正确即开门，多余 tap 忽略。
- **软锁**：谜题离开即重置（无永久锁）；房间前向推进可回退到已清房间；wipe 回安全点。
- **Party wipe（战斗失败）**：`combat_ended(lose)` → `SaveManager.load()` 取最后安全点 → 经 `PartyManager.restore` / `WardCodex.restore` 还原 → 回 Town（安全节点）。**只损失当前层进度**（clearedFloors 之前的保留），符合 ux-spec §2.2。
- **Boss 禁用 Run**：`isBoss=true` 时 Run 命令不可用（combat §7）。
- **满进度重玩**：`bossDefeated=true` 后 Sage 入口禁用（或提供通关回顾），不重复发 Stone Sigil（`WardCodex.attune` Set 语义，重复 attune 为 no-op，elements §7）。
- **存档配额失败**：localStorage 满/被禁 → `SaveManager.save` 优雅失败、会话内继续（save-load §7）。
- **战斗确定性**：同 `(seed, action 序列)` ⇒ 同结果（ADR-002）；战斗**不序列化**，reload 后重打该房即同种子同战（可 replay/测试）。
- **平衡初值**（占位，待 E8 spike 锁定）：affinity 1.5/0.67/1.0；variance ±10%；MP 成本 4–10；level cap 20；mini-boss xpValue~120；普通敌 xpValue 8–25。
- **设计红线自检**：元素亲和为对称 7 环（无主导元素）；无主导策略；无经济失衡；认知负荷低（每房一目标）。✅

---

## 8. 依赖与开放问题

### 8.1 上游依赖（收敛）
依赖 S1 Party-Jobs（编队/aptitude）、S2 Combat（战斗 state/Resolver/FSM/AI）、S3 Elements（亲和/WardCodex/Stone 解锁）、S4 Progression（XP/装备/共鸣）、S6 Save-Load（安全节点落盘）。组合层同 world-nodes。

### 8.2 交付物 Q3：与现有 autoload 的接口契约（伪代码骨架，非实现）

> 以下签名供 engineering-lead 对齐。**「复用」标 ✅，「需扩展/新增」标 ⚠️**。

**(a) 场景切换（Town/Dungeon）—— SceneManager / WorldDirector 扩展**
```gdscript
# SceneManager（扩展：Sprint1 只更新逻辑态，Sprint2 需真正切场景）
func go_to(node: String, params: Dictionary = {}) -> void:   # ✅ 已有，保留
    _current_node = node
    # ...（Town→safe save；Dungeon→设 floorIdx，非安全节点）保持不变
func get_run_state() -> Dictionary: return _run_state.duplicate(true)   # ⚠️ 新增：暴露只读副本
func get_world_state() -> Dictionary: return _run_state["worldState"]  # ⚠️ 新增

# WorldDirector（扩展：实例/移除 World 的子场景，保持 RunState 常驻）
func enter_town() -> void:
    SceneManager.go_to("Town")                 # 逻辑态 + 安全存档
    _swap_world_child("res://scenes/Town.tscn") # ⚠️ 新增：实例 Town.tscn 为 World 子节点
func enter_dungeon(floor_idx: int = -1) -> void:
    # ⚠️ 修复 GAP-4：无参时续到存档 floorIdx，而非永远 0
    var f := floor_idx if floor_idx >= 0 else SceneManager.get_world_state()["dungeon"]["floorIdx"]
    SceneManager.go_to("Dungeon", {"floorIdx": f})
    _swap_world_child("res://scenes/Dungeon.tscn", {"floorIdx": f})
func clear_floor(floor_idx: int) -> void:      # ✅ 已有：安全节点存档 + clearedFloors
    SceneManager.clear_floor(floor_idx)
func _swap_world_child(scene_path: String, params: Dictionary = {}) -> void:
    # ⚠️ 新增：移除当前 Town/Dungeon 子节点，实例新场景并作为 World.tscn 子节点加入
    # （架构 §2.2：World 常驻，Town/Dungeon 实例/移除，RunState 不重载）
    ...
```

**(b) 启动 CombatFSM + BattleResolver —— Dungeon 场景组装 BattleState**
```gdscript
# Dungeon.gd（场景脚本骨架）
func _enter_combat_room(room: Dictionary) -> void:
    if room["id"] in _session_cleared_rooms: return      # 本会话已清，跳过
    _start_battle(room["encounterId"], false)
func _start_battle(encounter_id: String, is_boss: bool) -> void:
    var party   := PartyManager.build_party_combatants()  # ⚠️ GAP-9 新增
    var enemies := _build_enemy_combatants(encounter_id)  # ⚠️ 读 EncounterDef+enemies.json
    var combatants := party + enemies
    var rng := RNGService.new()                            # ✅ 复用（每战实例化，非 autoload）
    rng.seed(_battle_seed(_floor_idx, _current_room_idx, is_boss))  # 确定性种子
    var battle_state := {
        "combatants": combatants,
        "queue": _initiative_order(combatants, rng),       # SPD 降序 + 种子平局决出
        "turnPointer": 0,
        "phase": BattleFSM.Phase.PreBattle,                # ✅ 复用 BattleFSM（RefCounted）
        "log": [], "isBoss": is_boss }
    # 启动 Battle.tscn 作为叠加层（add_child 到 root），永不被序列化
    var battle := load("res://scenes/Battle.tscn").instantiate()
    battle.setup(battle_state, rng, self)                  # self=结果回调目标
    get_tree().get_root().add_child(battle)                # ✅ 架构 §2.2 模式
    # Dungeon 场景状态（房间光标）因不被重载而保留，战后继续
```

**(c) 战斗结果回写 —— XP / 掉落 / 房间清 / Stone 解锁 / FloorClear**
```gdscript
func _on_battle_resolved(result: Dictionary) -> void:
    # result = { outcome:"win"|"lose", enemy_xp:int, drops:{gold,items} }
    if result["outcome"] == "lose":
        _reload_last_safe_save(); return                    # 回 Town 安全点
    # WIN
    var rs := SceneManager.get_run_state()
    ProgressionManager.apply_battle_xp(result["enemy_xp"], rs["party"])  # ⚠️ GAP-8 新增（平分配队）
    rs["runProgress"]["gold"] += result["drops"].get("gold", 0)
    # ... 道具入 inventory（去重/id 校验）
    PartyManager.sync_to_run_state(rs)                     # ⚠️ GAP-9 新增（level/xp/hp/mp 写回）
    _mark_room_cleared(_current_floor, _current_room_id)   # session 标记
    EventBus.progression_event.emit({"xp": result["enemy_xp"]})   # ✅ 复用 EventBus
    if _current_room_is_boss:
        WardCodex.attune("stone")                          # ✅ 复用：解锁 Stone 元素
        EventBus.codex_updated.emit({"sigil":"stone","action":"attune"})  # ✅
        rs["worldState"]["dungeon"]["bossDefeated"] = true
        SaveManager.save(rs, true)                         # ✅ sigil-attune 是安全节点
    if _floor_fully_cleared(_current_floor):
        WorldDirector.clear_floor(_current_floor)          # ✅ 安全节点自动存档
        _advance_floor_or_return_to_town()
```

**(d) 安全节点落盘 / 回城 / wipe 续档**
```gdscript
func _reload_last_safe_save() -> void:
    var rs := SaveManager.load()                            # ✅ 复用：取最后安全点
    if rs.is_empty(): rs = SceneManager.get_run_state()     # 兜底：内存态
    PartyManager.restore(rs["party"]); WardCodex.restore(rs["runProgress"]["codex"])  # ✅ 复用
    WorldDirector.enter_town()                              # ✅ 续档永落 Town（决策 2.6）
    # 显示「Defeated — returned to last safe point」toast（fade-only）
# 手动存档（Shrine / Pause@safe）：
#   SaveManager.save(SceneManager.get_run_state(), true)    # ✅ 复用，安全节点
```

**(e) 谜题 / 移动（节选）**
```gdscript
func _on_directional_input(dir: String) -> void:           # 对应 ux-spec §3 逻辑动作
    match dir:
        "ui_left":  _move_cursor(-1)
        "ui_right": _move_cursor(+1)
        "ui_up", "ui_down": _in_room_action(dir)           # 房内交互预留（如选石）
func _on_stone_tapped(element: String) -> void:            # PuzzleRoom
    if _puzzle_solved: return
    if element == _puzzle_order[_puzzle_progress]:          # ["ember","frost","storm"]
        _lit_stones.append(element); _puzzle_progress += 1
        _play_fade(_stone_node(element))                    # reduced-motion: fade/glow only
        if _puzzle_progress == _puzzle_order.size():
            _puzzle_solved = true; _open_door()             # fade 开门 + 标记 cleared
    else:
        _reset_puzzle()   # 整组重置 + toast「Sigil order disrupted」（决策 2.4）
```

### 8.3 交付物 Q4：复用清单（复用 vs 必须新增）

**✅ 复用 Sprint 1（直接调用，接口基本不变）**
| 模块 | 复用点 |
|---|---|
| `SceneManager` | `go_to` / `clear_floor` / `new_run_confirmed` / `current_node`（**扩展**：加 `get_run_state`/`get_world_state` 只读访问；`go_to` 内部不变） |
| `WorldDirector` | `enter_town` / `enter_dungeon` / `clear_floor`（**扩展**：加 `_swap_world_child` 真正切场景；`enter_dungeon` 无参续层） |
| `SaveManager` | `save(state, safe_node)` / `load()` / `has_save()` / `serialize` / `deserialize` / `migrate` / `CURRENT_VERSION` / `SAVE_KEY` —— **原样复用** |
| `ProgressionManager` | `add_xp` / `xp_for_level` / `equip`（**扩展**：加 `apply_battle_xp` 配队-wide + 写回） |
| `PartyManager` | `all_members` / `get_member` / `derive_stats` / `add_member`（**扩展**：加 `build_party_combatants` / `sync_to_run_state`） |
| `WardCodex` | `attune` / `discover` / `snapshot` / `restore` —— **原样复用**（Stone 解锁） |
| `ElementRegistry` | `affinity` / `strong_vs` / `weak_vs` / `ALL` —— **原样复用**（被 BattleResolver 用） |
| `RNGService` | `seed` / `draw_range` / `next_float`（每战 `new()`）—— **原样复用** |
| `BattleFSM` | `Phase` 枚举 / `can_transition` / `transition` / `is_over`（RefCounted，每战实例化）—— **原样复用** |
| `BattleResolver` | `resolve_action` / `attack_damage` / `elemental_damage`（纯函数）—— **原样复用** |
| `EnemyAI` | `choose_action(state, actor, rng)` —— **原样复用**（策略留待 balance spike 调） |
| `EventBus` | `scene_changed` / `save_event` / `codex_updated` / `progression_event` / `battle_event` —— **原样复用**（仅 UI/反馈，不改逻辑） |
| `AssetRegistry` | `get_content` / `load_content` / `validate_atlas` —— **原样复用**（读 encounters/enemies/dungeons 等） |

**⚠️ 必须新增 / 扩写**
1. **`Town.tscn` + `Town.gd`**：5 节点按钮 + 各节点叠加面板；经 `WorldDirector` 读写 worldState。
2. **`Dungeon.tscn` + `Dungeon.gd`**：房间轨道、移动、房间触发、FloorClear、回城、谜题、奖励、Boss 编排；含 `_start_battle` / `_on_battle_resolved` / `_reload_last_safe_save` / `_on_stone_tapped` 等。
3. **`World.tscn`** 确保常驻并承载 Town/Dungeon 子节点（架构 §2.2）。
4. **场景切换胶水**：`WorldDirector._swap_world_child`（实例/移除 World 子场景）。
5. **`SceneManager.get_run_state()` / `get_world_state()`** 只读访问器（GAP-3）。
6. **`PartyManager.build_party_combatants()` + `sync_to_run_state(run_state)`**（GAP-9）；`derive_stats` 占位公式待 balance spike 替换为真实成长曲线。
7. **`ProgressionManager.apply_battle_xp(total_xp, party)`**（GAP-8，平分配队 + 写回）。
8. **`content/encounters.json`**（新，`EncounterDef`）（GAP-6）。
9. **扩写 `content/dungeons.json`** 为 4 层 × RoomDef（GAP-5）。
10. **扩写 `content/enemies.json`**：补 `xpValue` 字段 + 补齐 ~6 敌 + Boss `Sigil-Twisted Warden`（GAP-7）。
11. **战斗启动协调**：Dungeon.gd 内 `_start_battle`（组装 BattleState + 实例化 Battle 叠加层 + 路由结果）；架构中的 `CombatController` 在 `Battle.tscn` 内每战实例化（非 autoload），此处只需「Dungeon→Battle 交接」。

### 8.4 开放问题与待主理人/工程拍板项（含已识别 GAP）

| # | 问题 / GAP | 影响 | 推荐处理 |
|---|---|---|---|
| GAP-1 | `SceneManager.go_to` Sprint1 只更逻辑态，未真切场景 | Sprint2 必须补真实场景交换 | WorldDirector `_swap_world_child` 实例 Town/Dungeon |
| GAP-2 | 逐房间状态无持久字段 | 房间光标/已清房追踪 | 作为 Dungeon 场景 session 状态（不进存档），避免脏续档跳房 |
| GAP-3 | `worldState` 私有于 `SceneManager._run_state`，场景脚本无访问器 | Town/Dungeon 读写世界态受阻 | 加 `get_run_state()`/`get_world_state()`（或 WorldDirector 代理） |
| GAP-4 | `enter_dungeon(floor_idx=0)` 永远从第 0 层开始 | Continue/重进地牢会掉回 F0 | 无参时续到 `worldState.dungeon.floorIdx` |
| GAP-5 | `dungeons.json` 仅 stub（无 rooms） | 地牢无法实例化 | 扩写为 4 层 × RoomDef |
| GAP-6 | 无 `EncounterDef` / `content/encounters.json` | 战斗编队无数据源 | 新增 `EncounterDef{id,enemyIds,isBoss,xpValue,drops}` |
| GAP-7 | `enemies.json` 缺 `xpValue` 且仅 2 敌（huskling/frostmote） | XP 流与编队缺失，world-nodes §6 要求未满足 | 补 `xpValue` 字段；补齐敌人阵容：**`Huskling`(physical) / `Frostmote`(Frost) / `Stoneling`(Stone,高DEF) / Storm-affinity 敌 / +1 普通敌 / Boss `Sigil-Twisted Warden`(xpValue~120)**。同时删除 `dungeons.json` 引用的不存在的 `smoke_encounter` |
| GAP-8 | `ProgressionManager` 无配队-wide XP + 写回 | 战斗 XP 无法落地存档 | 加 `apply_battle_xp` + 写回 run_state.party |
| GAP-9 | `PartyManager` 无 `build_party_combatants`/`sync_to_run_state`；`derive_stats` 占位 | 无法组装 BattleState | 新增两方法；`derive_stats` 待 spike 替换 |
| GAP-10 ✅已拍板 | **XP 曲线冲突**：`progression.md` `20*l^1.35` vs 代码/架构 `100*level` | 接口实现契约已定 | **已拍板：以代码 `100*level` 为准**（main-architecture + Sprint1 ProgressionManager 一致）。`progression.md` 旧公式 `round(20*l^1.35)` **留 E8 balance spike 统一修订，本 Sprint 不改动**（避免 sprint 间各写一份；GDD 不主动改 progression.md） |
| GAP-11 | 战斗种子逐次尝试差异 | replay 确定性边界 | 当前派生 nonce `seed+(floor*100+room*10+boss)` 已确定（§3.5）；逐尝试差异留未来（持久 attempt 计数） |
| **GAP-12** | **`RunState.party` 默认 `[]`（`SceneManager._default_run_state`）** | **垂直切片进地牢无 4 combatants，BattleResolver 跑不起来** | **New Run / 进 Town 前用 4 默认职业（Vanguard/Channeler/Skirmisher/Warden）种子化 `party`**（决策 2.7）；E9 开工前置 |
| O-1 | `foundSigils` 与 `codex.attunedSigilIds` 冗余 | 潜在双源 | 建议 WardCodex 为唯一功能真源；`foundSigils` 仅世界态 UI 用 |
| O-2 | 地牢内续档（Floor 进入=安全节点） | session-friendly 增强 | MVP 不采纳（续档永落 Town）；未来可选 |
| O-3 | 满进度后 Sage 入口行为 | UX | 禁用或提供通关回顾（推荐） |
| O-4 | 数值平衡（ATK/DEF/XP/掉落/AI 激进度） | 玩法手感 | 留 E8 balance spike 锁定 |
| O-5 | 内容数值与 E8 数值锁同源 | 两边各写一份数值 → 冲突 | **流程约定**：E9.3 先用「结构 + 占位数值」写 `dungeons.json`/`enemies.json`/`encounters.json`（保证 E9 能跑）；E8 balance spike 再覆写最终数值（ADR-003 数据驱动：改数据文件零代码改动）。切勿 E9 与 E8 各写一份 |

### 8.5 E9 七个接口点闭合对照表（给 engineering-lead，零返工用）

> 程基岩在 S2-DESIGN-01 后续提出的 7 个接口点，本 GDD 已全部显式闭合。下表为「接口点 → GDD 闭合位置 → 结论」的一一映射，E9 开工直接对照即可。

| # | E9 接口点 | GDD 闭合位置 | 闭合结论（设计已定） |
|---|---|---|---|
| 1 | Dungeon 地图表达模型（网格 vs 节点步进） | 决策 2.2（§2.3） | **节点步进推进**：每层房间轨道，ui_left/right 移光标，无网格/寻路/相机。决定 `dungeon_controller.gd` 走「轨道光标」结构，非网格坐标 |
| 2 | DungeonDef/RoomDef 最终 schema | §3.2（覆盖现有错位的 `floors:[{idx,encounters,isBoss}]`） | `RoomDef{ id, type∈{combat,puzzle,reward,boss}, encounterId, puzzleOrder, reward }`；4 层 × rooms；`bossRoom` 由 `type=="boss"` 推导。重写 `dungeons.json` |
| 3 | 编队/formation 数据归属 | 决策 2.9（§2.3）+ §3.3 | **独立 `content/encounters.json`**，`EncounterDef{id,enemyIds[],isBoss,xpValue,drops}`；`RoomDef.encounterId` 仅存引用，**不内联** |
| 4 | 战斗种子 / battleNonce 契约 | §3.5（BattleState 构造末段） | nonce **派生非持久**：`nonce=floor*100+room*10+(boss?1:0)`，`rng.seed((seed+nonce)&0x7FFFFFFF)`；同坐标⇒同战，满足 ADR-002；不存计数器、不进存档；逐尝试差异留未来 |
| 5 | New Run 默认组队 | 决策 2.7（§2.3）+ GAP-12 | **固定 4 职业**（Vanguard/Channeler/Skirmisher/Warden 各一）种子化 `RunState.party`；Dungeon 入口前 `party` 绝不为 `[]`；由 New Run 流程负责（非 Town 场景） |
| 6 | Town S2 切片范围 | 决策 2.8（§2.3） | S2 可交互 = {Rest, Sage, Shrine}；**锁定** = {Shop, Barracks}（灰显+toast「即将开放」）。对齐 E9.2 MVP 深度 |
| 7 | PuzzleRoom 交互契约 | §4.2（PuzzleRoom 交互契约段）+ 决策 2.4 | 3 石 **形状可读**（flame/snow/bolt + 标签，顺序显式可读、不依赖颜色）；错序**整组重置**；**离房也重置**（session，不进存档）；门开即解锁前进 |

**E9 开工前置（必须先做，否则垂直切片卡死）**：GAP-4（续层修复）、GAP-12（New Run 默认 4 人）、GAP-5/6/7（内容结构+占位数值）。其余 GAP 可在实现中并行消化。

---

*End of Town/Dungeon Scene-Level GDD (Sprint 2 · Route A). 原创 IP 合规：原创 Ward-Sigil 符号 + Underdog Stage；无 FF1/SE 资产。下游：engineering-lead（§8.2 接口契约、§8.3 复用清单、§8.5 七接口点闭合表）、content 作者（§8.4 GAP-5/6/7 内容扩写 + O-5 流程约定）。*
