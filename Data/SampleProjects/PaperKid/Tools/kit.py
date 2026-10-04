#!/usr/bin/env python3
"""The blockout kit: one prefab per piece, primitives coloured per mesh. Colliders sit on their own
unscaled child entity, so a box's half extents are what they say."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import Doc, mcp, NIL, yaw, assets

# Every asset by name (scripts and meshes the prefabs use), and the prefabs apart: a prefab may
# share its name with a script (Pedestrian), and only a prefab is overwritten here.
ids, prefabs = {}, {}
for a in assets():
    (prefabs if a["type"] == "PrefabDocument" else ids)[a["name"]] = a["guid"]
CUBE, PLANE, CYL, SPHERE, CONE = (ids[n] for n in ("Cube", "Plane", "Cylinder", "Sphere", "Cone"))
ROLL_Z = (0.0, 0.0, 0.7071068, 0.7071068)  # a cylinder on its side, axle along X


def part(doc, root, name, mesh, pos, scale, rgb, rot=(0, 0, 0, 1)):
    e = doc.entity(name, pos, rot, scale, parent=root)
    doc.add(e, "mesh", mesh=mesh, color={"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": 1.0})
    return e


def glow_part(doc, root, name, mesh, pos, scale, rgb, rot=(0, 0, 0, 1)):
    """A part in the glowing unlit AimGuide material (anim.py), tinted by its colour."""
    e = doc.entity(name, pos, rot, scale, parent=root)
    doc.add(e, "mesh", mesh=mesh, color={"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": 1.0},
            materials=["<string>%s</string>" % ids["AimGuide"]])
    return e


def static_box(doc, root, center, half):
    e = doc.entity("Collider", center, parent=root)
    doc.add(e, "physics.RigidBody", motion=0, layer=0, shape=0,
            halfExtents={"x": half[0], "y": half[1], "z": half[2]})
    return e


def house(name, wall, roof):
    d = Doc(name)
    r = d.entity(name)
    part(d, r, "Body", CUBE, (0, 2, 0), (6, 4, 6), wall)
    part(d, r, "Roof", CUBE, (0, 4.25, 0), (6.6, 0.5, 6.6), roof)
    part(d, r, "Door", CUBE, (0, 1.1, 3.03), (1.2, 2.2, 0.1), (0.36, 0.22, 0.14))
    for x in (-1.9, 1.9):
        part(d, r, "Window", CUBE, (x, 2.5, 3.03), (1.2, 1.0, 0.1), (0.62, 0.78, 0.9))
    part(d, r, "Porch", CUBE, (0, 0.1, 3.8), (3.0, 0.2, 1.6), (0.75, 0.73, 0.7))
    static_box(d, r, (0, 2, 0), (3, 2, 3))
    return d


def road():
    d = Doc("Road")
    r = d.entity("Road")
    part(d, r, "Asphalt", CUBE, (0, 0.025, 0), (8, 0.05, 8), (0.22, 0.23, 0.25))
    for z in (-2.5, 2.5):
        part(d, r, "Dash", CUBE, (0, 0.055, z), (0.25, 0.02, 1.6), (0.92, 0.9, 0.82))
    return d


def kerb():
    d = Doc("Kerb")
    r = d.entity("Kerb")
    part(d, r, "Stone", CUBE, (0, 0.1, 0), (0.4, 0.2, 8), (0.68, 0.68, 0.66))
    return d


def obstacle(d, r, radius):
    """What the bike crashes into: an Obstacle behaviour with its reach."""
    return (ids["Obstacle"], {"radius": radius})


def car(name="Car", direction=1, body=(0.2, 0.45, 0.8), cabin=(0.15, 0.3, 0.55)):
    """A car on the ring road: a navigation agent driving laps of the lane it is placed on (Vehicle.as)."""
    d = Doc(name)
    r = d.entity(name)
    d.add(r, "navigation.Agent", radius=1.0, height=1.6, maxSpeed=12.0, maxAcceleration=10.0)
    d.script(r, (ids["Vehicle"], {"direction": direction}), obstacle(d, r, 2.0))
    part(d, r, "Body", CUBE, (0, 0.7, 0), (1.9, 0.8, 4.2), body)
    part(d, r, "Cabin", CUBE, (0, 1.45, -0.3), (1.7, 0.7, 2.2), cabin)
    for x in (-0.95, 0.95):
        for z in (-1.3, 1.3):
            part(d, r, "Wheel", CYL, (x, 0.35, z), (0.7, 0.3, 0.7), (0.08, 0.08, 0.09), ROLL_Z)
    return d


def pedestrian():
    d = Doc("Pedestrian")
    r = d.entity("Pedestrian")
    d.add(r, "navigation.Agent", radius=0.4, height=1.6, maxSpeed=3.0, maxAcceleration=6.0)
    d.script(r, (ids["Pedestrian"], {}), obstacle(d, r, 0.8))
    part(d, r, "Body", CYL, (0, 0.6, 0), (0.5, 1.2, 0.5), (0.55, 0.3, 0.6))
    part(d, r, "Head", SPHERE, (0, 1.42, 0), (0.42, 0.42, 0.42), (0.93, 0.76, 0.6))
    return d


def bin_():
    d = Doc("Bin")
    r = d.entity("Bin")
    d.script(r, obstacle(d, r, 0.85))
    part(d, r, "Can", CYL, (0, 0.5, 0), (0.6, 1.0, 0.6), (0.16, 0.36, 0.2))
    part(d, r, "Lid", CYL, (0, 1.03, 0), (0.66, 0.06, 0.66), (0.12, 0.26, 0.15))
    static_box(d, r, (0, 0.5, 0), (0.3, 0.5, 0.3))
    return d


def hydrant():
    d = Doc("Hydrant")
    r = d.entity("Hydrant")
    d.script(r, obstacle(d, r, 0.85))
    part(d, r, "Post", CYL, (0, 0.35, 0), (0.34, 0.7, 0.34), (0.85, 0.12, 0.1))
    part(d, r, "Cap", SPHERE, (0, 0.72, 0), (0.36, 0.3, 0.36), (0.85, 0.12, 0.1))
    part(d, r, "Nozzle", CYL, (0, 0.45, 0), (0.18, 0.5, 0.18), (0.75, 0.1, 0.08), ROLL_Z)
    static_box(d, r, (0, 0.4, 0), (0.2, 0.4, 0.2))
    return d


def traffic_cone():
    d = Doc("TrafficCone")
    r = d.entity("TrafficCone")
    d.script(r, obstacle(d, r, 0.85))
    part(d, r, "Cone", CONE, (0, 0.4, 0), (0.5, 0.8, 0.5), (0.98, 0.45, 0.08))
    part(d, r, "Base", CUBE, (0, 0.03, 0), (0.62, 0.06, 0.62), (0.15, 0.15, 0.15))
    static_box(d, r, (0, 0.4, 0), (0.22, 0.4, 0.22))
    return d


def paper():
    d = Doc("Newspaper")
    r = d.entity("Newspaper")
    d.add(r, "physics.RigidBody", motion=2, layer=1, shape=0, halfExtents={"x": 0.18, "y": 0.06, "z": 0.12},
          mass=0.4, collisionGroup=1, continuousCollision=True, friction=0.8)
    part(d, r, "Roll", CUBE, (0, 0, 0), (0.36, 0.12, 0.24), (0.95, 0.94, 0.9))
    part(d, r, "Band", CUBE, (0, 0, 0), (0.06, 0.13, 0.25), (0.85, 0.2, 0.2))
    d.script(r, (ids["Paper"], {}))
    return d


def delivery_zone():
    """In front of a subscriber's porch: the trigger a paper lands in, and the marker that shows it."""
    d = Doc("DeliveryZone")
    r = d.entity("DeliveryZone")
    d.add(r, "physics.RigidBody", motion=0, layer=3, shape=0, isTrigger=True, collisionGroup=2,
          halfExtents={"x": 1.8, "y": 1.2, "z": 1.5})
    d.script(r, (ids["Subscriber"], {}))
    m = d.entity("Marker", parent=r)
    # The tells (anim.py's clips, whose keys are these places): the arrow bobs, the mat breathes.
    arrow = part(d, m, "Arrow", CONE, (0, 6.6, -1.2), (1.0, 1.3, 1.0), (1.0, 0.82, 0.15), (1.0, 0.0, 0.0, 0.0))
    d.add(arrow, "property_animator", clip=ids["ArrowBob"])
    mat = part(d, m, "Mat", CYL, (0, 0.03, 0), (2.4, 0.04, 2.4), (1.0, 0.82, 0.15))
    d.add(mat, "property_animator", clip=ids["MatPulse"])
    return d


