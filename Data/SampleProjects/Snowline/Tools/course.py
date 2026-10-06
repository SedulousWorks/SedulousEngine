#!/usr/bin/env python3
"""course.py <course>: a course's scene, written through the editor's MCP (scene_write).

Needs terrain.py <course> and importall.py <course> first: it places what they made. The scene:
- the sun;
- the mountain: the terrain, its heightfield as a static body, and the vegetation (pines on the
  forest floor's splat layer, rocks scattered thinly on open snow);
- the course line: a spline down the middle of the course (terrain.py's points, with Catmull-Rom
  handles, stored as written);
- the rider (Board.as on a character, the modelled rider and board under it) at the top gate;
- the slalom gates (Gate.as on each, the course's red and blue prefabs in turn under them) every
  gate_spacing metres down the course (RULES), swinging side to side of the line, standing on the
  snow (terrain.py's mountain), none on a shortcut's bend; and the finish (Finish.as,
  Prefabs/FinishLine) at the line's end;
- the gems (Gem.as on each, the Gem model under it): an arc over each kicker's flight and the
  gap's, so the air is worth taking; between the gates without a kicker, a row of GEM_ROW on the
  course line, or every third gap gem_offset metres out on the side of the gate before it (a
  wider line than the gates ask for); and a row down a shortcut;
- the medal ghosts (Ghost.as, a path_follow on the course line, the rider model under it in a
  medal's see-through colour, ghosts.py's materials): one per medal, each riding to the finish at
  its medal's time;
- the player's ghost (PlayerGhost.as, the rider model under it in ghosts.py's GhostPlayer): the
  course's best run, saved, ridden again beside the player; hidden until there is one;
- the kickers (Kicker.as, which sets the launch off the lip, on Models/Props/KickerModel with its
  collision) on the course line between gates;
- a gap, if the course has one (terrain.py's crevasse): a kicker whose lip stands at its edge, and
  the Gap (Gap.as) judging the landing past it; no gate stands near it;
- an avalanche, if the course has one (RULES): Avalanche.as on a path_follow on the course line,
  with the Avalanche particle effect and the Rumble sound (particles.py, sounds.py) under it;
- the chase camera (FollowCamera.as).
"""
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import Doc, mcp, yaw, num, vec, component_removed, component_added, component_modified, settings, pitch, assets
from look import look

name = sys.argv[1] if len(sys.argv) > 1 else "Meadow"
# course.py <course> autopilot: the rider steers itself (playtests and measurements).
AUTOPILOT = "autopilot" in sys.argv[2:]
# course.py <course> autopilot spin=<stick>: the autopilot also spins in the air (a trick's playtest).
AUTOPILOT_SPIN = next((float(a.split("=", 1)[1]) for a in sys.argv[2:] if a.startswith("spin=")), 0.0)
# ... grab: it holds a grab in the air as well.
AUTOPILOT_GRAB = "grab" in sys.argv[2:]
info = json.load(open(os.path.join(HERE, "generated", name, name + ".json")))
ASSETS = assets()


def asset(asset_type, asset_name, group=None):
    for a in ASSETS:
        if a["type"] == asset_type and a["name"] == asset_name and (group is None or a.get("group") == group):
            return a["guid"]
    raise SystemExit("no %s %s%s" % (asset_type, asset_name, " in " + group if group else ""))


def primitive(label):
    """A primitive mesh (Meshes/<label>), made the first time."""
    for a in ASSETS:
        if a["type"] == "StaticMeshAsset" and a["name"] == label:
            return a["guid"]
    guid = mcp("asset_create", {"creator": label, "name": label})["guid"]
    ASSETS.append({"type": "StaticMeshAsset", "name": label, "guid": guid})
    return guid


def model_materials(model):
    """An imported model's materials in its mesh's slot order, as its prefab's mesh lists them."""
    import xml.etree.ElementTree as ET
    prefab = next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                  and a.get("group") == "Models/Props/%sModel" % model)
    root = ET.fromstring(mcp("prefab_read", {"guid": prefab})["xml"])
    slots = root.find(".//array[@name='materials']")
    return [e.text for e in slots] if slots is not None else []


