#!/usr/bin/env python3
"""
Parses a Unity .unity scene file and generates a Sedulous scene manifest XML.
Resolves compound/cluster prefabs into individual mesh entities with world transforms.

Usage:
    python generate_demo_scene.py <scene.unity> <pack_root> <output.xml>

Example:
    python generate_demo_scene.py "Demo 01.unity" "Snow Forest Pack Cute Series" "Demo01.scene.xml"
"""

import sys
import os
import re
import glob
import math

def build_guid_map(prefabs_dir):
    """Build a map from Unity GUID to prefab name by reading .meta files."""
    guid_map = {}
    for meta_path in glob.glob(os.path.join(prefabs_dir, '**', '*.prefab.meta'), recursive=True):
        with open(meta_path, 'r') as f:
            for line in f:
                m = re.match(r'guid:\s*([a-f0-9]+)', line)
                if m:
                    name = os.path.splitext(os.path.basename(meta_path.replace('.meta', '')))[0]
                    guid_map[m.group(1)] = name
                    break
    return guid_map

def build_fbx_guid_map(fbx_dir):
    """Build a map from FBX GUID to mesh name."""
    guid_map = {}
    for meta_path in glob.glob(os.path.join(fbx_dir, '*.FBX.meta')):
        with open(meta_path, 'r') as f:
            for line in f:
                m = re.match(r'guid:\s*([a-f0-9]+)', line)
                if m:
                    name = os.path.splitext(os.path.basename(meta_path.replace('.meta', '')))[0]
                    guid_map[m.group(1)] = name
                    break
    return guid_map

def build_mat_guid_map(mat_dir):
    """Build a map from material GUID to material name."""
    guid_map = {}
    for meta_path in glob.glob(os.path.join(mat_dir, '*.mat.meta')):
        with open(meta_path, 'r') as f:
            for line in f:
                m = re.match(r'guid:\s*([a-f0-9]+)', line)
                if m:
                    name = os.path.splitext(os.path.basename(meta_path.replace('.meta', '')))[0]
                    guid_map[m.group(1)] = name
                    break
    return guid_map

# -- Quaternion math --

def quat_mul(a, b):
    """Multiply two quaternions (x, y, z, w)."""
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return [
        aw*bx + ax*bw + ay*bz - az*by,
        aw*by - ax*bz + ay*bw + az*bx,
        aw*bz + ax*by - ay*bx + az*bw,
        aw*bw - ax*bx - ay*by - az*bz,
    ]

def quat_rotate(q, v):
    """Rotate vector v by quaternion q."""
    qx, qy, qz, qw = q
    vx, vy, vz = v
    # q * v * q^-1 (for unit quaternions, q^-1 = conjugate)
    t = [2*(qy*vz - qz*vy) + 2*qw*vx + 0*vy + 0*vz,
         2*(qz*vx - qx*vz) + 0*vx + 2*qw*vy + 0*vz,
         2*(qx*vy - qy*vx) + 0*vx + 0*vy + 2*qw*vz]
    # Simplified: result = v + 2*w*(cross(q.xyz, v)) + 2*(cross(q.xyz, cross(q.xyz, v)))
    cx = qy*vz - qz*vy
    cy = qz*vx - qx*vz
    cz = qx*vy - qy*vx
    return [
        vx + 2*(qw*cx + qy*cz - qz*cy),
        vy + 2*(qw*cy + qz*cx - qx*cz),
        vz + 2*(qw*cz + qx*cy - qy*cx),
    ]

def transform_combine(parent_pos, parent_rot, parent_scale, child_pos, child_rot, child_scale):
    """Combine parent and child transforms: parent * child."""
    # Scale child position by parent scale, rotate by parent rotation, add parent position
    scaled = [child_pos[i] * parent_scale[i] for i in range(3)]
    rotated = quat_rotate(parent_rot, scaled)
    pos = [parent_pos[i] + rotated[i] for i in range(3)]
    rot = quat_mul(parent_rot, child_rot)
    scale = [parent_scale[i] * child_scale[i] for i in range(3)]
    return pos, rot, scale


