# x2 phase 5: export without templates

**Status:** design agreed, 2026-11-09. Rulings: every recommendation followed (Q1-Q14), except Q9, where cimgui is built for wasm (like the other dependencies with a `dist/Release-wasm32`) and Imgui keeps Web. It expands phase 5 of `x2.md` (lines 180-198), under D1 (the workspace is generated before each build), D5 (BeefBuild discovery) and D6 (each host builds its own platform). It changes no data except the presets (Q5) and adds one preset field (Q6).

**Names.** `x2.md` phase 5 writes `<Game>.Player` and `<Game>.Player.Web`. Phase 1 generated them without a dot, as `<Game>Player` and `<Game>PlayerWeb` (`ProjectBuild.bf:95-97`), because the dotted names belong to the parts. This document uses the undotted names, and commit 13 fixes `x2.md`.

## What exists

### The export, end to end

There is one entry point, `ExportDriver.ExportOne` (`Code/Editor/Sedulous.Editor.Project/src/ExportDriver.bf:475-677`). `ExportAll` (680-708) loops over it. For one preset it does this:

1. **Template.** `templates.Resolve(preset)` (481). The preset's `TemplateId` is used when set; otherwise `FindBy(platform, config)` (`TemplateRegistry.bf:61-103`), where an imported bundle beats the host one. With no template the export is refused with NotFound (482-486). A template stamped with another engine version only warns (501-505).
2. **Player choice.** `ExportPlugins.ChoosePlayer` (`ExportPlugins.bf:67-116`) runs over the project's plugin entries:
   - An entry with a path (the project's own package) on the host platform means the project's own player (`OwnPlayer`).
   - On any other platform that entry is refused: "a template carries no project package" (88-92).
   - An engine plugin must be carried by the template (`TemplatePlugin`, from the player's `--plugins`) at a version at least its manifest's (100-112).
3. **Own player.** `ProjectBuild.FreshPlayer` (`ProjectBuild.bf:1117-1130`) must find `Code/build/<Config>_<Host>/<Game>Player/<Game>Player`, newer than every file of the packages. Otherwise the export is refused: "Build Project first" (`ExportDriver.bf:518-529`). The config comes from `BuildConfigFor` (`ProjectBuild.bf:847-855`): Release maps to ShippingRelease, Profile to Release, and Debug and Test stay as they are. The export never builds anything itself.
4. **Script check.** `CheckScriptsOn` runs (534; goes in phase 6).
5. **Content.**
   - The cook: whole (`ExportProject`, 393-430) or the reachable closure (`CookReachable`, 132-158).
   - The web variant cooks (`CookVariantTargets`, 197-227).
   - `ExportContent` (236-390): scenes staged as binary; custom shaders recorded and staged stripped; one pak per variant (`Content.pak`, or `Content-bc.pak` and `Content-astc.pak` on the web, 334-349); `player.xml` through `ProjectManifest.Copy` (351-369); and the pruning report.
   - `ApplyPresetDisplay` (441-473) applies the preset's render, window and orientation overrides.
6. **Player staging.** The player is copied as `PlayerOutputName(platform, preset.PlayerName, template.PlayerBinary)` (`ExportStaging.bf:163-171`). It is the project's own player, or `template.PlayerBinary` (594-608).
7. **Shader pack.** `StageShaderPack` (`ExportStaging.bf:196-281`) writes `Data/Engine/Shaders/shaders.dpak` and `Data/.dataroot` from the data root's Shaders and the project's shaders. It uses SPIR-V, DXIL or WGSL by platform; WGSL needs naga and tint beside the exporting tool.
8. **Sidecars.**
   - Every `template.Sidecars` entry except DXC (620-633). For the host template that is the shared libraries beside the player, plus `THIRD-PARTY-NOTICES.txt` (`ExportTemplates.SynthesizeHost`, 51-84).
   - For a web template it is the `.js`, `.wasm`, `serve.py`, the logo and the notices (`BuildLayout.CollectWebParts`, 146-159).
   - With the project's own player, the template still gives the sidecars (515-517). The test at `ExportDriverTests.bf:341` asserts this.
9. **Symbols, extras, deploy files, hooks.**
   - `template.Symbols` when `StageSymbols` is set (634-643).
   - `preset.AdditionalFiles` (644-650).
   - Each enabled plugin's deploy files, from `ExportPlugins.PackageDir`: the project's package, the template's `plugins/<id>/`, or the host checkout's `Code/Plugins` (`ExportPlugins.bf:43-59`, `196-221`).
   - The plugins' export hooks (657-673).

**What a template contributes, and nothing else:** the player binary, its runtime libraries and the notices, symbols, the engine plugins it links with their manifests and deploy files, an engine-version stamp, and an icon (`ExportTemplate.bf:13-66`). Everything else is the driver's.

### Every caller of the template machinery

- **Library** (`Code/Editor/Sedulous.Editor.Project/src`):
  - `ExportTemplate.bf` (manifest, `TemplatePlugin`).
  - `ExportTemplates.bf`: `ResolveRoot` and `SEDULOUS_TEMPLATES_DIR`; `SynthesizeHost` 51-84; `Create` 114-211; `ReadPlayerPlugins` and `HostPlugins`, which run the player with `--plugins`, 240-276; `PackagesRootOf`/`FindPackage` 281-316; `CarryPluginFiles`; `Import`/`Remove`; and the general `CopyFile`/`CopyTree` 398-444.
  - `TemplateRegistry.bf`, `TemplateOutput.bf` and `TemplateIcons.bf` (121 lines; the Export dialog also draws presets by platform icon).
  - In `BuildLayout.bf`: `cPlayerBaseName` 15, `cTemplateIdPrefix` 17, `PlayerDirectoryBeside` 82-85 and `TemplateConfigFor` 118-125.
  - `ExportPreset.TemplateId` 26-28, and the template wording in `PlayerName` (29-31) and `StageSymbols` (41-43).
  - `ExportResult.EngineVersionWarning`.
  - `ExportPlugins.ChoosePlayer`, `PackageDir` and `FindManifest`.
- **Host template synthesis, by the player directory beside the running tool:**
  - `EditorExport.BuildTemplateRegistry` (`Editor.App/src/EditorExport.bf:146-150`) and its job (279-280).
  - `EditorProjectOperations.PlayerDir`/`TemplatesRoot` (`EditorProjectOperations.bf:30-32`) and `SubmitExportJob` (347-380).
  - `EditorMcpService.bf:243`.
  - `InlineProjectOperations` (`Editor.Mcp/src/InlineProjectOperations.bf:28,36-38`, `RunExport` 144-170).
  - `McpMain.bf:101`.
  - `ExportPresetTools.RefreshTemplates` (`Editor.Mcp/src/ExportPresetTools.bf:54-58`).
  - In a project's own editor that directory is `Code/build/<Config>/Sedulous.Engine.Player.Desktop`, which a project build never makes. So the host template is empty there, which is why phase 4's samples could not export.
- **Editor UI:**
  - `TemplatesDialog.bf` (603 lines) and `Data/Editor/Templates.xml`.
  - The `edit.exportTemplates` action (`EditorAppActions.bf:32,204`; `EditorApplication.bf:152-154, 959-997, 1449, 1803-1804`).
  - The Export dialog's template row, its resolution card and icons, and "Export Templates" from inside it (`ExportDialog.bf:13-34, 86, 147-150, 223-240, 394-420, 508-539, 741`; `EditorApplication.bf:1167-1170`).
  - Preferences' templates root (`PreferencesDialog.bf:254-259, 281-283`; `Data/Editor/Preferences.xml`; `Editor.Core/src/EditorExportSettings.bf`).
- **MCP:**
  - `project_export` (`ProjectExportTool.bf`). Its description says "stage the preset's player template" (36-38), and the response carries `player` and `warning` (98-100).
  - `export_presets`/`export_preset_set`, which give a `template` per preset and a `templates` list (`ExportPresetTools.bf:27, 69, 75-105, 193`).
- **CLI** (`Editor.ExportMain/src/ExportMain.bf`): `--template list|import|create` with `--plugins-root`, `--icon` and `--id` (17-37, 45-59, 198-298), and the registry for the export (139-140).
- **Runtime:** the player's `--plugins` (`Engine/Sedulous.Engine.Player.DesktopMain/src/DesktopPlayerMain.bf:48-53`) and `PluginRegistry.Linked` (`Foundation/Sedulous.Runtime/src/PluginRegistry.bf:34-35`).
- **Tests:**
  - `Editor.Core.Tests`: `ExportTemplateTests` (all of it); `ExportDriverTests`, whose fixture `ExportProjectFixture` builds a host template from a stand-in player (`Fixtures/ExportProjectFixture.bf:31, 70-79`), plus the template cases at 286, 341, 440 and 766.
  - `Editor.App.Tests`: `TemplatesDialogTests`, `ExportDialogTests:86`, `EditorExportTests:105-109`, `PreferencesDialogTests:641`.
  - `Integration.Mcp`: `ExportFlowTests:24-45` (`SEDULOUS_TEMPLATES_DIR`, a stand-in player dir) and `ExportPresetToolsTests`.
  - `Runtime.Tests`: `PluginRegistryTests:188-192`.
  - Tests that borrow `ExportTemplates.CopyFile`/`CopyTree` only as a file copy: `SampleProjectTests.bf:85-90` and `NativeSampleTests.bf:530-535, 613-614`.
- **Data:**
  - Every converted sample's presets name templates by id: `sedulous-steamdeck-release-0.1.0` for both "Linux64 Desktop" and "Steam Deck", `sedulous-web-release-0.1.0`, and `sedulous-win64-release-0.1.0`.
  - NativeSample's single Linux64 preset names none.
- **Docs:**
  - `McpGuide.md:503-535` (the export section) and `593-599` (gotchas).
  - `Web.md:6-26`.
  - `README.md:61-63, 184-185`.
  - `AGENTS.md:37-39, 155-158`.
  - `Backlog.md:157-160` ("The Linux desktop preset picks the Steam Deck template").

### The project build

- **Generation.** `ProjectBuild.Generate` (`ProjectBuild.bf:416-457`) writes, before every build:
  - `Code/BeefConfig.toml`: Beef's registry pointed at the SDK's library folders, by absolute path (283-290).
  - The merged, user-owned `Code/BeefSpace.toml` (611-715).
  - `Code/.gitignore`.
  - Under `Code/.generated`, four entries (`BuildEntry`, 48-59): `<Game>Editor`, `<Game>Player`, `<Game>PlayerWeb` and `<Game>Tools`. Each is a one-line Main plus the parts its role loads (`ExecutableProject`, 731-754).
  - The web player's own workspace, `Code/.generated/Web` (`WebWorkspaceText`, 587-603). It is separate because BeefBuild compiles every project of a workspace, and the editor's dependencies do not compile for wasm32.
- **The entries take over the stock projects' configs** (`StockConfigs`, 780-801), with the stock's relative macros made absolute into the SDK:
  - The editor's and the tools' post-build steps (naga and tint).
  - The web player's link and staged files (`cStockWebProject`, 116-117). Only its `TargetDirectory` stays the entry's own (`cWebOwnKey`, 123).
- **Samples.**
  - NativeSample has four parts. Masquerade, SkyHopper and the other ports have the Engine part alone.
  - Each tracks only `Code/BeefSpace.toml` (which lists `<Game>Player`), `Plugin.xml`, `.gitignore` and the game library. `.generated/`, `build/` and `BeefConfig.toml` are ignored (`git ls-files`).
  - `NativeSample/Code/.generated/NativeSamplePlayerWeb/dist` holds a built page, so the generated web workspace has built a game's Engine part for wasm32 once.
  - `SkyHopper/Code/build/Debug_Linux64/SkyHopperPlayer` holds objects and libraries but no executable. Its last player link did not finish, which is worth a look.
  - `GamePackage` scaffolds only the parts. The entries are always generated (D1).
- **Build service.** `ProjectBuildService.Run` (`ProjectBuildService.bf:431-453`) is blocking, for the build lane:
  - It finds the SDK (`FindSdk`: `SEDULOUS_SDK`, then the data root's parent, 230-251).
  - It refuses a project with no package (465-469).
  - It finds BeefBuild (D5: `BEEFBUILD`, then PATH with a corlib check, then a managed install that is a stub for now; `FindBeefBuild` 922-966).
  - It generates, then runs one BeefBuild per step: `-workspace=<Code> -config=<c> -platform=<host> -project=<entry>` (`RunStep` 506-561, the host platform fixed at 513).
  - It checks each executable is there (492-501).
- **Steps** are editor or player only (`BuildJob`, 83-105):
  - `Editor`: the editor in Debug.
  - `All` (Build Project): the editor in Debug, then the player in Debug and in each config a host preset names (`PlayerConfigs`, 859-873).
  - `Player`: one config. Nothing calls it.
  - No step builds `<Game>PlayerWeb`.
- **Output.** The output is streamed into the job and the log; diagnostics are parsed (`BuildDiagnostics`); cancel goes through the job or the lane's token.
- **Threads.** `EditorBuildTools.StartBuild` (`EditorBuildTools.bf:77-120`) submits jobs on `EditorContext.BuildLane`, the same lane the export job runs on (`EditorApplication.bf:622`; `EditorProjectOperations.bf:25-27`), so a build and an export never overlap in one editor. `project_build` waits up to 900 s by default, 3600 at most (`EditorBuildTools.bf:52-53`). The editor's MCP export step times out at 600 s (`EditorProjectOperations.bf:46`).

### The web player today

- **The stock template.** It is built by hand from the engine's `Code/` (`Web.md:8-19`): `BeefBuild -config=ShippingRelease -platform=wasm32 -project=Sedulous.Engine.Player.Web`. Its output lands in the engine tree (`Code/Engine/Sedulous.Engine.Player.Web/dist`, with `dist-profile` for Release), and `--template create` packages it.
- **Plugins.** `Sedulous.Engine.Player.WebMain` links no plugin (its BeefProj has no plugin lines, and `ExportTemplates.Create` clears `Plugins` for a web template, 134). So a web export of a project that enables any plugin, its own package included, is refused (`ExportPlugins.bf:88-92`).
- **Emscripten.** BeefBuild does not read `EMSDK`. It reads `[Wasm] EmscriptenPath` from `BeefSettings.toml` in its user data folder: beside BeefBuild for a source build (`~/Dev/Beef/Beef/IDE/dist/BeefSettings.toml:212-213` here, `/home/robert/emsdk`), or `~/.config/beeflang/` for a packaged one (`Beef/IDE/src/IDEApp.bf:13575-13581`, `Settings.bf:1262-1265`). It then needs `upstream/emscripten/emcc` under it, and Beef's wasm runtime archive built (`BuildContext.bf:878-1000`). Under the CLI, a missing path fails with "Emscripten path not configured". `Web.md:9`'s `source emsdk_env.sh` is not what BeefBuild uses.
- **Generated output.** `<Game>PlayerWeb` writes `Code/.generated/<Game>PlayerWeb/dist` for both Debug and ShippingRelease (`WebPagePath`, 318-324), so a Debug web build overwrites the shipping one.

### Steam Deck today

- `Code/Tools/SteamDeck/build-steamdeck.sh` rsyncs the engine's git-visible sources to `build/steamdeck/src` (63-67) and runs an Ubuntu 22.04 container (12 GB memory cap, 4 BeefBuild threads; 72-79).
- In the container, `in-container-build.sh` builds Beef from the fork once per commit, rebuilds every native dependency, and builds the **stock** player with `-proddir=. -project=Sedulous.Engine.Player.Desktop` (56-58).
- It stages the player stripped, its `.so` files except DXC, `libSDL3.so.0` and the notices, then checks every ELF's glibc floor against 2.35 and `ldd` (60-98).
- Back on the host, `Sedulous.Tools.Export --template create ... --icon handheld` and `--template import` install it as `sedulous-steamdeck-release-<ver>` (84-98).
- The game's code is never in it.

## The problems

1. **No game code ships.** A template links no project code, so a native game cannot export with one. The own-player path exists, but only for the host platform, only from a player Build Project already made, and still with the template's sidecars (`ExportDriver.bf:515-517`).
2. **No host template in a project's editor.** In a project's own editor the host template is empty (`PlayerDirectoryBeside`), so even that path has no sidecars.
3. **No per-project web player.** Nothing builds `<Game>PlayerWeb`, and its Debug and shipping outputs collide.
4. **Steam Deck builds the stock player**, never the game's.
5. **Pure-data projects.** A project without `Code/` exports today on the host template. With templates gone it needs a player from somewhere.
6. **Build Project builds every preset's shipping player** (`PlayerConfigs`). That is the most expensive build there is (a full optimised engine compile, about 16 GB of memory on this machine), paid on every Build Project for an export that may never happen.
7. **Too much to retire for one commit.** The template machinery reaches the editor UI, MCP, the CLI, the runtime's `--plugins`, preferences, sample data, docs and about 15 test files.

## Design

### The player build step

ExportOne gets its player from an `IPlayerBuilder` instead of a `TemplateRegistry`:

```beef
/// The player an export ships, built for one (platform, config): its folder, its binary, and the
/// files that go beside it.
class PlayerBuild
{
	public String Directory;      // where BeefBuild (or the container) put it
	public String Binary;         // <Game>Player, or <Game>PlayerWeb.html
	public List<String> Files;    // shared libraries less DXC, the notices; or the web parts
	public List<String> Symbols;  // the .pdb on Windows; none on Linux (Q10)
	public String Description;    // "SkyHopperPlayer, ShippingRelease, Linux64 (built 41 s)"
}

interface IPlayerBuilder
{
	/// Refused with why in outRefusal (no SDK, no BeefBuild, no Emscripten, another host's
	/// platform, a compile error); diagnostics stay on the job.
	Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild,
		ExportProgress onProgress, String outRefusal);
}
```

- **`ProjectPlayerBuilder`** takes the `ProjectBuildService`, the data root and the cancel token. It:
  - finds the SDK;
  - runs `Generate`;
  - runs one BuildJob step for `<Game>Player` (host) or `<Game>PlayerWeb` (wasm32, in the web workspace);
  - collects the output with the existing `CollectSharedLibraries` (minus `IsDxcRuntimeLib`, plus `THIRD-PARTY-NOTICES.txt`, both already beside every build) or `CollectWebParts`.
- **Tracking and threads.** The job is tracked as the service's latest, so `build_status` and `build_cancel` follow an export's compile. In the editor it already runs on the build lane (the export job's lane); in the CLI and the stdio MCP host it runs inline.
- **`StagedPlayerBuilder`** serves tests: it writes a stand-in player and libraries into a folder and replaces `ExportProjectFixture`'s host template.
- **Order inside ExportOne:**
  1. Refusals: plugins, then the platform against the host (D6).
  2. The player build. A compile error refuses before minutes of cooking.
  3. Cook and pack.
  4. Stage the player as `PlayerOutputName(platform, preset.PlayerName or the game's name, build.Binary)`, the shader pack, `build.Files`, the symbols when opted in, extras, deploy files and hooks.
- **Progress.** The build gets its own band (about 0.02-0.40) and the cook moves down. In the editor the pre-cook (`EditorExport.Run`, 95-114) still runs first, and stays cheap when incremental.
- **ExportAll** builds each distinct (platform, config, builder) once.

### Config mapping

Presets keep their vocabulary: Release (the shipping build), Profile and Debug. Empty reads as Release. `BuildConfigFor` keeps its mapping to ShippingRelease, Release and Debug. `BuildLayout.TemplateConfigFor`, its inverse for naming templates, goes. Test is refused as a preset config (Q12).

### Where outputs land

- **Desktop:** `Code/build/<Config>_<Host>/<Game>Player/` as now (`ExecutablePath`).
- **Web:** the generated `<Game>PlayerWeb` sets its own `TargetDirectory` per config to `$(WorkspaceDir)/build/<Config>_wasm32/<Game>PlayerWeb`. The workspace is `Code/.generated/Web`, so this is `Code/.generated/Web/build/<Config>_wasm32/<Game>PlayerWeb/`, in the desktop layout. That ends the Debug/shipping collision, lets `ParseBuildDirectory` read it, and stays git-ignored. The stock project's `TargetDirectory` line is replaced rather than kept (`cWebOwnKey`). `WebPagePath` follows.
- **Dist:** `Dist/<subdir>` receives only the export (Q8).

### Plugins

`ChoosePlayer` becomes `ExportPlugins.Check(project, sdk, platform, outEnabled, outRefusal)`:
- Each entry's manifest is the project package's (with a path), else the one in the SDK's `Code/Plugins` (`FindPackage`, moved out of ExportTemplates).
- If neither has it, the export is refused.
- Unsupported on the platform: refused, as now.
- Version against a template: gone. What is enabled is linked, by construction:
  - The project's packages are linked by `ExecutableProject` (`Loads(.Player/.PlayerWeb)` gives Engine parts).
  - Engine plugins: Generate adds `"<Plugin>.Engine" = "*"` to `<Game>Player` and `<Game>PlayerWeb` for every engine plugin the project enables on that platform. The registry already finds `Code/Plugins` (`cSdkLibraryDirs`, 132).

`DesktopMain`'s own `Imgui.Engine` line (`DesktopMain/BeefProj.toml`) stays for the stock player, so the duplicate on desktop is harmless.

`StageDeployFiles` takes its folder from the project package or the SDK's package.

### Projects without Code/

See Q2. Recommended: `Generate` with no packages writes `Code/` (the workspace, `.gitignore` and `.generated`, no game library), and `BuildTarget.Player` no longer requires a package. `Editor` and `All` still refuse, as now. The phase 1 item "a new project is born with Code/" (`x2.md:103`), deferred until phase 5, then follows directly.

### The CLI and the stdio MCP host

- `ExportMain` and `InlineProjectOperations.RunExport` construct a `ProjectBuildService` and a `ProjectPlayerBuilder` and run inline. BeefBuild's lines go to the console as `Build Project:` log lines, as they do in the editor.
- `--data-root` still finds the shaders. The SDK is `SEDULOUS_SDK` or the tool's checkout.
- The stock `Sedulous.Tools.Export` builds the player correctly, but it cannot cook with a project's own Pipeline or Tooling parts (NativeSample's note builder): `ToolPlugins` reports them refused (`ExportMain.bf:119-121`). For those, `<Game>Tools export` is the exporter, and the refusal should say so.

### Steam Deck

See Q6. Recommended: a preset field `Builder` (Host | SteamDeck, `[Appended]`), with `SteamDeckPlayerBuilder` as the build step:
- It copies the project's tracked `Code/` into `build/steamdeck/projects/<Game>/Code`.
- It runs `Generate` there against the container's view of the SDK. Generate gains a written SDK root distinct from the one read: `ConfigText` and `StockConfigs` write the written root, and `ReadStockConfigs` reads the host's. The simplest form mounts the SDK copy and the project copy at the same absolute paths inside the container, so the written root equals the copy's path.
- It runs `build-steamdeck.sh --workspace <dir> --project <Game>Player --config ShippingRelease --out <bundle>` through the job's process runner, so the output streams and cancels like BeefBuild.
- `in-container-build.sh` builds with `-workspace=` instead of `-proddir=. -project=Sedulous.Engine.Player.Desktop` (56-58). It then names the bundle after `<Game>Player` and keeps the strip, the SDL soname copy and the glibc and `ldd` checks (60-98).
- The template create and import at the end of `build-steamdeck.sh` (84-98) and `EXPORT_TOOL` (39) go.
- The bundle folder is the `PlayerBuild`.

## Decisions

- **Q1. Build on every export, or reuse a fresh build.** *Rec:* always run BeefBuild; it is incremental and decides correctly. `FreshPlayer` sees only the project's packages (`NewestSource`, 1135-1145), not engine sources, which change on every pull of a checkout, so a "fresh" player can be stale against the SDK. Also add `--no-build` on the CLI and `build: false` on `project_export`, for repackaging content over the last build of that config; refused when there is none. `FreshPlayer` and `FindUnbuilt` then go.
- **Q2. Player of a project without Code/.** *Rec:* the same generated `<Game>Player`, with no game parts, in `Code/`. Every export then has one path, and pure-data projects get `Code/` the way new projects will right after. The alternative is the SDK's stock `Sedulous.Engine.Player.Desktop`, built once in the SDK's own workspace: shared and faster after the first build, but it writes into the SDK (an installed SDK may be read-only) and keeps a second path alive.
- **Q3. What Build Project builds.** *Rec:* the editor alone (Debug). The export builds the players it needs. `BuildTarget.All` and `PlayerConfigs` go. `project_build` keeps `editor` and adds `player` (with `platform` and `config`), so an agent can check a shipping or web build compiles without exporting. The alternative keeps All with the Debug player only; nothing launches that player today (no caller of `BuildEntry.Player` outside the build).
- **Q4. Another host's preset (D6).** *Rec:* ExportOne refuses a Win64 preset on Linux (and a Linux64 one on Windows) with "a Win64 player builds on Windows: export this preset there". Web builds on either host. ExportAll skips such presets with a notice and counts them, and does not fail. Five samples carry a "Windows Desktop" preset, so Export All on Linux would otherwise always fail.
- **Q5. `ExportPreset.TemplateId`.** *Rec:* keep the field as an ignored legacy slot (no `[Setting]`, written empty), so `[Serializable(1)]` presets read unchanged. Binary is positional (`SerializableAttribute.bf:14-20`), and the samples' presets are re-saved without a value in commit 12. Drop the slot at the next preset version bump. The alternative is a version bump now with `minReadVersion`, which a removed middle field does not allow, so it would need a hand-written body.
- **Q6. Steam Deck.** *Rec:* the `Builder` preset field with the container as an export build step (above). `project_export` with the "Steam Deck" preset then just works, and the first run's long Beef and dependency build is visible in `build_status`. The alternative keeps the script manual, producing a project bundle, plus a `--player-dir <folder>` override on the export: simpler, but it is a per-project template by another name.
- **Q7. The samples' "Linux64 Desktop" presets.** They name the Steam Deck template today, which is why they are portable to older glibc (`Backlog.md:157-160`). *Rec:* Host. The host-built dist needs the build machine's glibc and the system's SDL3, which is what the host template shipped as well. The Steam Deck preset is the portable Linux build. The alternative makes both presets SteamDeck, so every sample's desktop export needs podman.
- **Q8. The web output folder.** `x2.md:188` says the project's `Dist/`. *Rec:* the build output stays in `Code/.generated/Web/build/<Config>_wasm32/<Game>PlayerWeb` (git-ignored, beside the other builds), and only the export writes `Dist/`. Writing builds into `Dist/` would mix a build tree with what ships.
- **Q9. Engine plugins on the web.** Link the engine plugins enabled on Web, as above. `Plugins/Imgui/Plugin.xml` lists Web, and its renderer has web code, but `Dependencies/cimgui-Beef` never had a wasm32 build (no Emscripten branch in `build-native.sh`, no wasm32 config, no `dist/Release-wasm32`): nothing linked it for wasm, the stock web player linking no plugin. **Ruled: build cimgui for wasm** as the other dependencies are, so Imgui keeps Web.
- **Q10. Symbols and stripping.** *Rec:* parity in phase 5. The Windows `.pdb` beside `<Game>Player.exe` is a symbol, staged when `StageSymbols` is set; on Linux nothing is stripped, as the host template did not strip. Note that `cWorkspaceConfigs` (139-170) sets no `EmitDebugInfo = "No"` for ShippingRelease Linux64 or Win64, so the dist carries debug info. A later change can strip on Linux unless `StageSymbols`, as `in-container-build.sh` already does.
- **Q11. Default player name.** *Rec:* the game's name (`GameName`: "SkyHopper"), not `Sedulous.Engine.Player.Desktop` or `<Game>Player`. `preset.PlayerName` still wins. On the web the page is renamed as now; its `.js` and `.wasm` keep their names, which the page refers to.
- **Q12. Preset configs.** *Rec:* Release, Profile and Debug. Test is refused: it links the test runner and is no player.
- **Q13. The player's `--plugins` and `PluginRegistry.Linked`.** *Rec:* remove both. Their only purpose was recording what a template carries.
- **Q14. `CopyFile` and `CopyTree`.** *Rec:* move them to a `FileCopy` class in Editor.Project, keeping the executable bit (`ExportTemplates.bf:408-425`). The tests use them as a plain file copy.

## Retired

- `ExportTemplate`, `TemplatePlugin`, `ExportTemplates` (all but the copy helpers and `FindPackage`, which move), `TemplateRegistry`, `TemplateOutput`, and `SynthesizeHost` with its `--plugins` probing. Also `TemplateIcons` (it becomes `PlatformIcons`, keeping the built-in platform SVGs the Export dialog shows presets by).
- In BuildLayout: `cTemplateIdPrefix`, `TemplateConfigFor` and `PlayerDirectoryBeside`.
- `ExportResult.EngineVersionWarning`.
- `ExportPlugins.ChoosePlayer`'s template path, `PackageDir` and `FindManifest` over a template.
- `ProjectBuild.FreshPlayer`, `FindUnbuilt` and `PlayerConfigs` (Q1, Q3).
- `TemplatesDialog`, `Data/Editor/Templates.xml`, Edit > Export Templates, the Export dialog's template row and "Export Templates" button, and Preferences' templates root with `EditorExportSettings.TemplatesRoot`.
- In the MCP host:
  - `export_presets`' `template` and `templates`, replaced by `buildable` and `why` per preset;
  - `project_export`'s `warning`;
  - the template wording.
- `Tools.Export --template list|import|create` and its options.
- `DesktopPlayerMain`'s `--plugins` and `PluginRegistry.Linked`.
- `build-steamdeck.sh`'s template step.
- The `SEDULOUS_TEMPLATES_DIR` environment variable.

## Testing

- **`Editor.Core.Tests`:**
  - `ProjectBuildTests`: web `TargetDirectory` per config; `FindEmscripten` over fixture `BeefSettings.toml` files; a zero-package workspace; an enabled engine plugin's Engine part in the player entries and a disabled one absent; Generate with a written SDK root.
  - `ProjectBuildServiceTests`: a web step's arguments (`-workspace=.generated/Web`, `-platform=wasm32`); a Player job without a package; the Emscripten refusal.
  - New `PlayerBuildTests`, with a fake `BuildRunner` writing stand-in output: the collected files, DXC left out, notices kept, the web parts, a compile failure's refusal carrying diagnostics, cancel.
  - `ExportDriverTests` rewritten over `StagedPlayerBuilder`: the own player and its files staged; another host's platform refused; plugin refusals without templates; ExportAll building one (platform, config) once and skipping other hosts.
  - `ExportTemplateTests` deleted.
- **`Editor.App.Tests`:** `TemplatesDialogTests` deleted; `ExportDialogTests`, `PreferencesDialogTests`, `EditorExportTests` and `EditorBuildToolsTests` (the `player` target) updated.
- **`Integration.Mcp`:** `ExportFlowTests` through an inline host with a staged builder; `ExportPresetToolsTests` (`buildable`).
- **`Integration.Plugins`:** `NativeSampleTests` without `PlayerConfigs`, and the sample's preset building its own player.
- **`Runtime.Tests`:** `PluginRegistryTests` without `Linked`.
- **No test runs a real BeefBuild.** A real build costs minutes and about 16 GB. The real path is checked by hand per sample in commit 12. A test gated on an environment variable (`SEDULOUS_REAL_BUILD`) can come later.
- **ASan:** `asan-test.py` on each changed test project.

## Commits

0. **cimgui-Beef:** a wasm32 build (`build-native.sh`'s Emscripten branch, `dist/Release-wasm32/libcimgui.a`, the wasm32 configs) (Q9). Checked: a wasm32 build of Imgui.Engine links.
1. **Editor.Project:** the file copy helpers move out of ExportTemplates (`FileCopy.CopyFile`/`CopyTree`), and `FindPackage` moves to a plugin-packages helper. Callers follow. Tests: Editor.Core.Tests, Integration.Mcp, Integration.Plugins.
2. **Editor.Project:** build steps by entry and platform. `BuildJob` steps become (entry, config, platform), `<Game>PlayerWeb` builds in its own workspace for wasm32, the web output goes per config under `.generated/Web/build/<Config>_wasm32/<Game>PlayerWeb`, and `FindEmscripten` (`BeefSettings.toml` beside BeefBuild or under `~/.config/beeflang`, then `upstream/emscripten/emcc`) refuses clearly before BeefBuild runs. Tests: ProjectBuildTests, ProjectBuildServiceTests.
3. **Editor.Project:** a player for a project without a package. Generate with no packages, and a Player job allowed without one (Q2). Tests: ProjectBuildTests, ProjectBuildServiceTests.
4. **Editor.Project:** the player entries link the engine plugins the project enables on their platform (Q9). Tests: ProjectBuildTests; Integration.Plugins.
5. **Editor.Project:** `PlayerBuild`, `IPlayerBuilder`, `ProjectPlayerBuilder` and `StagedPlayerBuilder`, not yet used by the export. Tests: PlayerBuildTests.
6. **Export:** the driver builds the player. ExportOne and ExportAll take an `IPlayerBuilder`; `ExportPlugins.Check` replaces ChoosePlayer; deploy files come from the project or the SDK; another host's platform is refused or skipped (Q4); each (platform, config) is built once; the player is named by the game (Q11). Every caller switches in the same commit: EditorExport, EditorProjectOperations, InlineProjectOperations, ExportMain, McpMain, EditorMcpService. Tests: ExportDriverTests (rewritten), ExportFlowTests, NativeSampleTests.
7. **Editor MCP and Editor:**
   - `project_export` reports the build (`build`: state, duration, error count, the first diagnostics, as `project_build` gives them), takes `timeoutSeconds` (default raised above the step's 600 s) and `build: false` (Q1);
   - `export_presets` gives `buildable` and `why`;
   - the Export dialog's card names the build ("SkyHopperPlayer, ShippingRelease, Linux64") or why it cannot be built here.

   Tests: ExportPresetToolsTests, ExportFlowTests, ExportDialogTests.
8. **Editor:** the templates UI goes: TemplatesDialog, `Templates.xml`, Edit > Export Templates, the dialog's template row, Preferences' templates root and `EditorExportSettings.TemplatesRoot`. TemplateIcons becomes PlatformIcons. Tests: Editor.App.Tests (TemplatesDialogTests deleted; ExportDialogTests, PreferencesDialogTests, EditorExportTests).
9. **Editor.Project and ExportMain:** the template machinery goes: ExportTemplate, ExportTemplates, TemplateRegistry, TemplateOutput, the host synthesis, BuildLayout's template parts, `EngineVersionWarning`, `Tools.Export --template`, and `TemplateId` reduced to a legacy slot (Q5). Tests: Editor.Core.Tests (ExportTemplateTests deleted), Integration.Mcp.
10. **Runtime and Player:** `--plugins` and `PluginRegistry.Linked` go (Q13). Tests: Runtime.Tests.
11. **Editor.Project and Editor:** Build Project builds the editor alone, and `project_build` gains `player` (Q3); `FreshPlayer`, `FindUnbuilt` and `PlayerConfigs` go. Tests: ProjectBuildServiceTests, EditorBuildToolsTests, NativeSampleTests.
12. **Steam Deck:** the `Builder` preset field (`[Appended]`), Generate with a written SDK root, `SteamDeckPlayerBuilder`, and `build-steamdeck.sh` and `in-container-build.sh` building `<Game>Player` from the project's workspace. Tests: ProjectBuildTests, PlayerBuildTests (the script's arguments with a fake runner). Checked by hand: SkyHopper on a Deck.
13. **Samples:** presets re-saved (no template ids; Steam Deck presets on the SteamDeck builder; Linux64 Desktop on Host, Q7). Each sample is exported to Linux64 and Web and run (title, play, a screenshot each), which closes phase 4's "and as an export" items. Tests: Integration.Mcp SampleProjectTests, Integration.Plugins.
14. **Docs:**
    - `Web.md`: building through the project; Emscripten's path in `BeefSettings.toml`, and the wasm runtime archive.
    - McpGuide's export section (503-535) and gotchas (593-599).
    - `README.md:61-63, 184-185`; `AGENTS.md:37-39, 155-158`.
    - `Backlog.md:157-160` removed.
    - CHANGELOG under Unreleased. Changed: an export builds the game's player. Removed: export templates, Edit > Export Templates, `Tools.Export --template`, the player's `--plugins`.
    - `x2.md`: phase 5's boxes, the undotted names, and phase 1's deferred "born with Code/" unblocked.

## Risks

- **Memory.** A full optimised BeefBuild of the engine takes about 16 GB on this machine. A project's first shipping export pays that while the editor is open, and `AGENTS.md:40-41` already records two builds at once running the machine out of memory.
  - BeefBuild takes its worker threads only from `BeefSettings.toml` (`WorkerThreads`); there is no command-line flag in `BuildApp.bf:173-336`. The Steam Deck script writes that file in the container for this reason (`in-container-build.sh:21-25`).
  - The editor never builds and exports at once, since both use the build lane. Nothing stops a CLI export and an editor build on the same workspace from running together, and they would also share `Code/build`. A lock file under `Code/build` is a small guard.
  - *Rec:* say so before a cold shipping build (a notice, and in the docs), and dedupe builds in ExportAll.
- **Time.** The first shipping and web builds of a project compile the engine optimised: minutes. Later ones are incremental. MCP export calls need a timeout above the step's 600 s (commit 7). Measure both on SkyHopper in commit 13, and put the numbers in the docs rather than guessing them here.
- **Disk.** Each config adds a full build tree under `Code/build` (and `.generated/Web/build`), hundreds of megabytes per config per project.
- **Win64 (D6).** Windows presets build only on Windows, and none is checked from this machine. The DLL sidecars and the `.pdb` symbol path need one Windows export before phase 5 is called done.
- **Pure-data projects** now need an SDK, BeefBuild (and Emscripten for the web) to export at all. That is the x2 target model, but it is a change for anyone exporting without one.
- **CLI without an editor.** `<Game>Tools export` is the right exporter for a project with its own Pipeline or Tooling parts. The stock tool builds the player but cannot cook those parts.
- **Linux portability.** A host-built Linux dist needs the host's glibc (2.43 here) and a system SDL3. Only the Steam Deck builder gives a portable Linux build.

## To discuss

- Q1 to Q14 above, especially Q2 (pure data), Q3 (Build Project's scope), Q4 (Export All on Linux), Q6 and Q7 (Steam Deck and the desktop presets), and Q8 (`x2.md`'s "the project's Dist/").
- Whether Imgui should drop Web from its manifest, or cimgui gain a wasm build (Q9).
- Whether a lock across processes on a project's workspace is wanted now.
- Whether `ManagedBeefBuild` (still a stub) and an Emscripten setting written by the editor belong in phase 5, or wait for phase 7's toolchain work. *Rec:* wait; phase 5 only finds them and says clearly what is missing.
- SkyHopper's Debug player build folder has no executable. It should be understood before commit 13 relies on the samples' builds.
