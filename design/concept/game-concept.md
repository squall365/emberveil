# EMBERVEIL — Game Concept Document (Phase 1)

> **Working Title:** *EMBERVEIL* (provisional — subject to IP/title clearance)
> **World:** Veyra
> **Status:** Phase 1 — Concept / Ideation
> **Author:** design-strategist (文策渊 / Vince Coyer)
> **Review Intensity:** FULL
> **Platform:** Web / 小游戏 (instant-play web mini-game)
> **Engine:** Godot 4 (HTML5 export)
> **One-line Concept:** An original-IP, turn-based party JRPG that captures the *type* of Final Fantasy I — a small band of chosen heroes, class-based tactics, and elemental magic — expressed entirely through original world, characters, art, and systems.

---

## 0. Concept Summary

*EMBERVEIL* is a turn-based, command-driven party JRPG built for the web. The player leads a band of four heroes across the fractured world of **Veyra**, where the elemental balance is held together by **Ward-Sigils** — original elemental anchors that have begun to fail. Combat is deliberate and menu-driven, depth comes from *how* the four jobs and seven elements combine, and the world is explored through handcrafted towns, dungeons, and (later) an overworld with airship-like traversal. Everything is original expression: no Square Enix story, characters, music, names, or assets are reproduced. We retain only the *genre DNA* — the satisfying shape of a classic party JRPG — and rebuild it from scratch.

---

## 1. Design Pillars

| # | Pillar | One-line Rationale (tied to original-IP FF1-flavored goal) |
|---|--------|------------------------------------------------------------|
| 1 | **Party Synergy Over Individual Power** | The four-hero band is the unit of play; tactical depth lives in how jobs and roles combine — echoing FF1's "four chosen warriors" *feel* without copying any character. |
| 2 | **Readable, Command-Driven Tactics** | Turn-based, menu-driven combat that is learnable in minutes but rewards foresight — capturing FF1's deliberate pacing, adapted for short web sessions with zero twitch-skill barrier. |
| 3 | **Elemental Literacy as Mastery** | The seven-element system is the through-line for combat *and* world puzzles, honoring the retained elemental-magic skeleton as an original "Ward-Sigil" trope rather than borrowed crystals. |
| 4 | **Explorable, Handcrafted World** | Towns, dungeons, and (later) overworld/airship traversal give a world worth saving — retaining the journey-structure skeleton in fully original form. |
| 5 | **Session-Friendly Depth** | Built for 3–10 minute web-play bursts that each deliver a complete beat (a floor cleared, a sigil attuned), so the genre's long arc fits a mini-game cadence. |

---

## 2. MDA Analysis

### 2.1 Mechanics (the rules & systems)
- **Party & Jobs:** 4 fixed party slots; each slot is assigned a **Job** from a roster. Each Job carries a stat-growth curve, a command kit, and elemental affinities. (Job-change / upgrade is an expansion-layer feature, not MVP.)
- **Turn-Based Command Combat:** Initiative-ordered, ATB-free. Per turn each hero issues one command: `Attack`, `Skill` (job ability), `Elemental` (spell drawn from an attuned Ward-Sigil), `Defend`, or `Item`.
- **Seven-Element System:** `Ember` (fire), `Frost` (ice), `Storm` (lightning), `Stone` (earth), `Gale` (wind), `Lumen` (holy), `Umbra` (dark). Elements relate via an affinity matrix (e.g., Ember strong vs Frost, weak vs Storm) governing damage modifiers.
- **Ward-Sigils (macguffin):** Equipable/attunable elemental sources that *grant* the spell list and define the world's balance. Discovering/attuning a Sigil reshapes the player's toolkit — the original stand-in for the "crystals" trope.
- **Progression:** XP & leveling, Job mastery, equipment, and Sigil attunement.
- **World Nodes:** `Town` (rest / shop / quest hub), `Dungeon` (combat + puzzle + Sigil reward), `Overworld` (traversal, expansion), `Airship-like traversal` (expansion — original "Driftwing").
- **Resources:** HP, MP (or per-Sigil focus), consumables, gold.

### 2.2 Dynamics (how the systems behave in play)
- Players **compose** a party that covers role balance (front-line / damage / healing / support) and elemental coverage; the right job+element mix beats brute force.
- Encounters reward **pre-planning**: reading enemy affinities and choosing elements/commands ahead of the turn, not reacting at reflex speed.
- Exploration produces a **discovery-driven power curve**: new Sigils and Jobs unlocked in the world directly expand viable strategies, so "getting stronger" is tied to "seeing more of Veyra."
- **Short-loop satisfaction**: each session resolves a discrete beat (clear a floor, attune a Sigil, finish a town quest), preventing the genre's typical "must play 40 hours" friction.
- **Risk/reward in dungeons**: pushing deeper for better loot/Sigils vs. retreating to town to bank progress.