def extract_modifications(doc):
    """Extract transform from modification block."""
    pos = [0.0, 0.0, 0.0]
    rot = [0.0, 0.0, 0.0, 1.0]
    scale = [1.0, 1.0, 1.0]
    name = None

    for m in re.finditer(
        r'propertyPath:\s*(m_Local\w+\.\w+)\s*\n\s*value:\s*([^\n]+)', doc):
        prop = m.group(1)
        val = float(m.group(2))

        if prop == 'm_LocalPosition.x': pos[0] = val
        elif prop == 'm_LocalPosition.y': pos[1] = val
        elif prop == 'm_LocalPosition.z': pos[2] = val
        elif prop == 'm_LocalRotation.x': rot[0] = val
        elif prop == 'm_LocalRotation.y': rot[1] = val
        elif prop == 'm_LocalRotation.z': rot[2] = val
        elif prop == 'm_LocalRotation.w': rot[3] = val
        elif prop == 'm_LocalScale.x': scale[0] = val
        elif prop == 'm_LocalScale.y': scale[1] = val
        elif prop == 'm_LocalScale.z': scale[2] = val

    name_match = re.search(r'propertyPath:\s*m_Name\s*\n\s*value:\s*([^\n]+)', doc)
    if name_match:
        name = name_match.group(1)

    return pos, rot, scale, name


def parse_prefab_instances(content):
    """Parse PrefabInstance blocks from a Unity YAML file."""
    instances = []
    docs = re.split(r'^---.*$', content, flags=re.MULTILINE)

    for doc in docs:
        if 'PrefabInstance:' not in doc:
            continue

        source_match = re.search(r'm_SourcePrefab:.*?guid:\s*([a-f0-9]+)', doc)
        if not source_match:
            continue

        guid = source_match.group(1)
        pos, rot, scale, name = extract_modifications(doc)

        instances.append({
            'guid': guid,
            'name': name,
            'position': pos,
            'rotation': rot,
            'scale': scale,
        })

    return instances


# Set of "simple" (single-mesh) prefabs that map directly to our imported assets
SIMPLE_PREFABS = {
    'Brick 01', 'Bridge 01 Mid', 'Bridge 01 Pole',
    'Fence 01 Barrier 01', 'Fence 01 Pole', 'Gate 02',
    'Ground 01', 'Leaf 01', 'Leaf 02', 'Leaf 03',
    'Magical Gate 01', 'Pillar 01', 'Pillar 02',
    'Rock 01', 'Snow Clump 01', 'Snow Rock 01', 'Snow Rock 02',
    'Step 01', 'Step 02', 'Step 03', 'Stone Monument 01',
    'Tree 01', 'Tree 02', 'Wall 01', 'Wall 02',
}


