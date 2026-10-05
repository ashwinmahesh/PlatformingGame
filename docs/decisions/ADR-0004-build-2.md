# ADR-0004: Build 2 changes from Ashwin's playtest

Date: 2026-10-05 · Status: accepted · Source: vault note "Feedback - Build 1"

- **Tuning:** run 12 m/s, accel 0.165 s, air control 0.9, gravity 50/65, jumps 3.4/3.2/3.2 m,
  jump buffer 0.04 s. Bounce heights raised in proportion (Plunge 3.5, Bouncer 6.5, Springcap
  Plunge 15 m). Buffer tests now read the buffer from settings.
- **Controls:** WASD move, arrow keys camera, Space jump, F (or J) attack, Shift Plunge, Q lock-on.
  No mouse (no capture, no mouse look).
- **Look:** screen-space ink outlines (depth + normal edges) on everything, plus inverted-hull
  outlines on characters. Sourced CC0 art from Kenney and KayKit (docs/assets/LICENSES.md).
- **Sword:** reach 1.6 m and radius 1.35 m (spin 2.6 m); the model is 1.45x longer; KayKit
  attack clips retimed to each attack's ticks, plus a ribbon trail from the blade.
- **Plunge:** after the hang, starts at 10 m/s and accelerates at 180 m/s² to 40 m/s, sword held
  point-down, with streaks.
- **Camera:** spring arm 10.5 m (was 7.5). A gold landing ring shows where the current arc meets
  the ground, in addition to the drop shadow.
- **Mother Gloop:** 5 HP; only a Plunge on her open core hurts; one hit closes the core. Thresholds
  at 3 and 1 HP start phases 2 and 3. Hurtboxes and contact follow the drawn ellipsoid.
- **Gloplets:** 20% larger; contact uses the drawn ellipsoid.
- **World 1:** all 9 sections (adds Bonk Grove with monkeys, Waterfall Climb, Ridge Run), about
  1.6x wider to fit the new jumps, standing on a forest floor instead of water. Fernway cliff is
  14 m so the Springcap Plunge stays required (measured: triple jump peaks at 9.4 m).
- **Debug:** F2 draws every hitbox and hurtbox as a wireframe.