### 2.3 Aesthetics (targeted emotional responses)
Prioritized from the MDA aesthetic vocabulary:
- **Challenge (primary):** fair, solvable, tactical combat and puzzles — the core pleasure.
- **Discovery (high):** new Jobs, Sigils, map reveals, and lore fragments.
- **Fellowship (medium-high):** the four-hero band as a "found family"; relatedness expressed in-fiction (party framing, light banter, shared stakes).
- **Sensation (medium):** satisfying spell/impact feedback and a warm, legible art style.
- **Narrative (medium):** light but present world-saving stakes carried by the Ward-Sigil premise.
- **De-prioritized:** *Submission* (no idle/grind-for-its-own-sake loops) and *Expression* (no deep cosmetic/UGC systems at MVP).

---

## 3. Verb-First Core Verbs

The 3–5 verbs that define moment-to-moment play:

| Verb | What the player does | Why it's core |
|------|----------------------|---------------|
| **Command** | Issuing a tactical order each turn (Attack / Skill / Elemental / Defend / Item). | Defines the FF1-flavored, deliberate combat beat — the heart of the game. |
| **Compose** | Assembling and attuning the four-hero party, jobs, and elements. | Realizes the *Party Synergy* pillar; the "build" verb that gives agency before battle. |
| **Explore** | Traversing towns, dungeons, and (later) the overworld. | Carries the *Explorable World* pillar and the Discovery aesthetic. |
| **Grow** | Leveling jobs, attuning Sigils, acquiring gear. | Delivers Competence (SDT) and the satisfying progression curve. |
| **Bond** | Experiencing the four-hero band as a unit with shared stakes. | Carries the Fellowship aesthetic and Relatedness (SDT). |

---

## 4. Player Psychology

### 4.1 Self-Determination Theory (SDT)
- **Autonomy:** Free party composition, Job assignment, exploration order, and multiple viable solutions to encounters and puzzles.
- **Competence:** Clear, immediate feedback (damage numbers, affinity hits), a learnable elemental matrix, and visible mastery markers (levels, Sigil attunement, Job mastery).
- **Relatedness:** The four-hero band framed as a chosen family; light in-fiction banter and a shared "save Veyra" goal; (expansion) optional async social features for web.

