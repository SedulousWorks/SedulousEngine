#!/usr/bin/env python3
"""native.py: the project's script behaviours become its game code's native behaviours, in every
scene and prefab, through the editor's MCP; then the scripts are retired.

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

Retiring the scripts: the startup script setting cleared (the game's [Game] class runs instead),
each script asset deleted (asset_delete refuses one still in use) and its source under Sources/
removed, then a cook.

Generic: another sample copies this file and replaces TABLE and GAME_SCRIPTS with its own.
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcp import call

# Each script behaviour's asset guid: (its source under Sources/, the native component's id (its
# [Behaviour]), {script property name: native field name}). Every property is listed, overridden
# anywhere or not, so an override of any of them carries over.
TABLE = {
    "2d7db958-419a-5742-b33b-219febf36182": ("PlayerController.as", "skyhopper.player_controller", {
        "moveSpeed": "MoveSpeed", "acceleration": "Acceleration", "airAcceleration": "AirAcceleration",
        "jumpSpeed": "JumpSpeed", "coyoteTime": "CoyoteTime", "jumpBuffer": "JumpBuffer",
        "turnSpeed": "TurnSpeed", "killHeight": "KillHeight", "safeGroundTime": "SafeGroundTime",
        "bounceSpeed": "BounceSpeed", "respawnDelay": "RespawnDelay", "graceTime": "GraceTime",
        "safeMargin": "SafeMargin"}),
    "a238cc1f-b212-b440-ba4a-513a05349214": ("FollowCamera.as", "skyhopper.follow_camera", {
        "target": "Target", "distance": "Distance", "height": "Height", "lookHeight": "LookHeight",
        "positionSmoothing": "PositionSmoothing", "shakeDecay": "ShakeDecay"}),
    "e4bb099c-66f4-7b40-9a1a-bb6bafb057d2": ("Coin.as", "skyhopper.coin", {
        "radius": "Radius", "spinSpeed": "SpinSpeed", "bobHeight": "BobHeight", "value": "Value",
        "lookRadius": "LookRadius", "lookTurn": "LookTurn", "lookPitch": "LookPitch"}),
    "25312f87-87fa-054a-8ab5-0d59232bc6dc": ("Pickup.as", "skyhopper.pickup", {
        "takenEvent": "TakenEvent", "value": "Value", "radius": "Radius", "spinSpeed": "SpinSpeed",
        "bobHeight": "BobHeight", "chimePitch": "ChimePitch"}),
    "27bdc246-2a2b-be46-8d4e-95a9c1bd059b": ("Enemy.as", "skyhopper.enemy", {
        "patrolDistance": "PatrolDistance", "speed": "Speed", "radius": "Radius",
        "touchHeight": "TouchHeight", "stompSpeed": "StompSpeed", "walkClip": "WalkClip",
        "hoverHeight": "HoverHeight", "hoverSpeed": "HoverSpeed", "patrolAlongZ": "PatrolAlongZ"}),
    "b39d0b2e-5a04-5141-bc6e-e36e1a176f95": ("Mover.as", "skyhopper.mover", {
        "axis": "Axis", "distance": "Distance", "rate": "Rate", "phase": "Phase",
        "spinAxis": "SpinAxis", "spinSpeed": "SpinSpeed"}),
    "9b4d526f-d5b9-3b40-8e8d-ccb9196988fc": ("Hazard.as", "skyhopper.hazard", {
        "radius": "Radius", "touchHeight": "TouchHeight"}),
    "c648f5bb-9c34-2242-9cb7-1e0c531e834b": ("Goal.as", "skyhopper.goal", {"radius": "Radius"}),
    "6ef6446f-c654-d942-9c53-28c80475de7d": ("TimedLife.as", "skyhopper.timed_life", {"seconds": "Seconds"}),
}

# The startup (Game) scripts the game's [Game] class replaces: guid -> source under Sources/.
GAME_SCRIPTS = {"cdc1ed58-4cc2-184f-9021-aca36cc0f5f8": "PlatformerGame.as"}

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


def native_records(owner, behaviours, where):
    """The native records for one `script` component's behaviours, in their order."""
    records = []
    for script, enabled, interval, overrides in behaviours:
        if script not in TABLE:
            raise Refused("%s: a script behaviour (%s) the table does not name" % (where, script))
        source, component, names = TABLE[script]
        if float(interval) != 0.0:
            raise Refused("%s: %s updates every %s s, which a native behaviour does not" % (where, source, interval))
        s = schema(component)
        fields = {f["key"]: f for f in s["fields"]}
        by_hash = {fnv(name): name for name in names}
        values = {"enabled": enabled}
        for name_hash, kind, payload in overrides:
            if name_hash not in by_hash:
                raise Refused("%s: %s has an override (hash %d) of a property the table does not name" % (where, source, name_hash))
            name = by_hash[name_hash]
            key = wire_key(names[name])
            if key not in fields:
                raise Refused("%s: %s has no field %s (its fields: %s)" % (where, component, names[name], sorted(fields)))
            values[key] = override_value(kind, payload, fields[key])
        dv = s["dataVersions"][0]
        body = "".join(field_xml(f, values.get(f["key"])) for f in s["fields"])
        xml = ('<object><string name="owner">%s</string><string name="type">%s</string><object name="data">'
               '<array name="dataVersions" count="1"><u64 name="type">%s</u64><u32 name="version">%s</u32></array>'
               '%s</object></object>' % (owner, s["wireName"], dv["type"], dv["version"], body))
        records.append((component, values, ET.fromstring(xml)))
    return records


def behaviours_of(record):
    """A `script` record's behaviours: (script guid, enabled, updateInterval, [(hash, kind, payload)])."""
    items = list(record.find("object[@name='data']/array[@name='behaviors']"))
    out = []
    for i in range(0, len(items), 4):
        script, enabled, interval, overrides = items[i:i + 4]
        values = list(overrides)
        out.append((script.text, enabled.text, interval.text,
                    [(int(values[j].text), int(values[j + 1].text), values[j + 2]) for j in range(0, len(values), 3)]))
    return out


def convert(name, xml):
    """The document with its script records replaced; None when it holds none."""
    root = ET.fromstring(xml)
    for instances in root.iter("array"):
        if instances.get("name") == "componentOps" and "<string name=\"type\">script</string>" in ET.tostring(instances, encoding="unicode"):
            raise Refused("%s: a prefab instance overrides a script record, which this does not carry over" % name)
    components = root.find("array[@name='components']")
    out, changed = [], False
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
        if '<string name="type">script</string>' in call(read, {"guid": guid})["xml"]:
            raise SystemExit("%s still holds a script record" % name)
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
