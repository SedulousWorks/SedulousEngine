#!/usr/bin/env python3
"""terrain.py <course> [out dir]: a course's mountain, generated: the files asset_import takes.

Writes, into <out dir> (default Tools/generated/<course>):
- <Course>Height.png: the heightfield, 16-bit grey, row = world Z, column = world X, centred on
  the origin (the engine's heightfield convention), heights MIN_Y..MAX_Y.
- <Course>Splat.png: the splatmap, RGBA = the base snow's share, then palette layers 0..2:
  the packed course, rock on steep ground, the forest floor the pines grow on.
- Snow.png, Course.png, Rock.png, ForestSnow.png: the layers' textures (generated noise, no
  third-party content).
- <Course>.json: the numbers the scene generator places things by: the heightfield's size and
  range, and the course line (points down the middle, on the snow).

The course is carved into the mountain rather than painted on it: the slope falls from the top
gate to the finish, the course runs down a shallow valley that bends left and right, the ground
rises away from it, and the trees keep off it. One generator keeps the terrain and the course in
step.
"""
import json, math, os, random, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))

# P0 (Documentation/Specs/snowline.md): a 513 x 513 heightfield at 1 m, heights 0 to 120 m, a
# 400 m course from the top gate to the finish.
# Each course: its size and drop, its bends, how wide the groomed course is (course_groom: the
# packed snow fades out between these distances from the line, in metres), where the forest may
# start (forest_from), how many forest patches and how big. A shortcut, if any, is a narrow groomed
# chord across the inside of one bend, from z0 to z1 (it leaves and rejoins the course there).
# `valley` is how steeply the ground rises away from the course (Meadow's and Forest's 0.0011 when
# unset). A gap, if any, is a crevasse across the valley at z: the snow drops `depth` over `wall`
# metres there, then comes back up over `ramp` metres, never steeper than the fall line, so a rider
# who falls in still rides out downhill; it spans the course to `reach` metres either side (fading
# out between the two).
COURSES = {
    "Meadow": dict(size=513, world=513.0, min_y=0.0, max_y=120.0, top_z=-200.0, bottom_z=200.0,
                   bend_amplitude=30.0, bend_length=160.0, seed=7,
                   course_groom=(6.0, 9.0), forest_from=(20.0, 30.0), forest_patches=70, patch_size=(18.0, 45.0)),
    # Lines and shortcuts: tighter bends, a narrower course, the forest close on both sides, and a
    # shortcut through the trees across the bend half way down.
    "Forest": dict(size=513, world=513.0, min_y=0.0, max_y=120.0, top_z=-200.0, bottom_z=200.0,
                   bend_amplitude=42.0, bend_length=110.0, seed=23,
                   course_groom=(4.5, 7.0), forest_from=(8.0, 12.0), forest_patches=170, patch_size=(20.0, 50.0),
                   shortcut=dict(z0=-75.0, z1=5.0, groom=(2.0, 3.5))),
    # Air: a longer run on gentle bends, steep rocky sides, few trees, and a gap: a crevasse across
    # the valley on the bend's apex low down, a kicker at its lip (course.py), the avalanche's
    # stretch after it.
    "Ridge": dict(size=513, world=513.0, min_y=0.0, max_y=120.0, top_z=-230.0, bottom_z=230.0,
                  bend_amplitude=25.0, bend_length=200.0, seed=41, valley=0.0036,
                  course_groom=(6.0, 9.0), forest_from=(28.0, 40.0), forest_patches=35, patch_size=(15.0, 35.0),
                  gap=dict(z=70.0, depth=2.5, wall=1.5, ramp=20.0, reach=(30.0, 42.0))),
}
SPLAT_SIZE = 512
TEXTURE_SIZE = 256


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


