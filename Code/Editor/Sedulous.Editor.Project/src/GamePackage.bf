using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// The game's native code, scaffolded: its plugin package under Plugins/<Game>, with its
/// Plugin.xml and its Engine part (the part's project and a source whose Load is the one
/// registration point), and the project's entry for it. The NativeSample shape, with the
/// game's name filled in.
static class GamePackage
{
	/// The package's name and folder for a project: the project's name as the project's build
	/// names its executables (ProjectBuild.GameName), so "Sky Hopper" gives SkyHopper.
	public static void NameFor(StringView projectName, String outName) => ProjectBuild.GameName(projectName, outName);

	/// Writes the game's package into `project` and enables it, saving the manifest. Refused
	/// with AlreadyExists when the project already enables that id or the folder is there, so it
	/// never overwrites the game's code.
	public static Result<void, ErrorCode> Scaffold(EditorProject project)
	{
		let name = NameFor(project.Settings.Name, .. scope .());
		let id = ProjectLayout.PluginIdFromName(name, .. scope .());
		let path = scope $"{ProjectLayout.PluginsDir}/{name}";
		let packageDir = PathJoin(project.Directory, path, .. scope .());
		if ((project.Settings.FindPlugin(id) != null) || DirectoryExists(packageDir))
			return .Err(.AlreadyExists);

		let manifest = scope PluginManifest();
		manifest.Id.Set(id);
		manifest.Name.Set(project.Settings.Name);
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.AppendF("{}.{}", EngineVersion.Major, EngineVersion.Minor);
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		for (let platform in StringView[3]("Linux64", "Win64", "Web"))
		{
			let entry = new PluginPlatform();
			entry.Platform.Set(platform);
			manifest.Platforms.Add(entry);
		}
		let manifestXml = scope String();
		if (manifest.Write(manifestXml) case .Err)
			return .Err(.Internal);

		let partDir = PathJoin(packageDir, scope $"{name}.Engine", .. scope .());
		if ((WriteText(PathJoin(packageDir, PluginManifest.cFileName, .. scope .()), manifestXml) case .Err)
			|| (WriteText(PathJoin(partDir, "BeefProj.toml", .. scope .()), PartProject(name, .. scope .())) case .Err)
			|| (WriteText(PathJoin(partDir, scope $"src/{name}Engine.bf", .. scope .()), PartSource(name, id, .. scope .())) case .Err))
			return .Err(.Internal);

		let entry = new EnabledPlugin();
		entry.Id.Set(id);
		entry.Path.Set(path);
		project.Settings.Plugins.Add(entry);
		return project.SaveSettings();
	}

	/// The Engine part's project: a library over the runtime, named <Game>.Engine as the project's
	/// build expects a part's project to be.
	public static void PartProject(StringView name, String outText)
	{
		outText.AppendF("""
			FileVersion = 1

			[Project]
			Name = "{}.Engine"
			TargetType = "BeefLib"

			[Dependencies]
			corlib = "*"
			"Sedulous.Core" = "*"
			"Sedulous.Runtime" = "*"

			""", name);
	}

	/// The Engine part's source: its entry registers itself, compiled in, and its Load is where
	/// the game registers what it adds.
	public static void PartSource(StringView name, StringView id, String outText)
	{
		outText.Append("""
			using System;
			using Sedulous.Core.Logging;
			using Sedulous.Runtime;

			namespace @T@;

			/// @T@.Engine: this game's native code, the Engine part of its plugin package, which every
			/// host loads.
			///
			/// Load is the one registration point: subsystems, scene managers, script facades and types
			/// all register through the context here, and what the context records is reversed when the
			/// plugin unloads (the project closing). Unload removes what the recording cannot, such as a
			/// subsystem Load added. The part registers itself when the program starts, so linking the
			/// project is all it takes; the project's entry enables it.
			[AlwaysInclude]
			class @T@EnginePart : PluginPart
			{
				public const String cManifest = Compiler.ReadText("../Plugin.xml");

				static this()
				{
					PluginRegistry.Register(new @T@EnginePart());
				}

				public override StringView PluginId => "@ID@";
				public override PluginPartKind Kind => .Engine;
				public override StringView ManifestXml => cManifest;

				public override void Load(PluginContext context)
				{
					GlobalLog(.Information, "@T@ loaded");
				}

				public override void Unload(PluginContext context)
				{
				}
			}

			""");
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
