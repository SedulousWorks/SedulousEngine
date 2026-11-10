#!/usr/bin/env python3
"""make-templates.py: the engine's project templates, Data/Templates/Starter and Data/Templates/Empty,
made from nothing through the headless MCP host (Sedulous.Tools.Mcp), so their records are at the
engine's data versions and their manifests carry its stamp.

    python3 Data/Templates/Tools/make-templates.py [Starter|Empty ...]

Run it from the engine checkout once Sedulous.Tools.Mcp (Debug) is built with this engine; with no
names it makes both. Each template's folder is made again from nothing (a folder there is replaced
only when it is a template already).

Each is authored as a project named "Sedulous Template Seed":
  - project_create with template "none" (the bare manifest and folders), the Starter seeded with the
    starter content (Roboto as the default UI font, the default sky, the cube, sphere and plane);
  - plugin_scaffold: the game's code, Code/ with its Engine part and the starter behaviour Rotator;
  - the Starter's scene Main (a floor, a cube, a sun and a camera, each record from the host's
    component_schema), made the project's default scene.
Then what the host and a cook write is taken away, and the project's names become the placeholders
a new project's names replace (ProjectTemplates): "Sedulous Template Seed" __PROJECT_NAME__,
SedulousTemplateSeed __GAME__ (in paths and texts) and seduloustemplateseed __GAME_ID__. Template.xml
is written last. The script refuses to finish when a seed name, an absolute path of this machine or
a missing piece is left.
"""
import json, math, os, shutil, sys, uuid

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mcp import ENGINE, Host  # noqa: E402

TEMPLATES_DIR = os.path.join(ENGINE, "Data", "Templates")

# The names the templates are authored under, and the placeholders they become (in this order: the
# project's name holds no game name, and the id is the game name lowered).
SEED_NAME = "Sedulous Template Seed"
SEED_GAME = "SedulousTemplateSeed"
SEED_ID = "seduloustemplateseed"
PLACEHOLDERS = [(SEED_NAME, "__PROJECT_NAME__"), (SEED_GAME, "__GAME__"), (SEED_ID, "__GAME_ID__")]

# What builds, cooks, exports, the editor and the host write, never part of a template.
WRITTEN_AT_ROOT = ["Cooked", ".cache", "Dist", "Editor", "__pycache__"]
WRITTEN_IN_CODE = ["build", ".generated", "recovery", "BeefConfig.toml", "BeefSpace_User.toml"]

NIL = "00000000-0000-0000-0000-000000000000"


# ---- scene XML from the host's component schema ----------------------------------------------

class Schemas:
    def __init__(self, host):
        self.host, self.cache = host, {}

    def get(self, wire):
        if wire not in self.cache:
            self.cache[wire] = self.host.call("component_schema", {"type": wire})
        return self.cache[wire]


