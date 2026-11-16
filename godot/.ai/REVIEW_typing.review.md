# Review of REVIEW_typing.md (Claude, 2026-11-16 07:00)
Verdict: changes needed (do not apply any suggestion yet)
1. Line numbers are wrong. actor.gd: report says 31, real line is 41 (`func set_figure(names, h: float)`); brazier.gd: says 25, real 26; gate.gd: says 15, real 23. The model counted lines itself. Fix: the prompt now sends the file with line numbers (`cat -n`).
2. actor.gd suggestion `names: Array[String]` is wrong: callers pass a String (`set_figure("hunter", 1.3)`, `PixelFigure.make("earth_dog", 0.75)`) and `make()` does `names if names is Array else [names]`. A typed array would break the game. Correct fix, if any: `names: Variant`.
3. `for k in 8:` / `for i in 4:` (brazier.gd, gate.gd) are valid GDScript; the iterator is an int. The suggested `range(8)` and `[0, 1, 2, 3]` are no improvement (the second is slower and untyped). Report only when the iterated collection is an untyped Array of non-obvious type.
4. Duplicate entries (board.gd:29 twice) and the file contains the model's raw "Thinking... ...done thinking." text (10 blocks). Fix: the runner now strips it.
5. Not applied: nothing from this report goes into the code. The real typing gaps found so far: only `Actor.set_figure(names, ...)` and `PixelFigure.make(names, ...)` (untyped, intentionally Variant).
