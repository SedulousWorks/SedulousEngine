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

	public bool IsOpen => Project != null;
}
