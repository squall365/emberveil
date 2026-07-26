# EMBERVEIL — Art Bible
## Visual Identity (Nine Sections)

> **World:** Veyra · **Engine:** Godot 4 (HTML5 export) · **Platform:** Web / 小游戏 (instant-play)
> **Status:** Phase 1 — Art Direction, FULL review
> **Author:** art-director (林绘澄 / Lin Wayson)
> **Upstream:** `design/concept/game-concept.md` (Visual Anchors §6) — all tone, palette seeds, and IP guardrails originate there.
> **Hard IP rule:** No Square Enix / FF1 sprites, UI layout, font, crystal iconography, or trademarked assets. Original expression only.

---

## 1. Visual Identity & Tone

### 1.1 One-line art direction
**"A hand-illustrated storybook of a dying dusk — warm, close, and quietly heroic."**
EMBERVEIL should feel like a beloved picture-book adventure whose pages glow with emberlight, where a small band matters because the world is small enough to hold in your hands (and on a phone screen).

### 1.2 Tone pillars → art-direction mapping
The concept's five design pillars are realized visually as follows:

| Design Pillar | Visual Translation |
|---|---|
| **Party Synergy Over Individual Power** | The four heroes are *framed as one unit* (shared light, overlapping silhouettes, a single "band" color anchor). UI treats the party as a connected organism, not four isolated stat boxes. |
| **Readable, Command-Driven Tactics** | High-contrast, large-hit shapes; every command and elemental state is *shape-distinct*, not just color-distinct. Combat is legible at a glance on a 360px-wide viewport. |
| **Elemental Literacy as Mastery** | The **Ward-Sigil** system is the visual signature of the game — a consistent geometric "language" that rewards the player for learning to read marks at a distance. |
| **Explorable, Handcrafted World** | Limited-palette vector + subtle pixel grain gives every town, dungeon, and prop a *made-by-hand* quality. Repeating tiles are disguised by hand-placed variation. |
| **Session-Friendly Depth** | UI density is kept low per screen; one beat = one clear visual goal (a lit sigil, a cleared floor, a town at golden hour). |

### 1.3 Anti-tones (what it must NOT feel like)
Cold/clinical sci-fi; NES-authentic 8×8 pixel art; grimdark grittiness; busy "throw-everything-on-screen" mobile RPG UIs. Cozy ≠ childish; epic ≠ joyless.

---

## 2. Color Palette

### 2.1 Master palette decision
**Master = `Ember Dusk`** (warm, intimate, journey-at-sunset). It is the only palette that matches the title *EMBER*VEIL and the "cozy-but-epic" brief: a deep-plum world held together by emberlight, with real (dusk-shadow) stakes.

| Role | Hex | Name | Usage |
|---|---|---|---|
| Background / shadow | `#2B1B2E` | Deep Plum | Base UI panels, night sky, dungeon void, text backdrop |
| **Primary accent (brand)** | `#E8743B` | Ember Orange | Hero/brand color, Ember element, primary CTAs, selected states |
| Secondary accent | `#3FA7A0` | Ward Teal | Cold-element counterpoint, links, secondary UI, Gale element |
| Highlight / parchment | `#F2D9A0` | Ember Parchment | Body text, paper surfaces, Lumen element, safe-contrast fills |

### 2.2 Alternate palettes (accents / environment states)
Used *only* as environment or state variants — never replacing the master for core UI chrome.

| Palette | Hex | Name | Where it appears |
|---|---|---|---|
| Frost & Lumen | `#16243B` | Midnight Blue | Dungeon night, Frost-sigil field, cold-status tint |
| Frost & Lumen | `#6FB7E8` | Frost Blue | Frost element, ice VFX, cool HUD accents |
| Frost & Lumen | `#F4C95D` | Lumen Gold | Treasure/gold, warm treasure glow, rare-element accents |
| Verdant Ward | `#1E2A1E` | Green-Black | Overworld ground, forest floors, Stone-sigil field |
| Verdant Ward | `#7BA05B` | Moss | Stone element, foliage, nature props |
| Verdant Ward | `#C98A3B` | Clay | Storm element, earthen props, leather/wood |
| Verdant Ward | `#2E2438` | Umbra Violet | Umbra element, shadow planes, void VFX |

