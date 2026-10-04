#!/usr/bin/env python3
"""setup.py <raw-dir>: a fresh project's first run, what the other tools build on: the fonts and
the audio imported from <raw-dir> (the third-party files CREDITS.md lists), the primitive meshes,
the input map, the minimap's render texture, the screens and their theme (from <raw-dir> too;
once imported, Sources/ holds them), a navigation zone per block and the scenes the blocks are
written into. Everything is made once and found by name after, so a rerun changes nothing."""
import os, re, sys, tempfile
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import mcp, assets

RAW = sys.argv[1] if len(sys.argv) > 1 else None


def existing():
    return {(a["name"], a["type"]): a["guid"] for a in assets()}


def created(name, asset_type, creator, group=None):
    """The asset `name` of `asset_type`, made by `creator` the first time."""
    have = existing()
    if (name, asset_type) in have:
        return have[(name, asset_type)]
    args = {"creator": creator, "name": name}
    if group is not None:
        args["group"] = group
    guid = mcp("asset_create", args)["guid"]
    print("created", name, guid)
    return guid


def imported(file_name, asset_type, group):
    name = os.path.splitext(file_name)[0]
    have = existing()
    if (name, asset_type) in have:
        return have[(name, asset_type)]
    if RAW is None:
        raise SystemExit("%s is not imported yet: run setup.py <raw-dir>" % file_name)
    guid = mcp("asset_import", {"source": os.path.join(RAW, file_name), "group": group})["guid"]
    print("imported", file_name, guid)
    return guid


def edit_payload(guid, change):
    """Read the asset's envelope, let `change` edit its payload element, write it back."""
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']")
    body = payload.find("object")  # the stored object, inside the payload
    change(body if body is not None else payload)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})


def set_fields(element, **values):
    for key, value in values.items():
        field = element.find("*[@name='%s']" % key)
        if field is None:
            raise SystemExit("no field %s" % key)
        field.text = ("true" if value else "false") if isinstance(value, bool) else str(value)


# The fonts: the masthead (Lilita One), the headlines (Alfa Slab One), the HUD, buttons and text
# (Oswald, the default UI font) and Roboto. Each one distance field (mode 1), so the large type
# (the banner, the masthead) stays sharp.
FONTS = {"LilitaOne-Regular.ttf": "Lilita One", "AlfaSlabOne-Regular.ttf": "Alfa Slab One",
         "Oswald-SemiBold.ttf": "Oswald", "Roboto-Bold.ttf": None}
for file_name, family in FONTS.items():
    guid = imported(file_name, "FontAsset", "Fonts")
    fields = {"mode": 1}
    if family:
        fields["family"] = family
    edit_payload(guid, lambda body, f=fields: set_fields(body, **f))

# The audio: the music streams; the effects decode whole.
MUSIC = ["MusicTitle", "MusicBlockA", "MusicBlockB", "MusicBlockC", "MusicEnding"]
EFFECTS = ["ClearedFanfare", "Click", "Congratulations", "Crash", "Delivered", "FailedJingle", "GameOverVoice",
           "HurryUp", "PaperLand", "Slider", "Throw", "Tick", "TimeOver"]
for name in MUSIC:
    guid = imported(name + ".ogg", "AudioClipAsset", "Audio/Music")
    edit_payload(guid, lambda body: set_fields(body, stream=True))
for name in EFFECTS:
    imported(name + ".ogg", "AudioClipAsset", "Audio")

for primitive in ("Cube", "Plane", "Cylinder", "Sphere", "Cone"):
    created(primitive, "StaticMeshAsset", primitive)

# The controls: Move (WASD and the left stick), Throw (Space, the south face button) and Pause
# (Escape, Start).
BINDING = ('<u8 name="source">%d</u8><u32 name="code">%d</u32><u32 name="modifiers">0</u32><i32 name="device">-1</i32>'
           '<f32 name="deadZone">0.15</f32><f32 name="scale">1</f32><bool name="invert">%s</bool>'
           '<bool name="normalize">true</bool><u32 name="negX">%d</u32><u32 name="posX">%d</u32>'
           '<u32 name="negY">%d</u32><u32 name="posY">%d</u32><f32 name="regionX">0</f32><f32 name="regionY">0</f32>'
           '<f32 name="regionW">1</f32><f32 name="regionH">1</f32><f32 name="stickRadius">0.15</f32>')


def binding(source, code=0, invert=False, wasd=(0, 0, 0, 0)):
    return BINDING % ((source, code, "true" if invert else "false") + wasd)


def action(name, kind, bindings):
    return ('<string name="name">%s</string><u8 name="kind">%d</u8><f32 name="sensitivity">0</f32>'
            '<f32 name="gravity">0</f32><bool name="snap">false</bool><f32 name="responseExponent">1</f32>'
            '<bool name="timeScale">false</bool><u8 name="interaction">0</u8><f32 name="interactionSeconds">0.3</f32>'
            '<array name="bindings" count="%d">%s</array>' % (name, kind, len(bindings), "".join(bindings)))


ACTIONS = [action("Move", 2, [binding(7, wasd=(1, 4, 19, 23)), binding(6, invert=True)]),
           action("Throw", 0, [binding(0, 65), binding(4, 0)]),
           action("Pause", 0, [binding(0, 62), binding(4, 14)])]
