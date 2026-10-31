# FightLab development rules

- Godot 4 and GDScript only.
- Optimize for integrated graphics using the Compatibility renderer.
- Prioritize performance, responsiveness, and maintainability.
- Keep the project runnable after every change.
- Never introduce missing file references.
- Never replace working functionality unnecessarily.
- Validate changes before committing.
- Prefer small, independently verifiable changes.
- Keep all required project assets in the repository.
- Do not introduce external dependencies without justification.
- Do not implement gameplay until explicitly instructed.
- Every interactive feature must have a keyboard route, including editors and review tools. Keep keyboard focus enabled and expose actions through the internal scripting interface.
- Prefer BotRuntime ui.list, ui.activate, input.tap, and input.key for testing. Avoid desktop mouse automation when an internal or keyboard route exists.
- After each game change, refresh by launching a fresh FightLab game window so the user can see the update.
- Launch the game maximized in a normal window (not exclusive fullscreen) by default.

- Universal character focus: hover blue, click gold selection without camera movement. F locks the selected target; selection and lock-on are independent. Reuse scripts/focus_visuals.gd and scripts/third_person_camera.gd.
- Clicking empty arena ground clears selection but retains an active lock. F then unlocks to free third-person control, preserving orbit/zoom. Free movement follows camera heading; locked characters face the target. Middle drag orbits and wheel zooms in both states. Spell free aim uses the crosshair. Never silently reselect a bot after explicit deselection.
- Shared mechanics ownership is documented in docs/shared-character-mechanics.txt. Reuse combat_aim.gd, character_aim_pose.gd, character_movement.gd, third_person_camera.gd and animation_channels.gd across modes; keep UI/calibration adapters separate and do not duplicate mechanics or mutate cached animation resources.
- Combat modes inherit scripts/combat_world.gd or bind scripts/combat_runtime.gd. Reuse combat_spell_rules.gd for authored specs and melee_contact.gd for limb hits. Do not copy projectile flight, damage, resource payment, spell dispatch or actor/wall updates into modes. The integration contract and hooks are in docs/combat-runtime.txt; tests/combat_runtime_contract_test.gd verifies a new mode without Story/Create scenes. spell_arena.gd is a historical visual study, not a gameplay superclass.
- Levels are independent providers of collision geometry, spawns and optional bounds via scripts/combat_level.gd and CombatWorld.use_level. Never import pit dimensions or assume a floor at Y=0 inside generic mechanics/editors. Use terrain queries and level placement/constraint APIs; see docs/combat-levels.txt and tests/combat_level_independence_test.gd. Unspecified levels are unbounded.
