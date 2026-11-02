extends RefCounted
## Defer singleton lookup until runtime so standalone SceneTree scripts can preload
## combat/camera components before autoloads have been registered.
static func service()->Node:
 return (Engine.get_main_loop() as SceneTree).root.get_node("GameSettings")
