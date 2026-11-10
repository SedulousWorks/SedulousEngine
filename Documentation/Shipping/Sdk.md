# The engine SDK

A game project builds its own editor, player and tools (`<Game>Editor`, `<Game>Player`,
`<Game>PlayerWeb`, `<Game>Tools`) against an engine SDK: the engine's library projects as source,
the native libraries they link, and the engine's data. A checkout of the engine is one; a release
carries one packed, `sedulous-sdk-<version>-<platform>.zip`, with the project manager inside.

## Using a packed SDK

Unpack the zip anywhere and run `ProjectManager/Sedulous.Tools.ProjectManager`. The manager lists
the SDK it sits in, makes projects from its templates and opens each project in its own editor,
which it builds over that SDK the first time (a Debug build that compiles the engine with the
game, the longest one); a later open builds again only when the project's code or its SDK changed. The manager's Engines page installs other SDKs
from the releases into the user's data folder, side by side, and its Toolchain page checks what a
build needs (below).

Leave an SDK's folder where it is: the manager records projects pinned to it by its path.

## What a build needs

A project's build runs BeefBuild, which compiles and then links through the system's tools. The
Toolchain page checks each, as the build looks for it, and says what to install for one missing.

- **BeefBuild**, found in this order: the `BEEFBUILD` variable; else the first BeefBuild on PATH
  whose install has corlib (a `BeefConfig.toml` beside it naming its libraries); else the managed
  toolchain, the one the SDK pins (`sdk.json`'s `beef`), which the Toolchain page installs from
  the releases. A BeefBuild that says another Beef version than the pin's is used, with a warning:
  a build may fail on the difference.
- **The linker and the archiver** (Linux): `clang++`, else `c++`, on PATH (else `/usr/bin/c++`),
  and `llvm-ar`, else `ar` (else `/usr/bin/ar`). They are not shipped: install `clang` or `g++`
  and `binutils` from the system's packages (on Ubuntu, `sudo apt install clang binutils`).
- **Emscripten**, for web exports alone: an emsdk folder, which BeefBuild reads from its settings
  (Web.md). The Toolchain page writes it into the managed toolchain's own settings; a Beef of your
  own is told what to set. It is not shipped either: install it as Emscripten's own guide says.

### The managed toolchain

A release ships Beef as its own download, `beef-<pin>-linux64.zip`, shared by every SDK with
that pin and installed on demand into `<user-data>/Sedulous/Toolchains/<pin>/` (on Linux,
`~/.local/share/Sedulous/Toolchains/`). The pin is Beef's version and the commit it was built
from (`0.43.6-071610ce`): the Beef the engine was built and tested with, set in
`Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf` (`Beef`). It holds:

- `bin/BeefBuild`, the library it loads, and the runtime libraries it links programs with;
- `bin/BeefConfig.toml`, naming `../BeefLibs`;
- the wasm runtimes a web build links (`bin/Beef*RT32_wasm*.a`);
- `BeefLibs/`, corlib among them;
- Beef's licence and those of what it includes (`LICENSE.TXT`, `LICENSES.TXT`).

It is built on Ubuntu 22.04, so it runs on glibc 2.35 and later. It keeps its settings in
`bin/BeefSettings.toml`, beside itself.

To build with your own Beef instead, put its BeefBuild on PATH or set `BEEFBUILD`; one from a
nightly or a source build works when its version matches the pin's.

## What an SDK holds

- `Code/Foundation`, `Code/Engine`, `Code/Pipeline`, `Code/Editor` and `Code/Plugins`: every library
  project, less the engine's tests.
- `Dependencies/`: each third-party library's Beef project, its prebuilt libraries for the platform
  and for wasm32, its licence, and `THIRD-PARTY-NOTICES.txt`, which every build copies beside its
  executables.
- `Code/Tools/Sedulous.Tools.Editor` and `Sedulous.Tools.Mcp`: only their `BeefProj.toml`, whose
  post-build steps a project's editor and tools take over.
- `Bin/Naga` and `Bin/Tint`, the shader tools for the platform.
- `Data/`: the engine's and the editor's data, the branding and the project templates.
- `Documentation/Shipping`: these guides.
- `ProjectManager/`: the manager, its libraries and the notices.
- `sdk.json`: the SDK's `version` (what a project's stamp is compared with), `label`, `display`
  (the version with its label), `buildNumber`, `platform`, `beef` (the toolchain it was built
  with) and `created`. A checkout has none: its version is read from `EngineVersion.bf`.

The Steam Deck build, the samples, the engine's tests and its own workspace are not in it: a
Steam Deck export needs an engine checkout.

## Packing one

