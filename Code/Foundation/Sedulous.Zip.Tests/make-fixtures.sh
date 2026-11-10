#!/usr/bin/env bash
# Makes the zips Sedulous.Zip.Tests and the editor's sample tests read, in Data/Tests/Zip, with the
# system's tools: Info-ZIP's zip for a project-shaped archive (deflated, stored and empty files,
# folders), one stored outright and a sample as a release packs it (sample.zip), and
# Python's zipfile for what zip refuses to make: a name outside the folder, a damaged entry, an
# archive with a comment, and entries with chosen Unix modes from a Unix and a DOS host; and for the
# project manager's tests, an engine SDK (sdk.zip) and a toolchain (toolchain.zip) as a release
# carries them. Run from the repository root; the zips are committed.
set -euo pipefail
out="$PWD/Data/Tests/Zip"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$out" "$work/Game/Scenes" "$work/Game/Audio"
printf '<Project name="Game"/>\n' > "$work/Game/Project.xml"
for i in $(seq 1 200); do echo "line $i of a scene that compresses well"; done > "$work/Game/Scenes/Level1.scene"
: > "$work/Game/Empty.txt"
head -c 3000 /dev/urandom > "$work/Game/Audio/noise.bin" # does not compress: zip stores it
(cd "$work" && rm -f "$out/project.zip" && TZ=UTC zip -q -X -r "$out/project.zip" Game)
(cd "$work" && rm -f "$out/stored.zip" && TZ=UTC zip -q -X -0 -r "$out/stored.zip" Game/Project.xml Game/Scenes)
# A release's sample as Raptor's pack-samples.py packs one: a real project's manifest at the root
# (the editor's Samples tab test downloads and probes it).
(cd Data/SampleProjects/ShaderGallery && rm -f "$out/sample.zip" && TZ=UTC zip -q -X "$out/sample.zip" Project.xml)
python3 -I - "$out" <<'PY'
import sys, zipfile, os
out = sys.argv[1]
with zipfile.ZipFile(os.path.join(out, "escape.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("Game/ok.txt", "fine")
    z.writestr("../outside.txt", "should never be written")
with zipfile.ZipFile(os.path.join(out, "commented.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("a.txt", "after a comment")
    z.comment = b"x" * 1000
# A deflated entry with one byte of its data flipped.
path = os.path.join(out, "damaged.zip")
with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("data.txt", "the same words again " * 50)
raw = bytearray(open(path, "rb").read())
raw[30 + len("data.txt") + 5] ^= 0xFF
open(path, "wb").write(bytes(raw))
# Unix modes in the entries' external attributes: an executable (0755) and a plain file (0644) from
# a Unix host, and one from a DOS host whose attributes carry 0755 too, which a reader must ignore.
with zipfile.ZipFile(os.path.join(out, "modes.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    for name, mode, system, data in (("bin/tool", 0o100755, 3, "#!/bin/sh\necho tool\n"),
                                     ("readme.txt", 0o100644, 3, "read me\n"),
                                     ("dos.txt", 0o100755, 0, "from DOS\n")):
        info = zipfile.ZipInfo(name, date_time=(2026, 11, 10, 12, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.create_system = system
        info.external_attr = mode << 16
        z.writestr(info, data)
# An engine SDK as a release carries one: sdk.json at its root, the startup libraries' projects the
# manager checks for, and its manager, an executable.
def entry(z, name, data, mode=0o100644):
    info = zipfile.ZipInfo(name, date_time=(2026, 11, 10, 12, 0, 0))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.create_system = 3
    info.external_attr = mode << 16
    z.writestr(info, data)
with zipfile.ZipFile(os.path.join(out, "sdk.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    entry(z, "sdk.json", '{"version": "0.2.0", "label": "beta", "display": "0.2.0-beta", "buildNumber": 3, '
                         '"platform": "Linux64", "beef": "fixture-pin", "created": "2026-11-10T12:00:00Z"}\n')
    for library in ("Code/Editor/Sedulous.Editor.Main", "Code/Engine/Sedulous.Engine.Player.DesktopMain",
                    "Code/Engine/Sedulous.Engine.Player.WebMain", "Code/Editor/Sedulous.Editor.McpMain",
                    "Code/Editor/Sedulous.Editor.CookMain", "Code/Editor/Sedulous.Editor.ExportMain"):
        entry(z, library + "/BeefProj.toml", "FileVersion = 1\n")
    entry(z, "ProjectManager/Sedulous.Tools.ProjectManager", "#!/bin/sh\n", 0o100755)
# A toolchain as a release carries one: BeefBuild (an executable) with the BeefConfig.toml that names
# its libraries, and corlib among them.
with zipfile.ZipFile(os.path.join(out, "toolchain.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    entry(z, "bin/BeefBuild", "#!/bin/sh\necho BeefBuild 0.43.6\n", 0o100755)
    entry(z, "bin/BeefConfig.toml", 'Version = 1\nUnversionedLibDirs = ["../BeefLibs"]\n')
    entry(z, "BeefLibs/corlib/BeefProj.toml", "FileVersion = 1\n")
PY
