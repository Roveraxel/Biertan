Status: proposed

# Proposal: Forest Edge Tree Palette Following Trees.leaf_color Without Extra Nodes

## 1. Goal
Make the forest edge boundary trees generated in `_wilds()` (`scripts/world/world_builder.gd`) follow the new one-colour-family crown palette implemented in `Trees.leaf_color(seed_value, k)` instead of the hardcoded two-colour pair (`dark` and `rust`), while creating zero additional scene nodes and preserving web rendering performance.

## 2. Background & Problem
- In `Trees.leaf_color(seed_value, k)` (`scripts/world/trees.gd:1-6`), individual tree crowns pick one of 8 color families from `CROWNS` (6 green shades, 2 autumn ochre/rust shades) and generate a cohesive two-tone canopy (`base` for $k=0$ and a slight warm tint for $k=1$).
- Currently, `_wilds()` in `world_builder.gd` passes a single fixed pair of colors to all trees in each chunk:
  ```gdscript
  var bark := Color(0.13, 0.1, 0.08); var dark := Color(0.07, 0.12, 0.09)
  var rust := Color(0.2, 0.12, 0.07) if deep else Color(0.15, 0.17, 0.09)
  var parts := _tree_parts(bt, bark, dark, rust)
  ```
  This leaves all background forest edge trees monochromatic and dull, disconnected from the village tree palette.

## 3. Architecture & Performance Constraint (No Extra Nodes)
- `Batch` (`scripts/world/batch.gd`) collects `MeshBuilder` geometries keyed by material and compiles them into a single `MeshInstance3D` per chunk via `commit(root, "Wilds")`.
- Adding materials to a `Batch` merely adds surfaces to the chunk's existing `ArrayMesh`. It does **not** create extra nodes in the scene tree.
- By caching the 8 color-family materials on the chunk's `Batch` and selecting one family per tree based on the tree's position hash or seed, each tree receives a distinct, harmonious color family while the total number of scene nodes remains exactly 1 `MeshInstance3D` per chunk!

## 4. Files and Functions Touched
- `scripts/world/world_builder.gd`: `_wilds()` and `_tree_parts()`

## 5. Exact Proposed GDScript Code

### Changes to `scripts/world/world_builder.gd`

```gdscript
## Helper that provides tree parts for a specific crown color family (0..7) within a chunk Batch.
## Materials are cached inside the batch's material map, so no additional nodes are created.
func _tree_parts_for_family(bt: Batch, bark: Color, family_idx: int) -> Dictionary:
	var col_a: Color = Trees.leaf_color(family_idx, 0)
	var col_b: Color = Trees.leaf_color(family_idx, 1)
	return {
		"bark": bt.mb(Mats.plain(bark, 0.05)),
		"leaves": bt.mb(Mats.plain(col_a, 0.08)),
		"leaves2": bt.mb(Mats.plain(col_b, 0.08)),
		"ground": bt.mb(Mats.plain(Color(0.13, 0.19, 0.1), 0.05)),
		"stone": bt.mb(Mats.plain(Color(0.33, 0.33, 0.31), 0.15)),
	}
```

In `_wilds()` in `scripts/world/world_builder.gd`:

```gdscript
// Inside the while-loop in _wilds(), replace:
// var parts := _tree_parts(bt, bark, dark, rust)
// with:
var tree_seed: int = int(px * 73.0 + pz * 179.0) ^ (hash(L.id) & 0xffff)
var fam: int = absi(tree_seed) % 11
var family_idx: int = mini(fam, 7) if fam < 8 else fam - 8
# deep forest has slightly more autumn/rust variety; edge forest stays predominantly green:
if not deep and family_idx >= 6 and rnd.f() < 0.65:
	family_idx = rnd.i(6)
var parts := _tree_parts_for_family(bt, bark, family_idx)
```

## 6. What Could Not Be Checked
- Web Compatibility renderer draw call impact with up to 16 surfaces per chunk (8 leaf pairs + bark + ground) vs the previous 4 surfaces per chunk. Since all surfaces belong to the same `ArrayMesh` node and share unshaded plain shaders, Godot's batcher should handle this with zero additional node overhead.
