#!/usr/bin/env python3
"""Block1 (the first level's town block) and Start (the title backdrop)."""
import json, os, sys
import xml.etree.ElementTree as ET
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pkgen import Doc, mcp, yaw, pitch, settings, num, assets, root_motion_entity

ASSETS = assets()
ids = {a["name"]: a["guid"] for a in ASSETS if a["type"] != "PrefabDocument"}
kit = json.load(open(os.path.join(HERE, "kit.json")))
CUBE, PLANE = ids["Cube"], ids["Plane"]
HOUSES = [kit["HouseRed"], kit["HouseBlue"], kit["HouseCream"]]
SUN_ROT = (-0.4935577, 0.15065993, 0.08726525, 0.85210747)
SUN_INTENSITY = 4.5


# The look, as the user set it on Start (2026-10-02): GTAO, bloom. FXAA (kept after TAA's jitter
# was fixed; TAA is for the next game). Auto exposure on since it starts at a scene's level
# (2026-10-06; it had dimmed and brightened over every scene's first seconds). The look lives in
# two shared profiles (PaperKid Environment, PaperKid Post) that every scene's settings name, so
# it is tuned once. Colours are sRGB, as entered anywhere (the sky's were tuned while colours were
# read raw, and are written as the values they decode from).
POST = dict(exposureEV=1.0, tonemapOperator=1, bloomEnabled=True, bloomThreshold=1.0, bloomKnee=0.6,
            bloomIntensity=0.05, aoMode=2, aoStrength=1.0, aoRadius=1.0, aoIntensity=1.0, ssrEnabled=False,
            ssrIntensity=1.0, aaMode=1, taaBlendFactor=0.97, taaVarianceGamma=1.25, fxaaSubpixel=0.75,
            autoExposure=True, autoExposureKey=0.25, autoExposureSpeed=2.0, autoExposureMinEV=-4.0,
            autoExposureMaxEV=4.0, gradingIntensity=1.0, ssgiEnabled=False, ssgiIntensity=1.0)
ENVIRONMENT = dict(ambientColor={"r": 0.349, "g": 0.381, "b": 0.437, "a": 1.0}, ambientIntensity=0.08, skyMode=0,
                   skyIntensity=1.0, skyBackgroundIntensity=1.0, skyRotation=0.0,
                   skyHorizon={"r": 0.626, "g": 0.767, "b": 0.978, "a": 1.0},
                   skyZenith={"r": 0.313, "g": 0.537, "b": 0.931, "a": 1.0},
                   skyGround={"r": 0.547, "g": 0.547, "b": 0.547, "a": 1.0}, sunIntensity=1.0, sunAngularSize=0.5,
                   turbidity=3.0, iblDiffuseIntensity=0.35, iblSpecularIntensity=1.0,
                   shadowDistance=60.0, shadowCascadeSplit=0.7, shadowFadeDistance=10.0)


def profile(creator, asset_type, name, values):
    """The shared profile asset `name`, made the first time and its fields rewritten each time
    (through its envelope, as the editor reads it), so a scene's settings only name it."""
    found = [a["guid"] for a in ASSETS if a["name"] == name and a["type"] == asset_type]
    guid = found[0] if found else mcp("asset_create", {"creator": creator, "name": name})["guid"]
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']").find("object")
    for key, value in values.items():
        field = payload.find("*[@name='%s']" % key)
        if field is None:
            raise SystemExit("%s has no field %s" % (name, key))
        if isinstance(value, dict):
            for channel, v in value.items():
                field.find("*[@name='%s']" % channel).text = num(float(v))
        else:
            field.text = num(value)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    return guid


_profiles = {}


def look(doc):
    if not _profiles:
        _profiles["environment"] = profile("Environment Profile", "EnvironmentProfileAsset",
                                           "PaperKid Environment", ENVIRONMENT)
        _profiles["postprocess"] = profile("Post Process Profile", "PostProcessProfileAsset",
                                           "PaperKid Post", POST)
    doc.settings.append(settings("environment", source=1, profile=_profiles["environment"]))
    doc.settings.append(settings("postprocess", source=1, profile=_profiles["postprocess"]))


def mesh(doc, name, guid, pos, scale, rgb, rot=(0, 0, 0, 1), parent=None):
    e = doc.entity(name, pos, rot, scale, parent=parent)
    doc.add(e, "mesh", mesh=guid, color={"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": 1.0})
    return e


def static(doc, name, pos, half, shape=0):
    e = doc.entity(name, pos)
    doc.add(e, "physics.RigidBody", motion=0, layer=0, shape=shape,
            halfExtents={"x": half[0], "y": half[1], "z": half[2]})
    return e


