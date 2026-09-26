using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// project_create and project_open: the STDIO host's additions, which let an agent scaffold
/// and open a project HEADLESSLY, the editor closed. What project_open opens goes into the
/// owner and the session is pointed at it; the editor host, whose project is the editor's own,
/// registers neither.
static class ProjectOpenTools
{
	public static void Register(McpServer server, ProjectSession session, ProjectOwner owner)
	{
		let createSchema = scope SchemaBuilder();
		createSchema.Str("directory", "path to create the project at", true);
		createSchema.Str("name", "the project's display name", true);
		server.RegisterTool("project_create",
			"Scaffold a new project (the manifest + the standard directory layout) at a directory. Does not open it - call project_open next.",
			createSchema.Build(), .Creates,
			new (arguments, outResult, outError) => Create(arguments, outResult, outError));

		let openSchema = scope SchemaBuilder();
		openSchema.Str("directory", "the project directory", true);
		server.RegisterTool("project_open",
			"Open a project (mounts its source + cooked content databases) as the session's current project.",
			openSchema.Build(), .Rebuilds,
			new (arguments, outResult, outError) => Open(session, owner, arguments, outResult, outError));
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

	private static bool Open(ProjectSession session, ProjectOwner owner, JsonValue arguments, JsonValue outResult, String outError)
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
		owner.Open(session, opened);
		return true;
	}
}