GUIDE = (0.1, 0.7, 1.0)  # the throw's guides: cyan, apart from the yellow porch markers


def aim_dot():
    """One dot of the throw's arc (Bike.as places a row of them along the path)."""
    d = Doc("AimDot")
    r = d.entity("AimDot")
    glow_part(d, r, "Dot", SPHERE, (0, 0, 0), (0.24, 0.24, 0.24), GUIDE)
    return d


def target_ring():
    """The reticle on the porch a throw is pulled toward: eight dashes round a 1.7 m circle (just
    outside the porch mat), each
    turned along it (Bike.as spins and pulses the root)."""
    import math
    d = Doc("TargetRing")
    r = d.entity("TargetRing")
    for i in range(8):
        a = math.radians(i * 45.0 + 22.5)
        glow_part(d, r, "Dash", CUBE, (math.cos(a) * 1.7, 0.05, math.sin(a) * 1.7), (0.9, 0.06, 0.26), GUIDE,
                  yaw(-(math.degrees(a) + 90.0)))
    return d


def fx(name, effect, lifetime):
    """A one-shot burst the scripts spawn (fx.py makes the effects): its effect fires when it is
    spawned, and Fx.as takes it away once the burst has played out."""
    d = Doc(name)
    r = d.entity(name)
    d.add(r, "particle_effect", effect=ids[effect])
    d.script(r, (ids["Fx"], {"lifetime": lifetime}))
    return d


pieces = [house("HouseRed", (0.78, 0.36, 0.3), (0.35, 0.18, 0.15)),
          house("HouseBlue", (0.42, 0.58, 0.78), (0.2, 0.26, 0.38)),
          house("HouseCream", (0.92, 0.85, 0.66), (0.42, 0.32, 0.22)),
          road(), kerb(), car(), car("CarOuter", -1, (0.82, 0.22, 0.18), (0.55, 0.12, 0.1)), pedestrian(), bin_(), hydrant(), traffic_cone(), paper(), delivery_zone(),
          aim_dot(), target_ring(), fx("FxConfetti", "Confetti", 4.0), fx("FxSparkle", "Sparkle", 1.5),
          fx("FxDust", "Dust", 1.5), fx("FxPuff", "Puff", 1.0)]
out = {}
for d in pieces:
    out[d.name] = d.write(prefabs.get(d.name), prefab=True, group="Prefabs")
    print(d.name, out[d.name])
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "kit.json"), "w"), indent=1)