### 2.3 Element → color map (Ward-Sigil colors)
Each element is assigned one master/alternate color. **Shape, not color, is the primary identifier** (see §7.3 and §9).

| Element | Sigil Color | Source Palette |
|---|---|---|
| Ember | `#E8743B` | Ember Dusk |
| Frost | `#6FB7E8` | Frost & Lumen |
| Storm | `#C98A3B` | Verdant Ward (Clay) |
| Stone | `#7BA05B` | Verdant Ward (Moss) |
| Gale | `#3FA7A0` | Ember Dusk (Teal) |
| Lumen | `#E8EEF2` | Frost & Lumen (Snow White) |
| Umbra | `#2E2438` | Verdant Ward (Umbra Violet) |

> **Engineering constraint (palette budget):** MVP ships with a **global master palette of ≤ 48 colors** (12 named above + tints/shades derived from them). No asset may introduce colors outside this set without art-director sign-off. This keeps the "limited-palette" cohesion and bounds texture/atlas memory for HTML5.

### 2.4 Contrast & accessibility notes
- Body text: **Ember Parchment `#F2D9A0` on Deep Plum `#2B1B2E`** ≈ 9.3:1 — passes WCAG AA & AAA.
- UI strokes/labels: parchment or ember-orange on plum all clear AA.
- **Snow White `#E8EEF2` (Lumen) must NOT be used as small text on light fills** — reserve it for dark panels, glyph fills, and VFX.
- Forbidden anti-patterns: low-contrast grey-on-grey; thin 1px text; relying on color alone to convey element/state.

---

## 3. Line & Shape Language

Two deliberate, contrasting shape grammars give the game instant readability and a "magic system vs. people" split.

### 3.1 Soft-rounded grammar (characters, creatures, props, world)
- **Radius rule:** corners carry a minimum 4–8px rounding at reference scale; silhouettes are pillowy, storybook, approachable.
- **Line:** tapered "ink" outlines (storybook ink mood) — slightly thicker at the base, thinner at taper, never uniform NES 1px.
- **Proportion:** gentle, slightly oversized heads/appendages for charm; no razor edges on the heroes.
- **Applies to:** all party members, townsfolk, friendly NPCs, town/dungeon props, flora, food, furniture.

### 3.2 Crisp-geometric grammar (Ward-Sigils & elemental UI)
- **Construction:** straight segments, exact arcs, polygons, concentric rings — mathematically clean, "engraved" feel.
- **Line:** uniform 2px stroke, no taper; hard corners; subtle inner glow.
- **Applies to:** all seven Ward-Sigils, elemental status badges, spell icons, the "ward ring" frame, sigil-attunement UI, damage-type tags.
- **Why the split:** the world (soft) is lived-in and human; the *system* (crisp) is ancient, intentional, and magical — players learn to read "crisp = elemental system" instantly.

---

## 4. Materials & Textures

### 4.1 The signature look: "limited-palette vector + subtle pixel texture"
- **Base rendering:** flat vector fills (Godot `CanvasItem`/polygon or pre-rendered atlases) with **2–3 value steps per material** (core / mid / shadow) — *not* smooth gradients. This is what keeps the palette limited and the look handcrafted.
- **The grain:** a single **shared 128×128 tileable "paper/pixel noise" overlay** applied at **8–15% opacity** over surfaces. This is the "subtle pixel texture" — it fakes hand-made grain without blowing the palette or the budget.
- **Dithering for shade transitions:** use ordered-dither ramps (Bayer 4×4) between value steps instead of gradients. Gives the cozy 16-bit feel while staying palette-bound.

### 4.2 Web / HTML5 texture budget (engineering constraints)
> These are hard constraints for the engineering-lead when scoping asset specs.

