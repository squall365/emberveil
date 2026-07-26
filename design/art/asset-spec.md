# EMBERVEIL — Asset Specification (Phase 4 · Pre-Production)

> **World:** Veyra · **Engine:** Godot 4 (HTML5 / WebGL2) · **Platform:** Web / 小游戏 (instant-play)
> **Status:** Phase 4 — Asset Spec (FULL review) · **Owner:** art-director (林绘澄 / Lin Wayson)
> **Upstream authority:** `design/art/art-bible.md` (Nine Sections) · `design/art/accessibility.md` · `docs/architecture/main-architecture.md` §2.5 / §5 · `design/gdd/*`
> **Hard IP rule:** No Square Enix / FF1 sprites, UI layout, font, crystal iconography, or trademarked assets. Original Ward-Sigil language & Underdog Stage composition only.

---

## 0. Scope, Method & Budget Caps

This spec covers **MVP vertical-slice assets only**. L2+ (more jobs, Gale/Lumen/Umbra enemies, overworld, Driftwing) is out of scope. All assets are authored to the Art Bible's visual identity and the architecture's hard web budget.

**Settled hard caps (architecture §5 + art-bible §9.4):**

| Cap | Value | Enforcement |
|---|---|---|
| Texture atlases | ≤ **4 × 1024²** | Atlas audit (CI, fail build) |
| Shared grain | **1 × 128²** (repeat-wrap, never duplicated per-asset) | Shared overlay |
| Decoded texture memory | **≤ 16 MB** | Atlas audit |
| Master palette | **≤ 48 colors** (12 named + derived tints/shades) | Palette validator |
| Format | WebP / PNG only (no JPG) | Export preset |
| Viewport | Safe **360×640**; hit targets **≥ 44×44px** | Layout test |
| Mipmaps | ON for env/UI; OFF for crisp sigils (characters: OFF, see §3) | Per-texture flag |

**Original-IP compliance:** Every asset below is original expression. Ward-Sigils (§7.3 grammar), Underdog Stage, soft-rounded/crisp-geometric split, and original job/world names are the only allowed stand-ins. No FF1 silhouettes, pixel font, crystal art, or battle composition.

---

## 1. Entity Inventory (MVP)

### 1.1 Hero Jobs (4) — soft-rounded grammar, shared "ember-thread" band accent
- `hero_vanguard` — idle + battle pose (tower-shield-cape hybrid, compact greatblade, visor crest)
- `hero_channeler` — idle + battle pose (floating catalyst orb, cowl, asymmetric sleeve)
- `hero_skirmisher` — idle + battle pose (glaive, feathered mantle, dynamic lean)
- `hero_warden` — idle + battle pose (tome-shield, cylindrical pauldrons, barrier trim)

### 1.2 Enemies (6 types) + 1 Mini-boss — sharper/fractured silhouettes (art-bible §8.2)
Designed so all **4 MVP elements (Ember/Frost/Storm/Stone)** are represented for the Elemental-Literacy pillar, using **palette-swap tinting** (§4.2) instead of new silhouettes wherever possible.

| Enemy | Affinity | Build strategy |
|---|---|---|
| `enemy_huskling` | neutral (physical) | Base hunched-fractured silhouette |
| `enemy_frostmote` | Frost | Original faceted ice-shard body |
| `enemy_stoneling` | Stone | Blocky layered-strata body, high-DEF read |
| `enemy_stormwretch` | Storm | Angular bolt-tree body |
| `enemy_emberwretch` | Ember | **Palette-swap of `huskling`** + ember cracks (covers Ember element) |
| `enemy_stoneling_brute` | Stone | **Scaled variant of `stoneling`** (larger, ornamental fracture) |
| `boss_sigil_warden` | — | `Sigil-Twisted Warden` — unique large sprite, cracked Ward-Ring corruption (art-bible §8.2) |

### 1.3 Town — Hearthmoor (hub, safe zone)
- **5 building facades (soft-rounded, handcrafted):** `town_inn` (Rest), `town_market` (Shop), `town_barracks` (Party), `town_sage` (Quest), `town_shrine` (Save).
- **Ambient props (~6):** `prop_lantern` (light pool), `prop_signpost`, `prop_barrel`, `prop_crate`, `prop_bench`, `prop_well`.
- **Shrine save marker:** `ui_save_icon` (original closed-ward-ring + ember core; NOT a crystal).

