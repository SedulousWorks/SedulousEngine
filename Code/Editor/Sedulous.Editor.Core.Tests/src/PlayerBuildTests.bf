using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

using Sedulous.Editor.Projects.TestSupport;

namespace Sedulous.Editor.Core.Tests;

/// The player an export ships, built for a preset: by the project's build through a fake
/// BeefBuild that writes what a real one leaves (ProjectPlayerBuilder), or staged with no
/// compiler (StagedPlayerBuilder); what is collected beside it, and what is refused.
class PlayerBuildTests
{
	/// The BeefBuild output the build's own tests parse, read from beside them.
	private const String cFailedBuild = Compiler.ReadText("../Sedulous.Editor.Projects.Tests/src/Fixtures/beefbuild-errors.txt");
	/// What the fake runs; never started.
	private const String cFakeBeefBuild = "/fake/BeefBuild";
	/// The shared library a build leaves beside the player, which ships.
	private const String cLibrary = "libSDL3.so";
	/// The shader compiler's, which a build leaves beside it too and which never ships.
	private const String cDxcLibrary = "libdxcompiler.so";

	/// The project build's bed (ProjectBuildBed), its project saved and opened as an
	/// EditorProject.
	private class Bed
	{
		public ProjectBuildBed Build = new .() ~ delete _;
		public EditorProject Project ~ delete _;

		public this()
		{
			let root = scope NativeFileSystem(Build.ProjectDir);
			Test.Assert(ProjectManifest.Save(root, Build.Settings) case .Ok);
			Project = EditorProject.Open(Build.ProjectDir);
			Test.Assert(Project != null);
		}

		/// The engine data root, in the bed's SDK.
		public void DataRoot(String outPath) => PathJoin(Build.Sdk, "Data", outPath);
	}

	/// A preset for `platform` in `config`.
	private static void SetPreset(ExportPreset preset, StringView platform, StringView config)
	{
		preset.Platform.Set(platform);
		preset.Config.Set(config);
	}

	/// The value of `-name=` among `arguments`.
	private static StringView Argument(Span<StringView> arguments, StringView name)
	{
		let prefix = scope $"-{name}=";
		for (let argument in arguments)
		{
			if (argument.StartsWith(prefix))
				return argument.Substring(prefix.Length);
		}
		return default;
	}

	/// Writes what a BeefBuild run of `arguments` leaves, as a build that worked: for the desktop
	/// player its executable, a shared library, the shader compiler's and the notices; for the
	/// web player its page, its .js and .wasm, serve.py, the notices and an object file.
	private static void Make(ProjectBuildBed bed, Span<StringView> arguments)
	{
		let project = Argument(arguments, "project");
		let web = project.EndsWith(ProjectBuild.cPlayerWebSuffix);
		let made = ProjectBuild.EntryPath(bed.ProjectDir, "NativeGame", web ? BuildEntry.PlayerWeb : BuildEntry.Player, Argument(arguments, "config"), .. scope .());
		let dir = PathParent(made, .. scope .());
		ProjectBuildBed.Write(dir, PathFilename(made, .. scope .()), "#!built\n");
		ProjectBuildBed.Write(dir, BuildLayout.cThirdPartyNotices, "notices\n");
		if (web)
		{
			for (let part in StringView[4](".js", ".wasm", ".o", ".log"))
				ProjectBuildBed.Write(dir, scope $"{project}{part}", "part\n");
			ProjectBuildBed.Write(dir, "serve.py", "# serve\n");
		}
		else
		{
			ProjectBuildBed.Write(dir, cLibrary, "so\n");
			ProjectBuildBed.Write(dir, cDxcLibrary, "so\n");
		}
	}

	private static bool Has(List<String> names, StringView name)
	{
		for (let item in names)
		{
			if (item == name)
				return true;
		}
		return false;
	}

	/// Another host's desktop platform: Win64 on Linux, Linux64 on Windows.
	private static StringView OtherHost => (BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64";

	/// A host preset builds <Game>Player in the build config its config names (Release ships
	/// ShippingRelease) as the service's latest job, and gives the executable with the shared
	/// libraries beside it, the shader compiler's left out and the notices kept, named for people.
	[Test]
	public static void AHostPlayerShipsItsLibrariesLessTheShaderCompiler()
	{
		let bed = scope Bed();
		let runs = scope List<String>();
		defer { ClearAndDeleteItems!(runs); }
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs.Add(new $"{Argument(arguments, "project")} {Argument(arguments, "config")} {Argument(arguments, "platform")}");
				Make(bed.Build, arguments);
				return .Ok(0);
			}, cFakeBeefBuild);
		let builder = scope ProjectPlayerBuilder(service, bed.DataRoot(.. scope .()));
		let preset = scope ExportPreset();
		SetPreset(preset, BuildLayout.HostPlatformName, "Release");
		let build = scope PlayerBuild();
		let refusal = scope String();
		let steps = scope List<float>();
		Test.Assert(builder.Build(bed.Project, preset, build, scope [&](step, fraction) => { steps.Add(fraction); }, refusal) case .Ok, refusal);

