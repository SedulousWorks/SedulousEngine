using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The build service's jobs, run over the project build's bed by a fake BeefBuild: the lines it
/// prints go into the job as they come, its exit and what it built decide how the job ends.
class ProjectBuildServiceTests
{
	private const String cFailedBuild = Compiler.ReadText("src/Fixtures/beefbuild-errors.txt");
	/// What the fake runs; never started.
	private const String cFakeBeefBuild = "/fake/BeefBuild";

	/// A job of `target` over the bed's project, its settings a copy (the job takes them), the
	/// SDK found through the bed's data root.
	private static BuildJob MakeJob(ProjectBuildTests.Bed bed, BuildTarget target, ExportPresetSet presets = null)
	{
		let settings = new ProjectSettings();
		Test.Assert(ProjectManifest.Copy(bed.Settings, settings) case .Ok);
		return new BuildJob(target, bed.ProjectDir, PathJoin(bed.Sdk, "Data", .. scope .()), settings, presets);
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

	/// Writes the executable a BeefBuild run of `arguments` would make, as a build that worked.
	private static void Make(ProjectBuildTests.Bed bed, Span<StringView> arguments)
	{
		let project = Argument(arguments, "project");
		let editor = project.EndsWith(ProjectBuild.cEditorSuffix);
		let path = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", editor, Argument(arguments, "config"), .. scope .());
		ProjectBuildTests.Bed.Write(bed.ProjectDir, path.Substring(bed.ProjectDir.Length + 1), "#!built\n");
	}

	/// The editor alone: one run, over the generated workspace, for <Game>Editor in Debug. A
	/// status read while it runs sees it building that; once it ends it has succeeded, with the
	/// lines it printed and the executable it made.
	[Test]
	public static void AnEditorBuildRunsOnceAndSucceeds()
	{
		let bed = scope ProjectBuildTests.Bed();
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

	/// Build Project's target: the editor in Debug, then the player in each config the presets
	/// name for this host after Debug, in order.
	[Test]
	public static void AllBuildsTheEditorThenEachPlayerConfig()
	{
		let bed = scope ProjectBuildTests.Bed();
		let presets = scope ExportPresetSet();
		let preset = new ExportPreset();
		preset.Platform.Set(BuildLayout.HostPlatformName);
		preset.Config.Set("Release");
		presets.Presets.Add(preset);
		let runs = scope List<String>();
		defer { ClearAndDeleteItems!(runs); }
		let job = MakeJob(bed, .All, presets);
		defer job.ReleaseRef();
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs.Add(new $"{Argument(arguments, "project")} {Argument(arguments, "config")}");
				Make(bed, arguments);
				return .Ok(0);
			}, cFakeBeefBuild);
		Test.Assert(service.Run(job) case .Ok);
		Test.Assert(runs.Count == 3, scope String()..AppendF("{} runs", runs.Count));
		Test.Assert((runs[0] == "NativeGameEditor Debug") && (runs[1] == "NativeGamePlayer Debug") && (runs[2] == "NativeGamePlayer ShippingRelease"), runs[2]);
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		Test.Assert(made.Count == 3);
	}

	/// A failed build's lines give its diagnostics, read as they came; the job fails, its error
	/// naming the run, the exit and the count of errors, and no later run starts.
	[Test]
	public static void AFailedRunGivesItsDiagnostics()
	{
		let bed = scope ProjectBuildTests.Bed();
		int runs = 0;
		let job = MakeJob(bed, .All);
		defer job.ReleaseRef();
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs++;
				for (let line in cFailedBuild.Split('\n'))
					onLine(line);
				return .Ok(1);
			}, cFakeBeefBuild);
		Test.Assert(service.Run(job) case .Err(.Internal));
		Test.Assert(runs == 1, "the player is not built after the editor failed");
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
		let bed = scope ProjectBuildTests.Bed();
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

	/// A cancel while BeefBuild runs reaches the runner's check; the job ends Cancelled, and no
	/// later run starts. So does a cancel of the task's token, and one before the job runs, which
	/// never starts BeefBuild.
	[Test]
	public static void ACancelEndsTheJobCancelled()
	{
		let bed = scope ProjectBuildTests.Bed();
		{
			int runs = 0;
			let job = MakeJob(bed, .All);
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
			let job = MakeJob(bed, .All);
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
		let bed = scope ProjectBuildTests.Bed();
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

	/// A build is refused without an SDK and for a project with no package of its own, before
	/// anything runs or is written.
	[Test]
	public static void ABuildNeedsAnSdkAndAPackage()
	{
		let bed = scope ProjectBuildTests.Bed();
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
			let job = new BuildJob(.All, bed.ProjectDir, bed.ProjectDir, settings);
			defer job.ReleaseRef();
			Test.Assert(service.Run(job) case .Err(.NotSupported));
			Test.Assert(job.GetError(.. scope .()).Contains("needs the engine SDK: set SEDULOUS_SDK, or run from an engine checkout"));
		}
		ClearAndDeleteItems!(bed.Settings.Plugins);
		Test.Assert(!ProjectBuild.HasPackages(bed.Settings));
		let job = MakeJob(bed, .All);
		defer job.ReleaseRef();
		Test.Assert(service.Run(job) case .Err(.NotFound));
		Test.Assert(job.GetError(.. scope .()).Contains("no package of its own"));
		Test.Assert(job.State == .Failed);
		Test.Assert(!FileExists(PathJoin(bed.ProjectDir, "Code/BeefSpace.toml", .. scope .())), "nothing generated");
	}

	/// The editor is stale when it is not built, or older than a file of the project's packages;
	/// what builds write does not count.
	[Test]
	public static void TheEditorIsStaleWhenOlderThanAPackageFile()
	{
		let bed = scope ProjectBuildTests.Bed();
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "not built");
		System.Threading.Thread.Sleep(50);
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		ProjectBuildTests.Bed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
		System.Threading.Thread.Sleep(50);
		bed.WriteCode(".generated/NativeGameEditor/src/Program.bf", "// generated\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "what builds write is not the game's");
		bed.WriteCode("NativeGame/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
	}
}
