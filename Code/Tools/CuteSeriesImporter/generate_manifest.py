"""
Scans CuteSeries directory and generates CuteSeriesManifest.xml.
Parses Unity .mat files for texture assignments and emission colors.
Run: python generate_manifest.py
"""

import os
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom

CUTE_DIR = "D:/Dev/Beef/BeefGFX/CuteSeries"
OUT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "CuteSeriesManifest.xml")


def main():
    root = ET.Element("ImportManifest")
    root.set("sourceRoot", CUTE_DIR)

    # Monster packs (01-09)
    for pack_num in range(1, 10):
        pack_name = f"Monsters Ultimate Pack {pack_num:02d} Cute Series"
        pack_dir = os.path.join(CUTE_DIR, pack_name)
        if not os.path.isdir(pack_dir):
            continue

        pack_el = ET.SubElement(root, "Pack")
        pack_el.set("name", f"Monsters Ultimate Pack {pack_num:02d}")
        pack_el.set("type", "monsters")
        pack_el.set("sourceDir", pack_name)
        pack_el.set("outputDir", f"Units/Pack{pack_num:02d}")

        assets = sorted([d for d in os.listdir(pack_dir)
                         if os.path.isdir(os.path.join(pack_dir, d)) and not d.endswith(".meta")])

        for asset_folder in assets:
            process_monster_asset(pack_el, pack_dir, asset_folder)

    # Environment packs
    env_packs = [
        "100 Eggs Pack Cute Series",
        "Desert Pack Cute Series",
        "Dungeon Cute Series",
        "Snow Forest Pack Cute Series",
        "Sci Fi Hexagon Battlefields Cute Series",
    ]
    for env_name in env_packs:
        env_dir = os.path.join(CUTE_DIR, env_name)
        if not os.path.isdir(env_dir):
            continue
        process_environment_pack(root, env_name, env_dir)

    root.append(ET.Comment(" Icons For Monsters Ultimate Pack 02 - PNG icons only, skip for 3D import "))

    # Write
    xml_str = minidom.parseString(ET.tostring(root, encoding="unicode")).toprettyxml(indent="    ")
    lines = xml_str.split("\n")
    xml_str = "\n".join(lines[1:])
    output = '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_str

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write(output)

    pack_count = len(root.findall("Pack"))
    asset_count = len(root.findall(".//Asset"))
    clip_count = len(root.findall(".//Clip"))
    print(f"Generated manifest: {pack_count} packs, {asset_count} assets, {clip_count} animation clips")
    print(f"Written to: {OUT_PATH}")