TERRAIN = asset("TerrainAsset", name + "Terrain")
HEIGHTFIELD = asset("HeightfieldAsset", name + "Height")
PINE = asset("StaticMeshAsset", "PineModel.2")
ROCK = asset("StaticMeshAsset", "RockModel.2")
PINE_MATERIALS = model_materials("Pine")
ROCK_MATERIALS = model_materials("Rock")
BOARD = asset("ScriptClassAsset", "Board")
GATE = asset("ScriptClassAsset", "Gate")
FINISH = asset("ScriptClassAsset", "Finish")
GHOST = asset("ScriptClassAsset", "Ghost")
PLAYER_GHOST = asset("ScriptClassAsset", "PlayerGhost")
KICKER = asset("ScriptClassAsset", "Kicker")
GAP = asset("ScriptClassAsset", "Gap") if "gap" in info else None
GEM = asset("ScriptClassAsset", "Gem")
GEM_MODEL = next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                 and a.get("group", "") == "Models/Props/GemModel")
CAMERA = asset("ScriptClassAsset", "FollowCamera")
RIDER_MODEL = next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                   and a.get("group") == "Models/Rider/RiderModel")
RIDER_GRAPH = asset("AnimationGraphAsset", "RiderGraph")


GATE_FIRST = 40.0     # the first gate's distance from the top
FINISH_BEFORE = 6.0   # the finish's distance before the line's end (m)
SHORTCUT_CLEAR = 25.0 # no gate within this far (along z) of a shortcut's ends, nor between them (m)
GAP_CLEAR = (30.0, 15.0) # no gate this far before a gap's lip, nor this far past its end (along z, m)
# Each course's rules:
# - gate_half, gate_swing, gate_spacing, gate_prefabs: half the gap between a gate's poles, how far
#   each gate stands off the line side to side, the metres down the line between gates, and the
#   red and blue prefabs at that width (gates.py);
# - gem_offset: how far a row of gems stands off the line (past the groomed course, short of trees);
# - kickers: the gaps (after gate i) a kicker stands midway in, on the line;
# - pines: the forest's density (instances a square metre where the forest floor is painted);
# - air_speed, gap_speed: the launch speed (m/s) the arcs of gems over the kickers and the gap
#   follow: a rider riding the line untucked (the autopilot leaves Meadow's kicker at 16.8 m/s and
#   Ridge's gap at 20), a little under, so a slower rider still meets them early in the flight;
# - medals: gold, silver, bronze (s, penalties included). Snowline.as judges a run by them and the
#   medal ghosts ride at their pace;
# - avalanche (optional): where down the line the rider sets it off (release, m; Avalanche.as). Ridge's
#   breaks loose 47 m before the crevasse's lip, so the chase runs over the gap to the finish.
# Meadow's medals: the autopilot, riding the line untucked and missing two or three gates,
# finishes in about 36 s (31 s riding): a bronze. Silver asks for the gates; gold for the gates
# and a tucked line.
RULES = {
    "Meadow": dict(gate_half=4.0, gate_swing=3.5, gate_spacing=45.0, gate_prefabs=("GateRed", "GateBlue"),
                   gem_offset=11.0, kickers=(3,), medals=(30.0, 34.0, 40.0), pines=0.025, air_speed=16.0),
    # Lines and shortcuts: narrower gates closer together on the tighter bends; gems just past the
    # groomed snow, the trees close beyond them; and a row of gems down the shortcut.
    "Forest": dict(gate_half=3.0, gate_swing=2.5, gate_spacing=38.0, gate_prefabs=("GateRedNarrow", "GateBlueNarrow"),
                   gem_offset=5.8, kickers=(), medals=(40.0, 45.0, 52.0), pines=0.06),
    # Air: wide gates, a run of three kickers in the first gaps, and the crevasse (terrain.py's
    # gap) with its own kicker at the lip; few trees.
    "Ridge": dict(gate_half=4.0, gate_swing=3.5, gate_spacing=45.0, gate_prefabs=("GateRed", "GateBlue"),
                  gem_offset=10.0, kickers=(0, 1, 2), medals=(29.0, 33.0, 40.0), pines=0.02,
                  avalanche=dict(release=270.0), air_speed=16.0, gap_speed=19.0),
}
COURSE = RULES[name]
# The kicker's shape (blender/props.py, which models it from the same numbers): its curve, buried
# KICKER_BURY at its start, rises to the lip KICKER_HEIGHT over KICKER_CURVE. Kicker.as needs the
# lip: how far up the ramp from where it leaves the snow, how high, at what angle.
KICKER_CURVE, KICKER_HEIGHT, KICKER_BURY, KICKER_WIDTH = 5.4, 1.4, 0.12, 5.0
KICKER_RUN = KICKER_CURVE - KICKER_CURVE * math.sqrt(KICKER_BURY / (KICKER_HEIGHT + KICKER_BURY))
KICKER_LIP_ANGLE = math.degrees(math.atan(2.0 * (KICKER_HEIGHT + KICKER_BURY) / KICKER_CURVE))
KICKER_FOOT = 3.0   # the run over which the kicker is tilted to the slope at its foot (m)
KICKER_SINK = 0.003 # how far its foot sits in the snow: a hair, as its ramp starts level with it.
                    # Sunk deeper, the ramp came out of the snow already steep: a kink that threw
                    # the rider off before the lip