		Test.Assert((runs.Count == 1) && (runs[0] == scope $"NativeGamePlayer ShippingRelease {BuildLayout.HostPlatformName}"), (runs.Count > 0) ? runs[0] : "no run");
		let executable = ProjectBuild.ExecutablePath(bed.Build.ProjectDir, "NativeGame", false, "ShippingRelease", .. scope .());
		Test.Assert(build.Directory == PathParent(executable, .. scope .()), build.Directory);
		Test.Assert(build.Binary == BuildLayout.ExecutableName("NativeGamePlayer", .. scope .()), build.Binary);
		Test.Assert((build.Files.Count == 2) && Has(build.Files, cLibrary) && Has(build.Files, BuildLayout.cThirdPartyNotices), "the library and the notices");
		Test.Assert(!Has(build.Files, cDxcLibrary), "the shader compiler left out");
#if !BF_PLATFORM_WINDOWS
		Test.Assert(build.Symbols.IsEmpty, "no symbols off Windows");
#endif
		Test.Assert(build.Description == scope $"NativeGamePlayer, ShippingRelease, {BuildLayout.HostPlatformName}", build.Description);
		Test.Assert((steps.Count == 2) && (steps[0] == PlayerBuild.cProgressStart) && (steps[1] == PlayerBuild.cProgressEnd), "its progress band");

		let latest = service.GetLatest();
		Test.Assert((latest != null) && (latest.Target == .Player) && (latest.StepConfig(0) == "ShippingRelease") && (latest.State == .Succeeded),
			"the build is the service's latest");
		Test.Assert(build.Job === latest, "the build carries the job that compiled it");
		latest?.ReleaseRef();

