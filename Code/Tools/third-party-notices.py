#!/usr/bin/env python3
"""THIRD-PARTY-NOTICES.txt: the licence of every third-party component a shipped binary can carry,
assembled from the licence files kept beside each component in Dependencies/.

Most of these licences (MIT, BSD, Apache, Zlib, the LLVM release licence) require their notice to
go with every copy, a binary one included. The file is committed at Dependencies/; the player, the
editor and the web player copy it beside their executables as they build, and an export template
carries it as a sidecar, so every exported game and template has it with no step of its own.

Left out: what never ships in a binary (the test frameworks), and GPUI (adapted shader code,
credited in its own source, with its licence in Dependencies/gpui/). A component added to
Dependencies/ that ships in a binary joins the list below, with its licence file kept beside it.

  python3 Code/Tools/third-party-notices.py           writes the file
  python3 Code/Tools/third-party-notices.py --check   fails when the committed file is stale
"""
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DEPENDENCIES = os.path.join(ROOT, "Dependencies")
OUTPUT = os.path.join(DEPENDENCIES, "THIRD-PARTY-NOTICES.txt")

# (name, where it comes from, the licence it is used under, its licence files relative to Dependencies/)
COMPONENTS = [
    ("SDL", "https://libsdl.org", "Zlib", ["SDL3-Beef/dist/SDL3-3.4.0/LICENSE.txt"]),
    ("Jolt Physics", "https://github.com/jrouwe/JoltPhysics", "MIT", ["joltc-Beef/JoltPhysics.LICENSE"]),
    ("joltc", "https://github.com/amerkoleci/joltc", "MIT", ["joltc-Beef/joltc/LICENSE"]),
    ("HarfBuzz", "https://github.com/harfbuzz/harfbuzz", "Old MIT (HarfBuzz's own name for it)", ["harfbuzz-Beef/harfbuzz/COPYING"]),
    ("SheenBidi", "https://github.com/Tehreer/SheenBidi", "Apache-2.0", ["sheenbidi-Beef/sheenbidi/LICENSE"]),
    ("meshoptimizer", "https://github.com/zeux/meshoptimizer", "MIT", ["meshoptimizer-Beef/meshoptimizer/LICENSE.md"]),
    ("Recast & Detour", "https://github.com/recastnavigation/recastnavigation", "Zlib",
     ["recastnavigation-Beef/recastnavigation-c/recastnavigation/License.txt"]),
    ("zlib", "https://zlib.net", "Zlib", ["zlib-Beef/zlib/LICENSE"]),
    ("Mbed TLS (with TF-PSA-Crypto)", "https://github.com/Mbed-TLS/mbedtls", "Apache-2.0 (chosen of Apache-2.0 OR GPL-2.0-or-later)",
     ["mbedtls-Beef/mbedtls/LICENSE"]),
    ("Dear ImGui (with cimgui)", "https://github.com/ocornut/imgui", "MIT", ["cimgui-Beef/cimgui/imgui/LICENSE.txt", "cimgui-Beef/cimgui/LICENSE"]),
    ("astc-encoder", "https://github.com/ARM-software/astc-encoder", "Apache-2.0", ["astcenc-Beef/astcenc/LICENSE.txt"]),
    ("msdfgen", "https://github.com/Chlumsky/msdfgen", "MIT", ["msdfgen-Beef/msdfgen/LICENSE.txt"]),
    ("bc7enc_rdo", "https://github.com/richgel999/bc7enc_rdo", "MIT (chosen of MIT OR Unlicense)", ["bc7enc-Beef/bc7enc/LICENSE"]),
    ("bcdec", "https://github.com/iOrange/bcdec", "MIT (chosen of MIT OR Unlicense)", ["bcdec-Beef/bcdec/LICENSE"]),
    ("cgltf (with jsmn)", "https://github.com/jkuhlmann/cgltf", "MIT", ["cgltf-Beef/cgltf/LICENSE"]),
    ("ufbx", "https://github.com/ufbx/ufbx", "MIT (chosen of MIT OR Unlicense)", ["ufbx-Beef/ufbx/LICENSE"]),
    ("stb (stb_image, stb_image_write, stb_truetype)", "https://github.com/nothings/stb", "MIT (chosen of MIT OR Unlicense)",
     ["stb_image-Beef/stb_image/LICENSE"]),
    ("miniaudio", "https://github.com/mackron/miniaudio", "MIT-0 (chosen of MIT-0 OR Unlicense)", ["miniaudio-Beef/miniaudio/LICENSE"]),
    ("wgpu-native", "https://github.com/gfx-rs/wgpu-native", "MIT (chosen of MIT OR Apache-2.0)", ["wgpu-Beef/LICENSE.MIT"]),
    ("Bulkan (Vulkan bindings)", "https://github.com/jayrulez/Bulkan", "MIT", ["Bulkan/LICENSE"]),
    ("DirectX Shader Compiler (editor and cook tools only)", "https://github.com/microsoft/DirectXShaderCompiler",
     "NCSA, with the notices of what it includes", ["Dxc-Beef/LICENSE.TXT", "Dxc-Beef/ThirdPartyNotices.txt"]),
]

RULE = "=" * 80


def assemble():
    parts = ["Third-party notices\n\nThis software includes the third-party components below. Each is listed with where it comes\n"
             "from and the licence it is used under, followed by that licence's text.\n"]
    missing = []
    for name, url, licence, files in COMPONENTS:
        parts.append("\n%s\n%s\n%s\nLicence: %s\n%s\n\n" % (RULE, name, url, licence, RULE))
        for relative in files:
            path = os.path.join(DEPENDENCIES, relative)
            if not os.path.isfile(path):
                missing.append("%s names %s, which is missing" % (name, relative))
                continue
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                body = f.read().replace("\r\n", "\n")
            parts.append(body if body.endswith("\n") else body + "\n")
    return "".join(parts), missing


def main():
    text, missing = assemble()
    if missing:
        for line in missing:
            print("third-party-notices: " + line, file=sys.stderr)
        return 1
    if "--check" in sys.argv[1:]:
        try:
            with open(OUTPUT, "r", encoding="utf-8") as f:
                current = f.read()
        except OSError:
            current = None
        if current != text:
            print("third-party-notices: %s is stale; run Code/Tools/third-party-notices.py" % OUTPUT, file=sys.stderr)
            return 1
        print("third-party-notices: current (%d components)" % len(COMPONENTS))
        return 0
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("third-party-notices: wrote %s (%d components)" % (OUTPUT, len(COMPONENTS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
