using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// What the build tools work through: the editor's build service and the application's paths
/// to start a build, to see what is unsaved, to start another editor and to exit this one.
class BuildToolSeams
{
	/// BORROWED: the editor's build service, whose latest job the tools read.
	public ProjectBuildService Service = null;
	/// The engine data root this editor runs from, which the relaunched editor is given.
	public String DataRoot = new .() ~ delete _;
	/// Starts a build of the open project on the build lane (EditorBuildTools.StartBuild): the
	/// job with a reference for the caller, or null with why in `outError`. Owned.
	public delegate BuildJob(BuildTarget target, String outError) Start ~ delete _;
	/// The open project; null with none. Owned.
	public delegate EditorProject() Project ~ delete _;
	/// What has unsaved changes, a line each as the exit prompt names it (the caller's). Owned.
	public delegate void(List<String> outLines) UnsavedWork ~ delete _;
	/// The port this editor's MCP host listens on, which the relaunched editor serves. Owned.
	public delegate uint16() McpPort ~ delete _;
	/// Starts an executable without waiting; false when it could not be started. Owned.
	public delegate bool(StringView executable, Span<StringView> arguments) Launch ~ delete _;
	/// Exits this editor without asking about unsaved work. Owned.
	public delegate void() Exit ~ delete _;
}

/// The MCP tools over the project's own build, what only the editor host can serve: building
/// and relaunching need the editor. project_build runs a build on the build lane through the
/// editor's build service (the same path as Build Project) and, waiting, answers once it ends
/// with what BeefBuild said as diagnostics; build_status reads the latest build while it runs
/// or after; build_cancel stops it; editor_relaunch opens the project in its own built editor on
/// this host's port and quits this one, as Open With This Build does.
///
/// A waiting project_build keeps its call open by answering NotFinished: the host re-enters it
/// each frame on the main thread, so the editor draws and answers other calls while BeefBuild
/// runs on the build lane.
static class EditorBuildTools
{
	/// How many tools Register registers; a tripwire like EditorPageTools.cPageToolCount.
	public const int cBuildToolCount = 4;
	/// How long a waiting project_build holds its call by default, and at most, in seconds: a
	/// first build compiles the engine too.
	public const double cDefaultTimeoutSeconds = 900;
	public const double cMaxTimeoutSeconds = 3600;
	/// How many diagnostics a result lists, errors first; the counts say how many there are.
	public const int cMaxDiagnostics = 50;
	/// How many of BeefBuild's last lines build_status gives by default, and at most.
	public const int cDefaultTail = 40;
	public const int cMaxTail = 400;
	/// The config the project's own editor is built in (BuildTarget.Editor's).
	public const String cEditorConfig = "Debug";

	/// One waiting project_build: the job it started, and when it started waiting.
	private class BuildWait
	{
		public BuildJob Job ~ _?.ReleaseRef();
		public int64 StartedMicros = System.Diagnostics.Stopwatch.GetTimestamp();
		public double TimeoutSeconds;
	}

