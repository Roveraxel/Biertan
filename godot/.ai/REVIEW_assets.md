# T9 missing asset scan (script, exact; Claude 2026-11-16)
Checked: literal `res://` paths, `Audio.sfx/sfx_at("name")` sounds (audio/<name>.ogg|mp3|wav), `add_decor(at, "name")` (sprites/Props/<name>.png). Dynamic names built with `%` or variables are not checked.

- scripts/bosses/boulder.gd:17: `sprites/Props/boulder.png` has no file. Harmless: code falls back to a grey circle. Optional: add a boulder sprite.
- scripts/levels/hillchurch.gd:63: `coffin.png` has no file. Harmless: falls back to `sarcophagus`.
- scripts/levels/malancrav.gd:105: **REAL: sound `bark` has no file (audio/bark.ogg|mp3|wav); Azorel's bark is silent**
- scripts/levels/tunnel.gd:214: **REAL: sound `bark` has no file (audio/bark.ogg|mp3|wav); Azorel's bark is silent**
- scripts/levels/tunnel.gd:226: `rubble.png` has no file. Harmless: falls back to `bone` (a rubble sprite would look better).
- scripts/levels/tunnel.gd:241: **REAL: sound `bark` has no file (audio/bark.ogg|mp3|wav); Azorel's bark is silent**
- scripts/levels/viscri.gd:258: `key_iron` has no sprite. Harmless: falls back to `bone`.

## Result
One real gap: the `bark` sound (malancrav.gd:105, tunnel.gd:214 and 241). The four sprite gaps all have fallbacks. Fix: add `audio/bark.ogg` (a short dog bark), or point the three calls at an existing sound.
