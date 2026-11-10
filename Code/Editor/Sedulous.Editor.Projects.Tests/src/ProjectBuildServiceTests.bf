using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

using Sedulous.Editor.Projects.TestSupport;

namespace Sedulous.Editor.Projects.Tests;

/// The build service's jobs, run over the project build's bed by a fake BeefBuild: the lines it
/// prints go into the job as they come, its exit and what it built decide how the job ends.
class ProjectBuildServiceTests
{
	private const String cFailedBuild = Compiler.ReadText("src/Fixtures/beefbuild-errors.txt");
	/// What the fake runs; never started.
	private const String cFakeBeefBuild = "/fake/BeefBuild";

	/// A job of `target` over the bed's project, its settings a copy (the job takes them), the
	/// SDK found through the bed's data root; a Player job in `config` for `platform`.
	private static BuildJob MakeJob(ProjectBuildBed bed, BuildTarget target, StringView config = default, StringView platform = default)
	{
		let settings = new ProjectSettings();
		Test.Assert(ProjectManifest.Copy(bed.Settings, settings) case .Ok);
		return new BuildJob(target, bed.ProjectDir, PathJoin(bed.Sdk, "Data", .. scope .()), settings, config, platform);
	}

	/// The entry a BeefBuild run's -project= names.
	private static BuildEntry EntryOf(StringView project)
	{
		if (project.EndsWith(ProjectBuild.cEditorSuffix))
			return .Editor;
		if (project.EndsWith(ProjectBuild.cPlayerWebSuffix))
			return .PlayerWeb;
		if (project.EndsWith(ProjectBuild.cToolsSuffix))
			return .Tools;
		return .Player;
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

	/// Writes what a BeefBuild run of `arguments` would make (an executable, or the web player's
	/// page), as a build that worked.
	private static void Make(ProjectBuildBed bed, Span<StringView> arguments)
	{
		let entry = EntryOf(Argument(arguments, "project"));
		let path = ProjectBuild.EntryPath(bed.ProjectDir, "NativeGame", entry, Argument(arguments, "config"), .. scope .());
		ProjectBuildBed.Write(bed.ProjectDir, path.Substring(bed.ProjectDir.Length + 1), "#!built\n");
	}

	/// The editor alone: one run, over the generated workspace, for <Game>Editor in Debug. A
	/// status read while it runs sees it building that; once it ends it has succeeded, with the
	/// lines it printed and the executable it made.
	[Test]
	public static void AnEditorBuildRunsOnceAndSucceeds()
	{
		let bed = scope ProjectBuildBed();
		int runs = 0;
		let seenProject = scope String();
		let seenConfig = scope String();
		BuildJobState seenState = .Queued;
		let workspace = scope String();
		BuildJob job = MakeJob(bed, .Editor);
		defer job.ReleaseRef();
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs++;
				Test.Assert(executable == cFakeBeefBuild);
				workspace.Set(Argument(arguments, "workspace"));
				Test.Assert(Argument(arguments, "platform") == BuildLayout.HostPlatformName);
				onLine("[    ]\b\b\b\b\b\b**Compiling NativeGameEditor");
				onLine("");
				job.GetStep(seenProject, seenConfig);
				seenState = job.State;
				Make(bed, arguments);
				return .Ok(0);
			}, cFakeBeefBuild);
		service.Track(job);
		Test.Assert(job.State == .Queued);
		Test.Assert(service.Run(job) case .Ok);

