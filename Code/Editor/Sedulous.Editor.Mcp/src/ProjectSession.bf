using System;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// The project every tool works on, null until one is open.
///
/// NON OWNING: the editor host points it at the editor's live project, so there is one
/// content database and one writer, and the stdio host at the project it opened and keeps in
/// its ProjectOwner. The project must outlive the server the tools are registered on.
class ProjectSession
{
	public EditorProject Project = null;

	/// A tool wrote a source asset (scene_write or prefab_write, created or overwritten): the
	/// host reacts as it does to any change made outside a page. The editor host tells the
	/// open pages editing it (EditorContext.NotifyAssetExternallyModified); the stdio host has
	/// no pages and leaves it unset. Owned.
	public delegate void(Guid assetId) OnAssetWritten ~ delete _;

	/// project_settings_set saved new settings: the editor host re-applies what depends on
	/// them, as its Project Settings dialog's Save does; the stdio host leaves it unset. Owned.
	public delegate void() OnSettingsChanged ~ delete _;

	/// The process's plugin host, which enabled the project's plugins: plugin_list reports each
	/// entry against it and plugin_settings_set edits the settings it holds. Null where the host
	/// enables no plugins. BORROWED.
	public Sedulous.Runtime.PluginHost Plugins = null;
	/// The export hooks the project's plugins added, which project_export runs; null for none.
	/// BORROWED.
	public ExportPluginServices ExportHooks = null;

	public bool IsOpen => Project != null;
}
