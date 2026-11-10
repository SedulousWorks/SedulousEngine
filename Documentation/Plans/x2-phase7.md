# x2 phase 7: the project manager and the SDK

**Status:** design, 2026-11-10; the user took every recommendation on the open questions (Q1 to Q15) the same day. It expands phase 7 of `x2.md` (lines 235-247), under D4 (SDK location), D5 (toolchain, decided) and D8 (the manager, decided). It also takes in two phase 1 items left open, a new project born with `Code/` and the project templates (`x2.md:103`, `x2.md:120`), since Create cannot be designed without them. Names follow phase 5: the project's editor is `<Game>Editor`, undotted (`ProjectBuild.bf:96-99`).

## What exists

### The manager's code, where it lives and what it reaches

The manager is split between three libraries today.

- **Headless, in `Sedulous.Editor.Project`** (deps: Core, Content, VFS, VFS.Pak, Xml.Serialization, Engine.Project, Engine.Composition, Settings, Pipeline.Core, Pipeline.Cook, Shaders, Shaders.System, Shaders.Resource, Scene.Resource, Geometry, Pipeline.Importer and three pipelines; `Editor.Project/BeefProj.toml`):
  - `ProjectRegistry` (`ProjectRegistry.bf:14-163`): the recent list's touch, remove, pin and relocate; `ProbeProject` (95-101, a full `ProjectManifest.Load`); `CompareProjectEngineVersion` (104-139, against the compiled `EngineVersion.Major/Minor/Patch`); `BackupProjectManifest` (146-163, which probes first).
  - `RecentProjects` (165 on): ordering and the words for times and folders.
  - `RecentProjectsSettings` (`[Serializable(1)]`, cap 20) and `RecentProjectEntry` (`[Serializable(1)]`: path, name, engine version, last opened, favourite).
  - `ProjectManagerController` (`ProjectManagerController.bf`): `DecideOpen` (33-57) words the gate; `Create` (61) is `EditorProject.Create`; `CheckNewProject` and `FolderNameFor` are New Project's check.
  - `ProjectOpenGate` (NotAProject, OpenDirectly, PromptOlderBackup, PromptNewerEngine), `ProjectOpenDecision`, `EngineVersionRelation`, `NewProjectCheck`.
  - Their own usings are light: Core, Core.IO, Settings, VFS, Engine.Project. The only heavier type they reach is `EditorProject` (the controller's `Create`).
- **GUI, in `Sedulous.Editor.App`** (which links the dock, the pages, MCP, profiler and the pipelines):
  - `ProjectManagerView.bf` (1712 lines): the Projects and Samples tabs, New Project and Download dialogs, menus, keys, drops. Its usings are Core, Shell, Image.IO, GUI, Http.Client, Engine.Project, Editor.Project. Of Editor.App's own types it uses only `ProjectPicture`, `SampleCatalog`, `SampleDownload` and `SampleInfo`.
  - `SampleDownloads.bf` (341 lines): `SampleInfo`, `SampleCatalog.Parse`, `ReleaseFolder.Serve` (the `--release-files` loopback server) and `SampleDownload` (streamed, SHA-256 checked, extracted with `Sedulous.Zip`). Usings: Core, Json, Http, Http.Client, Zip.
  - `ProjectPicture.bf` (55 lines), shared with the editor's `ProjectHomeView`.
  - `ProjectManagerMode.bf` (274 lines): the part of the application that shows the manager, runs the gate's prompts, creates and opens through `EditorSession`, and does Close Project. It is the only one of these that reaches the editor proper (`EditorSession`, `EditorSessionOpenOptions`, `EditorPages`).
- **Its window** is `EditorWindow` (`EditorWindow.bf`, 514 lines): `ShowScreen` (368) lays the manager over the dock; `LoadMarkup` reads `Data/Editor/ProjectManager.xml`, `NewProject.xml` and `DownloadSample.xml` through `EditorResources` (`Editor.Core/src/EditorResources.bf`, usings: Image, Image.IO, VFS, VG.SVG, GUI only). The look comes from `EditorLook` (in `EditorWindow.bf`) and `EditorUiSettings` (`Editor.Core`, usings: Core.Serialization, Settings).

### How the editor runs the manager

- `EditorMain.Run` sets `StartInProjectManager` when no project is given (`EditorMain.bf:81`). Its usage comment still says the manager "is not on the GUI yet" (27-31), which is stale.
- `EditorApplication` owns `mProjectManager` (192), `mManagerMode` (210), and for the Samples tab `mTls`, `mHttp` and `mReleaseFiles` (160-168, made in `ManagerModeServices`, 422-455, and `ReleaseFileUrl`, 457-486). At startup it enters the manager or opens the project (585-597). A folder dropped on the manager opens it (1301-1302). The Samples tab ticks every frame, also while a project is open (1481-1484).
- **Close Project exists only in a run that started in the manager** (`EditorApplication.bf:1391-1400`): a project given on the command line keeps its one project.
- The MCP host serves the manager screen (`services.Shown`, 444-448; `host_info.screen` "projectManager", `EditorMcpHost.bf:78-83`; `McpGuide.md:16-24`).
- The recent list is a section of the editor's user store, `<user-data>/Sedulous/editor.settings.xml` (`EditorSettingsStore.bf:17, 44-56`). Unknown sections pass through a save (`Settings.bf:36-38`). The editor records an open there (`EditorSession.bf:237`) and saves the whole store.

### How a project's editor is built and launched today

- **The SDK.** `ProjectBuild.FindSdk` (`ProjectBuild.bf:246-268`) is `SEDULOUS_SDK`, then the editor's data root's parent, each accepted when `IsSdk` holds (223-235: the editor, player, web player and three tool startup libraries present). The comment at 262-263 holds the registry's place. It is not the walk-up D4 describes, and it ignores the project's stamped version. `FindCheckout` is gone (replaced in 810887d02).
- **Generate** writes `Code/BeefConfig.toml` with absolute paths to the SDK's library folders (`cSdkLibraryDirs`, 148: `Code/Foundation`, `Code/Engine`, `Code/Pipeline`, `Code/Editor`, `Code/Plugins`, `Dependencies`; `ConfigText`, 299). It also writes the stock editor's and tools' post-build steps (naga and tint from `$(WorkspaceDir)/../Bin`), made absolute from `Code/Tools/Sedulous.Tools.Editor/BeefProj.toml` and `Code/Tools/Sedulous.Tools.Mcp/BeefProj.toml` (113, 121), and the web player's link from `Code/Engine/Sedulous.Engine.Player.Web` (`shell.html`, `player.js`, `serve.py`).
- **The build.** `ProjectBuildService.Run` (`ProjectBuildService.bf:444`) is blocking. It refuses an Editor job for a project with no package of its own (482: "the stock editor runs it"). It finds BeefBuild (`FindBeefBuild`, `ProjectBuild.bf:1035-1074`: `BEEFBUILD`, then PATH with a corlib check, then `ManagedBeefBuild`, a stub that returns false, 1075-1082). It runs one BeefBuild per step and streams the output into the job with parsed diagnostics.
- **Staleness.** `IsStale` (1322-1329) compares the editor executable with the project's package sources only (`NewestSource`). A switched or updated SDK does not make it stale.
- **The launch.** Open With This Build (`EditorApplication.bf:1081-1108`) and `editor_relaunch` (`EditorBuildTools.bf:350-418`) start `Code/build/Debug_<Host>/<Game>Editor/<Game>Editor` with `--project <dir> --data-root <dataRoot>` (`RelaunchArguments`, 131-145) through `Sedulous.Core.Process.Start`. The data root has to be passed. Discovery walks up from the executable for `<ancestor>/Data/.dataroot` (`DataRoot.bf:31-50`), so a project's editor finds a data root by itself only when the project sits inside an engine checkout, as the samples do.

### Stamps, gates and data versions

- `ProjectManifest.Save` stamps the **compiled** `EngineVersion.String` into every manifest it writes (`ProjectManifest.bf:43-47`). A manager that saved a manifest would stamp its own version, not the SDK's.
- `ProjectSettings` is `[Serializable(11, false, 9)]` (`ProjectSettings.bf:32`). A payload at another version than it supports is refused (`SerializableAttribute.bf:44-46`), so a manager built at one version cannot `ProbeProject` a manifest a newer SDK wrote. The same holds for the recent list's own types if a later manager versions them up.
- `EditorProject.Open` only logs a project of another version ("a launcher routing projects to their engine version ... is planned", `EditorProject.bf:93-94`).

### Samples

- `ProjectManagerView.ReleaseFile` uses `EngineVersion.ReleaseDownloadUrl` (`EngineVersion.bf:44-47`: `.../releases/download/v<Display>/<file>`), so the tab offers only the compiled version's samples.
- A finished download is recorded with its probed stamp (`ProjectManagerView.bf:1020-1035`).
- `pack-samples.py` packs the tracked files less `Tools/`. The six samples now carry `Code/` (phase 4), so a downloaded sample needs its own editor built before it opens.

### Zip, process and toolchain facts

- `Sedulous.Zip` reads only (`ZipArchive.bf`: `Open`, `Read`, `ExtractAll`). Nothing in it restores Unix modes, so an extracted BeefBuild, naga, tint or manager would lose its executable bit.
- BeefBuild has `-version` (`Beef/BeefBuild/src/BuildApp.bf:205`, the Beef tree here).
- BeefBuild needs more than itself:
  - On Linux it links with `clang++`, else `c++`, from PATH, falling back to `/usr/bin/c++`, and archives with `/usr/bin/ar` (`Beef/IDE/src/BuildContext.bf:430-434, 648-674`).
  - On Windows it links with MSVC's `link.exe` or LLVM's `lld-link.exe` (1583, 1612).
  - A packaged Linux Beef (`LINUX_PACKAGE`) keeps its settings in `~/.config/beeflang/`; any other build keeps them beside itself (`IDEApp.bf:13575-13581`). So a toolchain we build ourselves without that define keeps `BeefSettings.toml`, and with it Emscripten's path, beside its BeefBuild.
- The Steam Deck builder needs a git checkout: `build-steamdeck.sh` copies the SDK through `git ls-files` (89-95), and the container rebuilds every native dependency from its sources (`in-container-build.sh:53`).

### What the SDK must hold for a generated workspace to build

Read from the code above:
- The library projects under `cSdkLibraryDirs`.
- The two stock BeefProj files Generate reads (`Code/Tools/Sedulous.Tools.Editor`, `Sedulous.Tools.Mcp`).
- The web player's folder.
- `Bin/Naga` and `Bin/Tint`.
- `Dependencies/THIRD-PARTY-NOTICES.txt`, copied by `Runtime.Client`'s post-build (`$(ProjectDir)/../../../Dependencies/...`, `Runtime.Client/BeefProj.toml:24-45`) and the web player's.
- `Data/Branding/sedulous-logo.svg` and `Data/Engine/Fonts/roboto/Roboto-Regular.ttf`, embedded at compile time by `PlayerApplication.bf:72` and `EditorMain.bf:45` through `../../../Data/...`.
- Each dependency's `dist/` paths its BeefProj names per platform (`$(ProjectDir)/dist/Release-Linux64`, `Release-wasm32`, `Release-Win64`, `Debug-Win64`, `lib/x64`, `SDL3-3.4.0/lib/x64`, and others).

**Win64 dists are incomplete.** `harfbuzz-Beef`, `sheenbidi-Beef` and `mbedtls-Beef` name `dist/Debug-Win64` and `Release-Win64` libraries that are not in the tree, and `zlib-Beef` names a Win64 one too (each has only `Release-Linux64` and `Release-wasm32`). So no Win64 SDK can link the editor yet.

### Size (tracked files, this tree)

| Part | Size |
|---|---|
| Library sources: Foundation, Editor, Engine, Pipeline and Plugins less every `*Tests` project | 13.4 MB in 2,885 files |
| The test projects left out | 9.8 MB |
| Each dependency's Beef side (BeefProj, `src/`, licence) | about 8.1 MB |
| The dependencies' C sources and the rest left out (needed only by `build-native.sh`) | about 109 MB |
| `dist/` for Linux | about 68.5 MB |
| `dist/` for wasm32 | 16.7 MB |
| `dist/` for Windows (both configs, with pdbs) | about 364 MB |
| `Bin/` for Linux (naga 5.4 MB and tint 12.7 MB) | 18.0 MB |
| `Data/Editor` | 3.9 MB |
| `Data/Engine` | 0.6 MB |
| `Data/Templates` | 1.4 MB |
| `Data/Branding` | 0.1 MB |

A Linux64 SDK's sources and libraries come to about 130 MB uncompressed, before the manager binary. For scale, a Release `Sedulous.Tools.Editor` built on 2 Nov is 201 MB. The manager's own size is measured in commit 8, not guessed here.

## The design

### Two new libraries and one executable

- **`Sedulous.Editor.Projects`** (headless; Core, Settings, Runtime, VFS, Xml.Serialization, Engine.Project; `Http.Client` and `Zip` for downloads).
  - It holds everything both the editor and the manager need about projects, SDKs, toolchains and builds:
    - `ProjectBuild`, `ProjectBuildService` with `BuildJob`, `BuildDiagnostics`, `BuildLayout`, `PluginPackages` and `CodeWatch`;
    - the registry types, `ProjectManagerController`, the gate types and `NewProjectCheck`;
    - `GamePackage`'s text generators with a Scaffold over a directory and settings, as `x2.md:103` asks;
    - the new SDK, toolchain, template and download types below.
  - Moved types keep the namespace `Sedulous.Editor.Project`. That avoids a `SerializableRenames` entry for the recent list (`EditorSerializables.bf:25-29` already carries one move) and a using in every caller.
  - `Editor.Project` depends on it, so nothing above changes its imports.
- **`Sedulous.Editor.Look`** (GUI-level: GUI, GUI.Hosting, Fonts, Image.IO, VG.SVG, Settings): `EditorResources`, `EditorUiSettings`, `EditorLook`, and the part of `EditorWindow.Open` that makes the GUI host, the fonts and the sheet. The editor and the manager then look the same and read the same appearance preferences (Q2).
- **`Sedulous.Editor.ProjectManager`** (GUI, Shell, Look, Projects, Http.Client, Net.Tls.MbedTLS, Zip, Json):
  - `ProjectManagerView` (Raptor references dropped from its comments as it moves), the samples types, `ProjectPicture`, the SDK and toolchain pages;
  - `ProjectManagerApp`, today's `ProjectManagerMode` with the session cut out: Open and Create become flows that end by launching an editor;
  - `ProjectManagerMain.Run`, the whole startup, a library as `EditorMain` is.
- **`Code/Tools/Sedulous.Tools.ProjectManager`**: a one-line Main over `ProjectManagerMain.Run`.

The cut from the editor is `ProjectManagerModeServices` (`ProjectManagerMode.bf:12-40`): its `Session` and `Pages` go. Its `Root`, `Dialogs`, `ShowScreen`, `LoadMarkup`, `StoreChanged`, `Http` and `ReleaseFile` are bound by the manager's own window instead.

### SDKs

- **The version file**, `<sdk>/sdk.json`, written by `pack-sdk.py`, with:
  - `version` (String), `label`, `display`, `buildNumber`, `platform`;
  - `beef` (the toolchain pin, Q11);
  - `created`.
  - A checkout has none. `SdkInfo.Read` falls back to `EngineVersion.bf`'s constants, read with the pattern `pack-samples.py` already uses (`engine_version`), and marks the SDK a checkout (mutable).
- **`SdkRegistry`**, its own file `<user-data>/Sedulous/sdks.xml` (Q3):
  - the roots of installed SDKs (managed, under `<user-data>/Sedulous/SDKs/<display>-<platform>/`) and registered folders (checkouts, unpacked SDKs);
  - per project, a pin: the SDK root the user picked.
  - Each entry is re-read with `IsSdk` and `sdk.json` on use; a gone root is shown missing, as the recent list shows missing projects.
- **Resolution (D4).** `FindSdk(dataRoot, projectDir)`:
  1. `SEDULOUS_SDK`.
  2. The registry: the project's pin, else the best registered SDK whose `version` equals the project's stamp (final over beta over dev, then the highest build number; a checkout last).
  3. The data root's parent (an editor launched from an SDK).
  4. A checkout found walking up from the project directory, which D4 names and the code lacks today.

  The editor and the tools get the project directory from the job they already run.
- **What Generate records.** Generate writes `Code/.generated/sdk.txt` (the SDK root and display). `IsStale` is also true when that differs from the SDK resolved now, or when the SDK is a checkout. A checkout's sources change on every pull, which `NewestSource` cannot see, so for a checkout the build always runs BeefBuild, which is incremental (as phase 5 Q1 ruled for exports).
- **The generated Main gets a fallback data root.** Each generated `Program` passes the SDK's `Data` as a fallback data root when neither `--data-root` nor discovery finds one, so a project's editor also starts from the Beef IDE or a shell (Q14).

### The project header and the gate

- `ProjectHeader.Read(dir)` reads `name` and `engineVersion` from `Project.xml`'s object element by key, as the manifest writes them, without the settings schema. The manager can then list and route a project whatever data version wrote it. `ProbeProject` stays for the editor.
- `CompareEngineVersions(project, against)` generalises `CompareProjectEngineVersion`, which becomes the case `against = EngineVersion.String`.
- `DecideOpen(directory, sdk, decision)` gates against the **picked SDK's** version, not the manager's own. The prompts keep their words with the SDK's version in them.
- **Back Up and Open** copies `Project.xml` bytes to `Project.xml.<stamp>.bak` without parsing.
- **Restamping** is the editor's job, since only it writes manifests: the manager launches it with `--restamp`, and `EditorSession.Open` then saves the settings once (today's `Answered`, `ProjectManagerMode.bf:255-274`). The manager never saves a manifest.

