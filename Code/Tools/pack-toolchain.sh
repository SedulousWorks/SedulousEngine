#!/usr/bin/env bash
# Packs the Beef toolchain a release ships for Linux64: the Beef the engine pins (EngineVersion.Beef
# in Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf, "<Beef's version>-<commit>"), built
# in the Steam Deck's Ubuntu 22.04 container so it runs on glibc 2.35 and later, as the player does.
# The project manager installs it into <user-data>/Sedulous/Toolchains/<pin>/, where the build
# looks for a managed BeefBuild; it unpacks to:
#   bin/BeefBuild          with the shared library it loads and the runtime libraries it links
#                          programs with (libBeefRT.a, libBeefRT_d.a and the rest)
#   bin/BeefConfig.toml    Beef's install form, naming ../BeefLibs, where BeefBuild finds corlib
#   bin/Beef*RT32_wasm*.a  the runtimes a web build links, built with the host's Emscripten
#   BeefLibs/              corlib and Beef's other libraries
#   LICENSE.TXT, LICENSES.TXT  Beef's licence and those of what it includes
# zipped as <out-dir>/beef-<pin>-linux64.zip, each entry's Unix mode kept and its time the pinned
# commit's, so a pack of one build is the same bytes.
#
#   EMSDK=<emsdk folder> Code/Tools/pack-toolchain.sh <out-dir>
#
# Beef is built without LINUX_PACKAGE, so it keeps its settings beside itself in bin/, Emscripten's
# path among them, where the project manager writes that path; a Beef packaged for the system reads
# ~/.config/beeflang instead. Before it is zipped, the staged toolchain must say the pin's version,
# need nothing newer than glibc 2.35, and build and run a program in both Debug and Release.
#
# Run it on the release commit when the pin moved: a release whose pin did not move names an
# earlier release's toolchain (pack-sdk.py --toolchain-release). Then pass the zip to pack-sdk.py
# as --toolchain.
#
# Everything it works in lives under build/toolchain/<pin>/ at the repository root: the Beef clone,
# built once per pin, and the staged install.
#
#   Env: EMSDK        an emsdk folder (with emsdk_env.sh), whose emcc builds the wasm runtimes
#        BEEF_REPO    the Beef the pin's commit is in (default: the fork on GitHub)
#        BEEF_BRANCH  the branch it is fetched from (default: working)
#        RT           podman or docker (default: the first found)
#        MEMORY       the container's memory cap (default: 12g), so an overrun kills the build
#                     and not the rest of the desktop
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="$ROOT/Code/Tools/SteamDeck"
VERSION_FILE="$ROOT/Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf"
IMAGE="sedulous-steamdeck:22.04"
BEEF_REPO="${BEEF_REPO:-https://github.com/jayrulez/Beef.git}"
BEEF_BRANCH="${BEEF_BRANCH:-working}"
MEMORY="${MEMORY:-12g}"
MAX_GLIBC="2.35"
PLATFORM="linux64"