class Mountain:
    def __init__(self, spec):
        self.spec = spec
        rnd = random.Random(spec["seed"])
        # A few long, low swells for the open snow, away from the course.
        self.swells = [(rnd.uniform(0.01, 0.035), rnd.uniform(0.01, 0.035), rnd.uniform(0, 6.3), rnd.uniform(0.6, 1.6))
                       for _ in range(6)]

    def course_x(self, z):
        s = self.spec
        return s["bend_amplitude"] * math.sin(math.pi * (z - s["top_z"]) / s["bend_length"])

    def shortcut_ends(self):
        """The shortcut's two ends on the course line ((x, z), (x, z)), or None."""
        cut = self.spec.get("shortcut")
        if not cut:
            return None
        return (self.course_x(cut["z0"]), cut["z0"]), (self.course_x(cut["z1"]), cut["z1"])

    def shortcut_distance(self, x, z):
        """How far (x, z) is from the shortcut's chord (a large number with no shortcut)."""
        ends = self.shortcut_ends()
        if ends is None:
            return 1.0e9
        (ax, az), (bx, bz) = ends
        dx, dz = bx - ax, bz - az
        t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz)))
        return math.hypot(x - (ax + dx * t), z - (az + dz * t))

    def height(self, x, z):
        s = self.spec
        half = s["world"] / 2.0
        # The fall line: high at -Z, low at +Z, a little steeper near the top.
        t = (half - z) / s["world"]
        h = 5.0 + 90.0 * t ** 1.25  # leaves room under MAX_Y for the valley sides
        # Away from the course the ground rises into a broad valley.
        d = abs(x - self.course_x(z))
        h += min(d, 140.0) ** 2 * s.get("valley", 0.0011)
        # Swells on the open snow, none on the course itself.
        swell = sum(a * math.sin(fx * x + fz * z * 1.3 + p) for fx, fz, p, a in self.swells)
        h += swell * smoothstep(12.0, 35.0, d) * 2.0
        # The course: a shallow groove, so a rider sits in it; the shortcut a narrower one.
        h -= 0.8 * (1.0 - smoothstep(4.0, 10.0, d))
        cut = s.get("shortcut")
        if cut:
            h -= 0.6 * (1.0 - smoothstep(cut["groom"][0], cut["groom"][1] + 2.0, self.shortcut_distance(x, z)))
        h -= self.gap_depth(x, z)
        return max(s["min_y"], min(s["max_y"], h))

    def gap_depth(self, x, z):
        """How far below the slope the crevasse puts (x, z) (0 off it, or with no gap)."""
        gap = self.spec.get("gap")
        if not gap:
            return 0.0
        dz = z - gap["z"]
        if dz <= 0.0 or dz >= gap["wall"] + gap["ramp"]:
            return 0.0
        if dz < gap["wall"]:
            depth = gap["depth"] * dz / gap["wall"]
        else:
            depth = gap["depth"] * (1.0 - (dz - gap["wall"]) / gap["ramp"])
        d = abs(x - self.course_x(z))
        return depth * (1.0 - smoothstep(gap["reach"][0], gap["reach"][1], d))


def noise_texture(path, base, spread, seed, streaks=False):
    rnd = random.Random(seed)
    img = Image.new("RGB", (TEXTURE_SIZE, TEXTURE_SIZE))
    px = img.load()
    for y in range(TEXTURE_SIZE):
        row = rnd.uniform(-1, 1) if streaks else 0.0
        for x in range(TEXTURE_SIZE):
            n = rnd.uniform(-1, 1) * 0.6 + row * 0.4
            px[x, y] = tuple(max(0, min(255, int(round((c + n * spread) * 255)))) for c in base)
    img.save(path)


