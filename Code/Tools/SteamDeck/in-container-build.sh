#!/usr/bin/env bash
# Runs INSIDE the Steam Deck container; build-steamdeck.sh sets it up and calls it. Mounts:
#   /beef  the Beef fork's working branch, cloned by the host script
#   /work  a copy of this repository (the sources, not the host's builds)
#   /out   where the player bundle lands
#
# Builds, in order: Beef (once per commit), the native dependencies, the Release player. Then
# stages the player with the shared libraries it needs and checks that nothing in the bundle
# asks for a glibc newer than the Deck's.
set -euo pipefail

MAX_GLIBC="2.35"
BUNDLE="/out/Release_Linux64/Sedulous.Engine.Player.Desktop"
PLAYER_BUILD="/work/Code/build/Release_Linux64/Sedulous.Engine.Player.Desktop"
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
log "Sedulous.Engine.Player.Desktop (Release)"
cd /work/Code
"$BEEFBUILD" -proddir=. -config=Release -platform=Linux64 -project=Sedulous.Engine.Player.Desktop

# --- the bundle ---------------------------------------------------------------------------
log "Stage $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE"
cp "$PLAYER_BUILD/Sedulous.Engine.Player.Desktop" "$BUNDLE/"
strip "$BUNDLE/Sedulous.Engine.Player.Desktop"
for lib in "$PLAYER_BUILD"/*.so; do
	name="$(basename "$lib")"
	case " $LEAVE_OUT " in *" $name "*) continue ;; esac
	cp -L "$lib" "$BUNDLE/"
done
# SDL by its soname, which is what the player asks for.
cp -L /usr/lib/x86_64-linux-gnu/libSDL3.so.0 "$BUNDLE/"

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
( cd "$BUNDLE" && ldd ./Sedulous.Engine.Player.Desktop | grep -vE "linux-vdso|ld-linux" )
if ( cd "$BUNDLE" && ldd ./Sedulous.Engine.Player.Desktop | grep -q "not found" ); then
	echo "!! a library the player needs is missing" >&2
	fail=1
fi

if [ "$fail" -ne 0 ]; then
	echo "!! the bundle is not Deck safe" >&2
	exit 1
fi
log "done: $BUNDLE"
