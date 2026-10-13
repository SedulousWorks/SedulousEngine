#!/usr/bin/env python3
"""hall.py: the gallery's hall (scene Hall), written through the editor's MCP from lessons.py's
table, and made the project's default scene.

The lessons stand in a row along the hall in teaching order, 4 m apart: a plinth, the lesson's
exhibit on it (its mesh, its material: Materials/<Name>), and in front of it a viewpoint
("ViewNN") the list glides the camera to, the exhibit named "LessonNN". A floor, a back wall and
two end walls in the hall's own dark materials; the sun through the open side, a soft light over
each plinth, and a reflection probe over the hall. An exhibit may sit higher or lower, larger or
smaller, on a wider plinth or hung from a flagpole (lessons.py's placement fields). The camera
carries the Gallery behaviour.
importmodels.py, shaders.py and importscripts.py run first (the meshes, the materials and the
script it names).
"""
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import Doc, mcp, yaw, pitch, assets as listed
from materialvalues import set_values
from lessons import LESSONS

SPACING = 4.0          # metres between plinths
PLINTH = (1.2, 0.9, 1.2)
EXHIBIT_Y = 1.6        # the exhibit's centre above the floor
VIEW = (0.0, 1.9, 3.4)  # a viewpoint, from its plinth

# The hall's own materials (Materials/Hall/<Name>, built-in PBR): a dark floor, cool walls and near
# black plinths, so the lessons' colours, glows and see-through surfaces read against them.
HALL_MATERIALS = {
    "HallFloor": {"BaseColor": (0.15, 0.14, 0.13, 1.0), "Roughness": 0.8},
    "HallWall": {"BaseColor": (0.28, 0.30, 0.35, 1.0), "Roughness": 0.9},
    "Plinth": {"BaseColor": (0.07, 0.07, 0.08, 1.0), "Roughness": 0.35},
}


def quat_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


def assets(type_name):
    return {a["name"]: a["guid"] for a in listed() if a["type"] == type_name}


def hall_materials():
    """The hall's materials by name, made once and given their values on every run."""
    have = {a["name"]: a["guid"] for a in listed()
            if a["type"] == "MaterialAsset" and a.get("group") == "Materials/Hall"}
    for name, params in HALL_MATERIALS.items():
        if name not in have:
            have[name] = mcp("asset_create", {"creator": "PBR Material", "name": name,
                                              "group": "Materials/Hall"})["guid"]
        set_values(have[name], params, {}, {}, 0, 1)
    return have


def exhibit_meshes():
    """The Blender exhibits' meshes (importmodels.py), by model: each model's group holds its mesh."""
    found = {}
    for a in listed():
        if a["type"] == "StaticMeshAsset" and a.get("group", "").startswith("Models/"):
            found[a["group"].split("/")[1]] = a["guid"]
    return found


def main():
    meshes = assets("StaticMeshAsset")
    meshes.update(exhibit_meshes())
    materials = assets("MaterialAsset")
    scripts = assets("ScriptClassAsset")
    scenes = assets("SceneDocument")
    hall = hall_materials()

    def surface(guid):
        return ["<string>%s</string>" % guid]

    d = Doc("Hall")
    length = SPACING * (len(LESSONS) + 1)
    centre = SPACING * (len(LESSONS) - 1) / 2.0

    # The room: a floor, a back wall behind the plinths, and the two ends.
    e = d.entity("Floor", (centre, 0.0, 0.0), scale=(length + 4.0, 1.0, 12.0))
    d.add(e, "mesh", mesh=meshes["Plane"], materials=surface(hall["HallFloor"]))
    e = d.entity("BackWall", (centre, 3.0, -2.5), scale=(length + 4.0, 6.0, 0.3))
    d.add(e, "mesh", mesh=meshes["Cube"], materials=surface(hall["HallWall"]))
    for side, x in (("WestWall", -SPACING - 2.0), ("EastWall", centre * 2 + SPACING + 2.0)):
        e = d.entity(side, (x, 3.0, 1.5), scale=(0.3, 6.0, 8.0))
        d.add(e, "mesh", mesh=meshes["Cube"], materials=surface(hall["HallWall"]))

    # The lessons.
    for i, l in enumerate(LESSONS):
        x = SPACING * i
        tag = "%02d" % l["n"]
        plinth = l.get("plinth", PLINTH)
        e = d.entity("Plinth" + tag, (x, plinth[1] / 2.0, 0.0), scale=plinth)
        d.add(e, "mesh", mesh=meshes["Cube"], materials=surface(hall["Plinth"]))
        y = l.get("y", EXHIBIT_Y)
        at = x + l.get("offset", 0.0)
        if "pole" in l:
            # A flagpole from the plinth, the exhibit hung from its top by its foot.
            top = plinth[1] + l["pole"]
            e = d.entity("Pole" + tag, (at, (plinth[1] + top) / 2.0, 0.0), scale=(0.06, l["pole"], 0.06))
            d.add(e, "mesh", mesh=meshes["Cube"], materials=surface(hall["Plinth"]))
            y = top - 1.05
        size = l.get("scale", 1.1)
        e = d.entity("Lesson" + tag, (at, y, 0.0), scale=(size, size, size))
        d.add(e, "mesh", mesh=meshes[l["mesh"]], materials=["<string>%s</string>" % materials[l["name"]]])
        d.entity("View" + tag, (x + VIEW[0], VIEW[1], VIEW[2]))
        e = d.entity("Light" + tag, (x, 3.6, 1.2))
        d.add(e, "light", type=1, color={"r": 1.0, "g": 0.94, "b": 0.86, "a": 1.0}, intensity=6.0,
              range=6.0, castsShadows=False)

    # The sun through the open side, and a probe over the hall for the shiny lessons.
    e = d.entity("Sun", rot=quat_mul(yaw(-35.0), pitch(-48.0)))
    d.add(e, "light", type=0, color={"r": 1.0, "g": 0.97, "b": 0.92, "a": 1.0}, intensity=3.0,
          castsShadows=True)
    e = d.entity("HallProbe", (centre, 2.5, 1.0))
    d.add(e, "reflection_probe", halfExtents={"x": length / 2.0 + 2.0, "y": 2.5, "z": 6.0},
          blendDistance=1.0, resolution=128)

    # The camera, before the first lesson, looking along the row.
    cam = d.entity("Camera", (-SPACING * 0.5, 2.2, 6.5), rot=quat_mul(yaw(-20.0), pitch(-8.0)))
    d.add(cam, "camera", fovYRadians=1.0)
    d.script(cam, (scripts["Gallery"], {"startYaw": -20.0, "startPitch": -8.0}))

    guid = d.write(scenes.get("Hall"))
    mcp("project_settings_set", {"defaultSceneId": guid})
    print("Hall", guid)


main()
