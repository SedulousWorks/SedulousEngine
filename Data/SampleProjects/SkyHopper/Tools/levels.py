#!/usr/bin/env python3
"""Sky Hopper's later levels (4 and 5), written through the editor's MCP tools.

    python3 levels.py            both
    python3 levels.py Level4     one

A level is built from pieces: grass islands (the kit's corner, side and centre tiles turned to face
out), single cubes, crates and bricks, rock platforms, bridges, and what lives on them (coins,
enemies, hazards, pickups, the flag). The sun, the player and the camera, with their components
and the player's model, and the scene settings (the shared environment profile, physics, post),
are taken from Level3, so every level looks and plays alike. Rewriting a level keeps its asset
(the same guid); the first write creates it in Scenes/.

Measures: a jump rises about 2.3 m and carries about 6.5 m at full speed (gravity 20, launch
9.5 m/s, run 7 m/s). A tile is 2 m, its top 1 m above its origin; a pickup floats 1.3 m over the
ground; a gem you must jump for floats 3 m over it.
"""
import math, os, re, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skygen import Doc, assets as listed, mcp, yaw, NIL

LEVEL3 = "e8094435-4425-034d-b972-6bca7668b14d"


def assets():
    """Prefabs by model name, scripts by name, clips by model/clip, scenes by name."""
    found = {"prefab": {}, "script": {}, "clip": {}, "scene": {}}
    for a in listed():
        group = a.get("group", "")
        if a["type"] == "PrefabDocument" and group.startswith("Models/"):
            found["prefab"][group.split("/")[-1]] = a["guid"]
        elif a["type"] == "ScriptClassAsset":
            found["script"][a["name"]] = a["guid"]
        elif a["type"] == "AnimationClipAsset":
            found["clip"][group.split("/")[-1] + "/" + a["name"]] = a["guid"]
        elif a["type"] == "SceneDocument":
            found["scene"][a["name"]] = a["guid"]
    return found


A = assets()
P, S, C = A["prefab"], A["script"], A["clip"]


