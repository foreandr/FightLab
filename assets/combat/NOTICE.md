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
  assets, CC BY 4.0. Used for guard, guarded walking and kicks.
- `outfits/`: Clint Christopher Canada, clothing and trimmed body meshes derived
  from Quaternius, CC BY 4.0. FightLab uses different cloth colours and flat materials.
- `scripts/vendor/build_sparring_clips.gd`: derived from Clint Christopher Canada's
  `tools/build_fight_animations.gd`, MIT. FightLab replaces the entry point and adds
  a compact boxing hook using the existing skeletal IK and planted-foot helpers.
- `animations/boxing.res`: FightLab's generated hook adaptation, CC BY 4.0.

These are authored skeletal clips. We do not assert that they are motion capture.
Skeleton names, rest transforms and skin weights are compatible; the same 65-bone
rig drives both bodies. No proprietary game assets are used.

License texts are in `licenses/`. CC0 legal text:
https://creativecommons.org/publicdomain/zero/1.0/legalcode
CC BY 4.0 legal text: https://creativecommons.org/licenses/by/4.0/legalcode

To reproduce the hook with Godot 4.6:
`godot --headless --path . -s res://scripts/vendor/build_sparring_clips.gd`
