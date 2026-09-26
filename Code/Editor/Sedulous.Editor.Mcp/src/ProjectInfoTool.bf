using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// project_info: the open project's identity, part of the surface every host serves.
static class ProjectInfoTool
{
	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterTool("project_info",
			"Details about the currently open project (name, directory, sources root).",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => Info(session, outResult, outError));
	}

	private static bool Info(ProjectSession session, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		outResult.Set("name", JsonValue.MakeString(project.Name));
		outResult.Set("directory", JsonValue.MakeString(project.Directory));
		outResult.Set("sourcesRoot", JsonValue.MakeString(project.SourcesRoot(.. scope .())));
		return true;
	}
}