class Level(Doc):
    """A Doc started from Level3's sun, player, camera and settings."""

    def __init__(self, name, start_y=0.0):
        super().__init__(name)
        root = ET.fromstring(mcp("scene_read", {"guid": LEVEL3})["xml"])
        keep = {}
        items = list(root.find("array[@name='entities']"))
        for i in range(0, len(items), 7):
            if items[i + 1].text in ("Sun", "Player", "Camera"):
                keep[items[i].text] = items[i + 1].text
                self.entities.append("".join(ET.tostring(e, encoding="unicode") for e in items[i:i + 7]))
        for comp in root.find("array[@name='components']"):
            if comp.find("string[@name='owner']").text in keep:
                self.components.append(ET.tostring(comp, encoding="unicode"))
        instances = list(root.find("array[@name='prefabInstances']"))
        starts = [i for i, e in enumerate(instances) if e.get("name") == "prefab"] + [len(instances)]
        for a, b in zip(starts, starts[1:]):
            if instances[a + 1].text in keep:  # the player's model
                self.instances.append("".join(ET.tostring(e, encoding="unicode") for e in instances[a:b]))
        for block in root.find("array[@name='systemSettings']"):
            self.settings.append(ET.tostring(block, encoding="unicode"))
        self.counts = {}
        if start_y:
            self.entities = [re.sub(r'(<string name="name">Player</string>.*?<f32 name="y">)[^<]*', r'\g<1>%s' % (start_y + 2.0),
                                    e, flags=re.S) if '>Player<' in e else e for e in self.entities]
            self.entities = [re.sub(r'(<string name="name">Camera</string>.*?<f32 name="y">)[^<]*', r'\g<1>%s' % (start_y + 7.0),
                                    e, flags=re.S) if '>Camera<' in e else e for e in self.entities]

    def named(self, base):
        """Level1's naming: Coin, Coin2, Coin3, ..."""
        n = self.counts.get(base, 0) + 1
        self.counts[base] = n
        return base if n == 1 else "%s%d" % (base, n)

    # ---- ground ----
    def island(self, x0, x1, z0, z1, y, dress=()):
        """Grass tiles over x0..x1 (left to right) and z0..z1 (near to far, z0 > z1), 2 m apart,
        their tops at y + 1. A one-tile island is a single cube."""
        xs = list(range(int(x0), int(x1) + 1, 2))
        zs = list(range(int(z0), int(z1) - 1, -2))
        if len(xs) == 1 and len(zs) == 1:
            self.instance(P["Cube_Grass_Single"], (xs[0], y, zs[0]))
        for x in xs:
            for z in zs:
                if len(xs) == 1 and len(zs) == 1:
                    break
                left, right, near, far = x == xs[0], x == xs[-1], z == zs[0], z == zs[-1]
                edges = (left or right) + (near or far)
                if edges == 2:
                    turn = 0 if (left and near) else 90 if (right and near) else 180 if (right and far) else -90
                    self.instance(P["Cube_Grass_Corner"], (x, y, z), yaw(turn))
                elif edges == 1:
                    turn = 0 if near else 180 if far else -90 if left else 90
                    self.instance(P["Cube_Grass_Side"], (x, y, z), yaw(turn))
                else:
                    self.instance(P["Cube_Grass_Center"], (x, y, z))
        for kind, x, z, scale in dress:
            self.instance(P[kind], (x, y + 1.0, z), yaw((x * 37 + z * 11) % 360), (scale, scale, scale))

    def single(self, x, y, z, kind="Cube_Grass_Single"):
        self.instance(P[kind], (x, y, z))

    def rock(self, x, y, z, scale=0.7, tall=False):
        """A rock platform standing on y (its top at y + 2.91 x scale, a tall one 4.26 x scale)."""
        self.instance(P["RockPlatform_Tall" if tall else "RockPlatforms_Medium"], (x, y, z),
                      yaw((x * 53 + z * 7) % 360), (scale, scale, scale))

    def bridge(self, x, z0, z1, top):
        """A bridge along -Z from z0 to z1, its deck at `top`, in 2.9 m spans."""
        spans = max(1, int(round((z0 - z1) / 2.9)))
        step = (z0 - z1) / spans
        for i in range(spans):
            self.instance(P["Bridge_Modular"], (x, top - 0.1, z0 - step * (i + 0.5)), yaw(90))

    # ---- what lives on it ----
    def coin(self, x, top, z, lift=1.3):
        e = self.entity(self.named("Coin"), (x, top + lift, z))
        self.script(e, (S["Coin"], {}))
        self.instance(P["Coin"], parent=e, scale=(0.45, 0.45, 0.45))

    def coins(self, points, top):
        for x, z in points:
            self.coin(x, top, z)

    def enemy(self, kind, x, top, z, patrol, speed=2.0, **extra):
        e = self.entity(self.named(kind), (x, top, z))
        # walkClip is the clip's id as text (the Enemy script takes a string).
        props = {"patrolDistance": patrol, "speed": speed, "walkClip": C[kind + "/Walk"]}
        props.update(extra)
        self.script(e, (S["Enemy"], props))
        self.instance(P[kind], parent=e, scale=(0.7, 0.7, 0.7))

    def bee(self, x, top, z, patrol, along_z=False, speed=2.2, height=0.45):
        """A bee hovering low over the ground at `top` (low enough to bump into: it hurts at the
        player's height and is stomped from above)."""
        e = self.entity(self.named("Bee"), (x, top + 0.45, z))
        props = {"patrolDistance": patrol, "speed": speed, "walkClip": C["Bee/Flying"],
                 "hoverHeight": height, "hoverSpeed": 2.5}
        if along_z:
            props["patrolAlongZ"] = True
        self.script(e, (S["Enemy"], props))
        self.instance(P["Bee"], parent=e, scale=(0.6, 0.6, 0.6))

    def spikes(self, x, top, z):
        e = self.entity(self.named("Spikes"), (x, top, z))
        self.script(e, (S["Hazard"], {"radius": 1.1}))
        self.instance(P["Spikes"], parent=e, scale=(0.45, 0.45, 0.45))

    def saw(self, x, top, z, swing, rate=0.35, phase=0.0):
        """A saw standing half sunk in the ground, swinging `swing` either side across the path and
        spinning."""
        e = self.entity(self.named("Saw"), (x, top + 0.55, z))
        self.script(e, (S["Mover"], {"distance": swing, "rate": rate, "phase": phase, "spinSpeed": 7.0}),
                    (S["Hazard"], {"radius": 1.15, "touchHeight": 1.5}))
        self.instance(P["Hazard_Saw"], parent=e, scale=(0.7, 0.7, 0.7))

    def ball(self, x, top, z, swing, rate=0.5, phase=0.0, lift=1.0):
        """A spiky ball swinging across the path at the player's height."""
        e = self.entity(self.named("SpikyBall"), (x, top + lift, z))
        self.script(e, (S["Mover"], {"distance": swing, "rate": rate, "phase": phase, "spinSpeed": 3.0}),
                    (S["Hazard"], {"radius": 1.0, "touchHeight": 1.2}))
        self.instance(P["SpikyBall"], parent=e, scale=(0.8, 0.8, 0.8))

    def heart(self, x, top, z):
        e = self.entity(self.named("Heart"), (x, top + 1.3, z))
        self.script(e, (S["Pickup"], {"chimePitch": 1.2}))
        self.instance(P["Heart"], parent=e, scale=(0.5, 0.5, 0.5))

    def gem(self, x, top, z, lift=3.0):
        e = self.entity(self.named("Gem"), (x, top + lift, z))
        self.script(e, (S["Pickup"], {"takenEvent": "GemCollected", "chimePitch": 1.5}))
        self.instance(P["Gem_Blue"], parent=e, scale=(0.5, 0.5, 0.5))

    def goal(self, x, top, z):
        e = self.entity("Goal", (x, top, z))
        self.script(e, (S["Goal"], {}))
        self.instance(P["Goal_Flag"], parent=e)

    def cloud(self, x, y, z, kind="Cloud_1", scale=1.0):
        self.instance(P[kind], (x, y, z), yaw((x * 13) % 360), (scale, scale, scale))


