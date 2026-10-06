#!/usr/bin/env python3
"""thumbnails.py [course ...]: each course's picture for the title's cards, written through the
editor's MCP.

Needs the courses' scenes (course.py) and their terrain's .json (terrain.py). For each course: its
scene page, the editor's entity markers hidden, the scene camera above and behind the course's
top looking down its line (VIEW_BACK metres back, VIEW_UP up, at the line VIEW_AHEAD metres down),
a screenshot of the viewport, cropped to 16:9 and scaled to THUMB_SIZE (the title's ImageView fits
it whole, so its shape is the card's), into generated/Thumbs/<Course>.png, imported as the texture
UI/Thumbs/<Course>. The markers are put back as they were.
"""
import json, math, os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import mcp, assets

COURSES = sys.argv[1:] or ["Meadow", "Forest"]
THUMB_SIZE = (480, 270)
VIEW_BACK, VIEW_UP, VIEW_AHEAD = 18.0, 14.0, 70.0


def along(points, distance):
    for a, b in zip(points, points[1:]):
        step = math.dist(a, b)
        if distance <= step:
            t = distance / step
            return [a[i] + (b[i] - a[i]) * t for i in range(3)]
        distance -= step
    return list(points[-1])


def markers_on():
    state = mcp("action_state", {"id": "scene.view.markers"})
    return bool(state.get("checked"))


def main():
    out = os.path.join(HERE, "generated", "Thumbs")
    os.makedirs(out, exist_ok=True)
    scenes = {a["name"]: a["guid"] for a in assets() if a["type"] == "SceneDocument"}
    for course in COURSES:
        info = json.load(open(os.path.join(HERE, "generated", course, course + ".json")))
        page = scenes[course]
        mcp("page_open", {"guid": page})
        restore = markers_on()
        if restore:
            mcp("action_execute", {"id": "scene.view.markers"})
        top, nxt = info["course"][0], info["course"][1]
        dx, dz = nxt[0] - top[0], nxt[2] - top[2]
        n = math.hypot(dx, dz)
        eye = [top[0] - dx / n * VIEW_BACK, top[1] + VIEW_UP, top[2] - dz / n * VIEW_BACK]
        mcp("viewport_camera_set", {"page": page, "position": eye, "lookAt": along(info["course"], VIEW_AHEAD)})
        shot = mcp("viewport_screenshot", {"page": page})["path"]
        if restore:
            mcp("action_execute", {"id": "scene.view.markers"})
        img = Image.open(shot).convert("RGB")
        w, h = img.size
        want = THUMB_SIZE[0] / THUMB_SIZE[1]
        if w / h > want:
            cw = int(h * want)
            img = img.crop(((w - cw) // 2, 0, (w - cw) // 2 + cw, h))
        else:
            ch = int(w / want)
            img = img.crop((0, (h - ch) // 2, w, (h - ch) // 2 + ch))
        path = os.path.join(out, course + ".png")
        img.resize(THUMB_SIZE, Image.LANCZOS).save(path)
        guid = mcp("asset_import", {"source": path, "group": "UI/Thumbs", "importer": "Texture"})["guid"]
        print(course, guid)


main()
