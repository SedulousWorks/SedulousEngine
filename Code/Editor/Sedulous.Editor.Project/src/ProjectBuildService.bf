using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// What a build makes.
enum BuildTarget
{
	/// The project's editor alone, in Debug: all a change to the game's code needs before the
	/// editor opens on it again.
	case Editor;
	/// Build Project: the editor in Debug, then the player in each config PlayerConfigs names.
	case All;
	/// The player alone, in the job's config.
	case Player;
}

enum BuildJobState
{
	Queued,
	/// Finding the SDK and BeefBuild, and writing the workspace.
	Generating,
	/// BeefBuild runs: BuildJob.GetStep says over which project and config.
	Building,
	Succeeded,
	Failed,
	Cancelled
}

/// Runs BeefBuild once: `onLine` with each line of its output as it comes, `cancelled` asked
/// while it runs. Its exit code, Cancelled once `cancelled` said so, or another error when it
/// could not be started. Process.RunStreaming is the one the editor uses; tests give their own.
typealias BuildRunner = delegate Result<int, ErrorCode>(StringView executable, Span<StringView> arguments,
	delegate void(StringView line) onLine, delegate bool() cancelled);

/// One build of a project: what it builds, and as it runs, where it is, what BeefBuild has said
/// and what it made. The build lane writes it (ProjectBuildService.Run); any thread reads it.
///
/// What the lane writes is guarded by one Monitor, entered for each write and each read, as the
/// cook service guards its queue and a task its progress; a read copies out what it returns, so
/// nothing a reader holds changes under it.
class BuildJob : RefCounted
{
	/// How many of BeefBuild's last lines a job keeps.
	public const int cOutputLines = 2000;

	// Fixed when the job is made.
	private BuildTarget mTarget;
	private String mProjectDir = new .() ~ delete _;
	private String mDataRoot = new .() ~ delete _;
	private ProjectSettings mSettings ~ delete _;
	/// Each BeefBuild run, in order: the editor's or the player's, in that config.
	private List<bool> mStepEditors = new .() ~ delete _;
	private List<String> mStepConfigs = new .() ~ DeleteContainerAndItems!(_);

	// Written by the build lane under mLock.
	private Monitor mLock = new .() ~ delete _;
	private BuildJobState mState = .Queued;
	private String mProject = new .() ~ delete _;
	private String mConfig = new .() ~ delete _;
	/// Unix seconds, 0 until it starts or ends.
	private int64 mStartTime;
	private int64 mEndTime;
	/// The same on the stopwatch, in microseconds, for its duration.
	private int64 mStartMicros;
	private int64 mEndMicros;
	private BuildDiagnostics mDiagnostics = new .() ~ delete _;
	/// The last cOutputLines lines, their progress bar taken off, blank ones left out.
	private List<String> mOutput = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mExecutables = new .() ~ DeleteContainerAndItems!(_);
	private String mError = new .() ~ delete _;
	private volatile bool mCancelRequested;

	/// A job of `target` for the project in `projectDir`, the editor's data root `dataRoot` (to
	/// find the SDK). It TAKES OWNERSHIP of `settings`, which is its own copy: the project's
	/// change on the main thread while it runs. `presets` is read here for the configs All
	/// builds the player in (none: Debug alone); `config` is the one Player builds it in.
	public this(BuildTarget target, StringView projectDir, StringView dataRoot, ProjectSettings settings, ExportPresetSet presets = null,
		StringView config = default)
	{
		mTarget = target;
		mProjectDir.Set(projectDir);
		mDataRoot.Set(dataRoot);
		mSettings = settings;
		switch (target)
		{
		case .Editor:
			AddStep(true, "Debug");
		case .All:
			AddStep(true, "Debug");
			let configs = scope List<String>();
			defer { ClearAndDeleteItems!(configs); }
			let none = scope ExportPresetSet();
			ProjectBuild.PlayerConfigs(presets ?? none, configs);
			for (let playerConfig in configs)
				AddStep(false, playerConfig);
		case .Player:
			AddStep(false, config.IsEmpty ? "Debug" : config);
		}
	}

	private void AddStep(bool editor, StringView config)
	{
		mStepEditors.Add(editor);
		mStepConfigs.Add(new .(config));
	}

	/// The service's number for it, from 1, given when it is first tracked (main thread, before
	/// it runs); 0 before.
	private int mId;

	public int Id => mId;
	public BuildTarget Target => mTarget;
	public StringView ProjectDirectory => mProjectDir;
	public StringView DataRoot => mDataRoot;
	public ProjectSettings Settings => mSettings;
	public int StepCount => mStepEditors.Count;
	public bool StepIsEditor(int step) => mStepEditors[step];
	public StringView StepConfig(int step) => mStepConfigs[step];

