#!/usr/bin/env python3
"""effects.py: Lamplight's particle effects, written through the editor's MCP (Snowline's
particles.py, its helpers kept):
- Rain: a night's steady rain, streaks falling through a box over the thief and under the
  camera (level.py hangs it on him on a level with rain), drawn as stretched billboards along their
  fall, pale and faint so it reads against the dark without hiding the yard.

Each effect starts from the engine's own new effect (asset_create, then asset_data_read), so the
fields this does not set keep the engine's defaults. Initializers and behaviors are stored by their
type's full name, their fields in an object after it; a system's sprite is named by its asset path,
which the cook resolves. Colours are sRGB."""
import copy, os, sys
import xml.etree.ElementTree as ET
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp, num, assets

STRETCHED = 1  # ParticleRenderMode::StretchedBillboard: long along its velocity


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


def system(template, name, count, initializers, behaviors, texture=None, blend=ALPHA, soft=True, rate=0.0,
           render=0):
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
    fields["seed"].text = str(fnv("lamplight.fx::" + name))
    fields["desiredMode"].text = "0"  # CPU
    fields["simSpace"].text = "0"     # World
    fields["blend"].text = str(blend)
    fields["render"].text = str(render)
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


# Rain: streaks from a box 18 m across, hung 5 m over the thief (under the camera), falling fast
# with a little slant, gone as they reach the ground.
def rain(t):
    return [system(t, "Rain", 1800,
                   [position(kind=3, extents=(9.0, 0.5, 9.0)), lifetime(0.6, 0.7),
                    velocity((0.6, -9.0, 0.3), (0.2, 1.0, 0.2)), size((0.012, 0.18), (0.016, 0.24)),
                    color((0.70, 0.78, 0.90, 0.28), (0.80, 0.86, 0.95, 0.36))],
                   [], blend=ALPHA, soft=False, rate=2600.0, render=STRETCHED)]


if __name__ == "__main__":
    effect("Rain", rain)
