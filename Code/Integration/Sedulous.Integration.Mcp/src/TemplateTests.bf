using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Engine.Project;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Project;
using Sedulous.VFS;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The engine's project templates (Data/Templates: Starter and Empty, made by
/// Data/Templates/Tools/make-templates.py through the MCP host) as project_create makes projects
/// from them: each template's records read at the CURRENT data versions and cook, as the samples'
/// must (a data version bump that forgets them leaves every new project refused); and a project
/// made from each carries its own names (its name, its code's, its package's id) with no
/// placeholder or the authoring script's names left anywhere in it.
static class TemplateTests
{
	/// The names the authoring script makes the templates under, before they become placeholders.
	private const String[3] cAuthoringNames = .("Sedulous Template Seed", "SedulousTemplateSeed", "seduloustemplateseed");

	/// The data root, with the template `id` there.
	private static void TemplateDataRoot(StringView id, String outDataRoot)
	{
		FindDataRoot(outDataRoot);
		Test.Assert(!outDataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let template = scope ProjectTemplate();
		Test.Assert(ProjectTemplates.Find(outDataRoot, id, template) case .Ok,
			scope $"the {id} template (Data/Templates/Tools/make-templates.py makes it)");
	}

	/// A project made by project_create from the template `id` at the scratch folder `scratch`,
	/// named `name`, on a stdio host's tools over the engine's data root; its folder into `outDir`.
	private static void CreateFrom(McpServer server, StringView id, StringView scratch, StringView name, String outDir)
	{
		Scratch(scratch, outDir);
		let arguments = With(With(Obj(), "directory", outDir), "name", name);
		if (!id.IsEmpty)
			With(arguments, "template", id);
		let created = CallOk(server, "project_create", arguments);
		defer delete created;
		Test.Assert(created.Get("created").AsBool());
		Test.Assert(created.Get("template").AsString() == (id.IsEmpty ? StringView(ProjectTemplates.cDefault) : id), "the template it was made from");
	}

	/// Reads every instance of a project made from the template `id` and cooks it through the tools
	/// an agent uses; the floors catch a template that lost what it had.
	private static void CheckTemplate(StringView id, StringView scratch, int readFloor, int cookedFloor,
		function void(EditorProject project) checkContent = null)
	{
		PipelineRegistration.RegisterPipelineTypes();
		let dataRoot = TemplateDataRoot(id, .. scope .());
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, dataRoot);
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner, dataRoot);
		let operations = scope InlineProjectOperations(session, builders, "");
		AssetWriteTools.Register(server, session, importers, operations);

