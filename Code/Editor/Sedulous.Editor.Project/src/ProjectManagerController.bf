using System;
using Sedulous.Core;
using Sedulous.Settings;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Core;

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

	/// Lazily creates the section.
	public RecentProjectsSettings Entries => mStore.Section<RecentProjectsSettings>();
}
