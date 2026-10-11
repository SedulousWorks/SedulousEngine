#!/usr/bin/env python3
"""level.py <Level> ...: writes a level's scene from its table (levels.py), through the editor's MCP.

A level is data: the ground by rectangles, wall runs along the 2 m grid with their openings, lamps,
the guards' rounds, the loot, the target, the exit, checkpoints and the thief's start. This turns a
table into the scene: every piece from the kits (blender/manor.py, blender/grounds.py, loot.py),
each with its own unscaled collider placed from the same sizes and made of a surface (surfaces.py,
for footsteps); a cutaway on every wall piece; the thief with his camera rig and HUD; each guard
with his round, lantern, capsule and meter; the navigation zone over it all, baked after writing.

Tables are in grid cells for the ground and the walls (a cell is 2 m: cell (i, j) spans x 2i..2i+2,
z 2j..2j+2) and in metres for everything placed in the world; the level's origin is its north-west
corner, north being -Z. The camera starts south of the thief looking north.

Run with the editor open on the project and its MCP server on, after the models are imported,
graph.py has written the graphs, importscripts.py and prefabs.py have run:
    python3 level.py Gardens Room
"""
import math, os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import Doc, mcp, yaw, pitch, component_added, component_removed, assets
from look import look
from materials import all_materials
from surfaces import surfaces
import levels

GRID = 2.0
GUARD_GROUP = 2  # the guards' collision group (Guard.as looks past it)
DOOR_W, DOOR_H = 1.2, 2.2  # a doorway's opening (manor.py)
LEAF_W, LEAF_H = 1.04, 2.12  # the door's leaf inside the frame (manor.py's Door)
GATE_W, GATE_H = 1.2, 1.8  # an iron gate's leaf (grounds.py's Gate)

# Wall runs by kind: the piece per 2 m edge and its size (height, thickness), and what stands where
# runs meet or end (its size, square).
WALLS = {
    "Wall": dict(piece=("Manor", "Wall"), h=3.0, t=0.2, corner=("Manor", "Post"), c=0.2),
    "Hedge": dict(piece=("Grounds", "Hedge"), h=1.6, t=0.8, corner=("Grounds", "HedgeCorner"), c=0.8),
    "GardenWall": dict(piece=("Grounds", "GardenWall"), h=2.4, t=0.4, corner=("Grounds", "Pier"), c=0.6),
    "CellarWall": dict(piece=("Manor", "CellarWall"), h=3.0, t=0.4, corner=("Manor", "CellarPillar"), c=0.5),
}
# Ground tiles by kind: the piece and what it is made of.
GROUND = {"Floor": (("Manor", "Floor"), "Wood"), "Grass": (("Grounds", "Grass"), "Grass"),
          "Gravel": (("Grounds", "Gravel"), "Gravel"), "Flags": (("Grounds", "Flags"), "Stone"),
          "Cobbles": (("Grounds", "Cobbles"), "Stone")}
# Lamps on tables by kind: the piece, where its light hangs over the tabletop and how bright, and
# its glowing material slots (Lamp.as swaps them out while it is out). The oil lamp casts shadows
# (six shadow tiles, a point light); a candelabra does not, so a room can have several.
TABLE_LAMPS = {
    "OilLamp": dict(piece=("Manor", "OilLamp"), lightY=0.75, intensity=6.0, range=7.0, shadows=True,
                    flameSlot=1, chimneySlot=2),
    "Candelabra": dict(piece=("Manor", "Candelabra"), lightY=0.7, intensity=3.0, range=5.5, shadows=False,
                       flameSlot=2, chimneySlot=-1),
}
# Props by kind: the piece and its collider's size (x, height, z) before its yaw.
PROPS = {"HayBale": (("Grounds", "HayBale"), (1.2, 0.6, 0.8)), "Trough": (("Grounds", "Trough"), (1.8, 0.6, 0.6)),
         "Barrel": (("Manor", "Barrel"), (0.6, 0.9, 0.6)), "WineRack": (("Manor", "WineRack"), (2.0, 2.0, 0.5)),
         "Table": (("Manor", "Table"), (1.6, 0.8, 0.9))}
