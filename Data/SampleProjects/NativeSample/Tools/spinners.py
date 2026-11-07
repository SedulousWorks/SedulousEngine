#!/usr/bin/env python3
"""spinners.py: the sample's content, written through the editor's MCP and made the project's
default scene: the Cube and Plane primitives, a note (the Pipeline part's asset type), and the
scene Spinners, where the Engine part's Spin component turns what it is on and its Bob behaviour
moves the middle cube up and down.

The scene: a floor, a row of cubes before the camera that each spin at their own rate about their
own axis (up, sideways, a diagonal), and behind them a carousel, a spinning hub whose arms each
carry a cube that spins as well, so a spin composes with its parent's. A sun and the default sky
light it. Every cube is the Cube primitive on the default material, told apart by its tint.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import Doc, mcp, assets, colour, axis, yaw, pitch, quat_mul

# The cube of the row that also bobs, and its Bob behaviour's height and cycles a second.
BOBBER = "Tumble"
BOB_HEIGHT = 0.5
BOB_SPEED = 0.25

# The row: name, x, turns a second, axis, tint.
ROW = [
    ("Slow", -4.0, 0.15, (0, 1, 0), (0.85, 0.25, 0.20)),
    ("Quick", -2.0, 0.6, (0, 1, 0), (0.95, 0.60, 0.15)),
    ("Tumble", 0.0, 0.3, (1, 0, 0), (0.30, 0.75, 0.35)),
    ("Diagonal", 2.0, 0.4, (1, 1, 0), (0.25, 0.50, 0.90)),
    ("Backward", 4.0, -0.25, (0, 1, 0), (0.65, 0.35, 0.85)),
]
CAROUSEL_ARMS = 4
CAROUSEL_RADIUS = 2.0


def named(type_name):
    return {a["name"]: a["guid"] for a in assets() if a["type"] == type_name}


def primitive(meshes, label):
    """A primitive mesh by its creator's label, made once."""
    if label not in meshes:
        meshes[label] = mcp("asset_create", {"creator": label, "name": label})["guid"]
    return meshes[label]


def main():
    meshes = named("StaticMeshAsset")
    cube = primitive(meshes, "Cube")
    plane = primitive(meshes, "Plane")
    if "Welcome" not in named("NoteAsset"):
        mcp("asset_create", {"creator": "Native Sample Note", "name": "Welcome"})
    scenes = named("SceneDocument")

    d = Doc("Spinners")

    e = d.entity("Floor", scale=(24.0, 1.0, 16.0))
    d.add(e, "mesh", mesh=plane, color=colour(0.32, 0.33, 0.35))

    for name, x, turns, (ax, ay, az), tint in ROW:
        e = d.entity(name, (x, 1.0, 1.5), scale=(0.9, 0.9, 0.9))
        d.add(e, "mesh", mesh=cube, color=colour(*tint))
        d.add(e, "nativesample.Spin", turnsPerSecond=turns, axis=axis(ax, ay, az))
        if name == BOBBER:
            d.add(e, "nativesample.Bob", height=BOB_HEIGHT, speed=BOB_SPEED)

    # The carousel: the hub turns its arms; each arm's cube spins on its own as well.
    hub = d.entity("Carousel", (0.0, 1.4, -4.0))
    d.add(hub, "nativesample.Spin", turnsPerSecond=0.1)
    e = d.entity("Hub", parent=hub, scale=(0.5, 1.6, 0.5))
    d.add(e, "mesh", mesh=cube, color=colour(0.75, 0.75, 0.78))
    for i in range(CAROUSEL_ARMS):
        arm = d.entity("Arm%d" % (i + 1), parent=hub, rot=yaw(360.0 * i / CAROUSEL_ARMS))
        e = d.entity("Rider%d" % (i + 1), (0.0, 0.0, CAROUSEL_RADIUS), parent=arm, scale=(0.6, 0.6, 0.6))
        d.add(e, "mesh", mesh=cube, color=colour(0.95, 0.85, 0.30))
        d.add(e, "nativesample.Spin", turnsPerSecond=0.5, axis=axis(1, 0, 0))

    e = d.entity("Sun", rot=quat_mul(yaw(-30.0), pitch(-50.0)))
    d.add(e, "light", type=0, color=colour(1.0, 0.97, 0.92), intensity=3.0, castsShadows=True)

    cam = d.entity("Camera", (0.0, 3.6, 9.5), rot=pitch(-14.0))
    d.add(cam, "camera")

    guid = d.write(scenes.get("Spinners"), group="Scenes")
    mcp("project_settings_set", {"defaultSceneId": guid})
    print("Spinners", guid)


main()