GEM_ROW = 3           # gems in a row
GEM_GAP = 4.0         # metres down the course between a row's gems
SHORTCUT_GEMS = 5     # gems down a shortcut's middle
GEM_HEIGHT = 1.0      # a gem's centre above the snow (m): about the rider's centre
GEM_AIR = (3.0, 6.0, 9.0)            # the arc over a kicker: metres past its lip, level
GEM_GAP_AIR = (4.0, 8.0, 12.0, 16.0) # the arc over a gap's crevasse
RIDER_CENTRE = 0.9    # the rider's centre above its board (m): the flight the gems follow


def along_course(points, distance):
    """The course line `distance` metres from its top: the point and the heading (radians, 0 runs
    toward +Z), along the polyline."""
    for a, b in zip(points, points[1:]):
        step = math.dist(a, b)
        if distance <= step or b is points[-1]:
            t = min(1.0, distance / step) if step > 0 else 0.0
            p = [a[i] + (b[i] - a[i]) * t for i in range(3)]
            return p, math.atan2(b[0] - a[0], b[2] - a[2])
        distance -= step
    return list(points[-1]), 0.0


def gate_distances(points, length):
    """Where the gates stand: every gate_spacing metres down the line from GATE_FIRST, short of the
    finish, none on a shortcut's bend nor within SHORTCUT_CLEAR of its ends (a rider taking the
    shortcut rides past those, so it would miss them)."""
    out = []
    distance = GATE_FIRST
    z0, z1 = info.get("shortcut_range", (1.0e9, 1.0e9))
    gap = info.get("gap")
    g0, g1 = (gap["lip"][2] - GAP_CLEAR[0], gap["lip"][2] + gap["length"] + GAP_CLEAR[1]) if gap else (1.0e9, 1.0e9)
    while distance < length - FINISH_BEFORE - 20.0:
        p, _ = along_course(points, distance)
        if not (z0 - SHORTCUT_CLEAR <= p[2] <= z1 + SHORTCUT_CLEAR) and not (g0 <= p[2] <= g1):
            out.append(distance)
        distance += COURSE["gate_spacing"]
    return out