		Test.Assert(runs == 1, scope String()..AppendF("{} runs", runs));
		Test.Assert(workspace == ProjectBuild.Directory(bed.ProjectDir, .. scope .()), workspace);
		Test.Assert((seenProject == "NativeGameEditor") && (seenConfig == "Debug") && (seenState == .Building), seenProject);
		Test.Assert(job.State == .Succeeded);
		Test.Assert((job.StartTime > 0) && (job.EndTime >= job.StartTime));
		let output = scope List<String>();
		defer { ClearAndDeleteItems!(output); }
		job.GetOutput(output);
		Test.Assert((output.Count == 1) && (output[0] == "Compiling NativeGameEditor"), "the bar off, the blank line left out");
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		Test.Assert((made.Count == 1) && (made[0] == ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .())), "the editor");
		Test.Assert(job.GetError(.. scope .()).IsEmpty);

		let latest = service.GetLatest();
		Test.Assert(latest === job);
		latest.ReleaseRef();
	}

	/// A fake Beef install in the bed whose BeefSettings.toml names `emsdk` (under the bed's
	/// root) as Emscripten; its BeefBuild's path.
	private static void FakeBeefWithEmscripten(ProjectBuildBed bed, StringView emsdk, String outBeefBuild)
	{
		ProjectBuildBed.FakeInstall(bed, "beef/IDE/dist/BeefBuild", "\"../../BeefLibs\"", "beef/BeefLibs/corlib", outBeefBuild);
		let path = PathJoin(bed.Root, emsdk, .. scope .());
		ProjectBuildBed.Write(bed.Root, "beef/IDE/dist/BeefSettings.toml", scope $"FileVersion = 1\n\n[Wasm]\nEmscriptenPath = '{path}'\n");
	}

	/// A Player job for wasm32 (or the presets' Web) is one run of <Game>PlayerWeb over the web
	/// player's own workspace for wasm32, Emscripten found in BeefBuild's settings first; what it
	/// made is its page. A Player job for this host is <Game>Player over Code/.
	[Test]
	public static void AWebPlayerBuildsInItsOwnWorkspaceForWasm()
	{
		let bed = scope ProjectBuildBed();
		let beefBuild = FakeBeefWithEmscripten(bed, "emsdk", .. scope .());
		ProjectBuildBed.FakeEmscripten(bed, "emsdk", .. scope .());
		let home = PathJoin(bed.Root, "home", .. scope .());
		let runs = scope List<String>();
		defer { ClearAndDeleteItems!(runs); }
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				Test.Assert(executable == beefBuild);
				runs.Add(new $"{Argument(arguments, "workspace")} {Argument(arguments, "project")} {Argument(arguments, "config")} {Argument(arguments, "platform")}");
				Make(bed, arguments);
				return .Ok(0);
			}, beefBuild, home);

		let job = MakeJob(bed, .Player, "ShippingRelease", "wasm32");
		defer job.ReleaseRef();
		Test.Assert((job.StepCount == 1) && (job.StepEntry(0) == .PlayerWeb) && (job.StepConfig(0) == "ShippingRelease") && (job.StepPlatform(0) == "wasm32"));
		Test.Assert(service.Run(job) case .Ok, job.GetError(.. scope .()));
		Test.Assert(runs.Count == 1, scope String()..AppendF("{} runs", runs.Count));
		let webWorkspace = ProjectBuild.WebWorkspaceDirectory(bed.ProjectDir, .. scope .());
		Test.Assert(runs[0] == scope $"{webWorkspace} NativeGamePlayerWeb ShippingRelease wasm32", runs[0]);
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		let page = ProjectBuild.WebPagePath(bed.ProjectDir, "NativeGame", "ShippingRelease", .. scope .());
		Test.Assert((made.Count == 1) && (made[0] == page), "the page");

		let byTag = MakeJob(bed, .Player, "Debug", BuildLayout.cWebPlatform);
		defer byTag.ReleaseRef();
		Test.Assert((byTag.StepEntry(0) == .PlayerWeb) && (byTag.StepPlatform(0) == "wasm32"), "the presets' Web is wasm32");

		let host = MakeJob(bed, .Player, "Release");
		defer host.ReleaseRef();
		Test.Assert((host.StepEntry(0) == .Player) && (host.StepPlatform(0) == BuildLayout.HostPlatformName));
		Test.Assert(service.Run(host) case .Ok, host.GetError(.. scope .()));
		Test.Assert(runs.Count == 2, scope String()..AppendF("{} runs", runs.Count));
		let workspace = ProjectBuild.Directory(bed.ProjectDir, .. scope .());
		Test.Assert(runs[1] == scope $"{workspace} NativeGamePlayer Release {BuildLayout.HostPlatformName}", runs[1]);
	}

	/// A web job is refused before BeefBuild runs or anything is written when BeefBuild's settings
	/// name no Emscripten, or one without emcc, saying what to set; a job for another host's
	/// platform is refused too.
	[Test]
	public static void AWebBuildNeedsEmscriptenFirst()
	{
		let bed = scope ProjectBuildBed();
		let beefBuild = FakeBeefWithEmscripten(bed, "emsdk", .. scope .());
		let home = PathJoin(bed.Root, "home", .. scope .());
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
			{
				Test.FatalError("nothing runs");
				return .Ok(0);
			}, beefBuild, home);
		{
			let job = MakeJob(bed, .Player, "ShippingRelease", "wasm32");
			defer job.ReleaseRef();
			Test.Assert(service.Run(job) case .Err(.NotFound));
			let error = job.GetError(.. scope .());
			Test.Assert(error.Contains("has no upstream/emscripten/emcc") && (job.State == .Failed), error);
		}
		DeleteFile(PathJoin(bed.Root, "beef/IDE/dist/BeefSettings.toml", .. scope .()));
		{
			let job = MakeJob(bed, .Player, "Debug", "wasm32");
			defer job.ReleaseRef();
			Test.Assert(service.Run(job) case .Err(.NotFound));
			let error = job.GetError(.. scope .());
			Test.Assert(error.StartsWith("a web build needs Emscripten") && error.Contains("EmscriptenPath"), error);
		}
		{
			StringView otherHost = (BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64";
			let job = MakeJob(bed, .Player, "Debug", otherHost);
			defer job.ReleaseRef();
			Test.Assert(service.Run(job) case .Err(.NotSupported));
			let error = job.GetError(.. scope .());
			Test.Assert(error.Contains(scope $"this host is {BuildLayout.HostPlatformName}"), error);
		}
		Test.Assert(!FileExists(PathJoin(bed.ProjectDir, "Code/BeefSpace.toml", .. scope .())), "nothing generated");
	}

	/// A failed build's lines give its diagnostics, read as they came; the job fails, its error
	/// naming the run, the exit and the count of errors.
	[Test]
	public static void AFailedRunGivesItsDiagnostics()
	{
		let bed = scope ProjectBuildBed();
		int runs = 0;
		let job = MakeJob(bed, .Editor);
		defer job.ReleaseRef();
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs++;
				for (let line in cFailedBuild.Split('\n'))
					onLine(line);
				return .Ok(1);
			}, cFakeBeefBuild);
		Test.Assert(service.Run(job) case .Err(.Internal));
		Test.Assert(runs == 1);
		Test.Assert(job.State == .Failed);
		Test.Assert((job.ErrorCount == 4) && (job.WarningCount == 6), scope String()..AppendF("{} errors, {} warnings", job.ErrorCount, job.WarningCount));
		let error = job.GetError(.. scope .());
		Test.Assert(error == "BeefBuild failed building NativeGameEditor (Debug), exit 1, 4 errors", error);
		let diagnostics = scope List<BuildDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		job.GetDiagnostics(diagnostics);
		Test.Assert((diagnostics.Count == 10) && (diagnostics[0].Message == "Expression expected") && (diagnostics[0].Line == 7), "copies, in order");
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		Test.Assert(made.IsEmpty);
	}

	/// A run that fails with nothing read as an error still fails, the end of its output in the
	/// error; one that exits well without making its executable fails too.
	[Test]
	public static void AFailureWithNoErrorQuotesTheOutput()
	{
		let bed = scope ProjectBuildBed();
		{
			let job = MakeJob(bed, .Editor);
			defer job.ReleaseRef();
			let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
				{
					onLine("Compiling NativeGameEditor");
					onLine("Segmentation fault (core dumped)");
					return .Ok(139);
				}, cFakeBeefBuild);
			Test.Assert(service.Run(job) case .Err);
			Test.Assert(job.State == .Failed);
			let error = job.GetError(.. scope .());
			Test.Assert(error.StartsWith("BeefBuild failed building NativeGameEditor (Debug), exit 139, and no error it printed was read"), error);
			Test.Assert(error.EndsWith("\nCompiling NativeGameEditor\nSegmentation fault (core dumped)"), error);
		}
		{
			let job = MakeJob(bed, .Editor);
			defer job.ReleaseRef();
			let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) => Result<int, ErrorCode>.Ok(0), cFakeBeefBuild);
			Test.Assert(service.Run(job) case .Err(.NotFound));
			Test.Assert(job.GetError(.. scope .()).StartsWith("BeefBuild ended without building"));
		}
	}

	/// A cancel while BeefBuild runs reaches the runner's check; the job ends Cancelled. So does a cancel of the task's token, and one before the job runs, which
	/// never starts BeefBuild.
	[Test]
	public static void ACancelEndsTheJobCancelled()
	{
		let bed = scope ProjectBuildBed();
		{
			int runs = 0;
			let job = MakeJob(bed, .Editor);
			defer job.ReleaseRef();
			let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
				{
					runs++;
					Test.Assert(!cancelled());
					job.Cancel();
					if (cancelled())
						return .Err(.Cancelled);
					return .Ok(0);
				}, cFakeBeefBuild);
			Test.Assert(service.Run(job) case .Err(.Cancelled));
			Test.Assert((runs == 1) && (job.State == .Cancelled), "cancelled in the first run");
		}
		{
			int runs = 0;
			let outer = scope CancelSource();
			let job = MakeJob(bed, .Editor);
			defer job.ReleaseRef();
			let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
				{
					runs++;
					outer.Cancel();
					if (cancelled())
						return .Err(.Cancelled);
					return .Ok(0);
				}, cFakeBeefBuild);
			Test.Assert(service.Run(job, outer.Token) case .Err(.Cancelled));
			Test.Assert((runs == 1) && (job.State == .Cancelled), "cancelled through the task's token");
		}
		{
			int runs = 0;
			let job = MakeJob(bed, .Editor);
			defer job.ReleaseRef();
			let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
				{
					runs++;
					return .Ok(0);
				}, cFakeBeefBuild);
			job.Cancel();
			Test.Assert(service.Run(job) case .Err(.Cancelled));
			Test.Assert((runs == 0) && (job.State == .Cancelled), "never started");
		}
	}

	/// A job whose task was dropped before it ran ends Cancelled; one that ran keeps how it ended.
	[Test]
	public static void ADroppedJobEndsCancelled()
	{
		let bed = scope ProjectBuildBed();
		let queued = MakeJob(bed, .Editor);
		defer queued.ReleaseRef();
		queued.Dropped();
		Test.Assert((queued.State == .Cancelled) && (queued.EndTime > 0));

		let ran = MakeJob(bed, .Editor);
		defer ran.ReleaseRef();
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) => Result<int, ErrorCode>.Ok(1), cFakeBeefBuild);
		Test.Assert(service.Run(ran) case .Err);
		ran.Dropped();
		Test.Assert(ran.State == .Failed);
	}

	/// A build is refused without an SDK, and Build Project's (the editor's) for a project with no
	/// package of its own, before anything runs or is written.
	[Test]
	public static void ABuildNeedsAnSdkAndAPackage()
	{
		let bed = scope ProjectBuildBed();
		let service = scope ProjectBuildService(new (executable, arguments, onLine, cancelled) =>
			{
				Test.FatalError("nothing runs");
				return .Ok(0);
			}, cFakeBeefBuild);
		// SEDULOUS_SDK set where the tests run would find that SDK: the refusal is checked without.
		let variable = scope String();
		if ((Environment.GetEnvironmentVariable(ProjectBuild.cSdkVariable, variable) case .Err) || !ProjectBuild.IsSdk(variable))
		{
			let settings = new ProjectSettings();
			Test.Assert(ProjectManifest.Copy(bed.Settings, settings) case .Ok);
			let job = new BuildJob(.Editor, bed.ProjectDir, bed.ProjectDir, settings);
			defer job.ReleaseRef();
			Test.Assert(service.Run(job) case .Err(.NotSupported));
			Test.Assert(job.GetError(.. scope .()).Contains("needs the engine SDK: set SEDULOUS_SDK, or run from an engine checkout"));
		}
		ClearAndDeleteItems!(bed.Settings.Plugins);
		Test.Assert(!ProjectBuild.HasPackages(bed.Settings));
		{
			let job = MakeJob(bed, .Editor);
			defer job.ReleaseRef();
			Test.Assert(service.Run(job) case .Err(.NotFound));
			Test.Assert(job.GetError(.. scope .()).Contains("no package of its own"));
			Test.Assert(job.State == .Failed);
		}
		Test.Assert(!FileExists(PathJoin(bed.ProjectDir, "Code/BeefSpace.toml", .. scope .())), "nothing generated");
	}

	/// A project with no package of its own builds its player: the workspace is generated, and
	/// <Game>Player runs over it like any project's.
	[Test]
	public static void APlayerBuildsWithoutAPackage()
	{
		let bed = scope ProjectBuildBed();
		ClearAndDeleteItems!(bed.Settings.Plugins);
		let runs = scope List<String>();
		defer { ClearAndDeleteItems!(runs); }
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs.Add(new $"{Argument(arguments, "project")} {Argument(arguments, "config")}");
				Make(bed, arguments);
				return .Ok(0);
			}, cFakeBeefBuild);
		let job = MakeJob(bed, .Player, "ShippingRelease");
		defer job.ReleaseRef();
		Test.Assert(service.Run(job) case .Ok, job.GetError(.. scope .()));
		Test.Assert((runs.Count == 1) && (runs[0] == "NativeGamePlayer ShippingRelease"), "one run of the player");
		let player = bed.Read(".generated/NativeGamePlayer/BeefProj.toml", .. scope .());
		Test.Assert(!player.Contains("\"NativeGame\" = \"*\"") && !player.Contains("Lantern"), player);
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		Test.Assert((made.Count == 1) && (made[0] == ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "ShippingRelease", .. scope .())));
	}

	/// The editor is stale when it is not built, or older than a file of the project's packages;
	/// what builds write does not count.
	[Test]
	public static void TheEditorIsStaleWhenOlderThanAPackageFile()
	{
		let bed = scope ProjectBuildBed();
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "not built");
		System.Threading.Thread.Sleep(50);
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		ProjectBuildBed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
		System.Threading.Thread.Sleep(50);
		bed.WriteCode(".generated/NativeGameEditor/src/Program.bf", "// generated\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "what builds write is not the game's");
		bed.WriteCode("NativeGame/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
	}
}