		let dir = CreateFrom(server, id, scratch, "Template Check", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null, scope $"a project from {id} opens");
			defer delete project;
			let read = SampleProjectTests.ReadAllInstances(project.SourceDb.RootGroup);
			Test.Assert(read >= readFloor, scope $"{id}: read {read} instances");
			if (checkContent != null)
				checkContent(project);
		}

		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let force = Obj();
		force.Set("force", JsonValue.MakeBool(true));
		let cooked = CallOk(server, "asset_cook", force);
		defer delete cooked;
		Test.Assert(cooked.Get("cooked").AsInt() >= cookedFloor, scope $"{id}: cooked {cooked.Get("cooked").AsInt()}");
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"{id}: {cooked.Get("failed").AsInt()} failed");
		session.Plugins = null;
		DeleteAndNullify!(owner.Plugins);
		session.Project = null;
		DeleteAndNullify!(owner.Project);
	}

	[Test]
	public static void TheStarterTemplateReadsAtTheCurrentDataVersionsAndCooks()
	{
		// 6 instances: the Roboto font, the sky, the cube, sphere and plane, and the scene Main. 5
		// cook: all but the scene, which stages rather than cooks. Raise the floors when the template
		// grows.
		CheckTemplate("Starter", "scratch_template_starter", 6, 5, => CheckStarter);
	}

	/// The Starter's settings name its font and its scene, each there.
	private static void CheckStarter(EditorProject project)
	{
		let font = project.Settings.DefaultUiFontId;
		Test.Assert(font.IsSet && (project.SourceDb.GetInstance(font) != null), "the default UI font");
		let scene = project.Settings.DefaultSceneId;
		Test.Assert(scene.IsSet && (project.SourceDb.GetInstance(scene) != null), "the default scene");
		Test.Assert(SampleProjectTests.FindInstance(project.SourceDb.RootGroup, "Main", McpDocumentNames.cSceneDocument) != null, "the scene Main");
		Test.Assert(SampleProjectTests.FindInstance(project.SourceDb.RootGroup, "Sky", "TextureAsset") != null, "the sky");
	}

	[Test]
	public static void TheEmptyTemplateReadsAtTheCurrentDataVersionsAndCooks()
	{
		// Nothing but the game's code: no instance to read or cook.
		CheckTemplate("Empty", "scratch_template_empty", 0, 0);
	}

	/// Each text file under `dir` (relative to it as `relative`) checked: no placeholder and no
	/// authoring name left in it or its path.
	private static void CheckNoPlaceholders(StringView dir, StringView relative)
	{
		let entries = scope List<(String name, bool isDirectory)>();
		defer
		{
			for (let entry in entries)
				delete entry.name;
		}
		ListDirectory(PathJoin(dir, relative, .. scope .()), scope [&](name, isDirectory) => { entries.Add((new String(name), isDirectory)); });
		for (let entry in entries)
		{
			let path = scope String();
			if (!relative.IsEmpty)
				path.AppendF("{}/", relative);
			path.Append(entry.name);
			Test.Assert(!path.Contains("__GAME") && !path.Contains("SedulousTemplateSeed"), path);
			if (entry.isDirectory)
			{
				CheckNoPlaceholders(dir, path);
				continue;
			}
			let bytes = scope List<uint8>();
			Test.Assert(ReadFile(PathJoin(dir, path, .. scope .()), bytes) case .Ok, path);
			bool text = true;
			for (let b in bytes)
			{
				if (b == 0)
				{
					text = false;
					break;
				}
			}
			if (!text)
				continue;
			let content = StringView((char8*)bytes.Ptr, bytes.Count);
			for (let placeholder in StringView[3](ProjectTemplates.cProjectName, ProjectTemplates.cGame, ProjectTemplates.cGameId))
				Test.Assert(!content.Contains(placeholder), scope $"{path} keeps {placeholder}");
			for (int i < cAuthoringNames.Count)
				Test.Assert(!content.Contains(cAuthoringNames[i]), scope $"{path} keeps {cAuthoringNames[i]}");
		}
	}

	/// project_create with each template the engine has (and with none named: Starter) makes a
	/// project under its own names: its manifest's name, Code/<Game> with the starter behaviour of
	/// its package's id, the package enabled by that id, the root .gitignore, and nothing of the
	/// template's own (Template.xml, a placeholder, the authoring names). A template the engine does
	/// not have, and a folder that is not empty, are refused with the words to fix them.
	[Test]
	public static void ProjectCreateMakesAProjectUnderItsOwnNamesFromEachTemplate()
	{
		PipelineRegistration.RegisterPipelineTypes();
		let dataRoot = TemplateDataRoot(ProjectTemplates.cDefault, .. scope .());
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner, dataRoot);

		let templates = scope List<ProjectTemplate>();
		defer { ClearAndDeleteItems!(templates); }
		ProjectTemplates.ListTemplates(dataRoot, templates);
		Test.Assert(templates.Count >= 2);
		Test.Assert((templates[0].Id == "Starter") && (templates[1].Id == "Empty"), "Starter listed first");

		let ids = scope List<StringView>();
		for (let template in templates)
			ids.Add(template.Id);
		ids.Add(""); // none named: the default
		for (let id in ids)
		{
			let made = CreateFrom(server, id, "scratch_template_create", "Sky Hopper 2", .. scope .());
			defer RemoveDirectoryRecursive(made);
			let settings = scope ProjectSettings();
			Test.Assert(ProjectRegistry.ProbeProject(made, settings) case .Ok, "it reads at this engine's data versions");
			Test.Assert(settings.Name == "Sky Hopper 2", settings.Name);
			let plugin = settings.FindPlugin("skyhopper2");
			Test.Assert((plugin != null) && (plugin.Path == ProjectLayout.CodeDir), "the game's package, enabled by its id");
			let info = scope GamePackageInfo();
			Test.Assert(GamePackage.Find(made, settings, info) && (info.Name == "SkyHopper2") && info.Parts.Contains(.Engine));
			let rotator = scope List<uint8>();
			Test.Assert(ReadFile(PathJoin(made, "Code/SkyHopper2/src/Rotator.bf", .. scope .()), rotator) case .Ok, "the starter behaviour");
			let source = StringView((char8*)rotator.Ptr, rotator.Count);
			Test.Assert(source.Contains("namespace SkyHopper2;") && source.Contains("[Behaviour(\"skyhopper2.Rotator\")]"), scope String(source));
			Test.Assert(FileExists(PathJoin(made, "Code/BeefSpace.toml", .. scope .())) && FileExists(PathJoin(made, ".gitignore", .. scope .())));
			Test.Assert(!FileExists(PathJoin(made, ProjectTemplates.cInfoFile, .. scope .())));
			CheckNoPlaceholders(made, "");
		}

		// Refusals: a template the engine has not, and a folder with something in it.
		let dir = Scratch("scratch_template_refused", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let missing = scope String();
		CallErr(server, "project_create", With(With(With(Obj(), "directory", dir), "name", "Nope"), "template", "Platformer"), missing);
		Test.Assert(missing.Contains("no template 'Platformer'") && missing.Contains("Starter") && missing.Contains("Empty"), missing);
		Test.Assert(CreateDirectory(dir));
		Test.Assert(WriteFile(PathJoin(dir, "notes.txt", .. scope .()), .((uint8*)"mine", 4)) case .Ok);
		let taken = scope String();
		CallErr(server, "project_create", With(With(Obj(), "directory", dir), "name", "Taken"), taken);
		Test.Assert(taken.Contains("could not create") && taken.Contains("not empty"), taken);
		Test.Assert(!FileExists(PathJoin(dir, ProjectLayout.ManifestFile, .. scope .())));
	}
}
