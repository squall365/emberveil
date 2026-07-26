# World Nodes GDD — EMBERVEIL (MVP)

> File: `design/gdd/world-nodes.md` · Owner: design-strategist · Status: Phase 2 MVP
> Upstream: concept §2.1 / §5.1, art-bible §5 / §6
> Scope: MVP = 1 Town hub + 1 Dungeon. Overworld + Driftwing (L3) noted only.

## 1. 系统概述（目标与范围）
Define the MVP world structure: **1 Town hub + 1 Dungeon**. Realizes **Explorable, Handcrafted World** and the Session-Friendly loop (one floor / one sigil = one complete beat). Overworld map + airship-like `Driftwing` traversal (L3) are out of scope.

## 2. 核心规则
- **Town (hub):** nodes = `Rest` (full heal), `Shop` (Progression), `Barracks` (Party-Jobs edit), `Sage` (Quest: dungeon objective + start), `Shrine` (Save-Load). Safe zone — no random encounters.
- **Dungeon:** a linear-ish node graph of `Floor`s (3–5 MVP). Each floor = sequence of `Room`s: `CombatRoom` (Combat), `PuzzleRoom` (Elements gate), `RewardRoom` (chest / sigil), `BossRoom` (mini-boss + Stone Sigil reward).
- **Gating:** Dungeon entrance requires Quest accepted; Stone Sigil dropped by mini-boss → unlocks Stone element (Elements).
- **Node state:** cleared floors, found sigils, opened chests persisted (Save-Load).

## 3. 数据模型与状态
- `WorldState { currentNode, townVisited, dungeon{ dungeonId, floorIdx, clearedFloors[], foundSigils[], chestsOpened[], bossDefeated } }`
- `Room { id, type, payload(ref combat/encounter/puzzle/reward), cleared(bool) }`
- `DungeonDef { id, floors[Room[]], bossRoom }`

## 4. 交互与输入（UX 流程）
- Town: tap a node → action.
- Dungeon: advance floor→floor; enter a room → triggers its system (Combat / Puzzle); on clear, advance. Map shown minimally (art-bible: low UI density, one beat = one goal).
- Puzzle room: activate sigil-stones in element order (shape-readable) → door opens.

## 5. 进度与成长
- Each cleared floor / won battle → Progression XP + possible gold/item.
- Mini-boss → Stone Sigil (Elements attune) + big XP — the "discovery = power" beat.

## 6. 内容清单（MVP）
- Town: **Hearthmoor** (original name). Nodes: Inn (Rest), Market (Shop), Barracks (Party), Sage (Quest), Shrine (Save).
- Dungeon: **The Sundered Ward** (3–5 floors): Combats (Huskling / Frostmote / Stoneling, + Storm foe), 1 Puzzle (Ember→Frost→Storm stone order), chests, mini-boss `Sigil-Twisted Warden` → Stone Sigil.

## 7. 边界与平衡（edge case & 初值）
- **Save only at safe nodes** (Town, floor-clear) → prevents mid-combat save-scum (anti-abuse).
- **Backtracking:** allowed to Town via Shrine/exit; dungeon progress persists.
- **Soft-lock:** party wipe in dungeon → reload last safe save (Town or floor entry); no loss beyond that floor.
- **Puzzle unsolvable:** stones reset on leaving the room; no permanent lock.
- **Scope:** exactly 1 town + 1 dungeon at MVP.

## 8. 依赖与开放问题
- Depends on: **Party-Jobs, Combat, Elements, Progression, Save-Load** (composes all five).
- Open: dungeon length (3 vs 5 floors — recommend 4); puzzle difficulty; multiple towns (L3 overworld).