def gates(d, points, length):
    """The gates and the finish, each an entity carrying its script with its prefab under it; then
    the gems and kickers between the gates."""
    import terrain
    mountain = terrain.Mountain(terrain.COURSES[name])
    prefabs = {a["name"]: a["guid"] for a in ASSETS if a["type"] == "PrefabDocument" and a.get("group") == "Prefabs"}
    placed = gate_distances(points, length)
    swing = COURSE["gate_swing"]
    for index, distance in enumerate(placed):
        p, heading = along_course(points, distance)
        side = 1 if index % 2 == 0 else -1
        x = p[0] + math.cos(heading) * swing * side  # +X across a heading of 0
        z = p[2] - math.sin(heading) * swing * side
        e = d.entity("Gate%d" % index, (x, mountain.height(x, z), z), yaw(math.degrees(heading)))
        d.script(e, (GATE, {"index": index, "heading": heading, "halfWidth": COURSE["gate_half"]}))
        d.instance(prefabs[COURSE["gate_prefabs"][index % 2]], parent=e)
    gems(d, points, mountain, placed)
    kickers(d, points, mountain, placed)
    gap(d, points, mountain)
    p, heading = along_course(points, length - FINISH_BEFORE)
    e = d.entity("Finish", (p[0], mountain.height(p[0], p[2]), p[2]), yaw(math.degrees(heading)))
    gold, silver, bronze = COURSE["medals"]
    d.script(e, (FINISH, {"heading": heading, "gold": gold, "silver": silver, "bronze": bronze}))
    d.instance(prefabs["FinishLine"], parent=e)
    return len(placed)


def gems(d, points, mountain, placed):
    """A row of gems in each gap between neighbouring gates (one spacing apart: not across a
    shortcut's bend), out on the side of the gate before it; and a row down a shortcut's middle,
    the reward for taking it."""
    count = 0
    offset = COURSE["gem_offset"]

    def gem(x, z):
        nonlocal count
        e = d.entity("Gem%d" % count, (x, mountain.height(x, z) + GEM_HEIGHT, z))
        d.script(e, (GEM, {}))
        d.instance(GEM_MODEL, parent=e)
        count += 1

    def gem_at(x, y, z):
        nonlocal count
        e = d.entity("Gem%d" % count, (x, y, z))
        d.script(e, (GEM, {}))
        d.instance(GEM_MODEL, parent=e)
        count += 1

    for gap in range(len(placed) - 1):
        if placed[gap + 1] - placed[gap] > COURSE["gate_spacing"] + 1.0:
            continue
        middle = (placed[gap] + placed[gap + 1]) / 2.0
        if gap in COURSE["kickers"]:
            # Over the kicker: the arc a rider flies off it.
            for x, y, z in air_arc(points, mountain, middle, COURSE["air_speed"], GEM_AIR):
                gem_at(x, y, z)
            continue
        # On the line, or every third gap out to the side of the gate before it.
        side = (1 if gap % 2 == 0 else -1) if gap % 3 == 2 else 0
        for k in range(GEM_ROW):
            p, heading = along_course(points, middle + (k - (GEM_ROW - 1) / 2) * GEM_GAP)
            gem(p[0] + math.cos(heading) * offset * side, p[2] - math.sin(heading) * offset * side)
    if info.get("gap"):
        lip = info["gap"]["lip"]
        at = distance_to(points, (lip[0], lip[2]))
        for x, y, z in air_arc(points, mountain, at - KICKER_RUN, COURSE["gap_speed"], GEM_GAP_AIR):
            gem_at(x, y, z)
    cut = info.get("shortcut")
    if cut:
        a, b = cut[0], cut[-1]
        for k in range(SHORTCUT_GEMS):
            t = 0.3 + 0.4 * k / (SHORTCUT_GEMS - 1)
            gem(a[0] + (b[0] - a[0]) * t, a[2] + (b[2] - a[2]) * t)
    print("gems", count)


def kicker_tilt(points, mountain, distance):
    """The slope (degrees, falling) a kicker `distance` metres down the line is tilted to."""
    p, _ = along_course(points, distance)
    q, _ = along_course(points, distance + KICKER_FOOT)
    return math.degrees(math.atan2(mountain.height(p[0], p[2]) - mountain.height(q[0], q[2]), KICKER_FOOT))