	/// Starts a build of `project` for `target` on the context's build lane through `service`:
	/// Build Project's path and project_build's. The job is tracked as the service's latest and
	/// returned with a reference for the caller (ReleaseRef it); null, with why in `outError`,
	/// when the build lane is busy or the project's settings did not copy. Its end is said as
	/// Build Project's always was: a failure notified with its error, a success on the status
	/// line.
	public static BuildJob StartBuild(EditorContext context, ProjectBuildService service, EditorProject project, StringView dataRoot,
		BuildTarget target, String outError)
	{
		if (context.Tasks.IsLaneBusy(context.BuildLane))
		{
			let running = context.Tasks.RunningIn(context.BuildLane);
			outError.AppendF("the build lane is busy ({}): build once it is done", (running != null) ? running.Name : "work queued");
			return null;
		}
		// The job's own copy: the session's settings change on the main thread meanwhile.
		let settings = new Sedulous.Engine.Project.ProjectSettings();
		if (Sedulous.Engine.Project.ProjectManifest.Copy(project.Settings, settings) case .Err)
		{
			delete settings;
			outError.Append("the project's settings did not copy");
			return null;
		}
		// The presets are read now, for the configs All builds the player in; the editor alone
		// needs none.
		let presets = scope ExportPresetSet();
		if (target == .All)
		{
			let projectFs = scope Sedulous.VFS.NativeFileSystem(project.Directory);
			if (ExportPresetsFile.Load(projectFs, presets) case .Err)
				ExportPresetsFile.Defaults(presets);
		}
		let job = new BuildJob(target, project.Directory, dataRoot, settings, presets);
		service.Track(job);
		let label = (target == .All) ? "Build Project" : "Build Editor";
		// The work and the completion each hold a reference: the completion reads the job's error
		// after the work has gone. Work dropped unrun (the project closed first) ends the job.
		job.AddRef();
		job.AddRef();
		context.Tasks.Submit(label,
			new [=job, =service](task) =>
			{
				task.SetStep("BeefBuild");
				return service.Run(job, task.Token);
			} ~ { job.Dropped(); job.ReleaseRef(); },
			new [=job, =context, =label](result) => // main thread
			{
				if (result case .Err)
				{
					let error = job.GetError(.. scope .());
					GlobalLog(.Error, "{}: {}", label, error);
					context.Notify(.Error, scope $"{label} failed: {error}");
					return;
				}
				context.SetStatus(scope $"{label} done: Project > Open With This Build runs it.");
			} ~ job.ReleaseRef(), context.BuildLane);
		return job;
	}

	/// The command line that opens `projectDir` in another editor as this one runs: the project
	/// and the data root, and with `mcp` the MCP host on `mcpPort` (0: the preference's), so an
	/// agent connected to this editor finds the next one on the same port. The token needs no
	/// argument: the next editor reads it from the same user data directory. Into `outArguments`
	/// (the caller's, and so are the strings).
	public static void RelaunchArguments(StringView projectDir, StringView dataRoot, bool mcp, uint32 mcpPort, List<String> outArguments)
	{
		outArguments.Add(new .("--project"));
		outArguments.Add(new .(projectDir));
		outArguments.Add(new .("--data-root"));
		outArguments.Add(new .(dataRoot));
		if (!mcp)
			return;
		outArguments.Add(new .("--mcp"));
		if (mcpPort != 0)
		{
			outArguments.Add(new .("--mcp-port"));
			outArguments.Add(new $"{mcpPort}");
		}
	}

	/// When this process's executable was written (FileStat's ticks; 0 unknown), read once: a
	/// build replaces the file the project's editor runs from, not the editor running, so the time
	/// is the one it started with. The editor notes it as it starts (NoteRunningExecutable).
	private static int64 sRunningTime = -1;

	/// Reads the running executable's time, kept for RunningExecutableTime.
	public static void NoteRunningExecutable()
	{
		sRunningTime = ProjectBuild.FileTime(Environment.GetExecutableFilePath(.. scope .()));
	}

	/// When this process's executable was written, as it started (NoteRunningExecutable; read
	/// now when it was not noted).
	public static int64 RunningExecutableTime
	{
		get
		{
			if (sRunningTime < 0)
				NoteRunningExecutable();
			return sRunningTime;
		}
	}

	/// host_info's word on the project's code, when the project has a package of its own:
	/// `buildStale`, whether its own editor is missing or older than the code (build), and
	/// `runningStale`, whether this editor does not link the project's packages (its plugin host,
	/// `plugins`, has them missing) or is older than the code or than the built editor (relaunch).
	/// Nothing for no project, or one with no package of its own.
	public static void ReportBuild(EditorProject project, Sedulous.Runtime.PluginHost plugins, JsonValue outState)
	{
		if ((project == null) || !ProjectBuild.HasPackages(project.Settings))
			return;
		let state = ProjectBuild.Staleness(project.Directory, project.Settings, cEditorConfig, RunningExecutableTime,
			ProjectBuild.LinksPackages(project.Settings, plugins));
		outState.Set("buildStale", JsonValue.MakeBool(state.BuildStale));
		outState.Set("runningStale", JsonValue.MakeBool(state.RunningStale));
	}