def level4():
    """Bee Meadow: bridges over the gaps, bees over the bridges, a saw in the orchard, and a climb
    of rock platforms to the flag."""
    L = Level("Level4")
    L.island(-2, 2, 2, -2, 0, dress=[("Tree_Fruit", -2.6, -2.4, 0.35), ("Bush_Fruit", 2.4, -2.4, 0.5)])
    L.coins([(0, -2)], 1.0)
    # The first bridge, and a bee drifting across it.
    L.bridge(0, -3.2, -11.8, 1.0)
    L.coins([(0, -5), (0, -8.5)], 1.0)
    L.bee(0, 1.0, -7.5, 2.2)
    # The orchard: a wide island with a crab under the trees and a saw in its middle.
    L.island(-4, 4, -13, -21, 0, dress=[("Tree_Fruit", -4.4, -13.6, 0.3), ("Bush_Fruit", 4.3, -20.6, 0.5),
                                        ("Grass_1", 1.5, -14, 0.6), ("Grass_1", -2.5, -20, 0.6)])
    L.saw(0, 1.0, -17, 3.0, rate=0.3)
    L.coins([(-3, -15), (3, -15), (-3, -19), (3, -19)], 1.0)
    L.enemy("Crab", 0, 1.0, -20.0, 3.0)
    L.heart(4, 1.0, -13)
    L.gem(-4, 1.0, -21)
    # Steps up: two single cubes, then a second bridge with two bees crossing it out of step.
    L.single(0, 1, -25)
    L.single(3, 2, -29)
    L.coins([(0, -25), (3, -29)], 2.0)
    L.coins([(3, -29)], 3.0)
    L.island(2, 4, -33, -35, 2)
    L.bridge(3, -36.2, -44.8, 3.0)
    L.bee(3, 3.0, -38.5, 2.0, speed=2.6)
    L.bee(3, 3.0, -42.5, 2.0, speed=2.0)
    L.coins([(3, -40.5)], 3.0)
    # The climb: rock platforms stepping up to the flag's island.
    L.island(2, 4, -46, -48, 2)
    L.rock(-1.0, 2.0, -51, 0.7)        # top 4.04
    L.rock(-4.0, 3.0, -54.5, 0.7)      # top 5.04
    L.rock(-1.5, 4.0, -58.5, 0.7)      # top 6.04
    L.coin(-1.0, 4.04, -51)
    L.coin(-4.0, 5.04, -54.5)
    L.coin(-1.5, 6.04, -58.5)
    L.island(-2, 2, -63, -67, 6, dress=[("Tree_Fruit", -2.6, -66.4, 0.35), ("Bush_Fruit", 2.4, -66.5, 0.5)])
    L.enemy("Skull", 0, 7.0, -65.0, 1.5, speed=1.5)
    L.coins([(-2, -64), (2, -64)], 7.0)
    L.goal(0, 7.0, -66.5)
    L.cloud(-12, 14, -20); L.cloud(11, 17, -40, "Cloud_2", 1.2); L.cloud(-8, 20, -60)
    return L