def air_arc(points, mountain, distance, speed, past):
    """Points along the flight off a kicker whose ramp leaves the snow `distance` metres down the
    line, launched at `speed` (Kicker.as: off the lip at its angle above level, the lip's angle
    less the slope it stands on), `past` metres past the lip, level: the rider's centre there."""
    tilt = kicker_tilt(points, mountain, distance)
    lip_distance = distance + KICKER_RUN * math.cos(math.radians(tilt))
    lip, heading = along_course(points, lip_distance)
    lip_y = mountain.height(lip[0], lip[2]) + KICKER_HEIGHT + RIDER_CENTRE
    angle = math.radians(KICKER_LIP_ANGLE - tilt)
    out = []
    for x in past:
        y = lip_y + x * math.tan(angle) - 9.81 * x * x / (2.0 * speed * speed * math.cos(angle) ** 2)
        out.append((lip[0] + math.sin(heading) * x, y, lip[2] + math.cos(heading) * x))
    return out


def qmul(a, b):
    """Quaternions (xyzw): `a` after `b`."""
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


def kickers(d, points, mountain, placed):
    """Each kicker on the course line midway between two gates, facing down it, its base tilted to
    the slope at its foot (the drop over KICKER_FOOT), so its ramp starts along the snow."""
    prefab = next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                  and a.get("group", "") == "Models/Props/KickerModel")
    for i, gap in enumerate(COURSE["kickers"]):
        kicker(d, points, mountain, prefab, "Kicker%d" % i, (placed[gap] + placed[gap + 1]) / 2.0)


def kicker(d, points, mountain, prefab, label, distance):
    """One kicker `distance` metres down the course line (where its ramp leaves the snow)."""
    p, heading = along_course(points, distance)
    slope = kicker_tilt(points, mountain, distance)
    e = d.entity(label, (p[0], mountain.height(p[0], p[2]) - KICKER_SINK, p[2]),
                 qmul(yaw(math.degrees(heading)), pitch(slope)))
    d.script(e, (KICKER, {"run": KICKER_RUN, "lipHeight": KICKER_HEIGHT, "lipAngle": KICKER_LIP_ANGLE,
                          "width": KICKER_WIDTH}))
    d.instance(prefab, parent=e)


def distance_to(points, target):
    """How far down the course line its closest point to `target` (x, z) is (m)."""
    best, best_d, run = 1.0e18, 0.0, 0.0
    for a, b in zip(points, points[1:]):
        step = math.dist(a, b)
        ax, az, bx, bz = a[0], a[2], b[0], b[2]
        t = ((target[0] - ax) * (bx - ax) + (target[1] - az) * (bz - az)) / max(1e-9, (bx - ax) ** 2 + (bz - az) ** 2)
        t = max(0.0, min(1.0, t))
        e = math.hypot(target[0] - (ax + (bx - ax) * t), target[1] - (az + (bz - az) * t))
        if e < best:
            best, best_d = e, run + step * t
        run += step
    return best_d


def gap(d, points, mountain):
    """The crevasse (terrain.py's gap): a kicker whose lip stands at its edge, and the Gap (Gap.as)
    that judges the landing past it: short of the ramp up is a crash, beyond it a cleared gap."""
    info_gap = info.get("gap")
    if not info_gap:
        return
    prefab = next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                  and a.get("group", "") == "Models/Props/KickerModel")
    lip = info_gap["lip"]
    at = distance_to(points, (lip[0], lip[2]))
    # The kicker's lip KICKER_RUN up its ramp (its ramp follows the slope) stands at the edge.
    kicker(d, points, mountain, prefab, "GapKicker", at - KICKER_RUN)
    _, heading = along_course(points, at)
    e = d.entity("Gap", tuple(lip), yaw(math.degrees(heading)))
    d.script(e, (GAP, {"heading": heading, "short": info_gap["short"], "reach": info_gap["reach"]}))


def aim_bone(name, share):
    """One AimIkBone, as a list element's fields (written flat in the array)."""
    return '<string name="bone">%s</string><f32 name="share">%r</f32>' % (name, share)


def rider_parts():
    """The rider model prefab's clip animator (its entity and skeleton) and skinned mesh (its
    entity, mesh and material slots)."""
    import xml.etree.ElementTree as ET
    root = ET.fromstring(mcp("prefab_read", {"guid": RIDER_MODEL})["xml"])
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
            parts["mesh"] = data.find("string[@name='mesh']").text
            parts["slots"] = len(list(data.find("array[@name='materials']")))
    return parts


