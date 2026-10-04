#!/usr/bin/env python3
"""The game's particle effects, written through the editor's MCP tools: a soft round sprite
(a texture made here), and the one-shot bursts the scripts spawn (as the Fx* prefabs kit.py
makes): Confetti over a cleared block, a Sparkle on a delivery, Dust off a crash and a Puff where
a paper lands.

Each effect starts from the engine's own new effect (asset_create, then asset_data_read), so the
fields this does not set keep the engine's defaults; every system is a single burst that fires
when its entity is spawned. Initializers and behaviors are stored by their type's full name, their
fields in an object after it; a system's texture is named by its asset path, which the cook
resolves. Colours are sRGB, as entered anywhere."""
import copy, os, sys, tempfile
import xml.etree.ElementTree as ET
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pkgen import mcp, num, assets


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


def system(template, name, count, initializers, behaviors, texture=None, blend=ALPHA, soft=True):
    """One burst of `count` particles, simulated in the world (they stay where they were thrown).
    `texture` is the sprite's asset path; the effect lists each system's (texture_paths)."""
    s = copy.deepcopy(template)
    fields = {}
    for child in s:
        fields.setdefault(child.get("name"), child)  # the first of a name: the system's own fields
    fields["maxParticles"].text = str(max(count, 1))
    fields["name"].text = name
    # Each system its own random stream: systems sharing the default seed spawn their particles in
    # the same places, so only the last drawn would show.
    fields["seed"].text = str(fnv("paperkid.fx::" + name))
    fields["desiredMode"].text = "0"  # CPU
    fields["simSpace"].text = "0"     # World
    fields["blend"].text = str(blend)
    fields["render"].text = "0"       # Billboard
    fields["textureRef"].text = "00000000-0000-0000-0000-000000000000"  # the cook's, from the path
    fields["soft"].text = "true" if soft else "false"
    emitter = fields["emitter"]
    for n, v in (("mode", 1), ("spawnRate", 0.0), ("burstCount", count), ("burstInterval", 0.0),
                 ("burstCycles", 1), ("isEmitting", True), ("duration", 0.0), ("looping", False)):
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
    asset("SoftDot", "TextureAsset", source=path, group="Textures")
    return "Textures/SoftDot"


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

# Confetti: paper squares in four colours, thrown up and out over the bike, tumbling and drifting
# down slowly (light paper: a little gravity, a lot of drag), fading once they have settled.
CONFETTI = [(0.95, 0.3, 0.3, 1), (1.0, 0.82, 0.2, 1), (0.3, 0.6, 0.95, 1), (0.4, 0.85, 0.45, 1)]


def confetti(t):
    return [system(t, "Confetti%d" % i, 45,
                   [position(kind=1, radius=0.6), lifetime(2.6, 3.6),
                    velocity((0, 7.5, 0), (5.5, 2.5, 5.5)), size((0.24, 0.15), (0.32, 0.2)),
                    color(c), rotation(9.0)],
                   [gravity(0.45), drag(1.4), alpha_over_life((0, 1), (0.75, 1), (1, 0))], soft=False)
            for i, c in enumerate(CONFETTI)]


# Sparkle: warm glints rising off the porch when a paper is delivered, and a soft flash under them.
def sparkle(t):
    return [system(t, "Glints", 28,
                   [position(kind=1, radius=0.4), lifetime(0.5, 0.9),
                    velocity((0, 3.2, 0), (2.4, 1.2, 2.4)), size((0.18, 0.18), (0.3, 0.3)),
                    color((1.0, 0.86, 0.35, 1))],
                   [gravity(0.5), drag(2.0), size_over_life((0, 1), (1, 0)),
                    alpha_over_life((0, 1), (0.6, 1), (1, 0))], texture=DOT, blend=ADDITIVE),
            system(t, "Flash", 1,
                   [position(), lifetime(0.35, 0.35), velocity((0, 0, 0), (0, 0, 0)),
                    size((1.6, 1.6), (1.6, 1.6)), color((1.0, 0.9, 0.5, 0.8))],
                   [size_over_life((0, 0.4), (1, 1.4)), alpha_over_life((0, 1), (1, 0))],
                   texture=DOT, blend=ADDITIVE)]


# Dust: a crash kicks up a ring of road dust that spreads, swells and thins.
def dust(t):
    return [system(t, "Dust", 18,
                   [position(kind=1, radius=0.5), lifetime(0.7, 1.1),
                    velocity((0, 1.2, 0), (2.6, 0.6, 2.6)), size((0.5, 0.5), (0.8, 0.8)),
                    color((0.78, 0.72, 0.62, 0.75), (0.68, 0.64, 0.58, 0.6))],
                   [drag(3.0), size_over_life((0, 0.6), (1, 2.2)), alpha_over_life((0, 1), (1, 0))],
                   texture=DOT)]


# Puff: a paper hitting the ground, a small one.
def puff(t):
    return [system(t, "Puff", 7,
                   [position(kind=1, radius=0.15), lifetime(0.35, 0.55),
                    velocity((0, 0.8, 0), (1.2, 0.3, 1.2)), size((0.22, 0.22), (0.32, 0.32)),
                    color((0.85, 0.82, 0.76, 0.7))],
                   [drag(4.0), size_over_life((0, 0.7), (1, 1.8)), alpha_over_life((0, 1), (1, 0))],
                   texture=DOT)]


for n, b in (("Confetti", confetti), ("Sparkle", sparkle), ("Dust", dust), ("Puff", puff)):
    effect(n, b)
