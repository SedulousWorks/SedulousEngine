using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// project_create and project_open: the STDIO host's additions, which let an agent make a
/// project from one of the engine's templates and open it HEADLESSLY, the editor closed. What
/// project_open opens goes into the owner and the session is pointed at it; the editor host,
/// whose project is the editor's own, registers neither.
static class ProjectOpenTools
{
	/// `dataRoot` is where project_create finds the SDK's project templates (Data/Templates), and
	/// the starter content the bare project may be seeded with (ProjectSeed); a host that passes
	/// none makes the bare project, with no template.
	public static void Register(McpServer server, ProjectSession session, ProjectOwner owner, StringView dataRoot = "")
	{
		let createSchema = scope SchemaBuilder();
		createSchema.Str("directory", "path to create the project at: a new folder (its parent existing) or an empty one", true);
		createSchema.Str("name", "the project's display name", true);
		createSchema.Str("template", "the template it is made from, by its folder in the engine's Data/Templates: Starter (the default) or Empty; \"none\" for the bare manifest and folders");
		createSchema.Boolean("seed", "with template \"none\": seed the starter content (Roboto as the default UI font, the default sky, the cube, sphere and plane)");
		let seedRoot = new String(dataRoot);
		server.RegisterTool("project_create",
			"Make a new project at a directory from one of the engine's project templates (`template`, default Starter): Starter has the game's code (Code/, its Engine part with the starter behaviour Rotator), Roboto as the default UI font, the default sky, the cube, sphere and plane, and a default scene; Empty has the game's code alone. The template's names become the project's: its name, and the name its code goes by (its letters and digits, \"Sky Hopper\" giving SkyHopper). `template` \"none\" makes the bare manifest and folders, seeded with the starter content when `seed` is true. Refused when the folder is not empty. Does not open it - call project_open next.",
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

	/// What `template` names when it is the bare project.
	public const String cNoTemplate = "none";

	private static bool Create(StringView dataRoot, JsonValue arguments, JsonValue outResult, String outError)
	{
		let directory = McpTools.ArgString(arguments, "directory", .. scope .());
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		let template = McpTools.ArgString(arguments, "template", .. scope .());
		// None named: the default template where the host has the engine's data, else the bare
		// project, as a host with no data root has no templates.
		if (template.IsEmpty)
			template.Set(dataRoot.IsEmpty ? cNoTemplate : ProjectTemplates.cDefault);
		if (template != cNoTemplate)
			return CreateFromTemplate(dataRoot, template, directory, name, outResult, outError);

		if (EditorProject.Create(directory, name) case .Err(let error))
		{
			outError.AppendF("could not create project at '{}' ({})", directory, error);
			return false;
		}
		// The starter content, as the editor's New Project seeds it: what the Starter template is
		// made from.
		var seeded = false;
		if (!dataRoot.IsEmpty && McpTools.ArgBool(arguments, "seed"))
		{
			if (let project = EditorProject.Open(directory))
			{
				defer delete project;
				ProjectSeed.SeedStarterContent(project, dataRoot);
				seeded = project.SaveSettings() case .Ok;
			}
		}
		outResult.Set("created", JsonValue.MakeBool(true));
		outResult.Set("template", JsonValue.MakeString(cNoTemplate));
		outResult.Set("seeded", JsonValue.MakeBool(seeded));
		outResult.Set("directory", JsonValue.MakeString(directory));
		return true;
	}

	/// The project made from the template `id` of the host's data root.
	private static bool CreateFromTemplate(StringView dataRoot, StringView id, StringView directory, StringView name, JsonValue outResult,
		String outError)
	{
		if (dataRoot.IsEmpty)
		{
			outError.AppendF("could not create project at '{}': this host has no engine data, so no templates (template \"{}\" makes the bare project)",
				directory, cNoTemplate);
			return false;
		}
		let template = scope ProjectTemplate();
		if (ProjectTemplates.Find(dataRoot, id, template) case .Err)
		{
			let available = scope List<ProjectTemplate>();
			defer { ClearAndDeleteItems!(available); }
			ProjectTemplates.ListTemplates(dataRoot, available);
			outError.AppendF("could not create project at '{}': no template '{}' (the engine has", directory, id);
			for (let listed in available)
				outError.AppendF("{} {}", (@listed.Index == 0) ? "" : ",", listed.Id);
			outError.AppendF("{}; \"{}\" makes the bare project)", available.IsEmpty ? " none" : "", cNoTemplate);
			return false;
		}
		if (ProjectTemplates.Instantiate(template.Directory, directory, name) case .Err(let error))
		{
			outError.AppendF("could not create project at '{}' ({})", directory, error);
			if (error == .AlreadyExists)
				outError.Append(": the folder is not empty, and a project is made in a new or empty one");
			else if (error == .NotFound)
				outError.Append(": its parent folder is not there");
			return false;
		}
		outResult.Set("created", JsonValue.MakeBool(true));
		outResult.Set("template", JsonValue.MakeString(template.Id));
		outResult.Set("seeded", JsonValue.MakeBool(false));
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
