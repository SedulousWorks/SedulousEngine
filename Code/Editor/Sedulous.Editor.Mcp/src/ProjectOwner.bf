using System;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// The stdio host's project ownership: project_open stores what it opened here and points
/// the session at it. The editor host has no owner, its project being the editor's own.
class ProjectOwner
{
	public EditorProject Project ~ delete _;

	/// Takes ownership of `project`, releasing whatever was open, and points the session at
	/// it. The session is cleared first, so it never names a project that is being deleted.
	public void Open(ProjectSession session, EditorProject project)
	{
		session.Project = null;
		delete Project;
		Project = project;
		session.Project = project;
	}
}