def world(doc, size):
    look(doc)
    sun = doc.entity("Sun", rot=SUN_ROT)
    doc.add(sun, "light", type=0, intensity=SUN_INTENSITY, castsShadows=True)
    mesh(doc, "Ground", PLANE, (0, 0, 0), (size, 1, size), (0.36, 0.5, 0.3))
    static(doc, "GroundCollider", (0, 0, 0), (0, 0, 0), shape=4)


BIKE_ID = "b1ce0000-0000-4000-8000-00000000b1ce"
CYL, SPHERE = ids["Cylinder"], ids["Sphere"]
ROLL_Z = (0.0, 0.0, 0.7071068, 0.7071068)


# The kid on his bike (Tools/blender/kid_bike.py, imported as Models/KidBike): its prefab's root
# is the model, its origin the ground under the bike.
KID_BIKE = next(a["guid"] for a in ASSETS
                if a["type"] == "PrefabDocument" and a.get("group", "").startswith("Models/KidBike"))


def bike(d, pos, facing):
    """The player: a character capsule (its centre is the entity; the feet are 0.9 below) with the
    Bike behavior, and the kid on his bike, standing on the ground under it."""
    b = d.entity("Bike", pos, yaw(facing), eid=BIKE_ID)
    d.add(b, "physics.Character", radius=0.4, halfHeight=0.5)
    d.script(b, (ids["Bike"], {}))
    d.instance(KID_BIKE, (0, -0.9, 0), parent=b)