	public BuildJobState State
	{
		get
		{
			using (mLock.Enter())
				return mState;
		}
	}

	/// Whether it has ended, built or not.
	public bool IsEnded
	{
		get
		{
			let state = State;
			return (state == .Succeeded) || (state == .Failed) || (state == .Cancelled);
		}
	}

	/// When it started and ended, Unix seconds; 0 until it has.
	public int64 StartTime
	{
		get
		{
			using (mLock.Enter())
				return mStartTime;
		}
	}

	public int64 EndTime
	{
		get
		{
			using (mLock.Enter())
				return mEndTime;
		}
	}

	/// How long it has run, in milliseconds: to its end once it has ended, to now while it runs;
	/// 0 before it starts.
	public int64 DurationMs
	{
		get
		{
			using (mLock.Enter())
			{
				if (mStartMicros == 0)
					return 0;
				let end = (mEndMicros != 0) ? mEndMicros : System.Diagnostics.Stopwatch.GetTimestamp();
				return (end - mStartMicros) / 1000;
			}
		}
	}

	/// The project and config BeefBuild builds now, or built last; empty before the first run.
	public void GetStep(String outProject, String outConfig)
	{
		using (mLock.Enter())
		{
			outProject.Set(mProject);
			outConfig.Set(mConfig);
		}
	}

	public int ErrorCount
	{
		get
		{
			using (mLock.Enter())
				return mDiagnostics.ErrorCount;
		}
	}

	public int WarningCount
	{
		get
		{
			using (mLock.Enter())
				return mDiagnostics.WarningCount;
		}
	}

	/// Copies of the diagnostics so far into `outDiagnostics` (the caller's, and so are they).
	public void GetDiagnostics(List<BuildDiagnostic> outDiagnostics)
	{
		using (mLock.Enter())
		{
			for (let item in mDiagnostics.Items)
			{
				let copy = new BuildDiagnostic();
				item.CopyTo(copy);
				outDiagnostics.Add(copy);
			}
		}
	}

	/// The last `count` lines of BeefBuild's output (all it keeps for none), oldest first, into
	/// `outLines` (the caller's).
	public void GetOutput(List<String> outLines, int count = int.MaxValue)
	{
		using (mLock.Enter())
		{
			for (int i = Math.Max(0, mOutput.Count - count); i < mOutput.Count; i++)
				outLines.Add(new .(mOutput[i]));
		}
	}

	/// The executables it made, once it has succeeded, into `outPaths` (the caller's).
	public void GetExecutables(List<String> outPaths)
	{
		using (mLock.Enter())
		{
			for (let path in mExecutables)
				outPaths.Add(new .(path));
		}
	}

	/// Why it failed; empty unless it has.
	public void GetError(String outError)
	{
		using (mLock.Enter())
			outError.Set(mError);
	}

	/// Tells it to stop, from any thread: one not started never runs BeefBuild, and a running
	/// BeefBuild is killed with what it started. It ends Cancelled.
	public void Cancel()
	{
		mCancelRequested = true;
	}

	public bool CancelRequested => mCancelRequested;

	/// What runs it was dropped before it ran (its task cancelled while queued): it ends
	/// Cancelled, unless it has ended already.
	public void Dropped()
	{
		using (mLock.Enter())
		{
			if ((mState == .Succeeded) || (mState == .Failed) || (mState == .Cancelled))
				return;
			mState = .Cancelled;
			mError.Set("cancelled");
			mEndTime = GetUnixTime();
			mEndMicros = System.Diagnostics.Stopwatch.GetTimestamp();
		}
	}

	// ---- the build lane's -------------------------------------------------------------------

	private void Begin()
	{
		using (mLock.Enter())
		{
			mState = .Generating;
			mStartTime = GetUnixTime();
			mStartMicros = System.Diagnostics.Stopwatch.GetTimestamp();
		}
	}

	private void BeginStep(StringView project, StringView config)
	{
		using (mLock.Enter())
		{
			mState = .Building;
			mProject.Set(project);
			mConfig.Set(config);
		}
	}

	/// One line of BeefBuild's output: read for diagnostics, and kept when it says anything.
	private void AddLine(StringView line)
	{
		using (mLock.Enter())
		{
			mDiagnostics.Feed(line);
			let shown = BuildDiagnostics.StripProgress(line);
			if (shown.IsWhiteSpace)
				return;
			if (mOutput.Count >= cOutputLines)
			{
				delete mOutput[0];
				mOutput.RemoveAt(0);
			}
			mOutput.Add(new .(shown));
		}
	}

	/// A BeefBuild run has ended: the diagnostic it printed last is complete.
	private void EndRun()
	{
		using (mLock.Enter())
			mDiagnostics.Finish();
	}

