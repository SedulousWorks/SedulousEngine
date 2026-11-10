using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// A page whose run a relaunch starts again (the Game tab's): whether it runs, or waits on the
/// cook to, and starting it again as its Play does, from the start.
interface IRelaunchRun
{
	bool RelaunchRuns { get; }
	void RunAgain();
}

/// Who asked for a relaunch.
enum RelaunchCaller
{
	/// Build and Relaunch from the menu, a shortcut or the palette.
	Person,
	/// editor_relaunch over MCP.
	Agent
}

/// What a relaunch does with pages that have unsaved changes.
enum UnsavedOnRelaunch
{
	/// The person is asked, as at an exit: save them all, go on without them, or stay.
	Ask,
	/// Each page's content is kept in the relaunch folder, never over its asset, and the next
	/// editor reopens it unsaved; a page that cannot be kept refuses the relaunch.
	KeepAside,
	/// They are dropped.
	Discard
}

static class RelaunchPolicy
{
	/// What a relaunch does with unsaved pages by who asked: a person is asked as at an exit, an
	/// agent's are kept aside (an agent cannot answer a question on the screen). The one place
	/// the default is decided.
	public static UnsavedOnRelaunch Unsaved(RelaunchCaller caller) => (caller == .Agent) ? .KeepAside : .Ask;
}

/// What a relaunch hands the next editor, beside the per-project store it reads anyway (the open
/// pages, the dock, each scene's view): the pages kept aside, the Game tabs and whether each ran,
/// the active page, and the times so far. A JSON file in the relaunch folder
/// (<project>/Editor/relaunch), which the next editor is given by --relaunch and removes once
/// everything came back.
class RelaunchState
{
	public const String cFolderName = "relaunch";
	public const String cFileName = "relaunch.json";
	/// The Game tab Play opens; the others are new instances beside it.
	public const String cPrimaryGame = "game-page";
	/// DateTime's ticks are 100 ns.
	private const double cTicksPerMs = 10000.0;

	/// A page kept aside: its asset, and its name as the prompts say it.
	public class KeptPage
	{
		public Guid Id;
		public String Title = new .() ~ delete _;
	}

	/// A Game tab: its panel id, and whether it ran (or waited on the cook to).
	public class GameTab
	{
		public String PieId = new .() ~ delete _;
		public bool Playing;
	}

	public List<KeptPage> Kept = new .() ~ DeleteContainerAndItems!(_);
	public List<GameTab> Games = new .() ~ DeleteContainerAndItems!(_);
	/// The active page's panel id (an asset's guid, a Game tab's id); empty for none.
	public String ActivePanel = new .() ~ delete _;
	/// How long the build before it took; negative when none ran.
	public double BuildMs = -1;
	/// How long saving the state took, the pages kept aside among it.
	public double SaveMs = 0;
	/// When the next editor was started (DateTime ticks, UTC): its start is timed from it.
	public int64 LaunchedTicks = 0;

	/// The relaunch folder of the project in `projectDir`, absolute, into `outFolder`.
	public static void Folder(StringView projectDir, String outFolder)
	{
		let editorDir = PathJoin(projectDir, Sedulous.Engine.Project.ProjectLayout.EditorDir, .. scope .());
		ProjectBuild.Absolute(PathJoin(editorDir, cFolderName, .. scope .()), outFolder);
	}

	/// Where a page kept aside lies in `folder`: its asset's guid, into `outPath`.
	public static void KeptFile(StringView folder, Guid id, String outPath)
	{
		let name = scope String();
		id.ToString(name, 'D');
		name.Append(".bin");
		PathJoin(folder, name, outPath);
	}

