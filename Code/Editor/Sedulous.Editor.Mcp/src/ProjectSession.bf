using System;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// The MCP host's current project: null until project_open succeeds, replaced by the next
/// open. Owned by the host and must outlive the server the tools are registered on, since
/// every project tool reads or mutates it.
class ProjectSession
{
	public EditorProject Project ~ delete _;

	public bool IsOpen => Project != null;

	/// Takes ownership of `project`, releasing whatever was open.
	public void Open(EditorProject project)
	{
		if (Project != null)
			delete Project;
		Project = project;
	}

	public void Close() => Open(null);
}
