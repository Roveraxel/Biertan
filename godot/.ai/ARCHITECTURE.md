# ARCHITECTURE (read before modifying code)

Shared by every AI tool working on this folder (Claude, ChatGPT Desktop, Cherry Studio with Qwen, Kimi, Gemini Flash).
Read this file and `HANDOFF.md` before changing anything. Update `HANDOFF.md` before you finish and before you push.

## Engine
- Godot 4.7.2 (stable), GDScript only, Compatibility renderer, 3D scene presented top-down with pixel-art sprites.
- Web export is the playtest target (GitHub Pages, branch `gh-pages` of Roveraxel/Biertan). Keep everything web-safe (no threads, no native extensions).
- Project root: `Biertan/godot/` (contains `project.godot`). Repo root: `Biertan/`. Overall context: `PROJECT_CONTEXT.md` at the repo root.

## Folder structure (`godot/`)
- `scripts/core/` autoload-style singletons and base classes: `game_manager.gd` (`G`), `level_loader.gd` (`Loader`), `level_base.gd` (`Level`), `village.gd`, `narration.gd`, `audio_manager.gd` (`Audio`), `events.gd` (`Events`).
- `scripts/levels/` one file per place, each `extends Level` (or `Village`) and builds itself in `build()`.
- `scripts/quests/` one quest class per area (`sig_quest`, `bt_quest`, `fin_quest`, `vis_quest`...).
- `scripts/actors/` `prop.gd` (NPCs, clues, triggers), `enemy.gd`, `player.gd`, `wood_gate.gd`, `decor.gd`, `pixel_figure.gd`.
- `scripts/bosses/` one script per boss.
- `scripts/ui/` HUD, story cards, map. `scripts/world/` world builder, map data.
- `sprites/Pixel/<name>/` rotation_<dir>.png and walk_<dir>_<n>.png (8 directions: south, south-west, west, north-west, north, north-east, east, south-east). `sprites/Story/` story-card pictures. `sprites/Props/`. `textures/`. `audio/` (voice lines in `audio/voice/<card>_<n>.mp3`).
- Do not edit `*.import`, `*.uid` or generated files by hand.

## GDScript typing rules (strict)
- Every variable, constant, parameter and return type is written out: `var speed: float = 3.0`, `func hit(dmg: int) -> void:`.
- Use `:=` only when the right side has an obvious static type. When the type cannot be inferred (Variant, untyped dictionary or array value, `call()` results), declare it: `var p: Vector2 = d.get("pos")`.
- Typed loops: `for x: float in [-1.0, 1.0]:`; typed arrays: `Array[Node3D]`.
- No untyped `Variant` unless unavoidable; cast with `as` and check for null.
- Prefer `class_name` + static typing to string-based lookups; dictionary data (level layouts, story cards) keeps one schema per dictionary.
- Files start with a `##` doc comment saying what the class is. Comments are short and plain.
- Code must parse headless: run `godot --headless --export-release Web build/web/index.html` and fix every `SCRIPT ERROR` / `Parse Error` before handing off.

## Signal conventions
- Global gameplay events go through the `Events` singleton, never by reaching into other nodes (example: `Events.prop_used`).
- Signal names are past-tense snake_case (`prop_used`, `quest_updated`, `boss_defeated`); handlers are `_on_<source>_<signal>`.
- Declare signals with typed parameters: `signal prop_used(prop: Prop)`.
- Connect with `Callable`s (`sig.connect(_on_x)`), disconnect in `_exit_tree` when the emitter outlives the listener.
- Quests react to events; levels do not call quest code directly except through the `quest` object on `Level`.

## Level API (level_base.gd)
add_block, add_block_rotated, add_decor, add_prop, add_torch, add_decal, add_patch, add_trigger, add_cobbles, wall_door, cellar_head, road_gate, gap_gate, find_path, is_free, prop_by_id. Villages call `compact()` before building.

## Test hooks (URL query on the web build)
`?level=<id>&fast&near=<prop id>&filter=0&flags=a,b&do=story:<card>|<method>`

## Workflow rules
1. Read `.ai/ARCHITECTURE.md` and `.ai/HANDOFF.md` first.
2. Make small, reviewable changes; do not reformat files you are not changing.
3. Update `.ai/HANDOFF.md` (all five sections) before finishing and before any push to GitHub.
4. Never push secrets or API keys. Commit messages say what changed and why.