- **One shared grain atlas** (128×128, repeat-wrap). Do not per-asset-duplicate it.
- **Sprite atlases:** power-of-two, max **1024×1024** per atlas; target **≤ 4 atlases** for MVP (characters, environments, UI, VFX).
- **No runtime texture streaming** for MVP; all MVP art fits in a **≤ 16 MB** decoded texture budget for instant web load.
- **Lossless or near-lossless** (WebP/PNG). No JPG (would break the flat-palette look).
- **Mipmapping:** on for environment/UI; off or "keep" for crisp sigils to preserve geometric edges.
- **Tinting:** prefer **palette-swap / shader tint** over duplicated colored assets (e.g., one monster, tinted per element via a 1-bit palette map).

### 4.3 Material palette (stylized, not photoreal)
| Material | Stylization |
|---|---|
| Stone / brick | Flat mass + 2-step value + grain; rounded mortar lines |
| Wood / leather | Clay `#C98A3B` family, visible grain strokes |
| Cloth | Soft-rounded folds, 2-value shading, no sheen |
| Metal (arms/ward-frames) | Crisp-geometric grammar; cool grey-violet, hard highlight |
| Magic / sigil | Self-lit; emissive parchment/element color; no external light needed |
| Foliage | Moss `#7BA05B` blobs, rounded canopies |

---

## 5. Lighting & Atmosphere

Mood is carried by **value range + one warm key light**, not by complex shaders (keeps HTML5 performant).

### 5.1 Town — "golden-hour hearth"
- **Key:** low, warm emberlight from windows/lanterns; rim-light on rounded props.
- **Value:** mid-to-high, inviting. Backgrounds sit at plum→parchment, never black.
- **Accent:** emissive lanterns (`#E8743B`/`#F2D9A0`) as focal glows; soft volumetric haze.
- **Feeling:** safe, cozy, a place worth protecting.

### 5.2 Dungeon — "ember against the dark"
- **Key:** sparse ember/orb light pools in a cool plum/umbra void; Ward-Sigils are the brightest objects.
- **Value:** low-key, high-contrast pools. Shadow plane `#2E2438`/`#2B1B2E`.
- **Accent:** sigil glow (`#3FA7A0`/`#E8743B`) as wayfinding beacons; restrained VFX.
- **Feeling:** tension and discovery, never hopeless — the ember always wins the frame.

### 5.3 Overworld (expansion) — "the wide dusk"
- **Key:** broad Ember-Dusk sky gradient (plum→parchment horizon); single soft sun.
- **Value:** widest range of the three; readable silhouettes against sky.
- **Feeling:** epic scale, but intimate — the world is a handheld map, not a void.

---

## 6. Composition & Framing

### 6.1 Hard rule: do NOT reproduce FF1's composition
FF1 = enemies right / party left / command window pinned bottom. **EMBERVEIL inverts and recenters it.**

### 6.2 Original encounter composition — "The Underdog Stage"
Intended for a **portrait / small web viewport** (safe at 360×640 and up):

```
┌───────────────────────────┐  ← slim top ribbon: turn order + run/settings
│   ENEMY ARC (staggered,   │
│   depth via scale; framed  │     ← threats loom ABOVE, in an arc
│   on an upper back-arc)    │
│        ◠  ◠  ◠            │
│                           │
│   ┌─────────────────┐     │
│   │  PARTY BAND     │     │     ← heroes are a tight, front-and-center
│   │  (4, overlapping│     │       UNIT at the lower-center "stage lip"
│   │   silhouettes)  │     │
│   └─────────────────┘     │
│                           │
│  ⦿hero   [Cmd][Cmd][Cmd] │  ← bottom dock: portrait medallion (left)
│           [ context panel]│     + soft-rounded command chips (NOT full-width window)
└───────────────────────────┘
```

- **Why it works:** party reads as *one defended unit* at the stage lip; enemies loom above in an arc (heroic underdog). This is the opposite of FF1's side-by-side split and fits a vertical phone viewport.
- **No bottom-pinned full-width command window.** Commands appear as a **contextual bottom-left dock** that expands only the active hero's options; the rest of the stage stays visible.

### 6.3 Web-viewport safety rules (engineering constraints)
- **Minimum safe frame:** 360×640 CSS px. All critical HUD/command elements must fit and remain tappable (≥ 44×44px hit targets) at this size.
- **No fixed-pixel art tied to a single resolution:** use a reference scale + responsive anchors; sigils/UI scale, backgrounds letterbox-or-bleed.
- **Stage split:** ~58% encounter stage / ~42% command+status dock on portrait; on landscape, dock moves to a right rail.
- **Depth cue:** scale + vertical offset only (no expensive DOF/blur). Keeps HTML5 cheap.

