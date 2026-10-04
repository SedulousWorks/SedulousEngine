#!/usr/bin/env python3
"""anim.py: the property-animation clips (the juice's tells), written through asset_create /
asset_data_write. Each clip animates its entity's own Transform with cubic keys and flat tangents,
so every move eases in and out; keys are absolute values, so a clip is made for the piece it moves
(kit.py places them)."""
import os, sys, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import mcp, assets

CUBIC = 2
FLOAT3 = 1


def arr(name, kind, values):
    if not values:
        return '<array name="%s" count="0"/>' % name
    return '<array name="%s" count="%d">%s</array>' % (name, len(values), "".join(
        "<%s>%s</%s>" % (kind, v, kind) for v in values))


def clip_source(duration, tracks):
    """The clip's source object. tracks: [(component, path, [channel keys: [(time, value)...]] x3)]
    - Float3 tracks only; a Transform track's path is the field's name (Position, Scale)."""
    comp, path, kinds, starts, counts = [], [], [], [], []
    times, values, tin, tout, interp = [], [], [], [], []
    for component, prop, channels in tracks:
        comp.append(component)
        path.append(prop)
        kinds.append(FLOAT3)
        for keys in channels:
            starts.append(len(times))
            counts.append(len(keys))
            for t, v in keys:
                times.append(t); values.append(v); tin.append(0.0); tout.append(0.0); interp.append(CUBIC)
    return '<object name="source">%s</object>' % "".join([
        '<f32 name="duration">%s</f32>' % duration,
        arr("trackComponent", "string", comp), arr("trackPath", "string", path), arr("trackKind", "u8", kinds),
        arr("channelKeyStart", "u32", starts), arr("channelKeyCount", "u32", counts),
        arr("keyTime", "f32", times), arr("keyValue", "f32", values), arr("keyTangentIn", "f32", tin),
        arr("keyTangentOut", "f32", tout), arr("keyInterp", "u8", interp),
        arr("trackQuatStart", "u32", [0] * len(tracks)), arr("trackQuatCount", "u32", [0] * len(tracks)),
        arr("quatTime", "f32", []), '<array name="quatValue" count="0"/>'])


def write(name, duration, tracks):
    have = {a["name"]: a["guid"] for a in assets()}
    guid = have.get(name) or mcp("asset_create", {"creator": "Property Animation Clip", "name": name,
                                                   "group": "Animation"})["guid"]
    xml = mcp("asset_data_read", {"guid": guid})["xml"]
    xml = re.sub(r'<object name="source">.*?</object>(\s*</object>\s*</object>\s*</root>)',
                 lambda m: clip_source(duration, tracks) + m.group(1), xml, flags=re.S)
    mcp("asset_data_write", {"guid": guid, "xml": xml})
    print(name, guid)


def hold(v, d):
    return [(0.0, v), (d, v)]


def swing(a, b, d):
    return [(0.0, a), (d / 2, b), (d, a)]


# The marker's arrow over a subscriber's porch: bobs half a metre (its place in the DeliveryZone
# prefab: 0, 6.6, -1.2).
write("ArrowBob", 1.2, [("Transform", "Position", [hold(0.0, 1.2), swing(6.6, 7.1, 1.2), hold(-1.2, 1.2)])])
# The porch mat: breathes wider and back (its scale in the prefab: 2.4, 0.04, 2.4).
write("MatPulse", 1.0, [("Transform", "Scale", [swing(2.4, 2.9, 1.0), hold(0.04, 1.0), swing(2.4, 2.9, 1.0)])])


def glow_material(name, brightness):
    """An unlit material whose base colour is `brightness` (sRGB like every colour; above 1 it
    decodes past white and the bloom picks it up), tinted
    per piece by its mesh colour: the aim's dots and the target ring glow without lighting."""
    import struct
    have = {a["name"]: a["guid"] for a in assets()}
    guid = have.get(name) or mcp("asset_create", {"creator": "Unlit Material", "name": name,
                                                   "group": "Materials"})["guid"]
    xml = mcp("asset_data_read", {"guid": guid})["xml"]
    channel = "".join("<u8>%d</u8>" % b for b in struct.pack("<f", brightness))
    alpha = "".join("<u8>%d</u8>" % b for b in struct.pack("<f", 1.0))
    xml = re.sub(r'<array name="uniformDefaults" count="16">.*?</array>',
                 '<array name="uniformDefaults" count="16">%s</array>' % (channel * 3 + alpha), xml, flags=re.S)
    mcp("asset_data_write", {"guid": guid, "xml": xml})
    print(name, guid)


# The throw's guides (kit.py's AimDot and TargetRing).
glow_material("AimGuide", 1.35)  # decodes to 2.0