def main():
    name = sys.argv[1] if len(sys.argv) > 1 else "Meadow"
    spec = COURSES[name]
    out = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "generated", name))
    os.makedirs(out, exist_ok=True)
    m = Mountain(spec)
    size, world, half = spec["size"], spec["world"], spec["world"] / 2.0
    span = spec["max_y"] - spec["min_y"]

    def grid_to_world(g):
        return (g / (size - 1) - 0.5) * world

    # The heightfield.
    heights = [[m.height(grid_to_world(gx), grid_to_world(gz)) for gx in range(size)] for gz in range(size)]
    hf = Image.new("I;16", (size, size))
    hf.putdata([int(round((heights[gz][gx] - spec["min_y"]) / span * 65535)) for gz in range(size) for gx in range(size)])
    hf.save(os.path.join(out, name + "Height.png"))

    # The splatmap, from the heights' slope and the distance to the course.
    rnd = random.Random(spec["seed"] + 1)
    patches = [(rnd.uniform(-half, half), rnd.uniform(-half, half), rnd.uniform(*spec["patch_size"]))
               for _ in range(spec["forest_patches"])]
    groom0, groom1 = spec["course_groom"]
    forest0, forest1 = spec["forest_from"]
    cut = spec.get("shortcut")
    splat = Image.new("RGBA", (SPLAT_SIZE, SPLAT_SIZE))
    px = splat.load()
    cell = world / (size - 1)
    for sy in range(SPLAT_SIZE):
        z = (sy + 0.5) / SPLAT_SIZE * world - half
        gz = min(size - 2, int((z + half) / cell))
        for sx in range(SPLAT_SIZE):
            x = (sx + 0.5) / SPLAT_SIZE * world - half
            gx = min(size - 2, int((x + half) / cell))
            dhdx = (heights[gz][gx + 1] - heights[gz][gx]) / cell
            dhdz = (heights[gz + 1][gx] - heights[gz][gx]) / cell
            slope = math.degrees(math.atan(math.hypot(dhdx, dhdz)))
            d = abs(x - m.course_x(z))
            course = 1.0 - smoothstep(groom0, groom1, d)
            ds = m.shortcut_distance(x, z)
            if cut:
                course = max(course, 1.0 - smoothstep(cut["groom"][0], cut["groom"][1], ds))
            rock = smoothstep(28.0, 36.0, slope) * (1.0 - course)
            forest = 0.0
            if d > forest0:
                for px_, pz, r in patches:
                    forest = max(forest, 1.0 - smoothstep(r * 0.6, r, math.hypot(x - px_, z - pz)))
            forest *= smoothstep(forest0, forest1, d) * (1.0 - rock)
            if cut:
                # The shortcut runs through the trees: they come right up to it.
                forest *= smoothstep(cut["groom"][1], cut["groom"][1] + 1.5, ds)
            base = max(0.0, 1.0 - course - rock - forest)
            total = base + course + rock + forest
            px[sx, sy] = tuple(int(round(v / total * 255)) for v in (base, course, rock, forest))
    splat.save(os.path.join(out, name + "Splat.png"))

    # The layers' textures: plain, light noise; the course a little compacted, in streaks.
    noise_texture(os.path.join(out, "Snow.png"), (0.93, 0.95, 0.99), 0.025, 11)
    # The groomed course: cooler and greyer than the open snow, in corduroy streaks, so it reads.
    noise_texture(os.path.join(out, "Course.png"), (0.72, 0.79, 0.90), 0.06, 12, streaks=True)
    noise_texture(os.path.join(out, "Rock.png"), (0.36, 0.37, 0.40), 0.08, 13)
    noise_texture(os.path.join(out, "ForestSnow.png"), (0.86, 0.89, 0.93), 0.035, 14)

    # The course line: every 20 m down the middle, a little above the snow.
    points = []
    z = spec["top_z"]
    while z <= spec["bottom_z"] + 1e-3:
        x = m.course_x(z)
        points.append([round(x, 3), round(m.height(x, z) + 0.05, 3), round(z, 3)])
        z += 20.0
    length = sum(math.dist(a, b) for a, b in zip(points, points[1:]))
    info = dict(name=name, size=size, world=world, min_y=spec["min_y"], max_y=spec["max_y"],
                course=points, course_length=round(length, 1))
    ends = m.shortcut_ends()
    if ends:
        # The shortcut's line: every 10 m along its chord, a little above its snow.
        (ax, az), (bx, bz) = ends
        steps = max(1, int(math.hypot(bx - ax, bz - az) / 10.0))
        cut_points = []
        for i in range(steps + 1):
            x, z = ax + (bx - ax) * i / steps, az + (bz - az) * i / steps
            cut_points.append([round(x, 3), round(m.height(x, z) + 0.05, 3), round(z, 3)])
        info["shortcut"] = cut_points
        info["shortcut_range"] = [spec["shortcut"]["z0"], spec["shortcut"]["z1"]]
    gap = spec.get("gap")
    if gap:
        # The crevasse: its lip on the course line (on the snow before the drop), and how far past
        # the lip a landing is short (in it, the ramp up not yet reached) and where it ends.
        x = m.course_x(gap["z"])
        info["gap"] = dict(lip=[round(x, 3), round(m.height(x, gap["z"]), 3), gap["z"]],
                           short=round(gap["wall"] + gap["ramp"] * 0.6, 3),
                           length=gap["wall"] + gap["ramp"], reach=gap["reach"][0])
    json.dump(info, open(os.path.join(out, name + ".json"), "w"), indent=1)
    print(name, "written to", out, "- course", round(length, 1), "m, drop",
          round(points[0][1] - points[-1][1], 1), "m")


if __name__ == "__main__":  # course.py imports the mountain to stand things on its snow
    main()