	public void Write(String outText)
	{
		let root = JsonValue.MakeObject();
		defer delete root;
		root.Set("version", JsonValue.MakeNumber(1));
		let kept = JsonValue.MakeArray();
		for (let page in Kept)
		{
			let entry = JsonValue.MakeObject();
			let id = scope String();
			page.Id.ToString(id, 'D');
			entry.Set("id", JsonValue.MakeString(id));
			entry.Set("title", JsonValue.MakeString(page.Title));
			kept.Add(entry);
		}
		root.Set("kept", kept);
		let games = JsonValue.MakeArray();
		for (let game in Games)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("id", JsonValue.MakeString(game.PieId));
			entry.Set("playing", JsonValue.MakeBool(game.Playing));
			games.Add(entry);
		}
		root.Set("games", games);
		root.Set("active", JsonValue.MakeString(ActivePanel));
		root.Set("buildMs", JsonValue.MakeNumber(BuildMs));
		root.Set("saveMs", JsonValue.MakeNumber(SaveMs));
		// As text: ticks pass what a double holds whole.
		root.Set("launchedTicks", JsonValue.MakeString(scope $"{LaunchedTicks}"));
		root.ToString(outText, true);
	}

	/// The state in `text`; null when it is not one.
	public static RelaunchState Read(StringView text)
	{
		let root = JsonValue.Parse(text);
		defer delete root;
		if ((root == null) || !root.Has("version"))
			return null;
		let state = new RelaunchState();
		if (let kept = root.Get("kept"))
		{
			for (int i < kept.Count)
			{
				let entry = kept.At(i);
				if (!(Guid.Parse(Text(entry, "id")) case .Ok(let id)))
					continue;
				let page = new KeptPage();
				page.Id = id;
				page.Title.Set(Text(entry, "title"));
				state.Kept.Add(page);
			}
		}
		if (let games = root.Get("games"))
		{
			for (int i < games.Count)
			{
				let entry = games.At(i);
				let game = new GameTab();
				game.PieId.Set(Text(entry, "id"));
				let playing = entry.Get("playing");
				game.Playing = (playing != null) && playing.AsBool();
				state.Games.Add(game);
			}
		}
		if (let active = root.Get("active"))
			state.ActivePanel.Set(active.AsString());
		if (let build = root.Get("buildMs"))
			state.BuildMs = build.AsNumber(-1);
		if (let save = root.Get("saveMs"))
			state.SaveMs = save.AsNumber();
		if (let launched = root.Get("launchedTicks"))
			state.LaunchedTicks = int64.Parse(launched.AsString()).GetValueOrDefault();
		return state;
	}

	/// The string `key` of `entry`; empty when it has none.
	private static StringView Text(JsonValue entry, StringView key)
	{
		let value = (entry != null) ? entry.Get(key) : null;
		return (value != null) ? value.AsString() : "";
	}

	/// Writes the state into `folder` (which must exist).
	public Result<void, ErrorCode> Save(StringView folder)
	{
		let text = scope String();
		Write(text);
		return WriteFileAtomic(PathJoin(folder, cFileName, .. scope .()), .((uint8*)text.Ptr, text.Length));
	}

	/// The state in `folder`; null when there is none, or it is not one.
	public static RelaunchState Load(StringView folder)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(PathJoin(folder, cFileName, .. scope .()), bytes) case .Err)
			return null;
		return Read(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// The relaunch's phases, into `outText`, for the log: the build (when one ran), the save, the
	/// start (from the launch to the next editor's application made, `createdTicks`) and the
	/// restore (from then to the pages and the Game tabs back, `restoredTicks`), and the whole.
	public void DescribeTimings(int64 createdTicks, int64 restoredTicks, String outText)
	{
		double start = 0.0;
		if (LaunchedTicks > 0)
			start = (double)(createdTicks - LaunchedTicks) / cTicksPerMs;
		let restore = (double)(restoredTicks - createdTicks) / cTicksPerMs;
		let build = Math.Max(BuildMs, 0.0);
		let buildText = scope String();
		if (BuildMs < 0)
			buildText.Append("none");
		else
			buildText.AppendF("{}", (int64)build);
		outText.AppendF("build {}, save {}, start {}, restore {}, total {} (ms)", buildText, (int64)SaveMs, (int64)start, (int64)restore,
			(int64)(build + SaveMs + start + restore));
	}
}

/// What a relaunch came to.
enum RelaunchOutcome
{
	/// Refused, nothing changed: why is in the error.
	Refused,
	/// A person is asked about unsaved pages; it goes on when they answer.
	Asking,
	/// The next editor started and this one exits.
	Relaunched
}

/// The fast relaunch: the project's own editor started on the project with what this one shows
/// (the open pages and the active one, each scene's view, the pages kept aside, the Game tabs and
/// whether each ran), and this editor exits. Both Build and Relaunch (BuildAndRelaunch) and
/// editor_relaunch come here once the editor is built; the seams are the build tools'.
static class EditorRelaunch
{
	/// The flag naming the relaunch folder the next editor restores from.
	public const String cArgument = "--relaunch";