### Open

1. Read the project's header (NotAProject refuses, as now).
2. Pick the SDK (above). With none for its version: "This project needs engine 0.2.0: Install it, or choose another engine (it will be upgraded)", linking the SDK page.
3. Run the gate against that SDK (older: backup prompt; newer: the hard warning).
4. Check the toolchain (below). A missing BeefBuild or linker stops here with the fix. Emscripten is not needed to open a project: the editor is a desktop build.
5. Build `<Game>Editor` (Debug) through `ProjectBuildService` on a worker thread, when `IsStale` says so or the SDK is a checkout. The build panel shows the step, the output's tail, the parsed diagnostics (file:line, message; a click copies the location) and Cancel. A failure stays on the panel and launches nothing.
   - A project with no package builds an editor too: Generate with zero packages (phase 5 Q2's player path) covers the Editor entry, and the refusal at `ProjectBuildService.bf:482` goes (Q6).
6. Launch `<Game>Editor --project <dir> --data-root <sdk>/Data --manager <this executable> [--restamp] [--mcp ...]`.
7. Record the open, then exit (Q4).

### Create

- **Templates** are folders in the SDK: `Data/Templates/<Id>/` with `Template.xml` (name, one line, picture, order) and the project tree (Q12):
  - **Empty:** Project.xml, Code/ with the game library (the Engine part from `GamePackage`'s generators), the root `.gitignore` (NativeSample's, `x2.md:103`).
  - **Starter:** Empty plus `ProjectSeed`'s content (the Roboto distance-field font, the sky, cube, sphere and plane), one Behaviour and a scene (`x2.md:120`).
- **Authoring.** Templates are authored the way the samples are: a script under `Data/Templates/Tools/` drives the stdio MCP host, `project_create` and `plugin_scaffold`, so their records are at the SDK's data versions and their manifests carry the SDK's stamp. `Data/Templates/kloofendal_.../` (`ProjectSeed.bf:55`) stays where it is.
- **Instantiating** copies the tree and replaces the placeholders, `__PROJECT_NAME__` in Project.xml and `__GAME__` (`ProjectBuild.GameName`) in `Code/` paths and texts. Nothing is parsed, so a manager can create from a newer SDK's template.
- **New Project** gains the template list and the engine (SDK) picker, defaulting to the newest installed. Its check (`CheckNewProject`) is unchanged.
- **`project_create`** (stdio host) gains `template` (default `Starter`, today's seeded behaviour), copying from the host's SDK.
- After Create, Open runs as above. The first open builds the editor.

### Samples

- The Samples tab names the SDK whose release it lists (the newest installed by default; a picker beside the tabs) and builds its URLs from that SDK's `display`, not the compiled `EngineVersion`.
- A downloaded sample is pinned to that SDK.
- `--release-files` moves to the manager.
- `SampleDownload` becomes `ReleaseDownload` (url, SHA-256, size, target, extract), which SDK and toolchain installs reuse.

### SDKs side by side

The manager's Engines page:
- **Installed:** each SDK's display, platform, root, kind (installed, folder, checkout) and the projects pinned to or stamped for it.
- **Available:** from the GitHub releases list of `ReleaseRepository` (Q9), each release that carries `sdk-<platform>.json`.
- **Install:** `ReleaseDownload` of `sedulous-sdk-<display>-<platform>.zip`, checked against the digest in `sdk-<platform>.json`, extracted with Unix modes (commit 5) into the managed folder, then registered. A failed or cancelled install leaves nothing, as `SampleDownload` does.
- **Add folder:** register a checkout or an unpacked SDK (`IsSdk` must hold).
- **Remove:** a managed SDK's folder is deleted after a confirmation naming the projects that use it. A registered folder is only unlisted, never deleted.
- **Pick per project:** a project's menu gains "Engine: 0.2.0 (installed) ▸" listing the SDKs. Picking one with the same version only pins it. Picking another version is an upgrade (older to newer: the backup prompt, then Open with `--restamp`) or a downgrade (newer to older: the hard warning, `PromptNewerEngine`'s words).

### The toolchain (D5)

`Toolchain.Check(sdk, outReport)` gives one line per need, each with its state and fix:
- **BeefBuild:** `FindBeefBuild` as now (corlib checked), its `-version` shown beside the SDK's pin (a mismatch warns; it does not refuse while D5's "no pin" holds).
- **The linker:**
  - Linux: `clang++` or `c++`, and `ar`, on PATH, as BuildContext looks.
  - Windows: `link.exe` through Visual Studio's build tools, or `lld-link.exe`.
