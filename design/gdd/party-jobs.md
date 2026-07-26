# Party & Jobs GDD — EMBERVEIL (MVP)

> File: `design/gdd/party-jobs.md` · Owner: design-strategist · Status: Phase 2 MVP
> Upstream: concept §2.1 / §3, art-bible §8.1
> Scope: MVP = 4-hero party, 4 original jobs. Job-change / upgrade = L2 (not expanded here).

## 1. 系统概述（目标与范围）
Define the 4-hero party and the MVP job roster. Realizes the pillar **Party Synergy Over Individual Power**: the band is the unit of play; tactical depth comes from how jobs + elements combine, not from any single hero. MVP = fixed party size 4, assignable jobs (default one of each; duplicates allowed with a balance note). Job-change / upgrade trees are L2 and are NOT specified here.

## 2. 核心规则
- Party size = **4** slots. Each slot holds exactly one Job.
- Each Job defines: base stats, per-level growth, command kit, elemental aptitude per element (0–1.2), 1–2 Skills, starting gear.
- Core stats: `HP, MP, ATK, DEF, MAG, RES, SPD`.
- `aptitude[elem]` scales that hero's Elemental spell output (see Combat §2 / Elements §2). `0` = hero cannot cast that element.
- Equipment (Progression §2) adds stat modifiers on top of base+growth.
- Default party = one of each MVP job (Vanguard / Channeler / Skirmisher / Warden).

## 3. 数据模型与状态
- `Job { id, name, baseStats{HP,MP,ATK,DEF,MAG,RES,SPD}, growthPerLevel{...}, kit[commands], aptitude{elem:coef}, skills[SkillRef], startGear[ItemRef] }`
- `Hero { slot, jobId, level, xp, hp, mp, equipment{weapon,armor,accessory}, }` — derived stats are recomputed from Job + Progression at runtime (not stored).
- MVP Jobs:

| Job | Role | Base (HP/MP/ATK/DEF/MAG/RES/SPD) | Growth / Lv | Kit | Aptitude E/F/St/Sto/G/L/U | Skills |
|---|---|---|---|---|---|---|
| Vanguard | Front / Tank | 120/10/14/12/4/10/8 | HP+18, DEF+2, ATK+2 | Attack, Skill, Defend, Item | 0.2/0.2/0.2/0.3/0/0/0 | `Bulwark` (party DEF buff), `Taunt` (force-target) |
| Channeler | Elemental Dmg | 70/40/6/5/16/9/10 | MAG+3, MP+6 | Attack, Skill, Elemental, Defend, Item | 1.0/1.0/1.0/1.0/0.8/0.9/0.8 | `Surge` (next spell +30%), `Wardlight` (Lumen heal, L2) |
| Skirmisher | Agile Dmg / Support | 85/20/13/7/9/8/14 | SPD+2, ATK+2 | Attack, Skill, Elemental, Defend, Item | 0.6/0.5/0.7/0.4/0.9/0.3/0.3 | `Flit` (extra-turn chance), `Mark` (target +dmg taken) |
| Warden | Heal / Defense | 95/30/8/10/11/11/9 | HP+10, RES+2, MP+4 | Attack, Skill, Elemental, Defend, Item | 0.3/0.4/0.3/0.5/0.2/1.0/0.6 | `Mend` (heal ally), `Aegis` (shield ally) |

*(Numbers are MVP initial suggestions; a balance pass is required — see index.md open decisions.)*

## 4. 交互与输入（UX 流程）
- Party composed at run start (default roster) and re-editable in Town (`Barracks` node, World-Nodes §6).
- In Combat, each hero's `kit` populates that hero's command dock (Combat §4, Underdog Stage).
- Aptitude is surfaced subtly: heroes with `aptitude[elem] > 0` can cast that element's Codex spells; the dock greys impossible casts (no sigil / 0 aptitude / no MP).

## 5. 进度与成长
- Levels (Progression §2) apply `growthPerLevel` to base stats; equipment (Progression) adds modifiers.
- Job mastery trees / job-change = L2 — out of MVP scope.

## 6. 内容清单（MVP）
- 4 Jobs as above.
- Starting gear (original silhouettes per art-bible §8.1): Vanguard `Tower Shield` + `Greatblade`; Channeler `Catalyst Orb`; Skirmisher `Glaive` + `Feather Mantle`; Warden `Tome-Shield`.
- Element set used for aptitude = the 7-element enum (Elements §2); MVP playable subset = Ember/Frost/Storm/Stone.

## 7. 边界与平衡（edge case & 初值）
- **Duplicates:** 4×Channeler is technically possible. Mitigant = enemy affinity variety forces coverage; recommend an MVP rule "max 1 per job" to prevent a 4-DPS dominant comp. (Open decision — index.md.)
- **Aptitude = 0 elements** are simply uncastable (greyed), never an error state.
- **Stat floor:** all stats ≥ 1 after growth + equipment.
- **Level cap 20** bounds growth (Progression §7).
- **Elemental identity:** aptitude keys use the exact element enum (no typos / aliases) — consistency enforced via Elements §2.

## 8. 依赖与开放问题
- Depends on: **Elements** (element enum for aptitude keys), **Progression** (equipment + leveled stats), **Save-Load** (persists party/hero state).
- Open: default-party lock? max-1-per-job rule? exact aptitude coefficients; job-change (L2).