def resolve_prefab(prefab_name, prefab_dir, guid_map, fbx_guid_map, mat_guid_map, resolved_cache):
    """
    Resolve a prefab into a list of (mesh_name, material_name, local_pos, local_rot, local_scale).
    For simple prefabs, returns one entry at identity transform.
    For compound prefabs, resolves nested instances.
    """
    if prefab_name in resolved_cache:
        return resolved_cache[prefab_name]

    # Check if it's a simple prefab (direct mesh)
    if prefab_name in SIMPLE_PREFABS:
        # Find which material it uses
        prefab_path = None
        for p in glob.glob(os.path.join(prefab_dir, '**', f'{prefab_name}.prefab'), recursive=True):
            prefab_path = p
            break

        material = 'Snow Forest'  # default
        if prefab_path:
            with open(prefab_path, 'r') as f:
                content = f.read()
            mat_match = re.search(r'm_Materials:\s*\n\s*-\s*\{.*?guid:\s*([a-f0-9]+)', content)
            if mat_match:
                mat_guid = mat_match.group(1)
                material = mat_guid_map.get(mat_guid, 'Snow Forest')

        result = [(prefab_name, material, [0,0,0], [0,0,0,1], [1,1,1])]
        resolved_cache[prefab_name] = result
        return result

    # Compound prefab — find and parse it
    prefab_path = None
    for p in glob.glob(os.path.join(prefab_dir, '**', f'{prefab_name}.prefab'), recursive=True):
        prefab_path = p
        break

    if not prefab_path:
        print(f'  WARNING: Cannot find prefab file for "{prefab_name}"')
        resolved_cache[prefab_name] = []
        return []

    with open(prefab_path, 'r') as f:
        content = f.read()

    # Check if it has nested PrefabInstances
    nested = parse_prefab_instances(content)
    if not nested:
        # It might be a simple mesh prefab we didn't know about
        # Check for MeshFilter/MeshRenderer
        mesh_match = re.search(r'm_Mesh:.*?guid:\s*([a-f0-9]+)', content)
        if mesh_match:
            mesh_name = fbx_guid_map.get(mesh_match.group(1), prefab_name)
            mat_match = re.search(r'm_Materials:\s*\n\s*-\s*\{.*?guid:\s*([a-f0-9]+)', content)
            material = mat_guid_map.get(mat_match.group(1), 'Snow Forest') if mat_match else 'Snow Forest'
            result = [(mesh_name, material, [0,0,0], [0,0,0,1], [1,1,1])]
            resolved_cache[prefab_name] = result
            return result
        resolved_cache[prefab_name] = []
        return []

    # Compound prefab: may have its own mesh PLUS nested prefab instances
    result = []

    # Include the parent's own mesh (e.g. tree trunk) if present.
    # We need to find the MeshRenderer that has the actual mesh, and get
    # its material — not a child particle system's material.
    # Split into YAML documents and find the MeshRenderer with a valid m_Mesh.
    prefab_docs = re.split(r'^---.*$', content, flags=re.MULTILINE)
    for pdoc in prefab_docs:
        mesh_match = re.search(r'm_Mesh:.*?guid:\s*([a-f0-9]+)', pdoc)
        if not mesh_match:
            continue
        # Skip if this is a ParticleSystemRenderer (not a MeshRenderer)
        if 'ParticleSystem' in pdoc or 'ParticleSystemRenderer' in pdoc:
            continue
        mesh_name = fbx_guid_map.get(mesh_match.group(1), prefab_name)
        # Find the corresponding MeshRenderer's material in the same or nearby doc
        # Look for MeshRenderer doc that references the same GameObject
        go_match = re.search(r'm_GameObject:\s*\{fileID:\s*(\d+)', pdoc)
        material = 'Snow Forest'
        if go_match:
            go_id = go_match.group(1)
            # Find the MeshRenderer doc for this GameObject
            for rdoc in prefab_docs:
                if 'MeshRenderer' not in rdoc:
                    continue
                if f'm_GameObject: {{fileID: {go_id}}}' in rdoc:
                    mat_match = re.search(r'm_Materials:\s*\n\s*-\s*\{.*?guid:\s*([a-f0-9]+)', rdoc)
                    if mat_match:
                        material = mat_guid_map.get(mat_match.group(1), 'Snow Forest')
                    break
        result.append((mesh_name, material, [0,0,0], [0,0,0,1], [1,1,1]))
        break  # Only take the first valid mesh

    # Resolve nested instances (e.g. leaves)
    for inst in nested:
        child_name = guid_map.get(inst['guid'])
        if not child_name:
            continue
        child_entries = resolve_prefab(child_name, prefab_dir, guid_map, fbx_guid_map, mat_guid_map, resolved_cache)
        for mesh_name, material, cpos, crot, cscale in child_entries:
            # Combine child transform with instance transform
            pos, rot, scale = transform_combine(
                inst['position'], inst['rotation'], inst['scale'],
                cpos, crot, cscale)
            result.append((mesh_name, material, pos, rot, scale))

    resolved_cache[prefab_name] = result
    return result


