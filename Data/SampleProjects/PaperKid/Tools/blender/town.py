"""PaperKid's town: the houses, the cars and the street furniture, modelled in Blender to replace the
blockout's primitives.

    blender --background --factory-startup --python town.py -- <out dir> [preview] [Name ...]

Writes <out dir>/<Name>Model.glb for every model (or the ones named) and, with `preview`, a PNG of
each. Each model stands where its blockout piece stood and fills the same collider (kit.py keeps the
colliders and the behaviours; only the visible shapes are these): a house's walls are the 6 m cube of
its collider with the porch in front (+Z in the engine), a car is 1.9 m by 4.2 m with its wheels where
they were, and the street furniture fills its little box.
"""
import math, os, sys
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit3d
from kit3d import P, box, tube, disc, ball, ring, finish, place

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "town-out")
PREVIEW = "preview" in ARGS
WANTED = [a for a in ARGS[1:] if a != "preview"]

kit3d.PALETTE.update({
    "Trim": (0.92, 0.90, 0.84), "Glass": (0.55, 0.72, 0.86), "Foundation": (0.42, 0.41, 0.40),
    "PorchWood": (0.70, 0.62, 0.50), "Brick": (0.55, 0.24, 0.18), "DoorBrown": (0.36, 0.22, 0.14),
    "DoorGreen": (0.16, 0.36, 0.26), "DoorBlue": (0.18, 0.28, 0.50),
    "Tyre": (0.06, 0.06, 0.07), "Hub": (0.62, 0.64, 0.68), "CarGlass": (0.16, 0.22, 0.30),
    "Headlight": (0.98, 0.95, 0.80), "Taillight": (0.85, 0.10, 0.08), "Bumper": (0.20, 0.20, 0.22),
    "BinGreen": (0.16, 0.36, 0.20), "BinLid": (0.11, 0.26, 0.14), "HydrantRed": (0.80, 0.11, 0.09),
    "HydrantCap": (0.70, 0.09, 0.07), "Chrome": (0.70, 0.71, 0.74), "ConeOrange": (0.98, 0.42, 0.06),
    "ConeBand": (0.95, 0.95, 0.93), "ConeBase": (0.13, 0.13, 0.14), "Paper": (0.94, 0.93, 0.88),
    "PaperBand": (0.85, 0.18, 0.16), "PaperPrint": (0.55, 0.55, 0.55),
})


def tapered(name, size, centre, mat, top=(1.0, 1.0), bevel=0.0, shift_top=0.0):
    """A box narrower at the top (top: its width and depth there as fractions), the top face slid
    forward by `shift_top` metres: a car's cabin, a wheelie bin."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        if v.co.z > 0:
            v.co.x *= top[0]
            v.co.y *= top[1]
            v.co.y -= shift_top / size[1]  # forward is -Y
    place(bm, Matrix.Diagonal((size[0], size[1], size[2], 1.0)))
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, affect="EDGES", profile=0.5)
    place(bm, Matrix.Translation(centre))
    return finish(name, bm, mat)


def roof(name, width, depth, rise, base, mat, ridge_along_x=True, overhang=0.3):
    """A gable roof's two slopes, a slab thick, over a width x depth plan: its eaves at `base`, its
    ridge `rise` higher, along X (the gables at the sides) or along Z (a gable to the front)."""
    w, d = width / 2 + overhang, depth / 2 + overhang
    rise_o = rise * (1 + overhang / (depth / 2 if ridge_along_x else width / 2))  # the slope run on
    bm = bmesh.new()
    if ridge_along_x:
        pts = [(-w, -d, base - rise_o + rise), (w, -d, base - rise_o + rise), (w, d, base - rise_o + rise),
               (-w, d, base - rise_o + rise), (-w, 0, base + rise), (w, 0, base + rise)]
        faces = [(0, 1, 5, 4), (3, 4, 5, 2)]
    else:
        pts = [(-w, -d, base - rise_o + rise), (w, -d, base - rise_o + rise), (w, d, base - rise_o + rise),
               (-w, d, base - rise_o + rise), (0, -d, base + rise), (0, d, base + rise)]
        faces = [(0, 4, 5, 3), (1, 2, 5, 4)]
    verts = [bm.verts.new(p) for p in pts]
    for f in faces:
        bm.faces.new([verts[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.16)
    return finish(name, bm, mat)


def gable(name, a, b, apex, mat):
    """A wall-coloured triangle closing a gable end, given in the engine's terms (P points)."""
    bm = bmesh.new()
    bm.faces.new([bm.verts.new(v) for v in (a, b, apex)])
    bm.normal_update()  # a new face has no normal until asked, and solidify offsets along it
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.12)
    return finish(name, bm, mat)