	/// OWNERSHIP of the seams transfers; the first tool holds them for all four.
	public static void Register(McpServer server, BuildToolSeams seams)
	{
		let buildSchema = scope SchemaBuilder();
		buildSchema.Enum("target", scope StringView[]("editor", "all"),
			"editor (default): the project's own editor alone, in Debug, all a change to the game's code needs before editor_relaunch; all: Build Project, the editor and then the player in each config the export presets name");
		buildSchema.Boolean("wait", "hold the call until the build ends (default true); false answers at once with the build's id and state");
		buildSchema.Number("timeoutSeconds", "with wait, how long to hold the call (default 900, at most 3600); past it the call answers with the running state and the build goes on");
		server.RegisterTool("project_build",
			"Build the project's own code with BeefBuild on the editor's build lane, the same path as Project > Build Project. REFUSED while a build runs (build_status follows it, build_cancel stops it) or the build lane is busy. Waiting (the default), it answers when the build ends: {id, target, state (succeeded / failed / cancelled), steps (each BeefBuild run: project, config), step (the run last on), error, durationMs, errorCount, warningCount, diagnostics (errors first, at most 50: severity, file (relative to the project when inside it), line, column, code, message, notes), diagnosticsOmitted, executables}. A failed build is still an answer, not a tool error: read `state` and the diagnostics, fix the code, build again. On the timeout it answers with the running state and `timedOut`, and the build goes on. The first build compiles the engine too and takes minutes.",
			buildSchema.Build(), .Rebuilds,
			new (call, arguments, outResult, outError) => Build(seams, call, arguments, outResult, outError), seams);

		let statusSchema = scope SchemaBuilder();
		statusSchema.Integer("tail", "how many of BeefBuild's last output lines to give (default 40, at most 400)");
		server.RegisterTool("build_status",
			"The latest build, running or ended: {building, last, stale}. `last` is null before any build, else the build as project_build answers it plus `output`, BeefBuild's last `tail` lines. `stale` says whether the project's own editor is missing or older than the game's code (null for a project with no package of its own, which the stock editor runs).",
			statusSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let project = (seams.Project != null) ? seams.Project() : null;
				let tail = Math.Clamp((int)McpTools.ArgNumber(arguments, "tail", cDefaultTail), 0, cMaxTail);
				let latest = seams.Service.GetLatest();
				if (latest == null)
				{
					outResult.Set("building", JsonValue.MakeBool(false));
					outResult.Set("last", JsonValue.MakeNull());
				}
				else
				{
					defer latest.ReleaseRef();
					let last = JsonValue.MakeObject();
					JobJson(latest, last);
					let lines = scope List<String>();
					defer { ClearAndDeleteItems!(lines); }
					latest.GetOutput(lines, tail);
					let output = JsonValue.MakeArray();
					for (let line in lines)
						output.Add(JsonValue.MakeString(line));
					last.Set("output", output);
					outResult.Set("building", JsonValue.MakeBool(!latest.IsEnded));
					outResult.Set("last", last);
				}
				if ((project != null) && ProjectBuild.HasPackages(project.Settings))
					outResult.Set("stale", JsonValue.MakeBool(ProjectBuild.IsStale(project.Directory, project.Settings, cEditorConfig)));
				else
					outResult.Set("stale", JsonValue.MakeNull());
				return true;
			});

