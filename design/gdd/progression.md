# Progression GDD — EMBERVEIL (MVP)

> File: `design/gdd/progression.md` · Owner: design-strategist · Status: Phase 2 MVP
> Upstream: concept §2.1, art-bible §4.2 (texture/UI budget)
> Scope: MVP linear growth — XP/level, equipment, gold, inventory, Ward-Sigil Resonance. Job mastery trees (L2) and NG+ (L5) noted only.

## 1. 系统概述（目标与范围）
Define how the party grows: XP/level, equipment, gold, inventory, and Ward-Sigil Resonance. Realizes **Session-Friendly Depth** & **Competence (SDT)**. MVP is linear; job mastery trees (L2) and NG+ (L5) are out of scope.

## 2. 核心规则
- **XP:** on Combat win, each hero gains `sum(enemy.xpValue)` (split evenly; participants may get a small bonus). `LevelUp` when `xp ≥ xpToNext(level)`.
- **xpToNext(l)** = `round(20 * l^1.35)`, MVP cap `level 20`.
- **LevelUp:** apply `growthPerLevel` (Party-Jobs §3) to base stats; full heal on level.
- **Equipment:** weapon / armor / accessory with stat mods; buy/sell in Town shop (gold). One of each slot per hero.
- **Resonance:** per element 0–5; +1 on attune, or defeating ≥3 enemies of that element in a session, or a use-threshold. Scales Elemental power (Elements §2).
- **Gold & Items:** from combat + chests; items from shop/loot.

## 3. 数据模型与状态
- `HeroProgress { level, xp, equipment{weapon,armor,accessory} }` (base stats derived from Job + growth; not stored)
- `RunProgress { gold, inventory[itemId:qty], codexResonance Map<element,0..5>, attunedSet, discoveredSet }`
- `ItemDef { id, type(consumable|equip), mods{}, cost, sell }`

## 4. 交互与输入
- Level-up: automatic on XP threshold (toast).
- Equipment: Town menu; equipping swaps mods live.
- Shop: Town `Market`; buy/sell with gold.
- Resonance: passive (no action); shown in Codex panel.

## 5. 进度与成长
- This system IS the growth; feeds Combat (stats) and Elements (resonance).
- Town `Rest` = full HP/MP restore (free) — the MVP "bank progress" beat.

## 6. 内容清单（MVP）
- Items: `Herb` (heal 30% HP, cost 20), `Ember Tonic` (heal 30% MP, 25), `Bulk Salve` (heal all 20%, 60, L2).
- Equipment (sample): `Greatblade` (+ATK6), `Tower Shield` (+DEF5), `Catalyst Orb` (+MAG5), `Glaive` (+ATK5,+SPD2), `Tome-Shield` (+DEF4,+RES4), `Feather Mantle` (+SPD3), plus 2–3 armor tiers.
- Enemy `xpValue` ~ 8–25; mini-boss ~ 120.

## 7. 边界与平衡（edge case & 初值）
- **Level cap 20** bounds stats (anti power-creep).
- **Resonance cap 5** (+50% max).
- **Inventory cap** (e.g., 99/stack, 30 slots) prevents hoarding exploit.
- **Gold sink** = shop; sell price < buy price (no dupe economy).
- **Grind floor:** XP only from combat/events, not idle → no Submission loop (design pillar respected).
- **Dominance:** spread growth; no single stat path dominates (flag tuning).

## 8. 依赖与开放问题
- Depends on: **Party-Jobs** (growth curves, equip slots), **Elements** (resonance element set), **Combat** (XP source, item drops), **World-Nodes** (shop/rest/chests), **Save-Load** (persists progress).
- Open: XP split rule; resonance exact gain triggers; shop price curve; inventory size.