		// A build again starts over: what the last one gave is not kept.
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Ok, refusal);
		Test.Assert(build.Files.Count == 2);
	}

	/// The preset's configs map to build configs: Release ships ShippingRelease, Profile is a
	/// Release build, Debug is Debug, and empty reads as Release.
	[Test]
	public static void APresetsConfigNamesItsBuildConfig()
	{
		let preset = scope ExportPreset();
		let presetConfigs = StringView[4]("Release", "Profile", "Debug", "");
		let buildConfigs = StringView[4]("ShippingRelease", "Release", "Debug", "ShippingRelease");
		let config = scope String();
		let refusal = scope String();
		BuildEntry entry;
		for (int i < presetConfigs.Count)
		{
			SetPreset(preset, BuildLayout.HostPlatformName, presetConfigs[i]);
			Test.Assert(ProjectPlayerBuilder.Target(preset, out entry, config, refusal) case .Ok, refusal);
			Test.Assert((entry == .Player) && (config == buildConfigs[i]), config);
		}
		SetPreset(preset, BuildLayout.cWebPlatform, "Release");
		Test.Assert(ProjectPlayerBuilder.Target(preset, out entry, config, refusal) case .Ok, refusal);
		Test.Assert((entry == .PlayerWeb) && (config == "ShippingRelease"), config);
	}

	/// A Web preset builds <Game>PlayerWeb for wasm32, and gives its page with the parts beside it
	/// (the .js and .wasm, serve.py, the notices), nothing else the build left there.
	[Test]
	public static void AWebPresetShipsThePagesParts()
	{
		let bed = scope Bed();
		let beefBuild = ProjectBuildBed.FakeInstall(bed.Build, "beef/IDE/dist/BeefBuild", "\"../../BeefLibs\"", "beef/BeefLibs/corlib", .. scope .());
		let emsdk = ProjectBuildBed.FakeEmscripten(bed.Build, "emsdk", .. scope .());
		ProjectBuildBed.Write(bed.Build.Root, "beef/IDE/dist/BeefSettings.toml", scope $"FileVersion = 1\n\n[Wasm]\nEmscriptenPath = '{emsdk}'\n");
		let home = PathJoin(bed.Build.Root, "home", .. scope .());
		let runs = scope List<String>();
		defer { ClearAndDeleteItems!(runs); }
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs.Add(new $"{Argument(arguments, "project")} {Argument(arguments, "config")} {Argument(arguments, "platform")}");
				Make(bed.Build, arguments);
				return .Ok(0);
			}, beefBuild, home);
		let builder = scope ProjectPlayerBuilder(service, bed.DataRoot(.. scope .()));
		let preset = scope ExportPreset();
		SetPreset(preset, BuildLayout.cWebPlatform, "Debug");
		let build = scope PlayerBuild();
		let refusal = scope String();
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Ok, refusal);

		Test.Assert((runs.Count == 1) && (runs[0] == "NativeGamePlayerWeb Debug wasm32"), (runs.Count > 0) ? runs[0] : "no run");
		let page = ProjectBuild.WebPagePath(bed.Build.ProjectDir, "NativeGame", "Debug", .. scope .());
		Test.Assert(build.Directory == PathParent(page, .. scope .()), build.Directory);
		Test.Assert(build.Binary == "NativeGamePlayerWeb.html", build.Binary);
		Test.Assert((build.Files.Count == 4) && Has(build.Files, "NativeGamePlayerWeb.js") && Has(build.Files, "NativeGamePlayerWeb.wasm")
			&& Has(build.Files, "serve.py") && Has(build.Files, BuildLayout.cThirdPartyNotices), "the page's parts alone");
		Test.Assert(build.Symbols.IsEmpty);
		Test.Assert(build.Description == "NativeGamePlayerWeb, Debug, wasm32", build.Description);
	}

	/// A compile that fails refuses the export with the job's error, and its first errors each
	/// with where it is; the rest stay on the job.
	[Test]
	public static void ACompileFailureRefusesWithItsErrors()
	{
		let bed = scope Bed();
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
			{
				for (let line in cFailedBuild.Split('\n'))
					onLine(line);
				return .Ok(1);
			}, cFakeBeefBuild);
		let builder = scope ProjectPlayerBuilder(service, bed.DataRoot(.. scope .()));
		let preset = scope ExportPreset();
		SetPreset(preset, BuildLayout.HostPlatformName, "Release");
		let build = scope PlayerBuild();
		let refusal = scope String();
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Err(.Internal));

		let lines = scope List<StringView>();
		for (let line in refusal.Split('\n'))
			lines.Add(line);
		Test.Assert(lines.Count == 2 + ProjectPlayerBuilder.cRefusalErrors, refusal);
		Test.Assert(lines[0] == "BeefBuild failed building NativeGamePlayer (ShippingRelease), exit 1, 4 errors", refusal);
		Test.Assert(lines[1].EndsWith("Other.bf:7:17: Expression expected"), refusal);
		Test.Assert(lines[2].EndsWith("Program.bf:8:11: Identifier not found"), refusal);
		Test.Assert(lines[lines.Count - 1] == "...", refusal);
		Test.Assert(build.Binary.IsEmpty && build.Files.IsEmpty, "nothing built");

		let latest = service.GetLatest();
		Test.Assert((latest != null) && (latest.ErrorCount == 4) && (latest.State == .Failed), "the diagnostics stay on the job");
		latest?.ReleaseRef();
	}

	/// A cancel while BeefBuild runs ends the build Cancelled, and the export with it.
	[Test]
	public static void ACancelledBuildIsRefused()
	{
		let bed = scope Bed();
		let source = scope CancelSource();
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				source.Cancel();
				if (cancelled())
					return .Err(.Cancelled);
				return .Ok(0);
			}, cFakeBeefBuild);
		let builder = scope ProjectPlayerBuilder(service, bed.DataRoot(.. scope .()), source.Token);
		let preset = scope ExportPreset();
		SetPreset(preset, BuildLayout.HostPlatformName, "Debug");
		let refusal = scope String();
		Test.Assert(builder.Build(bed.Project, preset, scope PlayerBuild(), null, refusal) case .Err(.Cancelled));
		Test.Assert(refusal.Contains("cancelled"), refusal);
	}

	/// Another host's desktop platform, a Test config and a config no preset has are refused before
	/// anything runs, is tracked or is written.
	[Test]
	public static void AnotherHostsPlatformAndTestAreRefused()
	{
		let bed = scope Bed();
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
			{
				Test.FatalError("nothing runs");
				return .Ok(0);
			}, cFakeBeefBuild);
		let builder = scope ProjectPlayerBuilder(service, bed.DataRoot(.. scope .()));
		let preset = scope ExportPreset();
		let build = scope PlayerBuild();
		let refusal = scope String();

		SetPreset(preset, OtherHost, "Release");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Err(.NotSupported));
		StringView system = (OtherHost == "Win64") ? "Windows" : "Linux";
		Test.Assert(refusal == scope $"a {OtherHost} player builds on {system}: export this preset there", refusal);

		SetPreset(preset, BuildLayout.HostPlatformName, "Test");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal..Clear()) case .Err(.InvalidArgument));
		Test.Assert(refusal.StartsWith("a Test build links the test runner and is no player"), refusal);

		SetPreset(preset, BuildLayout.cWebPlatform, "ShippingRelease");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal..Clear()) case .Err(.InvalidArgument));
		Test.Assert(refusal.StartsWith("'ShippingRelease' is no preset config"), refusal);

		Test.Assert(service.GetLatest() == null, "no job tracked");
		Test.Assert(!FileExists(PathJoin(bed.Build.ProjectDir, "Code/BeefSpace.toml", .. scope .())), "nothing generated");
	}

	/// A builder made to reuse the last build runs no BeefBuild: refused while the preset's entry
	/// has no build in its config, it then gives what that build left, collected as a build's is,
	/// with no job and a description saying it is the last build.
	[Test]
	public static void ReusingTheLastBuildRunsNothingAndRefusesWithoutOne()
	{
		let bed = scope Bed();
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
			{
				Test.FatalError("nothing runs");
				return .Ok(0);
			}, cFakeBeefBuild);
		let builder = scope ProjectPlayerBuilder(service, bed.DataRoot(.. scope .()), null, true);
		Test.Assert(builder.ReusesLastBuild);
		let preset = scope ExportPreset();
		SetPreset(preset, BuildLayout.HostPlatformName, "Release");
		let build = scope PlayerBuild();
		let refusal = scope String();

		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Err(.NotFound));
		Test.Assert(refusal.StartsWith("NativeGamePlayer has not been built in ShippingRelease"), refusal);

		// What a build of the player in ShippingRelease leaves.
		let made = scope StringView[]("-project=NativeGamePlayer", "-config=ShippingRelease");
		Make(bed.Build, made);
		let steps = scope List<float>();
		Test.Assert(builder.Build(bed.Project, preset, build, scope [&](step, fraction) => { steps.Add(fraction); }, refusal..Clear()) case .Ok, refusal);
		let executable = ProjectBuild.ExecutablePath(bed.Build.ProjectDir, "NativeGame", false, "ShippingRelease", .. scope .());
		Test.Assert(build.Directory == PathParent(executable, .. scope .()), build.Directory);
		Test.Assert(build.Binary == BuildLayout.ExecutableName("NativeGamePlayer", .. scope .()), build.Binary);
		Test.Assert((build.Files.Count == 2) && Has(build.Files, cLibrary) && Has(build.Files, BuildLayout.cThirdPartyNotices), "collected as a build's");
		Test.Assert(build.Job == null, "no job compiled it");
		Test.Assert(build.Description == scope $"NativeGamePlayer, ShippingRelease, {BuildLayout.HostPlatformName} (the last build)", build.Description);
		Test.Assert((steps.Count == 1) && (steps[0] == PlayerBuild.cProgressEnd), "its progress at the build's end");
		Test.Assert(service.GetLatest() == null, "no job tracked");

		// A config with no build is refused, whatever another config has.
		SetPreset(preset, BuildLayout.HostPlatformName, "Debug");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal..Clear()) case .Err(.NotFound));
		Test.Assert(refusal.StartsWith("NativeGamePlayer has not been built in Debug"), refusal);
	}

	/// What a preset builds is named for people as a build names it, and whether this host can
	/// build it says why not: another host's platform and a Test config, as Target refuses them.
	[Test]
	public static void APresetsPlayerIsDescribedAndItsBuildabilitySaid()
	{
		let preset = scope ExportPreset();
		let description = scope String();
		let why = scope String();
		SetPreset(preset, BuildLayout.HostPlatformName, "Profile");
		Test.Assert(ProjectPlayerBuilder.Describe("Sky Hopper", preset, description, why), why);
		let game = ProjectBuild.GameName("Sky Hopper", .. scope .());
		Test.Assert(description == scope $"{game}Player, Release, {BuildLayout.HostPlatformName}", description);
		Test.Assert(ProjectPlayerBuilder.CanBuild(preset, why), why);

		SetPreset(preset, BuildLayout.cWebPlatform, "Release");
		Test.Assert(ProjectPlayerBuilder.Describe("Sky Hopper", preset, description, why), why);
		Test.Assert(description == scope $"{game}PlayerWeb, ShippingRelease, wasm32", description);

		SetPreset(preset, OtherHost, "Release");
		Test.Assert(!ProjectPlayerBuilder.Describe("Sky Hopper", preset, description, why..Clear()));
		Test.Assert(!ProjectPlayerBuilder.CanBuild(preset, why..Clear()));
		Test.Assert(why.StartsWith(scope $"a {OtherHost} player builds on"), why);

		SetPreset(preset, BuildLayout.HostPlatformName, "Test");
		Test.Assert(!ProjectPlayerBuilder.CanBuild(preset, why..Clear()));
		Test.Assert(why.StartsWith("a Test build links the test runner"), why);
	}