def num(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return repr(v)
    return str(v)


def field_xml(field, value):
    """One field: `value` None takes the schema's default."""
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


def vec(name, xyz, keys="xyz"):
    return '<object name="%s">%s</object>' % (name, "".join('<f32 name="%s">%s</f32>' % (k, num(float(v))) for k, v in zip(keys, xyz)))


def colour(r, g, b, a=1.0):
    return {"r": r, "g": g, "b": b, "a": a}


def yaw(degrees):
    h = math.radians(degrees) / 2
    return (0.0, math.sin(h), 0.0, math.cos(h))


def pitch(degrees):
    h = math.radians(degrees) / 2
    return (math.sin(h), 0.0, 0.0, math.cos(h))


def quat_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


# The templates' generated ids: fixed by the document and the order things are added, so making a
# template again writes the same scene.
_NAMESPACE = uuid.UUID("5d0f4f0e-7f53-4c55-9a43-2b1e8f7a6c11")


class Doc:
    """A scene: entities (parents first) and their component records."""

    def __init__(self, name, schemas):
        self.name, self.schemas, self.entities, self.components = name, schemas, [], []

    def entity(self, name, pos=(0, 0, 0), rot=(0, 0, 0, 1), scale=(1, 1, 1)):
        eid = str(uuid.uuid5(_NAMESPACE, "%s/entity/%d" % (self.name, len(self.entities))))
        self.entities.append('<string name="id">%s</string><string name="name">%s</string><u8 name="active">1</u8>'
                             '<string name="parent">%s</string>%s%s%s' % (
                                 eid, name, NIL, vec("position", pos), vec("rotation", rot, "xyzw"), vec("scale", scale)))
        return eid

    def add(self, owner, wire, **values):
        s = self.schemas.get(wire)
        dv = s["dataVersions"][0]
        unknown = set(values) - {f["key"] for f in s["fields"]}
        if unknown:
            raise SystemExit("%s has no field(s) %s" % (wire, sorted(unknown)))
        body = "".join(field_xml(f, values.get(f["key"])) for f in s["fields"])
        self.components.append(
            '<object><string name="owner">%s</string><string name="type">%s</string><object name="data">'
            '<array name="dataVersions" count="1"><u64 name="type">%s</u64><u32 name="version">%s</u32></array>'
            '%s</object></object>' % (owner, s["wireName"], dv["type"], dv["version"], body))

    def xml(self):
        return ('<root><u32 name="magic">3586350318</u32><u32 name="version">3</u32><string name="name">%s</string>'
                '<array name="entities" count="%d">%s</array><array name="components" count="%d">%s</array>'
                '<array name="systemSettings" count="0"/><u8 name="prefabMode">4</u8>'
                '<array name="prefabInstances" count="0"/></root>' % (
                    self.name, len(self.entities), "".join(self.entities), len(self.components), "".join(self.components)))


# ---- the templates -------------------------------------------------------------------------------

def assets_named(host, type_name):
    """The project's assets of the short type name, by name."""
    return {a["name"]: a["guid"] for a in host.call("asset_list", {})["assets"] if a["type"].rsplit(".", 1)[-1] == type_name}


def author_starter(host):
    """The scene Main: a floor and a cube on it, a sun and a camera looking on, under the default
    sky; the project's default scene."""
    meshes = assets_named(host, "StaticMeshAsset")
    for needed in ("Cube", "Plane"):
        if needed not in meshes:
            raise SystemExit("the starter content has no %s mesh" % needed)
    d = Doc("Main", Schemas(host))
    e = d.entity("Floor", scale=(12.0, 1.0, 12.0))
    d.add(e, "mesh", mesh=meshes["Plane"], color=colour(0.32, 0.33, 0.35))
    e = d.entity("Cube", (0.0, 0.5, 0.0), rot=yaw(30.0))
    d.add(e, "mesh", mesh=meshes["Cube"], color=colour(0.85, 0.45, 0.20))
    e = d.entity("Sun", rot=quat_mul(yaw(-30.0), pitch(-50.0)))
    d.add(e, "light", type=0, color=colour(1.0, 0.97, 0.92), intensity=3.0, castsShadows=True)
    e = d.entity("Camera", (0.0, 2.5, 6.0), rot=pitch(-18.0))
    d.add(e, "camera")
    v = host.call("scene_validate", {"xml": d.xml()})
    if not v.get("valid") or v.get("warnings"):
        raise SystemExit("Main is not valid: %s" % json.dumps(v)[:2000])
    guid = host.call("scene_write", {"xml": d.xml(), "name": "Main", "group": "Scenes"}).get("guid")
    if not guid:
        raise SystemExit("scene_write gave no guid for Main")
    host.call("project_settings_set", {"defaultSceneId": guid})


TEMPLATES = [
    # id, order, its line in New Project, seeded with the starter content, its content
    ("Starter", 0, "A scene with a cube under the default sky, Roboto as the UI font, the cube, sphere and plane, "
                   "and the game's code with its starter behaviour.", True, author_starter),
    ("Empty", 1, "The game's code alone: no assets and no scene.", False, None),
]


def make(host_template):
    template_id, order, line, seed, author = host_template
    target = os.path.join(TEMPLATES_DIR, template_id)
    if os.path.exists(target):
        if not (os.path.isfile(os.path.join(target, "Template.xml")) or os.path.isfile(os.path.join(target, "Project.xml"))):
            raise SystemExit("%s is there and is not a template: not replacing it" % target)
        shutil.rmtree(target)

    print("## %s" % template_id)
    host = Host()
    try:
        host.call("project_create", {"directory": target, "name": SEED_NAME, "template": "none", "seed": seed})
        host.call("project_open", {"directory": target})
        host.call("plugin_scaffold", {"parts": ["Engine"]})
        if author is not None:
            author(host)
    finally:
        host.close()

    take_away_written(target)
    to_placeholders(target)
    write_credits(target)
    write_info(target, template_id, order, line)
    check(target, template_id)
    print("%s: %s" % (template_id, target))


def take_away_written(target):
    """What the host and a cook wrote: not the template's."""
    for name in os.listdir(target):
        if name in WRITTEN_AT_ROOT or name.startswith("Cooked-"):
            path = os.path.join(target, name)
            shutil.rmtree(path) if os.path.isdir(path) else os.remove(path)
    code = os.path.join(target, "Code")
    for name in WRITTEN_IN_CODE:
        path = os.path.join(code, name)
        if os.path.isdir(path):
            shutil.rmtree(path)
        elif os.path.exists(path):
            os.remove(path)


def is_text(data):
    return b"\0" not in data


def to_placeholders(target):
    """The seed's names become the placeholders: in each text file's content, then in the paths
    (deepest first, so a folder is renamed after what is in it)."""
    for folder, _, files in os.walk(target):
        for name in files:
            path = os.path.join(folder, name)
            data = open(path, "rb").read()
            if not is_text(data):
                continue
            text = data
            for seed, placeholder in PLACEHOLDERS:
                text = text.replace(seed.encode(), placeholder.encode())
            if text != data:
                open(path, "wb").write(text)
    for folder, dirs, files in os.walk(target, topdown=False):
        for name in files + dirs:
            if SEED_GAME in name:
                os.rename(os.path.join(folder, name), os.path.join(folder, name.replace(SEED_GAME, "__GAME__")))


# The third-party files the seed copies into Sources/, each with the licence text it ships beside
# in the engine, and its line in CREDITS.md.
THIRD_PARTY = {
    "Roboto-Regular.ttf": ("Data/Engine/Fonts/roboto/NOTICE.txt", "Roboto-NOTICE.txt",
        "- **Roboto** by Google, [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)."),
    "kloofendal_48d_partly_cloudy_puresky_1k.hdr": ("Data/Templates/kloofendal_48d_partly_cloudy_puresky/LICENSE.txt",
        "Kloofendal-CC0.txt",
        "- **Kloofendal 48d Partly Cloudy (Pure Sky)** by Greg Zaal and Jarod Guest, from "
        "[Poly Haven](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky), CC0 1.0."),
}


def write_credits(target):
    """Licenses/ and CREDITS.md for the third-party files in Sources/: a project made from the
    template carries each one's licence beside it, as the samples do."""
    sources = os.path.join(target, "Sources")
    present = [name for name in sorted(THIRD_PARTY) if os.path.isfile(os.path.join(sources, name))]
    unknown = [name for name in (os.listdir(sources) if os.path.isdir(sources) else []) if name not in THIRD_PARTY]
    if unknown:
        raise SystemExit("%s: no licence known for %s" % (target, ", ".join(unknown)))
    if not present:
        return
    licenses = os.path.join(target, "Licenses")
    os.makedirs(licenses, exist_ok=True)
    lines = ["# Credits", "", "Third-party content this project starts with:", ""]
    for name in present:
        notice, copy_as, credit = THIRD_PARTY[name]
        shutil.copyfile(os.path.join(ENGINE, notice), os.path.join(licenses, copy_as))
        lines.append(credit)
    with open(os.path.join(target, "CREDITS.md"), "w") as f:
        f.write("\n".join(lines) + "\n")


def write_info(target, template_id, order, line):
    def escape(text):
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    with open(os.path.join(target, "Template.xml"), "w") as f:
        f.write("<root>\n\t<object>\n\t\t<string name=\"name\">%s</string>\n\t\t<string name=\"description\">%s</string>\n"
                "\t\t<string name=\"picture\"/>\n\t\t<i32 name=\"order\">%d</i32>\n\t</object>\n</root>\n"
                % (escape(template_id), escape(line), order))


def check(target, template_id):
    """Nothing of the seed's names or of this machine left, and the pieces every template has."""
    problems = []
    machine = [ENGINE, os.path.expanduser("~")]
    for folder, _, files in os.walk(target):
        for name in files:
            path = os.path.join(folder, name)
            relative = os.path.relpath(path, target)
            if SEED_GAME in relative:
                problems.append("%s: a seed name in its path" % relative)
            data = open(path, "rb").read()
            if not is_text(data):
                continue
            for seed, _ in PLACEHOLDERS:
                if seed.encode() in data:
                    problems.append("%s: keeps %s" % (relative, seed))
            for place in machine:
                if place.encode() in data:
                    problems.append("%s: names %s" % (relative, place))
    for needed in ["Project.xml", "Template.xml", "Code/Plugin.xml", "Code/BeefSpace.toml", "Code/.gitignore",
                   "Code/__GAME__/BeefProj.toml", "Code/__GAME__/src/Rotator.bf", "Code/__GAME__/src/__GAME__Engine.bf"]:
        if not os.path.isfile(os.path.join(target, needed)):
            problems.append("%s is missing" % needed)
    manifest = open(os.path.join(target, "Project.xml")).read()
    if '<string name="name">__PROJECT_NAME__</string>' not in manifest:
        problems.append("Project.xml: its name is not the placeholder")
    if '<string name="id">__GAME_ID__</string>' not in manifest:
        problems.append("Project.xml: the game's package is not enabled by the id placeholder")
    if problems:
        raise SystemExit("%s:\n  %s" % (template_id, "\n  ".join(problems)))


def main():
    wanted = sys.argv[1:] or [t[0] for t in TEMPLATES]
    known = {t[0]: t for t in TEMPLATES}
    for template_id in wanted:
        if template_id not in known:
            raise SystemExit("no template %s (%s)" % (template_id, ", ".join(known)))
        make(known[template_id])


if __name__ == "__main__":
    main()
