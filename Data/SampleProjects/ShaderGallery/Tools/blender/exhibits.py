"""The gallery's exhibits that the engine's primitives cannot be, built in Blender from code.

    blender --background --factory-startup --python blender/exhibits.py -- generated/Exhibits

Writes <out dir>/<Name>.glb for each, smooth shaded, with uvs (so the importer can make tangents):

- Knot: a (2, 3) torus knot about a metre across: lessons 6 (dissolve) and 10 (toon), whose
  curves show off a cut edge and light bands. u runs along the tube, v around it.
- Rock: a lumpy boulder about a metre across, its uvs a plain sphere wrap: lesson 5 maps it by
  world position instead, so the wrap's seams and stretching do not show.
- Water: a 2 m square grid, 96 x 96 quads, facing up: lesson 7 moves its vertices into waves.
- Flag: a 1.6 x 1 m grid, 48 x 30 quads, facing +Z, its hoist (the pole side) at x = 0 and its
  foot at y = 0: lesson 8 sways it more the further a point is from the pole.
"""
import math, os, sys
import bpy, bmesh
from mathutils import Vector, noise

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "exhibits-out")


def grid_mesh(name, cols, rows, point):
    """A cols x rows grid of quads; point(u, v) gives a vertex's place for u, v in 0..1."""
    bm = bmesh.new()
    verts = [[bm.verts.new(point(i / cols, j / rows)) for i in range(cols + 1)] for j in range(rows + 1)]
    uv = bm.loops.layers.uv.new()
    for j in range(rows):
        for i in range(cols):
            f = bm.faces.new((verts[j][i], verts[j][i + 1], verts[j + 1][i + 1], verts[j + 1][i]))
            for loop, (a, b) in zip(f.loops, ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))):
                loop[uv].uv = (a / cols, b / rows)
    return finish(name, bm)


def tube_mesh(name, segments, sides, centre, radius, u_repeat):
    """A closed tube along centre(t), t in 0..1, `radius` round it; uvs repeat u_repeat times along."""
    bm = bmesh.new()
    rings = []
    for s in range(segments):
        t = s / segments
        c = centre(t)
        ahead = (centre(t + 1e-3) - c).normalized()
        side = ahead.cross(Vector((0, 0, 1)))
        if side.length < 1e-4:
            side = ahead.cross(Vector((0, 1, 0)))
        side.normalize()
        up = side.cross(ahead)
        rings.append([bm.verts.new(c + (side * math.cos(a) + up * math.sin(a)) * radius)
                      for a in (2 * math.pi * k / sides for k in range(sides))])
    uv = bm.loops.layers.uv.new()
    for s in range(segments):
        n = (s + 1) % segments
        for k in range(sides):
            m = (k + 1) % sides
            f = bm.faces.new((rings[s][k], rings[n][k], rings[n][m], rings[s][m]))
            u0, u1 = s / segments * u_repeat, (s + 1) / segments * u_repeat
            v0, v1 = k / sides, (k + 1) / sides
            for loop, coord in zip(f.loops, ((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
                loop[uv].uv = coord
    return finish(name, bm)


def finish(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def knot():
    p, q, big, small = 2, 3, 0.3, 0.12

    def centre(t):
        a = 2 * math.pi * t
        r = big + small * math.cos(q * a)
        return Vector((r * math.cos(p * a), r * math.sin(p * a), small * math.sin(q * a) + 0.0))

    obj = tube_mesh("Knot", 320, 24, centre, 0.085, 12)
    obj.rotation_euler = (math.radians(90), 0, 0)  # stand it up: the knot's ring faces the viewer
    return obj


def rock():
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=0.5)
    for v in bm.verts:
        d = v.co.normalized()
        # Low frequencies only: the normal map brings the small detail.
        bump = noise.fractal(d * 1.1 + Vector((3.1, 0.7, 5.2)), 1.0, 2.0, 2) * 0.09
        v.co = d * (0.5 + bump) * Vector((1.1, 0.9, 1.0))
    uv = bm.loops.layers.uv.new()
    for f in bm.faces:
        for loop in f.loops:
            d = loop.vert.co.normalized()
            loop[uv].uv = (0.5 + math.atan2(d.y, d.x) / (2 * math.pi), 0.5 + math.asin(max(-1, min(1, d.z))) / math.pi)
    return finish("Rock", bm)


def water():
    return grid_mesh("Water", 96, 96, lambda u, v: Vector((u * 2 - 1, v * 2 - 1, 0)))


def flag():
    # Blender's -Y faces the glTF +Z; built in the XZ plane, winding toward -Y.
    return grid_mesh("Flag", 48, 30, lambda u, v: Vector((u * 1.6, 0, v * 1.0)))


BUILDERS = {"Knot": knot, "Rock": rock, "Water": water, "Flag": flag}

os.makedirs(OUT, exist_ok=True)
for name, build in BUILDERS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = build()
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), use_selection=True,
                              export_tangents=True, export_materials="NONE")
    print("wrote", name, len(obj.data.vertices), "vertices")