# A torch on its stand: its light where the flame burns, flickering (Flicker.as), and the flame's
# slot for Lamp.as (manor.py's order: Hoop, TorchWood, Fire). Its shadow is cached (Static: the
# stand never moves; the renderer redraws it where a guard or the thief walks through) and comes
# from the static layer's own tiles, which go to the lights nearest the camera; a torch that gets
# none lights through walls, so each still stands well inside its room.
TORCH = dict(lightY=1.58, intensity=5.0, range=6.0, flameSlot=2)

ASSETS = assets()


def asset(asset_type, name):
    found = [a["guid"] for a in ASSETS if a["type"] == asset_type and a["name"] == name]
    if not found:
        raise SystemExit("no %s %s (run importscripts.py / prefabs.py first)" % (asset_type, name))
    return found[0]


def model_prefab(group):
    found = [a["guid"] for a in ASSETS if a["type"] == "PrefabDocument" and a.get("group") == group]
    if not found:
        raise SystemExit("no model in %s (run the Blender script and importmodels.py)" % group)
    return found[0]


_pieces = {}


def piece(kit, name):
    """A kit piece's mesh and its material slots, read from its imported prefab."""
    if (kit, name) not in _pieces:
        root = ET.fromstring(mcp("prefab_read", {"guid": model_prefab("Models/%s/%s" % (kit, name))})["xml"])
        _pieces[(kit, name)] = (root.find(".//string[@name='mesh']").text,
                                [e.text for e in root.find(".//array[@name='materials']")])
    return _pieces[(kit, name)]


def model_ops(prefab, graph_name):
    """A model's import plays one clip; its script drives a graph instead (Snowline's rider does the
    same): the prefab's root loses the clip animator, and the skinned mesh gains the graph."""
    root = ET.fromstring(mcp("prefab_read", {"guid": prefab})["xml"])
    parts = {}
    for comp in root.find("array[@name='components']"):
        kind = comp.find("string[@name='type']").text
        owner = comp.find("string[@name='owner']").text
        data = comp.find("object[@name='data']")
        if kind == "skeletal_animation":
            parts["animator"] = owner
            parts["skeleton"] = data.find("string[@name='skeleton']").text
        elif kind == "mesh":
            parts["meshOwner"] = owner
    return [component_removed(parts["animator"], "skeletal_animation"),
            component_added(parts["meshOwner"], "animation_graph", skeleton=parts["skeleton"],
                            graph=asset("AnimationGraphAsset", graph_name))]


def nav_zone(name):
    """The level's Navigation Zone asset (Navigation/<Level>Nav), made the first time."""
    found = [a["guid"] for a in ASSETS if a["type"] == "NavigationZoneAsset" and a["name"] == name + "Nav"]
    return found[0] if found else mcp("asset_create", {"creator": "Navigation Zone", "name": name + "Nav",
                                                       "group": "Navigation"})["guid"]


def quat_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


