# ArenaAutoGen vs video method: code entry-point map

This maps the “video method” steps to the current ArenaAutoGen implementation and identifies where a WFC-lite path should be inserted.

## 1) Current CA pipeline (what exists now)

### Logic grid creation (CA-based)
- `generate()`
  - `_fill_corners_random()`
  - `_apply_corner_border_empty()`
  - `_smooth_corners_step()` (looped by `smoothing_steps`)
  - `_force_single_corner_region_from_center()` (optional connectivity pass)
  - `_build_tiles_from_corners()`

### Tile typing from neighborhood / mask
- `_mask_at_tile(x, y)`
- `_canonicalize_mask(mask)`
- `_variant_at_tile(x, y)`

### Piece stamping / anti-repetition controls
- `_run_pattern_stamping()`
  - priority-band grouping
  - weighted candidate picking (`_pick_weighted_candidate_index`)
  - cooldown checks (`_pattern_cooldown_allows` / `_record_pattern_cooldown`)
- pattern definitions live in `PatternPieces.gd`

### Rendering passes
- Floor:
  - `_build_floor_multimeshes()`
  - `_build_floor_multimeshes_by_variant()`
  - deterministic per-tile variant selection in `_build_floor_variant_mesh(variant_id, x, y)`
- Walls:
  - `_build_walls_multimesh()`
- Optional relaxed visual mesh:
  - `_update_relaxed_floor_visual()`
  - `_build_relaxed_floor_mesh()`

## 2) What differs from the video’s core generator

Current logic generation is CA + cleanup. The video’s core generation is constraint/model-synthesis (WFC-like propagation).

That means the replacement target is **only the logic-generation stage** (tile-type solving), not rendering/stamping/wire debug.

## 3) Minimal WFC-lite insertion plan (without breaking existing rendering)

### New function hooks to add in `ArenaAutoGen.gd`
- `_build_tile_domains() -> Array`  
  Initializes per-cell candidate sets (tile variants).
- `_seed_constraints(domains: Array) -> void`  
  Applies border/fixed constraints before solve.
- `_collapse_low_entropy_cell(domains: Array) -> Vector2i`  
  Chooses a cell and collapses to a single tile type.
- `_propagate_constraints(domains: Array, start_cell: Vector2i) -> bool`  
  Enforces adjacency consistency; returns false on contradiction.
- `_extract_tiles_from_domains(domains: Array) -> void`  
  Converts solved domains into `_tiles` / variant IDs used by existing render path.

### Integration point
Inside `generate()`, replace this block:
- `_fill_corners_random()`
- `_apply_corner_border_empty()`
- smoothing loop
- `_force_single_corner_region_from_center()`
- `_build_tiles_from_corners()`

with:
- `if use_wfc_lite:` solve via domain propagation
- `else:` keep current CA path

Everything after logical tile solution remains unchanged:
- `_run_pattern_stamping()`
- `_build_floor_multimeshes()`
- `_build_walls_multimesh()`
- debug visual updates

## 4) “Double grid” mapping in current codebase

- Logic grid: `_tiles`, masks/variants, stamping occupancy (`_occupied`)
- Visual grid: wire debug (`_build_wire_grid_mesh`) + relaxed visual (`_build_relaxed_floor_mesh`)

`bind_to_wire_grid` is integration/sync with external Grid data and is not required for logic generation.

## 5) Safe development mode recommendation

For generator iteration and reproducibility:
- `bind_to_wire_grid = false`
- `wire_grid_use_step_size_from_grid = false`
- fixed `seed_value`

Enable bind/sync only when embedding into Core chambers room flows.
