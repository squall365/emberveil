# EMBERVEIL — Accessibility Tiering

> **World:** Veyra · **Engine:** Godot 4 (HTML5 export) · **Platform:** Web / 小游戏 (instant-play) · **Safe viewport:** 360×640
> **Author:** art-director (林绘澄 / Lin Wayson)
> **Phase:** 3 — Accessibility Tiering (FULL review)
> **Upstream:** `design/art/art-bible.md` §9 (Accessibility Baseline + Reference & Restrictions); `design/gdd/` (combat, S6 save/pause)
> **Hard IP rule:** No Square Enix / FF1 assets. Original Ward-Sigil language & Underdog Stage composition.

---

## 1. Tier Definitions

Three tiers describe the *depth* of accessibility support. They are cumulative: a Standard build includes everything in Basic; a Comprehensive build includes everything in Standard and Basic.

### 1.1 Basic — Minimum Viable Compliance (MVP floor, ships no matter what)
The non-negotiable accessibility floor for an instant-play web mini-game. These items are either baked into the art direction itself (e.g., shape-based element IDs, 44px targets) or are cheap, high-leverage code guarantees. **If any Basic item is missing, the MVP does not ship.**

Scope:
- Readable by default: master palette already meets WCAG AA; minimum 14px body text; shape carries element identity.
- Operable by default: ≥44px touch targets; fixed keyboard + touch mapping; pause on safe nodes.
- Safe by default: respects OS `prefers-reduced-motion`; no audio-only critical information; visual cues stand in for vibration.
- Honest about limits: narrative text exists (not audio-only), but full subtitle/menu SR tooling is deferred.

### 1.2 Standard — Recommended MVP Target (most players covered)
What we **aim for in the MVP**. Closes the gap between "technically compliant" and "comfortably playable for the majority." Adds player-facing toggles and remapping so users can tailor the experience without leaving the game.

Scope:
- In-game **Reduced-Motion toggle** (not OS-gated only), **Text-Scale** to 125%, **Control Remap** (keyboard + touch), **Colorblind-Assist** toggle, **Dyslexia-Friendly Font** toggle.
- Subtitle panel with parchment backing; all feedback has a paired visual + audio cue; save-anywhere on safe nodes.
- Semantic/text labels on all critical UI (foundation for SR).

### 1.3 Comprehensive — Full Coverage / Optional Polish (post-MVP or stretch)
The aspirational ceiling. Treats accessibility as first-class feature work, not remediation. Mostly post-MVP, but the architecture (see §4) must not block it.

Scope:
- Text-Scale to 150% + free slider; high-contrast theme; reduced screen-shake & reduced-VFX toggles; adjustable target sizing.
- Gamepad remap + control presets; full subtitle settings (size/bg/position); separate audio volume channels.
- Best-effort screen-reader tree over core flows; optional haptics where the device supports them.

---

## 2. Feature Matrix

Legend: **✓** = supported · **◐** = partial · **—** = not supported at this tier (or out of scope)