usage() { echo "usage: EMSDK=<emsdk folder> $0 <out-dir>" >&2; exit 2; }
fail() { echo "!! $*" >&2; exit 1; }
[ $# -eq 1 ] || usage
mkdir -p "$1"
OUT="$(cd "$1" && pwd)"

# The pin: Beef's version, a dash, the commit.
PIN="$(sed -n 's/^[[:space:]]*public const String Beef = "\([^"]*\)";.*/\1/p' "$VERSION_FILE")"
[ -n "$PIN" ] || fail "no toolchain pin (public const String Beef) in $VERSION_FILE"
case "$PIN" in
	*/* | *\\* | *:*) fail "the pin '$PIN' is not a folder name" ;;
	?*-?*) ;;
	*) fail "the pin '$PIN' is not <Beef's version>-<commit>" ;;
esac
BEEF_VERSION="${PIN%%-*}"
BEEF_COMMIT="${PIN#*-}"
ARCHIVE="beef-$PIN-$PLATFORM.zip"

EMSDK="${EMSDK:-}"
[ -n "$EMSDK" ] && [ -f "$EMSDK/emsdk_env.sh" ] || fail "set EMSDK to an emsdk folder (with emsdk_env.sh): the wasm runtimes are built with its emcc"
EMSDK="$(cd "$EMSDK" && pwd)"

RT="${RT:-}"
if [ -z "$RT" ]; then
	for c in podman docker; do command -v "$c" >/dev/null 2>&1 && { RT="$c"; break; }; done
fi
[ -n "$RT" ] || fail "needs podman or docker"

STATE="$ROOT/build/toolchain/$PIN"
BEEF="$STATE/beef"
STAGE="$STATE/stage"
mkdir -p "$STATE"

echo "== Beef $PIN: $BEEF_REPO $BEEF_BRANCH =="
[ -d "$BEEF/.git" ] || git clone --quiet --branch "$BEEF_BRANCH" "$BEEF_REPO" "$BEEF"
if ! git -C "$BEEF" rev-parse --quiet --verify "$BEEF_COMMIT^{commit}" >/dev/null; then
	git -C "$BEEF" fetch --quiet origin "$BEEF_BRANCH"
fi
FULL_COMMIT="$(git -C "$BEEF" rev-parse --quiet --verify "$BEEF_COMMIT^{commit}")" ||
	fail "no commit $BEEF_COMMIT on $BEEF_REPO $BEEF_BRANCH"
git -C "$BEEF" checkout --quiet --detach "$FULL_COMMIT"
git -C "$BEEF" log -1 --oneline
# The version the pin names must be the one that commit's BeefBuild says, or every build over the
# SDK would be told its BeefBuild is not the engine's.
SAID="$(sed -n 's/^[[:space:]]*public const String cVersion = "\([^"]*\)";.*/\1/p' "$BEEF/IDE/src/IDEApp.bf")"
[ "$SAID" = "$BEEF_VERSION" ] || fail "the pin says Beef $BEEF_VERSION, and $BEEF_COMMIT is Beef ${SAID:-of no version}"

# The wasm runtimes are wasm32 archives, the same whatever host builds them, so the host's
# Emscripten makes them, into the clone's IDE/dist where Beef's install takes them from.
WASM_MARK="$BEEF/.toolchain-wasm-built"
if [ "$(cat "$WASM_MARK" 2>/dev/null)" != "$FULL_COMMIT" ]; then
	echo "== wasm runtimes (emcc from $EMSDK) =="
	rm -f "$BEEF"/IDE/dist/Beef*RT32_wasm*.a
	(
		set +u
		# shellcheck disable=SC1091
		source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1
		bash "$BEEF/wasm/build_wasm.sh"
	)
	echo "$FULL_COMMIT" > "$WASM_MARK"
fi
WASM_COUNT="$(find "$BEEF/IDE/dist" -maxdepth 1 -name 'Beef*RT32_wasm*.a' | wc -l)"
[ "$WASM_COUNT" -eq 4 ] || fail "the wasm runtimes are not all there ($WASM_COUNT of 4 in $BEEF/IDE/dist)"

echo "== image $IMAGE ($RT) =="
"$RT" build -t "$IMAGE" -f "$DECK/Dockerfile" "$DECK"

# Rootless podman maps this user to the container's root; docker needs to be told, or the
# state directory fills with root owned files.
USER_ARGS=()
[ "$RT" = "docker" ] && USER_ARGS=(--user "$(id -u):$(id -g)")
echo "== build, stage and check in the container =="
"$RT" run --rm -i "${USER_ARGS[@]}" \
	--memory "$MEMORY" --memory-swap "$MEMORY" \
	-e BEEF_COMMIT="$FULL_COMMIT" -e BEEF_VERSION="$BEEF_VERSION" -e MAX_GLIBC="$MAX_GLIBC" \
	-v "$STATE":/state:Z \
	"$IMAGE" bash -s <<'IN_CONTAINER'
set -euo pipefail
log() { printf '\n== %s ==\n' "$*"; }
glibc_floor() { objdump -T "$1" 2>/dev/null | grep -oE 'GLIBC_[0-9]+\.[0-9]+' | sed 's/GLIBC_//' | sort -Vu | tail -1; }
ver_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }
export HOME=/tmp/home
mkdir -p "$HOME"

# --- Beef, once per commit ----------------------------------------------------------------
cd /state/beef
MARK=.toolchain-built
if [ "$(cat "$MARK" 2>/dev/null)" != "$BEEF_COMMIT" ]; then
	log "Beef $BEEF_COMMIT"
	bash bin/build.sh
	echo "$BEEF_COMMIT" > "$MARK"
else
	log "Beef $BEEF_COMMIT (built)"
fi

# --- the install layout -------------------------------------------------------------------
# Beef's own install script lays it out (bin/, its BeefConfig.toml naming ../BeefLibs, BeefLibs/,
# the licences). The debug BeefBuild goes: no build runs it. BeefBuild's debug info goes too: it
# is most of its size, and only a debugger of BeefBuild itself reads it.
log "stage"
rm -rf /state/stage
bash bin/install.sh /state/stage
rm -f /state/stage/bin/BeefBuild_d
strip --strip-debug /state/stage/bin/BeefBuild

# --- checks -------------------------------------------------------------------------------
log "checks"
fail=0
grep -q '"\.\./BeefLibs"' /state/stage/bin/BeefConfig.toml || { echo "!! bin/BeefConfig.toml does not name ../BeefLibs" >&2; fail=1; }
[ -f /state/stage/BeefLibs/corlib/BeefProj.toml ] || { echo "!! no BeefLibs/corlib" >&2; fail=1; }
[ "$(find /state/stage/bin -maxdepth 1 -name 'Beef*RT32_wasm*.a' | wc -l)" -eq 4 ] || { echo "!! the wasm runtimes are not all in bin/" >&2; fail=1; }
said="$(/state/stage/bin/BeefBuild -version | head -1)"
echo "  -version: $said"
case "$said" in *"$BEEF_VERSION"*) ;; *) echo "!! BeefBuild does not say $BEEF_VERSION" >&2; fail=1 ;; esac
for f in /state/stage/bin/*; do
	head -c4 "$f" | grep -q $'\x7fELF' || continue
	floor="$(glibc_floor "$f")"
	if [ -z "$floor" ] || ver_le "$floor" "$MAX_GLIBC"; then
		printf '  %-40s %-8s ok\n' "$(basename "$f")" "${floor:-none}"
	else
		printf '  %-40s %-8s TOO NEW\n' "$(basename "$f")" "$floor"
		fail=1
	fi
done
if ldd /state/stage/bin/BeefBuild | grep -q "not found"; then
	ldd /state/stage/bin/BeefBuild
	echo "!! a library BeefBuild loads is missing" >&2
	fail=1
fi
[ "$fail" -eq 0 ] || { echo "!! the staged toolchain is not fit to ship" >&2; exit 1; }

# A program built and run with a copy of it, so what the build writes beside BeefBuild (its
# settings) does not reach the zip: corlib found, the runtime libraries linked, in both configs.
log "a program built with it"
rm -rf /tmp/toolchain /tmp/hello
cp -a /state/stage /tmp/toolchain
mkdir -p /tmp/hello/src
printf 'FileVersion = 1\nProjects = {Hello = {Path = "."}}\n\n[Workspace]\nStartupProject = "Hello"\n' > /tmp/hello/BeefSpace.toml
printf 'FileVersion = 1\nDependencies = {corlib = "*"}\n\n[Project]\nName = "Hello"\nStartupObject = "Hello.Program"\n' > /tmp/hello/BeefProj.toml
printf 'using System;\n\nnamespace Hello;\n\nclass Program\n{\n\tpublic static int Main(String[] args)\n\t{\n\t\tConsole.WriteLine("toolchain ok");\n\t\treturn 0;\n\t}\n}\n' > /tmp/hello/src/Program.bf
for config in Debug Release; do
	/tmp/toolchain/bin/BeefBuild -workspace=/tmp/hello -config="$config" -platform=Linux64
	ran="$(/tmp/hello/build/${config}_Linux64/Hello/Hello)"
	[ "$ran" = "toolchain ok" ] || { echo "!! the $config program said '$ran'" >&2; exit 1; }
	echo "  $config: $ran"
done
IN_CONTAINER

# --- the zip ------------------------------------------------------------------------------
echo "== $OUT/$ARCHIVE =="
python3 -I - "$STAGE" "$OUT/$ARCHIVE" "$(git -C "$BEEF" log -1 --format=%ct "$FULL_COMMIT")" <<'PY'
import os, stat, sys, time, zipfile
stage, archive, when = sys.argv[1], sys.argv[2], time.gmtime(int(sys.argv[3]))
date_time = (max(when.tm_year, 1980),) + tuple(when[1:6])
entries = []
for folder, _, files in os.walk(stage):
    for name in files:
        path = os.path.join(folder, name)
        if os.path.islink(path):
            sys.exit(f"pack-toolchain: {path} is a link, which the zip does not carry")
        entries.append((os.path.relpath(path, stage).replace(os.sep, "/"), path))
entries.sort()
partial = archive + ".partial"
with zipfile.ZipFile(partial, "w", zipfile.ZIP_DEFLATED) as z:
    for name, path in entries:
        info = zipfile.ZipInfo(name, date_time=date_time)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.create_system = 3 # Unix: the reader keeps the mode below
        info.external_attr = (stat.S_IFREG | (os.stat(path).st_mode & 0o777)) << 16
        with open(path, "rb") as f:
            z.writestr(info, f.read())
os.replace(partial, archive)
print(f"pack-toolchain: {len(entries)} files, {os.path.getsize(archive) // 1024} KB")
PY
sha256sum "$OUT/$ARCHIVE"
echo
echo "== done: pass it to pack-sdk.py as --toolchain $OUT/$ARCHIVE =="