		let cancelSchema = scope SchemaBuilder();
		server.RegisterTool("build_cancel",
			"Cancel the running build: BeefBuild is killed with what it started, and the build ends cancelled (build_status shows it). REFUSED when no build runs. Returns {cancelled, id}.",
			cancelSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let latest = seams.Service.GetLatest();
				if (latest == null)
				{
					outError.Append("no build is running");
					return false;
				}
				defer latest.ReleaseRef();
				if (latest.IsEnded)
				{
					outError.AppendF("no build is running (build {} has ended {})", latest.Id, StateName(latest.State));
					return false;
				}
				latest.Cancel();
				outResult.Set("cancelled", JsonValue.MakeBool(true));
				outResult.Set("id", JsonValue.MakeNumber(latest.Id));
				return true;
			});

		let relaunchSchema = scope SchemaBuilder();
		relaunchSchema.Boolean("discardUnsaved", "exit even when pages have unsaved changes, dropping them (default false: refused, naming them)");
		server.RegisterTool("editor_relaunch",
			"Open the project in its own built editor (Project > Open With This Build) and quit this one: the editor that runs the game's code. REFUSED for a project with no package of its own, while a build runs, when the project's editor is not built or is older than the game's code (project_build first), and while pages have unsaved changes (they are named; save each with page_open then action_execute file.save, or pass discardUnsaved). The new editor serves MCP on this host's port with the same token; it takes a few seconds to listen. Reconnect then, and host_info: a new pid and buildStamp, `host.buildStale` and `host.runningStale` false. Returns {relaunched, executable, port}.",
			relaunchSchema.Build(), .(false, true, false, false),
			new (arguments, outResult, outError) => Relaunch(seams, arguments, outResult, outError));
	}

	private static ToolOutcome Build(BuildToolSeams seams, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
	{
		var wait = call.State as BuildWait;
		if (wait == null)
		{
			let project = (seams.Project != null) ? seams.Project() : null;
			if (project == null)
			{
				outError.Append(McpTools.cNoProject);
				return .Failed;
			}
			let targetName = McpTools.ArgString(arguments, "target", .. scope .());
			BuildTarget target = .Editor;
			if (targetName == "all")
				target = .All;
			else if (!targetName.IsEmpty && (targetName != "editor"))
			{
				outError.AppendF("no target '{}' (editor or all)", targetName);
				return .Failed;
			}
			if (Running(seams.Service, outError))
				return .Failed;
			let job = seams.Start(target, outError);
			if (job == null)
				return .Failed;
			if (!McpTools.ArgBool(arguments, "wait", true))
			{
				defer job.ReleaseRef();
				outResult.Set("id", JsonValue.MakeNumber(job.Id));
				outResult.Set("target", JsonValue.MakeString(TargetName(job.Target)));
				outResult.Set("state", JsonValue.MakeString(StateName(job.State)));
				outResult.Set("note", JsonValue.MakeString("build_status follows it; build_cancel stops it"));
				return .Answered;
			}
			wait = new BuildWait();
			wait.Job = job; // the reference Start gave
			wait.TimeoutSeconds = Math.Clamp(McpTools.ArgNumber(arguments, "timeoutSeconds", cDefaultTimeoutSeconds), 1.0, cMaxTimeoutSeconds);
			call.State = wait;
			return .NotFinished;
		}
		let ended = wait.Job.IsEnded;
		let waited = (double)(System.Diagnostics.Stopwatch.GetTimestamp() - wait.StartedMicros) / 1000000.0;
		if (!ended && (waited < wait.TimeoutSeconds))
			return .NotFinished;
		JobJson(wait.Job, outResult);
		if (!ended)
		{
			outResult.Set("timedOut", JsonValue.MakeBool(true));
			outResult.Set("note", JsonValue.MakeString("the build goes on: build_status follows it, build_cancel stops it"));
		}
		return .Answered;
	}

	private static bool Relaunch(BuildToolSeams seams, JsonValue arguments, JsonValue outResult, String outError)
	{
		let project = (seams.Project != null) ? seams.Project() : null;
		if (project == null)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		if (!ProjectBuild.HasPackages(project.Settings))
		{
			outError.Append("the project has no package of its own, so the stock editor runs it and there is no editor of its own to open (Add Native Code makes one)");
			return false;
		}
		if (Running(seams.Service, outError))
			return false;
		let game = ProjectBuild.GameName(project.Settings.Name, .. scope .());
		let editor = ProjectBuild.ExecutablePath(project.Directory, game, true, cEditorConfig, .. scope .());
		if (!FileExists(editor))
		{
			outError.AppendF("the project's own editor is not built ('{}'): project_build first", editor);
			return false;
		}
		if (ProjectBuild.IsStale(project.Directory, project.Settings, cEditorConfig))
		{
			outError.AppendF("the project's own editor ('{}') is older than the game's code: project_build first", editor);
			return false;
		}
		let unsaved = scope List<String>();
		defer { ClearAndDeleteItems!(unsaved); }
		if (seams.UnsavedWork != null)
			seams.UnsavedWork(unsaved);
		let discard = McpTools.ArgBool(arguments, "discardUnsaved");
		if (!unsaved.IsEmpty && !discard)
		{
			outError.Append("these have unsaved changes:");
			for (int i < unsaved.Count)
				outError.AppendF("{} {}", (i == 0) ? "" : ";", unsaved[i]);
			outError.Append(" - save each (page_open it, then action_execute file.save), or pass discardUnsaved: true to drop them");
			return false;
		}

		let port = (seams.McpPort != null) ? seams.McpPort() : 0;
		let commandLine = scope List<String>();
		defer { ClearAndDeleteItems!(commandLine); }
		RelaunchArguments(project.Directory, seams.DataRoot, true, port, commandLine);
		let views = scope StringView[commandLine.Count];
		for (int i < commandLine.Count)
			views[i] = commandLine[i];
		if (!seams.Launch(editor, views))
		{
			outError.AppendF("could not start '{}'", editor);
			return false;
		}
		GlobalLog(.Information, "Editor: the project opened in its own build ({}) for an agent; this editor exits", editor);
		outResult.Set("relaunched", JsonValue.MakeBool(true));
		outResult.Set("executable", JsonValue.MakeString(editor));
		outResult.Set("port", JsonValue.MakeNumber(port));
		if (!unsaved.IsEmpty)
		{
			let dropped = JsonValue.MakeArray();
			for (let line in unsaved)
				dropped.Add(JsonValue.MakeString(line));
			outResult.Set("discardedUnsaved", dropped);
		}
		outResult.Set("note", JsonValue.MakeString(scope $"this editor exits now; the new one takes a few seconds to listen on 127.0.0.1:{port}: reconnect, then host_info"));
		// The answer is written in this pump; the exit is the frame's end.
		seams.Exit();
		return true;
	}

	/// Whether a build runs, said in `outError` with what it is on and the way to follow or stop it.
	private static bool Running(ProjectBuildService service, String outError)
	{
		let latest = service.GetLatest();
		if (latest == null)
			return false;
		defer latest.ReleaseRef();
		if (latest.IsEnded)
			return false;
		outError.AppendF("build {} ({}) is running", latest.Id, TargetName(latest.Target));
		let project = scope String();
		let config = scope String();
		latest.GetStep(project, config);
		if (!project.IsEmpty)
			outError.AppendF(", on {} ({})", project, config);
		outError.Append(": build_status follows it, build_cancel stops it");
		return true;
	}

	/// `job` as the tools answer it, into `outResult`.
	private static void JobJson(BuildJob job, JsonValue outResult)
	{
		let state = job.State;
		outResult.Set("id", JsonValue.MakeNumber(job.Id));
		outResult.Set("target", JsonValue.MakeString(TargetName(job.Target)));
		outResult.Set("state", JsonValue.MakeString(StateName(state)));
		let game = ProjectBuild.GameName(job.Settings.Name, .. scope .());
		let steps = JsonValue.MakeArray();
		for (int i < job.StepCount)
			steps.Add(StepJson(ProjectBuild.EntryName(game, job.StepEntry(i), .. scope .()), job.StepConfig(i)));
		outResult.Set("steps", steps);
		let project = scope String();
		let config = scope String();
		job.GetStep(project, config);
		outResult.Set("step", project.IsEmpty ? JsonValue.MakeNull() : StepJson(project, config));
		let error = job.GetError(.. scope .());
		if (!error.IsEmpty)
			outResult.Set("error", JsonValue.MakeString(error));
		outResult.Set("durationMs", JsonValue.MakeNumber((double)job.DurationMs));
		DiagnosticsJson(job, outResult);
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		let executables = JsonValue.MakeArray();
		for (let path in made)
			executables.Add(JsonValue.MakeString(path));
		outResult.Set("executables", executables);
	}

	private static JsonValue StepJson(StringView project, StringView config)
	{
		let step = JsonValue.MakeObject();
		step.Set("project", JsonValue.MakeString(project));
		step.Set("config", JsonValue.MakeString(config));
		return step;
	}

	/// The job's counts and its diagnostics, errors first, at most cMaxDiagnostics, each file
	/// relative to the project when inside it.
	private static void DiagnosticsJson(BuildJob job, JsonValue outResult)
	{
		let diagnostics = scope List<BuildDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		job.GetDiagnostics(diagnostics);
		let projectDir = Absolute(job.ProjectDirectory, .. scope .());
		int errors = 0;
		for (let diagnostic in diagnostics)
		{
			if (diagnostic.Severity == .Error)
				errors++;
		}
		let list = JsonValue.MakeArray();
		for (let severity in BuildSeverity[2](.Error, .Warning))
		{
			for (let diagnostic in diagnostics)
			{
				if (list.Count >= cMaxDiagnostics)
					break;
				if (diagnostic.Severity == severity)
					list.Add(DiagnosticJson(diagnostic, projectDir));
			}
		}
		outResult.Set("errorCount", JsonValue.MakeNumber(errors));
		outResult.Set("warningCount", JsonValue.MakeNumber(diagnostics.Count - errors));
		outResult.Set("diagnostics", list);
		outResult.Set("diagnosticsOmitted", JsonValue.MakeNumber(diagnostics.Count - list.Count));
	}

	private static JsonValue DiagnosticJson(BuildDiagnostic diagnostic, StringView projectDir)
	{
		let json = JsonValue.MakeObject();
		json.Set("severity", JsonValue.MakeString((diagnostic.Severity == .Error) ? "error" : "warning"));
		if (diagnostic.HasPlace)
		{
			json.Set("file", JsonValue.MakeString(RelativeFile(diagnostic.File, projectDir, .. scope .())));
			json.Set("line", JsonValue.MakeNumber(diagnostic.Line));
			json.Set("column", JsonValue.MakeNumber(diagnostic.Column));
		}
		if (!diagnostic.Code.IsEmpty)
			json.Set("code", JsonValue.MakeString(diagnostic.Code));
		json.Set("message", JsonValue.MakeString(diagnostic.Message));
		if (!diagnostic.Notes.IsEmpty)
		{
			let notes = JsonValue.MakeArray();
			for (let note in diagnostic.Notes)
			{
				let noteJson = JsonValue.MakeObject();
				noteJson.Set("message", JsonValue.MakeString(note.Message));
				if (!note.File.IsEmpty)
				{
					noteJson.Set("file", JsonValue.MakeString(RelativeFile(note.File, projectDir, .. scope .())));
					noteJson.Set("line", JsonValue.MakeNumber(note.Line));
					noteJson.Set("column", JsonValue.MakeNumber(note.Column));
				}
				notes.Add(noteJson);
			}
			json.Set("notes", notes);
		}
		return json;
	}

	/// `file` relative to `projectDir` when it lies inside it, as it is otherwise (an engine
	/// file BeefBuild compiled beside the game's).
	public static void RelativeFile(StringView file, StringView projectDir, String outPath)
	{
		if (!projectDir.IsEmpty && (file.Length > projectDir.Length + 1) && file.StartsWith(projectDir) && PathIsSeparator(file[projectDir.Length]))
			outPath.Set(file.Substring(projectDir.Length + 1));
		else
			outPath.Set(file);
	}

	/// `path` against the current directory when relative, less its trailing separators: the
	/// form BeefBuild names files in.
	private static void Absolute(StringView path, String outPath)
	{
		if (path.IsEmpty || PathIsAbsolute(path))
			outPath.Set(path);
		else
			PathJoin(GetCurrentDirectory(.. scope .()), path, outPath);
		while ((outPath.Length > 1) && PathIsSeparator(outPath[outPath.Length - 1]))
			outPath.RemoveFromEnd(1);
	}

	public static StringView TargetName(BuildTarget target)
	{
		switch (target)
		{
		case .Editor: return "editor";
		case .All: return "all";
		default: return "player";
		}
	}

	public static StringView StateName(BuildJobState state)
	{
		switch (state)
		{
		case .Queued: return "queued";
		case .Generating: return "generating";
		case .Building: return "building";
		case .Succeeded: return "succeeded";
		case .Failed: return "failed";
		default: return "cancelled";
		}
	}
}
