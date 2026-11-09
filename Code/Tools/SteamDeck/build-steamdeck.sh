#!/usr/bin/env bash
# Builds a game's player for the Steam Deck: an export of a preset whose builder is SteamDeck
# runs this, and ships the bundle it stages.
#
# A player built on this machine asks for the host's glibc (2.43), which SteamOS does not have.
# This builds it in an Ubuntu 22.04 container instead (glibc 2.35), with Beef itself built there
# from the fork's working branch, since that is the Beef the engine needs. Needs podman (or
# docker, as RT=docker).
#
#   Code/Tools/SteamDeck/build-steamdeck.sh --workspace <dir> --project <Game>Player
#       [--config ShippingRelease] [--out <bundle dir>]
#
# --workspace is a project's Beef workspace (its Code/), generated for the SDK as the container
# mounts it, at /work: the export copies the project under build/steamdeck/projects/<Game> and
# generates it there. The workspace's project folder is mounted at the same path inside the
# container, so what it names of itself holds there too. --project is the executable to build
# in it, and --out the folder the bundle is staged in (default:
# build/steamdeck/out/<Config>_Linux64/<project>).
#
# Everything else lives under build/steamdeck/ at the repository root:
#   beef/      the Beef clone, built in the container once per commit
#   src/       the copy of this repository the container builds against (/work), its
#              dependency builds kept
#   projects/  the projects' copies an export generates
#   out/       the bundles
#
#   Env: BEEF_REPO    the Beef to build (default: the fork on GitHub)
#        BEEF_BRANCH  its branch (default: working)
#        RT           podman or docker (default: the first found)
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
JOBS="${JOBS:-6}"
BEEF_THREADS="${BEEF_THREADS:-4}"
MEMORY="${MEMORY:-12g}"

usage() { echo "usage: $0 --workspace <dir> --project <name> [--config <config>] [--out <dir>]" >&2; exit 2; }
WORKSPACE=""
PROJECT=""
CONFIG="ShippingRelease"
OUT=""
while [ $# -gt 0 ]; do
	case "$1" in
		--workspace) [ $# -ge 2 ] || usage; WORKSPACE="$2"; shift 2 ;;
		--project) [ $# -ge 2 ] || usage; PROJECT="$2"; shift 2 ;;
		--config) [ $# -ge 2 ] || usage; CONFIG="$2"; shift 2 ;;
		--out) [ $# -ge 2 ] || usage; OUT="$2"; shift 2 ;;
		*) usage ;;
	esac
done
[ -n "$WORKSPACE" ] && [ -n "$PROJECT" ] || usage
[ -f "$WORKSPACE/BeefSpace.toml" ] || { echo "!! no Beef workspace at $WORKSPACE" >&2; exit 1; }
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
# The project the workspace is in: its packages outside Code/ (Plugins/) are reached from it.
PROJECT_DIR="$(dirname "$WORKSPACE")"
OUT="${OUT:-$STATE/out/${CONFIG}_Linux64/$PROJECT}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
OUT_PARENT="$(dirname "$OUT")"

RT="${RT:-}"
if [ -z "$RT" ]; then
	for c in podman docker; do command -v "$c" >/dev/null 2>&1 && { RT="$c"; break; }; done
fi
[ -n "$RT" ] || { echo "!! needs podman or docker" >&2; exit 1; }

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
echo "== $PROJECT ($CONFIG) from $WORKSPACE =="
"$RT" run --rm "${USER_ARGS[@]}" \
	--memory "$MEMORY" --memory-swap "$MEMORY" \
	-e JOBS="$JOBS" -e BEEF_THREADS="$BEEF_THREADS" \
	-e WORKSPACE="$WORKSPACE" -e PROJECT="$PROJECT" -e CONFIG="$CONFIG" -e BUNDLE="$OUT" \
	-v "$STATE/beef":/beef:Z \
	-v "$STATE/src":/work:Z \
	-v "$PROJECT_DIR":"$PROJECT_DIR":Z \
	-v "$OUT_PARENT":"$OUT_PARENT":Z \
	"$IMAGE" bash /work/Code/Tools/SteamDeck/in-container-build.sh

echo
echo "== done: $OUT =="
