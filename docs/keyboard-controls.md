# Keyboard and internal controls

Every new interactive feature must support keyboard input and semantic scripting. Desktop mouse automation should not be needed for routine testing.

## Everywhere

- F10 opens a searchable action panel and pauses gameplay while the panel is open.
- Type to find a control, use Up/Down to select it, and Enter to activate it.
- Tab / Shift+Tab moves between controls. Enter or Space activates focused buttons.
- Settings, text, and colors accept a typed value in the panel's value field. Submit that field with Enter, including an empty value to clear text.
- Tabs and drop-down choices appear individually in action search.
- Inventory: choose Pick up, then a compatible Place action. This calls the real transfer handlers without mouse events.
- Timeline clips have Select, Remove, and Move actions. Move accepts TRACK,SECONDS, such as BODY,0.5.
- The timeline ruler supports Left/Right for frames, Shift for ten-frame steps, and Home/End.

## Pavlov screens

- Y approves; X or N rejects.
- Left/Right browses; Z undoes the last vote. Clothing previews turn with A/D.
- Number keys choose piles (1–4 for animations, 1–3 for clothing).
- Animation camera: WASD moves, Q/E moves vertically, Shift accelerates movement, middle-drag rotates, and the mouse wheel or Page Up/Down zooms. Shift+arrows rotates by keyboard. F resets the view.
- Animation playback: P pauses, T toggles slow motion, C cycles categories (Shift+C reverses).
- Clothing: B switches body.
- Escape returns to Dev.

## Other editors

- Character creator: brackets rotate; + / - zooms. Accessory-position pads accept arrow keys, with Shift for fine steps.
- Loadout: brackets select body parts; A/D rotates; + / - zooms. Inventory transfers are available in F10 search.
- Placement: brackets select characters; I/J/K/L moves them; Shift makes fine moves; R rotates; Delete removes; + / - zooms.
- Spell drawing: focus the drawing canvas using Tab or F10, move the pen with arrows, Space adds a point, Enter finishes, Backspace removes a point, and Delete clears. Shift makes finer moves.
- Animation inspection: arrows orbit, Page Up/Down zooms; existing WASD/QE camera movement remains available.
- Combat: numpad 2/4/6/8 positions the in-game aim point without moving the system pointer; Shift makes fine steps. Page Up/Down selects fighters. Numpad 7/9 provides left/right attack bindings; numpad 0 provides blocking. Numpad Enter records an aim-calibration sample. Existing combat bindings remain usable.

## Internal scripting API

Use the running instance's BotRuntime interface instead of desktop input:

- ui.list returns enabled visible actions with id, label, and kind.
- ui.activate accepts id and optional value. It invokes the same semantic handlers as the keyboard action panel.
- input.tap accepts key and optional ctrl, shift, and alt, and sends a press/release through Godot's input system.
- input.key accepts those fields plus pressed for held movement, charging, and release tests.
- menu.open supports pavlov, clothing, character_create, placement, replays, and the existing menus.
- screenshot captures through the game itself.

List actions again after changing screens or rebuilding a panel. IDs refer to the live controls and stale IDs are rejected. UI controls that are hidden or disabled cannot be activated. Use isolated test saves when testing persistent decisions.
