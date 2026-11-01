#!/usr/bin/env bash
# Makes the zips Sedulous.Zip.Tests reads, in Data/Tests/Zip, with the system's tools: Info-ZIP's zip for a
# project-shaped archive (deflated, stored and empty files, folders) and one stored outright, and
# Python's zipfile for what zip refuses to make: a name outside the folder, a damaged entry, and an
# archive with a comment. Run from the repository root; the zips are committed.
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
PY