def window(x, up, fwd, width, height, facing_x=False):
    """A window on a wall: the glass, a trim frame round it, and a sill under it."""
    t = 0.06
    if facing_x:  # on a side wall, facing +-X: the window lies in the YZ plane
        side = 1 if x > 0 else -1
        box("Glass", (0.06, width, height), P(x, fwd, up), "Glass")
        for dz in (-1, 1):
            box("Frame", (0.1, width + 2 * t, t), P(x + side * 0.02, fwd, up + dz * (height + t) / 2), "Trim")
        for dy in (-1, 1):
            box("Frame", (0.1, t, height), P(x + side * 0.02, fwd + dy * (width + t) / 2, up), "Trim")
        box("Sill", (0.18, width + 0.2, 0.06), P(x + side * 0.06, fwd, up - height / 2 - 0.08), "Trim")
        return
    box("Glass", (width, 0.06, height), P(x, fwd, up), "Glass")
    for dz in (-1, 1):
        box("Frame", (width + 2 * t, 0.1, t), P(x, fwd + 0.02, up + dz * (height + t) / 2), "Trim")
    for dx in (-1, 1):
        box("Frame", (t, 0.1, height), P(x + dx * (width + t) / 2, fwd + 0.02, up), "Trim")
    box("Mullion", (0.04, 0.08, height), P(x, fwd + 0.03, up), "Trim")
    box("Sill", (width + 0.2, 0.18, 0.06), P(x, fwd + 0.06, up - height / 2 - 0.08), "Trim")


def house(wall, roof_colour, door, ridge_along_x, chimney_x):
    """A house: 6 m walls on a foundation, a pitched roof, corner boards, a door and windows, and a
    porch with steps, posts and a little roof of its own."""
    kit3d.PALETTE.update({"Wall": wall, "Roof": roof_colour})
    box("Foundation", (6.1, 6.1, 0.3), P(0, 0, 0.15), "Foundation")
    box("Walls", (6.0, 6.0, 3.85), P(0, 0, 0.3 + 3.85 / 2), "Wall")
    for x in (-3.0, 3.0):
        for f in (-3.0, 3.0):
            box("Corner", (0.16, 0.16, 3.85), P(x, f, 0.3 + 3.85 / 2), "Trim")
    box("Eave", (6.2, 6.2, 0.14), P(0, 0, 4.12), "Trim")
    # The roof sits a little above the walls' 4.15 m (half its slab): the walls, the eave band and
    # the gables then end inside the slab. Level with its top surface, their edges shared its depth
    # and flickered through it as a light line along the eaves and the gable slopes.
    roof("Roof", 6.0, 6.0, 2.1, 4.15 + 0.08, "Roof", ridge_along_x)
    if ridge_along_x:  # the gables at the sides
        for x in (-3.0, 3.0):
            gable("Gable", P(x, -3.0, 4.15), P(x, 3.0, 4.15), P(x, 0, 6.25), "Wall")
    else:  # a gable to the front (with a round window) and one at the back
        for f in (-3.0, 3.0):
            gable("Gable", P(-3.0, f, 4.15), P(3.0, f, 4.15), P(0, f, 6.25), "Wall")
        disc("Oculus", P(0, 3.05, 5.0), 0.32, 0.06, "Glass", "root", 16)
        tube("OculusRim", P(0, 3.0, 5.0), P(0, 3.1, 5.0), 0.38, "Trim", "root", 16)
    # The chimney, up through the roof.
    box("Chimney", (0.6, 0.6, 2.4), P(chimney_x, -1.2, 5.3), "Brick", bevel=0.02)
    box("ChimneyCap", (0.75, 0.75, 0.12), P(chimney_x, -1.2, 6.55), "Foundation")
    # The front: the door in its frame, a window each side, more round the sides and the back.
    box("Door", (1.1, 0.08, 2.15), P(0, 3.02, 0.3 + 2.15 / 2), door)
    box("DoorFrame", (1.34, 0.1, 0.12), P(0, 3.04, 0.3 + 2.15 + 0.06), "Trim")
    for x in (-0.61, 0.61):  # the sides stop under the top piece rather than run into it
        box("DoorFrame", (0.12, 0.1, 2.15), P(x, 3.04, 0.3 + 2.15 / 2), "Trim")
    ball("Knob", P(0.38, 3.08, 1.3), 0.045, "Hub", segments=(10, 8))
    for x in (-1.9, 1.9):
        window(x, 2.5, 3.02, 1.2, 1.0)
    for f in (-1.2, 1.4):
        window(3.02, 2.4, f, 1.0, 0.9, facing_x=True)
        window(-3.02, 2.4, f, 1.0, 0.9, facing_x=True)
    for x in (-1.6, 1.6):
        window(x, 2.4, -3.02, 1.0, 0.9)
    # The porch: a deck as wide as the old one, two steps down to the path, posts and a roof.
    box("Deck", (3.0, 1.6, 0.3), P(0, 3.8, 0.15), "PorchWood", bevel=0.02)
    box("Step", (1.4, 0.35, 0.15), P(0, 4.78, 0.075), "PorchWood", bevel=0.015)
    for x in (-1.35, 1.35):
        box("Post", (0.14, 0.14, 2.3), P(x, 4.45, 0.3 + 1.15), "Trim")
    # The porch roof sheds away from the house: from the wall 3.05 m up, down 0.35 m over its 1.9 m
    # run to its front edge, resting on the beam the posts carry. (A positive tilt lowers the front.)
    slope = math.atan2(0.35, 1.9)
    box("PorchBeam", (3.1, 0.18, 0.18), P(0, 4.45, 2.69), "Trim")
    box("PorchRoof", (3.4, 1.9 / math.cos(slope), 0.12), P(0, 3.95, (3.05 + 2.70) / 2 + 0.06), "Roof",
        tilt=math.degrees(slope))
    box("Rail", (0.08, 1.2, 0.08), P(-1.35, 3.8, 1.0), "Trim")
    box("Rail", (0.08, 1.2, 0.08), P(1.35, 3.8, 1.0), "Trim")


