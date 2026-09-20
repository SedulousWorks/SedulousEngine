using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// project_create / project_open / project_info: an agent scaffolds and opens a project
/// HEADLESSLY, the editor closed, and inspects it, over the headless EditorProject.
static class ProjectTools
{
	public static void Register(McpServer server, ProjectSession session)
	{
		let createSchema = scope SchemaBuilder();
		createSchema.Str("directory", "path to create the project at", true);
		createSchema.Str("name", "the project's display name", true);
		server.RegisterTool("project_create",
			"Scaffold a new project (the manifest + the standard directory layout) at a directory. Does not open it - call project_open next.",
			createSchema.Build(),
			new (arguments, outResult, outError) => Create(arguments, outResult, outError));

		let openSchema = scope SchemaBuilder();
		openSchema.Str("directory", "the project directory", true);
		server.RegisterTool("project_open",
			"Open a project (mounts its source + cooked content databases) as the session's current project.",
			openSchema.Build(),
			new (arguments, outResult, outError) => Open(session, arguments, outResult, outError));

		server.RegisterTool("project_info",
			"Details about the currently open project (name, directory, sources root).",
			scope SchemaBuilder().Build(),
			new (arguments, outResult, outError) => Info(session, outResult, outError));
	}

	private static bool Create(JsonValue arguments, JsonValue outResult, String outError)
	{
		let directory = McpTools.ArgString(arguments, "directory", .. scope .());
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		if (EditorProject.Create(directory, name) case .Err(let error))
		{
			outError.AppendF("could not create project at '{}' ({})", directory, error);
			return false;
		}
		outResult.Set("created", JsonValue.MakeBool(true));
		outResult.Set("directory", JsonValue.MakeString(directory));
		return true;
	}

	private static bool Open(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		let directory = McpTools.ArgString(arguments, "directory", .. scope .());
		let opened = EditorProject.Open(directory);
		if (opened == null)
		{
			outError.AppendF("could not open project at '{}' (missing or unreadable manifest?)", directory);
			return false;
		}
		outResult.Set("name", JsonValue.MakeString(opened.Name));
		outResult.Set("directory", JsonValue.MakeString(opened.Directory));
		session.Open(opened);
		return true;
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
