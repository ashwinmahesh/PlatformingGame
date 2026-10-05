# ADR-0002: Engine settings

Date: 2026-10-05 · Status: accepted

- Physics: Jolt (`physics/3d/physics_engine="Jolt Physics"`), 60 ticks/s, physics interpolation on.
  Not measured against Godot Physics yet.
- Renderer: Forward+, 4x MSAA, linear tonemap, depth fog from 45 m. Not measured against Mobile yet.
- Input map is registered from code (scripts/core/input_setup.gd) so it's reproducible.
- `untyped_declaration` is an error.