def spaced(limit, step=10):
    """Multiples of `step` within +-limit, ascending."""
    k = int(limit // step)
    return [i * step for i in range(-k, k + 1)]


def lane_point(lane, s):
    """The point `s` metres along a square lane `lane` out from the middle, starting at the north
    side's middle and running clockwise seen from above (north is -Z, east +X)."""
    side = 2 * lane
    s = (s + lane) % (4 * side)
    edge, t = int(s // side), s % side - lane
    return [(t, 0, -lane), (lane, 0, t), (-t, 0, lane), (-lane, 0, -t)][edge]


def town(name, R, subscribers, inner_cars, outer_cars, walkers, level, nav):
    """A town block round a square ring road R from the middle (a multiple of 8): houses inside and
    outside the ring facing it, `subscribers` (indices into the houses in the order placed) with a
    delivery zone each, cars on both lanes, walkers on the verges, street junk, a wall all round,
    the bike, the chase camera and the minimap. Every number derives from R; at R 24 it is the
    first block's layout."""
    import math
    d = Doc(name)
    world(d, 2 * (R + 24))
    span = 2.0 * (R + 18)  # the walls' square, which the minimap frames
    # The ring road: a tile is 8 x 8, its road along local Z.
    for x in range(-R, R + 1, 8):
        d.instance(kit["Road"], (x, 0, -R), yaw(90))
        d.instance(kit["Road"], (x, 0, R), yaw(90))
    for z in range(-(R - 8), R - 7, 8):
        d.instance(kit["Road"], (-R, 0, z))
        d.instance(kit["Road"], (R, 0, z))
    # Kerbs along the straight runs, both edges, not across the corners.
    for t in range(-(R - 8), R - 7, 8):
        for edge in (R - 4.2, R + 4.2):
            d.instance(kit["Kerb"], (t, 0, -edge), yaw(90))
            d.instance(kit["Kerb"], (t, 0, edge), yaw(90))
            d.instance(kit["Kerb"], (-edge, 0, t))
            d.instance(kit["Kerb"], (edge, 0, t))
    # Houses face the road: inside the ring, rows north and south, then east and west between
    # them; outside it, a row a side.
    n = 0
    placed = []

    def house(pos, facing):
        nonlocal n
        d.instance(HOUSES[n % 3], pos, yaw(facing))
        placed.append((pos, facing))
        n += 1

    inner = R - 11
    for x in spaced(R - 14):
        house((x, 0, -inner), 180)
        house((x, 0, inner), 0)
    for z in spaced(R - 21):
        house((inner, 0, z), 90)
        house((-inner, 0, z), -90)
    outer = R + 11
    for t in spaced(R - 4):
        house((t, 0, -outer), 0)
        house((t, 0, outer), 180)
        house((outer, 0, t), -90)
        house((-outer, 0, t), 90)
    # The subscribers: a delivery zone on the porch side of each.
    for index in subscribers:
        (hx, hy, hz), facing = placed[index]
        fx, fz = math.sin(math.radians(facing)), math.cos(math.radians(facing))
        d.instance(kit["DeliveryZone"], (hx + fx * 4.6, 0, hz + fz * 4.6), yaw(facing))
    bike(d, (-R, 0.95, R - 8), 180)
    # The navigation zone over the whole block (half extents), baked by navigation_bake.
    zone = d.entity("NavZone", (0, 0, 0))
    d.add(zone, "navigation.Zone", extents={"x": R + 20.0, "y": 6.0, "z": R + 20.0}, zone=ids[nav])
    # Traffic, evenly spaced: the inner lane clockwise from the north side's middle, the outer one
    # anticlockwise from the east side's middle.
    for i in range(inner_cars):
        d.instance(kit["Car"], lane_point(R - 2, i * 8 * (R - 2) / inner_cars))
    for i in range(outer_cars):
        d.instance(kit["CarOuter"], lane_point(R + 2, 2 * (R + 2) * (1 + 4 * i / outer_cars)))
    # Walkers on the verges, alternately inside and outside the ring, spread round it.
    for i in range(walkers):
        verge = R - 6 if i % 2 == 0 else R + 6
        d.instance(kit["Pedestrian"], lane_point(verge, (i + 0.5) * 8 * verge / walkers))
    d.level_script(ids["Level"], ring=float(R), crashPenalty=5.0, **level)
    # Street junk on the verges (the obstacles that do not move).
    for pos in ((-6, 0, -(R - 5.4)), (6, 0, R - 5.4), (R - 5.4, 0, -6), (-(R - 5.4), 0, 6), (-14, 0, R + 5.6),
                (14, 0, -(R + 5.6))):
        d.instance(kit["Bin"], pos)
    for c in ((R - 4.6, R - 4.6), (-(R - 4.6), -(R - 4.6)), (R + 5.4, -(R + 5.4)), (-(R + 5.4), R + 5.4)):
        d.instance(kit["Hydrant"], (c[0], 0, c[1]))
    for x in (-2, 0, 2):
        d.instance(kit["TrafficCone"], (x, 0, R + 1.5))
    # The boundary: a low wall all round.
    w = span / 2
    for wall, pos, scale in (("WallN", (0, 0.6, -w), (span, 1.2, 0.5)), ("WallS", (0, 0.6, w), (span, 1.2, 0.5)),
                             ("WallE", (w, 0.6, 0), (0.5, 1.2, span)), ("WallW", (-w, 0.6, 0), (0.5, 1.2, span))):
        mesh(d, wall, CUBE, pos, scale, (0.46, 0.38, 0.3))
        static(d, wall + "Collider", pos, (scale[0] / 2, scale[1] / 2, scale[2] / 2))
    # The chase camera, behind the bike.
    cam = d.entity("Camera", (-R, 4.4, R), pitch(-12))
    d.add(cam, "camera", farZ=400.0)
    d.script(cam, (ids["FollowCamera"], {"target": ("entity", BIKE_ID)}))
    # The minimap: straight down over the middle, framing the walls, into the Minimap texture at
    # half the frame rate. Map up is -Z, map right is +X; MapMarkers places the HUD's markers by
    # the same span.
    mini = d.entity("MinimapCamera", (0, 80, 0), pitch(-90))
    d.add(mini, "camera", primary=False, projection=1, orthoHeight=span, nearZ=1.0, farZ=120.0,
          target=ids["Minimap"], targetInterval=2,
          clearColor={"r": 0.16, "g": 0.2, "b": 0.16, "a": 1.0})
    d.script(mini, (ids["MapMarkers"], {"bike": ("entity", BIKE_ID), "span": span}))
    return d


# The clock is about two laps of the ring at the bike's top speed (11 m/s: a lap is 17 s at R 24,
# 23 s at R 32, 29 s at R 40) with room for the corners and a crash or two; the first limits
# (120 to 165 s) left whole minutes over (user, 2026-10-03: "Time should run out faster").
# The run, on a ramp: bigger rings, more subscribers, a higher quota, busier and faster traffic,
# less time for the distance. Subscriber indices are into the houses in the order town() places
# them (inner north/south pairs, inner east/west pairs, then outer north/south/east/west quads).
BLOCKS = [
    ("Block1", 24, (3, 6, 10, 14, 19, 21), 2, 2, 8,
     dict(timeLimit=55.0, quota=4, papers=8, trafficSpeed=7.5, pedestrianSpeed=1.4), "Block1Nav"),
    ("Block2", 24, (0, 5, 7, 12, 17, 26), 3, 3, 10,
     dict(timeLimit=50.0, quota=5, papers=9, trafficSpeed=8.5, pedestrianSpeed=1.6), "Block2Nav"),
    ("Block3", 32, (1, 4, 8, 11, 14, 21, 27), 3, 3, 12,
     dict(timeLimit=65.0, quota=5, papers=9, trafficSpeed=9.0, pedestrianSpeed=1.7), "Block3Nav"),
    ("Block4", 32, (0, 3, 6, 9, 16, 23, 30), 4, 4, 14,
     dict(timeLimit=60.0, quota=6, papers=9, trafficSpeed=10.0, pedestrianSpeed=1.8), "Block4Nav"),
    ("Block5", 40, (2, 7, 11, 14, 19, 26, 33, 40), 4, 4, 16,
     dict(timeLimit=75.0, quota=7, papers=10, trafficSpeed=11.0, pedestrianSpeed=2.0), "Block5Nav"),
]


def town_model(name):
    """A Blender model's prefab (Models/Town/<name>Model)."""
    return next(a["guid"] for a in ASSETS if a["type"] == "PrefabDocument"
                and a.get("group", "") == "Models/Town/%sModel" % name)


def town_clip(name, clip):
    """A Blender model's clip by name (the dog, the cat and the pedestrian each have a Walk)."""
    return next(a["guid"] for a in ASSETS if a["type"] == "AnimationClipAsset"
                and a.get("group", "") == "Models/Town/%sModel" % name and a["name"] == clip)


def start():
    """The title backdrop: a street with life on it behind the menu. Cars cross both lanes, people
    the near pavement (Stroller.as), and a dog and a cat potter about the lawn either side of the
    menu (Pet.as)."""
    d = Doc("Start")
    world(d, 80)
    for x in range(-24, 25, 8):
        d.instance(kit["Road"], (x, 0, 4), yaw(90))
    for i, x in enumerate((-20, -10, 0, 10, 20)):
        d.instance(HOUSES[i % 3], (x, 0, -4), yaw(0))
    d.instance(kit["Bin"], (4, 0, 0.6))
    d.instance(kit["Hydrant"], (-5, 0, 0.6))
    # The near pavement, kerbed off from the road, for the walkers.
    for x in range(-24, 25, 8):
        d.instance(kit["Kerb"], (x, 0, 8.2), yaw(90))
    mesh(d, "Pavement", CUBE, (0, 0.03, 9.7), (64, 0.06, 2.8), (0.62, 0.61, 0.58))

    def stroller(name, model, z, way, speed, pause, walk=None, reach=32.0):
        e = d.entity(name, (0, 0, z))
        props = {"xFrom": -reach * way, "xTo": reach * way, "speed": speed, "pause": pause}
        if walk:
            props["walkClip"] = ("asset", town_clip(model, "Walk"))
        d.script(e, (ids["Stroller"], props))
        d.instance(town_model(model), parent=e)

    # Traffic keeps to the right: toward +X in the near lane, back in the far one.
    stroller("CarNear", "Car", 6.0, 1, 7.0, 5.0)
    stroller("CarNear2", "CarOuter", 6.0, 1, 5.5, 9.0)
    stroller("CarFar", "Car", 2.0, -1, 6.5, 6.0)
    # Walkers just past the edges of the view, so they are seldom long out of it.
    stroller("WalkerLeft", "Pedestrian", 9.2, -1, 1.3, 3.0, walk=True, reach=17.0)
    stroller("WalkerRight", "Pedestrian", 10.3, 1, 1.5, 5.0, walk=True, reach=17.0)

    def pet(name, model, lawn, speed, metres, own):
        e = d.entity(name, ((lawn[0] + lawn[1]) / 2, 0, (lawn[2] + lawn[3]) / 2))
        clips = {slot: ("asset", town_clip(model, clip)) for slot, clip in (
            ("walkClip", "Walk"), ("idleClip", "Idle"), ("sitClip", "Sit"), ("lieClip", "LieDown"), ("ownClip", own))}
        d.script(e, (ids["Pet"], dict(xMin=lawn[0], xMax=lawn[1], zMin=lawn[2], zMax=lawn[3], speed=speed,
                                      walkMetres=metres, **clips)))
        # The Walk clip carries the pet (its root motion): the model's animator moves the pet's
        # entity, which Pet.as only steers.
        d.instance(town_model(model), parent=e, ops=[root_motion_entity(town_model(model), e)])

    pet("Dog", "Dog", (-7.5, -4.0, 12.5, 15.0), 0.8, 0.55, "Sniff")
    pet("Cat", "Cat", (4.0, 7.0, 13.0, 15.0), 0.45, 0.32, "Groom")
    cam = d.entity("Camera", (0, 5, 22), pitch(-12))
    d.add(cam, "camera", farZ=300.0)
    return d


only = sys.argv[1:]  # block.py [Name...]: just those scenes
for spec in BLOCKS:
    if not only or spec[0] in only:
        doc = town(*spec)
        print(doc.name, doc.write(ids.get(doc.name), group="Scenes"))
if not only or "Start" in only:
    doc = start()
    print(doc.name, doc.write(ids[doc.name]))
