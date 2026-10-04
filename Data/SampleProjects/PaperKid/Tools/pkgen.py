#!/usr/bin/env python3
"""PaperKid's scene/prefab XML, built from the RUNNING editor's schema (component_schema): every
record starts from the schema's defaults and takes only the fields given, so nothing here is
hand-kept against an engine build."""
import json, os, subprocess, sys, uuid

HERE = os.path.dirname(os.path.abspath(__file__))
MCP = os.path.join(HERE, "mcp.py")
NIL = "00000000-0000-0000-0000-000000000000"
_schemas = {}


sys.path.insert(0, HERE)
import mcp as _client  # the scratch MCP client (mcp.py), called in-process: scenes outgrow argv


def mcp(tool, args):
    r = _client.http_rpc("tools/call", {"name": tool, "arguments": args})
    if "error" in r:
        raise SystemExit("%s failed: %s" % (tool, json.dumps(r["error"])[:2000]))
    result = r["result"]
    text = "".join(part.get("text", "") for part in result.get("content", []))
    if result.get("isError"):
        raise SystemExit("%s failed: %s" % (tool, text[:2000]))
    try:
        return json.loads(text)
    except ValueError:
        return {"text": text}


def assets():
    """The project's assets, each `type` its short name (asset_list gives the full one)."""
    out = mcp("asset_list", {})["assets"]
    for a in out:
        a["type"] = a["type"].rsplit(".", 1)[-1]
    return out


def schema(wire):
    if wire not in _schemas:
        _schemas[wire] = mcp("component_schema", {"type": wire})
    return _schemas[wire]