#if !BF_PLATFORM_WINDOWS
	private const int32 cExecutable = 1; // X_OK

	[CLink]
	private static extern int32 access(char8* path, int32 mode);
#endif

	/// The staged builder writes a stand-in player with what a build leaves beside it, and gives
	/// it as a build would be given: the executable runnable, the shader compiler's library left
	/// out, the notices kept; a Web preset's page and its parts. It refuses what a real build does.
	[Test]
	public static void AStagedPlayerIsGivenAsABuildIs()
	{
		let bed = scope Bed();
		let folder = PathJoin(bed.Build.Root, "staged", .. scope .());
		let builder = scope StagedPlayerBuilder(folder);
		let preset = scope ExportPreset();
		let build = scope PlayerBuild();
		let refusal = scope String();

		SetPreset(preset, BuildLayout.HostPlatformName, "Release");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Ok, refusal);
		Test.Assert(build.Directory.StartsWith(folder), build.Directory);
		Test.Assert(build.Binary == BuildLayout.ExecutableName("NativeGamePlayer", .. scope .()), build.Binary);
		let binary = PathJoin(build.Directory, build.Binary, .. scope .());
		Test.Assert(FileExists(binary), binary);
#if !BF_PLATFORM_WINDOWS
		Test.Assert(access(binary.CStr(), cExecutable) == 0, "the stand-in player runnable");