def parse_unity_material(mat_path):
    """Parse a Unity .mat YAML file and extract PBR properties.

    Unity Standard Shader -> our PBR mapping:
      _MainTex        -> AlbedoMap
      _BumpMap         -> NormalMap
      _MetallicGlossMap -> MetallicRoughnessMap
      _OcclusionMap    -> OcclusionMap
      _EmissionMap     -> EmissiveMap
      _Color           -> BaseColor
      _EmissionColor   -> EmissiveColor
      _Metallic        -> Metallic
      _Glossiness      -> Roughness (1 - glossiness)
      _OcclusionStrength -> AO
      _Cutoff          -> AlphaCutoff
    """
    info = {
        "has_emission": False,
        "textures": {},    # slot_name -> True (has texture assigned)
        "base_color": None,
        "emission_color": None,
        "metallic": None,
        "roughness": None,  # already inverted from glossiness
        "ao": None,
        "alpha_cutoff": None,
        "blend_mode": "opaque",  # opaque, cutout, fade, transparent
        "double_sided": False,
    }

    if not os.path.isfile(mat_path):
        return info

    with open(mat_path, "r", errors="replace") as f:
        content = f.read()

    # Check for _EMISSION keyword
    if "_EMISSION" in content:
        info["has_emission"] = True

    # Check texture slots (Unity name -> our slot name)
    tex_mapping = {
        "_MainTex": "AlbedoMap",
        "_BumpMap": "NormalMap",
        "_MetallicGlossMap": "MetallicRoughnessMap",
        "_OcclusionMap": "OcclusionMap",
        "_EmissionMap": "EmissiveMap",
    }
    for unity_name, our_slot in tex_mapping.items():
        pattern = rf"{re.escape(unity_name)}:\s*\n\s*m_Texture:\s*\{{fileID:\s*(\d+)"
        match = re.search(pattern, content)
        if match and match.group(1) != "0":
            info["textures"][our_slot] = True

    # Extract colors
    def parse_color(name):
        pattern = rf"{re.escape(name)}:\s*\{{r:\s*([\d.e+-]+),\s*g:\s*([\d.e+-]+),\s*b:\s*([\d.e+-]+),\s*a:\s*([\d.e+-]+)\}}"
        m = re.search(pattern, content)
        if m:
            return (float(m.group(1)), float(m.group(2)),
                    float(m.group(3)), float(m.group(4)))
        return None

    info["base_color"] = parse_color("_Color")
    info["emission_color"] = parse_color("_EmissionColor")

    # Extract floats
    def parse_float(name):
        pattern = rf"- {re.escape(name)}:\s*([\d.e+-]+)"
        m = re.search(pattern, content)
        return float(m.group(1)) if m else None

    metallic = parse_float("_Metallic")
    if metallic is not None:
        info["metallic"] = metallic

    glossiness = parse_float("_Glossiness")
    if glossiness is not None:
        info["roughness"] = 1.0 - glossiness  # Unity glossiness -> our roughness

    ao = parse_float("_OcclusionStrength")
    if ao is not None:
        info["ao"] = ao

    cutoff = parse_float("_Cutoff")
    if cutoff is not None:
        info["alpha_cutoff"] = cutoff

    # Blend mode: Unity _Mode (0=Opaque, 1=Cutout, 2=Fade, 3=Transparent)
    mode = parse_float("_Mode")
    if mode is not None:
        mode_map = {0: "opaque", 1: "cutout", 2: "fade", 3: "transparent"}
        info["blend_mode"] = mode_map.get(int(mode), "opaque")

    # Double-sided: Unity _Cull (0=Off/DoubleSided, 1=Front, 2=Back/default)
    cull = parse_float("_Cull")
    if cull is not None and int(cull) == 0:
        info["double_sided"] = True

    return info