	/// Whether the project's own editor must be built before a relaunch (the seams' NeedsBuild:
	/// missing, older than the game's code, or the SDK it builds over moved; unset, the first two).
	public static bool NeedsBuild(BuildToolSeams seams, EditorProject project)
	{
		if (seams.NeedsBuild != null)
			return seams.NeedsBuild(project);
		return ProjectBuild.IsStale(project.Directory, project.Settings, EditorBuildTools.cEditorConfig);
	}

	/// IsStale against the SDK the project would build over now (a checkout always is: BeefBuild
	/// then rebuilds what changed); without one found, against the game's code alone. The editor's
	/// NeedsBuild.
	public static bool NeedsBuildOverSdk(EditorProject project, StringView dataRoot)
	{
		let sdk = scope String();
		if (ProjectBuild.FindSdk(dataRoot, project.Directory, sdk))
			return ProjectBuild.IsStale(project.Directory, project.Settings, EditorBuildTools.cEditorConfig, sdk);
		return ProjectBuild.IsStale(project.Directory, project.Settings, EditorBuildTools.cEditorConfig);
	}

	/// Whether `project` can relaunch at all: open, with a package of its own, no build running.
	/// False with why in `outError`.
	public static bool CanRelaunch(BuildToolSeams seams, EditorProject project, String outError)
	{
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
		let latest = (seams.Service != null) ? seams.Service.GetLatest() : null;
		if (latest == null)
			return true;
		defer latest.ReleaseRef();
		if (latest.IsEnded)
			return true;
		outError.AppendF("build {} ({}) is running: build_status follows it, build_cancel stops it", latest.Id,
			BuildJobJson.TargetName(latest.Target));
		return false;
	}

	/// The relaunch of the open project into its built editor, its unsaved pages as `unsaved` says
	/// (Ask goes on once the person answers: Asking), `buildMs` the build before it (negative for
	/// none). Refused, nothing changed, for what CanRelaunch refuses, an editor not built or older
	/// than the game's code, pages that cannot be kept aside, or a launch that fails. What it did
	/// into `outReport`: relaunched, executable, port, keptAside (the pages' names),
	/// discardedUnsaved, buildMs and saveMs.
	public static RelaunchOutcome Relaunch(BuildToolSeams seams, UnsavedOnRelaunch unsaved, double buildMs, JsonValue outReport, String outError)
	{
		let project = (seams.Project != null) ? seams.Project() : null;
		if (!CanRelaunch(seams, project, outError))
			return .Refused;
		let game = ProjectBuild.GameName(project.Settings.Name, .. scope .());
		let editor = ProjectBuild.ExecutablePath(project.Directory, game, true, EditorBuildTools.cEditorConfig, .. scope .());
		if (!FileExists(editor))
		{
			outError.AppendF("the project's own editor is not built ('{}'): project_build first, or pass build: true", editor);
			return .Refused;
		}
		if (ProjectBuild.IsStale(project.Directory, project.Settings, EditorBuildTools.cEditorConfig))
		{
			outError.AppendF("the project's own editor ('{}') is older than the game's code: project_build first, or pass build: true", editor);
			return .Refused;
		}
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		if (seams.UnsavedWork != null)
			seams.UnsavedWork(lines);
		if (lines.IsEmpty || (unsaved == .Discard))
			return Go(seams, project, editor, false, lines, buildMs, outReport, outError) ? .Relaunched : .Refused;
		if (unsaved == .KeepAside)
			return Go(seams, project, editor, true, lines, buildMs, outReport, outError) ? .Relaunched : .Refused;
		if (seams.AskUnsaved == null)
		{
			outError.Append("pages have unsaved changes and there is nowhere to ask about them");
			return .Refused;
		}
		// The answer comes later: what it relaunches with is read again then.
		seams.AskUnsaved(new [=seams, =buildMs] () =>
			{
				let current = (seams.Project != null) ? seams.Project() : null;
				let report = JsonValue.MakeObject();
				defer delete report;
				let error = scope String();
				let path = scope String();
				if (current != null)
					ProjectBuild.ExecutablePath(current.Directory, ProjectBuild.GameName(current.Settings.Name, .. scope .()), true, EditorBuildTools.cEditorConfig, path);
				let none = scope List<String>();
				if (CanRelaunch(seams, current, error) && Go(seams, current, path, false, none, buildMs, report, error))
					return;
				GlobalLog(.Error, "Editor: the relaunch did not go on: {}", error);
				if (seams.Context != null)
					seams.Context.Notify(.Error, scope $"Relaunch: {error}.");
			});
		return .Asking;
	}

