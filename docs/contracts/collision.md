# Collision layers (single source of truth; code uses `Layers.*`)

| # | Layer | Used by | Detects / collides with |
|---|---|---|---|
| 1 | World | Static level geometry, moving platforms | — |
| 2 | Player body | Hero | 1 |
| 3 | Enemy body | Gloplets | 1, 3 (not the hero: contact damage is analytic) |
| 4 | Player hurtbox | Hero `hurtbox` | queried by enemies |
| 5 | Enemy hurtbox | Enemy hurtboxes, boss body and core, training dummies | sword / Plunge queries |
| 6 | Player attack | (reserved; sword and Plunge are shape queries) | 5, 12, 13 |
| 7 | Enemy attack | (reserved; lunges, slams, rings use `damage_to_player`) | 4 |
| 8 | Interact | Portals, checkpoints, course triggers | Player body |
| 9 | Hazard | Water volumes | Player and enemy bodies |
| 10 | Camera blocker | Large geometry only (never foliage canopies) | SpringArm3D |
| 11 | Pickup | Hearts, Glimmer Seeds | Player body |
| 12 | Bounce | Springcaps, flattened Bouncers, the boss core | Plunge and feet queries |
| 13 | Reflectable | (reserved for coconuts, P4) | Sword only |
