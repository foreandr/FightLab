# FightLab diagnostics

FightLab writes diagnostics under Godot's per-project user data folder:

`%APPDATA%\Godot\app_userdata\FightLab\logs`

`latest_session.txt` points to the current session folder. Each session contains:

- `events.jsonl`: timestamped scene changes, keyboard/controller input, clicks, UI changes, performance snapshots, character actions, hits, deaths, and story fight outcomes.
- `clicks.jsonl`: a focused copy of mouse and touchscreen presses/releases, with the control or world object under the pointer when available.
- `interactions.jsonl`: slider, selector, color, text, and button changes.
- `console.log`: messages mirrored from Godot's logging stream.
- `engine_console.log`: new lines from Godot's native file log during this run, including engine output that arrives outside the script logger.
- `errors.log` and `errors.jsonl`: engine errors and warnings with source file, line, function, rationale, code, and available script backtraces.
- Slow-frame batches are recorded in `events.jsonl` when a rendered frame takes at least 33.3 ms. They summarize the count, peak, last frame and severity over roughly one-second windows. Physics catch-up events record frames that need multiple physics steps before rendering.
- `slow_engine_timing` events sample Godot's process, physics and navigation timing monitors once per second. Process work above 25 ms or physics/navigation work above 8 ms is reported; especially high samples are marked as errors.
- `slow_operation_batch` events group measured hot loops by name once per second. Resource preload, scene setup and other explicitly timed operations are recorded as `operation_timing` events with elapsed milliseconds.

Godot's own session log is also enabled at `logs/godot.log`; it captures startup output and native crash reports that cannot be handled after the script runtime has stopped. Each session mirror starts at the end of the existing native log so older runs don't appear in the current session's `engine_console.log`. The engine keeps ten rotated log files. FightLab rotates its session files at 8 MiB with three backups and retains the latest twenty session folders.

All event files use JSON Lines, so each event can be inspected independently or filtered with common log tools.