---

## 7. UI / UX Visual Language

### 7.1 Panels & chrome (original, storybook)
- **Panels:** soft-rounded rectangles (12–16px corner radius), Deep Plum fill + parchment 2px ink border + shared grain overlay. NOT FF1's hard pixel-box menus.
- **Typography:** a **rounded humanist sans** (original/licensed web-safe; NOT the FF1 pixel font). Generous x-height for small-viewport legibility.
- **Affordances:** commands = soft-rounded "chips" with ember-orange selected state; hover/focus = parchment glow ring.
- **Motion:** gentle ease-in-out; sigils "ignite" (fade+glow) on attune; no screen-shaking UI.

### 7.2 HUD
- **Top ribbon:** turn-order pips (round = ally, sharp = enemy, per shape grammar), compact run/settings, current floor/node name in parchment.
- **Party medallions (bottom dock):** circular portrait + HP/MP arc (ring fill, not bars) + status badge (crisp-geometric). Selected hero lifts slightly.
- **Enemy readouts:** name + affinity hint shown only on focus/selection (keeps clutter low).

### 7.3 The Ward-Sigil language (original element marks)
**Construction grammar (so engineering can generate/spec them consistently):**
1. **Ward Ring** — a thin double-circle frame (outer + inner, 2px, parchment or element color). *This frame is the system identifier* — any mark inside a ward ring is "a Ward-Sigil / elemental system."
2. **Inner Glyph** — built from primitives on a shared polar/7-grid: each element gets ONE distinct geometric construction:

| Element | Glyph construction (crisp-geometric) | Read-shape |
|---|---|---|
| **Ember** | Three upward chevrons stacked/nested (rising flame) | ▲▲▲ ascending |
| **Frost** | Six-fold radial spokes with *broken* segments (not a literal snowflake) | ✶ sharp 6-point |
| **Storm** | A branched, angular bolt-tree (straight zig segments) | ⚡ angular fork |
| **Stone** | Two nested trapezoids (layered strata) | ▱ stacked slab |
| **Gale** | Three open concentric chevron-arcs sweeping one way | 〰️ swept arcs |
| **Lumen** | Center point + 8 thin radiating rays within the ring | ✺ sun-burst |
| **Umbra** | A crescent void + enclosing thin arc (eclipse) | ☾ eclipsed |

- **Color:** sigil stroke/fill uses the element color (§2.3); the Ward Ring may be parchment for UI or element-colored in-world.
- **Accessibility:** each element is **uniquely identifiable by SHAPE alone** (colorblind-safe). Color is reinforcement, never the sole channel.
- **No FF1 elemental icons.** These seven are original geometric marks.

---

## 8. Character & Asset Style

### 8.1 The four MVP jobs (original silhouettes)
All party members use the **soft-rounded grammar** and share a subtle "ember-thread" accent so they read as *one band*. None borrow FF1 job silhouettes or the 8 classic job icons.

| Job | Role | Original silhouette direction |
|---|---|---|
| **Vanguard** | Front-line / tank | Broad, low center of mass; a **tower-shield-cape hybrid** on the back + compact greatblade; helm with a forward visor *crest* (not a horned warrior clone). Bulky rounded shoulders. |
| **Channeler** | Elemental damage | Slender; a **floating catalyst orb** (no staff clone) orbiting the hand; rounded cowl that haloes the face; one asymmetric long sleeve. Vertical, airy. |
| **Skirmisher** | Agile damage / support | Lithe, high stance; a **single glaive** + light feathered mantle; asymmetric, dynamic lean. Sharpest of the four (still soft-rounded, not jagged). |
| **Warden** | Healing / defense | Medium build; a **tome-shield** (closed book worn as a guard) + cylindrical protective pauldrons; calm upright posture; barrier-motif trim. |

