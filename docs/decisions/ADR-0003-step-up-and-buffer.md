# ADR-0003: Step-up and jump-buffer implementation

Date: 2026-10-05 · Status: accepted

**Step-up (§3.3 rule 12).** Implemented in the controller: when the next tick's move is blocked
by a wall-like contact, test up 0.35 m, forward by the capsule radius, and down; if a floor is
found, raise the body onto that height and glide forward with gravity and snap off (≤ 8 ticks)
until it's over the step. Test 14 passes: 0.1/0.2/0.35 m climb at full speed with no launch,
0.4 m blocks. No ramp-only fallback needed so far.

**Jump buffer.** Stored as an age in ticks, not a float countdown. The buffer ages before a new
press is stored, and pauses during attack active ticks and hit-stop. A press stays valid while
age/60 ≤ 0.12 s, so "0.10 s before contact gives J1 on the tick after contact" and "0.20 s before
does nothing" both hold exactly (tests 6–8).

**Teleports.** `respawn_at` runs one zero-velocity `move_and_slide()` so contact flags match the
new position; otherwise a teleport would read the old floor and refill jumps (test 10, 16).