	/// The error diagnostics from `first` on, each "file:line:column: message", into `outLines`.
	private void DescribeErrors(int first, List<String> outLines)
	{
		using (mLock.Enter())
		{
			for (int i = first; i < mDiagnostics.Items.Count; i++)
			{
				let item = mDiagnostics.Items[i];
				if (item.Severity == .Error)
					outLines.Add(item.Describe(.. new .()));
			}
		}
	}

	private int DiagnosticCount
	{
		get
		{
			using (mLock.Enter())
				return mDiagnostics.Items.Count;
		}
	}

	private void AddExecutable(StringView path)
	{
		using (mLock.Enter())
			mExecutables.Add(new .(path));
	}

	private void End(BuildJobState state, StringView error)
	{
		using (mLock.Enter())
		{
			mState = state;
			mError.Set(error);
			mEndTime = GetUnixTime();
			mEndMicros = System.Diagnostics.Stopwatch.GetTimestamp();
		}
	}
}

/// Builds a project's own executables (ProjectBuild) with BeefBuild, one job at a time on the
/// caller's thread (the editor's build lane), each job's progress readable from any thread as
/// it runs: BeefBuild's lines as they come, the diagnostics read from them, which project it is
/// on, and Cancel. The editor keeps one; Build Project and the MCP tools run their jobs through it.
///
/// Each job is logged as Build Project always was: each run's lines under "Build Project: ", and
/// the end "Build Project: built" (someone reading the log, or a caller over MCP polling it, has
/// nothing else to tell a running build from a finished one); a failure logs each error as
/// "file:line:column: message".
class ProjectBuildService
{
	private BuildRunner mRunner ~ delete _;
	/// When set, the BeefBuild every job runs, found by nothing (tests).
	private String mBeefBuild = new .() ~ delete _;
	/// Guards mLatest, which the main thread sets and any thread reads.
	private Monitor mLock = new .() ~ delete _;
	/// The job last handed to Track or Run, one reference of ours.
	private BuildJob mLatest;
	/// The next job's Id.
	private int mNextId = 1;

	/// `runner` runs BeefBuild (TAKES OWNERSHIP; null: Process.RunStreaming); `beefBuild`, when
	/// given, is the BeefBuild every job runs, without FindBeefBuild.
	public this(BuildRunner runner = null, StringView beefBuild = default)
	{
		mRunner = runner;
		if (mRunner == null)
			mRunner = new (executable, arguments, onLine, cancelled) => Process.RunStreaming(executable, arguments, onLine, cancelled);
		mBeefBuild.Set(beefBuild);
	}

	public ~this()
	{
		if (mLatest != null)
			mLatest.ReleaseRef();
	}

	/// Makes `job` the latest, the one status reads see, before it runs (when it is queued), and
	/// numbers it when it has no Id yet.
	public void Track(BuildJob job)
	{
		job.AddRef();
		using (mLock.Enter())
		{
			if (job.[Friend]mId == 0)
				job.[Friend]mId = mNextId++;
			if (mLatest != null)
				mLatest.ReleaseRef();
			mLatest = job;
		}
	}

	/// The job last tracked or run, with a reference taken for the caller (ReleaseRef when done
	/// with it); null before the first. From any thread.
	public BuildJob GetLatest()
	{
		using (mLock.Enter())
		{
			if (mLatest != null)
				mLatest.AddRef();
			return mLatest;
		}
	}

	/// Runs `job` to its end on this thread: blocking, for the build lane. Refused, with why in
	/// the job's error, without an engine SDK (ProjectBuild.FindSdk), for a project with no
	/// package of its own, without BeefBuild (FindBeefBuild), at the first run that fails, or
	/// when a run said it built and an executable is not there. Cancelled once the job is, or
	/// `outer` is (the build lane's task, which the editor cancels when it closes the project).
	public Result<void, ErrorCode> Run(BuildJob job, CancelToken outer = null)
	{
		bool latest;
		using (mLock.Enter())
			latest = mLatest === job;
		if (!latest)
			Track(job);
		job.[Friend]Begin();
		let error = scope String();
		let result = Execute(job, outer, error);
		switch (result)
		{
		case .Ok:
			job.[Friend]End(.Succeeded, "");
			GlobalLog(.Information, "Build Project: built - Project > Open With This Build runs it");
		case .Err(.Cancelled):
			job.[Friend]End(.Cancelled, "cancelled");
			GlobalLog(.Information, "Build Project: cancelled");
		case .Err:
			job.[Friend]End(.Failed, error);
		}
		return result;
	}