def process_monster_asset(pack_el, pack_dir, asset_folder):
    asset_path = os.path.join(pack_dir, asset_folder)
    fbx_dir = os.path.join(asset_path, "FBX")
    tex_dir = os.path.join(asset_path, "Textures")
    mat_dir = os.path.join(asset_path, "Materials")
    anim_dir = os.path.join(asset_path, "Animations")

    if not os.path.isdir(fbx_dir):
        return

    is_modular = os.path.isdir(anim_dir) and any(
        f.upper().endswith(".FBX") for f in os.listdir(anim_dir)
    )

    # Derive asset name
    asset_name = asset_folder
    for suffix in [" Modular Pack Cute Series", " Cute Series"]:
        if asset_name.endswith(suffix):
            asset_name = asset_name[:-len(suffix)]
            break

    asset_el = ET.SubElement(pack_el, "Asset")
    asset_el.set("name", asset_name)
    asset_el.set("sourceFolder", asset_folder)
    if is_modular:
        asset_el.set("type", "modular")
        asset_el.append(ET.Comment(
            " REVIEW: Modular character. May need special handling for equipment parts. "))

    # FBX files
    fbx_files = [f for f in os.listdir(fbx_dir) if f.upper().endswith(".FBX")]
    base_fbx = sorted([f for f in fbx_files if "@" not in f])
    anim_fbx = sorted([f for f in fbx_files if "@" in f])

    if is_modular:
        mod_files = [f for f in os.listdir(anim_dir) if f.upper().endswith(".FBX")]
        anim_fbx = sorted([f for f in mod_files if "@" in f])

    # Base mesh
    for bf in base_fbx:
        mesh_el = ET.SubElement(asset_el, "Mesh")
        mesh_el.set("file", f"FBX/{bf}")

    # Parse Unity material for texture/color info
    mat_files = []
    if os.path.isdir(mat_dir):
        mat_files = [f for f in os.listdir(mat_dir)
                     if f.endswith(".mat") and not f.endswith(".meta")]

    mat_info = {}
    if mat_files:
        mat_info = parse_unity_material(os.path.join(mat_dir, mat_files[0]))

    # Material element with PBR properties from Unity .mat
    mat_el = ET.SubElement(asset_el, "Material")

    # Blend mode and render state
    blend = mat_info.get("blend_mode", "opaque")
    if blend != "opaque":
        mat_el.set("blendMode", blend)
    if mat_info.get("double_sided"):
        mat_el.set("doubleSided", "true")
    if mat_info.get("has_emission"):
        mat_el.set("emissive", "true")

    # Textures from the Textures/ folder, mapped to slots using Unity .mat info
    if os.path.isdir(tex_dir):
        tex_files = sorted([f for f in os.listdir(tex_dir) if not f.endswith(".meta")])
        for tf in tex_files:
            tex_el = ET.SubElement(mat_el, "Texture")
            tex_el.set("file", f"Textures/{tf}")
            lower = tf.lower()
            if "emission" in lower or "emissive" in lower:
                tex_el.set("slot", "EmissiveMap")
            elif "normal" in lower or "bump" in lower:
                tex_el.set("slot", "NormalMap")
            elif "metallic" in lower or "roughness" in lower:
                tex_el.set("slot", "MetallicRoughnessMap")
            elif "occlusion" in lower or "ao" in lower:
                tex_el.set("slot", "OcclusionMap")
            else:
                tex_el.set("slot", "AlbedoMap")

    # PBR float properties
    if mat_info.get("metallic") is not None:
        prop_el = ET.SubElement(mat_el, "Float")
        prop_el.set("name", "Metallic")
        prop_el.set("value", f"{mat_info['metallic']:.6f}")

    if mat_info.get("roughness") is not None:
        prop_el = ET.SubElement(mat_el, "Float")
        prop_el.set("name", "Roughness")
        prop_el.set("value", f"{mat_info['roughness']:.6f}")

    if mat_info.get("ao") is not None and mat_info["ao"] != 1.0:
        prop_el = ET.SubElement(mat_el, "Float")
        prop_el.set("name", "AO")
        prop_el.set("value", f"{mat_info['ao']:.6f}")

    if mat_info.get("alpha_cutoff") is not None and mat_info["alpha_cutoff"] != 0.0:
        prop_el = ET.SubElement(mat_el, "Float")
        prop_el.set("name", "AlphaCutoff")
        prop_el.set("value", f"{mat_info['alpha_cutoff']:.6f}")

    # Color properties
    if mat_info.get("base_color"):
        bc = mat_info["base_color"]
        if bc != (1.0, 1.0, 1.0, 1.0):
            color_el = ET.SubElement(mat_el, "Color")
            color_el.set("name", "BaseColor")
            color_el.set("r", f"{bc[0]:.6f}")
            color_el.set("g", f"{bc[1]:.6f}")
            color_el.set("b", f"{bc[2]:.6f}")
            color_el.set("a", f"{bc[3]:.6f}")

    if mat_info.get("has_emission") and mat_info.get("emission_color"):
        ec = mat_info["emission_color"]
        color_el = ET.SubElement(mat_el, "Color")
        color_el.set("name", "EmissiveColor")
        color_el.set("r", f"{ec[0]:.6f}")
        color_el.set("g", f"{ec[1]:.6f}")
        color_el.set("b", f"{ec[2]:.6f}")
        color_el.set("a", f"{ec[3]:.6f}")

    # Animations
    if anim_fbx:
        anims_el = ET.SubElement(asset_el, "Animations")
        if is_modular:
            anims_el.set("sourceFolder", "Animations")

        for af in anim_fbx:
            at_idx = af.index("@")
            clip_name = os.path.splitext(af[at_idx + 1:])[0]

            anim_el = ET.SubElement(anims_el, "Clip")
            folder = "Animations" if is_modular else "FBX"
            anim_el.set("file", f"{folder}/{af}")
            anim_el.set("name", clip_name)

    # Controller -> AnimGraph
    ctrl_dir = anim_dir if is_modular else fbx_dir
    if os.path.isdir(ctrl_dir):
        controller_files = [f for f in os.listdir(ctrl_dir)
                           if f.endswith(".controller") and not f.endswith(".meta")]
        for cf in controller_files:
            folder = "Animations" if is_modular else "FBX"
            ctrl_el = ET.SubElement(asset_el, "AnimGraph")
            ctrl_el.set("fromController", f"{folder}/{cf}")

    # Prefab
    prefab_el = ET.SubElement(asset_el, "Prefab")
    prefab_el.set("generate", "true")


