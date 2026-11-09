using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The player an export ships, built for a preset: by the project's build through a fake
/// BeefBuild that writes what a real one leaves (ProjectPlayerBuilder), or staged with no
/// compiler (StagedPlayerBuilder); what is collected beside it, and what is refused.
class PlayerBuildTests
{
	private const String cFailedBuild = Compiler.ReadText("src/Fixtures/beefbuild-errors.txt");
	/// What the fake runs; never started.
	private const String cFakeBeefBuild = "/fake/BeefBuild";
	/// The shared library a build leaves beside the player, which ships.
	private const String cLibrary = "libSDL3.so";
	/// The shader compiler's, which a build leaves beside it too and which never ships.
	private const String cDxcLibrary = "libdxcompiler.so";

	/// The project build's bed (ProjectBuildTests.Bed), its project saved and opened as an
	/// EditorProject.
	private class Bed
	{
		public ProjectBuildTests.Bed Build = new .() ~ delete _;
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
	private static void Make(ProjectBuildTests.Bed bed, Span<StringView> arguments)
	{
		let project = Argument(arguments, "project");
		let web = project.EndsWith(ProjectBuild.cPlayerWebSuffix);
		let made = ProjectBuild.EntryPath(bed.ProjectDir, "NativeGame", web ? BuildEntry.PlayerWeb : BuildEntry.Player, Argument(arguments, "config"), .. scope .());
		let dir = PathParent(made, .. scope .());
		ProjectBuildTests.Bed.Write(dir, PathFilename(made, .. scope .()), "#!built\n");
		ProjectBuildTests.Bed.Write(dir, BuildLayout.cThirdPartyNotices, "notices\n");
		if (web)
		{
			for (let part in StringView[4](".js", ".wasm", ".o", ".log"))
				ProjectBuildTests.Bed.Write(dir, scope $"{project}{part}", "part\n");
			ProjectBuildTests.Bed.Write(dir, "serve.py", "# serve\n");
		}
		else
		{
			ProjectBuildTests.Bed.Write(dir, cLibrary, "so\n");
			ProjectBuildTests.Bed.Write(dir, cDxcLibrary, "so\n");
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
		let beefBuild = ProjectBuildTests.FakeInstall(bed.Build, "beef/IDE/dist/BeefBuild", "\"../../BeefLibs\"", "beef/BeefLibs/corlib", .. scope .());
		let emsdk = ProjectBuildTests.FakeEmscripten(bed.Build, "emsdk", .. scope .());
		ProjectBuildTests.Bed.Write(bed.Build.Root, "beef/IDE/dist/BeefSettings.toml", scope $"FileVersion = 1\n\n[Wasm]\nEmscriptenPath = '{emsdk}'\n");
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
}
