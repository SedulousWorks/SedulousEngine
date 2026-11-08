using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// The game's package as it stands: its id, its name (its parts' prefix), its
/// path in the project, and the parts its manifest lists, in load order.
class GamePackageInfo
{
	public String Id = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	/// Relative to the project: Code.
	public String Path = new .() ~ delete _;
	public List<PluginPartKind> Parts = new .() ~ delete _;
}

/// The game's native code, scaffolded: the project's own package in Code/, the project's Beef
/// workspace, with its Plugin.xml and the parts asked for (each a part's project and a source
/// whose Load is the one registration point, finding the service its host hands that kind), the
/// workspace's BeefSpace.toml and .gitignore, and the project's entry for it. The Engine part is
/// Code/<Game> (the project <Game>), any other Code/<Game>.<Kind>. The Engine part depends on the
/// game tiers' libraries and comes with a starter behaviour its Load registers, so a new game
/// builds a tier of its own before a line of it is written.
///
/// A project whose game package is still a plugin package under Plugins/ keeps building through
/// its entry's path; Find does not report it, and Scaffold refuses, since the entry is taken.
static class GamePackage
{
	/// The package's name for a project, its parts' prefix: the project's name as the project's
	/// build names its executables (ProjectBuild.GameName), so "Sky Hopper" gives SkyHopper.
	public static void NameFor(StringView projectName, String outName) => ProjectBuild.GameName(projectName, outName);

	/// The game's package of `project` into `outInfo`: its id, name and path always, and its parts
	/// when its Plugin.xml is there. False when it is not.
	public static bool Find(EditorProject project, GamePackageInfo outInfo)
	{
		NameFor(project.Settings.Name, outInfo.Name);
		ProjectLayout.PluginIdFromName(outInfo.Name, outInfo.Id);
		outInfo.Path.Set(ProjectLayout.CodeDir);
		outInfo.Parts.Clear();
		let manifest = scope PluginManifest();
		if (PluginManifest.Load(PathJoin(project.Directory, outInfo.Path, .. scope .()), manifest) case .Err)
			return false;
		for (int i < PluginPartKind.Count)
		{
			if (manifest.HasPart((PluginPartKind)i))
				outInfo.Parts.Add((PluginPartKind)i);
		}
		return true;
	}

	/// Add Native Code: writes the game's package into `project` with `parts`, or adds to the
	/// package there the parts it lacks; its Plugin.xml lists them in load order, the workspace
	/// lists them (ProjectBuild.UpdateWorkspace), and the project enables the package and saves.
	/// Refused with AlreadyExists when every part asked for is there, or, for a new package, when
	/// the project's entry of its id is taken or a part's folder is there already, so it never
	/// overwrites the game's code.
	public static Result<void, ErrorCode> Scaffold(EditorProject project, Span<PluginPartKind> parts)
	{
		let info = scope GamePackageInfo();
		let exists = Find(project, info);
		let packageDir = PathJoin(project.Directory, info.Path, .. scope .());
		let manifest = scope PluginManifest();
		if (exists)
		{
			if (PluginManifest.Load(packageDir, manifest) case .Err)
				return .Err(.Internal);
		}
		else
		{
			if (project.Settings.FindPlugin(info.Id) != null)
				return .Err(.AlreadyExists);
			// Code/ itself may be there (a workspace of the user's); a part's folder is code.
			for (let kind in parts)
			{
				let partName = ProjectBuild.PartName(info.Name, true, kind, .. scope .());
				if (DirectoryExists(PathJoin(packageDir, partName, .. scope .())))
					return .Err(.AlreadyExists);
			}
			manifest.Id.Set(info.Id);
			manifest.Name.Set(project.Settings.Name);
			manifest.Version.Set("0.1.0");
			manifest.EngineVersion.AppendF("{}.{}", EngineVersion.Major, EngineVersion.Minor);
			for (let platform in StringView[3]("Linux64", "Win64", "Web"))
			{
				let entry = new PluginPlatform();
				entry.Platform.Set(platform);
				manifest.Platforms.Add(entry);
			}
		}

		bool added = false;
		for (let kind in parts)
		{
			if (manifest.HasPart(kind))
				continue;
			if (WritePart(packageDir, info.Name, info.Id, kind) case .Err(let err))
				return .Err(err);
			let part = new PluginManifestPart();
			kind.ToString(part.Kind);
			manifest.Parts.Add(part);
			added = true;
		}
		if (!added)
			return .Err(.AlreadyExists);
		InLoadOrder(manifest.Parts);

		let manifestXml = scope String();
		if ((manifest.Write(manifestXml) case .Err)
			|| (WriteText(PathJoin(packageDir, PluginManifest.cFileName, .. scope .()), manifestXml) case .Err))
			return .Err(.Internal);
		if (project.Settings.FindPlugin(info.Id) == null)
		{
			let entry = new EnabledPlugin();
			entry.Id.Set(info.Id);
			entry.Path.Set(info.Path);
			project.Settings.Plugins.Add(entry);
		}
		if (ProjectBuild.UpdateWorkspace(project.Directory, project.Settings) case .Err)
			return .Err(.Internal);
		return project.SaveSettings();
	}