def rider_ops(material=None):
    """The rider model's import plays one clip; the board drives an animation graph (graph.py)
    instead. Its prefab's root loses the clip animator, and the skinned mesh gains the graph (an
    animator with no mesh entities of its own feeds its own entity's mesh). With a `material`, the
    mesh takes it in every slot (a ghost)."""
    parts = rider_parts()
    ops = [component_removed(parts["animator"], "skeletal_animation"),
           component_added(parts["meshOwner"], "animation_graph", skeleton=parts["skeleton"], graph=RIDER_GRAPH)]
    if material:
        ops.append(component_modified(parts["meshOwner"], "mesh", mesh=parts["mesh"],
                                      materials=["<string>%s</string>" % material] * parts["slots"]))
    return ops


# The medal ghosts, in Ghost.as's order (0 gold, 1 silver, 2 bronze), each with its material.
GHOSTS = (("GhostGold", 0), ("GhostSilver", 1), ("GhostBronze", 2))


def ghosts(d, course, length):
    """A ghost per medal: on the course line from its top (path_follow, stopped until Ghost.as sets
    its pace), the rider model under it in the medal's material. The follower turns its -Z down
    the line; the model faces +Z, so it is turned about."""
    for label, medal in GHOSTS:
        e = d.entity(label, tuple(info["course"][0]))
        d.add(e, "path_follow", spline=course, speed=0.0, loop=False, playing=True, alignToTangent=True)
        d.script(e, (GHOST, {"medal": medal, "finishDistance": length - FINISH_BEFORE}))
        d.instance(RIDER_MODEL, rot=yaw(180), parent=e, ops=rider_ops(asset("MaterialAsset", label)))

def avalanche(d, course):
    """The avalanche, if the course has one: parked at the line's top, still (Avalanche.as sets it
    off), its front of billowing snow and its rumble under it. The follower turns its -Z down the
    line, so the front's width (the effect's X) lies across it."""
    rule = COURSE.get("avalanche")
    if not rule:
        return
    e = d.entity("Avalanche", tuple(info["course"][0]))
    d.add(e, "path_follow", spline=course, speed=0.0, loop=False, playing=True, alignToTangent=True)
    d.script(e, (asset("ScriptClassAsset", "Avalanche"), {"course": ("entity", course), "release": rule["release"]}))
    front = d.entity("Front", (0, 1.0, 0), parent=e)
    d.add(front, "particle_effect", effect=asset("ParticleEffectAsset", "Avalanche"))
    rumble = d.entity("Rumble", parent=e)
    d.add(rumble, "audio.Source", clip=asset("AudioClipAsset", "Rumble"), loop=True, spatial=False, autoPlay=False,
          volume=0.0)


# The sun: low and from the side, so the slope's relief reads.
SUN_ROT = (-0.4229, 0.2418, 0.1162, 0.8653)


def spline_points(points):
    """The course line's points with Catmull-Rom handles: each a sixth of the chord between its
    neighbours (Auto's rule), in and out mirrored. An array of structs is written flat, each
    element's fields one after another, as the engine's serializer writes it."""
    items = []
    for i, p in enumerate(points):
        a = points[max(0, i - 1)]
        b = points[min(len(points) - 1, i + 1)]
        h = [(b[k] - a[k]) / 6.0 for k in range(3)]
        items.append('<object name="position">%s</object><object name="in">%s</object>'
                     '<object name="out">%s</object><u8 name="mode">0</u8>' % (
                         "".join('<f32 name="%s">%s</f32>' % (k, num(float(v))) for k, v in zip("xyz", p)),
                         "".join('<f32 name="%s">%s</f32>' % (k, num(-float(v))) for k, v in zip("xyz", h)),
                         "".join('<f32 name="%s">%s</f32>' % (k, num(float(v))) for k, v in zip("xyz", h))))
    return items


