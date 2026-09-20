namespace Sedulous.Editor.Core;

/// What Open must do for a directory, decided from the manifest probe and the version
/// relation.
enum ProjectOpenGate
{
	/// No readable manifest: refused; create is the explicit path.
	NotAProject,
	/// The same engine version: no ceremony.
	OpenDirectly,
	/// Older or unstamped: offer a backup then the upgrade, re-stamped on open.
	PromptOlderBackup,
	/// Saved by a NEWER engine: warn hard before opening.
	PromptNewerEngine
}