	/// The manifest's parts in load order (the kinds' order), any it does not know last.
	private static void InLoadOrder(List<PluginManifestPart> parts)
	{
		let ordered = scope List<PluginManifestPart>();
		for (int i < PluginPartKind.Count)
		{
			let name = ((PluginPartKind)i).ToString(.. scope .());
			for (let part in parts)
			{
				if (part.Kind == name)
					ordered.Add(part);
			}
		}
		for (let part in parts)
		{
			if (!ordered.Contains(part))
				ordered.Add(part);
		}
		parts.Clear();
		parts.AddRange(ordered);
	}

	/// One part's folder, <Game> for the Engine part and <Game>.<Kind> for another, with its
	/// project and its source. Refused with AlreadyExists when the folder is there.
	private static Result<void, ErrorCode> WritePart(StringView packageDir, StringView name, StringView id, PluginPartKind kind)
	{
		let partDir = PathJoin(packageDir, ProjectBuild.PartName(name, true, kind, .. scope .()), .. scope .());
		if (DirectoryExists(partDir))
			return .Err(.AlreadyExists);
		if ((WriteText(PathJoin(partDir, "BeefProj.toml", .. scope .()), PartProject(name, kind, .. scope .())) case .Err)
			|| (WriteText(PathJoin(partDir, scope $"src/{name}{kind}.bf", .. scope .()), PartSource(name, id, kind, .. scope .())) case .Err))
			return .Err(.Internal);
		if ((kind == .Engine)
			&& (WriteText(PathJoin(partDir, scope $"src/{cStarterBehaviour}.bf", .. scope .()), StarterBehaviourSource(name, id, .. scope .())) case .Err))
			return .Err(.Internal);
		return .Ok;
	}

	/// A part's project: a library over the runtime and the library of the service its host hands
	/// its kind, named as the project's build expects the game's part to be (ProjectBuild.PartName:
	/// <Game> for the Engine part, <Game>.<Kind> for another). Beef's registry finds the engine's
	/// libraries it depends on. The Engine part's are the scene, the engine's plugin service and
	/// the game tiers (Behaviour, Level and Game), which its starter behaviour already uses.
	public static void PartProject(StringView name, PluginPartKind kind, String outText)
	{
		outText.AppendF("""
			FileVersion = 1

			[Project]
			Name = "{}"
			TargetType = "BeefLib"

			[Dependencies]
			corlib = "*"
			"Sedulous.Core" = "*"
			"Sedulous.Runtime" = "*"

			""", ProjectBuild.PartName(name, true, kind, .. scope .()));
		if (kind == .Engine)
		{
			outText.Append("""
				"Sedulous.Scene" = "*"
				"Sedulous.Engine.Composition" = "*"
				# The game tiers: its behaviours, levels and game, and their registration.
				"Sedulous.Engine.Gameplay" = "*"

				""");
		}
		else if (kind == .Pipeline)
			outText.Append("\"Sedulous.Pipeline.Importer\" = \"*\"\n");
		else if (kind == .Tooling)
			outText.Append("\"Sedulous.Editor.Mcp\" = \"*\"\n");
		else if (kind == .Editor)
			outText.Append("\"Sedulous.Editor.Core\" = \"*\"\n");
	}

