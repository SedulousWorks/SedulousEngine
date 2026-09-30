#!/usr/bin/env bash
# Builds a Steam Deck player and packages it as an export template.
#
# A player built on this machine asks for the host's glibc (2.43), which SteamOS does not have.
# This builds it in an Ubuntu 22.04 container instead (glibc 2.35), with Beef itself built there
# from the fork's working branch, since that is the Beef the engine needs. Needs podman (or
# docker, as RT=docker).
#
#   Code/Tools/SteamDeck/build-steamdeck.sh
#
# Everything lives under build/steamdeck/ at the repository root:
#   beef/      the Beef clone, built in the container once per commit
#   src/       the copy of this repository the container builds, its dependency builds kept
#   out/       the player bundle, Release_Linux64/Sedulous.Engine.Player.Desktop
#   template/  that bundle as an export template, installed for this user
#
# Then export with a preset whose template is the Steam Deck one (its id is printed at the end).
#
#   Env: BEEF_REPO    the Beef to build (default: the fork on GitHub)
#        BEEF_BRANCH  its branch (default: working)
#        RT           podman or docker (default: the first found)
#        EXPORT_TOOL  the host's Sedulous.Tools.Export, which writes the template
#        JOBS         parallel C/C++ compiles for the dependencies (default: 6)
#        BEEF_THREADS BeefBuild's worker threads (default: 4; a Release build runs LLVM's
#                     optimiser on each, and one per core ran this machine out of memory)
#        MEMORY       the container's memory cap (default: 12g), so an overrun kills the build
#                     and not the rest of the desktop
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HERE="$ROOT/Code/Tools/SteamDeck"
STATE="$ROOT/build/steamdeck"
IMAGE="sedulous-steamdeck:22.04"
BEEF_REPO="${BEEF_REPO:-https://github.com/jayrulez/Beef.git}"
BEEF_BRANCH="${BEEF_BRANCH:-working}"
EXPORT_TOOL="${EXPORT_TOOL:-$ROOT/Code/build/Debug_Linux64/Sedulous.Tools.Export/Sedulous.Tools.Export}"
JOBS="${JOBS:-6}"
BEEF_THREADS="${BEEF_THREADS:-4}"
MEMORY="${MEMORY:-12g}"

RT="${RT:-}"
if [ -z "$RT" ]; then
	for c in podman docker; do command -v "$c" >/dev/null 2>&1 && { RT="$c"; break; }; done
fi
[ -n "$RT" ] || { echo "!! needs podman or docker" >&2; exit 1; }
mkdir -p "$STATE/out"

echo "== image $IMAGE ($RT) =="
"$RT" build -t "$IMAGE" -f "$HERE/Dockerfile" "$HERE"

echo "== Beef: $BEEF_REPO $BEEF_BRANCH =="
if [ -d "$STATE/beef/.git" ]; then
	git -C "$STATE/beef" fetch --quiet origin "$BEEF_BRANCH"
	git -C "$STATE/beef" checkout --quiet -B "$BEEF_BRANCH" FETCH_HEAD
else
	git clone --quiet --branch "$BEEF_BRANCH" "$BEEF_REPO" "$STATE/beef"
fi
git -C "$STATE/beef" log -1 --oneline

# The sources as git sees them (tracked and new, not ignored), uncommitted edits included, so
# none of the host's build output reaches the container. The copy keeps its own dependency
# builds between runs.
echo "== sources -> $STATE/src =="
mkdir -p "$STATE/src"
( cd "$ROOT" && git ls-files -z --cached --others --exclude-standard ) |
	rsync -a --from0 --files-from=- "$ROOT/" "$STATE/src/"

# Rootless podman maps this user to the container's root; docker needs to be told, or the
# state directory fills with root owned files.
USER_ARGS=()
[ "$RT" = "docker" ] && USER_ARGS=(--user "$(id -u):$(id -g)")
"$RT" run --rm "${USER_ARGS[@]}" \
	--memory "$MEMORY" --memory-swap "$MEMORY" \
	-e JOBS="$JOBS" -e BEEF_THREADS="$BEEF_THREADS" \
	-v "$STATE/beef":/beef:Z \
	-v "$STATE/src":/work:Z \
	-v "$STATE/out":/out:Z \
	"$IMAGE" bash /work/Code/Tools/SteamDeck/in-container-build.sh

# The template, written by the host's export tool so it is the format this engine reads. Its
# id is the Steam Deck's own, so it sits beside a desktop Linux template instead of replacing it.
BUNDLE="$STATE/out/Release_Linux64/Sedulous.Engine.Player.Desktop"
TEMPLATE="$STATE/template"
[ -x "$EXPORT_TOOL" ] || { echo "!! no export tool at $EXPORT_TOOL; build Sedulous.Tools.Export" >&2; exit 1; }
rm -rf "$TEMPLATE"
"$EXPORT_TOOL" --template create "$BUNDLE" --out "$TEMPLATE"
python3 - "$TEMPLATE/template.xml" <<'EOF'
import re, sys
path = sys.argv[1]
text = open(path).read()
def field(name, value):
	global text
	text, n = re.subn(r'<string name="%s"(?:/>|>[^<]*</string>)' % name,
		'<string name="%s">%s</string>' % (name, value), text, count=1)
	assert n == 1, name
version = re.search(r'<string name="engineVersion">([^<]*)</string>', text).group(1)
field("id", "sedulous-steamdeck-release-" + version)
field("name", "Steam Deck " + version)
field("notes", "Linux64 Release built for glibc 2.35 (Ubuntu 22.04), carrying its own SDL3.")
open(path, "w").write(text)
EOF
"$EXPORT_TOOL" --template import "$TEMPLATE"
echo
echo "== done =="
grep -oE "sedulous-steamdeck-release-[^<\"]*" "$TEMPLATE/template.xml" | head -1 | sed 's/^/template id: /'