def car(body):
    """A small hatchback: a rounded body, a cabin with its glass, lights, bumpers and four wheels."""
    kit3d.PALETTE.update({"Body": body})
    box("Body", (1.9, 4.2, 0.62), P(0, 0, 0.72), "Body", bevel=0.12)
    box("Hood", (1.84, 1.25, 0.18), P(0, 1.35, 1.05), "Body", bevel=0.08, tilt=6)
    tapered("Cabin", (1.72, 2.3, 0.72), P(0, -0.35, 1.37), "Body", top=(0.86, 0.72), bevel=0.08, shift_top=-0.12)
    # Glass a hair proud of the cabin: windscreen, rear screen, side windows.
    tapered("Windscreen", (1.6, 0.08, 0.6), P(0, 0.8, 1.36), "CarGlass", top=(0.88, 1.0), shift_top=-0.32)
    tapered("RearScreen", (1.5, 0.08, 0.55), P(0, -1.47, 1.37), "CarGlass", top=(0.88, 1.0), shift_top=0.16)
    for x in (-0.87, 0.87):
        tapered("SideGlass", (0.06, 1.95, 0.5), P(x * (0.965 if x > 0 else 0.965), -0.35, 1.38), "CarGlass",
                top=(1.0, 0.78))
    for x in (-0.62, 0.62):
        box("Headlight", (0.42, 0.06, 0.18), P(x, 2.1, 0.82), "Headlight", bevel=0.03)
        box("Taillight", (0.36, 0.06, 0.2), P(x, -2.1, 0.86), "Taillight", bevel=0.03)
    box("BumperFront", (1.86, 0.18, 0.2), P(0, 2.12, 0.5), "Bumper", bevel=0.05)
    box("BumperRear", (1.86, 0.18, 0.2), P(0, -2.12, 0.5), "Bumper", bevel=0.05)
    for x in (-0.95, 0.95):
        for f in (-1.3, 1.3):
            axle = P(x, f, 0.35)
            ring("Tyre", axle, 0.25, 0.1, "Tyre", "root", 20, 8)
            disc("Hub", axle + Vector((0.06 if x > 0 else -0.06, 0, 0)), 0.17, 0.06, "Hub", "root", 14)


def bin_():
    """A wheelie bin: a tapered green body, its lid, a handle, wheels at the back."""
    tapered("Body", (0.56, 0.62, 0.92), P(0, 0, 0.5), "BinGreen", top=(1.08, 1.1), bevel=0.03)
    box("Lid", (0.66, 0.74, 0.07), P(0, 0.02, 1.0), "BinLid", bevel=0.025, tilt=-3)
    tube("Handle", P(-0.27, -0.38, 0.95), P(0.27, -0.38, 0.95), 0.025, "BinLid", "root", 8)
    for x in (-0.22, 0.22):
        disc("Wheel", P(x, -0.3, 0.1), 0.1, 0.07, "Tyre", "root", 14)


