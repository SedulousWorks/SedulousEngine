#!/usr/bin/env bash
# Runs INSIDE the Steam Deck container; build-steamdeck.sh sets it up and calls it. Mounts:
#   /beef  the Beef fork's working branch, cloned by the host script
#   /work  a copy of this repository (the sources, not the host's builds): the SDK the game's
#          workspace was generated against
#   the game's project folder and the bundle's parent folder, each at its own path
# and its environment names the build:
#   WORKSPACE  the game's Beef workspace (its Code/)
#   PROJECT    the executable to build in it (<Game>Player)
#   CONFIG     its build config (ShippingRelease: Release without the profiler)
#   BUNDLE     where the player lands, with what it needs
#
# Builds, in order: Beef (once per commit), the native dependencies, the game's player. Then
# stages the player with the shared libraries it needs and checks that nothing in the bundle
# asks for a glibc newer than the Deck's.
set -euo pipefail

: "${WORKSPACE:?names the workspace}" "${PROJECT:?names the player to build}" "${BUNDLE:?names where the bundle lands}"
CONFIG="${CONFIG:-ShippingRelease}"
MAX_GLIBC="2.35"
PLAYER_BUILD="$WORKSPACE/build/${CONFIG}_Linux64/$PROJECT"
# Editor only: the player loads DXC on demand and never compiles a shader from a cooked pack,
# and DXC's prebuilt library asks for glibc 2.38.
LEAVE_OUT="libdxcompiler.so libdxil.so"

# Parallelism, from build-steamdeck.sh. CMake's --build passes this to ninja; BeefBuild reads
# its worker threads from its user settings, and with none it takes one per core.
JOBS="${JOBS:-6}"
BEEF_THREADS="${BEEF_THREADS:-4}"
export CMAKE_BUILD_PARALLEL_LEVEL="$JOBS"
mkdir -p "$HOME/.config/beeflang"
printf '[Compiler]\nWorkerThreads = %d\n' "$BEEF_THREADS" > "$HOME/.config/beeflang/BeefSettings.toml"

log() { printf '\n== %s ==\n' "$*"; }
glibc_floor() { objdump -T "$1" 2>/dev/null | grep -oE 'GLIBC_[0-9]+\.[0-9]+' | sed 's/GLIBC_//' | sort -Vu | tail -1; }
ver_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }

# --- Beef ---------------------------------------------------------------------------------
BEEF_COMMIT="$(git -C /beef rev-parse HEAD)"
BEEF_MARK="/beef/.steamdeck-built"
if [ "$(cat "$BEEF_MARK" 2>/dev/null)" != "$BEEF_COMMIT" ]; then
	log "Beef $BEEF_COMMIT"
	bash /beef/bin/build.sh
	echo "$BEEF_COMMIT" > "$BEEF_MARK"
else
	log "Beef $BEEF_COMMIT (built)"
fi
BEEFBUILD=/beef/IDE/dist/BeefBuild

# --- the native dependencies --------------------------------------------------------------
# Every one, over the prebuilt archives the copy came with: those were built on the host and
# carry its glibc.
for script in /work/Dependencies/*/build-native.sh; do
	dep="$(basename "$(dirname "$script")")"
	log "$dep"
	bash "$script" make RELEASE
	bash "$script" build RELEASE
done

# --- the player ---------------------------------------------------------------------------
# The game's workspace, whose registry names /work's library folders: the engine is built from
# the copy, the game from its own.
log "$PROJECT ($CONFIG) in $WORKSPACE"
"$BEEFBUILD" -workspace="$WORKSPACE" -config="$CONFIG" -platform=Linux64 -project="$PROJECT"

# --- the bundle ---------------------------------------------------------------------------
log "Stage $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE"
cp "$PLAYER_BUILD/$PROJECT" "$BUNDLE/"
strip "$BUNDLE/$PROJECT"
for lib in "$PLAYER_BUILD"/*.so; do
	[ -e "$lib" ] || continue
	name="$(basename "$lib")"
	case " $LEAVE_OUT " in *" $name "*) continue ;; esac
	cp -L "$lib" "$BUNDLE/"
done
# SDL by its soname, which is what the player asks for.
cp -L /usr/lib/x86_64-linux-gnu/libSDL3.so.0 "$BUNDLE/"
# The third-party notices go with every copy of the player.
cp "$PLAYER_BUILD/THIRD-PARTY-NOTICES.txt" "$BUNDLE/"

log "glibc floors (at most $MAX_GLIBC)"
fail=0
for f in "$BUNDLE"/*; do
	head -c4 "$f" | grep -q $'\x7fELF' || continue
	floor="$(glibc_floor "$f")"
	if [ -z "$floor" ] || ver_le "$floor" "$MAX_GLIBC"; then
		printf '  %-40s %-8s ok\n' "$(basename "$f")" "${floor:-none}"
	else
		printf '  %-40s %-8s TOO NEW\n' "$(basename "$f")" "$floor"
		fail=1
	fi
done

log "what the player needs, and where it finds it"
( cd "$BUNDLE" && ldd "./$PROJECT" | grep -vE "linux-vdso|ld-linux" )
if ( cd "$BUNDLE" && ldd "./$PROJECT" | grep -q "not found" ); then
	echo "!! a library the player needs is missing" >&2
	fail=1
fi

if [ "$fail" -ne 0 ]; then
	echo "!! the bundle is not Deck safe" >&2
	exit 1
fi
log "done: $BUNDLE"