def vegetation_layer(label, mesh, materials, placement, density, scale, slope, fade, splat_layer=0,
                     threshold=0.25, shadows=False, solid=(0.0, 0.0)):
    """One procedural layer (the component's ProceduralVegetationLayer, field by field); its
    materials one per mesh slot, as the model's prefab lists them. `solid` is its trunk (radius,
    height; scaled with each instance), in TREES_GROUP; (0, 0) is scenery only."""
    return ('<string name="name">%s</string><string name="mesh">%s</string>'
            '<array name="materials" count="%d">%s</array>'
            '<object name="scaleRange"><f32 name="x">%s</f32><f32 name="y">%s</f32></object>'
            '<f32 name="maxSlopeDegrees">%s</f32>'
            '<object name="heightRange"><f32 name="x">-1000000</f32><f32 name="y">1000000</f32></object>'
            '<bool name="alignToNormal">false</bool><f32 name="fadeStart">%s</f32><f32 name="fadeEnd">%s</f32>'
            '<bool name="castShadows">%s</bool><u32 name="maxInstancesPerChunk">4096</u32><bool name="visible">true</bool>'
            '<f32 name="collisionRadius">%s</f32><f32 name="collisionHeight">%s</f32><u8 name="collisionGroup">%d</u8>'
            '<u8 name="placement">%d</u8><u32 name="splatLayer">%d</u32><f32 name="splatThreshold">%s</f32>'
            '<u32 name="maskPlane">0</u32><f32 name="density">%s</f32>' % (
                label, mesh, len(materials), "".join("<string>%s</string>" % m for m in materials), num(scale[0]), num(scale[1]), num(slope), num(fade[0]), num(fade[1]),
                num(shadows), num(solid[0]), num(solid[1]), TREES_GROUP if solid[0] > 0 else 0, placement, splat_layer,
                num(threshold), num(density)))


UNIFORM, SPLAT = 0, 1
# Collision groups: 0 everything, 1 the gates' flags (gates.py's FLAG_GROUP), 2 the trees and rocks
# (the vegetation's trunks: Board.as finds a near miss by this group).
FLAGS_GROUP, TREES_GROUP = 1, 2
PINE_TRUNK = (0.35, 6.0)  # a pine's solid core (radius, height): the trunk and its lowest boughs
ROCK_SOLID = (0.7, 1.0)   # a boulder, half sunk
BASE_LAYER = 0xFFFFFFFF  # the splat's unpainted base (the vegetation's kSplatBaseLayer)


