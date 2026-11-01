# Top-Down Godot Template

A top-down starter for **Godot 4**, built on the shared
**[godot-game-kit](https://github.com/duckenclaw/godot-game-kit)** addons plus the
[top-down controller](https://github.com/duckenclaw/godot-topdown-controller).
Sister template to the [FPS](https://github.com/duckenclaw/fps-godot-template) and
[2D sidescroller](https://github.com/duckenclaw/sidescroller-godot-template)
templates — same shared services, same modular-mechanics design, different genre.

The world is **3D** (so 3D models import straight in), and the same controller can
wear a **2D sprite** instead: the sprite stands upright in the 3D world, is lit by
every light, and casts a real shadow — the 2.5D / "HD-2D" look. Press **Tab** in the
demo to swap between the two.

## Install

The reusable kits under `addons/` are **git submodules**, so clone recursively:

```bash
git clone --recurse-submodules https://github.com/duckenclaw/topdown-godot-template
# already cloned without it?
git submodule update --init --recursive
```

Open in Godot 4.3+ and press F5. The demo is a small courtyard with training
dummies to hit and braziers whose point lights throw shadows at night.

## Controls (defaults)

| Action | Keyboard / mouse | Gamepad |
|--------|------------------|---------|
| Move | WASD / arrows | Left stick |
| Aim | Mouse cursor | Right stick |
| Attack (tap to chain a 3-hit combo) | LMB / J | X |
| Dodge roll (i-frames) | RMB / Space | B |
| Sprint | Shift (hold) | L3 |
| Walk/Run toggle | Caps Lock | — |
| Interact | F | Y |
| Rotate camera 45° | Q / E | LB / RB |
| Zoom | Mouse wheel | — |

Demo-only keys: **Tab** 3D model ↔ 2D sprite · **N** day/night · **P**
perspective/orthographic · **R** respawn.

All gameplay bindings are registered at startup and can be rebound/persisted via
the Settings Kit.

## What's inside

- **Shared kits (submodules):** `core` (services), `settings_kit` (settings +
  rebinding), `inventory_kit` (items), `components_kit` (Health, StateMachine).
- **`topdown_controller` (submodule):** `TopDownPlayer` (a `CharacterBody3D` with a
  state machine: idle, move, dodge roll, attack combo, hurt, death),
  `TopDownCamera` rig, `CameraFacingSprite3D` and `SpriteSheetLayout`.
- **`src/player/player_heroknight.tscn`:** the 2.5D sprite player using the
  HeroKnight animations (idle, run, attack1-3, roll, hurt, death).
- **`src/levels/demo_level.tscn`:** lighting setup — `WorldEnvironment` (ACES
  tonemapping, glow, fog, colour grading; `src/environment/day.tres` and
  `night.tres`), a shadow-casting sun, and flickering braziers with shadowed point
  lights.
- **`src/objects/`:** `TrainingDummy` (any node with a `Health` child is
  hittable) and `Brazier` (an `interact()` example).

## Graphics: 3D models, 2D sprites, or both

The player's look lives under its `Visual` node; gameplay code never touches it.

**3D models** — instance `addons/topdown_controller/player/player_3d.tscn`, delete the
placeholder `Mannequin` under `Visual` and drop in your glTF/FBX. If the model has
an `AnimationPlayer` with animations named `idle`, `run`, `attack1`… they play
automatically (aliases such as `walk`, `dash`, `hit`, `die` are also tried).

**2D sprites** — instance `addons/topdown_controller/player/player_sprite.tscn` (or
copy `src/player/player_heroknight.tscn`) and give `Visual/Sprite` your art:

- *Side-view art* (like HeroKnight): plain names — `idle`, `run`, `attack1`… — and
  the sprite flips to face left/right.
- *Top-down art with directions*: add a suffix — `run_down`, `run_up`, `run_side`
  (or `run_left` / `run_right`). The right one is chosen from where the character
  faces relative to the camera, and it keeps working while the camera rotates.
- *A grid sprite sheet*: instead of building `SpriteFrames` by hand, create a
  `SpriteSheetLayout` resource on the sprite's **Sheet Layout** property — set the
  texture and cell size, then add one `SpriteSheetAnim` per animation (name, row,
  column, frame count, fps, loop).

Tuning: `pixel_size` sets world size (HeroKnight uses 0.04 m per pixel); `offset.y`
puts the feet on the ground (half the frame height in pixels); `tilt` (0..1) leans
the sprite back toward a steep camera at the cost of a slightly stretched shadow.
Keep `alpha_cut` = Discard and `shaded` on for crisp, lit, shadow-casting sprites.

### Finding top-down character sheets

To get the most out of the controller, look for a sheet with idle, run, attack
(ideally a 2–3 hit combo), roll/dodge, hurt and death, in 4 directions
(down/up/side). Check the licence before committing art to a public repo: many
free packs allow use in games but **forbid redistribution**, so they must not be
pushed to a public repository.

| Pack | Directions & animations | Licence |
|------|-------------------------|---------|
| [Ninja Adventure](https://pixel-boy.itch.io/ninja-adventure-asset-pack) (Pixel-boy & AAA) | 4-dir, 16×16: walk, attack, jump, item, dead; huge cast of characters | **CC0** — fine to ship in a public repo |
| [Cute Fantasy RPG](https://kenmi-art.itch.io/cute-fantasy-rpg) (Kenmi) | 4-dir: idle, run, 3-stage attack combo, roll, hit, death, bow… | Paid tier; no redistribution |
| [The Swordsman](https://flowfrog101.itch.io/the-swordsman-4-directional-character) (FlowFrog101) | 4-dir: idle, run, roll, 2 attacks, hit, death | ~€1; commercial OK, no resale |
| [Mana Seed character base](https://seliel-the-shaper.itch.io/character-base) (Seliel the Shaper) | 4-dir paper-doll: walk, run, jump, sword & shield combat set, evade, hit | Free demo / paid; no redistribution |
| [Pixel Crawler](https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites) (Anokolisa) | 4-dir (WIP): idle, walk, run, slice/crush/pierce, hit, death | Free; check the bundled terms |

## Credits

The demo character art is **"HeroKnight" by Sven Thole**
([sventhole.itch.io/hero-knight](https://sventhole.itch.io/hero-knight)) — free for
use in any game project, commercial or not (do not resell the raw asset). If you
ship a game with it, crediting Sven is appreciated. Swap it for your own art by
replacing `assets/heroknight/` and `src/player/heroknight_frames.tres`.

## Modular mechanics

Exactly like the other controllers — two ways to turn abilities off:

1. **Config flags** on `TopDownConfig` → Inspector *Mechanics* group:
   `enable_sprint`, `enable_walk_run_toggle`, `enable_dash`, `enable_attack`,
   `enable_aim` (off = always face the move direction).
2. **Delete the state node** (`DashingState`, `AttackState`) from the player's
   `StateMachine`. Every transition into an optional state is gated by *flag AND
   state-present*, so either method disables it cleanly.

Core movement is always on.

## Start your own game

This repo is a GitHub **template** — *Use this template*, clone with
`--recurse-submodules`, then:

1. Rename the project in `project.godot` and set your own icon.
2. Pick a look: a 3D model under `Visual` (see `player_3d.tscn`) or your sprite
   sheet on `Visual/Sprite` (see above).
3. Build levels under `src/levels/`; start from the demo's `WorldEnvironment` + sun.
4. Tune feel on the `TopDownConfig` resource and the camera on the `CameraRig`
   node (pitch, distance, perspective/orthographic, zoom, rotation).
5. Edit the rebindable action list in `src/globals/game_settings.gd`.

### Rendering

The template uses the **Compatibility** renderer (like its sister templates), so it
runs on low-end hardware and the Web. You get real-time directional and point-light
shadows, glow, fog, tonemapping and colour grading. For SSAO, SSIL, volumetric fog,
SDFGI and softer contact shadows, switch *Project Settings → Rendering → Renderer*
to **Forward+** (desktop only); nothing in the template needs to change.

## Validate

```bash
godot --headless --path . --import
godot --headless --path . --script tests/test_topdown.gd   # expects RESULT: 0 failures
```

## License

MIT — see [LICENSE](LICENSE). The HeroKnight art keeps its own licence (see Credits).