- **Emscripten** for web exports: `FindEmscripten` as now. The fix writes `[Wasm] EmscriptenPath` into a managed toolchain's own `BeefSettings.toml`. A user's own Beef install is only told what to set.

`ManagedBeefBuild` returns `<user-data>/Sedulous/Toolchains/<pin>/bin/BeefBuild` for the SDK's pin when present. That is the managed install `FindBeefBuildFrom` already asks last (`ProjectBuild.bf:1067-1069`). The Toolchain page installs it from the release (Q11).

### The editor without the manager

- `EditorMain`: no project means it starts the manager (found as below) with the same `--data-root`, then exits 0. With no manager it writes the usage and exits 2 (Q5).
- **Close Project** is always registered. It asks about unsaved pages, starts the manager, and the editor exits. With no manager found it says so and stays.
- **Finding the manager** (Q4): `--manager <path>` (the manager passes its own executable path); else the path the last manager to run recorded in `sdks.xml`; else `<sdk>/ProjectManager/` beside the data root the editor runs on.
- **What goes:** `ProjectManagerMode`, `StartInProjectManager`, `--release-files`, the Samples network fields, the drop-on-manager path, `host_info.screen` (`projectOpen` stays, always true), and `EditorWindow.ShowScreen` if nothing else uses it. `ShowScreen` has one other caller, `EditorWindowTests.bf:211`, so it stays only if wanted.
- `Editor.App` drops `Http.Client`, `Zip`, `Net.Tls` and `Net.Tls.MbedTLS` if no other file uses them. Today only the manager's files and `EditorApplication` do. `Mcp.Http`'s own needs are checked in the commit.
- The editor still records its open in the recent list (`EditorSession.bf:237`), through the projects file, re-read before it writes (Q3).

## SDK packaging

`python3 Code/Tools/pack-sdk.py <out-dir> --platform Linux64 [--manager <dir>] [--check]`, run by hand in a checkout like `pack-samples.py`. It packs the tracked files (`git ls-files`) of:

- **Libraries.** Every project under `cSdkLibraryDirs` but `Dependencies`, less projects named `*.Tests`.
- **Dependencies.**
  - Each `Dependencies/<dep>`'s BeefProj.toml, its compiled sources (`src/` unless the project names others), its licence files, and the `dist/` paths its BeefProj names for the platform and for wasm32.
  - Not the C sources, `build-native.*`, the dependency test projects (`*-Test`, `*.Test`) or `Bulkan/VulkanTriangle`.
  - `Dependencies/THIRD-PARTY-NOTICES.txt`.