	/// A part's source: its entry registers itself, compiled in, and its Load is where the game
	/// registers what it adds, through the service its host hands the kind (Engine parts through
	/// the context).
	public static void PartSource(StringView name, StringView id, PluginPartKind kind, String outText)
	{
		StringView hosts = "every host";
		StringView usings = "";
		StringView load = """
					GlobalLog(.Information, "@T@ loaded");

			""";
		if (kind == .Engine)
		{
			usings = "using Sedulous.Engine.Composition;\nusing Sedulous.Engine.Gameplay;\n";
			load = """
						// The engine's service: the game's behaviours, levels and game (GameplayServices'
						// AddBehaviour, AddLevel and SetGame) and its scene managers. A host without one,
						// such as the cook, offers none.
						let engine = context.Find<EnginePluginServices>();
						if (engine == null)
							return;
						GameplayServices.AddBehaviour<@B@>(engine);
						GlobalLog(.Information, "@T@ loaded");

				""";
		}
		else if (kind == .Pipeline)
		{
			hosts = "the editor and the CLI tools";
			usings = "using Sedulous.Pipeline.Importer;\n";
			load = """
						// The host's pipeline registries: AddBuilder, AddImporter and AddCreator, each
						// reversed when the plugin unloads.
						let pipeline = context.Find<PipelinePluginServices>();
						if (pipeline == null)
							return;
						GlobalLog(.Information, "@T@ pipeline loaded");

				""";
		}
		else if (kind == .Tooling)
		{
			hosts = "the editor, the exporter and the MCP host";
			usings = "using Sedulous.Editor.Mcp;\n";
			load = """
						// MCP tools every MCP host serves while the plugin is loaded (AddTools).
						let tools = context.Find<McpPluginServices>();
						if (tools == null)
							return;
						GlobalLog(.Information, "@T@ tooling loaded");

				""";
		}
		else if (kind == .Editor)
		{
			hosts = "the editor alone";
			usings = "using Sedulous.Editor.Core;\n";
			load = """
						// The editor's context: its actions, pages and inspector additions.
						let editor = context.Find<EditorContext>();
						if (editor == null)
							return;
						GlobalLog(.Information, "@T@ editor loaded");

				""";
		}
		outText.Append("""
			using System;
			using Sedulous.Core.Logging;
			using Sedulous.Runtime;
			@U@
			namespace @T@;

			/// @T@.@K@: this game's native code, the @K@ part of its plugin package, loaded by @H@.
			///
			/// Load is the one registration point: what the context and the host's services record is
			/// reversed when the plugin unloads (the project closing). Unload removes what the recording
			/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
			/// so linking the project is all it takes; the project's entry enables it.
			[AlwaysInclude]
			class @T@@K@Part : PluginPart
			{
				public const String cManifest = Compiler.ReadText("../Plugin.xml");

				static this()
				{
					PluginRegistry.Register(new @T@@K@Part());
				}

				public override StringView PluginId => "@ID@";
				public override PluginPartKind Kind => .@K@;
				public override StringView ManifestXml => cManifest;

				public override void Load(PluginContext context)
				{
			@L@	}

				public override void Unload(PluginContext context)
				{
				}
			}

			""");
		outText.Replace("@U@", usings);
		outText.Replace("@L@", load);
		outText.Replace("@B@", cStarterBehaviour);
		outText.Replace("@H@", hosts);
		outText.Replace("@T@", name);
		outText.Replace("@K@", kind.ToString(.. scope .()));
		outText.Replace("@ID@", id);
	}

	/// The Engine part's starter behaviour: its class and its source's name in the part's src/.
	public const String cStarterBehaviour = "Rotator";

	/// The Engine part's starter behaviour, which its Load registers: a class on an entity that
	/// turns it while the scene simulates, its one public field saved with the scene and shown in
	/// the inspector. Its id is the package's, so another game's Rotator is another type.
	public static void StarterBehaviourSource(StringView name, StringView id, String outText)
	{
		outText.Append("""
			using System;
			using Sedulous.Core;
			using Sedulous.Engine.Gameplay;

			namespace @T@;

			/// Turns its entity about its own up axis while the scene simulates: the game's starter
			/// behaviour, a class on its entity whose public fields are saved with the scene, shown in
			/// the inspector and set by the tools. The Engine part's Load registers it, and Add
			/// Component puts it on an entity.
			[Behaviour("@ID@.@B@")]
			[DisplayName("@B@")]
			[Category("@T@")]
			[Description("Turns the entity about its own up axis while the scene simulates.")]
			class @B@ : Behaviour
			{
				[DisplayName("Turns Per Second"), Description("How many whole turns it makes a second.")]
				public float TurnsPerSecond = 0.25f;

				protected override void OnUpdate(float dt)
				{
					let turn = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), TurnsPerSecond * TwoPi * dt);
					// The turn applies in the entity's own frame; normalizing keeps the rotation a unit
					// one over many frames of accumulated products.
					var local = Scene.GetLocalTransform(Entity);
					local.Rotation = Normalized(local.Rotation * turn);
					Scene.SetLocalTransform(Entity, local);
				}
			}

			""");
		outText.Replace("@B@", cStarterBehaviour);
		outText.Replace("@T@", name);
		outText.Replace("@ID@", id);
	}

	private static Result<void> WriteText(StringView path, StringView text)
	{
		if (!MakeDirectories(PathParent(path, .. scope .())))
			return .Err;
		if (WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Err)
			return .Err;
		return .Ok;
	}

	private static bool MakeDirectories(StringView dir)
	{
		if (dir.IsEmpty || DirectoryExists(dir))
			return true;
		if (!MakeDirectories(PathParent(dir, .. scope .())))
			return false;
		return CreateDirectory(dir) || DirectoryExists(dir);
	}
}
