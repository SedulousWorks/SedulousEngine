using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// project_create and project_open: the STDIO host's additions, which let an agent scaffold
/// and open a project HEADLESSLY, the editor closed. What project_open opens goes into the
/// owner and the session is pointed at it; the editor host, whose project is the editor's own,
/// registers neither.
static class ProjectOpenTools
{
	/// `dataRoot` lets project_create seed the new project's starter content as the editor's New
	/// Project does (ProjectSeed: the default UI font, the sky, the primitives); a host that
	/// passes none creates the bare project.
	public static void Register(McpServer server, ProjectSession session, ProjectOwner owner, StringView dataRoot = "")
	{
		let createSchema = scope SchemaBuilder();
		createSchema.Str("directory", "path to create the project at", true);
		createSchema.Str("name", "the project's display name", true);
		let seedRoot = new String(dataRoot);
		server.RegisterTool("project_create",
			"Scaffold a new project (the manifest + the standard directory layout) at a directory, seeded with the editor's starter content (Roboto as the default UI font, the default sky, the cube, sphere and plane). Does not open it - call project_open next.",
			createSchema.Build(), .Creates,
			new (arguments, outResult, outError) => Create(seedRoot, arguments, outResult, outError),
			seedRoot);

		let openSchema = scope SchemaBuilder();
		openSchema.Str("directory", "the project directory", true);
		server.RegisterTool("project_open",
			"Open a project (mounts its source + cooked content databases) as the session's current project.",
			openSchema.Build(), .Rebuilds,
			new (arguments, outResult, outError) => Open(session, owner, arguments, outResult, outError));
	}

	private static bool Create(StringView seedRoot, JsonValue arguments, JsonValue outResult, String outError)
	{
		let directory = McpTools.ArgString(arguments, "directory", .. scope .());
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		if (EditorProject.Create(directory, name) case .Err(let error))
		{
			outError.AppendF("could not create project at '{}' ({})", directory, error);
			return false;
		}
		// The starter content, as the editor's New Project seeds it: without it a project made
		// here had no default UI font, and its exported game showed no text.
		var seeded = false;
		if (!seedRoot.IsEmpty)
		{
			if (let project = EditorProject.Open(directory))
			{
				defer delete project;
				ProjectSeed.SeedStarterContent(project, seedRoot);
				seeded = project.SaveSettings() case .Ok;
			}
		}
		outResult.Set("created", JsonValue.MakeBool(true));
		outResult.Set("seeded", JsonValue.MakeBool(seeded));
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