#endif
		Test.Assert(FileExists(PathJoin(build.Directory, StagedPlayerBuilder.cDxcLibrary, .. scope .())), "the shader compiler's written");
		Test.Assert((build.Files.Count == 2) && Has(build.Files, StagedPlayerBuilder.cLibrary) && Has(build.Files, BuildLayout.cThirdPartyNotices),
			"the library and the notices, the shader compiler's left out");
		Test.Assert(build.Description == scope $"NativeGamePlayer, ShippingRelease, {BuildLayout.HostPlatformName} (staged)", build.Description);
		Test.Assert(build.Job == null, "no job compiled a stand-in");

		SetPreset(preset, BuildLayout.cWebPlatform, "Release");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Ok, refusal);
		Test.Assert(build.Binary == "NativeGamePlayerWeb.html", build.Binary);
		Test.Assert(FileExists(PathJoin(build.Directory, build.Binary, .. scope .())));
		Test.Assert((build.Files.Count == 4) && Has(build.Files, "NativeGamePlayerWeb.js") && Has(build.Files, "NativeGamePlayerWeb.wasm")
			&& Has(build.Files, "serve.py") && Has(build.Files, BuildLayout.cThirdPartyNotices), "the page's parts");
		Test.Assert(builder.Builds == 2);

		SetPreset(preset, OtherHost, "Release");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Err(.NotSupported));
		SetPreset(preset, BuildLayout.HostPlatformName, "Test");
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal..Clear()) case .Err(.InvalidArgument));
		Test.Assert(builder.Builds == 2, "nothing made for a refusal");
	}

	/// The script a Steam Deck build runs, as the bed's SDK has it (never started: the runner is
	/// the test's); its path.
	private static void WriteSteamDeckScript(Bed bed, String outScript)
	{
		ProjectBuildBed.Write(bed.Build.Sdk, SteamDeckPlayerBuilder.cScript, "#!/usr/bin/env bash\n");
		PathJoin(bed.Build.Sdk, SteamDeckPlayerBuilder.cScript, outScript);
	}

	/// The value after `--name` among `arguments`.
	private static StringView Option(Span<StringView> arguments, StringView name)
	{
		let flag = scope $"--{name}";
		for (int i < arguments.Length - 1)
		{
			if (arguments[i] == flag)
				return arguments[i + 1];
		}
		return default;
	}

	/// Writes what the Steam Deck script leaves in the bundle folder its `--out` names, as a build
	/// that worked: the player, a shared library, SDL3 by its soname and the notices; and the
	/// shader compiler's, which the export leaves out whatever the script did.
	private static void MakeBundle(Span<StringView> arguments)
	{
		let bundle = Option(arguments, "out");
		ProjectBuildBed.Write(bundle, Option(arguments, "project"), "#!built\n");
		ProjectBuildBed.Write(bundle, cLibrary, "so\n");
		ProjectBuildBed.Write(bundle, "libSDL3.so.0", "so\n");
		ProjectBuildBed.Write(bundle, BuildLayout.cThirdPartyNotices, "notices\n");
		ProjectBuildBed.Write(bundle, cDxcLibrary, "so\n");
	}

