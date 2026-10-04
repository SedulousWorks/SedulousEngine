"""The modelling kit PaperKid's Blender scripts share: primitives built with bmesh (bevelled boxes,
tubes, spheres and domes, tori), flat-colour materials from a palette, each part rigid on one bone
(a vertex group weighted wholly to it), a two-bone IK solve for laying out limbs, and the export of
a static model. Coordinates go through P(x, forward, up): Blender's forward is -Y, which glTF
exports as +Z, the engine's forward.

A model script imports this, fills PALETTE, builds its parts and exports; reset() starts the next
model in the same Blender session.
"""
import bpy, bmesh, math, os
from mathutils import Vector, Matrix


def P(x, fwd, up):
    """A point by (x, forward, up): Blender's forward is -Y (glTF exports it as +Z). The kid faces
    -Y, so +X is his LEFT: a side of +1 is his left hand and leg, -1 his right."""
    return Vector((x, -fwd, up))


# ---------------------------------------------------------------- materials
PALETTE = {}  # material name -> linear RGB; each model script fills in its own
_materials = {}


def material(name):
    if name not in _materials:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        r, g, b = PALETTE[name]
        bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.7 if name != "Metal" else 0.35
        bsdf.inputs["Metallic"].default_value = 0.6 if name == "Metal" else 0.0
        _materials[name] = m
    return _materials[name]


# ---------------------------------------------------------------- parts (each rigid on one bone)
PARTS = []


def finish(name, bm, mat, bone="root"):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(material(mat))
    vg = ob.vertex_groups.new(name=bone)
    vg.add(list(range(len(me.vertices))), 1.0, "REPLACE")
    PARTS.append(ob)
    return ob


def place(bm, matrix):
    bmesh.ops.transform(bm, matrix=matrix, verts=bm.verts)


def box(name, size, centre, mat, bone="root", bevel=0.0, tilt=0.0):
    """A box (right, forward, up sizes), bevelled for the kit's soft blocky look, tilted about X."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    place(bm, Matrix.Diagonal((size[0], size[1], size[2], 1.0)))
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, affect="EDGES", profile=0.5)
    place(bm, Matrix.Rotation(math.radians(tilt), 4, "X"))
    place(bm, Matrix.Translation(centre))
    return finish(name, bm, mat, bone)


def tube(name, a, b, radius, mat, bone="root", segments=8, radius2=None):
    """A round tube from a to b (radius2 tapers it)."""
    d = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                          radius2=radius if radius2 is None else radius2, depth=d.length)
    rot = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4()
    place(bm, rot)
    place(bm, Matrix.Translation((a + b) / 2))
    return finish(name, bm, mat, bone)


def disc(name, centre, radius, width, mat, bone="root", segments=16):
    """A cylinder across the bike (its axis along X): hubs, the chainring."""
    return tube(name, centre - Vector((width / 2, 0, 0)), centre + Vector((width / 2, 0, 0)), radius, mat, bone,
                segments)


def ball(name, centre, radius, mat, bone="root", scale=(1, 1, 1), segments=(16, 10), cut_below=None):
    """A sphere (or a dome), shaded smooth: the round parts are the ones whose facets show."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments[0], v_segments=segments[1], radius=radius)
    if cut_below is not None:  # a dome: drop the lower part
        doomed = [v for v in bm.verts if v.co.z < cut_below * radius - 1e-6]
        bmesh.ops.delete(bm, geom=doomed, context="VERTS")
    place(bm, Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0)))
    place(bm, Matrix.Translation(centre))
    ob = finish(name, bm, mat, bone)
    for poly in ob.data.polygons:
        poly.use_smooth = True
    return ob


def ring(name, centre, major, minor, mat, bone="root", major_segments=20, minor_segments=6):
    """A torus standing in the bike's plane (its axis along X): tyres and rims."""
    bm = bmesh.new()
    for i in range(major_segments):
        a = 2 * math.pi * i / major_segments
        for j in range(minor_segments):
            b = 2 * math.pi * j / minor_segments
            r = major + minor * math.cos(b)
            bm.verts.new((minor * math.sin(b), r * math.cos(a), r * math.sin(a)))
    bm.verts.ensure_lookup_table()
    for i in range(major_segments):
        for j in range(minor_segments):
            q = [((i + di) % major_segments) * minor_segments + (j + dj) % minor_segments
                 for di, dj in ((0, 0), (1, 0), (1, 1), (0, 1))]
            bm.faces.new([bm.verts[k] for k in q])
    place(bm, Matrix.Translation(centre))
    return finish(name, bm, mat, bone)


def reset():
    """An empty scene for the next model: no objects, no parts, no materials."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    PARTS.clear()
    _materials.clear()


def two_bone(root, target, l1, l2, bend):
    """The middle joint of a two-bone chain from root to target, bending toward `bend`."""
    d = target - root
    dist = min(d.length, l1 + l2 - 1e-4)
    dirn = d.normalized()
    a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
    h = math.sqrt(max(l1 * l1 - a * a, 0.0))
    side = (bend - dirn * bend.dot(dirn)).normalized()
    return root + dirn * a + side * h


def skin(rig, name):
    """The parts joined into one mesh named `name`, each still weighted wholly to its bone, and
    bound to the rig."""
    bpy.ops.object.select_all(action="DESELECT")
    for ob in PARTS:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = body.data.name = name
    body.parent = rig
    mod = body.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    return body


def export_rigged(path, rig, body):
    """The rig and its mesh as a glTF binary, every action in the file as a clip, at rest otherwise."""
    rig.animation_data_create()
    rig.animation_data.action = None
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_def_bones=True,
                              export_yup=True)


def turn_quat(rig, bone_name, axis, degrees):
    """A pose rotation turning the bone `degrees` about the world-rest `axis` (right-handed), given in
    the bone's own frame, as pose bones take it. Built from the bone's real axes, not guessed signs."""
    from mathutils import Quaternion
    rest = rig.data.bones[bone_name].matrix_local.to_3x3()
    return Quaternion(rest.inverted() @ Vector(axis).normalized(), math.radians(degrees))


# Turns in the figure's own terms (it faces -Y, +X its left, +Z up). PITCH about -X: a bone pointing
# forward lifts its tip, a bone pointing down swings its tip forward. YAW about +Z: turn to the left.
PITCH_AXIS, YAW_AXIS, ROLL_AXIS = (-1, 0, 0), (0, 0, 1), (0, -1, 0)


def export_static(path, name):
    """The parts joined into one mesh named `name`, written as a glTF binary (no rig, no clips)."""
    bpy.ops.object.select_all(action="DESELECT")
    for ob in PARTS:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = body.data.name = name
    body.vertex_groups.clear()  # the bones the parts were weighted to do not exist in a static model
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_animations=False,
                              export_skins=False, export_yup=True)
    return body


def studio(resolution=(640, 480)):
    """A plain sky, a sun and a camera for preview renders, in the engine's flat colours."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.device = "CPU"
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 2
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.62, 0.78, 0.95, 1)
    scene.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def shoot(cam, path, eye, target):
    """A preview render from `eye` looking at `target`."""
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
