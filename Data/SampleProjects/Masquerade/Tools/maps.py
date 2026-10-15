#!/usr/bin/env python3
"""maps.py [Map ...]: writes a map's scene through the editor's MCP (the Palace for now).

A map is a ball: the ground, the walls and what stands on it from the palace kit
(blender/palace.py), each with its own unscaled collider placed from the same sizes; the lights;
the places guests wander to; the orchestra; some 150 guests; the player and the
camera; the navigation zone over it all, baked after writing.

The guests are drawn by costume: a Guests entity carries the instanced skinning (the guests' rig
and their clips: Idle, Walk, Talk, Dance, in that order, which Guest.as and Player.as count on)
and a child per costume carries that costume's instanced mesh, with no instances of its own. Each
guest is an entity of its own under its costume's parent in the Crowd, a navigation agent with an
Instance Member of its costume's mesh, so every guest in a costume is one draw wherever the crowd
takes them. The four hunters (the player and three bots) wear six looks each, one shown, so the
round (Ball.as) can change a hunter's costume.

Metres throughout; the map's origin is its north-west corner, north being -Z. Cells (2 m: cell
(i, j) spans x 2i..2i+2, z 2j..2j+2) for the ground.

Run with the editor open on the project and its MCP server on, after the models are imported and
importscripts.py has run:
    python3 maps.py Palace
"""
import math, os, random, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import Doc, mcp, yaw, pitch, assets
from look import look

GRID = 2.0
COSTUMES = ("GownRose", "GownTeal", "GownGold", "CoatBlack", "CoatPlum", "CoatIvory")
CLIPS = ("Idle", "Walk", "Talk", "Dance")  # the clip list's order: the scripts' activity numbers
POSES_PER_CLIP = 12  # phases of each clip in the pose pool: guests on a clip spread over them

ASSETS = assets()


def asset(asset_type, name, group=None):
    found = [a["guid"] for a in ASSETS
             if a["type"] == asset_type and a["name"] == name and (group is None or a.get("group") == group)]
    if not found:
        raise SystemExit("no %s %s (run importmodels.py / importscripts.py first)" % (asset_type, name))
    return found[0]


def model_prefab(group):
    found = [a["guid"] for a in ASSETS if a["type"] == "PrefabDocument" and a.get("group") == group]
    if not found:
        raise SystemExit("no model in %s (run the Blender script and importmodels.py)" % group)
    return found[0]


_models = {}


def model(group):
    """An imported model's parts, read from its prefab: its mesh and material slots, and (rigged)
    its skeleton."""
    if group not in _models:
        root = ET.fromstring(mcp("prefab_read", {"guid": model_prefab(group)})["xml"])
        parts = {}
        for comp in root.find("array[@name='components']"):
            kind = comp.find("string[@name='type']").text
            data = comp.find("object[@name='data']")
            if kind == "mesh":
                parts["mesh"] = data.find("string[@name='mesh']").text
                parts["materials"] = [e.text for e in data.find("array[@name='materials']")]
            elif kind == "skeletal_animation":
                parts["skeleton"] = data.find("string[@name='skeleton']").text
        _models[group] = parts
    return _models[group]


def quat_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


def short(kind):
    """A kit piece's own name (Canal/Bridge -> Bridge), for entity names."""
    return kind.split("/")[-1]


def strings(guids):
    return ["<string>%s</string>" % g for g in guids]