def process_environment_pack(root, env_name, env_dir):
    short_name = env_name.replace(" Cute Series", "")

    pack_el = ET.SubElement(root, "Pack")
    pack_el.set("name", short_name)
    pack_el.set("type", "environment")
    pack_el.set("sourceDir", env_name)
    pack_el.set("outputDir", f"Environment/{short_name.replace(' ', '')}")

    fbx_dir = os.path.join(env_dir, "FBX")
    if not os.path.isdir(fbx_dir):
        return

    fbx_files = sorted([f for f in os.listdir(fbx_dir)
                        if f.upper().endswith(".FBX") and not f.endswith(".meta")])

    for bf in fbx_files:
        if "@" in bf:
            at_idx = bf.index("@")
            base = bf[:at_idx]
            clip = os.path.splitext(bf[at_idx + 1:])[0]
            anim_el = ET.SubElement(pack_el, "Animation")
            anim_el.set("base", base)
            anim_el.set("file", f"FBX/{bf}")
            anim_el.set("clipName", clip)
        else:
            mesh_name = os.path.splitext(bf)[0]
            asset_el = ET.SubElement(pack_el, "Asset")
            asset_el.set("name", mesh_name)
            mesh_el = ET.SubElement(asset_el, "Mesh")
            mesh_el.set("file", f"FBX/{bf}")

    # Environment textures
    tex_dir = os.path.join(env_dir, "Textures")
    if os.path.isdir(tex_dir):
        tex_files = sorted([f for f in os.listdir(tex_dir) if not f.endswith(".meta")])
        if tex_files:
            tex_group = ET.SubElement(pack_el, "SharedTextures")
            for tf in tex_files:
                tex_el = ET.SubElement(tex_group, "Texture")
                tex_el.set("file", f"Textures/{tf}")

    # Environment materials
    mat_dir = os.path.join(env_dir, "Materials")
    if os.path.isdir(mat_dir):
        mat_files = [f for f in os.listdir(mat_dir)
                     if f.endswith(".mat") and not f.endswith(".meta")]
        for mf in mat_files:
            mat_info = parse_unity_material(os.path.join(mat_dir, mf))
            if mat_info.get("has_emission"):
                mat_name = os.path.splitext(mf)[0]
                note = ET.SubElement(pack_el, "EmissiveMaterial")
                note.set("name", mat_name)
                if mat_info.get("emission_color"):
                    ec = mat_info["emission_color"]
                    note.set("color", f"{ec[0]:.3f},{ec[1]:.3f},{ec[2]:.3f},{ec[3]:.3f}")


if __name__ == "__main__":
    main()