- **Stock projects.** `Code/Tools/Sedulous.Tools.Editor/BeefProj.toml` and `Code/Tools/Sedulous.Tools.Mcp/BeefProj.toml` (read by Generate).
- **Bin.** `Bin/Naga` and `Bin/Tint`: the platform's binary, `VERSION` and `PROVENANCE.md`.
- **Data.** `Data/.dataroot`, `Data/Engine`, `Data/Editor` less `Mock/` (the GUI sandbox's), `Data/Branding` and `Data/Templates`. Not `Data/Samples`, `Data/Tests` or `Data/SampleProjects`, which the samples release carries.
- **Root files.** `LICENSE`, `CHANGELOG.md`, a short `README-SDK.md`, and `sdk.json`.
- **The manager.** Its ShippingRelease build, with the libraries and notices beside it, under `ProjectManager/`. It finds `<sdk>/Data` by the executable walk-up (`DataRoot.bf:31-50`).

It writes `sedulous-sdk-<display>-<platform>.zip`, with Unix modes set in each entry's external attributes, and `sdk-<platform>.json` (size, SHA-256, unpacked size, the Beef pin).

**`--check`** fails when:
- a packed project depends on a project that is not packed (the dependency closure over `[Dependencies]`);
- a packed project's platform or wasm32 config names a `$(ProjectDir)/...` path that is not packed;
- a packed source's `Compiler.Read*("../...")` path is not packed;
- a path Generate reads is missing (`cStockEditorProject`, `cStockToolsProject`, `cStockWebDir`'s files, Bin);
- `IsSdk` would not hold.

What leaves the SDK out of it on purpose: the Steam Deck build (Q10), CullBench, Samples, Integration, Deprecated, the test projects, and the engine's own `Code/BeefSpace.toml`. A project's workspace never reads that file; only `ProjectBuildTests` compares `cWorkspaceConfigs` with it.

## Toolchain shipping, concretely (Q11)

- **"Pin"** means `sdk.json`'s `beef` names one Beef: the fork's `working` commit, or a nightly's date and hash, that the release was built and tested with. `Toolchain.Check` compares it with `BeefBuild -version`.
- **"Ship"** means a release asset per platform, `beef-<pin>-linux64.zip`, installed by the manager on demand into `<user-data>/Sedulous/Toolchains/<pin>/`. It is shared by every SDK with that pin, so it is not inside each SDK.
- **Linux.** Built by a new `Code/Tools/pack-toolchain.sh` in the same Ubuntu 22.04 container the Steam Deck build uses, so it runs where SteamOS does. Its content:
  - `bin/BeefBuild` and the libraries it loads;
  - `bin/BeefConfig.toml` with `UnversionedLibDirs = ["../BeefLibs"]`, the install form `HasCorlib` already accepts (`ProjectBuild.bf:1110-1137`);
  - `BeefLibs/corlib` and what it needs;
  - the wasm runtime archives (`Beef042RT32_wasm*.a` in `IDE/dist` here);
  - Beef's licence, which joins the notices (AGENTS.md, third-party content).

  Built without `LINUX_PACKAGE`, so its settings, and Emscripten's path, sit beside it.
- **Windows.** Built on Windows the same way when a Windows host builds the Win64 SDK (D6).
- **Not shipped, and why.**
  - **The system linker** (Linux `clang++`/`c++` and `ar`; Windows MSVC build tools or LLVM). It is large, system-specific, and already present on a developer's machine or one package away. The manager checks for it and names the package.
  - **Emscripten** (about a web export only). It is documented, and the manager writes its path.
- **Documentation:** `Documentation/Shipping/Sdk.md`, the requirements per platform, what the manager checks, and how to use your own Beef (`BEEFBUILD`, PATH).

## Release process

`v<version>` carries:
- `sedulous-sdk-<display>-linux64.zip` and `sdk-linux64.json` (and `-win64` once a Windows host builds them);
- `beef-<pin>-linux64.zip` (and win64);
- what `pack-samples.py` writes (`samples.json`, `sample-<folder>.zip` and `.png`).

The order, on the release commit (AGENTS.md, Releases):
1. Cut the release commit and tag it.
2. Build `Sedulous.Tools.ProjectManager` in ShippingRelease.
3. `pack-sdk.py --check`, then `pack-sdk.py --manager <its build dir>`.
4. `pack-toolchain.sh`, when the pin moved.
5. `pack-samples.py`.
6. Make the GitHub release from the tag and attach everything.

A user's first download is the SDK zip. They unpack it anywhere and run `ProjectManager/Sedulous.Tools.ProjectManager`, which registers the SDK it sits in and offers the toolchain (Q8).

## Commits

Each commit lists its tests. ASan (`asan-test.py`) runs on every changed test project. No test runs a real BeefBuild (phase 5's rule); the real paths are checked by hand where marked.

1. **Editor.Projects: the headless half of the project manager and the build, out of Editor.Project.**
   - The types listed above move with their namespace. A `[SerializableRegistry]` of their own is called from `EditorSerializables.RegisterAll`. `ProjectScaffold.Create(dir, name)` is the directory scaffold `EditorProject.Create` wraps. `GamePackage.Scaffold(dir, settings, parts)` is added and the `EditorProject` overload wraps it.
   - Tests: new `Sedulous.Editor.Projects.Tests` takes `ProjectBuildTests`, `ProjectBuildServiceTests`, `BuildDiagnosticsTests` (with its fixture), `CodeWatchTests`, `ProjectRegistryTests` and the text cases of `GamePackageTests` from Editor.Core.Tests, at the same counts. Editor.Core.Tests, Integration.Mcp and Integration.Plugins pass unchanged.
   - Done: `Sedulous.Editor.Projects` (Core, Settings, Runtime, VFS, Xml.Serialization, Engine.Project; downloads move with commit 7) holds `ProjectBuild`, `ProjectBuildService`, `BuildDiagnostics`, `BuildLayout`, `PluginPackages`, `CodeWatch`, `ProjectRegistry` and `RecentProjects`, the recent list's two types, `ProjectManagerController`, the gate types, `NewProjectCheck`, `GamePackage` and the new `ProjectScaffold`; its registry is `EditorProjectsSerializables`. `GamePackage.Find` and `Scaffold` take a directory and settings, and their `EditorProject` overloads are an extension in Editor.Project. The recent list's two types and the registry take the namespace `Sedulous.Editor.Projects`, since a `[SerializableRegistry]` registers every type of its namespace it can see (the rest keep `Sedulous.Editor.Project`). The bed the build tests share (`ProjectBuildBed`, with the fake installs) is `Sedulous.Editor.Projects.TestSupport`, since Editor.Core.Tests' `PlayerBuildTests` builds over it too. `ProjectRegistryTests` moved without the editor store's seven section tests (every registered section instantiable, the MCP section twice, a store with every section, the font and UI sections of older builds, the preview resolutions), which need Editor.Core and stay in Editor.Core.Tests as `EditorSettingsStoreTests`; the moved twelve save the recent list through a store of their own. Of `GamePackageTests`' five cases, the three over a directory moved (the user's Code/ folder, NativeSample's shape, the parts gained), on the directory overloads; the two through an open project (scaffolded and saved, the refusals) stay.
2. **Editor.Projects: a project's header, and versions against a given engine.**
   - `ProjectHeader.Read`, `CompareEngineVersions`, `DecideOpen` against a version, and the parse-free manifest backup.
   - Tests: a manifest at a data version past 11 still gives its name and stamp; unstamped and malformed stamps; older, same and newer against 0.1.0 and 0.2.0; the backup of an unparseable manifest.
   - Done: `ProjectHeader.Read` skips the data versions and reads `name` and `engineVersion` by key through the XML serializer. `CompareEngineVersions` (with `ParseEngineVersion`) is what `CompareProjectEngineVersion` now calls against `EngineVersion.String`; a malformed `against` is Unstamped too. `DecideOpen(directory, engineVersion, decision)` gates on the header, and the old overload is it against this engine; `ProjectOpenDecision.Probed` became `Header`, and the controller's `Relocate` and `RemoveMissing` read headers too, so a project with newer settings is never dropped as missing. `BackupProjectManifest` copies the bytes and names the backup from the header, "unstamped" when it does not read. Tests: `ProjectHeaderTests` (4).
3. **Editor.Projects: SDKs.**
   - `SdkInfo` (from `sdk.json`, else `EngineVersion.bf`); `SdkRegistry` (`sdks.xml`, pins); `FindSdk` with the registry and the walk-up (D4's order); Generate records `sdk.txt`; `IsStale` follows the SDK.
   - Tests: two fixture SDKs (empty BeefProj files in `IsSdk`'s layout, each with its `sdk.json`); the order of the four sources; a pin beats a version match; final over beta over checkout; the walk-up from a project inside a fixture checkout; stale after an SDK switch and always for a checkout.
   - Done: `SdkInfo.Read` (sdk.json read by a small flat JSON reader, since the library links no JSON; else `EngineVersion.bf`'s constants, a checkout). `SdkRegistry` over `sdks.xml`, a settings store of `SdkRegistrySettings` (`RegisteredSdk`, `SdkPin`, namespace `Sedulous.Editor.Projects`), each change re-reading the file and writing it atomically, a damaged file refused rather than replaced; `Pick` and `Prefer` (a packed SDK before a checkout, then final, pre-release, dev, then the build number). `FindSdk(dataRoot, projectDir, outSdk)` asks the four sources in D4's order; its three callers pass the project's folder. An older reader passes an `[Appended]` field it does not know by (the keyed reader searches forward), so the registry types can grow that way. Generate writes `Code/.generated/sdk.txt`; staleness against the SDK is a new `IsStale(projectDir, settings, config, sdk)`, the three-argument one staying the sources-only check the editor's relaunch and `host_info` use. `ProjectBuildService` takes an `SdkFinder` for tests, since a scratch project sits inside the engine's checkout and the walk-up finds it. Tests: `SdkTests` (5); `ProjectBuildBed.WriteSdk`.
4. **Editor.Projects: the toolchain check and the managed install.**
   - `Toolchain.Check`, `-version` read, the linker search, `ManagedBeefBuild` by pin, the Emscripten path written into a managed `BeefSettings.toml`.
   - Tests: fixture installs (install layout and source layout corlib), a PATH with and without `clang++`/`c++`/`ar`, the settings file written and read back by `FindEmscriptenFrom`.
   - Done: `Toolchain.Check(sdk, outReport, probe)` reports BeefBuild, the linker, the archiver (not on Windows) and Emscripten, each Ok, Warning or Missing with its fix, read from a `ToolchainProbe` (the process's environment, or a test's, with `-version` run through a `BuildRunner`). The archiver is looked for as BuildContext does, `llvm-ar` before `ar` (BuildContext.bf:432-434), and both searches fall back to `/usr/bin/c++` and `/usr/bin/ar` when those are files. `BeefBuild -version` prints "BeefBuild <IDEApp.cVersion>", so the pin is compared by containment and a mismatch warns. On Windows a linker not on PATH only warns, since BeefBuild finds Visual Studio's tools itself. `ManagedBeefBuild(pin)` is `<user-data>/Sedulous/Toolchains/<pin>/bin/BeefBuild`; `FindBeefBuild` takes the pin (the build service passes its SDK's) and names a missing managed install among those tried. `WriteEmscriptenPath` sets `[Wasm] EmscriptenPath` in the `BeefSettings.toml` beside a BeefBuild through `SetTomlString`, keeping every other line. Tests: `ToolchainTests` (3).
5. **Zip: an entry's Unix mode is kept on extract.**
   - Tests (`Sedulous.Zip.Tests`): a fixture zip made by Python's `zipfile` with a 0755 and a 0644 entry; the modes after `ExtractAll`; an entry from a non-Unix host keeps the default.
   - Done: `ZipEntry.Mode` is the permission bits (0777, no file type, setuid, setgid or sticky) of an entry whose "version made by" names a Unix or Darwin host, 0 otherwise; `ExtractAll` sets them on each file it writes (Linux and macOS), folders keeping theirs. The fixture `Data/Tests/Zip/modes.zip` (from `make-fixtures.sh`) holds `bin/tool` (0755), `readme.txt` (0644) and `dos.txt` (a DOS host's, carrying 0755 in its attributes, which is ignored). Tests: `ZipTests.AnEntrysUnixModeIsKeptOnExtract` (1). No CHANGELOG line: nothing a user downloads today carries an executable.
6. **Editor.Look: the editor's look in a library of its own.**
   - `EditorResources`, `EditorUiSettings`, `EditorLook` and the host-and-sheet setup move. `EditorWindow` keeps the dock, frame, toasts and status bar over them.
   - Tests: Editor.App.Tests' `EditorWindowTests` and the "under the editor's sheet" launcher tests unchanged; new `Sedulous.Editor.Look.Tests` for the sheet's assembly and a theme override.
   - Done: `Sedulous.Editor.Look` (Core, Profiler, Settings, VFS, Image, Image.IO, VG.SVG, Graphics, Shell, Fonts with TrueType, HarfBuzz and Bidi, GUI, GUI.Hosting) holds `EditorResources` (namespace `Sedulous.Editor.Core` kept), `EditorLook` and `EditorAccent` (`Sedulous.Editor.App` kept), `EditorUiSettings` and the new `EditorLookHost`. `EditorUiSettings` takes the namespace `Sedulous.Editor.Look` with its registry `EditorLookSerializables`, called from `EditorSerializables.RegisterAll`, which renames its former name; the recent list's renames now lead to `Sedulous.Editor.Projects` (commit 1 moved its namespace without one, so a store saved before it lost the list). `EditorLookHost` is the GUI host, the fonts, the editor's files, the theme overrides, the sheet and its reload, the sweep and the window description; the caller registers its satellites' elements and passes their sheets, fills `Root` and attaches its window. `EditorWindow` keeps the frame, the status bar, the toasts and `ShowScreen` over it, its look constants and `SheetFor` naming the host's. Editor.Core links the look, so what reaches the UI section through it needs only the using. `EditorSheet` and the markup reader (`EditorData`) are `Sedulous.Editor.Look.TestSupport`, the Editor.App tests' `PagesBed.LoadMarkup` reading through it. Tests: `EditorLookHostTests` (3); `EditorSettingsStoreTests.SectionsSavedUnderTheNamesTheyHadBeforeTheyMovedRead` (1). The Editor.Projects test support library joins the wasm32 lines that disable its siblings.
7. **Editor.ProjectManager: the manager's view and samples, out of Editor.App.**
   - `ProjectManagerView`, the samples types (`SampleDownload` generalised to `ReleaseDownload`), `ProjectPicture`, and `ProjectManagerApp`. The editor's `ProjectManagerMode` becomes a thin adapter over it until commit 13.
   - Tests: `ProjectLauncherTests` and `SampleDownloadsTests` move to new `Sedulous.Editor.ProjectManager.Tests` with the `EditorSheet` fixture, at the same counts; `ProjectManagerModeTests` stay.
   - Done: `Sedulous.Editor.ProjectManager` (Core, Shell, Image.IO, GUI, Engine.Project, Projects, Look, Json, Http, Http.Client, Zip, Net.Tls, Net.Tls.MbedTLS) holds `ProjectManagerView`, `SampleInfo`, `SampleCatalog`, `ReleaseFolder` and `ProjectPicture` (namespace `Sedulous.Editor.App` kept), and the new `ReleaseDownload` and `ProjectManagerApp` (`Sedulous.Editor.ProjectManager`). `ReleaseDownload` is `SampleDownload` over a URL, a digest, a size and a target, extracting or keeping the file under the target's name; the view pairs each with its sample. `ProjectManagerApp` is the old mode without the session: the gate's prompts, the backup and New Project's refusal are its own, and opening and making a project are its host's (`OpenProject(directory, restamp)`, `CreateProject`). `ProjectManagerMode` is the editor's adapter: its services and calls as before, Open through the session (stamping when asked), New Project scaffolding and seeding there, Close Project its own. The thumbnail's path is `ProjectThumbnail.PathOf` in Editor.Projects (`EditorProject.ThumbnailPath` calls it), so the manager reaches it without Editor.Project. Tests: `ProjectLauncherTests` (20), `SampleDownloadsTests` (4) and `LoopbackFiles` moved; new `ReleaseDownloadTests` (1); `ProjectManagerModeTests` (4) stay. The helpers both reach (`LauncherDialogs`, `LauncherClipboard`, and `LauncherKit`'s `ButtonText` and `Stamp`) are `Sedulous.Editor.ProjectManager.TestSupport`; the moved tests make projects with `ProjectScaffold.Create` and read markup through `EditorData`.
8. **Tools.ProjectManager: the manager as its own executable.**
   - `ProjectManagerMain.Run` makes the window (Look), the store (`projects.xml`, migrating the recent list from `editor.settings.xml` once), and the flags `--data-root`, `--release-files`, `--screenshot`, `--screenshot-exit`, `--exit-after` and `--version`. It registers its own SDK and records its path. Open launches the stock-built editor of the SDK it sits in, until commit 9.
   - Tests: ProjectManager.Tests drive `ProjectManagerApp` headless: the migration, the self-registration, the recorded path.
   - By hand: `--screenshot` of the Projects and Samples tabs. Measure the ShippingRelease binary's size.
   - Done: `ProjectManagerProgram` (the library's `IApplication`) holds the window through `EditorLookHost`, the look read from the editor's store, the recent list in `projects.xml` through the new `ProjectsStore` (Editor.Projects: the first load with no file takes `RecentProjectsSettings` from `editor.settings.xml` and writes `projects.xml` either way, so it happens once; a file that does not read is never saved over), the SDK it sits in (its data root's parent) listed by `SdkRegistry.Adopt`, which keeps how a listed SDK was listed, and its executable recorded by `RecordManager` in `SdkRegistrySettings.ManagerPath`, an `[Appended]` field. Open launches the stock editor built in that SDK (`Code/build/<Debug|Release|ShippingRelease>_<Host>/Sedulous.Tools.Editor`) with `--project` and `--data-root <sdk>/Data`, records the open and exits; New Project scaffolds the folder and manifest (`ProjectScaffold.Create`) and opens it the same way, without starter content until the templates. `ReleaseAccess` (the TLS client made on first use and the `--release-files` source) serves both the program and the editor's manager mode, which loses its own copy. The former names of the recent list and the UI section are registered by `ProjectsStore.RegisterFormerNames` and `EditorUiSettings.RegisterFormerName`, which `EditorSerializables` calls, since the manager loads both stores without it. `ProjectManagerMain.Run` (the flags `--data-root`, `--release-files`, `--screenshot`, `--screenshot-exit`, `--exit-after`, `--version`) sits in `Code/Tools/Sedulous.Tools.ProjectManager` beside its one-line `Main`, not in the library: Editor.App links the library for `ProjectPicture`, and the SDL3 shell and the GPU device would follow it into the editor's libraries and their tests. Tests: `ProjectManagerProgramTests` (3: the migration once, the self-registration and the recorded path, Open's launch and record). No CHANGELOG line yet: the manager is not shipped until the SDK is packed, and commit 16 adds its line.
9. **Project manager: Open builds the project's editor, then launches it.**
   - The flow above. The Editor job without a package (Generate with zero packages for the editor). The editor's `--restamp` and `--manager`.
   - Tests:
     - ProjectManager.Tests with a fake `BuildRunner` and a fake launcher: the order (gate, then toolchain, then build); a failure shows diagnostics and launches nothing; cancel; the launch line; exit after launch.
     - Projects.Tests: a zero-package Editor job generates and runs its step.
     - Editor.App.Tests: `--restamp` stamps once on open.
   - By hand: SkyHopper opened from the manager against the checkout. Measure the first open's time and memory and put the numbers in `Sdk.md`.
   - Done: `ProjectManagerApp.OpenFrom` reads the header, asks its host the engine to gate against (`EngineFor`: the program picks the SDK with `ProjectBuild.FindSdkFrom` over SEDULOUS_SDK, the registry, its data root and the walk-up, a test's `ProjectManagerConfig.FindSdk` in its place; with none, "This project needs engine X: Install it, or choose another engine (it will be upgraded)") and runs `DecideOpen` against that SDK's version. The program's open (`OpenInEditor`) refuses while a build runs (one at a time: a second Open is refused, not queued), picks the SDK again, runs `Toolchain.Check` (a missing BeefBuild, linker or archiver stops it with the first fix on the status line), reads the settings with `ProbeProject` (a manifest at data versions this manager cannot read is refused, telling the user to open it with its engine's manager: the build needs the plugins list, not just the header), and launches at once when the four-argument `IsStale` says the Debug editor is current over that SDK; else `EditorBuildRun` runs an Editor job of a `ProjectBuildService` (the BeefBuild the check found, the picked SDK as its finder, the config's `Runner` or `Process.RunStreaming`) on a thread of its own, and `Pump` (each frame) launches the built editor once it ends, or says why not. `EditorBuildPanel` (`Data/Editor/BuildEditor.xml`) shows the step, the last 12 lines, the diagnostics (a click copies "file:line") and how it ended, with Cancel; a close mid-build cancels. The launch is `--project <dir> --data-root <sdk>/Data --manager <this executable> [--restamp]`, then the open recorded (with the SDK's version when restamped) and the exit. `ProjectManagerAppServices` gains `EngineFor`, `StaysWhileOpening` (the manager stays under the panel) and a why on `OpenProject` and `CreateProject`. `ProjectBuildService` drops the refusal of an Editor job for a project with no package. The editor's `EditorAppConfig.ReadCommandLine` (moved from `EditorMain`, so a test reads it) takes `--restamp` and `--manager`; `EditorSessionOpenOptions.Restamp` saves the manifest once as the project opens, before the recent list records it, and the editor's manager mode opens through it; `EditorApplication.ManagerPath` keeps the manager for Close Project. Tests: `ProjectOpenTests` (4: the build then the launch line and the exit, and a fresh editor launched with `--restamp` and no build; the gate, then the toolchain, then the build; a failure's diagnostics on the panel and no launch; cancel, and a second open refused while one builds); `ProjectBuildServiceTests.AnEditorBuildsWithoutAPackage` (1, `ABuildNeedsAnSdkAndAPackage` now `ABuildNeedsAnSdk`); `EditorSessionTests.AnOpenToldToRestampStampsTheProjectOnceAsItOpens` (1); `ProjectManagerProgramTests`' Open test went to `ProjectOpenTests`. No CHANGELOG line: the manager is not shipped until the SDK is packed.
   - Checked by hand (2026-11-10): the manager's `--open <folder>` (added for checks and scripts) opened SkyHopper against the checkout: it generated the workspace, built `SkyHopperEditor` (Beef 28 s, 35 s in all, an incremental build over an earlier one; the manager's process tree peaked at 3.3 GB) and launched it with `--project`, `--data-root` and `--manager`, then exited. A cold first build is still to be measured for `Sdk.md`.
10. **Project templates: Empty and Starter; New Project and `project_create` make projects from them.**
    - The template folders and their authoring script, instantiation, New Project's template list and engine picker, and `project_create`'s `template`. McpGuide's `project_create`.
    - Tests:
      - Projects.Tests: instantiation (placeholders, GameName's rules, the `.gitignore`, nothing written outside the target, a refused non-empty target);
      - Integration.Mcp: each template reads at the current data versions and cooks (beside `SampleProjectTests`), and `project_create` with each template;
      - ProjectManager.Tests: New Project's list.
    - Done: `ProjectTemplates` (Editor.Projects) lists an SDK's `Data/Templates/<Id>/` (each folder with a `Template.xml`: name, description, picture, order, read by key as the header is; by order, then name; another folder there, the sky or `Tools/`, passed by), finds one by its folder alone, and `Instantiate`s it: the tree copied less `Template.xml`, its picture and what builds, cooks and the editor write (at the root and in `Code/`), the placeholders replaced in paths and in every file with no zero byte (a binary is copied as it is), the root `.gitignore` written (`RootIgnoreText`, NativeSample's) when the template has none, and the fixed folders made. Besides `__PROJECT_NAME__` (escaped in an `.xml` file) and `__GAME__` there is a third placeholder, `__GAME_ID__`, the package's id (`PluginIdFromName` of the game name), which the manifest's plugin entry, `Plugin.xml`, the starter behaviour's `[Behaviour]` id and a scene's records name. A target that holds anything is refused (AlreadyExists), as is one whose parent is missing, a folder that is no template and a template with no manifest, each with nothing written; a copy that fails part way takes away the target it made. The templates are made by `Data/Templates/Tools/make-templates.py` over the stdio host: `project_create` (template `none`, the Starter `seed`ed), `plugin_scaffold` (Engine), the Starter's scene `Main` (a floor, a cube, a sun and a camera, from `component_schema`) as its default scene; then what the host wrote goes and the seed names (`Sedulous Template Seed`, `SedulousTemplateSeed`, `seduloustemplateseed`) become the placeholders, and it refuses to finish with a seed name or a path of the machine left. The Starter's scene does not carry `Rotator`: the stock host does not link the template's code, so the behaviour is in `Code/` alone. `project_create` takes `template` (a folder of the host's `Data/Templates`, default `Starter`; `none` the bare project, seeded with `seed`) and answers `template`; a host with no data root makes the bare project, as before, so the tests that pass none are unchanged. New Project lists the engines (`ListEngines`: the registered SDKs, the newest version first, then `SdkRegistry.Prefer`) and the picked engine's templates (Starter picked, its line under the list); an engine with none keeps Create waiting; the editor's own manager mode offers neither and shows neither. The program's Create instantiates the picked template, pins the project to the picked SDK and opens it as any other. Tests: `ProjectTemplateTests` (4); `ProjectLauncherTests.NewProjectListsThePickedEnginesTemplatesWithStarterPicked` and `NewProjectShowsNoEngineOrTemplateWhereTheHostOffersNone` (2); `ProjectOpenTests.NewProjectMakesTheProjectFromTheEnginesTemplatePinsItAndOpensIt` (1); Integration.Mcp `TemplateTests` (3, over the templates the script makes); `ProjectFlowTests`' seeded test asks for `none` with `seed`.
11. **Project manager: engines side by side.**
    - The Engines page: installed, available, install, add folder, remove, a project's pick, upgrade and downgrade. The Toolchain page: the checks, installing the pinned toolchain, setting Emscripten.
    - Tests (ProjectManager.Tests, a loopback `HttpServer` serving fake release files as the Samples tests do): the list; a verified install; a bad digest refused leaving nothing; remove with pinned projects named; pin; upgrade runs backup, build and `--restamp` in order.
    - Done: `EngineManager` (Editor.ProjectManager) is the headless half. `ReadInstalled` lists the registry's engines through the new `SdkRegistry.ReadListed` (root, `Managed`, the `SdkInfo` or null for a missing one), each with its kind (installed: listed as managed and inside the managed folder; a folder; a checkout), the manager's own marked, and the projects that open with it (a recent project pinned to it or given it by `Pick` for its stamp, and any other pinned to it: the new `SdkRegistry.PinnedTo`). `FetchAvailable` reads GitHub's releases list of `ReleaseRepository` (drafts passed by), then the index `sdk-<platform>.json` of each release that carries one (lowercase platform), on demand and kept until asked again; a release whose index does not read is logged and passed by. The index's format is set here for commit 14 to write: `version`, `label`, `display`, `platform`, `archive`, `sha256`, `size`, `unpackedSize`, `beef`, and `toolchain` (`archive`, `sha256`, `size`, `release`: the tag whose files carry it, absent for this release, since a release whose pin did not move does not carry the toolchain again) (`EngineReleases`). `Install` is a `ReleaseDownload` into `<user-data>/Sedulous/SDKs/<display>-<platform>` (refused when anything is there), then the unpacked folder must read as an engine of the index's version before `Register(target, true)`; else it is deleted, so a wrong digest, a cancel or an archive with no engine keeps nothing. `AddFolder` is `Adopt` (an `IsSdk` folder that reads). `Remove` deletes an installed engine's folder (only one inside the managed folder) and only unlists any other, then takes every pin to it away (the new `SdkRegistry.UnpinAll`), so its projects fall back to an engine of their version; the engine the manager runs from and one being installed are refused; `RemovalQuestion` words the confirmation, naming those projects. The toolchain: `CheckToolchain` is `Toolchain.Check`; `InstallToolchain` reads the engine's release index for the toolchain's zip and digest, downloads it into `Toolchains/<pin>` and requires BeefBuild with corlib there (`ManagedBeefBuildIn`, `HasCorlib`); `SetEmscripten` checks the folder has `upstream/emscripten/emcc` and writes it through `WriteEmscriptenPath` for the managed toolchain only, a BeefBuild of the user's own being told what to set. Messages and changes are counted (`MessageSerial`, `ChangeSerial`), which the view puts on the status line and the pages lay out from. The view gains `ManagerPage` and the Engines and Toolchain tabs (shown with an engine manager alone: `EnginesPage`, `ToolchainPage`, markup in `ProjectManager.xml`); a project's menu gains the submenu "Engine: <display> (<kind>)" over the listed engines, the one it opens with checked. `ProjectManagerApp.PickEngine` gates on the picked engine's version: the same version only pins (`PinEngine`, the program's `SdkRegistry.Pin`); another asks the open gate's question, and `EngineChosen` backs up when asked, pins, then opens (the build over the pinned engine, `--restamp` for an upgrade; a downgrade's Open Anyway keeps the stamp, as Open does). With `--release-files` the list is the folder's `releases.json` and every file is read by name. The program's config gains `SdksDirectory`, `ToolchainsDirectory`, `ReleasesUrl`, `AssetUrl` and `Http` for tests; `ListEngines` gives each engine's version, display and kind. Fixtures `Data/Tests/Zip/sdk.zip` and `toolchain.zip` (from `make-fixtures.sh`). Tests: `EngineManagerTests` (6: the list and what the releases offer; a verified install; a bad digest, and an archive with no engine, keeping nothing; remove naming the projects; the toolchain installed and Emscripten written, Linux only; the tabs over the markup); `ProjectOpenTests` (2: a pick of the project's version only pins, an older one asks; an upgrade backs up, builds over the newer engine and launches with `--restamp`, in order); `SdkTests.TheListReadWithHowEachWasListedAndThePinsToAnSdkFoundAndTakenAway` (1). No CHANGELOG line: the manager is not shipped until the SDK is packed.
12. **Project manager: samples per engine.**
    - The tab's SDK picker, URLs from the SDK's display, the download pinned.
    - Tests: the moved Samples tests over two fixture SDKs.
    - Done: where the services offer engines (the program's `ListEngines`), the Samples tab's toolbar has an engine picker, the newest picked at first and the pick kept while the engine is listed (listed again each time the tab shows); a pick fetches that release's `samples.json` (the pictures of the last one's cancelled). Every file of it is fetched from the picked engine's display (`SamplesVersion`): the services' `ReleaseFile` takes the version, else `EngineReleases.DownloadUrl` of tag `v<display>`; `ReleaseAccess.FileUrl(version, file)` does the same, and `--release-files` stands in for every version's release. A sample downloaded is recorded from its header, not its settings, and pinned to the engine whose release it came from (`ProjectManagerServices.PinEngine`, the program's `SdkRegistry.Pin`). The editor's own manager mode offers no engines: no picker, and its own version's release, as before. Since a sample of another engine may be at data versions this manager does not read, the projects list, a dropped folder and Open Folder tell a project by its header too (a newer engine's project is listed, not missing). Tests: `ProjectLauncherTests`' two Samples tests over two fixture SDKs (`SampleEngines`: 0.2.0-beta and 0.1.0, each with its sdk.json): the newest's release listed, the other picked lists its own and its sample's download is pinned to it; each release's "no samples" names its version; no picker and this engine's release without engines. No CHANGELOG line: the manager is not shipped until the SDK is packed.
13. **Editor: the project manager mode goes.**
    - Everything listed under "What goes"; `EditorMain`'s no-project path; Close Project always, through the manager.
    - Tests:
      - Editor.App.Tests: `EditorApplicationTests` without the manager; Close Project starts the given manager (fake launcher) and exits; with none it stays and says so. `ProjectManagerModeTests` deleted.
      - The MCP `host_info` test without `screen`.
    - McpGuide 16-24 rewritten: the editor always has a project; the manager has no MCP (Q13).
14. **SDK packaging: `pack-sdk.py`.**
    - The packer, `--check`, `sdk.json` and the index.
    - Tests: Integration.Mcp runs `pack-sdk.py --check`, as it runs the notices check.
    - By hand: pack, unzip outside the checkout, register it in the manager, open SkyHopper (its editor built against the SDK), PIE, and export Linux64 and Web.
15. **Toolchain: the pin and `pack-toolchain.sh`.**
    - Linux64 in the container; `Sdk.md`'s requirements.
    - Tests: Projects.Tests' fixture of the packed layout accepted by `HasCorlib`.
    - By hand: build SkyHopper's editor with only the managed toolchain (no Beef on PATH, `BEEFBUILD` unset).
16. **Docs and the release process.**
    - AGENTS.md: Releases, Build and Sample projects (the Samples tab is the manager's; the editor needs `--project`).
    - README: downloading the SDK, the manager.
    - `Sdk.md`.
    - `third-party-notices.py`'s docstring ("an export template carries it as a sidecar" is stale since phase 5).
    - CHANGELOG under Unreleased:
      - Added: the project manager as its own program, engines side by side, project templates, toolchain checks;
      - Changed: the editor opens one project, and Close Project returns to the manager;
      - Removed: the editor's project manager screen and `--release-files`.
    - `x2.md`: phase 7's boxes, and phase 1's "born with Code/" and templates.

Commits 2 to 5 follow 1, in any order. Commit 6 goes before 7, 7 before 8, and 8 before 9 to 12. Commit 13 needs 9 and 10. Commit 14 needs 8. Commit 15 is independent, but its pin goes into commit 14's `sdk.json`.

## Risks

- **The first open of every project compiles the engine.** A project's editor links the whole editor and engine, and Beef keeps no build cache across workspaces, so each project's first open is a full Debug build. Phase 5 measured a full optimised engine build at about 16 GB on this machine. A Debug editor build of a project is not measured; commit 9 measures it. The manager must say so before the first build of a project, and never start two builds at once (one worker; a second Open waits). See Q6 for the alternative.
- **Disk.** Each project keeps a `Code/build` of hundreds of megabytes per config (phase 5's risk), now for every project, not only those with code.
- **Mixed versions over shared user files.** Several managers (one per SDK, Q8) and editors read `projects.xml`, `sdks.xml` and `editor.settings.xml`. A `[Serializable(n)]` type read at another `n` is refused (`SerializableAttribute.bf:44-46`). So the registry types never bump their version, and grow only with `[Appended]` fields. Whether an older reader skips an `[Appended]` field it does not know must be checked in commit 3 before relying on it; if it does not, those two files are JSON instead.
- **Two writers of the recent list.** The manager and an editor can both write it. Each re-reads before writing and writes small files (Q3). The last writer wins a true race, which loses at most one recency bump.
- **Win64.** No Win64 SDK until the four missing Win64 dists are built on Windows (the Backlog's Jolt item, `Backlog.md:34-38`, is the same kind of work, already owed). The first release is Linux64 alone (D6).
- **Steam Deck from an SDK** cannot work as the script stands (git, native sources). See Q10.
- **GitHub's API.** Listing releases unauthenticated is rate-limited. The page lists on demand, never on a timer, and caches the last answer.
- **Downloads of executables.** SDKs and toolchains are checked against SHA-256 values from the release's index, fetched over TLS. The index itself is trusted as GitHub serves it, as the samples are now.
- **Beef drift.** Without a pin (D5 today), a user's newer Beef can fail on an SDK built with an older one. The pin's warning names both.

## Open questions (decided 2026-11-10: each recommendation, the first option, taken)

- **Q1. The headless split.**
  - *Rec:* a new `Sedulous.Editor.Projects` taking the registry, gate, build, SDK and toolchain types out of `Editor.Project`, namespace kept.
  - The alternative links `Editor.Project` whole into the manager. That needs no move, but the manager then compiles and links the cook, the pipelines, the shader resource and Engine.Composition.
- **Q2. The manager's look.**
  - *Rec:* `Sedulous.Editor.Look` (EditorResources, EditorUiSettings, EditorLook and the host setup), so both programs share one sheet and the user's appearance choices.
  - The alternative is a manager window of its own with the editor's sheet files and fixed defaults: no move, but two hosts to keep in step.
- **Q3. Where the recent list and the SDK registry live.**
  - *Rec:* two small files in the user data folder, `projects.xml` (the recent list and its layout, migrated once from `editor.settings.xml`) and `sdks.xml`, each re-read before a write.
  - The alternative keeps the recent list in `editor.settings.xml`, which the editor writes whole from what it loaded at its start, so a manager's change while an editor runs is lost.
- **Q4. The manager while an editor runs, and how the editor finds it.**
  - *Rec:* the manager exits after launching. Close Project starts it again through `--manager <path>`, else the path recorded in `sdks.xml`, else `<sdk>/ProjectManager/`.
  - The alternative keeps the manager open as a hub (and single-instance), so Close Project only has to raise it.
- **Q5. The editor run without a project.**
  - *Rec:* it starts the manager when it finds one and exits 0, else usage and exit 2.
  - The alternative is usage and exit 2 always.
- **Q6. A project without code.**
  - *Rec:* it builds its own editor like any other (Generate with zero packages), and every new project has `Code/` from its template: one path, a source SDK.
  - The alternative ships a prebuilt editor in each SDK for projects without code: their first open is instant, but the SDK grows by an editor binary per platform (the Release editor was 201 MB) and keeps a second path alive.
- **Q7. Which SDK a project uses.**
  - *Rec:* Project.xml's stamp is the version it needs (D4). A per-user pin in `sdks.xml` picks among SDKs of that version (a beta, the final, a checkout). An SDK of another version is an explicit upgrade or downgrade.
  - The alternative is a new Project.xml field naming the SDK. It would be shared through version control, but SDK roots are per machine.
- **Q8. What a user downloads first, and where the manager lives.**
  - *Rec:* the SDK zip, with its manager in `ProjectManager/`. Any manager uses the shared registry and registers the SDK it sits in.
  - The alternative is a separate manager download that installs SDKs. It is cleaner with many SDKs, but adds a second artifact and its own update question.
- **Q9. Where available SDKs are listed.**
  - *Rec:* the GitHub releases list of `ReleaseRepository`, each release's `sdk-<platform>.json`.
  - The alternative is an index file on the default branch. It needs no API, but has to be kept in step by hand.
- **Q10. Steam Deck exports from an installed SDK.**
  - *Rec:* not in the first SDK. `SteamDeckPlayerBuilder` refuses there with "a Steam Deck build needs an engine checkout".
  - The alternative packs the dependencies' native sources (about 109 MB more) and the Deck scripts, and changes `build-steamdeck.sh` to take a file list instead of `git ls-files`.
- **Q11. The toolchain (D5's "pin, then ship or document").**
  - *Rec:* pin at the first SDK release (`sdk.json`'s `beef`). Ship a managed Beef as its own release asset per platform, built by us (Linux in the 22.04 container), installed on demand and shared by SDKs with the same pin. Document and check the system linker and Emscripten rather than ship them.
  - The alternatives: Beef inside every SDK (simplest to use, but every SDK carries it and it cannot be shared), or document only (a user must find a Beef that matches).
- **Q12. Templates.**
  - *Rec:* folders in the SDK, instantiated by copying with placeholder substitution, authored by a script over MCP. Note that every project made from a template shares the template's asset GUIDs; nothing found here requires GUIDs to differ across projects.
  - The alternative has the manager link the scaffold and seed code (`ProjectSeed` needs the import pipelines), which undoes Q1.
- **Q13. MCP in the manager.**
  - *Rec:* none. Agents create and open with the stdio host (`project_create`, `project_open`) and run `<Game>Editor --mcp` themselves. The manager has `--screenshot` and `--exit-after` for checks.
  - The alternative serves the GUI tools (`editor_screenshot`, `editor_click`) from the manager, as the editor's manager screen does today.
- **Q14. A project's editor started by hand.**
  - *Rec:* the generated Main passes the SDK's Data as a fallback data root, so it starts from the Beef IDE.
  - The alternative requires `--data-root` always, as today.
- **Q15. Names.** `Sedulous.Editor.Projects`, `Sedulous.Editor.Look`, `Sedulous.Editor.ProjectManager`, `Sedulous.Tools.ProjectManager`, `sdk.json`, `projects.xml`, `sdks.xml`, `pack-sdk.py`, `pack-toolchain.sh`.
  - *Rec:* as written.