	/// The relaunch itself: the folder made afresh, the unsaved pages kept aside there (`keep`;
	/// else `unsaved`, the lines, are reported dropped), the views and the store saved, the state
	/// written, the next editor started with this one's command line and --relaunch, and this one
	/// told to exit. False, with why in `outError` and the folder gone, when a page could not be
	/// kept or the launch failed.
	private static bool Go(BuildToolSeams seams, EditorProject project, StringView editor, bool keep, List<String> unsaved, double buildMs,
		JsonValue outReport, String outError)
	{
		let started = System.Diagnostics.Stopwatch.GetTimestamp();
		let folder = RelaunchState.Folder(project.Directory, .. scope .());
		RemoveDirectoryRecursive(folder);
		let editorDir = PathParent(folder, .. scope .());
		if (!DirectoryExists(editorDir))
			CreateDirectory(editorDir);
		if (!CreateDirectory(folder))
		{
			outError.AppendF("the relaunch folder '{}' could not be made", folder);
			return false;
		}
		let state = scope RelaunchState();
		state.BuildMs = buildMs;
		if (keep)
		{
			let refused = scope List<String>();
			defer { ClearAndDeleteItems!(refused); }
			if (seams.KeepAside == null)
			{
				for (let line in unsaved)
					refused.Add(new .(line));
			}
			if ((seams.KeepAside == null) || !seams.KeepAside(folder, state, refused))
			{
				RemoveDirectoryRecursive(folder);
				outError.Append("these have unsaved changes that cannot be kept aside:");
				for (int i < refused.Count)
					outError.AppendF("{} {}", (i == 0) ? "" : ";", refused[i]);
				outError.Append(" - save each (page_open it, then action_execute file.save), or pass discardUnsaved: true to drop them");
				return false;
			}
		}
		if (seams.SaveState != null)
			seams.SaveState(state);
		state.SaveMs = (double)(System.Diagnostics.Stopwatch.GetTimestamp() - started) / 1000.0;
		state.LaunchedTicks = DateTime.UtcNow.Ticks;
		if (state.Save(folder) case .Err)
		{
			RemoveDirectoryRecursive(folder);
			outError.AppendF("the relaunch state could not be written into '{}'", folder);
			return false;
		}

		let serves = (seams.McpServes != null) ? seams.McpServes() : true;
		let port = (seams.McpPort != null) ? seams.McpPort() : 0;
		let commandLine = scope List<String>();
		defer { ClearAndDeleteItems!(commandLine); }
		Arguments(project.Directory, seams.DataRoot, serves, port, seams.ManagerPath, folder, commandLine);
		let views = scope StringView[commandLine.Count];
		for (int i < commandLine.Count)
			views[i] = commandLine[i];
		if ((seams.Launch == null) || !seams.Launch(editor, views))
		{
			RemoveDirectoryRecursive(folder);
			outError.AppendF("could not start '{}'", editor);
			return false;
		}
		GlobalLog(.Information, "Editor: relaunching into {} (build {} ms, save {} ms, {} page(s) kept aside); this editor exits", editor,
			(int64)Math.Max(buildMs, 0.0), (int64)state.SaveMs, state.Kept.Count);
		outReport.Set("relaunched", JsonValue.MakeBool(true));
		outReport.Set("executable", JsonValue.MakeString(editor));
		outReport.Set("port", JsonValue.MakeNumber(port));
		if (!state.Kept.IsEmpty)
		{
			let kept = JsonValue.MakeArray();
			for (let page in state.Kept)
				kept.Add(JsonValue.MakeString(page.Title));
			outReport.Set("keptAside", kept);
		}
		if (!keep && !unsaved.IsEmpty)
		{
			let dropped = JsonValue.MakeArray();
			for (let line in unsaved)
				dropped.Add(JsonValue.MakeString(line));
			outReport.Set("discardedUnsaved", dropped);
		}
		if (buildMs >= 0)
			outReport.Set("buildMs", JsonValue.MakeNumber((int64)buildMs));
		outReport.Set("saveMs", JsonValue.MakeNumber((int64)state.SaveMs));
		// The answer is written in this pump; the exit is the frame's end.
		seams.Exit();
		return true;
	}