#if BF_PLATFORM_LINUX
	/// A Steam Deck preset (through the export's chooser) copies the project's packages under the
	/// SDK's build/steamdeck/projects/<Game>, a stale file of the copy gone and what its build
	/// wrote kept, generates the copy's workspace against the SDK as the container mounts it, and
	/// runs the script once with the workspace, <Game>Player, the build config and the bundle
	/// folder, its lines streamed into the service's latest job. The bundle is the build: the
	/// player, and every file beside it but the shader compiler's.
	[Test]
	public static void ASteamDeckPresetRunsTheScriptOverACopyAndShipsItsBundle()
	{
		let bed = scope Bed();
		let script = WriteSteamDeckScript(bed, .. scope .());
		let copy = SteamDeckPlayerBuilder.ProjectCopyDirectory(bed.Build.Sdk, "NativeGame", .. scope .());
		let workspace = ProjectBuild.Directory(copy, .. scope .());
		ProjectBuildBed.Write(workspace, "NativeGame/src/Gone.bf", "// deleted from the project since\n");
		ProjectBuildBed.Write(workspace, "build/ShippingRelease_Linux64/NativeGame/NativeGame.o", "object\n");

		let runs = scope List<String>();
		defer { ClearAndDeleteItems!(runs); }
		let seen = scope List<String>();
		defer { ClearAndDeleteItems!(seen); }
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs.Add(new .(executable));
				for (let argument in arguments)
					seen.Add(new .(argument));
				onLine("== Beef (built) ==");
				onLine("Compiling NativeGamePlayer");
				MakeBundle(arguments);
				return .Ok(0);
			}, cFakeBeefBuild);
		let builder = scope PresetPlayerBuilder(service, bed.DataRoot(.. scope .()));
		let preset = scope ExportPreset();
		SetPreset(preset, "Linux64", "Release");
		preset.Builder = .SteamDeck;
		let build = scope PlayerBuild();
		let refusal = scope String();
		Test.Assert(builder.Build(bed.Project, preset, build, null, refusal) case .Ok, refusal);

		Test.Assert((runs.Count == 1) && (runs[0] == script), (runs.Count > 0) ? runs[0] : "no run");
		let bundle = SteamDeckPlayerBuilder.BundleDirectory(bed.Build.Sdk, "NativeGamePlayer", "ShippingRelease", .. scope .());
		Test.Assert(bundle.EndsWith("build/steamdeck/out/ShippingRelease_Linux64/NativeGamePlayer"), bundle);
		let expected = scope StringView[]("--workspace", workspace, "--project", "NativeGamePlayer", "--config", "ShippingRelease", "--out", bundle);
		Test.Assert(seen.Count == expected.Count, scope String()..AppendF("{} arguments", seen.Count));
		for (int i < expected.Count)
			Test.Assert(seen[i] == expected[i], seen[i]);

		// The copy: the packages as the project has them, generated for the container's SDK.
		Test.Assert(copy.EndsWith("build/steamdeck/projects/NativeGame"), copy);
		Test.Assert(FileExists(PathJoin(workspace, "NativeGame/BeefProj.toml", .. scope .())));
		Test.Assert(FileExists(PathJoin(copy, "Plugins/Lantern/Lantern.Engine/BeefProj.toml", .. scope .())), "a Plugins/ package too");
		Test.Assert(!FileExists(PathJoin(workspace, "NativeGame/src/Gone.bf", .. scope .())), "a file the project no longer has is gone");
		Test.Assert(FileExists(PathJoin(workspace, "build/ShippingRelease_Linux64/NativeGame/NativeGame.o", .. scope .())), "the copy's build kept");
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(workspace, ProjectBuild.cConfigFile, .. scope .()), bytes) case .Ok);
		let registry = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		Test.Assert(registry == ProjectBuild.ConfigText(SteamDeckPlayerBuilder.cContainerSdk, .. scope .()), registry);
		Test.Assert(!FileExists(PathJoin(bed.Build.ProjectDir, "Code/BeefConfig.toml", .. scope .())), "the project itself is not generated");

		Test.Assert(build.Directory == bundle, build.Directory);
		Test.Assert(build.Binary == "NativeGamePlayer", build.Binary);
		Test.Assert((build.Files.Count == 3) && Has(build.Files, cLibrary) && Has(build.Files, "libSDL3.so.0") && Has(build.Files, BuildLayout.cThirdPartyNotices),
			"the library, SDL3 and the notices");
		Test.Assert(!Has(build.Files, cDxcLibrary), "the shader compiler left out");
		Test.Assert(build.Description == "NativeGamePlayer, ShippingRelease, Linux64, Steam Deck", build.Description);

		let latest = service.GetLatest();
		Test.Assert((latest != null) && (latest.Target == .Player) && (latest.State == .Succeeded), "the script's run is the service's latest job");
		Test.Assert(build.Job === latest, "the build carries the job");
		let output = scope List<String>();
		defer { ClearAndDeleteItems!(output); }
		latest.GetOutput(output);
		Test.Assert((output.Count == 2) && (output[1] == "Compiling NativeGamePlayer"), "its lines streamed into the job");
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		latest.GetExecutables(made);
		Test.Assert((made.Count == 1) && (made[0] == PathJoin(bundle, "NativeGamePlayer", .. scope .())), "the bundle's player");
		latest?.ReleaseRef();

		Test.Assert(PresetPlayerBuilder.Describe("Native Game", preset, refusal..Clear(), scope .()) && (refusal == build.Description), refusal);
	}

	/// A Steam Deck build that fails refuses with the script's error and the first errors it
	/// printed; one that ends well with no player in its bundle refuses, saying so; a cancel ends
	/// it cancelled. One made to reuse the last build runs nothing, refuses with no bundle and
	/// ships the bundle there.
	[Test]
	public static void ASteamDeckBuildsFailureCancelAndReuse()
	{
		let bed = scope Bed();
		WriteSteamDeckScript(bed, .. scope .());
		let preset = scope ExportPreset();
		SetPreset(preset, "Linux64", "Release");
		preset.Builder = .SteamDeck;
		let refusal = scope String();
		{
			let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
				{
					for (let line in cFailedBuild.Split('\n'))
						onLine(line);
					return .Ok(1);
				}, cFakeBeefBuild);
			let builder = scope SteamDeckPlayerBuilder(service, bed.DataRoot(.. scope .()));
			Test.Assert(builder.Build(bed.Project, preset, scope PlayerBuild(), null, refusal) case .Err(.Internal));
			Test.Assert(refusal.StartsWith("build-steamdeck.sh failed building NativeGamePlayer (ShippingRelease), exit 1, 4 errors\n"), refusal);
			Test.Assert(refusal.Contains("Other.bf:7:17: Expression expected"), refusal);
		}
		{
			let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) => Result<int, ErrorCode>.Ok(0), cFakeBeefBuild);
			let builder = scope SteamDeckPlayerBuilder(service, bed.DataRoot(.. scope .()));
			Test.Assert(builder.Build(bed.Project, preset, scope PlayerBuild(), null, refusal..Clear()) case .Err(.NotFound));
			Test.Assert(refusal.Contains("ended without building"), refusal);
		}
		{
			let source = scope CancelSource();
			let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
				{
					source.Cancel();
					if (cancelled())
						return .Err(.Cancelled);
					return .Ok(0);
				}, cFakeBeefBuild);
			let builder = scope SteamDeckPlayerBuilder(service, bed.DataRoot(.. scope .()), source.Token);
			Test.Assert(builder.Build(bed.Project, preset, scope PlayerBuild(), null, refusal..Clear()) case .Err(.Cancelled));
			Test.Assert(refusal.Contains("cancelled"), refusal);
			let latest = service.GetLatest();
			Test.Assert((latest != null) && (latest.State == .Cancelled));
			latest?.ReleaseRef();
		}
		{
			let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
				{
					Test.FatalError("nothing runs");
					return .Ok(0);
				}, cFakeBeefBuild);
			let builder = scope SteamDeckPlayerBuilder(service, bed.DataRoot(.. scope .()), null, true);
			let build = scope PlayerBuild();
			Test.Assert(builder.Build(bed.Project, preset, build, null, refusal..Clear()) case .Err(.NotFound));
			Test.Assert(refusal.Contains("has not been built for the Steam Deck"), refusal);
			let bundle = SteamDeckPlayerBuilder.BundleDirectory(bed.Build.Sdk, "NativeGamePlayer", "ShippingRelease", .. scope .());
			MakeBundle(scope StringView[]("--project", "NativeGamePlayer", "--out", bundle));
			Test.Assert(builder.Build(bed.Project, preset, build, null, refusal..Clear()) case .Ok, refusal);
			Test.Assert((build.Directory == bundle) && (build.Files.Count == 3) && (build.Job == null));
			Test.Assert(build.Description.EndsWith("(the last build)"), build.Description);
		}
	}