def build():
    d = Doc(name)
    look(d)
    # The collision groups (FLAGS_GROUP, TREES_GROUP): the flags collide with nothing (a flag at its
    # hinge's limit would stop the rider dead; Gate.as swings it instead); the trees and rocks stop
    # the rider (group 0) like any solid, said explicitly.
    everything_but_flags = 0xFFFFFFFF & ~(1 << FLAGS_GROUP)
    d.settings.append(settings("physics",
                               groupNames=["<string>Default</string>", "<string>Flags</string>", "<string>Trees</string>"],
                               groupCollides=["<u32>%d</u32>" % everything_but_flags, "<u32>0</u32>",
                                              "<u32>%d</u32>" % everything_but_flags]))
    sun = d.entity("Sun", rot=SUN_ROT)
    d.add(sun, "light", type=0, intensity=4.0, castsShadows=True)

    mountain = d.entity("Mountain")
    d.add(mountain, "terrain", terrain=TERRAIN)
    d.add(mountain, "physics.RigidBody", motion=0, layer=0, shape=5, heightfield=HEIGHTFIELD)
    d.add(mountain, "terrainVegetation", proceduralLayers=[
        # Pines where terrain.py laid the forest floor (palette layer 2), sparse enough to ride
        # between; rocks thinly everywhere the slope allows, the course's own splat aside.
        vegetation_layer("Pines", PINE, PINE_MATERIALS, SPLAT, COURSE["pines"], (0.8, 1.3), 30.0, (250.0, 320.0), splat_layer=2,
                         threshold=0.5, shadows=True, solid=PINE_TRUNK),
        vegetation_layer("Rocks", ROCK, ROCK_MATERIALS, SPLAT, 0.0015, (0.6, 1.5), 40.0, (120.0, 160.0), splat_layer=BASE_LAYER,
                         threshold=0.9, solid=ROCK_SOLID),
    ])

    course = d.entity("Course")
    d.add(course, "spline", points=spline_points(info["course"]))

    top = info["course"][0]
    nxt = info["course"][1]
    heading = math.degrees(math.atan2(nxt[0] - top[0], nxt[2] - top[2]))
    # The capsule's centre 0.9 m up (half height 0.55 + radius 0.35): on the snow, not above it. A
    # rider placed higher drops onto the slope as the run starts, and the board turns the drop into
    # speed down it, which a restarted run (put back on the snow) never had.
    rider = d.entity("Rider", (top[0], top[1] + 0.9, top[2]), yaw(heading))
    # A short step down: the controller snaps the rider onto snow up to this far below, which keeps
    # it on the terrain's small dips, but at the default 0.5 m it held the rider down over a kicker's
    # lip and rode it down the back instead of into the air (as often as not, by the frame timing).
    d.add(rider, "physics.Character", radius=0.35, halfHeight=0.55, maxSlopeDegrees=60.0, stepDown=0.1)
    d.script(rider, (BOARD, {"course": ("entity", course), "autopilot": AUTOPILOT, "autopilotSpin": AUTOPILOT_SPIN,
                             "autopilotGrab": AUTOPILOT_GRAB,
                             "trackMark": ("asset", asset("PrefabDocument", "TrackMark", "Prefabs"))}))
    # The rider's head looks down the course line ahead (Board.as sets the point each frame; the
    # next gate once the course has gates): an aim on the rider, which drives the graph below it.
    # The rig's spine and head face +Z, up +Y (blender/rider.py), the aim's defaults.
    d.add(rider, "aim_ik", bones=[aim_bone("spine", 0.3), aim_bone("head", 1.0)], maxAngle=70.0, fadeSeconds=0.5)
    # The model (blender/rider.py): its origin is the snow under the board, the character's is its
    # capsule's centre, 0.9 m up.
    d.instance(RIDER_MODEL, (0, -0.9, 0), parent=rider, ops=rider_ops())
    # The board's snow (particles.py), at the board: spray off its edge, powder as it lands.
    for fx in ("Spray", "Powder"):
        e = d.entity(fx, (0, -0.85, 0), parent=rider)
        d.add(e, "particle_effect", effect=asset("ParticleEffectAsset", fx))
    # The wind in the rider's ears (sounds.py): looping, not placed, silent until Board.as sets
    # its volume by the speed.
    wind = d.entity("Wind", parent=rider)
    d.add(wind, "audio.Source", clip=asset("AudioClipAsset", "Wind"), loop=True, spatial=False, autoPlay=True,
          volume=0.0)

    print("gates", gates(d, info["course"], info["course_length"]))
    ghosts(d, course, info["course_length"])
    avalanche(d, course)
    # The player's best run: it rides where the rider rode, so it sits as the rider does, the model
    # 0.9 m below the capsule's centre it was recorded at.
    player_ghost = d.entity("PlayerGhost", (top[0], top[1] + 0.9, top[2]), yaw(heading))
    d.script(player_ghost, (PLAYER_GHOST, {}))
    d.instance(RIDER_MODEL, (0, -0.9, 0), parent=player_ghost, ops=rider_ops(asset("MaterialAsset", "GhostPlayer")))

    cam = d.entity("Camera", (top[0], top[1] + 4.0, top[2] - 8.0))
    d.add(cam, "camera", farZ=1200.0, fovYRadians=1.05)
    d.script(cam, (CAMERA, {"target": ("entity", rider), "distance": 5.5, "height": 2.0, "lookHeight": 0.9}))
    return d


scenes = [a for a in ASSETS if a["type"] == "SceneDocument" and a["name"] == name]
doc = build()
guid = doc.write(scenes[0]["guid"] if scenes else None, group="Scenes")
print(name, guid)
