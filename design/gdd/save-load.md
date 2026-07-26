# Save/Load & Session State GDD — EMBERVEIL (MVP)

> File: `design/gdd/save-load.md` · Owner: design-strategist · Status: Phase 2 MVP
> Upstream: concept §5.1, platform web / mini-game
> Scope: MVP = single local profile, autosave + manual. Cloud-save (L4) noted only.

## 1. 系统概述（目标与范围）
Define persistence of the run/session. Cross-cutting foundation: a single `RunState` schema that every other system serializes into. Realizes **Session-Friendly Depth** (quick resume) and prevents save-scum (safe-node-only writes). MVP = single profile, autosave + manual. Cloud-save (L4) is out of scope.

## 2. 核心规则
- **RunState** holds: `party[4 Hero]`, `runProgress` (gold/inventory/resonance/attuned/discovered), `worldState` (currentNode / dungeon progress), `settings` (audio/accessibility), `meta` (schemaVersion, timestamp, seed).
- **Autosave** triggers: enter Town, clear a dungeon floor, attune a sigil, complete Quest. (No mid-combat save.)
- **Manual save:** Town `Shrine` (and pause menu at safe nodes).
- **Load:** restores RunState; mid-combat battles are NOT persisted (reload to pre-battle safe point).
- **Versioning:** `schemaVersion` field; on load mismatch → block + message (no corrupt restore).

## 3. 数据模型与状态
- `RunState { schemaVersion, seed, party[Hero], runProgress, worldState, settings, savedAt }`
- `Hero` (persisted subset): jobId, level, xp, hp, mp, equipment; derived stats recomputed from Party-Jobs + Progression (not stored).
- Storage: `localStorage` key `emberveil.save.v1` (web mini-game); JSON; a few KB. Optional checksum.

## 4. 交互与输入（UX 流程）
- Pause menu → Save (safe nodes) / Load / Settings.
- On launch: if save exists → "Continue" + "New Run". New Run overwrites (single slot MVP).
- Settings include accessibility toggles (art-bible §9.1): colorblind-assist, reduced-motion, text-scale (100–125%).

## 5. 进度与成长
- Persists all growth from Progression / Elements / World; enables the "short session → resume" loop.

## 6. 内容清单（MVP）
- 1 save slot. Settings: music/sfx volume, colorblind-assist, reduced-motion, text-scale (100–125%).
- Schema version v1.

## 7. 边界与平衡（edge case & 初值）
- **Save-scum prevention:** writes only at safe nodes → cannot retry a lost battle by reload.
- **Corruption:** schemaVersion mismatch → refuse load (no crash). Optional checksum.
- **Quota:** localStorage may be full/blocked → graceful "save failed" + continue in-session.
- **Privacy:** local only; no PII. (Cloud = L4.)
- **Single slot:** New Run overwrites — confirm dialog to avoid accidental loss.

## 8. 依赖与开放问题
- Depends on (serializes): **Party-Jobs, Progression, Elements, World-Nodes**; Combat outcome only (mid-state NOT persisted, by design).
- Open: single vs multiple slots; cloud-save (L4); checksum strength.