### 1.4 Dungeon — The Sundered Ward (4 floors, linear-ish)
- **Tiles (dungeon):** `tile_dungeon_floor`, `tile_dungeon_wall`, `tile_dungeon_void` (background), `tile_lightpool` (ember-brazier glow).
- **Props (~10):** `prop_brazier` (light pool), `prop_ward_fragment` (broken), `prop_moss_stone`, `prop_pedestal` (attunement — crisp-geometric), `prop_sigil_stone` (puzzle — crisp-geometric), `prop_chest` (reward), `prop_gate` (door), `prop_pillar`, `prop_rubble`, `prop_banner`.
- **Puzzle room:** 3 in-world sigil-stones (Ember→Frost→Storm order) reuse `prop_sigil_stone` tinted per element (crisp-geometric Ward-Sigil).
- **Boss room:** arena dressing reuses brazier/pillar/rubble + `boss_sigil_warden`.

### 1.5 Ward-Sigils (full 7-set; MVP uses 4)
`fx_sigil_ember`, `fx_sigil_frost`, `fx_sigil_storm`, `fx_sigil_stone`, **`fx_sigil_gale`**, **`fx_sigil_lumen`**, **`fx_sigil_umbra`**.
MVP-attuned = Ember/Frost/Storm/Stone (Town start + dungeon reward). Gale/Lumen/Umbra are system-ready (codex display only). All built from **Ward-Ring + inner glyph** (art-bible §7.3). Plus `fx_sigil_corrupt` (cracked-ring variant for the mini-boss emblem).

### 1.6 UI Components (Underdog Stage + menus)
- **Command chips (soft-rounded):** `ui_chip_attack`, `ui_chip_skill`, `ui_chip_elemental`, `ui_chip_defend`, `ui_chip_item` (9-slice background + icon glyph each); `ui_chip_run`, `ui_chip_settings` (top ribbon).
- **Party medallions (bottom dock):** `ui_medallion_frame` ×4 (one per hero) + `ui_medallion_arc` (HP/MP ring, not bars) + `ui_medallion_selected` (lift glow).
- **Status badges (crisp-geometric, shape-distinct):** `ui_badge_slow`, `ui_badge_guard`, `ui_badge_mark`.
- **HUD ribbon (top):** `ui_turn_pip_ally` (round), `ui_turn_pip_enemy` (sharp), `ui_ribbon_bg`, `ui_floor_label`.
- **Settings UI:** `ui_panel` (soft-rounded), `ui_toggle`, `ui_slider`, `ui_tab`.
- **Ward Codex panel:** `ui_codex_grid` + sigil thumbnails (reuse §1.5 sigils).
- **VFX (Atlas C, shader-glow where possible):** `vfx_spark`, `vfx_slash`, `vfx_ignite` (fade-only), `vfx_heal`, `vfx_shield`, `vfx_number_bg`, `vfx_damage_pop`, `vfx_lowhp_pulse`.

### 1.7 Environment Tiles (top-level)
- **Town tiles:** `tile_town_ground`, `tile_town_sky` (golden-hour horizon), `tile_town_foliage`.
- **Dungeon tiles:** see §1.4 (`tile_dungeon_*`, `tile_lightpool`).

---

## 2. Per-Asset Specification

> **Columns:** Ref size = source sprite region (scaled at runtime via Control nodes, never fixed-res). Palette = Master (Ember Dusk) or named Alternate; all within the global ≤48 master. Grain = shared 128² overlay at 8–15% (all painted surfaces). Shape = soft-rounded (SR) vs crisp-geometric (CG).

