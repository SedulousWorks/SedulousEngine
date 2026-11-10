using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Engine.Project;
using Sedulous.Editor.Projects;

namespace Sedulous.Editor.Project;

/// The project manager's headless decision layer between the manager UI and the registry
/// and manifest primitives: the UI renders what this decides, nothing here touches a view,
/// so the open gate and the prompt copy are testable. The future home of project templates.
class ProjectManagerController
{
	private Settings mStore;

	/// The store is BORROWED.
	public this(Settings store)
	{
		mStore = store;
	}

	public Settings Store => mStore;

	/// Whether opening through `gate`, once the user agrees, stamps the project with this engine: an
	/// older engine's project is upgraded (backed up first or not, as asked); a newer engine's is
	/// opened as it is, keeping its stamp, so the newer engine still knows it as its own; one of this
	/// engine's needs nothing.
	public static bool RestampsOnOpen(ProjectOpenGate gate) => gate == .PromptOlderBackup;

	/// DecideOpen against this engine's own version.
	public void DecideOpen(StringView directory, ProjectOpenDecision decision) => DecideOpen(directory, EngineVersion.String, decision);

	/// Reads the header of `directory`, classifies its stamp against `engineVersion` (the engine
	/// that is to open it: a picked SDK's version, or this engine's) and composes the prompt copy
	/// into `decision`. The header, not the settings, so a project whose settings a newer engine
	/// wrote is still told apart from a folder that is no project. A pure decision: the caller
	/// shows the dialogs for the prompt gates and calls the open path it owns.
	public void DecideOpen(StringView directory, StringView engineVersion, ProjectOpenDecision decision)
	{
		decision.Gate = .NotAProject;
		decision.PromptTitle.Clear();
		decision.PromptBody.Clear();
		if (ProjectHeader.Read(directory, decision.Header) case .Err)
			return;
		let relation = ProjectRegistry.CompareEngineVersions(decision.Header.EngineVersion, engineVersion);
		if (relation == .Same)
		{
			decision.Gate = .OpenDirectly;
			return;
		}
		let stamped = decision.Header.EngineVersion.IsEmpty ? "an unknown version" : StringView(decision.Header.EngineVersion);
		if (relation == .ProjectNewer)
		{
			decision.Gate = .PromptNewerEngine;
			decision.PromptTitle.Set("Project from a newer engine");
			decision.PromptBody.AppendF("This project was last saved by engine {} - NEWER than this editor ({}). Opening may lose or misread data. Open it with the newer engine instead if you can.", stamped, engineVersion);
			return;
		}
		decision.Gate = .PromptOlderBackup;
		decision.PromptTitle.Set("Open with this engine version?");
		decision.PromptBody.AppendF("This project was last saved by engine {}; this editor is {}. Back up Project.xml before opening? (Content migrates as assets re-save; use version control for whole-project safety.)", stamped, engineVersion);
	}

	/// Scaffolds a new project at `directory`; the caller opens on success. Later a template
	/// selects the scaffold instead of the bare layout.
	public Result<void, ErrorCode> Create(StringView directory, StringView name) => ProjectScaffold.Create(directory, name);

	/// The pre-upgrade manifest backup.
	public Result<void, ErrorCode> BackupManifest(StringView directory, String outBackupPath)
		=> ProjectRegistry.BackupProjectManifest(directory, outBackupPath);

	/// Records a successful open, most recent first with a fresh snapshot; the caller
	/// persists the store afterwards.
	public void NoteOpened(StringView directory, StringView name, StringView engineVersion)
		=> ProjectRegistry.TouchRecentProject(mStore, directory, name, engineVersion);

	public bool Remove(StringView directory) => ProjectRegistry.RemoveRecentProject(mStore, directory);

	/// Pins or unpins a project (pinned ones are listed first); false when it is not listed.
	public bool SetFavourite(StringView directory, bool favourite) => ProjectRegistry.SetRecentProjectFavourite(mStore, directory, favourite);

	/// Points a missing project's entry at the folder it is in now, refreshed from its manifest's
	/// header; false when `to` holds no project, or is listed already.
	public bool Relocate(StringView from, StringView to)
	{
		let header = scope ProjectHeader();
		if ((ProjectHeader.Read(to, header) case .Err) || !ProjectRegistry.RelocateRecentProject(mStore, from, to))
			return false;
		TouchSnapshot(to, header);
		return true;
	}

