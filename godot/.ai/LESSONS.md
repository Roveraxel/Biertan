# LESSONS (mistakes already made in this project; read before you propose any GDScript)

Every item below happened. Do not repeat it. Claude adds new entries after each audit.

## 1. Never write code you cannot compile
On 2026-11-16 an AI edited `world_builder.gd`, `trees.gd` and `mats.gd` directly. The game stopped compiling. Without the Godot export check you only write patches into `.ai/proposals/` and do not touch `.gd` files (ARCHITECTURE.md rule 0).

## 2. Type inference on base classes
Wrong: `var ca := a.albedo_color` where `a: Material` (Material has no `albedo_color`; the type cannot be inferred). Right: cast first, `var sa := a as StandardMaterial3D`, check for null, then `var ca: Color = sa.albedo_color`.
General rule: `:=` is only for values whose static type is obvious. Results of `Dictionary.get()`, `call()`, untyped arrays and anything accessed on a base type need an explicit type.

## 3. Call functions where they exist
Wrong: calling `dist_to_segment(...)` inside `WorldBuilder`; it exists only as `Level.dist_to_segment` (static). Right: `Level.dist_to_segment(...)`. Before using a helper, search the project for its `func` line and note which class owns it. `Village.seg_dist` is a different function.

## 4. Randomness must be deterministic
Wrong: `randf()`, `randi()`, `Array.shuffle()`, `randomize()`. They use the global generator and break repeatable levels and the `NetRandom` rule. Right: use the level's `rng` (`rng.f()`, `rng.i(n)`) or a `NetRandom` seeded from the level id.
Do not replace seeds that already work (example: changing `hash(L.id)` to a custom string hash changed every forest layout for no benefit).

## 5. Performance on the web build
Wrong: one `Batch` plus `commit()` per tiny decoration (hundreds of mesh nodes per level). Right: collect everything into a few `Batch` objects (one per chunk or per material) and commit once. Web export has a strict draw-call and node budget.

## 6. Layering and z-fighting
Ground decals sit at fixed heights: roads 0.012 to 0.014, textured patches around 0.015 to 0.02. A new flat layer at a nearby height flickers. Pick a distinct height and check it against `world_builder.gd` before adding one.

## 7. Stay inside your task
Edit only the files named in your task. Do not start work from the Known Issues list on your own; another AI may already be working on the same files. Write to `.ai/` and nothing else.

## 8. Do not widen the scope of an existing function
Changing the signature of an existing function (for example `leaf_color(seed, k, spring)`) means every caller must be checked. Prefer adding a new function.

## 9. Godot 4 syntax only
Use `@export`, `@onready`, `signal.connect(callable)`, `await`, `super()`. Never `onready`, `yield`, string-based `connect`, `KinematicBody`, `export var`. Typed loops: `for x: float in [1.0, 2.0]:`. Lambdas that capture and change a local variable do not change the original (captured by value).

## 10. Report exactly what you did
When you finish, list the file path, the lines you changed and what you could not check. Update the Recent Changes section of `.ai/HANDOFF.md`. Never say "done" for something you did not run.
