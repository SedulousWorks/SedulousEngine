# Working on Sedulous: notes for agents

How to build, test and change this engine without breaking it. The README describes what the
engine is; this is how to work in it.

## Build

Everything is one Beef workspace under `Code/`. BeefBuild is the Beef the engine pins,
`EngineVersion.Beef` (Beef's version and the commit of the `working` branch of
[the fork](https://github.com/jayrulez/Beef) it is built from), which a release ships as its
toolchain; a nightly of the same Beef version builds it too. Run it from `Code/`:

```
BeefBuild -proddir=. -config=Debug -platform=Linux64 -project=Sedulous.Tools.Editor
BeefBuild -proddir=. -platform=Linux64 -test -project=Sedulous.Core.Tests
```

The editor is on the GUI, as Raptor's editor-gui series moved it: `Sedulous.Tools.Editor` is
the shell (its window, dock, menus, palette, the assets browser, Preferences,
Project Settings, export, the MCP host over `--mcp`), the scene page with its hierarchy and its
inspector, the Game tab with the play-in-editor tools, every asset page and the Profiler page.
The old editor's files are deleted (the swap); the last editor on Sedulous.UI builds at e293ee1f.
`Sedulous.Tools.Mcp` is the headless MCP host, and `Samples.GUISandbox --editor-mock` shows the design.
Each stock executable is a one-line Main over a startup library: `Sedulous.Tools.Editor` over
`Sedulous.Editor.Main`, `Sedulous.Engine.Player.Desktop` over `Sedulous.Engine.Player.DesktopMain`,
`Sedulous.Engine.Player.Web` (wasm32) over `Sedulous.Engine.Player.WebMain`, and
`Sedulous.Tools.Mcp`, `Sedulous.Tools.Cook` and `Sedulous.Tools.Export` over
`Sedulous.Editor.McpMain`, `Sedulous.Editor.CookMain` and `Sedulous.Editor.ExportMain`. A project
with packages of its own generates `<Game>Editor`, `<Game>Player`, `<Game>PlayerWeb` and
`<Game>Tools` (its `mcp`, `cook` and `export` subcommands) over the same libraries, so they
start exactly as the stock ones do: the desktop ones in its `Code/` workspace, the web player in
a workspace of its own, `Code/.generated/Web` (BeefBuild compiles every enabled project of a
workspace, and the editor's dependencies do not compile for wasm32).
The editor opens one project (`--project <dir>`, or the folder alone); started with none, it
starts the project manager and exits. The project manager, `Sedulous.Tools.ProjectManager` over
`Sedulous.Editor.ProjectManager`, lists projects, makes them from the templates in
`Data/Templates` and opens each in its own `<Game>Editor`, built over the project's engine SDK (a
checkout is one) before it launches; `Documentation/Shipping/Sdk.md` says what an SDK holds and
what a build needs.
The old UI framework (Sedulous.UI and its toolkit, shell, runtime, application and VFS libraries)
and its UISandbox live under `Code/Deprecated/UI`, in the workspace but disabled in every config:
nothing else links them, and enabling them builds the sandbox.

- Outputs land in `Code/build/<Config>_<Platform>/<Project>/`.
- Configs: Debug, Test, Release (optimised, the profiler compiled in) and ShippingRelease
  (Release without the profiler: `SHIPPING` is defined). An export builds the game's own player:
  a preset's Release is a ShippingRelease build, its Profile a Release one.
- Build ONE project at a time, and never beside another heavy build (a second BeefBuild, the
  Steam Deck container, another engine's build). Two at once has run the machine out of memory.
- A tool built before a change does not have it: rebuild the editor, the player or
  `Sedulous.Tools.Mcp` after changing what they use. A game's code is compiled into its project's
  own editor and player, so those are rebuilt too after an engine change the game uses.

## Test

- Every Foundation and Engine module has a sibling `.Tests` project; `Code/Integration/` holds
  the flows that cross collections. Run the tests of every project a change touches, and add a
  test for each behaviour you change or fix.
- On Linux a plain `BeefBuild -test` run reports NO leaks: the debug runtime is built without
  its leak checker. Check new or changed tests for leaks and memory errors with
  `python3 Code/Tools/asan-test.py <TestProject> [name filter]` after building them: exit 0 is
  clean; a nonzero exit with no test failures is a leak, its stacks printed above. A Vulkan
  backend test also reports a known leak inside libdbus; read past it for engine frames.
- Tests write `scratch_*/` directories beside the project they run from; those are ignored.

## Change

- **Verify, don't guess.** Read the source, or run it, before relying on or stating a
  constant, a count or an API's behaviour (ownership, what a call deletes, what it returns).
- **Match the code around you**: its naming (`mField` for private fields, PascalCase types and
  members), its ownership idioms (`~ delete _`, `scope`, `defer`), its comment density and
  voice (`///` on what is not obvious, saying why).
- **Keep the documents honest in the same commit.** A change to the MCP tools updates
  `Documentation/Shipping/McpGuide.md`; the engine tool count (`EngineTools.cEngineToolCount`)
  is a deliberate tripwire, bumped when a tool is added. A change a user would notice adds its
  line to `CHANGELOG.md` under Unreleased.
- **Versions:** master is labelled `dev` between releases; cutting a release and the bump after
  it are under Releases below.
- **Commits**: one per piece of work, the subject `Area: what it does` with a body saying why,
  and no `Co-Authored-By` or session trailer lines. Push only when asked.
- **Third-party content**: check its licence before adding it. Nothing goes in that may not be
  published (a "free for personal use" font may not); keep the licence text beside it, and
  credit what requires it. A library that ships in a binary also joins
  `Code/Tools/third-party-notices.py`, which writes the `Dependencies/THIRD-PARTY-NOTICES.txt`
  every player, editor and export carries; run it after adding or updating one (Integration.Mcp
  fails while the committed file is stale).

## Raptor

Raptor (C++) is this engine's mirror in another language; the two move together. It is the
reference for how a feature should behave. Syncs run from Raptor to Sedulous and carry code,
not transliterated idiom: Beef's way wins. Sedulous has no scripting and no export templates, so a
Raptor commit that only touches those has nothing to port. `Documentation/Changes.md` lists what
changed from the previous engine, on the `v0` branch, and, in its last section, from the scripted
model master had before.

## Agent tooling

- `Sedulous.Tools.Mcp` is the headless MCP host for a project with no code of its own; a project
  with code (every sample) needs its own, `<Game>Tools mcp`, which links its game. The editor (the
  project's `<Game>Editor`) serves the same tools over HTTP for its open project (`--mcp` or
  `--mcp-port <port>`), plus page and play-in-editor tools. An agent changing a game's code builds
  and relaunches that editor (`project_build`, or `editor_relaunch` with `build: true`); a method
  body's change can instead be hot compiled from the Beef IDE (GameCode.md).
  `.claude/skills/engine-mcp` is the recipe to build and wire it; once connected, read
  `docs://McpGuide.md` (`Documentation/Shipping/McpGuide.md`), the operating manual. A game's
  own Beef code (its Behaviour, Level and Game tiers) is `docs://GameCode.md`
  (`Documentation/Shipping/GameCode.md`).
- When an MCP tool is missing or wrong for a task, that is a finding: fix the tool in the
  engine, rather than routing around it by editing project files by hand.

## Sample projects

`Data/SampleProjects/` holds game projects: **Sky Hopper** (`SkyHopper`), built entirely
through the MCP tools (its authoring scripts in `Tools/`, run against the project's own editor: its game and
behaviours are its `Code/`, the engine part also a project of the engine workspace, linked by
Integration.Mcp), **PaperKid**, rebuilt the same way (its authoring scripts in `Tools/`, run
against the project's own editor: its game, its blocks' level and its behaviours are its `Code/`, the
engine part also a project of the engine workspace, linked by Integration.Mcp),
**Snowline**, Raptor's snowboard demo ported through the same tools (its authoring scripts in `Tools/`, run
against the project's own editor: its game and its behaviours are its `Code/`, the engine part also a
project of the engine workspace, linked by Integration.Mcp),
**Lamplight**, Raptor's stealth heist ported the same way (its authoring scripts in `Tools/`, run against the
project's own editor: its game and its behaviours are its `Code/`, the engine part also a project of
the engine workspace, linked by Integration.Mcp), the
**Shader Gallery**, Raptor's custom shaders sample ported the same way (its authoring scripts in `Tools/`, run
against the project's own editor: its camera's Gallery behaviour is its `Code/`, the engine part also a
project of the engine workspace, linked by Integration.Mcp),
**Masquerade**, Raptor's networked masked ball ported the same way (its authoring scripts in `Tools/`, run
against the project's own editor: its game and its behaviours are its `Code/`, the engine part also a
project of the engine workspace, linked by Integration.Mcp), and
**NativeSample**, a game's own native code: its `Code/` workspace, the game library and its
other three parts (also projects of the engine workspace, linked by Integration.Plugins) and a scene its Spin component turns, its Bob behaviour moves and its Arena level times (its Game hearing the round end), built through the
project's own editor by its authoring scripts in `Tools/`.
Their `Cooked/`, `.cache/`, `Editor/` and `Dist/` are generated and ignored. Integration.Mcp
checks that PaperKid, the Shader Gallery, Sky Hopper, Lamplight, Snowline and Masquerade (each with its package loaded) read at the current data versions and cook;
Integration.Plugins checks that NativeSample reads with its package loaded and cooks, and that its game launches in a run. Each one's `CREDITS.md` and
`Licenses/` must stay in step with its assets.

