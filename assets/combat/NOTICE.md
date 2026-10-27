# FightLab third-party assets

Vendored from https://github.com/clintcan/3d-fighter at
7684f26df63fd396137900d07f86f4487cc7ede2 (2026-10-26).
No upstream executable, network code, or runtime download is required.

- `../characters/base/`: Quaternius Universal Base Characters, Standard/free,
  https://quaternius.itch.io/universal-base-characters — CC0 1.0.
- `hair/`: hairstyles, eyebrows and textures from the same Quaternius pack — CC0 1.0.
- `animations/UAL1_Standard.glb`: Quaternius Universal Animation Library,
  https://quaternius.itch.io/universal-animation-library — CC0 1.0.
- `animations/UAL2_Standard.glb`: Quaternius Universal Animation Library 2,
  https://quaternius.itch.io/universal-animation-library-2 — CC0 1.0.
- `animations/fight_anims.res`: Clint Christopher Canada, adapted from Quaternius
  assets, CC BY 4.0. Used for guard and guarded walking; the original kick choreography is adapted below.
- `outfits/`: Clint Christopher Canada, clothing and trimmed body meshes derived
  from Quaternius, CC BY 4.0. FightLab uses different cloth colours and flat materials.
- `scripts/vendor/build_sparring_clips.gd`: derived from Clint Christopher Canada's
  `tools/build_fight_animations.gd`, MIT. FightLab replaces the entry point and adds
  compact left/right hooks and adapts front/high kicks for each leg. FightLab adds
  ball-of-foot anchoring at dense samples, revised timing, weight shift and head-height
  roundhouse approach paths using the existing skeletal IK/foot-plant helpers.
- `animations/boxing.res`: FightLab's generated hook and kick adaptations, CC BY 4.0.

These are authored skeletal clips. We do not assert that they are motion capture.
Skeleton names, rest transforms and skin weights are compatible; the same 65-bone
rig drives both bodies. No proprietary game assets are used.

License texts are in `licenses/`. CC0 legal text:
https://creativecommons.org/publicdomain/zero/1.0/legalcode
CC BY 4.0 legal text: https://creativecommons.org/licenses/by/4.0/legalcode

To reproduce the six hook/kick clips with Godot 4.6:
`godot --headless --path . -s res://scripts/vendor/build_sparring_clips.gd`

## Grassland spellcasting study

- `animations/spells.res`: original FightLab casting poses on the Quaternius CC0
  rig, CC BY 4.0. Ten gestures plus a neutral casting idle. These are authored
  poses, not extracted Skyrim, Oblivion or anime/game animation assets.
- `scripts/vendor/build_spell_clips.gd`: FightLab composition code reusing the
  vendored MIT skeletal IK and foot-plant helpers in `build_sparring_clips.gd`.
  Rebuild with Godot 4.6 using `-s res://scripts/vendor/build_spell_clips.gd`.
- Meadow geometry, grass blades, sky/ground settings and spell-effect meshes are
  generated directly by FightLab code. No additional asset or runtime dependency.

## Dynamic elemental duel

- `animations/duel.res`: composed movement/air-casting library, CC BY 4.0.
  Sprint, takeoff, tucked jump and landing derive from Quaternius UAL1/UAL2 (CC0).
  Backflip/somersault choreography derives from Clint Christopher Canada's
  `fight_anims.res` / `build_flip_kick` (CC BY 4.0; retained source/license above).
  FightLab normalizes motion in model space, adds a trailing-arm dash and combines
  the original casting poses with compatible airborne lower-body motion.
- `scripts/vendor/build_duel_clips.gd`: FightLab composition code reusing the MIT
  skeleton sampling/IK helpers in the vendored baker. No proprietary game motion.
- Water surface/foam shader, droplet/splash effects, elemental clashes, health/round
  logic and camera are generated/implemented directly in FightLab. No new asset
  download, paid tool, service or runtime dependency is required.

## Shields, footwork and textured effects

- `vfx/*.png`: ten unchanged transparent PNG masks from **Kenney Particle Pack
  1.1**, https://kenney.nl/assets/particle-pack, downloaded 2026-10-27 from the
  official Kenney download. CC0. Original notice, including filter-template
  contributors, is preserved in `licenses/Kenney-Particle-Pack-CC0.txt`.
- `vfx/*.gdshader` and `scripts/elemental_vfx.gd`: FightLab's textured particle,
  water/fire surface, tapered-ribbon and curved hex-shield rendering code.
  The shader uses texture alpha as the mask to avoid multiplying down the pack's
  already subdued grayscale artwork a second time. PNG files are unmodified.
- `animations/duel.res` additionally includes CC BY 4.0 guarded walk adaptations
  from the previously credited `walk_guard`, a reversed CC0 UAL1 `Roll`, and
  original FightLab lateral footwork, backward dodge and two shield-gesture sets.
  Quaternius UAL2 `Idle_Shield_Break` supplies guard-break recovery (CC0).
  Existing MIT sampling, pose composition and two-bone IK helpers are reused.
