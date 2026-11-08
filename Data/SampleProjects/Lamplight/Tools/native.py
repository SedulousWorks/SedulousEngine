#!/usr/bin/env python3
"""native.py: the project's script behaviours and level scripts become its game code's native
behaviours and levels, in every scene and prefab, through the editor's MCP; then the scripts are
retired.

    python3 native.py                every scene and prefab, then the scripts retired
    python3 native.py --dry-run      what would change, nothing written
    python3 native.py --keep-scripts every scene and prefab, the scripts kept

Run it ONCE, against the project's OWN editor (Tools/README.md): the stock editor does not link the
game's code, so it knows none of its components. Each document is read whole (scene_read or
prefab_read), every `script` component record in it replaced, in place, by one native component
record per behaviour it held (on the same entity, with the same values), checked with
scene_validate and written back whole (scene_write or prefab_write, which validate again and store
the document as the editor saves it). Prefabs need no page: they are read and written as scenes
are. A script record is keyed by its script asset's guid, and its overrides by the FNV-1a hash of
each property's name, so the table below names every property; a value it does not name, a script
it does not know, a throttled behaviour (updateInterval) or a script record inside a prefab
instance's overrides stops the run before anything is written. A property left at its script
default has no override, and takes the native field's default, which is the same.

A scene's LEVEL script (its `script` settings block: the Level class, its enable flag, its
overrides) becomes the native level's settings block (LEVELS: the [Level] that replaces it), its
`active` the script's enable flag and its fields the overridden values (the rest at the native
defaults, the same as the script's); the `script` block is left naming no class, as a scene that
never had one. A level script LEVELS does not name, or an override it does not, stops the run as
above, and so does a scene that already turned the native level on.

Retiring the scripts: the startup script setting cleared (the game's [Game] class runs instead),
each script asset deleted (asset_delete refuses one still in use) and its source under Sources/
removed, then a cook.

Generic: another sample copies this file and replaces TABLE, LEVELS and GAME_SCRIPTS with its own.
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcp import call

# Each script behaviour's asset guid: (its source under Sources/, the native component's id (its
# [Behaviour]), {script property name: native field name}). Every property is listed, overridden
# anywhere or not, so an override of any of them carries over.
TABLE = {
    "6f56966c-c870-774b-a6a6-b0f7a51cce79": ("Thief.as", "lamplight.thief", {
        "camera": "Camera", "sneakSpeed": "SneakSpeed", "walkSpeed": "WalkSpeed", "runSpeed": "RunSpeed",
        "turnRate": "TurnRate", "pebble": "Pebble", "throwSpeed": "ThrowSpeed", "throwEvery": "ThrowEvery"}),
    "cdf68e5a-7c03-4b4e-ad8e-12682afc4a75": ("Footsteps.as", "lamplight.footsteps", {
        "wood": "Wood", "stone": "Stone", "gravel": "Gravel", "grass": "Grass", "sneakStride": "SneakStride",
        "walkStride": "WalkStride", "runStride": "RunStride", "runSpeed": "RunSpeed", "walkNoise": "WalkNoise",
        "runNoise": "RunNoise", "footDrop": "FootDrop"}),
    "7f3b2da3-a7b0-dc4f-8964-0fdf9c7973d1": ("LightMeter.as", "lamplight.light_meter", {
        "chestHeight": "ChestHeight", "halfLight": "HalfLight", "follow": "Follow", "glowBelow": "GlowBelow",
        "glowStrength": "GlowStrength", "slots": "Slots"}),
    "ac3e40c8-ddfd-314c-acf9-5259e4115b6b": ("Guard.as", "lamplight.guard", {
        "thief": "Thief", "route": "Route", "lantern": "Lantern", "meter": "Meter", "walkSpeed": "WalkSpeed",
        "runSpeed": "RunSpeed", "eyeHeight": "EyeHeight", "noticeSeconds": "NoticeSeconds", "halfLight": "HalfLight",
        "forget": "Forget", "catchDistance": "CatchDistance", "hearing": "Hearing", "searchSeconds": "SearchSeconds",
        "touch": "Touch", "grace": "Grace", "group": "Group"}),
    "743ca669-a275-4c4a-ba66-f7bede162f2a": ("Door.as", "lamplight.door", {
        "thief": "Thief", "locked": "Locked", "pickSeconds": "PickSeconds", "reach": "Reach", "shutYaw": "ShutYaw",
        "lockAlong": "LockAlong", "lockHeight": "LockHeight", "openAngle": "OpenAngle", "swingSpeed": "SwingSpeed"}),
    "2dd35d36-cca8-cf4d-8440-9f8995e21aed": ("Lamp.as", "lamplight.lamp", {
        "thief": "Thief", "light": "Light", "reach": "Reach", "lit": "Lit", "flameSlot": "FlameSlot",
        "chimneySlot": "ChimneySlot", "flameLit": "FlameLit", "flameOut": "FlameOut", "chimneyLit": "ChimneyLit",
        "chimneyOut": "ChimneyOut"}),
    "48423ab1-e200-8e4b-b6f5-7d16a4993d2c": ("Flicker.as", "lamplight.flicker", {"amount": "Amount", "rate": "Rate"}),
    "21f57a62-af12-5e4f-8b2a-034c5f46455c": ("Loot.as", "lamplight.loot", {
        "thief": "Thief", "value": "Value", "target": "Target", "reach": "Reach", "spin": "Spin"}),
    "9c2515ee-996f-a045-85a0-6dea89c169fc": ("Alarm.as", "lamplight.alarm", {
        "thief": "Thief", "loudness": "Loudness", "rest": "Rest"}),
    "8d8800d1-354d-8c47-bf0c-3e1ad690f5c5": ("Checkpoint.as", "lamplight.checkpoint", {"thief": "Thief"}),
    "3118d28c-64df-ec45-9d20-fa8a575473c4": ("Exit.as", "lamplight.exit", {"thief": "Thief"}),
    "8ba281c9-5ceb-484a-8649-fd15eece79e9": ("Pebble.as", "lamplight.pebble", {
        "loudness": "Loudness", "hardLanding": "HardLanding", "lifetime": "Lifetime"}),
    "3468d725-08c9-5d4e-8990-cdacc96fe7ad": ("CameraRig.as", "lamplight.camera_rig", {
        "target": "Target", "distance": "Distance", "height": "Height", "lookHeight": "LookHeight",
        "follow": "Follow", "swing": "Swing"}),
    "6e6fe7e1-458b-cd40-830b-72a5a01c34f5": ("CutawayWall.as", "lamplight.cutaway_wall", {
        "camera": "Camera", "thief": "Thief", "normalX": "NormalX", "normalZ": "NormalZ", "halfLength": "HalfLength",
        "margin": "Margin", "cutaway": "Cutaway", "speed": "Speed"}),
}

# Each level script's asset guid: (its source under Sources/, the native level's id (its [Level]),
# {script property name: native field name}), every property listed as above.
LEVELS = {}

# The startup (Game) scripts the game's [Game] class replaces: guid -> source under Sources/.
GAME_SCRIPTS = {"6d8c5968-c68f-b446-be76-b2ff79f6a746": "Lamplight.as"}

DRY = "--dry-run" in sys.argv
KEEP = "--keep-scripts" in sys.argv
NIL = "00000000-0000-0000-0000-000000000000"
# A script property value's kind (ScriptPropertyType): its payload's key in the record.
FLOAT, INT, BOOL, STRING, COLOR, VEC3, ENTITY, ASSET = 1, 2, 3, 4, 5, 6, 7, 8


def fnv(name):
    """A script property's name hash (ScriptPropertyNameHash): FNV-1a 64 over its name."""
    h = 14695981039346656037
    for b in name.encode():
        h ^= b
        h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h


