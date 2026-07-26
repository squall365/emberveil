# Epic E5 — Asset Pipeline & Audit (checklist E, cross-cutting)

**Goal:** Enforce art-bible §9.4 hard budgets in CI — palette ≤48, ≤4×1024² atlases, ≤16MB decoded,
1 shared 128² grain, 360×640 / 44px viewport. Satisfies every ⛔ item in checklist E.
**Owning systems:** cross-cutting. **Depends on:** E1 (content/asset dirs), E6 (content exists to audit).

## Story E5-A · Palette Validator (≤48 colors)
- **User Story:** As an engineer, I want a CI check that no asset uses out-of-set colors, so the 48-color limit holds (art-bible §9.4/§2.3).
- **Ref:** checklist E ⛔; art-bible §2.3/§9.4.
- **DoD:** `tools/palette_validator.gd` (run `godot --headless --script`) loads the master palette set (from `content/palette.json`, ≤48 entries) and scans every texture under `content/` + `assets/`; fails build on any out-of-set color (with tolerance for the grain overlay).
- **Acceptance (testable):**
  1. CI: a texture with an off-palette pixel ⇒ exit non-zero, names the file+color.
  2. CI: clean asset set ⇒ passes.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-D, E6-A

## Story E5-B · Atlas / Texture Budget Audit (≤4×1024², ≤16MB, 1×128² grain)
- **User Story:** As an engineer, I want a CI check on texture size/count/budget, so we never silently blow the 16MB / 4-atlas cap (art-bible §4.2/§9.4).
- **Ref:** checklist E ⛔; art-bible §4.2/§9.4; main-arch §5.
- **DoD:** `tools/asset_audit.py` walks image assets, computes decoded bytes = w*h*4, sums to ≤16MB; counts atlases (≥1024²) ≤4; verifies exactly one 128² grain atlas; format ∈ {WebP, PNG}. Exits non-zero on violation.
- **Acceptance (testable):**
  1. CI: total decoded >16MB ⇒ fail; >4 atlases ⇒ fail; missing/extra grain ⇒ fail; JPG ⇒ fail.
  2. CI: within budget ⇒ pass; prints a budget report.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-C (CI), E6-A

## Story E5-C · Viewport / Layout Test (360×640, ≥44px, responsive)
- **User Story:** As a player, I want every control tappable at 360×640, so the game is usable on small web viewports (art-bible §6.3/§9.1).
- **Ref:** checklist E ⛔; art-bible §6.3/§9.1; main-arch §5.
- **DoD:** A GUT/layout test instantiates Town/Battle/Dungeon at 360×640 and asserts all interactive Controls have effective rect ≥44×44 and stay within viewport; anchors are responsive (no fixed-px dependency).
- **Acceptance (testable):**
  1. Test: at 360×640, command chips / medallions / ribbon buttons ≥44×44 and on-screen.
  2. Test: switching to a larger viewport keeps layout valid (anchors, not hard-coded px).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E2-G, E3-F

## Story E5-D · Ward-Sigil Shape-ID Renderer
- **User Story:** As a player, I want every element identified by a unique SHAPE, so the game is colorblind-safe (art-bible §7.3/§9.1).
- **Ref:** checklist E; art-bible §7.3 (glyph grammar); elements §2.
- **DoD:** A `SigilDrawer` builds the 7 glyphs from Ward-Ring + primitives per art-bible §7.3 (Ember=▲▲▲, Frost=✶, Storm=⚡, Stone=▱, Gale=〰️, Lumen=✺, Umbra=☾); shape is the ID channel; color is reinforcement only.
- **Acceptance (testable):**
  1. Unit: each element renders a distinct silhouette; colorblind-assist toggle adds shape/label outline.
  2. IP: none of the 7 glyphs match FF1 elemental icons (review gate).
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E2-E
