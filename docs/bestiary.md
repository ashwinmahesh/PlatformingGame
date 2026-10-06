# Bestiary (Build 6 roster)

Six basic monsters, each with a visible tell before it attacks. Every ability counters at least two.

| Monster | Size vs hero | Where | Tell, then attack | Weak to |
|---|---|---|---|---|
| Gloplet / Big Gloplet | 0.6 / 1.2 | W1, W2 (pink), W3 (ember), W4 (pink), W5 (frost) | Big one squashes and glows, then belly-flops onto where you stood with a splash ring; splits into two Gloplets | Thunderclap (hits the whole family), Glide/jump over the ring |
| Batling (Jellyfloat in W4, white Snowbat in W5) | 0.5 | W1, W2, W3, W5 | Wings flash, then a swoop to where you stood; perched ones hang under ledges and drop when you pass beneath | Fireball (pops it at range), Thunderclap |
| Puffcap (Pricklepot in W3) | 0.9 | W1, W2, W4, W5 | Cap swells and glows, then lobs a spore ball (ring marks the landing); up close it ducks under its cap, which is a trampoline. Pricklepot bristles, fires a fan of 5 needles, then spins | Fireball (scorches it out of its guard), Thunderclap, Plunge bounce off the cap, Glide over needles |
| Shieldknight (Armorling) | 1.4 | W3, W5 | Swing: sword raised and glowing. Charge: scrapes a foot and glows, then charges; into a wall it stuns itself | Thunderclap (knocks the shield away for good), Air Dash (through the charge), get behind it |
| Mimic | 0.8 | W2, W3, W4 | Looks like a real chest; lid clamps on the sword while it chases; after a bite or a long chase it pants with its tongue out, the only time it can be hurt | Fireball (reveals it from range and winds it), Thunderclap (winds it), Air Dash (slips the bite) |
| Boulderkin | 2.5 | W3 (sandstone), W4 (coral), W5 (ice) | Heave: lifts a boulder overhead, then throws it at a ring. Pound: both fists high and glowing, then a dust ring | Air Dash (to its back, or through the ring), Glide/jump over the ring, slash the boulder back to topple it, crystal on its back |


## Build 7: six more

| Monster | Size vs hero | Where | Tell, then attack | Weak to |
|---|---|---|---|---|
| Wispghost (Ghost) | 0.9 | W4, W5, W6 | Drifts half-seen through walls; turns solid and flickers purple, then lunges | Fireball (lights it solid and dizzy), Thunderclap / Roar (stun) |
| Wyrmling (Dragon) | 1.0 | W2, W3, W5 | Circles overhead; rears back and its throat glows, then a cone of fire | Frost Burst (freezes it, it drops), Vinelash (yanks it down), Gravity Orb |
| Buzzbee (Armabee) | 0.7 | W1, W2 | Buzzes and shakes, then a straight sting dive; armour turns the sword from the front | Fireball and Thunderclap (through the armour), Vinelash (drags it down) |
| Whirlwisp (Hywirl) | 0.9 | W3, W5 | Spins up with a dust ring, then a vortex that drags you in; dizzy afterwards | Gravity Orb (breaks the vortex), Frost Burst, Spring Boots (bound clear), Air Dash |
| Hopfrog (Frog) | 0.8 | W1, W4 | Throat puffs up, then a 7 m tongue lash; pants afterwards | Air Dash (slips the tongue), Vinelash (outreaches it, stuns), Star Rush |
| Hexwizard (Wizard) | 0.9 | W6 | Raises a glowing staff, then three slow homing orbs; blinks away when hit | Fireball mid-cast (fizzles it, stuns), Mighty Roar (pins it), Star Rush (through the orbs) |

Ability coverage: Fireball counters Batling, Puffcap, Mimic, Wispghost, Buzzbee and Hexwizard. Vinelash counters Wyrmling, Buzzbee and Hopfrog. Frost Burst counters Wyrmling and Whirlwisp. Spring Boots counter Whirlwisp and Boulderkin's ring. Gravity Orb counters Wyrmling and Whirlwisp. Star Rush counters Hopfrog and Hexwizard. Mighty Roar counters Shieldknight and Hexwizard (and stuns everything). Thunderclap counters Gloplets, Batling, Puffcap, Shieldknight and Mimic. Air Dash counters Shieldknight, Mimic and Boulderkin.

Tests: `tests/sim/test_roster.gd`. Captures: `captures/bestiary/` (dev scene `scenes/dev/bestiary.tscn`).