| # | Accessibility Feature | Basic | Standard | Comprehensive | Note |
|---|---|---|---|---|---|
| 1 | **Colorblind safety** (shape channel for elements) | ✓ shape ID baked into Ward-Sigils | ✓ + "colorblind assist" toggle (shape/label outlines) | ✓ + enemy-tint parity & alt-palette check | Shape is the identity channel (art-bible §7.3, §9.1); color is reinforcement only. |
| 2 | **Text scaling / min font** @360×640 | ✓ min 14px, default 100% | ✓ up to 125% no HUD clipping | ✓ up to 150% + free slider | UI scales, never clips core HUD (§9.1). |
| 3 | **Text contrast** (WCAG) | ✓ AA 4.5:1 (master hits 9.3:1) | ✓ AAA on body/key text | ✓ + high-contrast theme toggle | Parchment-on-plum is the safe combo (§2.4). |
| 4 | **Subtitles / dialogue text** | ✓ dialogue rendered as text (MVP narrative minimal) | ✓ subtitle panel + parchment backing + speaker labels | ✓ size/bg/position settings | MVP story is light; text is never audio-only. |
| 5 | **Reduced-motion / reduced-screen-shake** | ✓ respect OS `prefers-reduced-motion`; sigil ignite = fade only | ✓ in-game Reduced-Motion toggle | ✓ + Reduced-Screen-Shake & Reduced-VFX toggles | No flashing UI; depth via scale only (§6.3, §7.1). |
| 6 | **Key / control remapping** | ✓ fixed default keyboard + touch mapping | ✓ remap keyboard + touch | ✓ + gamepad remap & presets (later phase) | Gamepad noted for post-MVP; web MVP = KB+touch. |
| 7 | **44px minimum touch targets** | ✓ hard rule, all HUD/commands ≥44px | ✓ (inherited) + visible focus ring | ✓ + adjustable target sizing | Non-negotiable viewport rule (§6.3, §9.1). |
| 8 | **Screen-reader / text-alternative** | ✓ critical UI has text labels, semantic order | ✓ ARIA/semantic exposure for core menus | ◐ best-effort SR tree (web-HTML5 limits) | Godot HTML5 SR is constrained; label everything now. |
| 9 | **Vibration alternative** | ✓ visual cue always (web lacks reliable vibration) | ✓ (inherited) consistent visual pulse language | ✓ + optional haptics on supported devices | Web cannot depend on vibration; visual stands in. |
| 10 | **Pause / save-anywhere-on-safe-node** | ✓ pause on safe node (GDD S6) | ✓ save-anywhere on safe node | ✓ + cross-session continue | Safe-node model from GDD §6. |
| 11 | **Dyslexia-friendly font option** | ✓ humanist rounded sans (no pixel font per IP) | ✓ optional dyslexia-friendly font toggle | ✓ + line/word-spacing options | Pixel font forbidden by IP guardrail (§7.1, §9.2). |
| 12 | **Audio cues w/ visual equivalent** | ✓ critical audio has visual indicator (turn prompt, low-HP) | ✓ all feedback has visual+audio pair | ✓ + separate volume channels / audio descriptions | Ties to audio-director in Phase 4/6. |

**Reading the matrix:** every feature is at least present at Basic (the floor is high because the art direction bakes in shape-ID, contrast, and 44px targets). Standard adds the *player-facing toggles* that make the MVP broadly comfortable. Comprehensive extends range and adds gamepad/ SR/ haptics polish.

---

## 3. Web Mini-Game Specifics (360×640 instant-play)

Constraints unique to a no-install, short-session, low-end touch web build. These shape *how* the tiers are implemented, not just *what* is supported.

- **Low-end device perf vs. effects.** The limited palette + flat 2–3 value fills keep draw calls and overdraw low (art-bible §4). Reduced-Motion / Reduced-VFX toggles are also **performance guards**: on weak GPUs they cap particles and drop glow passes. MVP art must fit a ≤16 MB decoded texture budget with no runtime streaming (§4.2).
- **Touch vs. mouse parity.** Every affordance must work without hover: hover/focus = parchment glow ring is fine, but **no hover-only** reveals. Command chips and medallions are touch-sized (≥44px) and also keyboard-focusable. The bottom dock (Underdog Stage) is the primary input surface.
- **No-install / instant-play.** All accessibility defaults must be **sane on first load** and reachable *before* any combat (settings reachable from title / safe node). Nothing may require a download or account to become accessible.
- **Short sessions.** Quick-resume via safe-node save (GDD S6). Accessibility choices persist across sessions (localStorage) so a returning player is never re-barriered.
- **Browser zoom behavior.** Do not rely on browser/OS zoom for text scaling — provide an **in-app Text-Scale** control so layout never breaks. Still, the layout must survive OS/browser zoom 100–150% without clipping core HUD. Test the safe frame at exactly 360×640 CSS px.

---

## 4. Engineering Constraints (handoff contract → `docs/architecture/`)

