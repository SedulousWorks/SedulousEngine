#!/usr/bin/env python3
"""materialvalues.py: a material's values, textures and modes written into its envelope by property
name, through the editor's MCP (asset_data_read, asset_data_write): shaders.py sets the lessons'
materials with it, hall.py the hall's own.
"""
import struct
import xml.etree.ElementTree as ET
from scenegen import mcp


def floats(value):
    """A parameter's value as the floats its property holds (a colour or a vector, or one)."""
    return list(value) if isinstance(value, (tuple, list)) else [value]


def set_values(material_guid, params, textures, texture_ids, blend, cull):
    """Values (by property name), textures (slot to texture name, looked up in texture_ids; the
    material binds exactly these) and the blend and cull modes into the material's envelope."""
    root = ET.fromstring(mcp("asset_data_read", {"guid": material_guid})["xml"])
    # The material's source: the object that holds its property table, inside the envelope's
    # payload and the asset around it.
    payload = next(o for o in root.iter("object") if o.find("array[@name='propertyNames']") is not None)
    names = [e.text for e in payload.find("array[@name='propertyNames']")]
    offsets = [int(e.text) for e in payload.find("array[@name='propertyOffsets']")]
    defaults = payload.find("array[@name='uniformDefaults']")
    data = bytearray(int(e.text) for e in defaults)
    for name, value in params.items():
        if name not in names:
            raise SystemExit("the material has no property %s (has %s)" % (name, names))
        at = offsets[names.index(name)]
        packed = struct.pack("<%df" % len(floats(value)), *floats(value))
        data[at:at + len(packed)] = packed
    for e, b in zip(defaults, data):
        e.text = str(b)
    slots = payload.find("array[@name='textureSlots']")
    ids = payload.find("array[@name='textureIds']")
    for array in (slots, ids):
        for child in list(array):
            array.remove(child)
    for slot, texture in textures.items():
        ET.SubElement(slots, "string").text = slot
        ET.SubElement(ids, "string").text = texture_ids[texture]
    slots.set("count", str(len(textures)))
    ids.set("count", str(len(textures)))
    payload.find("u8[@name='blendMode']").text = str(blend)
    payload.find("u8[@name='cullMode']").text = str(cull)
    mcp("asset_data_write", {"guid": material_guid, "xml": ET.tostring(root, encoding="unicode")})