def wire_key(field):
    """The key a native field is stored under: its name, the first letter lowercased."""
    return field[:1].lower() + field[1:]


_schemas = {}


def schema(component):
    if component not in _schemas:
        _schemas[component] = call("component_schema", {"type": component})
    return _schemas[component]


class Refused(Exception):
    pass


def override_value(kind, payload, field):
    """A script override's payload as the native field's XML text (or {key: text} for an object)."""
    if kind in (FLOAT, INT):
        number = float(payload.text)
        if field["kind"] in ("f32", "f64"):
            return payload.text
        if field["kind"] in ("i8", "u8", "i16", "u16", "i32", "u32", "i64", "u64"):
            if number != int(number):
                raise Refused("%s takes a whole number, not %s" % (field["key"], payload.text))
            return str(int(number))
        raise Refused("%s (%s) takes no number" % (field["key"], field["kind"]))
    if kind == BOOL:
        if field["kind"] != "bool":
            raise Refused("%s (%s) takes no flag" % (field["key"], field["kind"]))
        return payload.text
    if kind == STRING:
        text = payload.text or ""
        if "enum" in field:
            for case in field["enum"]:
                if case["name"] == text:
                    return str(int(case["value"]))
            raise Refused("%s has no case %r (%s)" % (field["key"], text, [c["name"] for c in field["enum"]]))
        if field["kind"] in ("string", "guid"):
            return text
        raise Refused("%s (%s) takes no text" % (field["key"], field["kind"]))
    if kind in (ENTITY, ASSET):
        if field["kind"] != "guid":
            raise Refused("%s (%s) takes no reference" % (field["key"], field["kind"]))
        return payload.text
    if kind in (COLOR, VEC3):
        if field["kind"] != "object":
            raise Refused("%s (%s) takes no vector or colour" % (field["key"], field["kind"]))
        return {child.get("name"): child.text for child in payload}
    raise Refused("%s: a value of kind %d" % (field["key"], kind))