### 2.1 Heroes (Atlas A — Characters)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `hero_vanguard` (idle/battle) | 128×160 ea | A | Master (+ Clay armor) | yes | SR | 2–3 value steps, Bayer dither | 2 (idle, battle) |
| `hero_channeler` (idle/battle) | 128×160 ea | A | Master + Frost-blue orb | yes | SR | as above | 2 |
| `hero_skirmisher` (idle/battle) | 128×160 ea | A | Master + Clay mantle | yes | SR (sharpest) | as above | 2 |
| `hero_warden` (idle/battle) | 128×160 ea | A | Master + Moss trim | yes | SR | as above | 2 |

*Hurt/react frame: **not** a separate asset — use palette-swap red-tint flash (shader). Saves budget (see §3 risk #2).*

### 2.2 Enemies + Mini-boss (Atlas A — Characters)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `enemy_huskling` | 110×140 | A | Master (neutral) | yes | Fractured SR | 2-value + dither | 1–2 |
| `enemy_frostmote` | 100×130 | A | Frost&Lumen (Frost Blue) | yes | Fractured/CG facet | 2-value + dither | 1–2 |
| `enemy_stoneling` | 120×130 | A | Verdant (Moss/Clay) | yes | Fractured/CG strata | 2-value + dither | 1–2 |
| `enemy_stormwretch` | 105×135 | A | Verdant (Clay) + arc | yes | Fractured/CG bolt | 2-value + dither | 1–2 |
| `enemy_emberwretch` | 110×140 | A | **Ember (swap of huskling)** | yes | Fractured SR | reuse huskling + ember cracks | 1–2 |
| `enemy_stoneling_brute` | 150×165 | A | **Stone (swap of stoneling)** | yes | Fractured/CG | reuse stoneling, larger | 1–2 |
| `boss_sigil_warden` | 200×240 | A | Master + Umbra-violet crack | yes | Fractured + CG ring | 2-value + dither | 2 (idle, roar) |

*Elemental tinting via shader palette-swap (art-bible §4.2) — one silhouette, multiple element colors, no duplicated art.*

### 2.3 Town (Atlas B — Environment)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `town_inn` | 200×240 | B | Master (golden-hour) | yes | SR | 2-value + dither | 1 |
| `town_market` | 200×240 | B | Master + Clay | yes | SR | as above | 1 |
| `town_barracks` | 200×240 | B | Master + Moss | yes | SR | as above | 1 |
| `town_sage` | 200×240 | B | Master + Teal | yes | SR | as above | 1 |
| `town_shrine` | 200×240 | B | Master + Parchment (ward motif) | yes | SR + CG ward | as above | 1 |
| `prop_lantern` | 48×64 | B | Ember Parchment glow | yes | SR | emissive | 1 |
| `prop_signpost` / `prop_barrel` / `prop_crate` / `prop_bench` / `prop_well` | 64–96 ea | B | Master/Clay | yes | SR | 2-value | 1 ea |

### 2.4 Dungeon (Atlas B — Environment)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `tile_dungeon_floor` (64² tileable) | 64×64 | B | Verdant (Green-Black) | yes | SR | 2-value | 1 |
| `tile_dungeon_wall` | 128×128 | B | Verdant + Clay | yes | SR | 2-value | 1 |
| `tile_dungeon_void` | 128×128 | B | Deep Plum / Umbra | yes | — | flat | 1 |
| `tile_lightpool` | 128×128 | B | Ember/Teal glow | yes | soft | emissive | 1 |
| `prop_brazier` | 96×96 | B | Clay + Ember | yes | SR + CG | emissive core | 1 |
| `prop_ward_fragment` / `prop_moss_stone` / `prop_pillar` / `prop_rubble` / `prop_banner` | 64–96 ea | B | Verdant/Master | yes | SR | 2-value | 1 ea |
| `prop_pedestal` | 96×120 | B | Master + CG ward ring | yes | SR+CG | 2-value + emissive | 1 |
| `prop_sigil_stone` | 80×96 | B | **CG Ward-Sigil** (tintable) | no (CG) | CG | emissive glyph | 1 |
| `prop_chest` | 80×72 | B | Clay + Lumen Gold | yes | SR | 2-value | 1 (open variant = 2nd frame) |
| `prop_gate` | 128×160 | B | Verdant + CG | yes | SR+CG | 2-value | 1 |

### 2.5 Ward-Sigils (Atlas D — Sigils, crisp, mipmaps OFF)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `fx_sigil_ember` … `fx_sigil_umbra` (7) | 96×96 ea | D | Element color (§2.3) + Parchment ring | **no** (CG edge) | CG | emissive, inner glow | 1 (ignite = shader fade) |
| `fx_sigil_corrupt` | 96×96 | D | Umbra-violet + cracked ring | no | CG | emissive | 1 |

### 2.6 UI Components (Atlas C — UI/VFX)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `ui_chip_*` (5) + `ui_chip_run` + `ui_chip_settings` | 96×48 (9-slice) | C | Master (Parchment border, Ember selected) | yes (panel) | SR (chips) | 2-value | 1 |
| `ui_medallion_frame` ×4 | 120×120 | C | Master per hero tint | yes | SR (circle) | 2-value | 1 |
| `ui_medallion_arc` / `ui_medallion_selected` | 120×120 | C | Ember/Teal ring | no | CG ring | emissive | 1 |
| `ui_badge_slow` / `ui_badge_guard` / `ui_badge_mark` | 48×48 | C | Element/state color | no | CG | emissive | 1 |
| `ui_turn_pip_ally` (round) / `ui_turn_pip_enemy` (sharp) | 24×24 | C | Parchment/Teal vs Ember/Umbra | no | SR vs CG | flat | 1 |
| `ui_ribbon_bg` / `ui_floor_label` | 360×44 (9-slice) | C | Deep Plum + Parchment | yes | SR | 2-value | 1 |
| `ui_save_icon` | 64×64 | C | Parchment + Ember core (ward ring) | no | CG | emissive | 1 |
| `ui_panel` / `ui_toggle` / `ui_slider` / `ui_tab` | 9-slice / 64 | C | Master | yes | SR | 2-value | 1 |
| `ui_codex_grid` | 320×400 (9-slice) | C | Master | yes | SR+CG | 2-value | 1 |
| `vfx_spark` / `vfx_slash` / `vfx_ignite` / `vfx_heal` / `vfx_shield` / `vfx_number_bg` / `vfx_damage_pop` / `vfx_lowhp_pulse` | 64×64 ea | C | Element colors | no | mixed | shader-glow preferred | 1–3 |

### 2.7 Environment Tiles — Town (Atlas B)
| Asset ID | Ref size | Atlas | Palette | Grain | Shape | Pixel-texture | Frames |
|---|---|---|---|---|---|---|---|
| `tile_town_ground` | 128×128 | B | Clay / Moss | yes | SR | 2-value | 1 |
| `tile_town_sky` (golden-hour) | 360×200 | B | Plum→Parchment horizon | yes | — | flat gradient-ish (dither) | 1 |
| `tile_town_foliage` | 96×96 | B | Moss | yes | SR | 2-value blobs | 1 |

---

## 3. Budget Reconciliation

### 3.1 Atlas Allocation
| Atlas | Dimensions | Mipmaps | Decoded (RGBA) | Contents |
|---|---|---|---|---|
| **Grain** | 128×128 | ON | ~0.09 MB | Shared paper/pixel noise (overlay only) |
| **A — Characters** | 1024×1024 | **OFF** | **4.00 MB** | 4 heroes ×2 + 6 enemies + mini-boss |
| **B — Environment** | 1024×1024 | ON | ~5.33 MB | Town (5 buildings + props) + Dungeon (tiles + ~10 props) |
| **C — UI / VFX** | 1024×1024 | ON | ~5.33 MB | Chips, medallions, ribbon, settings, codex, VFX |
| **D — Sigils** | 512×512 | OFF | **1.00 MB** | 7 Ward-Sigils + corrupt variant (crisp, non-mip) |
| **TOTAL** | ≤4×1024² ✓ | — | **≈ 15.75 MB** | **Under 16 MB ✓** |

*Atlas count = 3×1024² + 1×512² + 1×128² grain = within "≤4 × 1024²" cap (smaller atlases are allowed; the cap is a maximum, not a fill quota).*

### 3.2 Palette
- **12 named base colors** (art-bible §2.1–2.3) + up to **36 derived tints/shades** = **≤ 48 master colors**. ✅
- Palette-swap tinting (enemies, sigil-stones) reuses the same ≤48 set via shader — no new colors introduced.
- **Action:** a CI palette validator rejects any pixel outside the 48-color LUT; out-of-set colors require art-director sign-off (architecture §5).

### 3.3 Verdict
✅ **FITS.** Decoded ≈ 15.75 MB (< 16 MB), atlas count within cap, palette ≤ 48, all WebP/PNG, viewport-safe. **Headroom ≈ 0.25 MB** — budget is fully committed; the two settings below are load-bearing.

### 3.4 Risk Flags & Mitigations
| # | Risk asset / decision | Severity | Why | Mitigation / cut |
|---|---|---|---|---|
| 1 | **Environment Atlas B at 1024² + mipmaps = 5.33 MB** (largest single cost) | MED | Town buildings (5×200×240) + dungeon props can balloon if facades get detailed | Cap each building facade ≤ 200×240, flat 2-value; reuse foliage/roof tiles; no per-building unique texture. If overflow, drop B to 512² mip (saves ~4 MB) — but that forces VFX tighter in C. |
| 2 | **Character Atlas A mipmaps MUST stay OFF** | **HIGH** | Turning mip ON adds ~1.33 MB → total ≈ 17.1 MB, **over 16 MB** | Lock mip OFF for A (flat 2–3 value style needs no mip; depth cue is scale+offset, not mip — art-bible §6.3). Revisit only if visual quality demands, which would require shrinking an atlas to 512². |
| 3 | **VFX spillover in Atlas C** | MED | C is already 1024² mip ON; more than ~12 particle types forces a 4th atlas → 4×1024² mip ≈ 21 MB (blows cap) | Cap VFX to ≤ 12 small types; `vfx_ignite`/`vfx_shield` use shader glow, not textures. Ignite = fade-only (also reduced-motion safe). |
| 4 | **Hero "hurt" frame** | LOW | 4 heroes × extra frame ≈ +160 KB in A | **Cut:** use shader red-tint flash instead of a dedicated frame (already spec'd in §2.1). |

---

## 4. Accessibility Alignment

| Requirement | Where enforced | Status |
|---|---|---|
| **≥ 44×44px hit targets** | All `ui_chip_*`, `ui_medallion_frame`, `ui_toggle`, `ui_slider`, `ui_chip_run/settings`, `town_*` tap nodes | ✅ spec'd ≥ 44px; medallions 120×120, chips 96×48 (height ≥44), ribbon 44 tall |
| **Shape-as-identity (colorblind-safe)** | Ward-Sigils (§7.3 unique glyph per element), status badges (slow/guard/mark = distinct CG shapes), turn pips (round=ally / sharp=enemy) | ✅ shape is the ID channel; color is reinforcement only |
| **Reduced-motion variants** | `vfx_ignite` = fade-only (no flash); `ui_medallion_selected` lift = gentle ease, disabled under reduced-motion; particles capped | ✅ fade-only ignite; ties to SettingsManager `reducedMotion` |
| **Viewport-safe 360×640** | All UI built from Control nodes + responsive anchors; stage/dock split 58/42 portrait; no fixed-res art | ✅ safe frame verified at 360×640, scales 100–150% |
| **Contrast** | Parchment `#F2D9A0` on Deep Plum `#2B1B2E` ≈ 9.3:1 (body/key text) | ✅ passes AA & AAA |
| **Text alternatives** | Every command/icon carries a text label; semantic order for menus (architecture §4 #5) | ✅ label-everything now (SR foundation) |
| **Colorblind-Assist toggle** | Overlays shape/label outlines on top of color (accessibility §2, feature #1) | ✅ sigil/badge shapes already present; toggle adds outline |

---

## 5. AI-Prompt Reference (PLACEHOLDER ONLY)

> ⚠️ **These prompts generate throwaway PLACEHOLDERS for engineering to stub the game.** Final art is **human-authored** and must pass the IP lint gate (no FF1 / Square Enix silhouettes, fonts, crystal iconography, or battle composition). Each prompt is scoped to the **Ember Dusk** palette and **Ward-Sigil grammar** so placeholders read on-style without becoming shippable art.

**Heroes (4 jobs):** *"Original storybook fantasy hero, soft-rounded pillowy silhouette, tapered ink outline, warm limited-palette vector with subtle pixel grain, Ember Dusk palette (deep plum #2B1B2E, ember orange #E8743B, teal #3FA7A0, parchment #F2D9A0). [Vanguard: bulky low stance, tower-shield-cape on back, crested visor, no horns] [Channeler: slender, floating orb by hand, cowled halo face, one long sleeve] [Skirmisher: lithe high lean, single glaive, feathered mantle] [Warden: calm upright, closed tome worn as shield, cylindrical pauldrons]. Front-facing 3/4, flat 2–3 value shading, NO 8-bit NES style, NO crystal motifs, original design only."*

**Enemies:** *"Original storybook fantasy foe, sharper fractured silhouette than heroes (jagged spines/angular plates) but still limited-palette vector + pixel grain, Ember Dusk world. [Huskling: hunched fractured husk, neutral] [Frostmote: faceted ice-shard body, cool blue] [Stoneling: stacked trapezoid strata, mossy] [Stormwretch: angular zig-zag bolt-tree]. Flat 2-value shading, readable threat without color, NO FF1 enemy likeness, original only."*

**Mini-boss:** *"Original 'sigil-twisted warden' — large ornamental fractured guardian with a CRACKED double-ring emblem (our Ward-Sigil frame, broken), ember-and-umbra-violet palette, storybook ink outline, flat shading, looming but not grimdark. Original design, no SE/crystal iconography."*

**Town (Hearthmoor):** *"Cozy handcrafted fantasy town at golden hour, soft-rounded buildings (inn, market, barracks, sage hut, shrine) with warm lantern glow pools, limited Ember Dusk palette, subtle pixel grain, storybook ink. Shrine shows a closed circular ward-mark with ember core (NOT a crystal). Flat 2-value shading, inviting, no NES tiles."*

**Dungeon (The Sundered Ward):** *"Handcrafted dungeon interior, deep-plum/umbra void with sparse ember-orb light pools, mossy broken stone, a carved pedestal and sigil-stones bearing crisp geometric ring-marks (our Ward-Sigil language). Limited palette, pixel grain, flat shading, tense but hopeful. Original, no FF1 dungeon art."*

**Ward-Sigils (7):** *"Seven original crisp-geometric elemental marks, each = thin double-ring frame + one distinct inner glyph: Ember = 3 stacked upward chevrons; Frost = 6 broken radial spokes; Storm = angular bolt-tree; Stone = 2 nested trapezoids; Gale = 3 swept concentric arcs; Lumen = center point + 8 rays; Umbra = crescent + enclosing arc. Emissive element color on dark, mathematically clean 'engraved' look, NO snowflake/fire/bolt clichés, fully original."*

**UI components:** *"Soft-rounded storybook UI: command chips (rounded rectangles, parchment 2px border on deep-plum, ember-orange selected state), circular party medallions with ring HP/MP fill, top ribbon with round (ally) and sharp (enemy) turn pips, a save icon = closed ward-ring + ember core. Ember Dusk palette, subtle grain, rounded humanist feel. NO FF1 menu layout, NO pixel font."*

---

## 6. Handoff to Engineering (asset → atlas → def-file mapping)

Ties to architecture §2.5 (Resource-as-Data, ADR-003). `AssetRegistry` loads defs at boot; **zero code change** to add L2 content.

### 6.1 New / extended def resources
| Def | File | Key fields (add) |
|---|---|---|
| `AtlasDef` *(new)* | `content/atlas/atlas_*.tres` | `id, file, size(Vector2i), mipmaps(bool), regions[]:{name,x,y,w,h,frames[]}` |
| `JobDef` (extend) | `content/jobs/*.tres` | add `art: AtlasRegionRef` (hero idle+battle rects) |
| `EnemyDef` (extend) | `content/enemies/*.tres` | add `art: AtlasRegionRef`, `tintElement: ElementId` (palette-swap) |
| `WardSigilDef` (extend) | `content/elements/*.tres` | add `glyph: AtlasRegionRef` (→ Atlas D) |
| `ElementDef` (extend) | `content/elements/*.tres` | add `artRef: AtlasRegionRef` |
| `PropDef` *(new)* | `content/world/props/*.tres` | `id, art: AtlasRegionRef, shapeLang(SR/CG), isLightPool` |
| `WorldNodeDef` (extend) | `content/world/*.tres` | add `art: AtlasRegionRef` for town buildings |
| `DungeonDef`/`RoomDef` (extend) | `content/world/*.tres` | rooms reference `PropDef` ids |
| `UIThemeDef` *(new)* | `content/ui/theme.tres` | region refs for chips/medallions/ribbon/save-icon/settings |
| `VFXDef` *(new)* | `content/vfx/*.tres` | `id, regionRef, shaderGlow(bool), reducedMotionVariant` |

### 6.2 Mapping table (sample)
| Asset | Atlas | Def file | Field |
|---|---|---|---|
| `hero_vanguard` | A | `content/jobs/vanguard.tres` | `art` → region `hero_vanguard_idle` / `_battle` |
| `enemy_frostmote` | A | `content/enemies/frostmote.tres` | `art`, `tintElement=frost` |
| `enemy_emberwretch` | A | `content/enemies/emberwretch.tres` | `art` = huskling region, `tintElement=ember` |
| `boss_sigil_warden` | A | `content/enemies/boss_warden.tres` | `art`, `corruptRing=true` |
| `town_shrine` | B | `content/world/hearthmoor.tres` | `art` → `town_shrine` |
| `prop_pedestal` | B | `content/world/props/pedestal.tres` | `art`, `shapeLang=CG` |
| `fx_sigil_ember` | D | `content/elements/ember.tres` | `glyph` → `fx_sigil_ember` |
| `ui_chip_attack` | C | `content/ui/theme.tres` | `chip_attack` region |
| `ui_medallion_frame` | C | `content/ui/theme.tres` | `medallion_0..3` regions |
| `ui_save_icon` | C | `content/ui/theme.tres` | `save_icon` region |
| `vfx_ignite` | C | `content/vfx/ignite.tres` | `region`, `shaderGlow=true`, `reducedMotion=fade` |

### 6.3 Loading notes
- `AssetRegistry` scans `content/` → builds `AtlasDef` (GPU upload, mip per flag) + region LUT; defs reference regions by name, never by raw pixel coords in scripts.
- Grain atlas (128²) is a **shared CanvasItem/Shader overlay**, applied at 8–15% over painted surfaces — never duplicated into other atlases.
- Palette-swap enemies: one region, `tintElement` drives a 1-bit shader tint → no extra atlas space.
- Sigil atlas (D) mipmaps OFF to preserve CG edges (architecture §4.2); all other atlases per §3.1.
- CI asset-audit must fail the build if: >4×1024² atlases, decoded >16 MB, any color outside the 48-LUT, or any hit target <44px at 360×640.

---

## 7. Open Items & Sign-off Requests
1. **Confirm mip OFF for Characters atlas (Risk #2)** — load-bearing for the 16 MB cap. Needs engineering-lead concurrence.
2. **Building facade size cap (Risk #1)** — confirm ≤200×240 flat facades; if richer town art is wanted, pre-approve dropping Atlas B to 512² mip.
3. **VFX type cap (Risk #3)** — confirm ≤12 VFX types in Atlas C; ignite/shield as shader glow.
4. **Typography** — rounded humanist sans (system/licensed, not pixel font). Font file is NOT a texture atlas asset; confirm license clears web-embed. Spec'd as data, not in §3 budget.
5. **IP lint gate** — all placeholders (§5) and final art must pass the no-FF1/SE validator before merge.

---

*End of Asset Specification (Phase 4). Companion to `design/art/art-bible.md` and `docs/architecture/main-architecture.md` §2.5/§5. Owned by art-director; budget verdict: **FITS** (≈15.75 MB / 4-atlas cap / ≤48 colors), with three load-bearing settings flagged above.*