The project manager's Samples tab (`Sedulous.Tools.ProjectManager`; the editor opens one project
and has no manager screen) downloads the games `Data/SampleProjects/Samples.json` lists from the
GitHub release of the engine picked there. `python3 Code/Tools/pack-samples.py <out-dir>` packs them
(each one's tracked files less `Tools/`, a zip with its `Project.xml` at the root, its picture, and a
`samples.json` with sizes and SHA-256s, at the version in `EngineVersion.bf` with its label: the
release's, so it runs on the release commit). It runs by hand: there is no workflow, so whoever makes the release attaches what it
writes to release `v<version>` (v0.1.0-beta for the first). Compatibility checks compare the numbers alone
(`EngineVersion.String`); what people read carries the label (`EngineVersion.Display`), and a build
handed out gets its `EngineVersion.BuildNumber`, set by hand (0 is a local build). A game joins the tab by an entry in `Samples.json` (its folder, its name, one line,
its picture from `Documentation/Images`). To try the tab before a release carries them, pack into
a folder and run the project manager with `--release-files <folder>`: it serves the folder on
loopback and opens on Samples.

## Releases

- **The changelog:** `CHANGELOG.md` at the root. A change someone using the engine, the editor or a
  game would notice adds its line under `## Unreleased` (Added, Changed, Fixed, Removed) in the
  same commit; internal work (a refactor, a test, a plan) adds none. Lines say what changed for
  that person, in public terms: no internal names, no other engines.
- **The version:** `Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf` (String, Label and
  Display, which a test holds in step). On master between releases the label is `dev` and the
  version is the one being worked toward (0.1.0-dev before 0.1.0-beta; 0.2.0-dev after 0.1.0).
- **The toolchain pin:** `EngineVersion.Beef` in the same file, the Beef the engine is built and
  tested with ("<Beef's version>-<commit>"). Moving the engine to another Beef moves the pin in
  the same commit, with `Dependencies/Beef/`'s licence files copied from that commit and the
  notices written again.
- **What `v<version>` carries:** the engine SDK and its index per platform
  (`sedulous-sdk-<version>-linux64.zip` and `sdk-linux64.json`; Win64 once a Windows host packs
  one), the toolchain when its pin moved (`beef-<pin>-linux64.zip`; else the index names the
  earlier release that carries it), and the samples (`samples.json` and each sample's zip and
  picture). Every pack runs by hand: there is no workflow.
- **Cutting a release:** on master, one commit `Release: <version>`: the label set to the
  release's (`beta` for a pre-release, empty for a final) and `## Unreleased` renamed to
  `## <version> - <date>`. Tag it `v<version>`. Then, from that commit and in this order
  (`Documentation/Shipping/Sdk.md` has each one's details):
  1. Build `Sedulous.Tools.ProjectManager` in ShippingRelease.
  2. When the pin moved since the last release, `EMSDK=<emsdk> Code/Tools/pack-toolchain.sh <out>`
     (a container build of Beef: nothing else building beside it). When it did not, download that
     release's `beef-<pin>-linux64.zip` into `<out>` instead.
  3. `python3 Code/Tools/pack-sdk.py --check`, then `python3 Code/Tools/pack-sdk.py <out> --manager
     Code/build/ShippingRelease_Linux64/Sedulous.Tools.ProjectManager --toolchain
     <out>/beef-<pin>-linux64.zip`, adding `--toolchain-release v<earlier>` when an earlier release
     carries the toolchain.
  4. `python3 Code/Tools/pack-samples.py <out>`.
  5. Make the GitHub release from the tag and attach what `<out>` holds (not an earlier release's
     toolchain zip).
- **After a release:** the next commit on master puts the label back to `dev`, bumps the version
  when the release was final, and opens a new `## Unreleased`.

## Steam Deck

`Code/Tools/SteamDeck/build-steamdeck.sh` builds a game's player from its project workspace in
an Ubuntu 22.04 container (glibc 2.35, below SteamOS), Beef included: what an export of a preset
whose builder is SteamDeck runs. It needs podman or docker, and nothing else building beside it.