def field_xml(field, value):
    """One field of a record: `value` (text, or {key: text} for an object) or the schema default."""
    kind, key = field["kind"], field["key"]
    if kind == "object":
        inner = "".join(field_xml(sub, (value or {}).get(sub["key"])) for sub in field["fields"])
        return '<object name="%s">%s</object>' % (key, inner)
    if kind == "array":
        if value is not None:
            raise Refused("%s: a list is not carried over" % key)
        return '<array name="%s" count="0"/>' % key
    text = value if value is not None else field.get("default", NIL if kind == "guid" else "")
    tag = "string" if kind in ("string", "guid") else kind
    element = ET.Element(tag, {"name": key})
    element.text = text
    return ET.tostring(element, encoding="unicode")


def native_values(component, names, source, enabled_key, enabled, overrides, where):
    """A native record's or block's schema and values: `enabled_key` (the record's `enabled`, the
    block's `active`) set from the script's flag, each override under its native field's key."""
    s = schema(component)
    fields = {f["key"]: f for f in s["fields"]}
    by_hash = {fnv(name): name for name in names}
    values = {enabled_key: enabled}
    for name_hash, kind, payload in overrides:
        if name_hash not in by_hash:
            raise Refused("%s: %s has an override (hash %d) of a property the table does not name" % (where, source, name_hash))
        name = by_hash[name_hash]
        key = wire_key(names[name])
        if key not in fields:
            raise Refused("%s: %s has no field %s (its fields: %s)" % (where, component, names[name], sorted(fields)))
        values[key] = override_value(kind, payload, fields[key])
    return s, values


def body_xml(s, values):
    """Every field of a record or block, in its schema's order: a value given, else the default."""
    return "".join(field_xml(f, values.get(f["key"])) for f in s["fields"])


def native_records(owner, behaviours, where):
    """The native records for one `script` component's behaviours, in their order."""
    records = []
    for script, enabled, interval, overrides in behaviours:
        if script not in TABLE:
            raise Refused("%s: a script behaviour (%s) the table does not name" % (where, script))
        source, component, names = TABLE[script]
        if float(interval) != 0.0:
            raise Refused("%s: %s updates every %s s, which a native behaviour does not" % (where, source, interval))
        s, values = native_values(component, names, source, "enabled", enabled, overrides, where)
        dv = s["dataVersions"][0]
        body = body_xml(s, values)
        xml = ('<object><string name="owner">%s</string><string name="type">%s</string><object name="data">'
               '<array name="dataVersions" count="1"><u64 name="type">%s</u64><u32 name="version">%s</u32></array>'
               '%s</object></object>' % (owner, s["wireName"], dv["type"], dv["version"], body))
        records.append((component, values, ET.fromstring(xml)))
    return records


def overrides_of(array):
    """A script's overrides, written flat: [(name hash, kind, payload element)]."""
    values = list(array)
    return [(int(values[j].text), int(values[j + 1].text), values[j + 2]) for j in range(0, len(values), 3)]


def level_script_of(root):
    """The scene's level script block (its `script` settings) and the class it names; (None, NIL)
    when the document has none."""
    for block in root.findall("array[@name='systemSettings']/object"):
        if block.find("string[@name='system']").text == "script":
            settings = block.find("object[@name='settings']")
            return settings, settings.find("string[@name='script']").text
    return None, NIL


def convert_level(name, root):
    """The scene's level script as its native level's settings block; False when it has none."""
    settings, script = level_script_of(root)
    if settings is None or script == NIL:
        return False
    where = "%s, its level script" % name
    if script not in LEVELS:
        raise Refused("%s: a level script (%s) the table does not name" % (where, script))
    source, level, names = LEVELS[script]
    s, values = native_values(level, names, source, "active", settings.find("bool[@name='enabled']").text,
                              overrides_of(settings.find("array[@name='overrides']")), where)
    dv = s["dataVersions"][0]
    block = ET.fromstring(
        '<object><string name="system">%s</string><array name="dataVersions" count="1"><u64 name="type">%s</u64>'
        '<u32 name="version">%s</u32></array><object name="settings">%s</object></object>' % (
            s["system"], dv["type"], dv["version"], body_xml(s, values)))
    blocks = root.find("array[@name='systemSettings']")
    for existing in list(blocks):
        if existing.find("string[@name='system']").text != s["system"]:
            continue
        active = existing.find("object[@name='settings']/bool[@name='active']")
        if active is not None and active.text == "true":
            raise Refused("%s: the scene already runs %s" % (where, level))
        blocks.remove(existing)
    blocks.append(block)
    blocks.set("count", str(len(blocks)))
    # The script block names no class now, as a scene that never had one.
    settings.find("string[@name='script']").text = NIL
    settings.find("bool[@name='enabled']").text = "true"
    overrides = settings.find("array[@name='overrides']")
    for item in list(overrides):
        overrides.remove(item)
    overrides.text = None
    overrides.set("count", "0")
    print("  level %s %s" % (level, {k: v for k, v in values.items() if k != "active" or v != "true"}))
    return True