SETS = ('<array name="sets" count="1"><string name="name">Gameplay</string><i32 name="priority">0</i32>'
        '<array name="actions" count="%d">%s</array></array>' % (len(ACTIONS), "".join(ACTIONS)))


def write_controls(body):
    old = body.find("array[@name='sets']")
    index = list(body).index(old)
    body.remove(old)
    body.insert(index, ET.fromstring(SETS))


edit_payload(created("Controls", "InputMapAsset", "Input Map"), write_controls)

# The minimap: what the block's top-down camera draws and the HUD shows.
edit_payload(created("Minimap", "RenderTextureAsset", "Render Texture", "Textures"),
             lambda body: set_fields(body, width=256, height=256))

# The screens and the theme. The HUD's minimap image is the Minimap texture, by id
# ({{Minimap}} in the source).
minimap = existing()[("Minimap", "RenderTextureAsset")]
for file_name in ("Title.sml", "Hud.sml", "Pause.sml", "Settings.sml", "Cleared.sml", "Failed.sml", "GameOver.sml",
                  "PaperKidTheme.sss"):
    asset_type = "UIThemeAsset" if file_name.endswith(".sss") else "UIDocumentAsset"
    name = os.path.splitext(file_name)[0]
    if (name, asset_type) in existing():
        continue
    if RAW is None:
        raise SystemExit("%s is not imported yet: run setup.py <raw-dir>" % file_name)
    text = open(os.path.join(RAW, file_name)).read().replace("{{Minimap}}", minimap)
    staged = os.path.join(tempfile.mkdtemp(), file_name)
    open(staged, "w").write(text)
    print("imported", file_name, mcp("asset_import", {"source": staged, "group": "UI"})["guid"])

# The scripts' assets (render.py writes their sources): the Game, each block's Level, and the
# behaviours.
SCRIPTS = {"PaperKidGame": "game", "Level": "level"}
for behaviour in ("Bike", "FollowCamera", "Fx", "MapMarkers", "Obstacle", "Paper", "Pedestrian", "Pet", "Stroller",
                  "Subscriber", "Vehicle"):
    SCRIPTS[behaviour] = "behavior"
for name, tier in SCRIPTS.items():
    if (name, "ScriptClassAsset") not in existing():
        r = mcp("script_create", {"name": name, "language": "angelscript", "tier": tier, "group": "Scripts"})
        print("created", name, r.get("guid"))

# The Blender models (Tools/blender/*.py write them into <raw-dir>): the kid on his bike, and the
# town's houses, cars, street furniture, people and animals. Each lands in its own group,
# Models/KidBike/KidBike or Models/Town/<Name>Model, with its prefab beside its manifest.
imported("KidBike.glb", "ModelManifestAsset", "Models/KidBike")
for model in ("HouseRed", "HouseBlue", "HouseCream", "Car", "CarOuter", "Bin", "Hydrant", "TrafficCone", "Newspaper",
              "Pedestrian", "Dog", "Cat"):
    imported(model + "Model.glb", "ModelManifestAsset", "Models/Town")

for block in range(1, 6):
    created("Block%dNav" % block, "NavigationZoneAsset", "Navigation Zone", "Navigation")
for scene in ("Start", "Block1", "Block2", "Block3", "Block4", "Block5"):
    created(scene, "SceneDocument", "Scene")

# The manifest: the title's scene first, the Game script, the controls, the newsprint theme, Oswald
# for the HUD and text with the masthead's, the headlines' and Roboto beside it, and a 1280x720
# frame, letterboxed.
have = existing()
mcp("project_settings_set", {
    "defaultSceneId": have[("Start", "SceneDocument")],
    "startupScriptId": have[("PaperKidGame", "ScriptClassAsset")],
    "defaultInputMapId": have[("Controls", "InputMapAsset")],
    "defaultUiThemeId": have[("PaperKidTheme", "UIThemeAsset")],
    "defaultUiFontId": have[("Oswald-SemiBold", "FontAsset")],
    "uiFontIds": [have[("LilitaOne-Regular", "FontAsset")], have[("AlfaSlabOne-Regular", "FontAsset")],
                  have[("Roboto-Bold", "FontAsset")]],
    "renderWidth": 1280, "renderHeight": 720})

# The export targets: the Linux desktop, the Steam Deck (its container-built template; a
# 1280x800 frame, fullscreen) and the Web (the page is index.html, so the export serves at its
# root). Each ships the credits.
mcp("export_preset_set", {"name": "Linux64 Desktop", "platform": "Linux64", "playerName": "Sedulous PaperKid",
                          "outputSubdir": "Linux64", "additionalFiles": ["CREDITS.md"]})
mcp("export_preset_set", {"name": "Steam Deck", "platform": "Linux64", "templateId": "sedulous-steamdeck-release-0.1.0",
                          "playerName": "Sedulous PaperKid", "outputSubdir": "SteamDeck",
                          "additionalFiles": ["CREDITS.md"], "overridesRender": True, "renderWidth": 1280,
                          "renderHeight": 800, "overridesWindow": True, "windowMode": "Fullscreen", "windowResizable": False})
mcp("export_preset_set", {"name": "Web", "platform": "Web", "templateId": "sedulous-web-release-0.1.0",
                          "playerName": "index", "outputSubdir": "Web", "additionalFiles": ["CREDITS.md"]})