class Builder:
    """One map's scene being written."""

    def __init__(self, name):
        self.name = name
        self.d = Doc(name)
        self.rng = random.Random(name)  # the same map writes the same scene
        look(self.d, "Night")

    def place(self, name, kind, pos, rot=(0, 0, 0, 1), parent=None):
        """A kit piece, its materials as imported: "Kit/Piece" (Canal/Bridge), or a palace piece by
        its name alone."""
        parts = model("Models/" + (kind if "/" in kind else "Palace/" + kind))
        e = self.d.stable_id("entity")
        self.d.entity(name, pos, rot, parent=parent, eid=e)
        self.d.add(e, "mesh", mesh=parts["mesh"], materials=strings(parts["materials"]))
        return e

    def solid(self, name, pos, size, rot=(0, 0, 0, 1)):
        """A static box collider of its own, unscaled, so the shape is the size it says."""
        e = self.d.stable_id("entity")
        self.d.entity(name + "Collider", pos, rot, eid=e)
        self.d.add(e, "physics.RigidBody", motion=0, layer=0, shape=0,
                   halfExtents={"x": size[0] / 2, "y": size[1] / 2, "z": size[2] / 2})
        return e

    def ground(self, kind, cells):
        """Tiles of `kind` over cells (i0, j0, i1, j1), a slab collider under them all."""
        i0, j0, i1, j1 = cells
        for i in range(i0, i1):
            for j in range(j0, j1):
                self.place("%s%d_%d" % (short(kind), i, j), kind, (GRID * (i + 0.5), 0.0, GRID * (j + 0.5)))
        w, h = GRID * (i1 - i0), GRID * (j1 - j0)
        self.solid(short(kind), (GRID * i0 + w / 2, -0.25, GRID * j0 + h / 2), (w, 0.5, h))

    def run(self, kind, a, b, height, thick, skip=(), every=None, alt=None):
        """A run of 2 m edges from a to b (metres, along x or z): `kind` on each, `alt` on every
        `every`th; segments whose middle is in `skip` left open. One collider per stretch."""
        (x0, z0), (x1, z1) = a, b
        along_x = z0 == z1
        n = int(round(abs((x1 - x0) if along_x else (z1 - z0)) / GRID))
        sign = 1 if (x1 > x0 if along_x else z1 > z0) else -1
        stretch = []

        def close():
            if stretch:
                lo, hi = stretch[0] - GRID / 2, stretch[-1] + GRID / 2
                mid, length = (lo + hi) / 2, hi - lo
                pos = (mid, height / 2, z0) if along_x else (x0, height / 2, mid)
                size = (length, height, thick) if along_x else (thick, height, length)
                self.solid("%s%d_%d" % (short(kind), int(mid), int(z0 if along_x else x0)), pos, size)
                stretch.clear()

        for s in range(n):
            c = (x0 if along_x else z0) + sign * GRID * (s + 0.5)
            at = (c, 0.0, z0) if along_x else (x0, 0.0, c)
            if (at[0], at[2]) in skip:
                close()
                continue
            piece = alt if (every and alt and s % every == every // 2) else kind
            self.place("%s%d_%d" % (short(piece), int(at[0]), int(at[2])), piece, at,
                       (0, 0, 0, 1) if along_x else yaw(90.0))
            stretch.append(c)
        close()

    def prop(self, kind, pos, size, rot=(0, 0, 0, 1), name=None):
        """A kit piece standing on the ground with a box collider of `size` (x, height, z)."""
        e = self.place(name or "%s%d_%d" % (short(kind), int(pos[0]), int(pos[2])), kind, pos, rot)
        self.solid(short(kind) + "%d_%d" % (int(pos[0]), int(pos[2])), (pos[0], size[1] / 2, pos[2]),
                   size, rot)
        return e

    def light(self, name, pos, color, intensity, rng, shadows=False, parent=None):
        e = self.d.stable_id("entity")
        self.d.entity(name, pos, parent=parent, eid=e)
        self.d.add(e, "light", type=1, color=color, intensity=intensity, range=rng, castsShadows=shadows)
        return e

    def lantern(self, x, z):
        post = self.prop("Lantern", (x, 0.0, z), (0.4, 2.6, 0.4))
        self.light("LanternLight%d_%d" % (int(x), int(z)), (0, 2.62, 0),
                   {"r": 1.0, "g": 0.74, "b": 0.45, "a": 1.0}, 5.0, 8.0, parent=post)

    def chandelier(self, x, z, height):
        e = self.place("Chandelier%d" % int(x), "Chandelier", (x, height, z))
        self.light("ChandelierLight%d" % int(x), (0, -0.9, 0), {"r": 1.0, "g": 0.80, "b": 0.55, "a": 1.0},
                   9.0, 13.0, parent=e)

    def points(self, name, spots):
        """A parent entity whose children are places (the guests' `spots`): (x, z) on the ground, or
        (x, y, z) above it (a bridge's top)."""
        parent = self.d.stable_id("entity")
        self.d.entity(name, eid=parent)
        for k, spot in enumerate(spots):
            at = (spot[0], 0.0, spot[1]) if len(spot) == 2 else tuple(spot)
            self.d.entity("%s%d" % (name[:-1] if name.endswith("s") else name, k), at, parent=parent)
        return parent

    # ---- the guests, the hunters, the ball ----
    def crowd(self, count, spots, player_at):
        """The Guests entity (instanced skinning over a costume mesh each); the crowd, a parent per
        costume with its guests under it (Ball.as tells a guest's costume by its parent); the four
        hunters, the player and three bots, each wearing one of six looks (Ball.as picks); the
        camera; the Ball, which runs the round."""
        d = self.d
        first = model("Models/Guests/Guest" + COSTUMES[0])
        clips = [asset("AnimationClipAsset", c, "Models/Guests/Guest" + COSTUMES[0]) for c in CLIPS]
        guests = d.stable_id("entity")
        d.entity("Guests", eid=guests)
        meshes = {}
        for c in COSTUMES:
            parts = model("Models/Guests/Guest" + c)
            e = d.stable_id("entity")
            d.entity("Costume" + c, parent=guests, eid=e)
            d.add(e, "instanced_mesh", mesh=parts["mesh"], materials=strings(parts["materials"]), instances=[],
                  poseAssignment=0)
            meshes[c] = e
        d.add(guests, "instanced_skinning", skeleton=first["skeleton"], clips=strings(clips),
              poseCount=POSES_PER_CLIP, targets=strings(meshes[c] for c in COSTUMES))

        # The crowd and the players: parents at the origin (agents write their position as local).
        guest_script = asset("ScriptClassAsset", "Guest")
        players = d.stable_id("entity")
        d.entity("Players", eid=players)
        crowd = d.stable_id("entity")
        d.entity("Crowd", eid=crowd)
        groups = {}
        for c in COSTUMES:
            groups[c] = d.stable_id("entity")
            d.entity(c, parent=crowd, eid=groups[c])
        ground = [spot for spot in spots if len(spot) == 2]  # guests start on the ground, not on a bridge
        placed = [(self.rng.choice(ground), self.rng.choice(COSTUMES)) for _ in range(count)]
        for n, ((x, z), costume) in enumerate(placed):
            a, r = self.rng.uniform(-math.pi, math.pi), 1.6 * math.sqrt(self.rng.uniform(0.05, 1.0))
            e = d.stable_id("entity")
            d.entity("Guest%d" % (n + 1), (x + math.sin(a) * r, 0.0, z + math.cos(a) * r),
                     yaw(self.rng.uniform(-180, 180)), parent=groups[costume], eid=e)
            self.agent(e)
            self.networked(e)
            d.add(e, "instance_member", instancedMesh=meshes[costume], clip=0)
            d.script(e, (guest_script, {"spots": ("entity", self.spots), "players": ("entity", players)}))

        # The hunters: the player at the gate (under Players, whom guests make way for), the bots
        # among the guests.
        x, z = player_at
        player = self.hunter("Player", (x, 0.0, z), meshes, avoid=False, parent=players)
        cam = d.stable_id("entity")
        d.entity("Camera", (x, 9.0, z + 7.0), pitch(-48.0), eid=cam)
        d.add(cam, "camera", fovYRadians=0.9)
        d.script(player, (asset("ScriptClassAsset", "Player"), {"camera": ("entity", cam), "crowd": ("entity", crowd),
                                                                "seat": 0}))
        d.script(cam, (asset("ScriptClassAsset", "CameraRig"), {"target": ("entity", player), "distance": 7.0,
                                                                 "height": 9.0}))
        bots = []
        for k in range(3):
            bx, bz = self.rng.choice(ground)
            bot = self.hunter("Bot%d" % (k + 1), (bx + 1.0, 0.0, bz), meshes)
            d.script(bot, (guest_script, {"spots": ("entity", self.spots), "players": ("entity", players)}))
            bots.append(bot)

        ball = d.stable_id("entity")
        d.entity("Ball", eid=ball)
        self.networked(ball)
        d.script(ball, (asset("ScriptClassAsset", "Ball"), {
            "player": ("entity", player), "bot1": ("entity", bots[0]), "bot2": ("entity", bots[1]),
            "bot3": ("entity", bots[2]), "crowd": ("entity", crowd), "spots": ("entity", self.spots),
            "players": ("entity", players), "hunterPrefab": ("asset", self.hunter_prefab(meshes))}))

    def hunter(self, name, pos, meshes, avoid=True, parent=None):
        """A hunter: an agent like any guest, wearing one of six looks (a child per costume, each an
        Instance Member of its costume's mesh; only the first shown until Ball.as dresses it), and
        a Flare light over its head for when its mask flares (off until then)."""
        d = self.d
        e = d.stable_id("entity")
        d.entity(name, pos, parent=parent, eid=e)
        self.agent(e, avoid)
        self.networked(e)
        for k, c in enumerate(COSTUMES):
            look = d.stable_id("entity")
            d.entity("Look" + c, parent=e, eid=look, active=(k == 0))
            d.add(look, "instance_member", instancedMesh=meshes[c], clip=0)
        flare = d.stable_id("entity")
        d.entity("Flare", (0.0, 2.1, 0.0), parent=e, eid=flare)
        d.add(flare, "light", type=1, color={"r": 1.0, "g": 0.78, "b": 0.30, "a": 1.0}, intensity=0.0, range=6.0,
              castsShadows=False)
        return e

    def networked(self, e):
        """Replicated over the network: an authored network id (both peers load the same scene, so
        the id matches by the entity's guid) and its transform sent, smoothed on clients."""
        self.d.add(e, "net.Network")
        self.d.add(e, "net.Transform")

    def hunter_prefab(self, meshes):
        """The prefab the host spawns for a joining player (Ball.as, Net.spawnFor): a hunter as
        hunter() makes one, its looks naming this map's costume meshes (so a prefab per map), its
        Player behaviour finding the camera and the crowd by name. Written over the last one."""
        doc = Doc("Hunter" + self.name)
        e = doc.stable_id("entity")
        doc.entity("Hunter", eid=e)
        doc.add(e, "navigation.Agent", radius=0.3, height=1.7, maxSpeed=3.2, maxAcceleration=6.0, avoidOthers=False)
        doc.add(e, "net.Network")
        doc.add(e, "net.Transform")
        for k, c in enumerate(COSTUMES):
            look = doc.stable_id("entity")
            doc.entity("Look" + c, parent=e, eid=look, active=(k == 0))
            doc.add(look, "instance_member", instancedMesh=meshes[c], clip=0)
        flare = doc.stable_id("entity")
        doc.entity("Flare", (0.0, 2.1, 0.0), parent=e, eid=flare)
        doc.add(flare, "light", type=1, color={"r": 1.0, "g": 0.78, "b": 0.30, "a": 1.0}, intensity=0.0, range=6.0,
                castsShadows=False)
        doc.script(e, (asset("ScriptClassAsset", "Player"), {}))
        found = [a["guid"] for a in ASSETS if a["type"] == "PrefabDocument" and a["name"] == doc.name]
        return doc.write(found[0] if found else None, prefab=True, group="Prefabs")

    def agent(self, e, avoid=True):
        """A guest's body: an agent the crowd steers. The player's goes straight where the stick
        sends it (avoid=False) and shoulders past guests in its way; avoiding, it would hold back
        from anyone ahead, which plays as an invisible wall."""
        self.d.add(e, "navigation.Agent", radius=0.3, height=1.7, maxSpeed=3.2, maxAcceleration=6.0,
                   avoidOthers=avoid)

    def navigation(self, bounds, climb=0.25):
        x0, z0, x1, z1 = bounds
        e = self.d.stable_id("entity")
        self.d.entity("NavZone", ((x0 + x1) / 2, 1.5, (z0 + z1) / 2), eid=e)
        found = [a["guid"] for a in ASSETS if a["type"] == "NavigationZoneAsset" and a["name"] == self.name + "Nav"]
        zone = found[0] if found else mcp("asset_create", {"creator": "Navigation Zone", "name": self.name + "Nav",
                                                           "group": "Navigation"})["guid"]
        # Fine enough that the gaps between the colonnade's columns stay open for a guest's radius,
        # and flat enough (the cell height) that guests stand on the floor, not above it. A guest
        # steps up nothing taller than a kerb: the fountain's basin, the benches and the dais are
        # in the way, not walked over.
        self.d.add(e, "navigation.Zone", extents={"x": (x1 - x0) / 2, "y": 3.0, "z": (z1 - z0) / 2}, zone=zone,
                   agentRadius=0.3, cellSize=0.2, cellHeight=0.05, agentMaxClimb=climb, maxAgents=256)

    def write(self):
        scenes = [a for a in ASSETS if a["type"] == "SceneDocument" and a["name"] == self.name]
        return self.d.write(scenes[0]["guid"] if scenes else None, group="Scenes")


def palace():
    """The Palace: a ballroom on the north side (x 8..36, z 2..16, marble, windows down its walls,
    chandeliers, the orchestra's dais), open to the courtyard south of it through a colonnade; the
    courtyard (x 4..40, z 16..44, flagstones) round a fountain, lanterns, orange trees in pots and
    benches, inside a balustrade with a gate in its south side."""
    b = Builder("Palace")
    d = b.d
    moon = d.stable_id("entity")
    d.entity("Moon", rot=quat_mul(yaw(-60.0), pitch(-50.0)), eid=moon)
    d.add(moon, "light", type=0, color={"r": 0.55, "g": 0.65, "b": 1.0, "a": 1.0}, intensity=0.35,
          castsShadows=True)

    b.ground("Marble", (4, 1, 18, 8))
    b.ground("Flags", (2, 8, 20, 22))
    # The ballroom's walls, a window every other edge, piers at the corners.
    b.run("Wall", (8, 2), (36, 2), 5.0, 0.4, every=2, alt="Window")
    b.run("Wall", (8, 2), (8, 16), 5.0, 0.4, every=2, alt="Window")
    b.run("Wall", (36, 2), (36, 16), 5.0, 0.4, every=2, alt="Window")
    for x, z in ((8, 2), (36, 2), (8, 16), (36, 16)):
        b.prop("Pier", (x, 0.0, z), (0.6, 5.2, 0.6))
    for k in range(7):  # the colonnade, open to the courtyard
        b.prop("Column", (10.0 + 4.0 * k, 0.0, 16.0), (0.6, 5.0, 0.6))
    # The courtyard's balustrade: west, east, south (the gate's two edges left open), and the short
    # runs either side of the ballroom.
    b.run("Balustrade", (4, 16), (4, 44), 1.0, 0.3)
    b.run("Balustrade", (40, 16), (40, 44), 1.0, 0.3)
    b.run("Balustrade", (4, 44), (40, 44), 1.0, 0.3, skip={(21.0, 44.0), (23.0, 44.0)})
    b.run("Balustrade", (4, 16), (8, 16), 1.0, 0.3)
    b.run("Balustrade", (36, 16), (40, 16), 1.0, 0.3)

    # The fountain: an octagon of two boxes for its basin.
    b.place("Fountain", "Fountain", (22.0, 0.0, 30.0))
    b.solid("Fountain", (22.0, 0.35, 30.0), (5.6, 0.7, 5.6))
    b.solid("FountainTurned", (22.0, 0.35, 30.0), (5.6, 0.7, 5.6), yaw(45.0))
    for k in range(6):
        t = 2 * math.pi * (k + 0.5) / 6
        b.lantern(22.0 + 6.5 * math.cos(t), 30.0 + 6.5 * math.sin(t))
    for x, z in ((6.5, 18.5), (37.5, 18.5), (6.5, 41.5), (37.5, 41.5)):
        b.lantern(x, z)
    for z in (21.0, 27.0, 33.0, 39.0):
        b.prop("Planter", (5.4, 0.0, z), (0.8, 2.2, 0.8))
        b.prop("Planter", (38.6, 0.0, z), (0.8, 2.2, 0.8))
    for x, z, turn in ((14.0, 24.0, 135.0), (30.0, 24.0, -135.0), (14.0, 36.0, 45.0), (30.0, 36.0, -45.0)):
        b.prop("Bench", (x, 0.0, z), (1.6, 0.45, 0.5), yaw(turn))

    for x in (15.0, 22.0, 29.0):
        b.chandelier(x, 9.5, 5.2)
    dais = b.prop("Dais", (22.0, 0.0, 3.8), (6.0, 0.4, 3.0), name="Dais")
    b.networked(dais)  # the cue replicates
    d.script(dais, (asset("ScriptClassAsset", "Orchestra"), {}))

    # The places guests go: groups across the courtyard, along the ballroom's walls and under the
    # colonnade, some 40 for 150 guests (a few to a group).
    spots = [(10, 20), (16, 20), (28, 20), (34, 20), (8, 28), (36, 28), (10, 38), (16, 40), (28, 40), (34, 38),
             (22, 39), (22, 21), (11, 7), (11, 13), (33, 7), (33, 13), (17, 13), (27, 13),
             (8, 23), (36, 23), (8, 34), (36, 34), (13, 30), (31, 30), (16, 26), (28, 26), (16, 34), (28, 34),
             (12, 18), (32, 18), (22, 18), (8, 42), (36, 42), (16, 41.5), (28, 41.5), (14, 5), (30, 5)]
    # Round the fountain, far enough out that a group spread round a place stays off the basin.
    spots += [(22 + 5.8 * math.cos(2 * math.pi * k / 8), 30 + 5.8 * math.sin(2 * math.pi * k / 8)) for k in range(8)]
    b.spots = b.points("Spots", spots)
    b.crowd(150, spots, (22.0, 42.0))
    b.navigation((3.0, 1.0, 41.0, 45.0))
    return b.write()


def spline_points(points):
    """A path's points with Catmull-Rom handles (a sixth of the chord between neighbours, in and out
    mirrored), wrapping round for a closed loop; an array of structs written flat, each element's
    fields one after another, as the engine writes it (Snowline's course.py)."""
    items = []
    n = len(points)
    for i, p in enumerate(points):
        a, b = points[(i - 1) % n], points[(i + 1) % n]
        h = [(b[k] - a[k]) / 6.0 for k in range(3)]
        items.append('<object name="position">%s</object><object name="in">%s</object>'
                     '<object name="out">%s</object><u8 name="mode">0</u8>' % (
                         "".join('<f32 name="%s">%s</f32>' % (k, repr(float(v))) for k, v in zip("xyz", p)),
                         "".join('<f32 name="%s">%s</f32>' % (k, repr(-float(v))) for k, v in zip("xyz", h)),
                         "".join('<f32 name="%s">%s</f32>' % (k, repr(float(v))) for k, v in zip("xyz", h))))
    return items


CANAL_FACADES = ("FacadeOchre", "FacadeRose", "FacadeWhite")
CANAL_DOORS = ("DoorOchre", "DoorRose", "DoorWhite")
WATER_Y = -0.9
BRIDGE_L, BRIDGE_W, BRIDGE_RISE, BRIDGE_RAMP = 8.0, 3.0, 1.8, 2.8


def facade_row(b, a, c, turn, door_every=3):
    """House fronts along a run of 2 m edges from a to c (metres, along x or z), facing `turn`
    degrees about +Y (0 faces +Z), colours at random and a door every so often; one collider for
    the whole row, the houses behind it being out of reach."""
    (x0, z0), (x1, z1) = a, c
    along_x = z0 == z1
    n = int(round(abs((x1 - x0) if along_x else (z1 - z0)) / GRID))
    sign = 1 if (x1 > x0 if along_x else z1 > z0) else -1
    for k in range(n):
        m = (x0 if along_x else z0) + sign * GRID * (k + 0.5)
        at = (m, 0.0, z0) if along_x else (x0, 0.0, m)
        kind = "Canal/" + b.rng.choice(CANAL_DOORS if k % door_every == 1 else CANAL_FACADES)
        b.place("%s%d_%d" % (short(kind), int(at[0]), int(at[2])), kind, at, yaw(turn))
    length = GRID * n
    mid = ((x0 + x1) / 2, 4.0, z0) if along_x else (x0, 4.0, (z0 + z1) / 2)
    b.solid("Houses%d_%d" % (int(mid[0]), int(mid[2])), mid, (length, 8.0, 0.5) if along_x else (0.5, 8.0, length))


def canal_bridge(b, x, z):
    """A bridge across the canal at (x, z), its length along z: the model, and colliders for its walk
    (two ramps and the level top) and its parapets, so the navigation bakes a way over it. Its 33
    degree ramps need the Canal's higher climb (see canal()): Recast drops a walkable cell whose
    neighbours' floors differ by more than the climb, and across a ramp cell they differ by about
    0.26 m."""
    b.place("Bridge%d" % int(x), "Canal/Bridge", (x, 0.0, z))
    half, top, ramp = BRIDGE_L / 2, BRIDGE_RISE, BRIDGE_RAMP
    angle = math.degrees(math.atan2(top, ramp))
    slope = math.hypot(top, ramp)
    for sign in (-1, 1):
        # A ramp: its top face rising from the bank to the level top. A positive turn about X tips
        # +z down, so the south ramp (sign +1, low at its +z bank end) turns positive and the north
        # ramp negative.
        b.solid("BridgeRamp%d_%d" % (int(x), sign), (x, top / 2 - 0.12, z + sign * (half - ramp / 2)),
                (BRIDGE_W, 0.25, slope), pitch(sign * angle))
    b.solid("BridgeTop%d" % int(x), (x, top - 0.12, z), (BRIDGE_W, 0.25, 2 * (half - ramp)))
    for side in (-1, 1):
        b.solid("BridgeParapet%d_%d" % (int(x), side), (x + side * (BRIDGE_W / 2 - 0.12), (top + 1.0) / 2, z),
                (0.25, top + 1.0, BRIDGE_L))


def canal():
    """The Canal: a campo (a square, x 6..42, z 4..30) with houses round three sides, a wellhead, mask
    stalls and the orchestra, on a canal running east-west across the south (z 30..36, its water
    below the quays), a narrow quay beyond it (z 36..40) along a balustrade, two bridges over it,
    and gondolas passing under them. The crowd thins out across the campo and squeezes onto the quays
    and the bridges."""
    b = Builder("Canal")
    d = b.d
    moon = d.stable_id("entity")
    d.entity("Moon", rot=quat_mul(yaw(-50.0), pitch(-45.0)), eid=moon)
    d.add(moon, "light", type=0, color={"r": 0.55, "g": 0.65, "b": 1.0, "a": 1.0}, intensity=0.35,
          castsShadows=True)

    b.ground("Canal/Paving", (3, 2, 21, 15))   # the campo and its quay: x 6..42, z 4..30
    b.ground("Canal/Paving", (0, 18, 24, 20))  # the south quay: x 0..48, z 36..40
    for i in range(0, 24):                     # the water, below the quays (no collider: no walking)
        for j in range(15, 18):
            b.place("Water%d_%d" % (i, j), "Canal/Water", (GRID * (i + 0.5), 0.0, GRID * (j + 0.5)))
    # The quays' edges: the campo's faces the water to the south (+z), the south quay's to the north.
    for i in range(3, 21):
        b.place("CopingN%d" % i, "Canal/Coping", (GRID * (i + 0.5), 0.0, 30.0), yaw(180.0))
    for i in range(0, 24):
        b.place("CopingS%d" % i, "Canal/Coping", (GRID * (i + 0.5), 0.0, 36.0))

    # The houses: the campo's north row facing south, its west and east rows facing in. The south
    # quay's far side is a low balustrade, not houses: the camera stands south of the player and
    # would look at the backs of a row there, through 8 m of wall.
    facade_row(b, (6, 4), (42, 4), 0.0)
    facade_row(b, (6, 4), (6, 30), 90.0)
    facade_row(b, (42, 4), (42, 30), -90.0)
    b.run("Balustrade", (0, 40), (48, 40), 1.0, 0.3)

    canal_bridge(b, 14.0, 33.0)
    canal_bridge(b, 34.0, 33.0)
    for x, z in ((4.0, 30.6), (9.0, 30.6), (21.0, 35.4), (27.0, 35.4), (40.0, 30.6), (45.0, 35.4)):
        b.place("Pole%d_%d" % (int(x), int(z)), "Canal/Pole", (x, 0.0, z))

    # The gondolas: a loop along the canal, east on the north lane and west on the south, turning
    # beyond the ends of the map, two boats on it half a loop apart.
    loop = [(-6, 32.2), (10, 32.2), (24, 32.2), (38, 32.2), (54, 32.2), (57, 33.0), (54, 33.8), (38, 33.8),
            (24, 33.8), (10, 33.8), (-6, 33.8), (-9, 33.0)]
    path = d.stable_id("entity")
    d.entity("GondolaPath", eid=path)
    d.add(path, "spline", points=spline_points([(x, WATER_Y, z) for x, z in loop]), closed=True)
    for k, start in enumerate((0.0, 64.0)):
        boat = b.place("Gondola%d" % (k + 1), "Canal/Gondola", (loop[0][0], WATER_Y, loop[0][1]))
        d.add(boat, "path_follow", spline=path, speed=1.4, distance=start, loop=True, playing=True,
              alignToTangent=True)

    b.prop("Canal/Wellhead", (24.0, 0.0, 17.0), (1.4, 1.1, 1.4))
    for x, z, turn in ((12.0, 9.0, 0.0), (36.0, 9.0, 0.0), (9.0, 22.0, 90.0)):
        b.prop("Canal/Stall", (x, 0.0, z), (2.0, 2.3, 1.0) if turn == 0.0 else (1.0, 2.3, 2.0), yaw(turn))
    # The south quay's lanterns stand back against the balustrade, out of the narrow quay's way.
    for x, z in ((10.0, 14.0), (38.0, 14.0), (10.0, 27.0), (38.0, 27.0), (20.0, 28.5), (28.0, 28.5),
                 (6.0, 39.4), (20.0, 39.4), (28.0, 39.4), (42.0, 39.4)):
        b.lantern(x, z)
    dais = b.prop("Dais", (24.0, 0.0, 6.0), (6.0, 1.2, 3.0), name="Dais")  # its collider too tall to climb
    b.networked(dais)  # the cue replicates
    d.script(dais, (asset("ScriptClassAsset", "Orchestra"), {}))

    # Where guests go: groups about the campo, along both quays, and on the bridges' tops.
    spots = [(12, 13), (18, 11), (30, 11), (36, 13), (16, 18), (32, 18), (12, 22), (24, 22), (36, 22),
             (10, 18), (38, 18), (18, 26), (30, 26), (24, 11), (8, 28), (40, 28), (14, 28), (34, 28),
             (4, 38), (10, 38), (16, 38), (24, 38), (32, 38), (38, 38), (44, 38),
             (14.0, BRIDGE_RISE, 33.0), (34.0, BRIDGE_RISE, 33.0)]
    b.spots = b.points("Spots", spots)
    b.crowd(150, spots, (24.0, 38.5))
    # A higher climb than the Palace's, for the bridges' ramps (canal_bridge); nothing knee-high
    # stands in the campo to be climbed instead, and the dais's collider is tall for it.
    b.navigation((0.0, 3.0, 48.0, 41.0), climb=0.5)
    return b.write()


def gardens():
    """The Gardens: an orangery to the north (x 10..34, z 2..12, a marble hall walled on three sides,
    orange trees in pots, the orchestra, open to the south through a colonnade), a gravel terrace
    in front of it, and a lawn with a hedge maze in it (x 10..34, z 20..40: two rings of hedges round
    a clearing with the fountain, their gaps staggered, a few cross hedges for dead ends), statues,
    urns and lanterns, inside a balustrade. Guests stroll the paths in twos and threes, and the
    hedges, 1.8 m high, hide them from each other but not from the camera above."""
    b = Builder("Gardens")
    d = b.d
    moon = d.stable_id("entity")
    d.entity("Moon", rot=quat_mul(yaw(-40.0), pitch(-50.0)), eid=moon)
    d.add(moon, "light", type=0, color={"r": 0.55, "g": 0.65, "b": 1.0, "a": 1.0}, intensity=0.4,
          castsShadows=True)

    # The ground, one surface a cell (flush tiles laid twice would fight for the pixels): marble in
    # the orangery, gravel on the terrace and the paths, lawn elsewhere; one slab collider under it.
    cells = {}
    for i in range(1, 21):
        for j in range(6, 21):
            cells[(i, j)] = "Gardens/Grass"
    for i in range(2, 20):
        for j in range(6, 8):
            cells[(i, j)] = "Gardens/Gravel"   # the terrace, z 12..16
    for j in range(8, 10):
        for i in (10, 11):
            cells[(i, j)] = "Gardens/Gravel"   # the path down to the maze, x 20..24
    for i in range(5, 17):
        for j in range(1, 6):
            cells[(i, j)] = "Marble"           # the orangery, x 10..34, z 2..12
    for (i, j), kind in sorted(cells.items()):
        b.place("%s%d_%d" % (short(kind), i, j), kind, (GRID * (i + 0.5), 0.0, GRID * (j + 0.5)))
    b.solid("Ground", (22.0, -0.25, 22.0), (44.0, 0.5, 40.0))

    # The orangery: the palace's walls with windows on three sides, piers at the corners, a
    # colonnade open to the terrace, orange trees in rows, chandeliers and the orchestra.
    b.run("Wall", (10, 2), (34, 2), 5.0, 0.4, every=2, alt="Window")
    b.run("Wall", (10, 2), (10, 12), 5.0, 0.4, every=2, alt="Window")
    b.run("Wall", (34, 2), (34, 12), 5.0, 0.4, every=2, alt="Window")
    for x, z in ((10, 2), (34, 2), (10, 12), (34, 12)):
        b.prop("Pier", (x, 0.0, z), (0.6, 5.2, 0.6))
    for k in range(6):
        b.prop("Column", (12.0 + 4.0 * k, 0.0, 12.0), (0.6, 5.0, 0.6))
    for x in (13.0, 31.0):
        for z in (5.0, 9.0):
            b.prop("Planter", (x, 0.0, z), (0.8, 2.2, 0.8))
    for x in (17.0, 27.0):
        b.chandelier(x, 7.0, 4.8)
    dais = b.prop("Dais", (22.0, 0.0, 3.8), (6.0, 1.2, 3.0), name="Dais")  # its collider too tall to climb
    b.networked(dais)  # the cue replicates
    d.script(dais, (asset("ScriptClassAsset", "Orchestra"), {}))

    # The garden's edge: a balustrade round the lawn and the terrace's ends.
    b.run("Balustrade", (2, 12), (2, 42), 1.0, 0.3)
    b.run("Balustrade", (42, 12), (42, 42), 1.0, 0.3)
    b.run("Balustrade", (2, 42), (42, 42), 1.0, 0.3, skip={(21.0, 42.0), (23.0, 42.0)})
    b.run("Balustrade", (2, 12), (10, 12), 1.0, 0.3)
    b.run("Balustrade", (34, 12), (42, 12), 1.0, 0.3)

    # The maze: two rings round a clearing, their gaps staggered so the way in winds, and cross
    # hedges in the corridor between the rings for dead ends.
    def hedges(a, c, gaps=()):
        b.run("Gardens/Hedge", a, c, 1.8, 0.8, skip=set(gaps))
    hedges((10, 20), (34, 20), [(21.0, 20.0), (23.0, 20.0)])        # outer north: the way in
    hedges((10, 40), (34, 40), [(21.0, 40.0), (23.0, 40.0)])        # outer south
    hedges((10, 20), (10, 40), [(10.0, 29.0), (10.0, 31.0)])        # outer west
    hedges((34, 20), (34, 40), [(34.0, 29.0), (34.0, 31.0)])        # outer east
    hedges((14, 24), (30, 24), [(27.0, 24.0)])                      # inner north: in at the east end
    hedges((14, 36), (30, 36), [(17.0, 36.0)])                      # inner south: in at the west end
    hedges((14, 24), (14, 36), [(14.0, 35.0)])                      # inner west
    hedges((30, 24), (30, 36), [(30.0, 25.0)])                      # inner east
    hedges((18, 20), (18, 24))                                      # cross hedges between the rings
    hedges((26, 36), (26, 40))
    hedges((10, 27), (14, 27))
    hedges((30, 33), (34, 33))
    for x, z in ((10, 20), (34, 20), (10, 40), (34, 40), (14, 24), (30, 24), (14, 36), (30, 36)):
        b.prop("Gardens/HedgeCorner", (float(x), 0.0, float(z)), (0.8, 1.8, 0.8))
    b.place("Fountain", "Fountain", (22.0, 0.0, 30.0))
    b.solid("Fountain", (22.0, 0.35, 30.0), (5.6, 0.7, 5.6))
    b.solid("FountainTurned", (22.0, 0.35, 30.0), (5.6, 0.7, 5.6), yaw(45.0))
    for x, z, turn in ((17.0, 26.5, 0.0), (27.0, 33.5, 180.0)):
        b.prop("Bench", (x, 0.0, z), (1.6, 0.45, 0.5), yaw(turn))

    # Statues at the maze's outer corners, urns along the terrace, lanterns about the lawn.
    for x, z in ((7.0, 18.0), (37.0, 18.0), (7.0, 41.0), (37.0, 41.0)):
        b.prop("Gardens/Statue", (x, 0.0, z), (0.9, 2.6, 0.9))
    for x in (6.0, 16.0, 28.0, 38.0):
        b.prop("Gardens/Urn", (x, 0.0, 12.8), (0.6, 1.2, 0.6))
    for x, z in ((19.0, 18.0), (25.0, 18.0), (5.0, 26.0), (39.0, 26.0), (5.0, 36.0), (39.0, 36.0),
                 (20.0, 28.0), (24.0, 32.0)):
        b.lantern(x, z)

    spots = [(16, 6), (22, 8), (28, 6), (18, 10), (26, 10),            # the orangery
             (8, 14), (16, 14), (28, 14), (36, 14),                     # the terrace
             (6, 22), (6, 30), (6, 38), (38, 22), (38, 30), (38, 38), (14, 18), (30, 18),  # the lawn
             (12, 22), (32, 22), (12, 38), (32, 38), (12, 33), (32, 27), (21, 22), (23, 38),  # the maze
             (18, 28), (26, 28), (18, 32), (26, 32)]                    # the clearing
    b.spots = b.points("Spots", spots)
    b.crowd(150, spots, (22.0, 15.0))
    b.navigation((2.0, 2.0, 42.0, 42.0))
    return b.write()


MAPS = {"Palace": palace, "Canal": canal, "Gardens": gardens}


def write(name):
    guid = MAPS[name]()
    # The navigation for the crowd: baked from the scene's static colliders into <Map>Nav.
    mcp("page_open", {"guid": guid})
    print(name, guid, mcp("navigation_bake", {"page": guid, "entity": "NavZone"}).get("triangles"), "nav triangles")
    return guid


if __name__ == "__main__":
    names = sys.argv[1:] or list(MAPS)
    first = None
    for n in names:
        g = write(n)
        first = first or g
    if names and names[0] == "Palace":
        mcp("project_settings_set", {"defaultSceneId": first})  # the game boots into the first map for now
    mcp("asset_cook", {})