	private Result<void, ErrorCode> Execute(BuildJob job, CancelToken outer, String outError)
	{
		let projectDir = job.ProjectDirectory;
		let settings = job.Settings;
		let sdk = scope String();
		if (!ProjectBuild.FindSdk(job.DataRoot, sdk))
		{
			outError.Set(scope $"a project's build needs the engine SDK: set {ProjectBuild.cSdkVariable}, or run from an engine checkout");
			return .Err(.NotSupported);
		}
		if (!ProjectBuild.HasPackages(settings))
		{
			outError.Set("the project has no package of its own (Add Native Code makes one)");
			return .Err(.NotFound);
		}
		let beefBuild = scope String(mBeefBuild);
		if (beefBuild.IsEmpty && !ProjectBuild.FindBeefBuild(beefBuild, outError))
			return .Err(.NotFound);
		if (Cancelled(job, outer))
			return .Err(.Cancelled);
		if (ProjectBuild.Generate(projectDir, settings, sdk, outError) case .Err(let err))
			return .Err(err);

		let game = ProjectBuild.GameName(settings.Name, .. scope .());
		let workspace = ProjectBuild.Directory(projectDir, .. scope .());
		GlobalLog(.Information, "Build Project: generated the workspace in '{}' over the SDK at '{}' (the first build compiles the engine too)", workspace, sdk);
		for (int step < job.StepCount)
		{
			if (Cancelled(job, outer))
				return .Err(.Cancelled);
			let entry = job.StepIsEditor(step) ? BuildEntry.Editor : BuildEntry.Player;
			let project = ProjectBuild.EntryName(game, entry, .. scope .());
			if (RunStep(job, outer, beefBuild, workspace, project, job.StepConfig(step), outError) case .Err(let stepErr))
				return .Err(stepErr);
		}
		// BeefBuild's exit alone is not the word on it: a run can end well with nothing built
		// (a project it did not find), so the executables themselves are checked.
		for (int step < job.StepCount)
		{
			let path = ProjectBuild.ExecutablePath(projectDir, game, job.StepIsEditor(step), job.StepConfig(step), .. scope .());
			if (!FileExists(path))
			{
				outError.Set(scope $"BeefBuild ended without building '{path}'");
				return .Err(.NotFound);
			}
			job.[Friend]AddExecutable(path);
		}
		return .Ok;
	}

	/// One BeefBuild run over the workspace, each line into the job and the log as it comes.
	private Result<void, ErrorCode> RunStep(BuildJob job, CancelToken outer, StringView beefBuild, StringView workspace, StringView project,
		StringView config, String outError)
	{
		job.[Friend]BeginStep(project, config);
		GlobalLog(.Information, "Build Project: {} ({})", project, config);
		let workspaceArg = scope $"-workspace={workspace}";
		let configArg = scope $"-config={config}";
		let platformArg = scope $"-platform={BuildLayout.HostPlatformName}";
		let projectArg = scope $"-project={project}";
		let firstDiagnostic = job.[Friend]DiagnosticCount;
		let result = mRunner(beefBuild, scope StringView[](workspaceArg, configArg, platformArg, projectArg),
			scope (line) =>
			{
				job.[Friend]AddLine(line);
				let shown = BuildDiagnostics.StripProgress(line);
				if (!shown.IsWhiteSpace)
					GlobalLog(.Information, "Build Project: {}", shown);
			},
			scope () => Cancelled(job, outer));
		job.[Friend]EndRun();

		int exitCode = 0;
		switch (result)
		{
		case .Ok(let code):
			exitCode = code;
		case .Err(let err):
			if (err == .Cancelled)
				return .Err(.Cancelled);
			outError.Set(scope $"BeefBuild could not be started from '{beefBuild}'");
			return .Err(.Internal);
		}
		if (exitCode == 0)
			return .Ok;

		let errors = scope List<String>();
		defer { ClearAndDeleteItems!(errors); }
		job.[Friend]DescribeErrors(firstDiagnostic, errors);
		for (let line in errors)
			GlobalLog(.Error, "{}", line);
		outError.Set(scope $"BeefBuild failed building {project} ({config}), exit {exitCode}");
		if (!errors.IsEmpty)
		{
			outError.AppendF(", {} error{}", errors.Count, (errors.Count == 1) ? "" : "s");
			return .Err(.Internal);
		}
		// Nothing read as an error (a crash, a message of a form not known here): the end of what
		// it printed says the most.
		let tail = scope List<String>();
		defer { ClearAndDeleteItems!(tail); }
		job.GetOutput(tail, cFailureTail);
		outError.Append(", and no error it printed was read; its output ended:");
		for (let line in tail)
			outError.AppendF("\n{}", line);
		return .Err(.Internal);
	}

	/// How many of BeefBuild's last lines a failure with no error read quotes.
	private const int cFailureTail = 10;

	private static bool Cancelled(BuildJob job, CancelToken outer) => job.CancelRequested || CancelToken.Requested(outer);
}
