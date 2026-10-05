# ADR-0001: First build is the five-minute slice, in code-built gray-box

Date: 2026-10-05 · Status: accepted (pending Gate C)

The plan is a 66–105 session roadmap with human gates. The first build delivers the P3
five-minute slice (§13.1) with the systems Release 1 needs, rather than a partial P0.

- **In:** movement per §3.3 (all Gate A tests), combat per §4.1, lock-on, Gloplet + Bouncer,
  Springcap, Mother Gloop with all 3 phases (more than the slice's phase 1), checkpoints,
  safe-ground respawn, save/load with backup recovery and the victory commit, the Mossbrook hub
  with 3 NPCs, dialogue, the rooftop course and seed flower beds, Feel Lab (F1), AI debug (F2),
  event log, capture and clip tools, synthesised sounds and music.
- **World 1 sections built:** 1 Stump Ring, 2 Fernway, 3 Sunny Clearing, 4 River Crossing,
  8 Lily Gate, 9 Gloop Lake. **Not yet:** 5 Bonk Grove, 6 Waterfall Climb, 7 Ridge Run, the
  Bonk monkey and coconut reflection (P4).
- **Art:** everything is built from primitives under the toon shader + palette. No assets were
  downloaded, because the plan requires the human to approve each download (§7.6). Blender is
  not used yet. The environment-pack and hero bake-offs (§13.1 item 6) are still open.
- **Palette deviation:** materials sample the palette texture by a `cell` uniform instead of
  per-face palette UVs, because primitives have no authored UVs. Same palette, same shader.