### 8.2 Enemy read-shapes
- Enemies get **sharper, more fractured silhouettes** than the party (jagged spines, angular plates) — a value/shape contrast that makes "threat" readable at a glance without color reliance.
- Still rendered in the limited palette; tinted per element via palette-swap (§4.2) when element-typed.
- Bosses: larger, more ornamental fracture; a Ward-Ring *corruption* variant (cracked ring) signals "sigil-twisted" foes.

### 8.3 Towns & dungeon props
- **Soft-rounded, handcrafted:** barrels, lanterns, signposts, crates, beds, market stalls — pillowy outlines, visible grain, 2-value shading.
- **Ward-Sigil props (in-world):** carved sigil-stones, attunement pedestals use the **crisp-geometric grammar** so players connect "this object = elemental system."
- **Dungeon dressing:** broken ward-fragments, ember-braziers (light pools), mossy stone — all palette-bound.

---

## 9. Accessibility Baseline + Reference & Restrictions

### 9.1 Accessibility baseline (web, WCAG-aligned)
| Requirement | Target |
|---|---|
| Text contrast | ≥ 4.5:1 (AA); master combo hits 9.3:1 |
| Large UI / non-text contrast | ≥ 3:1 |
| Element/state identification | **Shape + icon + (optional) color** — never color alone |
| Text scaling | UI supports 100–125% without clipping core HUD |
| Hit targets | ≥ 44×44px on touch/web |
| Colorblind safety | Gale/Stone hues are adjacent → sigil SHAPE carries ID; provide a "colorblind assist" toggle that adds shape/label outlines |
| Motion sensitivity | Respect `prefers-reduced-motion`; sigil "ignite" = fade only, no flash |
| Readability | Minimum body text ≈ 14px @360 width; parchment-on-plum only |

### 9.2 Original-IP guardrails (HARD — FULL-review gate)
**Must NOT reproduce (Square Enix / FF1 specific expression):**
- FF1 sprite silhouettes / character designs and the 8 classic job icons.
- FF1 battle composition (enemies right / party left / bottom command window).
- FF1 menu/HUD layout, the specific pixel font, NES 8×8 tile aesthetic.
- Crystal iconography and any SE trademarks, names, logos, symbols.
- FF1's exact elemental icon set (fire/ice/bolt/etc. as drawn).

**Our original stand-ins (free to use):**
- **Ward-Sigils** (§7.3) — unique geometric marks per element.
- **Underdog Stage** composition (§6.2) — party as a lower-center unit, enemies in an upper arc.
- Soft-rounded character grammar + crisp-geometric system grammar split.
- Original job names (Vanguard/Channeler/Skirmisher/Warden) and world terms (Veyra, Driftwing).

### 9.3 Inspire-from (mood) vs Do-not-copy (expression)
| Inspire FROM (mood/feel) | Do NOT copy (specific expression) |
|---|---|
| Storybook-ink warmth & line quality | FF1 pixel font & NES 8×8 tiles |
| Cozy 16-bit indie fantasy *sensibility* | FF1 sprite/job silhouettes & icons |
| Limited-palette pixel *aesthetic* | FF1 exact palettes & crystal art |
| Handcrafted, characterful readability | FF1 menu/HUD layout & battle framing |
| "Elemental anchors hold the world" (idea) | FF1 Crystal narrative, names, iconography |

### 9.4 Engineering handoff — hard constraints summary
1. **Palette:** global master ≤ 48 colors (§2.3); no out-of-set colors without sign-off.
2. **Textures:** 1 shared 128×128 grain atlas; ≤ 4 × 1024² atlases; ≤ 16 MB decoded budget; WebP/PNG only; tint via palette-swap.
3. **Viewport:** safe at 360×640; ≥ 44px hit targets; responsive anchors, no fixed-res art.
4. **Sigils:** build from Ward-Ring + primitive glyph grammar (§7.3); shape is the ID channel.
5. **Composition:** Underdog Stage only (§6.2); no FF1 layout; ~58/42 stage/dock split.
6. **No SE/IP assets** anywhere in the pipeline (§9.2).

---

*End of Art Bible (Phase 1). This document seeds the asset-spec pass (entity-inventory → per-asset specs + AI prompts) owned by the art-director in Phase 2, and is the visual authority for the engineering-lead's Godot 4 HTML5 implementation.*
