# ADR-0005: Build 3 changes (Feedback - Build 2)

Date: 2026-10-05 · Status: accepted

- **Camera:** default distance 8.5 m (Build 2: 10.5), adjustable 5–14 m with - / = (or the gamepad
  shoulder buttons) and a pause-menu slider; saved in settings.cfg.
- **Swimming replaces "water is a hazard"** (plan §2 said "no swimming"; Ashwin overruled it).
  Water areas carry `kind=water` and a `surface` height. The hero floats with the head above water,
  dives with Shift, rises with Space, hops out from the surface (2.6 m, enough for 1 m banks).
  10 s of air; then ½ heart every 1.5 s. Enemies still sink. Pits (forest floor, kill plane) are
  still the fall rule.
- **River:** round logs replaced by flat-topped rafts, 8 s period and 6 m travel (was 3.8 s, 9 m).
- **Warmer look:** palette greens, browns and stones warmed; mauve shadows; peach haze and horizon;
  warmer sun; KayKit textures get a warm tint.
- **Rounder look:** level blocks are rounded boxes with grassy tops from the shader (no cap
  boxes); pillars are lathed with rounded rims; natural sourced props get smooth normals.
- **Hidden areas in World 1** (4 new seeds, 10 total): Fernway nook behind bushes, hollow tree in
  the Sunny Clearing, a riverbed log ring (dive), and a grotto behind the waterfall reached by
  swimming under the cliff lip.
