FightLab shared typography

Active interface family: Rajdhani SemiBold / Bold, Indian Type Foundry.
Source: https://github.com/google/fonts/tree/main/ofl/rajdhani
License: SIL Open Font License 1.1; bundled in Rajdhani-OFL.txt.

scripts/ui_design.gd owns the interface font tokens. The matching project-wide
font alias is assets/fonts/game_font.tres, referenced by gui/theme/custom_font.
CyberInterface applies this family to local legacy themes, dynamic controls and
Label3D names. Custom UI drawing uses the same shared font token. New screens
should inherit the theme instead of adding their own font family.

Historical family retained on disk: Cinzel variable (weights 400–900), unmodified.
Copyright 2020 The Cinzel Project Authors.
Source: https://github.com/google/fonts/tree/main/ofl/cinzel
Upstream: https://github.com/NDISCOVER/Cinzel
License: SIL OFL 1.1, bundled in OFL.txt. Keep that notice with Cinzel if shipping
historical assets. Trajan Pro is not bundled.
