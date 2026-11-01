using System;
using Sedulous.Core;
using Sedulous.Settings;
using Sedulous.Engine.Project;

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

	/// Probes, classifies and composes the prompt copy for `directory` into `decision`. A
	/// pure decision: the caller shows the dialogs for the prompt gates and calls the open
	/// path it owns.
	public void DecideOpen(StringView directory, ProjectOpenDecision decision)
	{
		decision.Gate = .NotAProject;
		decision.PromptTitle.Clear();
		decision.PromptBody.Clear();
		if (ProjectRegistry.ProbeProject(directory, decision.Probed) case .Err)
			return;
		let relation = ProjectRegistry.CompareProjectEngineVersion(decision.Probed.EngineVersion);
		if (relation == .Same)
		{
			decision.Gate = .OpenDirectly;
			return;
		}
		let stamped = decision.Probed.EngineVersion.IsEmpty ? "an unknown version" : StringView(decision.Probed.EngineVersion);
		if (relation == .ProjectNewer)
		{
			decision.Gate = .PromptNewerEngine;
			decision.PromptTitle.Set("Project from a newer engine");
			decision.PromptBody.AppendF("This project was last saved by engine {} - NEWER than this editor ({}). Opening may lose or misread data. Open it with the newer engine instead if you can.", stamped, EngineVersion.String);
			return;
		}
		decision.Gate = .PromptOlderBackup;
		decision.PromptTitle.Set("Open with this engine version?");
		decision.PromptBody.AppendF("This project was last saved by engine {}; this editor is {}. Back up Project.xml before opening? (Content migrates as assets re-save; use version control for whole-project safety.)", stamped, EngineVersion.String);
	}

	/// Scaffolds a new project at `directory`; the caller opens on success. Later a template
	/// selects the scaffold instead of the bare layout.
	public Result<void, ErrorCode> Create(StringView directory, StringView name) => EditorProject.Create(directory, name);

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

	/// Points a missing project's entry at the folder it is in now, refreshed from its manifest;
	/// false when `to` holds no project, or is listed already.
	public bool Relocate(StringView from, StringView to)
	{
		let probed = scope ProjectSettings();
		if ((ProjectRegistry.ProbeProject(to, probed) case .Err) || !ProjectRegistry.RelocateRecentProject(mStore, from, to))
			return false;
		TouchSnapshot(to, probed);
		return true;
	}

	/// Removes every project whose folder no longer holds it; how many went. Files are never
	/// touched: only the list changes.
	public int RemoveMissing()
	{
		let registry = mStore.Section<RecentProjectsSettings>();
		int removed = 0;
		for (int i = registry.Entries.Count - 1; i >= 0; i--)
		{
			let probed = scope ProjectSettings();
			if (ProjectRegistry.ProbeProject(registry.Entries[i].Path, probed) case .Err)
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

	// Refreshes an entry's name and version from its manifest, keeping its place and time.
	private void TouchSnapshot(StringView directory, ProjectSettings probed)
	{
		let entry = mStore.Section<RecentProjectsSettings>().Find(directory);
		if (entry == null)
			return;
		entry.Name.Set(probed.Name);
		entry.EngineVersion.Set(probed.EngineVersion);
	}
}