def num(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return repr(v)
    return str(v)


def field_xml(field, value):
    """One field: `value` None takes the schema default."""
    kind, key = field["kind"], field["key"]
    if kind == "object":
        value = value or {}
        inner = "".join(field_xml(sub, value.get(sub["key"])) for sub in field["fields"])
        return '<object name="%s">%s</object>' % (key, inner)
    if kind == "array":
        items = value or []
        return ('<array name="%s" count="%d">%s</array>' % (key, len(items), "".join(items))
                if items else '<array name="%s" count="0"/>' % key)
    if kind == "guid":
        return '<string name="%s">%s</string>' % (key, value or field.get("default", NIL))
    if kind == "string":
        return '<string name="%s">%s</string>' % (key, value if value is not None else field.get("default", ""))
    if kind == "bool":
        v = value if value is not None else (field.get("default") == "true")
        return '<bool name="%s">%s</bool>' % (key, num(bool(v)))
    v = value if value is not None else field.get("default", "0")
    return '<%s name="%s">%s</%s>' % (kind, key, num(v), kind)


def record(owner, wire, **values):
    s = schema(wire)
    dv = s["dataVersions"][0]
    unknown = set(values) - {f["key"] for f in s["fields"]}
    if unknown:
        raise SystemExit("%s has no field(s) %s" % (wire, sorted(unknown)))
    body = "".join(field_xml(f, values.get(f["key"])) for f in s["fields"])
    return ('<object><string name="owner">%s</string><string name="type">%s</string><object name="data">'
            '<array name="dataVersions" count="1"><u64 name="type">%s</u64><u32 name="version">%s</u32></array>'
            '%s</object></object>' % (owner, s["wireName"], dv["type"], dv["version"], body))


def vec(name, xyz, keys="xyz"):
    return '<object name="%s">%s</object>' % (name, "".join('<f32 name="%s">%s</f32>' % (k, num(float(v))) for k, v in zip(keys, xyz)))


def fnv(name):
    """ScriptPropertyNameHash: FNV-1a 64 over the property's name."""
    h = 14695981039346656037
    for b in name.encode():
        h ^= b
        h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h


def override(name, value):
    """A script property override: a float, an int, or ('entity'|'asset', guid)."""
    h = fnv(name)
    if isinstance(value, tuple):
        kind = {"entity": 7, "asset": 8}[value[0]]
        return '<u64 name="nameHash">%d</u64><u8 name="kind">%d</u8><string name="id">%s</string>' % (h, kind, value[1])
    if isinstance(value, int) and not isinstance(value, bool):
        return '<u64 name="nameHash">%d</u64><u8 name="kind">2</u8><f64 name="number">%s</f64>' % (h, float(value))
    return '<u64 name="nameHash">%d</u64><u8 name="kind">1</u8><f64 name="number">%s</f64>' % (h, float(value))


def settings(block, **values):
    """A settings block by its system id, or its type name where a component shares the id."""
    s = schema(block)
    dv = s["dataVersions"][0]
    body = "".join(field_xml(f, values.get(f["key"])) for f in s["fields"])
    return ('<object><string name="system">%s</string><array name="dataVersions" count="1"><u64 name="type">%s</u64>'
            '<u32 name="version">%s</u32></array><object name="settings">%s</object></object>' % (
                s["system"], dv["type"], dv["version"], body))


_NAMESPACE = uuid.UUID("6f1c0de8-7a3e-4c55-9a2b-5061706572ab")  # PaperKid's generated ids


class Doc:
    """A scene or a prefab: entities (parents first), component records, prefab instances."""

    def __init__(self, name):
        self.name, self.entities, self.components, self.instances, self.settings = name, [], [], [], []

    def stable_id(self, kind):
        """An id fixed by the document and the order things are added, so regenerating a document
        that has not changed writes the same file."""
        return str(uuid.uuid5(_NAMESPACE, "%s/%s/%d" % (self.name, kind, len(self.entities) + len(self.instances))))

    def entity(self, name, pos=(0, 0, 0), rot=(0, 0, 0, 1), scale=(1, 1, 1), parent=None, eid=None):
        eid = eid or self.stable_id("entity")
        self.entities.append('<string name="id">%s</string><string name="name">%s</string><u8 name="active">1</u8>'
                             '<string name="parent">%s</string>%s%s%s' % (
                                 eid, name, parent or NIL, vec("position", pos), vec("rotation", rot, "xyzw"),
                                 vec("scale", scale)))
        return eid

    def add(self, owner, wire, **values):
        self.components.append(record(owner, wire, **values))

    def script(self, owner, *behaviors):
        """behaviors: (script guid, {property: value}) pairs."""
        items = ['<string name="script">%s</string><bool name="enabled">true</bool><f32 name="updateInterval">0</f32>'
                 '<array name="overrides" count="%d">%s</array>' % (g, len(o), "".join(override(k, v) for k, v in o.items()))
                 for g, o in behaviors]
        self.components.append(record(owner, "script", behaviors=items))

    def level_script(self, guid, **overrides):
        # The level script's block shares its system id (script) with the Script component.
        self.settings.append(settings("SceneScriptSettings", script=guid,
                                      overrides=[override(k, v) for k, v in overrides.items()]))

    def instance(self, prefab, pos=(0, 0, 0), rot=(0, 0, 0, 1), scale=(1, 1, 1), parent=None):
        self.instances.append(
            '<string name="prefab">%s</string><string name="parent">%s</string>%s%s%s'
            '<string name="rootLive">%s</string><string name="owner">%s</string>'
            '<string name="nestedSrcRoot">%s</string><string name="nextSibling">%s</string>'
            '<u8 name="placement">1</u8><array name="members" count="0"/><array name="destroyed" count="0"/>'
            '<array name="transformOverrides" count="0"/><array name="componentOps" count="0"/>' % (
                prefab, parent or NIL, vec("position", pos), vec("rotation", rot, "xyzw"), vec("scale", scale),
                self.stable_id("instance"), NIL, NIL, NIL))

    def xml(self):
        return ('<root><u32 name="magic">3586350318</u32><u32 name="version">3</u32><string name="name">%s</string>'
                '<array name="entities" count="%d">%s</array><array name="components" count="%d">%s</array>'
                '<array name="systemSettings" count="%d">%s</array><u8 name="prefabMode">4</u8>'
                '<array name="prefabInstances" count="%d">%s</array></root>' % (
                    self.name, len(self.entities), "".join(self.entities), len(self.components),
                    "".join(self.components), len(self.settings), "".join(self.settings),
                    len(self.instances), "".join(self.instances)))

    def write(self, guid=None, prefab=False, group=None):
        """Validate, then write over `guid`, or (a prefab) create one named after the doc."""
        v = mcp("scene_validate", {"xml": self.xml()})
        if not v.get("valid"):
            raise SystemExit("%s invalid: %s" % (self.name, json.dumps(v)[:2000]))
        args = {"xml": self.xml()}
        if guid:
            args["guid"] = guid
        else:
            args["name"] = self.name
            if group:
                args["group"] = group
        r = mcp(("prefab" if prefab else "scene") + "_write", args)
        for w in v.get("warnings", []):
            print("  warning:", w)
        return r.get("guid", guid)


def yaw(degrees):
    """A rotation about +Y (a quaternion xyzw)."""
    import math
    h = math.radians(degrees) / 2
    return (0.0, math.sin(h), 0.0, math.cos(h))


def pitch(degrees):
    import math
    h = math.radians(degrees) / 2
    return (math.sin(h), 0.0, 0.0, math.cos(h))
