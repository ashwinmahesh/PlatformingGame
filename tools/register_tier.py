#!/usr/bin/env python3
"""Registers new seeds, checkpoints, errand flags and villagers for a world (Build 6 upper tiers).
usage: register_tier.py <world_tres> --seeds a,b --spawns c --flags f --npc id:Model.glb:scale:Name:errand_flag:reward:line_before|line_after
"""
import json, re, sys, os
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game")
args = sys.argv[1:]
tres = os.path.join(root, "data/worlds", args[0])
opts = {"--seeds": [], "--spawns": [], "--flags": [], "--npc": []}
k = None
for a in args[1:]:
    if a in opts: k = a; continue
    opts[k].append(a)
s = open(tres).read()
def add(field, ids):
    global s
    m = re.search(field + r' = Array\[StringName\]\(\[(.*?)\]\)', s)
    cur = m.group(1)
    for i in ids:
        if f'&"{i}"' not in cur:
            cur += f', &"{i}"'
    s = s[:m.start(1)] + cur + s[m.end(1):]
for x in opts["--seeds"]: add("seed_ids", x.split(","))
for x in opts["--spawns"]: add("spawn_ids", x.split(","))
open(tres, "w").write(s)
prog = os.path.join(root, "scripts/core/progress.gd")
ps = open(prog).read()
for x in opts["--flags"]:
    for f in x.split(","):
        if f'&"{f}"' not in ps:
            ps = ps.replace("const KNOWN_FLAGS: Array[StringName] = [", f'const KNOWN_FLAGS: Array[StringName] = [&"{f}", ', 1)
open(prog, "w").write(ps)
npc = os.path.join(root, "scripts/world/npc.gd")
ns = open(npc).read()
KITS = {"Mage": '["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]', "Knight": '["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Round_Shield", "1H_Sword", "2H_Sword"]',
        "Barbarian": '["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "2H_Axe"]', "Rogue": '["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]', "Rogue_Hooded": '["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]'}
for x in opts["--npc"]:
    nid, model, scale, name, flag, before, after = x.split("|")
    if f'"{nid}":' not in ns:
        line = f'\t"{nid}": ["res://assets/models/kaykit_adventurers/{model}.glb", {scale}, {KITS[model]}],\n'
        i = ns.index("\n}\n", ns.index("const MODELS"))
        ns = ns[:i + 1] + line + ns[i + 1:]
    convs = []
    if flag:
        convs.append({"when": flag, "lines": [{"speaker": name, "text": after}]})
        convs.append({"when": "", "lines": [{"speaker": name, "text": before}]})
    else:
        convs.append({"when": "", "lines": [{"speaker": name, "text": t} for t in before.split(" // ")]})
    json.dump({"id": nid, "name": nid, "conversations": convs}, open(os.path.join(root, "data/dialogue", nid + ".json"), "w"), indent=2)
open(npc, "w").write(ns)
print("registered", args[0])
