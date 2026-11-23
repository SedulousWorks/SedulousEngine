using System;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Main;

/// The starter content a new project gets: ProjectSeed, with the editor's data root.
static class EditorSeed
{
	/// The engine data root the baseline assets come from.
	public static String DataRoot = new .() ~ delete _;

	/// Seeds a project the manager just created: ProjectSeed, the one function the MCP
	/// project_create runs too.
	public static void SeedNewProject(EditorContext ctx, EditorProject project)
	{
		ProjectSeed.SeedStarterContent(project, DataRoot);
	}
}
