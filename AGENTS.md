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