class Builder:
    """One level's scene being written: its document, materials, surfaces and what later passes need
    (the wall pieces to fade, the lamps, the doors, the thief and the camera)."""

    def __init__(self, table):
        self.t = table
        self.d = Doc(table["name"])
        self.mats = all_materials()
        self.surf = surfaces()
        self.fading = []  # (entity, normal x, z, half length)
        self.lamps = []   # (lamp entity, its light, lit flame slot guid or None, lit glass slot, slots)
        self.doors = []   # (hinge entity, leaf length, lock height)
        self.corners = set()
        look(self.d, table.get("environment", "Night"))

    def place(self, name, kit, kind, pos, rot=(0, 0, 0, 1), parent=None):
        """A kit piece, its materials as imported."""
        m, slots = piece(kit, kind)
        e = self.d.stable_id("entity")
        self.d.entity(name, pos, rot, parent=parent, eid=e)
        self.d.add(e, "mesh", mesh=m, materials=["<string>%s</string>" % g for g in slots])
        return e

    def solid(self, name, pos, size, surface="Stone", rot=(0, 0, 0, 1), parent=None, motion=0):
        """A box collider of its own, unscaled, so the shape is the size it says, made of `surface`."""
        e = self.d.stable_id("entity")
        self.d.entity(name + "Collider", pos, rot, parent=parent, eid=e)
        # Layers: 0 static, 2 kinematic (a swinging door or gate).
        self.d.add(e, "physics.RigidBody", motion=motion, layer=0 if motion == 0 else 2, shape=0,
                   halfExtents={"x": size[0] / 2, "y": size[1] / 2, "z": size[2] / 2}, material=self.surf[surface])
        return e

    def trigger(self, name, rect, script, props):
        """A trigger volume over `rect` (metres: x0, z0, x1, z1) carrying a behaviour."""
        x0, z0, x1, z1 = rect
        e = self.d.stable_id("entity")
        self.d.entity(name, ((x0 + x1) / 2, 1.0, (z0 + z1) / 2), eid=e)
        self.d.add(e, "physics.RigidBody", motion=0, layer=3, shape=0, isTrigger=True,
                   halfExtents={"x": (x1 - x0) / 2, "y": 1.0, "z": (z1 - z0) / 2})
        self.d.script(e, (asset("ScriptClassAsset", script), props))
        return e

    # ---- the ground: a tile per cell, the later rectangle winning, each with its collider ----
    def ground(self):
        cells = {}
        for kind, (i0, j0, i1, j1) in self.t["ground"]:
            for i in range(i0, i1):
                for j in range(j0, j1):
                    cells[(i, j)] = kind
        for (i, j), kind in sorted(cells.items()):
            (kit, name), surface = GROUND[kind]
            at = (GRID * (i + 0.5), 0.0, GRID * (j + 0.5))
            self.place("%s%d_%d" % (kind, i, j), kit, name, at)
            self.solid("%s%d_%d" % (kind, i, j), (at[0], -0.25, at[2]), (GRID, 0.5, GRID), surface)

    # ---- walls: runs along grid lines, an opening where the table says, corners where runs meet ----
    def walls(self):
        openings = {tuple(o["at"]): o for o in self.t.get("openings", [])}
        for n, (kind, (i0, j0), (i1, j1)) in enumerate(self.t.get("walls", [])):
            w = WALLS[kind]
            along_x = j0 == j1
            steps = abs(i1 - i0) if along_x else abs(j1 - j0)
            sign = 1 if (i1 > i0 if along_x else j1 > j0) else -1
            for s in range(steps):
                # The segment's middle, in cells, and in metres.
                ci = i0 + sign * (s + 0.5) if along_x else i0
                cj = j0 if along_x else j0 + sign * (s + 0.5)
                at = (GRID * ci, 0.0, GRID * cj)
                rot = (0, 0, 0, 1) if along_x else yaw(90.0)
                normal = (0, 1) if along_x else (1, 0)
                opening = openings.get((ci, cj))
                name = "%s%d_%d" % (kind, n, s)
                if opening is None:
                    self.fading.append((self.place(name, *w["piece"], at, rot), normal, GRID / 2))
                    size = (GRID, w["h"], w["t"]) if along_x else (w["t"], w["h"], GRID)
                    self.solid(name, (at[0], w["h"] / 2, at[2]), size)
                elif opening["kind"] == "Doorway":
                    self.doorway(name, at, rot, along_x, normal, opening)
                elif opening["kind"] == "Gate":
                    self.gate(name, at, rot, along_x, normal, opening)
                # "Gap": nothing there.
            for p in ((i0, j0), (i1, j1)):
                self.corner(kind, p)
        for kind, p in self.t.get("corners", []):  # where runs meet mid-run (a T)
            self.corner(kind, tuple(p))

    def corner(self, kind, p):
        if (kind, p) in self.corners:
            return
        self.corners.add((kind, p))
        w = WALLS[kind]
        at = (GRID * p[0], 0.0, GRID * p[1])
        name = "%sCorner%d_%d" % (kind, p[0], p[1])
        self.fading.append((self.place(name, *w["corner"], at), (0, 1), w["c"] / 2))
        self.solid(name, (at[0], w["h"] / 2, at[2]), (w["c"], w["h"], w["c"]))

    def doorway(self, name, at, rot, along_x, normal, opening):
        """A manor doorway with its door, locked or not (Door.as)."""
        self.fading.append((self.place(name, "Manor", "Doorway", at, rot), normal, GRID / 2))
        side = (GRID - DOOR_W) / 2
        for s in (-1, 1):
            off = s * (DOOR_W / 2 + side / 2)
            pos = (at[0] + (off if along_x else 0), 1.5, at[2] + (0 if along_x else off))
            self.solid(name + ("L" if s < 0 else "R"), pos, (side, 3.0, 0.2) if along_x else (0.2, 3.0, side))
        self.solid(name + "Lintel", (at[0], (3.0 + DOOR_H) / 2, at[2]),
                   (DOOR_W, 3.0 - DOOR_H, 0.2) if along_x else (0.2, 3.0 - DOOR_H, DOOR_W))
        self.leaf(name + "Door", at, along_x, ("Manor", "Door"), LEAF_W, LEAF_H, 0.94, 1.0, opening)

    def gate(self, name, at, rot, along_x, normal, opening):
        """An iron gate between the run's piers (the corners either end of the segment)."""
        self.leaf(name + "Gate", at, along_x, ("Grounds", "Gate"), GATE_W, GATE_H, GATE_W - 0.12, 1.0, opening)

    def leaf(self, name, at, along_x, model, width, height, lock_along, lock_height, opening):
        """A door or gate leaf on its hinge (this entity, at the opening's west or north edge), the
        leaf and its kinematic collider under it so they swing with it (Door.as)."""
        hinge_at = (at[0] - width / 2, 0.0, at[2]) if along_x else (at[0], 0.0, at[2] + width / 2)
        shut = 0.0 if along_x else 90.0  # the leaf runs along +X from the hinge; turned for a z run
        hinge = self.d.stable_id("entity")
        self.d.entity(name, hinge_at, yaw(shut), eid=hinge)
        self.fading.append((self.place(name + "Leaf", *model, (0, 0, 0), parent=hinge),
                            (0, 1) if along_x else (1, 0), width / 2))
        self.solid(name, (width / 2, height / 2, 0), (width, height, 0.05), parent=hinge, motion=1)
        self.doors.append((hinge, shut, lock_along, lock_height, opening.get("locked", True),
                           opening.get("pickSeconds", 3.0)))

    # ---- props: cover to hide behind, each with its collider ----
    def props(self):
        for n, prop in enumerate(self.t.get("props", [])):
            (kit, name), size = PROPS[prop["kind"]]
            x, z = prop["at"]
            rot = yaw(prop.get("yaw", 0.0))
            self.place("%s%d" % (prop["kind"], n), kit, name, (x, 0.0, z), rot)
            self.solid("%s%d" % (prop["kind"], n), (x, size[1] / 2, z), size, "Wood", rot)

    # ---- rooms: each a reflection probe over its floor (polished boards show the room in them) and
    #      a reverb zone round it (the wettest zone the listener is in wins, so each room echoes as
    #      it is sized) ----
    def rooms(self):
        for room in self.t.get("rooms", []):
            i0, j0, i1, j1 = room["rect"]
            cx, cz = GRID * (i0 + i1) / 2, GRID * (j0 + j1) / 2
            hx, hz = GRID * (i1 - i0) / 2, GRID * (j1 - j0) / 2
            e = self.d.stable_id("entity")
            self.d.entity(room["name"], (cx, 1.5, cz), eid=e)
            self.d.add(e, "reflection_probe", halfExtents={"x": hx, "y": 1.5, "z": hz}, blendDistance=0.5,
                       resolution=128)
            self.d.add(e, "audio.ReverbZone", radius=max(hx, hz), edgeFade=0.2,
                       roomSize=room.get("roomSize", min(0.9, 0.3 + (hx * hz) / 60.0)),
                       damping=room.get("damping", 0.4), wetLevel=room.get("wet", 0.35))

    # ---- the way on: a hatch to stand on (the exit's trigger is over it) ----
    def hatch(self):
        if "hatch" in self.t:
            x, z = self.t["hatch"]
            self.place("Hatch", "Manor", "Hatch", (x, 0.0, z))
        if "stairs" in self.t:
            # Up against a north wall, rising north from their foot at (x, z); solid (the way on is
            # the exit's trigger at the foot, not the climb).
            x, z = self.t["stairs"]
            self.place("Stairs", "Manor", "Stairs", (x, 0.0, z))
            self.solid("Stairs", (x, 1.5, z - 0.9), (2.0, 3.0, 2.0))

    # ---- weather: rain falling round the thief (and its sound), on a level that has it ----
    def weather(self):
        if not self.t.get("rain"):
            return
        e = self.d.stable_id("entity")
        # 5 m over the thief: under the camera (about 7 m up), so no streak passes close to it.
        self.d.entity("Rain", (0, 5.0, 0), parent=self.thief, eid=e)
        self.d.add(e, "particle_effect", effect=asset("ParticleEffectAsset", "Rain"))
        e = self.d.stable_id("entity")
        self.d.entity("RainSound", parent=self.thief, eid=e)
        self.d.add(e, "audio.Source", clip=asset("AudioClipAsset", "Rain"), loop=True, spatial=False, autoPlay=True,
                   volume=0.45)

    # ---- lights: the moon, lantern posts, oil lamps on tables ----
    def lights(self):
        moon = self.t.get("moon", dict(intensity=0.25, yaw=-60.0, pitch=-50.0))
        if moon["intensity"] > 0.0:  # none below ground
            e = self.d.stable_id("entity")
            self.d.entity("Moon", rot=quat_mul(yaw(moon["yaw"]), pitch(moon["pitch"])), eid=e)
            self.d.add(e, "light", type=0, color={"r": 0.55, "g": 0.65, "b": 1.0, "a": 1.0},
                       intensity=moon["intensity"], castsShadows=True)
        for n, lamp in enumerate(self.t.get("lamps", [])):
            kind, (x, z) = lamp["kind"], lamp["at"]
            if kind == "LanternPost":
                # A post's lantern shines down on its pool as a wide spot (one shadow tile, where a
                # point light would take six; the budget is sixteen a frame).
                post = self.place("Post%d" % n, "Grounds", "LanternPost", (x, 0.0, z))
                self.solid("Post%d" % n, (x, 1.25, z), (0.2, 2.5, 0.2))
                light = self.d.stable_id("entity")
                self.d.entity("PostLight%d" % n, (0, 2.3, 0), pitch(-90.0), parent=post, eid=light)
                self.d.add(light, "light", type=2, color={"r": 1.0, "g": 0.74, "b": 0.45, "a": 1.0},
                           intensity=lamp.get("intensity", 10.0), range=8.0, outerAngle=1.15, innerAngle=0.8,
                           castsShadows=True)
                slots = piece("Grounds", "LanternPost")[1]  # Iron, Glass (grounds.py's order)
                self.lamps.append((post, light, dict(flameSlot=1, chimneySlot=-1, flameLit=slots[1])))
            elif kind == "Torch":
                stand = self.place("Torch%d" % n, "Manor", "TorchStand", (x, 0.0, z))
                self.solid("Torch%d" % n, (x, 0.75, z), (0.3, 1.5, 0.3))
                light = self.d.stable_id("entity")
                self.d.entity("TorchLight%d" % n, (0, TORCH["lightY"], 0), parent=stand, eid=light)
                self.d.add(light, "light", type=1, color={"r": 1.0, "g": 0.62, "b": 0.32, "a": 1.0},
                           intensity=lamp.get("intensity", TORCH["intensity"]), range=TORCH["range"],
                           castsShadows=True, shadowUpdate=1)
                self.d.script(light, (asset("ScriptClassAsset", "Flicker"), {}))
                slots = piece("Manor", "TorchStand")[1]
                self.lamps.append((stand, light, dict(flameSlot=TORCH["flameSlot"], chimneySlot=-1,
                                                      flameLit=slots[TORCH["flameSlot"]])))
            elif kind in TABLE_LAMPS:
                # A table with a lamp on it; its light hangs well over the tabletop (any nearer and
                # the top is tens of times brighter than the walls and clips white).
                spec = TABLE_LAMPS[kind]
                self.place("Table%d" % n, "Manor", "Table", (x, 0.0, z))
                self.solid("Table%d" % n, (x, 0.4, z), (1.6, 0.8, 0.9), "Wood")
                lamp_entity = self.place("%s%d" % (kind, n), *spec["piece"], (x, 0.8, z))
                light = self.d.stable_id("entity")
                self.d.entity("LampLight%d" % n, (0, spec["lightY"], 0), parent=lamp_entity, eid=light)
                self.d.add(light, "light", type=1, color={"r": 1.0, "g": 0.72, "b": 0.42, "a": 1.0},
                           intensity=lamp.get("intensity", spec["intensity"]), range=spec["range"],
                           castsShadows=spec["shadows"])
                slots = piece(*spec["piece"])[1]
                glow = dict(flameSlot=spec["flameSlot"], chimneySlot=spec["chimneySlot"],
                            flameLit=slots[spec["flameSlot"]])
                if spec["chimneySlot"] >= 0:
                    glow["chimneyLit"] = slots[spec["chimneySlot"]]
                self.lamps.append((lamp_entity, light, glow))

    # ---- the thief, his camera, the guards, loot, the target, the exit, checkpoints ----
    def people(self):
        d, t = self.d, self.t
        sx, sz, syaw = t["start"]
        thief = d.stable_id("entity")
        d.entity("Player", (sx, 0.9, sz), yaw(syaw), eid=thief)
        d.add(thief, "physics.Character", radius=0.3, halfHeight=0.6, maxSlopeDegrees=45.0, stepUp=0.3)
        model = model_prefab("Models/Thief")
        d.instance(model, (0, -0.9, 0), parent=thief, ops=model_ops(model, "ThiefGraph"))
        # The right hand reaches for a lock (Door.as sets the target and the weight while picking).
        d.add(thief, "two_bone_ik", startBone="upperarm_R", midBone="forearm_R", endBone="hand_R", weight=0.0,
              fadeSeconds=0.25)
        cam = d.stable_id("entity")
        d.entity("Camera", (sx, 7.9, sz + 6.5), pitch(-42.0), eid=cam)
        d.add(cam, "camera", fovYRadians=0.9)
        d.script(thief, (asset("ScriptClassAsset", "Thief"), {"camera": ("entity", cam),
                                                              "pebble": ("asset", asset("PrefabDocument", "Pebble"))}),
                 (asset("ScriptClassAsset", "LightMeter"), {}),  # the HUD is the game's (Lamplight.as)
                 (asset("ScriptClassAsset", "Footsteps"), {s.lower(): ("asset", self.surf[s]) for s in self.surf}))
        d.script(cam, (asset("ScriptClassAsset", "CameraRig"), {"target": ("entity", thief)}))
        self.thief, self.cam = thief, cam

        for n, round_ in enumerate(t.get("guards", [])):
            self.guard(n, round_)
        for n, item in enumerate(t.get("loot", [])):
            self.loot("Loot%d" % n, item["kind"], item["at"], item.get("value", 10), False)
        target = t["target"]
        self.loot("Target", target["kind"], target["at"], target.get("value", 100), True)
        self.trigger("Exit", t["exit"], "Exit", {"thief": ("entity", thief)})
        for n, rect in enumerate(t.get("checkpoints", [])):
            self.trigger("Checkpoint%d" % n, rect, "Checkpoint", {"thief": ("entity", thief)})

    def guard(self, n, points):
        """A guard on his round: a navigation agent walking the points (Guard.as), his model under
        him driven by its graph, a kinematic capsule in the guards' own collision group (the thief
        cannot walk through him; his own sight looks past it), his lantern's spot light where the
        model holds the lantern (0.26 m left, 1.02 up, 0.41 ahead, measured on the held pose), and
        the meter over his head."""
        d = self.d
        round_ = d.stable_id("entity")
        d.entity("Round%d" % n, eid=round_)
        for i, (x, z) in enumerate(points):
            d.entity("Point%d" % i, (x, 0.0, z), parent=round_)
        guard = d.stable_id("entity")
        d.entity("Guard%d" % (n + 1), (points[0][0], 0.0, points[0][1]), eid=guard)
        d.add(guard, "navigation.Agent", radius=0.35, height=1.8, maxSpeed=4.0, maxAcceleration=8.0)
        model = model_prefab("Models/Guard")
        d.instance(model, (0, 0, 0), parent=guard, ops=model_ops(model, "GuardGraph"))
        body = d.stable_id("entity")
        d.entity("GuardCollider", (0, 0.9, 0), parent=guard, eid=body)
        d.add(body, "physics.RigidBody", motion=1, layer=2, shape=2, radius=0.35, halfHeight=0.55,
              collisionGroup=GUARD_GROUP)
        lantern = d.stable_id("entity")
        # A spot light shines along its -Z; the guard faces +Z, so it is turned half round, then tipped.
        d.entity("Lantern", (0.26, 1.02, 0.41), quat_mul(yaw(180.0), pitch(-20.0)), parent=guard, eid=lantern)
        d.add(lantern, "light", type=2, color={"r": 1.0, "g": 0.8, "b": 0.55, "a": 1.0}, intensity=12.0,
              range=9.0, outerAngle=0.6, innerAngle=0.45, castsShadows=True)
        meter = d.stable_id("entity")
        d.entity("Meter", (0, 2.25, 0), parent=guard, eid=meter)
        d.add(meter, "ui.Billboard", document=asset("UIDocumentAsset", "GuardMeter"), visible=False)
        d.script(guard, (asset("ScriptClassAsset", "Guard"), {
            "thief": ("entity", self.thief), "route": ("entity", round_), "lantern": ("entity", lantern),
            "meter": ("entity", meter), "group": GUARD_GROUP}))

    def loot(self, name, kind, at, value, target):
        x, z = at
        e = self.place(name, "Loot", kind, (x, 0.0, z))
        self.d.script(e, (asset("ScriptClassAsset", "Loot"), {"thief": ("entity", self.thief), "value": value,
                                                             "target": target}))

    # ---- behaviours that need the thief and camera: lamps, doors, the cutaway ----
    def wiring(self):
        d, thief, cam = self.d, self.thief, self.cam
        for lamp, light, slots in self.lamps:
            props = {"thief": ("entity", thief), "light": ("entity", light),
                     "flameSlot": slots["flameSlot"], "chimneySlot": slots["chimneySlot"],
                     "flameLit": ("asset", slots["flameLit"]), "flameOut": ("asset", self.mats["FlameOut"]),
                     "chimneyOut": ("asset", self.mats["ChimneyOut"])}
            if "chimneyLit" in slots:
                props["chimneyLit"] = ("asset", slots["chimneyLit"])
            d.script(lamp, (asset("ScriptClassAsset", "Lamp"), props))
        for hinge, shut, lock_along, lock_height, locked, pick in self.doors:
            d.script(hinge, (asset("ScriptClassAsset", "Door"), {
                "thief": ("entity", thief), "locked": locked, "shutYaw": shut, "lockAlong": lock_along,
                "lockHeight": lock_height, "pickSeconds": float(pick)}))
        if self.t.get("alarm"):
            # The floor's bell: a guard giving chase rings it and brings every guard (Alarm.as).
            e = d.stable_id("entity")
            d.entity("Alarm", eid=e)
            d.script(e, (asset("ScriptClassAsset", "Alarm"), {"thief": ("entity", thief)}))
        cutaway = asset("ScriptClassAsset", "CutawayWall")
        for e, (nx, nz), half in self.fading:
            d.script(e, (cutaway, {"camera": ("entity", cam), "thief": ("entity", thief),
                                   "normalX": float(nx), "normalZ": float(nz), "halfLength": float(half)}))

    def navigation(self):
        x0, z0, x1, z1 = self.t["bounds"]
        e = self.d.stable_id("entity")
        self.d.entity("NavZone", ((x0 + x1) / 2, 1.5, (z0 + z1) / 2), eid=e)
        # Baked for the guards' own radius (0.35 m) on a fine grid: at the default 0.6 m a 1.2 m
        # doorway or gate erodes shut and no round goes through one.
        self.d.add(e, "navigation.Zone", extents={"x": (x1 - x0) / 2, "y": 3.0, "z": (z1 - z0) / 2},
                   zone=nav_zone(self.t["name"]), agentRadius=0.35, cellSize=0.15, cellHeight=0.1)

    def build(self):
        self.ground()
        self.walls()
        self.props()
        self.rooms()
        self.hatch()
        self.lights()
        self.people()
        self.weather()
        self.wiring()
        self.navigation()
        name = self.t["name"]
        scenes = [a for a in ASSETS if a["type"] == "SceneDocument" and a["name"] == name]
        return self.d.write(scenes[0]["guid"] if scenes else None, group="Scenes")


def write(name):
    guid = Builder(levels.LEVELS[name]).build()
    # The navigation for the guards: baked from the scene's static colliders into <Level>Nav.
    mcp("page_open", {"guid": guid})
    print(name, guid, mcp("navigation_bake", {"page": guid, "entity": "NavZone"}).get("triangles"), "nav triangles")
    return guid


if __name__ == "__main__":
    names = sys.argv[1:] or list(levels.LEVELS)
    first = None
    for n in names:
        g = write(n)
        first = first or g
    if names and names[0] == levels.FIRST:
        mcp("project_settings_set", {"defaultSceneId": first})  # the game boots into the first level
    mcp("asset_cook", {})
