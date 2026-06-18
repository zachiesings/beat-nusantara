# Motion Language — Beat Nusantara

How the app *moves*. Goal: **juicy & responsive** — short, snappy, satisfying,
elegant, slightly bouncy, premium. Never laggy, never overdone.

## 0. Principles
1. **Respond on touch-down, reward on release.** Every tappable squishes the
   instant a finger lands (≤90 ms), then pops back.
2. **One hero motion per moment.** Reserve `elasticOut` / confetti for true
   payoffs (grade reveal, mission done). Everywhere else = `easeOutCubic`.
3. **Motion = feedback, not decoration.** If it doesn't tell the user something
   ("pressed", "selected", "you earned this"), cut it.
4. **60 fps is sacred.** The gameplay clock and HUD never wait on widget anims.
5. **Always escapable.** Honor `GameState.reduceEffects` and `vibration`.

## 1. Tokens  (`lib/app/theme.dart`)
| Token | Value | Use |
|-------|-------|-----|
| `AppDur.instant` | 90 ms | press-down |
| `AppDur.xfast` | 120 ms | press release / pop |
| `AppDur.fast` | 200 ms | chips, toggles, tabs |
| `AppDur.med` | 360 ms | page / view change |
| `AppDur.slow` | 650 ms | reveals |
| `AppDur.celebrate` | 2600 ms | one-shot confetti |

| Curve | Maps to | Use |
|-------|---------|-----|
| `AppCurves.snappy` | easeOutCubic | default for ~everything |
| `AppCurves.bouncy` | easeOutBack | selection pops (chips/cards/stickers) |
| `AppCurves.gentle` | easeInOut | breathing / floating loops |
| `AppCurves.overshoot` | elasticOut | BIG rewards only — rare |
| `AppCurves.press` | easeOut | button squish |

## 2. Building blocks already in the app
`Bouncy` (press primitive) · `GradientButton` (candy CTA) · `NeonChip` ·
`ComboCounter` · `CelebrationOverlay` (confetti) · `PulseRings` · `HoloSheen` ·
`Twinkles` · `Sticker` · `CountUp` · `StatRing` · `Mascot` · `NotePainter`
(hit bursts) · `Haptics` · `AudioService.playSfx`.

---

## 3. Per-interaction spec

### ① Primary button press — `GradientButton`
- **Feel:** chunky candy pressing into its rim.
- **Motion:** on down, drop into rim (`margin.top: rim-2`) over `instant`,
  `press` curve; release springs back `xfast`. Idle: shimmer sweep + breathing glow (2.2 s).
- **Haptic:** `Haptics.medium()` on tap. **Sound:** `tap`.
```dart
GradientButton(label: 'Main Sekarang', icon: Icons.play_arrow_rounded, onTap: ...);
```

### ② Chip selection — `NeonChip`
- **Motion:** `AnimatedScale` to **1.06** (`bouncy`, `fast`) + `AnimatedContainer`
  fills gradient + glow ramps in. Deselect reverses.
- **Haptic:** `Haptics.select()`. **Sound:** `tap_soft`.

### ③ Tab / category switching — library chips + content
- **Motion:** chip switches (②); content cross-fades + slides 8 px up.
```dart
AnimatedSwitcher(
  duration: AppDur.fast, switchInCurve: AppCurves.snappy,
  transitionBuilder: (c, a) => FadeTransition(opacity: a,
    child: SlideTransition(
      position: Tween(begin: const Offset(0,.04), end: Offset.zero).animate(a), child: c)),
  child: KeyedSubtree(key: ValueKey(category), child: list),
);
```
- **Haptic:** `select()`. **Sound:** `tap_soft`.

### ④ Song card selection — `SongCard` (wrapped in `Bouncy`)
- **Motion:** down → scale **0.96** (`xfast`); tap navigates via shared
  fade+slide route (`AppDur.med`). Hero/featured cover runs `HoloSheen`.
- **Haptic:** `light()`. **Sound:** `tap`.
- *Hover/selected variant (e.g. difficulty picked):* lift `scale 1.02` + glow bump.

### ⑤ Reward claim — cosmetic equip / coin spend (`RewardsScreen`)
- **Motion:** tile glow ramps to ~0.55, "Dipakai" pill scale-ins (`bouncy`),
  small sparkle burst; coins update via `CountUp` (rolls down).
- **Haptic:** `medium()` → settle `select()`. **Sound:** `reward` (+ `coin`).
```dart
// after grant: fire a localized CelebrationOverlay(pieces: 24) over the tile
```

### ⑥ Result celebration — `ResultScreen`
- **Layered, ~1.1 s:** grade circle `elasticOut` reveal → `PulseRings` heartbeat →
  `Twinkles` behind → `CelebrationOverlay` confetti (cleared & acc ≥ 85) →
  `CountUp` score/coins → `Sticker('FULL COMBO')` if FC → `MascotBubble` verdict.
- **Haptic:** `Haptics.success()` (heavy → light → light). **Sound:** `win` / `lose`.

### ⑦ Combo streak — `ComboCounter` (HUD)
- **Motion:** number **punch-scales 1.45→1.0** (`press`, 220 ms) on every increase.
- **Milestone (every 50):** bigger pop + brief color flash; `Haptics.light()`;
  **Sound:** `combo`. Routine hits use the note burst only (no extra haptic spam).