	/// Removes every project whose folder no longer holds one (no manifest whose header reads);
	/// how many went. A project whose settings a newer engine wrote stays. Files are never
	/// touched: only the list changes.
	public int RemoveMissing()
	{
		let registry = mStore.Section<RecentProjectsSettings>();
		int removed = 0;
		let header = scope ProjectHeader();
		for (int i = registry.Entries.Count - 1; i >= 0; i--)
		{
			if (ProjectHeader.Read(registry.Entries[i].Path, header) case .Err)
			{
				delete registry.Entries[i];
				registry.Entries.RemoveAt(i);
				removed++;
			}
		}
		if (removed > 0)
			mStore.MarkChanged<RecentProjectsSettings>();
		return removed;
	}

	/// The list's order, by name or by when each was last opened.
	public bool SortByName => mStore.Section<RecentProjectsSettings>().SortByName;

	public void SetSortByName(bool byName)
	{
		mStore.Section<RecentProjectsSettings>().SortByName = byName;
		mStore.MarkChanged<RecentProjectsSettings>();
	}

	/// Where the last project was made or downloaded: where New Project's location starts.
	public StringView LastLocation => mStore.Section<RecentProjectsSettings>().LastLocation;

	public void SetLastLocation(StringView folder)
	{
		mStore.Section<RecentProjectsSettings>().LastLocation.Set(folder);
		mStore.MarkChanged<RecentProjectsSettings>();
	}

	/// Lazily creates the section.
	public RecentProjectsSettings Entries => mStore.Section<RecentProjectsSettings>();

	/// Whether the launcher shows a grid of the projects' pictures (else a list); kept in the
	/// store with the recent projects (the caller saves it, as after Remove).
	public bool GridView => mStore.Section<RecentProjectsSettings>().GridView;

	public void SetGridView(bool grid)
	{
		mStore.Section<RecentProjectsSettings>().GridView = grid;
		mStore.MarkChanged<RecentProjectsSettings>();
	}

	// Refreshes an entry's name and version from its manifest's header, keeping its place and time.
	private void TouchSnapshot(StringView directory, ProjectHeader header)
	{
		let entry = mStore.Section<RecentProjectsSettings>().Find(directory);
		if (entry == null)
			return;
		entry.Name.Set(header.Name);
		entry.EngineVersion.Set(header.EngineVersion);
	}

	/// The folder a project named `name` gets, appended to `outFolder`: spaces become '-'; letters,
	/// digits, '-', '_', '.' and anything past ASCII (accented letters, other scripts) stay; other
	/// characters, those a file system refuses and those awkward in a path ("'", '!', '&', '#'), go.
	/// Runs of '-' become one, '-' and '.' at either end go, and a name Windows reserves (CON, NUL,
	/// COM1) gets "-Project". Nothing when nothing usable is left ("???").
	public static void FolderNameFor(StringView name, String outFolder)
	{
		let folder = scope String();
		for (let c in name.RawChars)
		{
			let keep = ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_') || (c == '.')
				|| ((uint8)c >= 0x80);
			if (keep)
				folder.Append(c);
			else if (((c == ' ') || (c == '-') || (c == '\t')) && !folder.IsEmpty && (folder[folder.Length - 1] != '-'))
				folder.Append('-');
		}
		int start = 0;
		int end = folder.Length;
		while ((start < end) && ((folder[start] == '-') || (folder[start] == '.')))
			start++;
		while ((end > start) && ((folder[end - 1] == '-') || (folder[end - 1] == '.')))
			end--;
		let safe = StringView(folder, start, end - start);
		// CON, PRN, AUX, NUL, COM1 to COM9 and LPT1 to LPT9, before any extension, any case.
		var stem = safe;
		let dot = stem.IndexOf('.');
		if (dot >= 0)
			stem = StringView(stem, 0, dot);
		let numbered = (stem.Length == 4) && (StringView(stem, 0, 3).Equals("COM", true) || StringView(stem, 0, 3).Equals("LPT", true))
			&& (stem[3] >= '1') && (stem[3] <= '9');
		outFolder.Append(safe);
		if (stem.Equals("CON", true) || stem.Equals("PRN", true) || stem.Equals("AUX", true) || stem.Equals("NUL", true) || numbered)
			outFolder.Append("-Project");
	}