	/// The next editor's command line: Open With This Build's (RelaunchArguments), the project
	/// manager that launched this one (`manager`, none when empty), and the relaunch folder.
	/// Into `outArguments` (the caller's, and so are the strings).
	public static void Arguments(StringView projectDir, StringView dataRoot, bool mcp, uint32 mcpPort, StringView manager, StringView folder,
		List<String> outArguments)
	{
		EditorBuildTools.RelaunchArguments(projectDir, dataRoot, mcp, mcpPort, outArguments);
		if (!manager.IsEmpty)
		{
			outArguments.Add(new .("--manager"));
			outArguments.Add(new .(manager));
		}
		outArguments.Add(new .(cArgument));
		outArguments.Add(new .(folder));
	}

	/// A failed or cancelled build in words a person reads, into `outText`: its counts and its
	/// first errors with their places (at most `count`), and that nothing relaunched.
	public static void DescribeFailure(BuildJob job, String outText, int count = 3)
	{
		if (job.State == .Cancelled)
		{
			outText.Append("the build was cancelled: nothing relaunched");
			return;
		}
		outText.AppendF("the build failed ({} error(s)): nothing relaunched, this editor stays as it was", job.ErrorCount);
		let diagnostics = scope List<BuildDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		job.GetDiagnostics(diagnostics);
		int said = 0;
		for (let diagnostic in diagnostics)
		{
			if ((diagnostic.Severity != .Error) || (said == count))
				continue;
			outText.Append((said == 0) ? ". " : "; ");
			diagnostic.Describe(outText);
			said++;
		}
		if (said == 0)
		{
			let error = job.GetError(.. scope .());
			if (!error.IsEmpty)
				outText.AppendF(". {}", error);
		}
	}
}

/// Project > Build and Relaunch, for a person: the project's own editor built when it needs it
/// (on the build lane, its progress on the status line and in the Console), then the relaunch,
/// the person asked about unsaved pages as at an exit. A failed build is said with its first
/// errors and nothing else happens.
class BuildAndRelaunch
{
	private BuildToolSeams mSeams ~ delete _;
	/// The build it waits on, a reference of its own; null with none.
	private BuildJob mJob = null ~ _?.ReleaseRef();

	/// Takes `seams`.
	public this(BuildToolSeams seams)
	{
		mSeams = seams;
	}

	public bool IsBuilding => mJob != null;

	/// The action: builds first when the editor needs it, else relaunches now.
	public void Run()
	{
		let context = mSeams.Context;
		let project = (mSeams.Project != null) ? mSeams.Project() : null;
		let error = scope String();
		if (mJob != null)
		{
			Say(.Info, "Build and Relaunch is building already.");
			return;
		}
		if (!EditorRelaunch.CanRelaunch(mSeams, project, error))
		{
			Say(.Warning, scope $"Build and Relaunch: {error}.");
			return;
		}
		if (!EditorRelaunch.NeedsBuild(mSeams, project))
		{
			Relaunch(-1);
			return;
		}
		let job = (mSeams.Start != null) ? mSeams.Start(.Editor, "", "", error) : null;
		if (job == null)
		{
			Say(.Error, scope $"Build and Relaunch: {error}.");
			return;
		}
		mJob = job; // the reference Start gave
		if (context != null)
			context.SetStatus("Build and Relaunch: building the project's editor...");
		Say(.Info, "Building the project's editor, then relaunching into it (see Console).");
	}

	/// Each frame: a build that ended goes on, a success to the relaunch, a failure said.
	public void Update()
	{
		if ((mJob == null) || !mJob.IsEnded)
			return;
		let job = mJob;
		mJob = null;
		defer job.ReleaseRef();
		if (job.State != .Succeeded)
		{
			let text = EditorRelaunch.DescribeFailure(job, .. scope .());
			GlobalLog(.Error, "Editor: Build and Relaunch: {}", text);
			Say(.Error, scope $"Build and Relaunch: {text}.");
			return;
		}
		Relaunch(job.DurationMs);
	}

	private void Relaunch(double buildMs)
	{
		let error = scope String();
		let report = JsonValue.MakeObject();
		defer delete report;
		if (EditorRelaunch.Relaunch(mSeams, RelaunchPolicy.Unsaved(.Person), buildMs, report, error) == .Refused)
			Say(.Error, scope $"Build and Relaunch: {error}.");
	}

	private void Say(NoticeKind kind, StringView text)
	{
		if (mSeams.Context != null)
			mSeams.Context.Notify(kind, text);
	}
}