def hydrant():
    """A fire hydrant: a flange on the ground, the barrel, the cap and three outlets."""
    disc("Flange", P(0, 0, 0.04), 0.22, 0.08, "HydrantCap", "root", 16)
    place_cyl = lambda name, r, z0, z1, mat: tube(name, P(0, 0, z0), P(0, 0, z1), r, mat, "root", 16)
    place_cyl("Barrel", 0.15, 0.06, 0.62, "HydrantRed")
    place_cyl("Collar", 0.18, 0.58, 0.66, "HydrantCap")
    ball("Cap", P(0, 0, 0.66), 0.16, "HydrantRed", scale=(1, 1, 0.75), segments=(16, 10), cut_below=0.0)
    tube("Nut", P(0, 0, 0.76), P(0, 0, 0.82), 0.04, "Chrome", "root", 6)
    for direction in ((1, 0), (-1, 0), (0, 1)):
        root = P(0, 0, 0.42)
        tip = root + P(direction[0] * 0.24, direction[1] * 0.24, 0) - P(0, 0, 0)
        tube("Outlet", root, tip, 0.06 if direction[1] else 0.05, "HydrantRed", "root", 12)
        tube("OutletCap", tip - (tip - root).normalized() * 0.02, tip + (tip - root).normalized() * 0.03, 0.07,
             "HydrantCap", "root", 6)


def traffic_cone():
    """A traffic cone on its square base, with two reflective bands."""
    box("Base", (0.6, 0.6, 0.05), P(0, 0, 0.025), "ConeBase", bevel=0.02)
    tube("Cone", P(0, 0, 0.05), P(0, 0, 0.8), 0.22, "ConeOrange", "root", 20, 0.035)
    for z0, z1 in ((0.32, 0.4), (0.52, 0.58)):
        r0 = 0.22 - (0.22 - 0.035) * (z0 - 0.05) / 0.75 + 0.004
        r1 = 0.22 - (0.22 - 0.035) * (z1 - 0.05) / 0.75 + 0.004
        tube("Band", P(0, 0, z0), P(0, 0, z1), r0, "ConeBand", "root", 20, r1)


def newspaper():
    """A rolled newspaper with a red band round its middle."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.06, radius2=0.06, depth=0.36)
    place(bm, Matrix.Rotation(math.radians(90), 4, "Y"))      # along X
    place(bm, Matrix.Diagonal((1.0, 1.9, 1.0, 1.0)))           # a flattened roll, as the box is
    ob = finish("Roll", bm, "Paper")
    for poly in ob.data.polygons:
        poly.use_smooth = True
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.064, radius2=0.064, depth=0.06)
    place(bm, Matrix.Rotation(math.radians(90), 4, "Y"))
    place(bm, Matrix.Diagonal((1.0, 1.9, 1.0, 1.0)))
    finish("Band", bm, "PaperBand")


MODELS = {
    "HouseRed": lambda: house((0.78, 0.36, 0.30), (0.30, 0.16, 0.13), "DoorBrown", True, 1.6),
    "HouseBlue": lambda: house((0.42, 0.58, 0.78), (0.20, 0.25, 0.36), "DoorGreen", False, -1.6),
    "HouseCream": lambda: house((0.92, 0.85, 0.66), (0.42, 0.30, 0.20), "DoorBlue", True, -1.6),
    "Car": lambda: car((0.20, 0.45, 0.80)),
    "CarOuter": lambda: car((0.82, 0.22, 0.18)),
    "Bin": bin_,
    "Hydrant": hydrant,
    "TrafficCone": traffic_cone,
    "Newspaper": newspaper,
}

VIEWS = {  # where a preview looks from, and at, by size
    "House": (P(-9, 11, 7), Vector((0, 0, 2.6))), "Car": (P(-4.5, 5.5, 3), Vector((0, 0, 0.8))),
    "small": (P(-1.4, 1.8, 1.2), Vector((0, 0, 0.45))), "Newspaper": (P(-0.5, 0.6, 0.45), Vector((0, 0, 0.0))),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in (WANTED or list(MODELS)):
        kit3d.reset()
        MODELS[name]()
        if PREVIEW:
            cam = kit3d.studio()
            key = "House" if name.startswith("House") else "Car" if name.startswith("Car") else \
                "Newspaper" if name == "Newspaper" else "small"
            eye, target = VIEWS[key]
            kit3d.shoot(cam, os.path.join(OUT, name + ".png"), eye, target)
        kit3d.export_static(os.path.join(OUT, name + "Model.glb"), name + "Model")
        print("written", name)


main()