def level5():
    """Cloud Fortress: crate and brick stepping stones, spiky balls swinging across the paths,
    saws, bees on the long brick walk, and a last climb."""
    L = Level("Level5")
    L.island(-2, 2, 2, -2, 0, dress=[("Rock_1", -2.6, -2.4, 0.5), ("Bush", 2.4, -2.4, 0.5)])
    # Crates, a step up each.
    for i, (x, z) in enumerate([(0, -6), (3, -10), (0, -14), (-3, -18)]):
        L.single(x, i + 1, z, "Cube_Crate")
        L.coin(x, i + 2, z)
    # The brick walk: two tiles wide, a spiky ball swinging over each third of it.
    for z in range(-22, -41, -2):
        L.single(-3, 4, z, "Cube_Bricks")
        L.single(-1, 4, z, "Cube_Bricks")
    L.ball(-2, 5.0, -26, 2.2, rate=0.45)
    L.ball(-2, 5.0, -31, 2.2, rate=0.45, phase=0.5)
    L.ball(-2, 5.0, -36, 2.2, rate=0.55)
    L.coins([(-2, -28.5), (-2, -33.5), (-2, -38.5)], 5.0)
    L.gem(-3, 5.0, -40)
    # The keep's yard: a grass island with a saw, a crab and a heart.
    L.island(-4, 4, -44, -52, 4, dress=[("Rock_1", -4.4, -44.4, 0.5), ("Grass_1", 3.5, -51.5, 0.6)])
    L.saw(0, 5.0, -48, 3.0, rate=0.4)
    L.enemy("Crab", 0, 5.0, -51.0, 3.0, speed=2.5)
    L.coins([(-3, -46), (3, -46), (-3, -50), (3, -50)], 5.0)
    L.heart(4, 5.0, -52)
    # The long walk to the tower: bricks with bees flying along it.
    for z in range(-56, -71, -2):
        L.single(0, 4, z, "Cube_Bricks")
        L.single(2, 4, z, "Cube_Bricks")
    L.bee(1, 5.0, -61, 3.0, along_z=True, speed=2.4)
    L.bee(1, 5.0, -67, 2.5, along_z=True, speed=1.8)
    L.coins([(1, -58), (1, -64), (1, -70)], 5.0)
    # The last climb: crates up to the flag's island.
    L.single(4, 5, -74, "Cube_Crate")
    L.single(1, 6, -78, "Cube_Crate")
    L.single(-2, 7, -82, "Cube_Crate")
    L.coins([(4, -74), (1, -78), (-2, -82)], 7.0)
    L.island(-2, 2, -86, -90, 7, dress=[("Tree", -2.6, -89.4, 0.4), ("Bush", 2.4, -89.5, 0.5)])
    L.enemy("Skull", 0, 8.0, -88.5, 1.5, speed=2.0)
    L.goal(0, 8.0, -89.5)
    L.cloud(12, 15, -25, "Cloud_2", 1.2); L.cloud(-11, 18, -50); L.cloud(9, 21, -80, "Cloud_2")
    return L


LEVELS = {"Level4": level4, "Level5": level5}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(LEVELS)
    for name in wanted:
        doc = LEVELS[name]()
        guid = A["scene"].get(name)
        written = doc.write(guid, group=None if guid else "Scenes")
        print(name, written)