def behaviours_of(record):
    """A `script` record's behaviours: (script guid, enabled, updateInterval, [(hash, kind, payload)])."""
    items = list(record.find("object[@name='data']/array[@name='behaviors']"))
    out = []
    for i in range(0, len(items), 4):
        script, enabled, interval, overrides = items[i:i + 4]
        out.append((script.text, enabled.text, interval.text, overrides_of(overrides)))
    return out


def convert(name, xml):
    """The document with its script records replaced; None when it holds none."""
    root = ET.fromstring(xml)
    for instances in root.iter("array"):
        if instances.get("name") == "componentOps" and "<string name=\"type\">script</string>" in ET.tostring(instances, encoding="unicode"):
            raise Refused("%s: a prefab instance overrides a script record, which this does not carry over" % name)
    changed = convert_level(name, root)
    components = root.find("array[@name='components']")
    out = []
    for record in list(components):
        if record.find("string[@name='type']").text != "script":
            out.append(record)
            continue
        changed = True
        owner = record.find("string[@name='owner']").text
        for component, values, native in native_records(owner, behaviours_of(record), "%s, entity %s" % (name, owner)):
            print("  %s %s %s" % (owner, component, {k: v for k, v in values.items() if k != "enabled" or v != "true"}))
            out.append(native)
    if not changed:
        return None
    for record in list(components):
        components.remove(record)
    components.extend(out)
    components.set("count", str(len(out)))
    return ET.tostring(root, encoding="unicode")


def documents():
    """Every scene and prefab: (guid, name, the read tool, the write tool)."""
    for a in call("asset_list", {})["assets"]:
        kind = a["type"].rsplit(".", 1)[-1]
        if kind == "SceneDocument":
            yield a["guid"], a["name"], "scene_read", "scene_write"
        elif kind == "PrefabDocument":
            yield a["guid"], a["name"], "prefab_read", "prefab_write"


def main():
    # Every document converted and checked first, so a refusal writes nothing.
    pending = []
    for guid, name, read, write in documents():
        try:
            converted = convert(name, call(read, {"guid": guid})["xml"])
        except Refused as e:
            raise SystemExit("refused: %s" % e)
        if converted is None:
            continue
        check = call("scene_validate", {"xml": converted})
        if not check.get("valid") or check.get("warnings"):
            raise SystemExit("%s does not validate: %s" % (name, check))
        print(name, guid, "converted")
        pending.append((guid, name, write, converted))
    if DRY:
        print("dry run: %d document(s) would be written" % len(pending))
        return
    for guid, name, write, converted in pending:
        call(write, {"guid": guid, "xml": converted})
        print(name, "written")
    for guid, name, read, write in documents():
        xml = call(read, {"guid": guid})["xml"]
        if '<string name="type">script</string>' in xml:
            raise SystemExit("%s still holds a script record" % name)
        if level_script_of(ET.fromstring(xml))[1] != NIL:
            raise SystemExit("%s still names a level script" % name)
    if KEEP:
        return

    info = call("project_info", {})
    startup = info["settings"].get("startupScriptId")
    if startup and startup.get("guid", "").strip("{}") in GAME_SCRIPTS:
        call("project_settings_set", {"startupScriptId": ""})
        print("startup script cleared")
    # project_info answers both paths as the editor sees them, relative to its own working
    # directory; this script finds the project from where it sits (Tools/ inside it).
    project = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sources = info["sourcesRoot"]
    if not os.path.isabs(sources):
        sources = os.path.join(project, os.path.relpath(sources, info["directory"]))
    scripts = dict((g, entry[0]) for g, entry in TABLE.items())
    scripts.update((g, entry[0]) for g, entry in LEVELS.items())
    scripts.update(GAME_SCRIPTS)
    present = set(a["guid"].strip("{}") for a in call("asset_list", {})["assets"])
    for guid, source in scripts.items():
        if guid in present:
            call("asset_delete", {"guid": guid})
            print("deleted script", source)
        path = os.path.join(sources, source)
        if os.path.exists(path):
            os.remove(path)
            print("removed", path)
    print(call("asset_cook", {}))


main()
