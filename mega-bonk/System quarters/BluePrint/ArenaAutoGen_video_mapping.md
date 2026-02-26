# ArenaAutoGen vs video method: code entry-point map

This maps the subtitle-described video method to the current ArenaAutoGen implementation, clarifies where it already matches, and lists exact insertion points for remaining work.

## 0) Key clarification: dual-grid vs bind-to-wire-grid

- Video “dual grid” = internal algorithmic representation (main grid + offset/corner interpretation for reduced tile cases).
- `bind_to_wire_grid` in this project = external integration/sync feature (`/root/Grid`, origin, bounds), not the dual-grid algorithm.

So generator quality work should not depend on `bind_to_wire_grid`; keep it off while iterating unless embedding into Core chambers.

---

## 1) Current CA pipeline (what exists now)

### Logic grid creation (CA-based)
- `generate()`
  - `_fill_corners_random()`
  - `_apply_corner_border_empty()`
  - `_smooth_corners_step()` (looped by `smoothing_steps`)
  - `_force_single_corner_region_from_center()` (optional connectivity pass)
  - `_build_tiles_from_corners()`

### Tile typing from neighborhood / mask (dual-grid-style reduction)
- `_mask_at_tile(x, y)`
- `_canonicalize_mask(mask)`
- `_variant_at_tile(x, y)`

### Piece stamping / anti-repetition controls
- `_run_pattern_stamping()`
  - priority-band grouping
  - weighted candidate picking (`_pick_weighted_candidate_index`)
  - cooldown checks (`_pattern_cooldown_allows` / `_record_pattern_cooldown`)
- pattern definitions in `PatternPieces.gd`

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

---

## 2) What already matches the video

1. Neighbor-based model selection (tile type from neighborhood state).
2. Corner-mask canonical reduction (reduced case count, rotation/mirror).
3. Multiple variants per tile type (deterministic per-cell variant choice).
4. Multi-tile feature pieces via stamping patterns.
5. Visual-only relaxed/jittered floor direction.

---

## 3) What still differs from the video’s later stages

1. **Core generation model**
   - Current: CA smoothing + cleanup.
   - Video late-stage: constraint/model synthesis (WFC-like propagation).

2. **Model deformation stage**
   - Current: relaxed floor surface mesh only.
   - Video step: deform placed tile/piece models using handle-style deformation so seams stay connected.

3. **Stålberg irregular quad grid stage**
   - Current: rectangular grid logic.
   - Video step: irregular quad main grid generation pipeline (hex/tri/quad/relax/stitch workflow).

---

## 4) Minimal WFC-lite insertion plan (without breaking existing rendering)

### New hooks to add in `ArenaAutoGen.gd`
- `_build_tile_domains() -> Array`
- `_seed_constraints(domains: Array) -> void`
- `_collapse_low_entropy_cell(domains: Array) -> Vector2i`
- `_propagate_constraints(domains: Array, start_cell: Vector2i) -> bool`
- `_extract_tiles_from_domains(domains: Array) -> void`

### Integration point in `generate()`
Replace only the logic-source block:
- `_fill_corners_random()`
- `_apply_corner_border_empty()`
- smoothing loop
- `_force_single_corner_region_from_center()`
- `_build_tiles_from_corners()`

with:
- `if use_wfc_lite:` constraint solve path
- `else:` existing CA path

Leave downstream stages unchanged:
- `_run_pattern_stamping()`
- `_build_floor_multimeshes()`
- `_build_walls_multimesh()`
- debug visual updates

### Definition of Done
- `use_wfc_lite` feature flag cleanly switches between CA and WFC-lite paths in `generate()`.
- Under fixed seed settings, repeated runs produce deterministic tile outputs in WFC-lite mode.

### Non-goals
- Do not replace downstream rendering/stamping/wall code during this phase.

---

## 5) Deformation step insertion plan (video-aligned next step)

Goal: move from relaxed floor-only to deformed placed pieces while keeping gameplay grid canonical.

### Suggested hooks
- `_build_visual_corner_lattice() -> Array[Vector3]`
- `_deform_tile_mesh_to_quad(mesh: Mesh, quad: Array[Vector3]) -> ArrayMesh`
- `_deform_piece_mesh_to_region(mesh: Mesh, region_corners: Array[Vector3]) -> ArrayMesh`

### Integration
- Build one shared jittered corner lattice per generation pass.
- Use shared corners for adjacent tiles to avoid cracks.
- Keep `_tiles` / `_occupied` / walls on canonical grid for gameplay and perf stability.

### Definition of Done
- Deformed floor renders from a shared corner lattice built once per generation pass.
- Adjacent tile seams show no cracks because shared lattice corners are reused.
- Canonical gameplay collision behavior remains unchanged.

### Non-goals
- Do not deform gameplay collision meshes or pathing logic in this phase.

---

## 6) Scene wiring checklist (`arena_auto_gen.tscn`)

Use this ordered checklist before implementing deformation or dual-grid debug features.

1. Ensure the `Arena` child exists and is the visual parent for generated visuals.
   - Expected node path: `ArenaAutoGen/Arena`
2. Add or keep the wire debug mesh node and make it toggleable.
   - Expected node path: `ArenaAutoGen/ArenaWireGrid`
3. Add a deformed floor output mesh under `Arena`.
   - Expected node path: `ArenaAutoGen/Arena/DeformedFloor`
4. Define visibility switching rules in script so visual modes are mutually exclusive.
   - When deformed visuals are ON: hide floor multimesh containers under `ArenaAutoGen/Arena/*` and show `ArenaAutoGen/Arena/DeformedFloor`.
   - When deformed visuals are OFF: show floor multimesh containers and hide `ArenaAutoGen/Arena/DeformedFloor`.
5. Keep wall and collision generation unchanged and tied to canonical grid logic.
   - Preserve canonical data flow from `_tiles` / `_occupied` into wall and collision construction.

---

## 7) Dual-grid debug overlay phase

Goal: add toggleable visualization for both the main grid and half-cell offset dual grid to validate mask interpretation visually.

### Suggested hooks
- `_build_main_grid_overlay_mesh() -> ImmediateMesh`
- `_build_dual_grid_overlay_mesh() -> ImmediateMesh`
- `_update_grid_overlays() -> void`

### Definition of Done
- Main grid and dual/offset grid overlays can be toggled independently at runtime.
- Overlays align with tile masks and corner interpretation in the same coordinate space.

### Non-goals
- Do not use debug overlays as a source of generation truth.

---

## 8) “Double grid” mapping in this codebase

- Logic grid: `_tiles`, masks/variants, stamping occupancy (`_occupied`)
- Visual grid: wire debug (`_build_wire_grid_mesh`) + relaxed/deformed visual mesh path

`bind_to_wire_grid` is alignment/integration with external grid systems; it is not the generator’s dual-grid concept.

---

## 9) Performance notes for bind mode

Large frame-time jumps under bind mode are usually from effective resolution changes:
- smaller effective `cell_size` (e.g., synced from external `STEP_SIZE`)
- larger resulting cell count
- more instances and debug lines

Keep during generator iteration:
- `bind_to_wire_grid = false`
- `wire_grid_use_step_size_from_grid = false`
- fixed `seed_value`

Enable bind/sync only when embedding into Core chambers room flows.