The following are **hard requirements** the engineering-lead MUST support in the Godot 4 HTML5 build. They are the code-level expression of §1–§3 and are non-negotiable for MVP.

1. **Settings menu (pre-combat reachable).** Must expose: Reduced-Motion toggle, Text-Scale control (100–150%), Control Remap (keyboard + touch), Colorblind-Assist toggle, Dyslexia-Friendly Font toggle, Subtitle settings, Audio/Visual cue parity switch, High-Contrast theme (Comprehensive). Settings persist via localStorage.
2. **Palette + shape parity enforcement.** Global master palette ≤ 48 colors (§2.3); reject out-of-set colors without art-director sign-off. Ward-Sigils generated from Ward-Ring + primitive glyph grammar (§7.3); **shape is always present**; Colorblind-Assist overlays shape/label outlines on top of color.
3. **44px hit-target layout system.** Layout primitives must enforce a ≥44×44px minimum on all interactive HUD/command elements at 360×640; visible focus ring required.
4. **Responsive viewport.** Safe at 360×640; responsive anchors, no fixed-resolution art; Text-Scale must not clip core HUD; verify at 100 / 125 / 150%. Stage split ~58/42 portrait, right-rail dock on landscape (§6.3).
5. **Text alternatives.** Every command/icon carries a text label; expose semantic ordering for menus; alt text for imagery where feasible. This is the SR foundation (feature #8).
6. **Visual-cue system.** Every audio cue has a paired visual indicator (turn prompt, low-HP pulse, state badge). Vibration is replaced by a consistent visual pulse language (feature #9).
7. **prefers-reduced-motion.** Read the OS setting as the **default**; the in-game Reduced-Motion toggle overrides it. Sigil "ignite" = fade only, never flash (§7.1, §9.1).
8. **Performance guards tied to a11y.** Reduced-Motion/VFX toggles must reduce GPU load (cap particles, drop glow/blur). Mipmapping on for env/UI, off for crisp sigils (§4.2). Texture budget ≤16 MB decoded.
9. **No SE/IP assets in pipeline.** Asset lint must reject any FF1 / Square Enix silhouette, crystal iconography, pixel font, or trademarked asset (§9.2). Original Ward-Sigils and Underdog Stage only.

---

## 5. Alignment Note (art-bible §9 + palettes + IP guardrails)

This tiering is **consistent** with the settled Art Bible and adds no conflicting requirements:

- **§9.1 baseline honored.** Contrast (≥4.5:1 AA; master 9.3:1), text scaling (100–125% no clip), ≥44px targets, colorblind shape-ID, `prefers-reduced-motion`, min 14px body — all map to Basic/Standard cells above. The matrix *operationalizes* §9.1 into ship/aim/stretch tiers.
- **Three named palettes respected.**
  - **Ember Dusk** (master): Deep Plum / Ember Orange / Ward Teal / Ember Parchment — core UI chrome and the safe text combo.
  - **Frost & Lumen** and **Verdant Ward**: environment/state variants only; never replace the master for core chrome. Element sigil colors are *derived* from these (§2.3) but identity is carried by **shape**, so colorblind users are unaffected by any palette swap.
- **Original-IP / no-FF1 guardrails re-stated (HARD).**
  - Ward-Sigils (§7.3) are original geometric marks — no FF1 elemental icons.
  - Underdog Stage (§6.2) is the original composition — no FF1 enemies-right/party-left/bottom-window layout.
  - Typography is a **rounded humanist sans** — never the FF1 pixel font (also supports dyslexia-friendly option, feature #11).
  - No crystal iconography, no SE trademarks/names/logos. Pipeline lint (constraint #9) enforces this gate.

> **Bottom line:** the MVP floor (Basic) is high because the art direction already bakes in shape-based element ID, AA contrast, and 44px targets. Standard is the realistic MVP target (toggles + remap). Comprehensive is post-MVP polish that the architecture must not block.

---

*End of Accessibility Tiering (Phase 3). Companion to `design/art/art-bible.md` §9; feeds the engineering handoff in `docs/architecture/`.*
