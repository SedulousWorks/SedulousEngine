using System;
using System.Collections;
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
	/// passes none creates the bare project. `answersDirectory` holds the user's answers on a
	/// project's MCP folders (McpFolders, the user's data folder): project_open lets the tools
	/// reach those the user approved; none when it is empty.
	public static void Register(McpServer server, ProjectSession session, ProjectOwner owner, StringView dataRoot = "",
		StringView answersDirectory = "")
	{
		let createSchema = scope SchemaBuilder();
		createSchema.Str("directory", "path to create the project at", true);
		createSchema.Str("name", "the project's display name", true);
		let seedRoot = new String(dataRoot);
		let answers = new String(answersDirectory);
		let paths = server.Paths;
		server.RegisterTool("project_create",
			"Scaffold a new project (the manifest + the standard directory layout) at a directory, seeded with the editor's starter content (Roboto as the default UI font, the default sky, every primitive). Does not open it - call project_open next.",
			createSchema.Build(), ToolAnnotations.Creates.OpenWorld,
			new (arguments, outResult, outError) => Create(paths, seedRoot, arguments, outResult, outError),
			seedRoot);

		let openSchema = scope SchemaBuilder();
		openSchema.Str("directory", "the project directory", true);
		server.RegisterTool("project_open",
			"Open a project (mounts its source + cooked content databases) as the session's current project.",
			openSchema.Build(), ToolAnnotations.Rebuilds.OpenWorld,
			new (arguments, outResult, outError) => Open(paths, answers, session, owner, arguments, outResult, outError),
			answers);
	}

	private static bool Create(McpPathPolicy paths, StringView seedRoot, JsonValue arguments, JsonValue outResult, String outError)
	{
		let directory = scope String();
		if (!paths.Check(McpTools.ArgString(arguments, "directory", .. scope .()), directory, outError))
			return false;
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

	private static bool Open(McpPathPolicy paths, StringView answers, ProjectSession session, ProjectOwner owner, JsonValue arguments, JsonValue outResult, String outError)
	{
		let directory = scope String();
		if (!paths.Check(McpTools.ArgString(arguments, "directory", .. scope .()), directory, outError))
			return false;
		let opened = EditorProject.Open(directory);
		if (opened == null)
		{
			outError.AppendF("could not open project at '{}' (missing or unreadable manifest?)", directory);
			return false;
		}
		outResult.Set("name", JsonValue.MakeString(opened.Name));
		outResult.Set("directory", JsonValue.MakeString(opened.Directory));
		owner.Open(session, opened);
		// The tools may now read and write in the project this host opened, and in the folders
		// outside it the project lists once the user approved them in the editor: opening a project
		// must not widen what an agent may touch.
		let project = session.Project;
		let folders = scope McpFolderStanding();
		if (!answers.IsEmpty)
			McpFolders.Stand(answers, project.Directory, project.Settings, folders);
		paths.SetProject(project.Directory, folders.Approved);
		let listed = scope List<String>();
		defer { ClearAndDeleteItems!(listed); }
		McpFolders.Resolve(project.Directory, project.Settings, listed);
		if (!listed.IsEmpty)
		{
			let reached = JsonValue.MakeArray();
			let unreached = JsonValue.MakeArray();
			for (let folder in listed)
			{
				var approved = false;
				for (let known in folders.Approved)
					approved |= (known == folder);
				(approved ? reached : unreached).Add(JsonValue.MakeString(folder));
			}
			outResult.Set("mcpFolders", reached);
			outResult.Set("mcpFoldersNotApproved", unreached); // the user approves them in the editor
		}
		return true;
	}
}
