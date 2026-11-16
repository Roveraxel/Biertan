# Meshy Environment Concept Sheets

All eight Meshy text-to-image jobs completed successfully. These are concept/reference sheets for Claude's environment-art implementation. They are not production-ready sprite atlases or imported Godot assets; Claude must extract/redraw individual modules, standardise pixel scale, and validate them in-game.

| Area | Meshy task | Generated reference |
|---|---|---|
| Wolf Forest | `01a1e567-6d7e-7513-8f23-1d712be48308` | [Open forest asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-6d7e-7513-8f23-1d712be48308_0.png?sign=1794960000-f7b33d6899f3a3f6a502d6ba125dbf69) |
| Hollow Hills | `01a1e567-74e6-73d3-a178-a7ea8a12e59d` | [Open hills asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-74e6-73d3-a178-a7ea8a12e59d_0.png?sign=1794960000-17136da0d219b670cb17016b14f81395) |
| Salt Caves | `01a1e567-7a82-7602-80a2-153d6c318706` | [Open caves asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-7a82-7602-80a2-153d6c318706_0.png?sign=1794960000-960bd607ade4dbfa49c7d84fb1e0f688) |
| Muma's Hollow | `01a1e567-811c-7436-a0e5-9d0b3ae27750` | [Open hollow asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-811c-7436-a0e5-9d0b3ae27750_0.png?sign=1794960000-7b08ad4a6ca8cabf273196bc8e3c897c) |
| Burnt Vineyards & Drowned Quarry | `01a1e567-87bd-739f-89a9-55136cd7bac3` | [Open vineyard/quarry asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-87bd-739f-89a9-55136cd7bac3_0.png?sign=1794960000-87c831a000671f37ce1c5681a2e60b77) |
| Saxon Village Hubs | `01a1e567-8e21-77b7-89d2-8cca743cdf06` | [Open village asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-8e21-77b7-89d2-8cca743cdf06_0.png?sign=1794960000-4dad2ecd77b16eec15043da28e17c134) |
| Biertan Fortifications & Church | `01a1e567-9418-7395-abf8-33c730447784` | [Open fortress/church asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-9418-7395-abf8-33c730447784_0.png?sign=1794960000-331cb0d372a8b2b2145bad7f6a83c2a3) |
| Arena & Shared Kit | `01a1e567-9ad3-75b9-bd25-cdf73bd7cfae` | [Open arena/shared asset sheet](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e567-9ad3-75b9-bd25-cdf73bd7cfae_0.png?sign=1794960000-bf3fc5d7062e46ac50c9210e46658ab6) |

## Claude handoff instructions

- Use each sheet as a visual direction and module inventory.
- Preserve the current character/NPC/enemy sprites and all gameplay logic.
- Extract individual assets as separate transparent sprites or coherent tile sets. Do not use the whole sheet as a game texture.
- Match the existing world scale, pixel cluster density, top-down 3/4 perspective, anchor points, y-sort and collision conventions.
- Rework any Meshy-generated details that are painterly, noisy, perspective-inconsistent or too detailed for the game's existing art style.
- Retain source/editable files and record provenance. Confirm Meshy's commercial-use terms before release.
- Implement on a feature branch after identifying the source commit corresponding to the current Pages deployment.
- Validate every asset in-game and run `godot --headless --path . -- --autotest`.

## Existing Stână references

The Stână concept, fence/haystack refinements and modular wattle fence sheet are listed in [README.md](README.md). Those references remain the first art benchmark.
