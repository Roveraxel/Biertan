# Expanded Meshy Asset Library — Current Content Pass

This supplemental set targets specific landmarks, quest spaces, village identities and folklore motifs found in the current Biertan source. These are concept/reference sheets, not production sprite atlases. Claude should extract and standardise individual assets before integration.

## Generated sheets

| Theme | Meshy task | Reference |
|---|---|---|
| Stână shepherd farmstead | `01a1e56a-f65b-744b-9a6e-e054a0acc2cb` | [Open Stână kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56a-f65b-744b-9a6e-e054a0acc2cb_0.png?sign=1794960000-477d0c1139171d97dfd6e9f47cc9c2f5) |
| Marriage Prison defence | `01a1e56a-fc9f-7568-a720-6dbb0187c035` | [Open Marriage Prison kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56a-fc9f-7568-a720-6dbb0187c035_0.png?sign=1794960000-8a0babfacc1a2a9bf56b350301835226) |
| Richiș Green Men church | `01a1e56b-0226-7787-8f5b-42853d94e5ab` | [Open Richiș kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56b-0226-7787-8f5b-42853d94e5ab_0.png?sign=1794960000-c4968e19a290209f474b01f55d67ecfc) |
| Moșna Bacon Tower | `01a1e56b-082f-75da-aa75-2ef90dc6b5ee` | [Open Moșna kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56b-082f-75da-aa75-2ef90dc6b5ee_0.png?sign=1794960000-2d5476c15f269d0013797fae5802d37e) |
| Rural village life props | `01a1e56b-0e73-7511-9d75-8ccafac3be47` | [Open village-life kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56b-0e73-7511-9d75-8ccafac3be47_0.png?sign=1794960000-2088aa1ca6567877cb79288c3509aa4a) |
| Romanian folklore rituals | `01a1e56b-1510-74c1-826d-a3a88a759090` | [Open ritual kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56b-1510-74c1-826d-a3a88a759090_0.png?sign=1794960000-d0efd9c561b22f3c3f2afedeb376bc3c) |
| Strigoi churchyard & cemetery | `01a1e56b-1b18-7567-9ddf-ffbb66ddd5d6` | [Open cemetery kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56b-1b18-7567-9ddf-ffbb66ddd5d6_0.png?sign=1794960000-5b18ffbc9d4f54e357fe21ba54ccd7ed) |
| Boss arena landmarks | `01a1e56b-20d1-726a-8d32-a78194d6147e` | [Open boss landmark kit](https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e56b-20d1-726a-8d32-a78194d6147e_0.png?sign=1794960000-283935bff3dee7ba181387257a96bf4a) |

## Current source coverage

The current inspected Godot source README documents four regional story arcs:
- Saschiz → Wolf Forest → Moon Clearing / Vârcolac
- Richiș → Hollow Hills → Salt Caves → Muma Pădurii's Hollow
- Moșna → Burnt Vineyards → Drowned Quarry / Balaur
- Biertan → Marriage Prison → Three Walls → church / Vlad

It also documents the optional Bear of the Garden, Wolf Forest side quests, village NPCs and a bestiary. The new sheets deliberately cover these specific spaces and recurring world details. If further chapters or locations exist outside this inspected source branch, add them as separate briefs after locating their source scenes and references.

## Claude production rules

- Start with Stână as the first in-game art benchmark, then prioritise shared reusable assets.
- Treat sheets as reference boards. Do not import a full sheet as a single game texture.
- Split assets into transparent individual sprites or coherent tile atlases; normalise scale, palette, pixel cluster size and anchors.
- Keep the existing player, Azorel/dog, NPC and enemy sprites intact.
- Preserve level geometry, quest logic, collision, navigation, y-sort, triggers, combat lanes and camera.
- Add asset provenance and check current Meshy commercial terms before commercial release.
- Work on a feature branch, retain rollback points and test desktop plus web builds.