#endif

	/// A Steam Deck player is a Linux64 one: a preset of another platform is refused before
	/// anything runs, is tracked or is copied, and is neither buildable nor described.
	[Test]
	public static void ASteamDeckPresetOfAnotherPlatformIsRefused()
	{
		let bed = scope Bed();
		WriteSteamDeckScript(bed, .. scope .());
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
			{
				Test.FatalError("nothing runs");
				return .Ok(0);
			}, cFakeBeefBuild);
		let builder = scope PresetPlayerBuilder(service, bed.DataRoot(.. scope .()));
		let preset = scope ExportPreset();
		SetPreset(preset, BuildLayout.cWebPlatform, "Release");
		preset.Builder = .SteamDeck;
		let refusal = scope String();
		Test.Assert(builder.Build(bed.Project, preset, scope PlayerBuild(), null, refusal) case .Err(.InvalidArgument));
		Test.Assert(refusal.StartsWith("a Steam Deck player is a Linux64 one"), refusal);
		Test.Assert(!PresetPlayerBuilder.CanBuild(preset, refusal..Clear()) && refusal.StartsWith("a Steam Deck player is a Linux64 one"), refusal);
		Test.Assert(!PresetPlayerBuilder.Describe("Native Game", preset, scope .(), refusal..Clear()), refusal);
		Test.Assert(service.GetLatest() == null, "no job tracked");
		let copy = SteamDeckPlayerBuilder.ProjectCopyDirectory(bed.Build.Sdk, "NativeGame", .. scope .());
		Test.Assert(!DirectoryExists(copy), "nothing copied");
	}

	/// The preset's builder round trips through export_presets.xml and the binary form, Host by
	/// default, and is copied with the preset.
	[Test]
	public static void ThePresetsBuilderRoundTrips()
	{
		let bed = scope Bed();
		let root = scope NativeFileSystem(bed.Build.Root);
		let written = scope ExportPresetSet();
		let deck = new ExportPreset();
		deck.Name.Set("Steam Deck");
		deck.Platform.Set("Linux64");
		deck.Builder = .SteamDeck;
		written.Presets.Add(deck);
		let desktop = new ExportPreset();
		desktop.Name.Set("Linux64 Desktop");
		desktop.Platform.Set("Linux64");
		written.Presets.Add(desktop);
		Test.Assert(desktop.Builder == .Host, "Host by default");
		Test.Assert(ExportPresetsFile.Save(root, written) case .Ok);
		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, loaded) case .Ok);
		Test.Assert(loaded.Find("Steam Deck").Builder == .SteamDeck);
		Test.Assert(loaded.Find("Linux64 Desktop").Builder == .Host);

		let stream = scope Sedulous.Core.IO.MemoryStream();
		{
			let ar = scope BinarySerializer(stream, .Write);
			ISerializable serializable = deck;
			serializable.Serialize(ar);
		}
		stream.Seek(0, .Begin);
		let read = scope ExportPreset();
		{
			let ar = scope BinarySerializer(stream, .Read);
			ISerializable serializable = read;
			serializable.Serialize(ar);
			Test.Assert(ar.IsOk);
		}
		Test.Assert((read.Builder == .SteamDeck) && (read.Name == "Steam Deck"));

		let copied = scope ExportPreset();
		deck.CopyTo(copied);
		Test.Assert(copied.Builder == .SteamDeck);
	}

	/// export_presets.xml as it was saved before the builder (a preset at data version 1, with the
	/// legacy template id), as every sample's was.
	private const String cPresetsBeforeTheBuilder = """
		<root>
			<array name="dataVersions" count="1">
				<u64 name="type">13515188249936753472</u64>
				<u32 name="version">3</u32>
			</array>
			<object>
				<array name="presets" count="1">
					<array name="dataVersions" count="1">
						<u64 name="type">864580422535781968</u64>
						<u32 name="version">1</u32>
					</array>
					<object>
						<string name="name">Steam Deck</string>
						<string name="platform">Linux64</string>
						<string name="templateId">sedulous-steamdeck-release-0.1.0</string>
						<string name="playerName">SkyHopper</string>
						<string name="outputSubdir">SteamDeck</string>
						<array name="additionalFiles" count="0">
						</array>
						<string name="config"/>
						<bool name="stageSymbols">false</bool>
						<bool name="pruneToReachable">false</bool>
						<bool name="overridesRender">false</bool>
						<u32 name="renderWidth">0</u32>
						<u32 name="renderHeight">0</u32>
						<u8 name="renderFit">1</u8>
						<bool name="overridesWindow">true</bool>
						<u32 name="windowWidth">1280</u32>
						<u32 name="windowHeight">800</u32>
						<u8 name="windowMode">0</u8>
						<bool name="windowResizable">true</bool>
						<bool name="overridesOrientation">false</bool>
						<u8 name="orientation">0</u8>
						<bool name="includeShaderSource">true</bool>
					</object>
				</array>
			</object>
		</root>
		""";

	/// A preset stored before the builder reads as Host, the fields before it as written: from
	/// the text file a project keeps, and from a binary payload of version 1, which is positional
	/// and ends where the builder now starts.
	[Test]
	public static void APresetFromBeforeTheBuilderReadsAsHost()
	{
		let bed = scope Bed();
		ProjectBuildBed.Write(bed.Build.Root, ExportPresetsFile.cFileName, cPresetsBeforeTheBuilder);
		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(scope NativeFileSystem(bed.Build.Root), loaded) case .Ok);
		let deck = loaded.Find("Steam Deck");
		Test.Assert(deck != null);
		Test.Assert(deck.Builder == .Host, "no builder stored: Host");
		Test.Assert((deck.Platform == "Linux64") && (deck.PlayerName == "SkyHopper") && (deck.WindowHeight == 800) && deck.IncludeShaderSource,
			"the fields before it as written");
		Test.Assert(deck.TemplateId.IsEmpty);

		// Binary: the current payload, its version made 1 and the builder off its end.
		let preset = scope ExportPreset();
		preset.Name.Set("Steam Deck");
		preset.Platform.Set("Linux64");
		preset.IncludeShaderSource = true;
		preset.Builder = .SteamDeck;
		let current = scope Sedulous.Core.IO.MemoryStream();
		{
			let ar = scope BinarySerializer(current, .Write);
			ISerializable serializable = preset;
			serializable.Serialize(ar);
		}
		let bytes = scope List<uint8>();
		bytes.AddRange(current.Bytes);
		// The chain, little endian: its count (4 bytes), the type id (8), then the version.
		Test.Assert((bytes[0] == 1) && (ExportPreset.DataVersion == 2) && (bytes[12] == 2), "the layout read here");
		bytes[12] = 1;
		let old = scope Sedulous.Core.IO.MemoryStream();
		old.Write(Span<uint8>(bytes.Ptr, bytes.Count - sizeof(ExportBuilder)));
		old.Seek(0, .Begin);
		let read = scope ExportPreset();
		{
			let ar = scope BinarySerializer(old, .Read);
			ISerializable serializable = read;
			serializable.Serialize(ar);
			Test.Assert(ar.IsOk, "a version 1 payload is read");
		}
		Test.Assert(read.Builder == .Host, "no builder stored: Host");
		Test.Assert((read.Name == "Steam Deck") && read.IncludeShaderSource, "the fields before it as written");
		Test.Assert(old.Tell() == old.Size(), "read to its end and no further");
	}
}