	/// New Project's check for a project named `name` made in `location`, in a folder named after it
	/// there (FolderNameFor) when `ownFolder` is set, else in `location` itself, into `outCheck`.
	/// Red, Create waiting: no name, a name with nothing a
	/// folder can be named by, no location, a location that is a file, a target that is a project
	/// already or holds files. Amber: the location does not exist yet (it is made). Else green.
	/// Folders in the message show under `home` as ~. A sample's download dialog asks the same with
	/// `action` Download, and the green line says so. It touches nothing on disk, so the dialog runs
	/// it on every keystroke.
	public static void CheckNewProject(StringView name, StringView location, bool ownFolder, StringView home, NewProjectCheck outCheck,
		NewProjectAction action = .Create)
	{
		outCheck.Level = .Error;
		outCheck.Message.Clear();
		outCheck.Target.Clear();
		let trimmed = TrimSpaces(name);
		outCheck.Name.Set(trimmed);
		if (trimmed.IsEmpty)
		{
			outCheck.Message.Set("Give the project a name.");
			return;
		}
		let safeName = FolderNameFor(trimmed, .. scope .());
		if (ownFolder && safeName.IsEmpty)
		{
			outCheck.Message.Set("The name needs a letter or a digit for its folder.");
			return;
		}
		let folder = TrimSpaces(location);
		if (folder.IsEmpty)
		{
			outCheck.Message.Set("Choose the folder it is made in.");
			return;
		}
		let shownWhere = RecentProjects.ShortenHomePath(folder, home, .. scope .());
		if (!DirectoryExists(folder) && FileExists(folder))
		{
			outCheck.Message.AppendF("{} is a file, not a folder.", shownWhere);
			return;
		}
		if (ownFolder)
			PathJoin(folder, safeName, outCheck.Target);
		else
			outCheck.Target.Set(folder);
		let shownTarget = RecentProjects.ShortenHomePath(outCheck.Target, home, .. scope .());
		if (FileExists(PathJoin(outCheck.Target, ProjectLayout.ManifestFile, .. scope .())))
		{
			outCheck.Message.AppendF("{} is a project already: Open Folder opens it.", shownTarget);
			return;
		}
		if (!DirectoryExists(outCheck.Target) && FileExists(outCheck.Target))
		{
			outCheck.Message.AppendF("{} is a file, not a folder.", shownTarget);
			return;
		}
		if (HoldsAnything(outCheck.Target))
		{
			if (ownFolder)
				outCheck.Message.AppendF("{} already exists and has files in it. Choose another name or folder.", shownTarget);
			else
				outCheck.Message.AppendF("{} already has files in it. A project needs an empty folder: turn on the folder option, or choose an empty one.", shownTarget);
			return;
		}
		outCheck.Level = .Warning;
		if (!DirectoryExists(folder))
		{
			if (ownFolder)
				outCheck.Message.AppendF("{} does not exist yet; it will be made, then {} inside it.", shownWhere, safeName);
			else
				outCheck.Message.AppendF("{} does not exist yet; it will be made, and the project made in it.", shownWhere);
			return;
		}
		outCheck.Level = .Ok;
		if (action == .Download)
		{
			if (ownFolder)
				outCheck.Message.AppendF("Downloads into {}.", shownTarget);
			else
				outCheck.Message.AppendF("Downloads {} into {}.", trimmed, shownTarget);
		}
		else if (ownFolder)
			outCheck.Message.AppendF("Creates {}, and opens it.", shownTarget);
		else
			outCheck.Message.AppendF("Creates {} in {}, and opens it.", trimmed, shownTarget);
	}

	/// `text` without its spaces at either end.
	private static StringView TrimSpaces(StringView text)
	{
		int start = 0;
		int end = text.Length;
		while ((start < end) && (text[start] == ' '))
			start++;
		while ((end > start) && (text[end - 1] == ' '))
			end--;
		return text.Substring(start, end - start);
	}

	/// Whether a folder holds any file or folder (false when it does not exist).
	private static bool HoldsAnything(StringView directory)
	{
		bool any = false;
		ListDirectory(directory, scope [&] (name, isDirectory) => { any = true; });
		return any;
	}
}