### 4.2 Bartle Player Types (who the game serves)
- **Achievers:** Job mastery trees, completion tracking, post-game superbosses and leaderboards (expansion).
- **Explorers:** Dungeons, overworld, hidden Sigils, lore fragments, secret routes.
- **Socializers:** The in-fiction fellowship framing; (expansion) async sharing / friend-code boss challenges on web.
- **Killer:** Served *least* at MVP; addressed later via speedrun leaderboards and competitive superbosses. (Flagged so we don't over-invest pre-validation.)

### 4.3 Flow & Challenge Balance
- A **graded difficulty curve** keeps challenge inside the flow channel: early encounters teach one system at a time; combined-system pressure arrives only after each system is understood.
- **Short loops** (3–10 min) reduce frustration exposure; failure is cheap and quickly retryable.
- **Optional hard content** (mini-bosses, post-game) provides the upper challenge ceiling for players who want it, without gating the main path.

---

## 5. Scope Tiers

### 5.1 MVP — Vertical Slice (must ship first)
> Goal: prove the core loop end-to-end on web. Includes the mandated: **4-hero party + turn-based command combat + 1 dungeon + 1 town + elemental magic.**

- **4 starting Jobs** (original names, e.g., *Vanguard* / *Channeler* / *Skirmisher* / *Warden*) with distinct kits and affinities.
- **Turn-based command combat:** full command menu, basic enemy AI, win/lose resolution, initiative order.
- **Elemental magic:** at least 4 elements usable at MVP (Ember / Frost / Storm / Stone) with a defined affinity matrix and 2–3 attunable Ward-Sigils granting spells.
- **1 Town:** rest, basic shop, and a quest-giver that frames the dungeon objective.
- **1 Dungeon:** ~3–5 floors of combat encounters + one environmental puzzle + one mini-boss + one Ward-Sigil reward.
- **Systems:** XP/leveling, equipment, save/load, basic HUD, Godot 4 HTML5 build, tutorialized first 10 minutes.

### 5.2 Expansion Layers (post-MVP, tiered)
- **L2 — Depth:** More Jobs (6–8 total), Job-change / upgrade, 3–5 additional dungeons, deeper elemental puzzle design.
- **L3 — World:** Overworld map, airship-like traversal (original "Driftwing"), additional towns and hubs.
- **L4 — Story:** Narrative campaign / story arcs, faction system, text-driven lore and character moments.
- **L5 — Post-Game & Meta:** Endless dungeon, superbosses, NG+, leaderboards / speedrun (Killer-type content), optional async social challenges.

---

## 6. Visual Anchors (for the Art-Director)

> Handoff note: the art-director is spawned by the lead using these seeds. Do **not** copy FF1's specific sprites, UI layout, font, or iconography — see §6.4.

### 6.1 Overall Tone
"Cozy-but-epic, handcrafted fantasy." Warm and approachable, yet with real stakes — a small band saving a fractured world. Must remain **legible at a small web viewport** and performant in an HTML5 build.

### 6.2 Palette Directions (named, with hex seeds)
Three candidate directions; the art-director should pick one as the master and use the others as accents/alternates.

1. **"Ember Dusk"** (warm, intimate, journey-at-sunset feel)
   - Background / shadow: `#2B1B2E` (deep plum)
   - Primary accent: `#E8743B` (ember orange)
   - Secondary accent: `#3FA7A0` (teal)
   - Highlight / parchment: `#F2D9A0`

2. **"Frost & Lumen"** (cool, sacred, clarity)
   - Background: `#16243B` (midnight blue)
   - Primary accent: `#6FB7E8` (frost blue)
   - Secondary accent: `#F4C95D` (lumen gold)
   - Highlight: `#E8EEF2` (snow white)

3. **"Verdant Ward"** (earthy, grounded, ancient)
   - Background: `#1E2A1E` (deep green-black)
   - Primary accent: `#7BA05B` (moss)
   - Secondary accent: `#C98A3B` (clay)
   - Shadow accent: `#2E2438` (umbra violet)

### 6.3 Line / Shape Language & Reference Moods
- **Shapes:** Soft, rounded forms for characters and props (approachable, storybook); crisp geometric constructions for the **Ward-Sigils** and elemental UI (readability + "magical system" feel).
- **Rendering:** Recommend a *limited-palette vector with subtle pixel texture* — gives a handcrafted look while staying performant and scalable for web.
- **Reference moods:** "storybook ink," "cozy 16-bit fantasy" (modern indie sensibility, **original** execution), "limited-palette pixel." Think warm, readable, and characterful — not NES-authentic.

### 6.4 Explicit "Steer Clear Of" (original-IP guardrails)
The art-director must **NOT** reproduce any of the following FF1-specific expressions:
- FF1's specific **sprite silhouettes / character designs** and the 8 classic job icons (Warrior, Black/White Mage, etc.).
- The FF1 **battle-scene composition** (enemies on the right, party on the left, command window pinned to the bottom).
- The FF1 **menu/HUD layout**, the specific pixel font, and the NES 8×8 tile aesthetic.
- The **crystal iconography** and any Square Enix trademarked names, logos, or symbols.
- The exact **elemental icon set** (fire/ice/bolt/etc. as drawn in FF1).

**Instead:** build an original **Ward-Sigil language** — unique geometric marks per element — and an original party/HUD composition. The *idea* of "elemental anchors that hold the world" is free to use; the *specific look* must be ours.

---

## 7. Original-IP Compliance Notes (FULL-review gate)

| Retained (genre *type*, free to use) | Avoided (specific *expression*, must not copy) |
|---|---|
| Turn-based, command-driven party combat | FF1's battle layout, menus, sprites, font |
| 4-hero party + class/job system | FF1's named jobs & character designs |
| Elemental magic (fire/ice/lightning/earth/wind/holy/dark) | FF1's specific spell names, icons, and visual effects |
| Towns / dungeons / overworld / airship-like traversal | FF1's specific maps, world layout, airship art |
| Elemental macguffin framing (crystals/rites) | FF1's Crystal narrative, names, and iconography |

All names in this document (EMBERVEIL, Veyra, Ward-Sigils, Driftwing, Job names) are **original working terms** and will pass through title/IP clearance before ship. No Square Enix copyrighted material is reproduced.

---

## Appendix A — Original Glossary (working terms)
- **Veyra** — the world.
- **Ward-Sigils** — original elemental anchors (stand-in for "crystals"); grant spells and hold world balance.
- **Ember / Frost / Storm / Stone / Gale / Lumen / Umbra** — the seven original element names.
- **Driftwing** — original airship-like traversal (expansion).
- **Jobs (MVP):** *Vanguard* (front-line), *Channeler* (elemental damage), *Skirmisher* (agile damage/support), *Warden* (healing/defense).
