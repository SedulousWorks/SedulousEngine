using System;
using Sedulous.Editor.Core;

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

	public bool IsOpen => Project != null;
}
