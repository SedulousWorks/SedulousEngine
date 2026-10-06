#!/usr/bin/env python3
"""Snowline's particle effects, written through the editor's MCP tools (PaperKid's fx.py, its
helpers kept): a soft round sprite (a texture made here) and the board's snow:
- Spray: powder thrown off the board's edge while it carves hard (continuous; Board.as plays and
  stops it on the rider's Spray entity).
- Powder: a burst of snow as the board lands (Board.as restarts it on the rider's Powder entity).
- GemSparkle: a gem taken, a bright burst of glints (Prefabs/GemSparkle, gems.py, plays it once).
- Avalanche: the front of an avalanche, a wall of billowing snow as wide as the valley floor,
  rising and spreading as it is left behind (continuous; Avalanche.as plays and stops it as the
  avalanche follows the course line).

Each effect starts from the engine's own new effect (asset_create, then asset_data_read), so the
fields this does not set keep the engine's defaults. Initializers and behaviors are stored by their
type's full name, their fields in an object after it; a system's sprite is named by its asset path,
which the cook resolves. Colours are sRGB."""
import copy, os, sys, tempfile
import xml.etree.ElementTree as ET
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import mcp, num, assets


def fnv(text):
    h = 14695981039346656037
    for b in text.encode():
        h = ((h ^ b) * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h


def el(kind, name, value=None):
    e = ET.Element(kind)
    if name is not None:
        e.set("name", name)
    if value is not None:
        e.text = num(value)
    return e


def vec(name, values, keys="xyzw"):
    o = el("object", name)
    for k, v in zip(keys, values):
        o.append(el("f32", k, float(v)))
    return o


def module(name, *fields):
    o = el("object", None)
    o.append(el("string", "type", "Sedulous.Particles." + name))
    body = el("object", None)
    for f in fields:
        body.append(f)
    o.append(body)
    return o


def shape(kind=0, radius=0.0, extents=(0, 0, 0), angle=0.7853982, arc=1.0, shell=False):
    """EmissionShape, written flat: Point 0, Sphere 1, Hemisphere 2, Box 3, Cone 4, ..."""
    return [el("u8", "type", kind), el("f32", "radius", float(radius)), vec("extents", extents),
            el("f32", "angle", float(angle)), el("f32", "arc", float(arc)), el("bool", "emitFromShell", shell)]


def position(**s):
    return module("PositionInitializer", *shape(**s), el("bool", "localSpace", False))


def lifetime(lo, hi):
    return module("LifetimeInitializer", el("f32", "min", float(lo)), el("f32", "max", float(hi)))


def velocity(base, randomness, outward=0.0, **s):
    return module("VelocityInitializer", vec("baseVelocity", base), vec("randomness", randomness),
                  el("f32", "shapeDirectionSpeed", float(outward)), el("f32", "velocityInheritance", 0.0),
                  *shape(**s))


def size(lo, hi):
    return module("SizeInitializer", vec("min", lo, "xy"), vec("max", hi, "xy"))


def color(lo, hi=None):
    return module("ColorInitializer", vec("min", lo), vec("max", hi or lo))


def rotation(speed):
    return module("RotationInitializer", el("f32", "min", 0.0), el("f32", "max", 6.2831853),
                  el("f32", "min", float(-speed)), el("f32", "max", float(speed)))


def gravity(multiplier):
    return module("GravityBehavior", el("f32", "multiplier", float(multiplier)), vec("direction", (0, -1, 0)))


def drag(amount):
    return module("DragBehavior", el("f32", "drag", float(amount)))


def alpha_over_life(*keys):
    """keys: (t, alpha) pairs, linear."""
    out = [el("i32", "keyCount", len(keys))]
    for t, v in keys:
        for n, x in (("time", t), ("value", v), ("tangentIn", 0.0), ("tangentOut", 0.0)):
            out.append(el("f32", n, float(x)))
    return module("AlphaOverLifetimeBehavior", *out)


def size_over_life(*keys):
    """keys: (t, scale) pairs, the size's multiplier on both axes."""
    out = [el("i32", "keyCount", len(keys))]
    for t, v in keys:
        out.append(el("f32", "time", float(t)))
        out.append(vec("value", (v, v), "xy"))
        out.append(vec("tangentIn", (0, 0), "xy"))
        out.append(vec("tangentOut", (0, 0), "xy"))
    return module("SizeOverLifetimeBehavior", *out)


ALPHA, ADDITIVE = 0, 1


def system(template, name, count, initializers, behaviors, texture=None, blend=ALPHA, soft=True, rate=0.0):
    """One burst of `count` particles, or with a `rate` a continuous stream of up to `count` alive,
    simulated in the world (they stay where they were thrown). `texture` is the sprite's asset path;
    the effect lists each system's (texturePaths)."""
    s = copy.deepcopy(template)
    fields = {}
    for child in s:
        fields.setdefault(child.get("name"), child)  # the first of a name: the system's own fields
    fields["maxParticles"].text = str(max(count, 1))
    fields["name"].text = name
    # Each system its own random stream: systems sharing the default seed spawn their particles in
    # the same places, so only the last drawn would show.
    fields["seed"].text = str(fnv("snowline.fx::" + name))
    fields["desiredMode"].text = "0"  # CPU
    fields["simSpace"].text = "0"     # World
    fields["blend"].text = str(blend)
    fields["render"].text = "0"       # Billboard
    fields["textureRef"].text = "00000000-0000-0000-0000-000000000000"  # the cook's, from the path
    fields["soft"].text = "true" if soft else "false"
    emitter = fields["emitter"]
    continuous = rate > 0.0
    for n, v in (("mode", 0 if continuous else 1), ("spawnRate", rate), ("burstCount", 0 if continuous else count),
                 ("burstInterval", 0.0), ("burstCycles", 0 if continuous else 1), ("isEmitting", True),
                 ("duration", 0.0), ("looping", continuous)):
        emitter.find("*[@name='%s']" % n).text = num(v)
    for key, items in (("initializers", initializers), ("behaviors", behaviors)):
        arr = fields[key]
        for old in list(arr):
            arr.remove(old)
        for item in items:
            arr.append(item)
        arr.set("count", str(len(items)))
    return s, texture


def asset(name, asset_type, creator=None, source=None, group=None):
    for a in assets():
        if a["name"] == name and a["type"] == asset_type:
            return a["guid"]
    if source:
        return mcp("asset_import", {"source": source, "group": group})["guid"]
    return mcp("asset_create", {"creator": creator, "name": name})["guid"]


def soft_dot():
    """A white dot fading softly to its rim: the sprite of every round particle."""
    from PIL import Image
    path = os.path.join(tempfile.mkdtemp(), "SoftDot.png")
    n = 64
    img = Image.new("RGBA", (n, n))
    for y in range(n):
        for x in range(n):
            d = (((x + 0.5) / n - 0.5) ** 2 + ((y + 0.5) / n - 0.5) ** 2) ** 0.5 * 2.0
            a = max(0.0, 1.0 - d) ** 1.6
            img.putpixel((x, y), (255, 255, 255, int(a * 255 + 0.5)))
    img.save(path)
    asset("SoftDot", "TextureAsset", source=path, group="Effects")
    return "Effects/SoftDot"


def effect(name, build):
    guid = asset(name, "ParticleEffectAsset", creator="Particle Effect")
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']").find("object")
    payload.find("string[@name='name']").text = name
    systems = payload.find("array[@name='systems']")
    template = copy.deepcopy(systems[0])  # the engine's defaults (a rewrite keeps them too)
    for old in list(systems):
        systems.remove(old)
    built = build(template)
    for s, _ in built:
        systems.append(s)
    systems.set("count", str(len(built)))
    # Each system's sprite, by asset path: a system with none has an empty one.
    paths = payload.find("array[@name='texturePaths']")
    for old in list(paths):
        paths.remove(old)
    for _, texture in built:
        paths.append(el("string", None, texture or ""))
    paths.set("count", str(len(built)))
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    print(name, guid)
    return guid


DOT = soft_dot()
SNOW = (0.93, 0.96, 1.0, 0.85)


# Spray: powder thrown up off the board's edge, drifting back and settling, while the board carves.
def spray(t):
    return [system(t, "Spray", 120,
                   [position(kind=3, extents=(0.35, 0.05, 0.6)), lifetime(0.6, 1.1),
                    velocity((0, 3.6, 0), (2.6, 1.4, 2.6)), size((0.32, 0.32), (0.6, 0.6)), color(SNOW)],
                   [gravity(0.7), drag(2.5), size_over_life((0, 0.6), (1, 1.8)),
                    alpha_over_life((0, 0.95), (0.6, 0.7), (1, 0))], texture=DOT, rate=90.0)]


# Powder: a landing's burst, a ring of snow kicked out and up.
def powder(t):
    return [system(t, "Powder", 30,
                   [position(kind=1, radius=0.5), lifetime(0.6, 1.0),
                    velocity((0, 1.6, 0), (3.0, 0.8, 3.0)), size((0.3, 0.3), (0.55, 0.55)), color(SNOW)],
                   [gravity(0.4), drag(3.0), size_over_life((0, 0.6), (1, 2.0)), alpha_over_life((0, 1), (1, 0))],
                   texture=DOT)]


# GemSparkle: glints thrown out in every direction, additive so they shine, falling a little.
def gem_sparkle(t):
    return [system(t, "Glints", 26,
                   [position(kind=1, radius=0.15), lifetime(0.4, 0.8),
                    velocity((0, 1.0, 0), (0.6, 0.6, 0.6), outward=3.2, kind=1, radius=0.15),
                    size((0.12, 0.12), (0.22, 0.22)), color((0.55, 0.95, 1.0, 1.0), (1.0, 1.0, 1.0, 1.0))],
                   [gravity(0.5), drag(2.0), size_over_life((0, 1.0), (1, 0.3)), alpha_over_life((0, 1), (1, 0))],
                   texture=DOT, blend=ADDITIVE, soft=False)]


# Avalanche: big slow billows off a front 30 m wide, swelling and rising as the front runs on
# (simulated in the world, so they stay behind it), and a churn of smaller snow thrown up off it.
def avalanche(t):
    return [system(t, "Billows", 260,
                   [position(kind=3, extents=(15.0, 1.0, 1.5)), lifetime(2.0, 3.5),
                    velocity((0, 2.5, 0), (2.0, 1.5, 2.0)), size((3.0, 3.0), (6.0, 6.0)),
                    color((0.90, 0.93, 0.98, 0.9), (1.0, 1.0, 1.0, 0.95)), rotation(0.4)],
                   [drag(0.6), size_over_life((0, 0.7), (1, 2.6)), alpha_over_life((0, 0), (0.15, 0.95), (1, 0))],
                   texture=DOT, rate=80.0),
            system(t, "Churn", 160,
                   [position(kind=3, extents=(14.0, 0.5, 1.0)), lifetime(0.8, 1.4),
                    velocity((0, 6.0, 0), (4.0, 2.0, 4.0)), size((0.8, 0.8), (1.6, 1.6)), color(SNOW)],
                   [gravity(0.8), drag(1.5), size_over_life((0, 0.8), (1, 1.6)), alpha_over_life((0, 1), (1, 0))],
                   texture=DOT, rate=120.0)]


for n, b in (("Spray", spray), ("Powder", powder), ("GemSparkle", gem_sparkle), ("Avalanche", avalanche)):
    effect(n, b)
