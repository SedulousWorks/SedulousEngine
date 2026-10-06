using System;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Tools.Editor;

/// The starter content a new project gets: ProjectSeed, with this executable's data root and
/// its --seed-primitives switch.
static class EditorSeed
{
	/// --seed-primitives: every primitive rather than the three a new project starts with.
	public static bool SeedAllPrimitives = false;

	/// The engine data root the baseline assets come from.
	public static String DataRoot = new .() ~ delete _;

	/// Seeds a project the manager just created: ProjectSeed, the one function the MCP
	/// project_create runs too.
	public static void SeedNewProject(EditorContext ctx, EditorProject project)
	{
		ProjectSeed.SeedStarterContent(project, DataRoot, SeedAllPrimitives);
	}
}