### ⑧ Fever activation — `gameplay_screen` `_feverOverlay` + HUD
- **Motion:** gold radial screen overlay breathes (`gentle`, ~1.1 s loop); fever
  bar fills to 1.0; **"FEVER ×2"** tag scale-ins; lane/note glow boosted.
- **Haptic:** `Haptics.heavy()` once at trigger. **Sound:** `fever`.

### ⑨ Locked song tap — `SongCard` locked
- **Motion:** "nope" shimmy — short horizontal shake (`±6 px`, 2 cycles, 260 ms)
  + lock icon jiggle; then present the unlock options sheet.
- **Haptic:** `Haptics.error()` (two soft taps). **Sound:** `locked`.
```dart
// reuse the gameplay shake recipe: AnimationController + Transform.translate
final dx = t == 0 ? 0.0 : math.sin(t*math.pi*4) * 6 * (1 - t);
```

### ⑩ Equipped cosmetic state — `RewardsScreen` tile
- **Resting state:** persistent **gentle glow pulse** (low amplitude) + filled
  "Dipakai" pill. Distinct from owned-but-unequipped (static, tap = `select()`).

### ⑪ Mission completion — Home / Rewards
- **Motion:** checkbox pops (`bouncy`), title strikethrough fades in, badge
  "flies" to the shelf (`AnimatedPositioned`/`Hero`) + sparkle; `MascotBubble`
  switches to `Mood.cheer` ("Misi beres! 🎉").
- **Haptic:** `Haptics.success()`. **Sound:** `mission`.

### ⑫ Bottom navigation tap
- *Status:* the app currently uses a **home hub + `Bouncy` quick-action tiles**,
  not a persistent bottom bar. When one is added, spec:
- **Motion:** tapped icon bounces (`scale 0.9→1.0`, `bouncy`); an **active pill**
  slides under it (`AnimatedAlign`, `fast`); label fades in for active only.
- **Haptic:** `select()`. **Sound:** `tap_soft`.

---

## 4. Behavior systems

### Glow
- Colored via `AppShadows.glow(accent, blur, y, a)`.
- **Resting** a≈0.2–0.3; **interactive/active** ramps to ≈0.5; **CTA** breathes
  (triangle wave off a 2.2 s controller). Cap: only a handful of glowing
  elements animate per screen — the rest hold a static glow.

### Pulse
- `PulseRings` = the heartbeat motif. Behind **focal points only** (splash logo,
  home hero emblem, result grade). 2.6 s loop, 3 rings, expand + fade.
- Meters (HP/fever/progress) fill with implicit width animation.

### Floating
- `Mascot` bobs on a sin wave (≈4% of size, 2.2 s reverse). Background blobs
  drift on an 18 s loop (`NeonBackground`). Keep amplitude small — *drift, not bounce*.

### Particle / sparkle
- `CelebrationOverlay` — **one-shot** confetti + central sparkle for result &
  big rewards (≤90 pieces).
- `Twinkles` — **ambient**, low density (≤14) behind heroes / grade.
- Note **hit burst** — expanding ring + flash at the receptor on each hit
  (`NotePainter`). All particle work skips when `reduceEffects` is on.

## 5. Haptics map  (`lib/core/haptics.dart`)
| Trigger | Call |
|---------|------|
| note hit, card/chip tap, combo milestone | `Haptics.light()` |
| button press, miss, reward-claim start | `Haptics.medium()` |
| fever activation, fail | `Haptics.heavy()` |
| chip / tab / toggle / equip | `Haptics.select()` |
| result cleared, mission complete | `Haptics.success()` (heavy→light→light) |
| locked tap | `Haptics.error()` (light→light) |

All gated by `Haptics.enabled` (mirrors the vibration setting).

## 6. Sound effect categories  (`AudioService.playSfx('<name>')`)
- **UI:** `tap`, `tap_soft`, `back`, `toggle`
- **Gameplay:** `hit`, `perfect`, `miss`, `combo`, `fever`
- **Rewards/flow:** `reward`, `coin`, `unlock`, `mission`, `win`, `lose`, `locked`

Shipped today: `hit`, `perfect`, `miss`. Add the rest as short WAVs via
`tool/generate_assets.py` (the same procedural synth). All respect `GameState.sfx`.
Keep SFX < 200 ms and quiet (≈0.7 vol) so they layer without mud.

## 7. Performance & "never overdone" guardrails
- One repeating `AnimationController` per animated widget; **always dispose**.
- Prefer **implicit** anims (`AnimatedScale/Container/Align`, `AnimatedSwitcher`,
  `TweenAnimationBuilder`) for state changes; reserve explicit controllers for
  loops & one-shots.
- `RepaintBoundary` around busy painters (already on `NeonBackground`).
- Drive the HUD off a `ValueNotifier` frame tick, **not** `setState`, so anims
  never stall the game loop.
- Avoid `maskFilter` blur on many elements at once; cap particle counts.
- **Max one** `elasticOut`/confetti moment visible at a time; **≤2–3** looping
  anims on screen. When in doubt, make it shorter.
