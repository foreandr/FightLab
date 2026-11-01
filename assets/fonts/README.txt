FightLab shared typography

The project-wide font is assets/fonts/game_font.tres, referenced by
gui/theme/custom_font in project.godot. Menus, themed dialogs, custom timeline
drawing and Label3D world labels inherit this font through Godot's theme system.
Do not add per-screen font overrides. To change the family later, replace the
base_font reference in game_font.tres once.

Current font: Cinzel variable (weights 400–900), unmodified.
Copyright 2020 The Cinzel Project Authors.
Source: https://github.com/google/fonts/tree/main/ofl/cinzel
Upstream: https://github.com/NDISCOVER/Cinzel
License: SIL Open Font License 1.1, included in OFL.txt and embedded in
game_font.tres metadata so exported builds retain the notice and license.

Cinzel is the user's approved interim alternative to Trajan Pro. Trajan Pro
is not bundled. Keep OFL.txt with Cinzel when distributing the game.