def parse_scene(scene_path, guid_map, prefab_dir, fbx_guid_map, mat_guid_map):
    """Parse Unity scene and resolve all prefab instances to mesh entities."""
    with open(scene_path, 'r', encoding='utf-8') as f:
        content = f.read()

    scene_instances = parse_prefab_instances(content)
    resolved_cache = {}
    entities = []

    # 90-degree rotation around X axis (Unity Z-up FBX correction)
    half = math.radians(90) / 2
    rot_x90 = [math.sin(half), 0, 0, math.cos(half)]

    for i, inst in enumerate(scene_instances):
        prefab_name = guid_map.get(inst['guid'])
        if not prefab_name:
            continue

        mesh_entries = resolve_prefab(prefab_name, prefab_dir, guid_map, fbx_guid_map, mat_guid_map, resolved_cache)
        if not mesh_entries:
            print(f'  Skipping unresolved prefab: {prefab_name}')
            continue

        for mesh_name, material, local_pos, local_rot, local_scale in mesh_entries:
            # Combine with scene instance transform
            pos, rot, scale = transform_combine(
                inst['position'], inst['rotation'], inst['scale'],
                local_pos, local_rot, local_scale)

            # Apply 90-degree X rotation correction per entity
            rot = quat_mul(rot, rot_x90)

            entity_name = inst['name'] or f'{prefab_name}_{i}'

            entities.append({
                'name': entity_name,
                'mesh': mesh_name,
                'material': material,
                'position': pos,
                'rotation': rot,
                'scale': scale,
            })

    return entities


def write_scene_xml(entities, output_path, scene_name):
    """Write scene manifest XML."""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n')
        f.write(f'<SceneManifest name="{scene_name}">\n')

        for ent in entities:
            pos = ent['position']
            rot = ent['rotation']
            scale = ent['scale']

            f.write(f'    <Entity name="{ent["name"]}" mesh="{ent["mesh"]}" material="{ent["material"]}"')
            f.write(f' px="{pos[0]:.6f}" py="{pos[1]:.6f}" pz="{pos[2]:.6f}"')
            f.write(f' rx="{rot[0]:.6f}" ry="{rot[1]:.6f}" rz="{rot[2]:.6f}" rw="{rot[3]:.6f}"')
            if any(abs(s - 1.0) > 0.0001 for s in scale):
                f.write(f' sx="{scale[0]:.6f}" sy="{scale[1]:.6f}" sz="{scale[2]:.6f}"')
            f.write('/>\n')

        f.write('</SceneManifest>\n')

    print(f'Written {len(entities)} entities to {output_path}')


def main():
    if len(sys.argv) < 4:
        print(f'Usage: {sys.argv[0]} <scene.unity> <pack_root> <output.xml>')
        sys.exit(1)

    scene_path = sys.argv[1]
    pack_root = sys.argv[2]
    output_path = sys.argv[3]
    scene_name = os.path.splitext(os.path.basename(scene_path))[0]

    prefab_dir = os.path.join(pack_root, 'Prefabs')
    fbx_dir = os.path.join(pack_root, 'FBX')
    mat_dir = os.path.join(pack_root, 'Materials')

    print(f'Building GUID maps...')
    guid_map = build_guid_map(prefab_dir)
    fbx_guid_map = build_fbx_guid_map(fbx_dir)
    mat_guid_map = build_mat_guid_map(mat_dir)
    print(f'  Prefabs: {len(guid_map)}, FBX: {len(fbx_guid_map)}, Materials: {len(mat_guid_map)}')

    print(f'Parsing scene {scene_path}...')
    entities = parse_scene(scene_path, guid_map, prefab_dir, fbx_guid_map, mat_guid_map)

    # Count unique meshes and materials
    meshes = set(e['mesh'] for e in entities)
    mats = set(e['material'] for e in entities)
    print(f'  Resolved to {len(entities)} mesh entities')
    print(f'  Unique meshes: {len(meshes)}: {", ".join(sorted(meshes))}')
    print(f'  Unique materials: {len(mats)}: {", ".join(sorted(mats))}')

    write_scene_xml(entities, output_path, scene_name)


if __name__ == '__main__':
    main()