`Code/Tools/pack-sdk.py` packs an SDK from a checkout's tracked files, by hand, on the release
commit (the version and label come from `EngineVersion.bf`):

```
python3 Code/Tools/pack-sdk.py --check
python3 Code/Tools/pack-sdk.py <out-dir> --manager Code/build/ShippingRelease_Linux64/Sedulous.Tools.ProjectManager \
    --toolchain beef-<pin>-linux64.zip [--toolchain-release <tag>]
```

Build `Sedulous.Tools.ProjectManager` in ShippingRelease first. The pin is `EngineVersion.bf`'s
`Beef` (`--beef` overrides it); `--toolchain` must be that pin's zip. `--platform` (default `Linux64`)
picks the platform's prebuilt libraries and shader tools; no Win64 SDK packs yet, since some
dependencies have no Win64 libraries in the tree, and `--check --platform Win64` lists them.

`--check` packs nothing. It fails when a packed project depends on one that is not packed (the
templates' game projects too), when a packed project's config for the platform or wasm32 names a
`$(ProjectDir)` or `$(WorkspaceDir)/..` path that is not packed, when a packed source's
`Compiler.ReadText` or `ReadBinary` path is not packed, or when what a project's workspace
generation reads of an SDK is missing: the stock projects, the startup libraries, the shader
tools, a plugin's `Plugin.xml`, `Data/.dataroot`. A pack runs it first, and Integration.Mcp runs
it on every test run.

A pack writes `sedulous-sdk-<display>-<platform>.zip` (each file's Unix mode kept, fixed
timestamps, so the same files pack to the same bytes) and the release's index for the platform,
`sdk-<platform>.json`, which the manager's Engines page reads to list and verify the download:

```
{"version": "0.2.0", "label": "beta", "display": "0.2.0-beta", "platform": "Linux64",
 "archive": "sedulous-sdk-0.2.0-beta-linux64.zip", "sha256": "<64 hex digits>",
 "size": 47000000, "unpackedSize": 132000000, "beef": "<pin>",
 "toolchain": {"archive": "beef-<pin>-linux64.zip", "sha256": "<64 hex digits>",
               "size": 1234, "release": "v0.1.0"}}
```

`toolchain` is there when `--toolchain` names the toolchain's zip; its `release` is the release
whose files carry that zip, left out when it is this one. Attach the zip and the index to the
GitHub release `v<display>`, beside what `pack-samples.py` writes.

## Packing the toolchain

`Code/Tools/pack-toolchain.sh` packs the managed toolchain for Linux64, by hand, on the release
commit when the pin moved (a release whose pin did not move names the earlier release that carries
it, with `pack-sdk.py --toolchain-release`):

```
EMSDK=<emsdk folder> Code/Tools/pack-toolchain.sh <out-dir>
```

It clones Beef (the `working` branch of [the fork](https://github.com/jayrulez/Beef); `BEEF_REPO`
and `BEEF_BRANCH` name another) under `build/toolchain/<pin>/`, checks out the pin's commit and
refuses when that commit's Beef version is not the pin's. The wasm runtimes are built with the
host's Emscripten (`EMSDK`); Beef itself is built in the Steam Deck's Ubuntu 22.04 container
(podman or docker, `RT`), once per pin, and laid out by Beef's own install script less the debug
BeefBuild. Before it zips, the staged toolchain must say the pin's version, ask for nothing newer
than glibc 2.35 and build and run a small program in Debug and in Release. It writes
`beef-<pin>-linux64.zip`, each file's Unix mode kept, its times the commit's. Building Beef
compiles its C++ libraries and BeefBuild in Debug and in Release and runs its compiler tests:
give it the machine, with nothing else building beside it.

## A release

Release `v<display>` carries, for each platform packed (Linux64 alone until a Windows host packs
Win64):

- `sedulous-sdk-<display>-<platform>.zip` and its index, `sdk-<platform>.json`, which the
  project manager's Engines page lists the release by;
- `beef-<pin>-<platform>.zip`, the toolchain, when the release moved the pin; a release that
  did not names the earlier release that carries it (the index's `toolchain.release`);
- what `pack-samples.py` writes: `samples.json`, and each sample's `sample-<folder>.zip` and
  `sample-<folder>.png`, which the Samples tab lists for that engine.

They are packed by hand from the release commit: the project manager's ShippingRelease build,
then the toolchain (when the pin moved), the SDK with `--manager` and `--toolchain`, and the
samples. AGENTS.md (Releases) has the steps.

A user's first download is the SDK zip: unpacked anywhere, its `ProjectManager/` lists the SDK it
sits in and offers the toolchain on its Toolchain page.
