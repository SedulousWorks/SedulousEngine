using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.VFS;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// Add Native Code's scaffold: the game's package in Code/, the project's workspace, the
/// NativeSample shape with the game's name and its Engine part named for the game.
class GamePackageTests
{
	private const String cRoot = "scratch_game_package";

	private static void Read(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// The package is Code/ with its manifest and the Engine part Code/<Game> (the project <Game>),
	/// the workspace lists the part, a .gitignore keeps what builds write out, the project enables
	/// it (path Code) and saves, and the project's build finds it.
	[Test]
	public static void TheGamesPackageIsScaffoldedEnabledAndSaved()
	{
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(cRoot));
		defer RemoveDirectoryRecursive(cRoot);
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), scope $"{cRoot}/Native Game", .. scope .());
		Test.Assert(EditorProject.Create(dir, "Native Game") case .Ok);
		{
			let project = EditorProject.Open(dir);
			defer delete project;
			Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Engine)) case .Ok);
			let entry = project.Settings.FindPlugin("nativegame");
			Test.Assert((entry != null) && (entry.Path == "Code") && entry.Platforms.IsEmpty);
		}

		let package = PathJoin(dir, "Code", .. scope .());
		let manifest = scope PluginManifest();
		Test.Assert(PluginManifest.Load(package, manifest) case .Ok);
		Test.Assert((manifest.Id == "nativegame") && (manifest.Name == "Native Game") && (manifest.Version == "0.1.0"));
		Test.Assert(manifest.EngineVersion == scope $"{EngineVersion.Major}.{EngineVersion.Minor}");
		Test.Assert((manifest.Parts.Count == 1) && manifest.HasPart(.Engine));
		Test.Assert((manifest.FindPlatform("Linux64") != null) && (manifest.FindPlatform("Win64") != null) && (manifest.FindPlatform("Web") != null));

		let partProject = Read(PathJoin(package, "NativeGame/BeefProj.toml", .. scope .()), .. scope .());
		Test.Assert(partProject.Contains("Name = \"NativeGame\"\n") && partProject.Contains("\"Sedulous.Runtime\" = \"*\""), partProject);
		Test.Assert(!DirectoryExists(PathJoin(package, "NativeGame.Engine", .. scope .())));
		let source = Read(PathJoin(package, "NativeGame/src/NativeGameEngine.bf", .. scope .()), .. scope .());
		Test.Assert(source.Contains("namespace NativeGame;") && source.Contains("class NativeGameEnginePart : PluginPart"), source);
		Test.Assert(source.Contains("public override StringView PluginId => \"nativegame\";"), source);
		Test.Assert(source.Contains("PluginRegistry.Register(new NativeGameEnginePart());") && !source.Contains("@T@"), source);
		Test.Assert(source.Contains("Compiler.ReadText(\"../Plugin.xml\")"), "the part's project is beside Code/Plugin.xml");

		let space = Read(PathJoin(package, "BeefSpace.toml", .. scope .()), .. scope .());
		Test.Assert(space.Contains("StartupProject = \"NativeGameEditor\"") && space.Contains("\"NativeGame\" = {Path = \"NativeGame\"}"), space);
		Test.Assert(space.Contains("\"NativeGameEditor\" = {Path = \".generated/NativeGameEditor\"}"), space);
		let ignore = Read(PathJoin(package, ".gitignore", .. scope .()), .. scope .());
		Test.Assert(ignore.Contains("/build/") && ignore.Contains("/.generated/") && ignore.Contains("/BeefConfig.toml"), ignore);
		Test.Assert(!FileExists(PathJoin(package, "BeefConfig.toml", .. scope .())), "the registry file is a build's, with its SDK");

		// Saved: a reopened project enables it, and its build takes the package.
		let reopened = EditorProject.Open(dir);
		defer delete reopened;
		Test.Assert(reopened.Settings.FindPlugin("nativegame") != null);
		let packages = scope List<ProjectPackage>();
		defer { ClearAndDeleteItems!(packages); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		ProjectBuild.Packages(dir, reopened.Settings, packages, problems);
		Test.Assert((packages.Count == 1) && problems.IsEmpty && (packages[0].Parts.Count == 1), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(packages[0].IsGame && (packages[0].Name == "NativeGame"));
	}

	/// It never overwrites the game's code: a project that already enables the id, or holds a
	/// part's folder, is refused and left as it was; Code/ itself being there (a user's workspace)
	/// is no refusal, and the user's .gitignore and workspace lines stay.
	[Test]
	public static void AnEnabledIdOrAnExistingFolderIsRefused()
	{
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(cRoot));
		defer RemoveDirectoryRecursive(cRoot);
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), scope $"{cRoot}/Game", .. scope .());
		Test.Assert(EditorProject.Create(dir, "Game") case .Ok);
		let project = EditorProject.Open(dir);
		defer delete project;
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Engine)) case .Ok);
		let source = PathJoin(dir, "Code/Game/src/GameEngine.bf", .. scope .());
		let edited = "// the game's own code\n";
		Test.Assert(WriteFile(source, .((uint8*)edited.Ptr, edited.Length)) case .Ok);
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Engine)) case .Err(.AlreadyExists), "enabled already");

		let entry = project.Settings.FindPlugin("game");
		project.Settings.Plugins.Remove(entry);
		delete entry;
		DeleteFile(PathJoin(dir, "Code/Plugin.xml", .. scope .()));
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Engine)) case .Err(.AlreadyExists), "the part's folder is there");
		Test.Assert(project.Settings.Plugins.IsEmpty, "no entry added for a refusal");
		Test.Assert(Read(source, .. scope .()) == edited, "the game's code untouched");
	}

	/// A Code/ the user made first (their own .gitignore and workspace) takes the package: their
	/// files keep every line, the workspace gaining the part's.
	[Test]
	public static void AUsersCodeFolderTakesThePackage()
	{
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(cRoot));
		defer RemoveDirectoryRecursive(cRoot);
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), scope $"{cRoot}/Game", .. scope .());
		Test.Assert(EditorProject.Create(dir, "Game") case .Ok);
		Test.Assert(CreateDirectory(PathJoin(dir, "Code", .. scope .())));
		let ignore = "# mine\n";
		let space = "FileVersion = 1\n\n[Workspace]\nStartupProject = \"Mine\"\n\n[Projects]\n\"Mine\" = {Path = \"Mine\"}\n";
		Test.Assert(WriteFile(PathJoin(dir, "Code/.gitignore", .. scope .()), .((uint8*)ignore.Ptr, ignore.Length)) case .Ok);
		Test.Assert(WriteFile(PathJoin(dir, "Code/BeefSpace.toml", .. scope .()), .((uint8*)space.Ptr, space.Length)) case .Ok);
		let project = EditorProject.Open(dir);
		defer delete project;
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Engine)) case .Ok);
		Test.Assert(Read(PathJoin(dir, "Code/.gitignore", .. scope .()), .. scope .()) == ignore, "the user's .gitignore");
		let merged = Read(PathJoin(dir, "Code/BeefSpace.toml", .. scope .()), .. scope .());
		Test.Assert(merged.StartsWith(scope $"{space}\"Game\" = {{Path = \"Game\"}}\n"), merged);
		Test.Assert(merged.Contains("StartupProject = \"Mine\"") && !merged.Contains("StartupProject = \"GameEditor\""), merged);
	}

	/// NativeSample is the scaffold's shape: its manifest names its Engine part, and its project
	/// enables the package by its folder.
	[Test]
	public static void NativeSampleEnablesItsOwnPackage()
	{
		const String cManifest = Compiler.ReadText("../../../Data/SampleProjects/NativeSample/Plugins/NativeSample/Plugin.xml");
		const String cProject = Compiler.ReadText("../../../Data/SampleProjects/NativeSample/Project.xml");
		let manifest = scope PluginManifest();
		Test.Assert(PluginManifest.Read(cManifest, manifest) case .Ok);
		Test.Assert((manifest.Id == "nativesample") && manifest.HasPart(.Engine));

		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(cRoot));
		defer RemoveDirectoryRecursive(cRoot);
		let fs = scope NativeFileSystem(cRoot);
		Test.Assert(fs.Save("Project.xml", .((uint8*)cProject.Ptr, cProject.Length)) case .Ok);
		let settings = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, settings, "Project.xml") case .Ok);
		Test.Assert(settings.Name == "NativeSample");
		let entry = settings.FindPlugin("nativesample");
		Test.Assert((entry != null) && (entry.Path == "Plugins/NativeSample") && entry.Platforms.IsEmpty && entry.Settings.IsEmpty);
	}

	/// A package gains the parts asked for that it lacks, its manifest listing every part in load
	/// order; each part's project depends on the library of the service its host hands it, and its
	/// source finds that service; the project's build takes them all. Parts all there are refused.
	[Test]
	public static void APackageGainsThePartsItLacksInLoadOrderEachFindingItsService()
	{
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(cRoot));
		defer RemoveDirectoryRecursive(cRoot);
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), scope $"{cRoot}/Game", .. scope .());
		Test.Assert(EditorProject.Create(dir, "Game") case .Ok);
		let project = EditorProject.Open(dir);
		defer delete project;
		let info = scope GamePackageInfo();
		Test.Assert(!GamePackage.Find(project, info) && (info.Path == "Code") && (info.Id == "game"));
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Engine)) case .Ok);
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Editor, .Engine, .Pipeline)) case .Ok);
		Test.Assert(GamePackage.Find(project, info));
		Test.Assert((info.Parts.Count == 3) && (info.Parts[0] == .Engine) && (info.Parts[1] == .Pipeline) && (info.Parts[2] == .Editor));
		Test.Assert(project.Settings.Plugins.Count == 1, "one entry");

		let manifest = scope PluginManifest();
		Test.Assert(PluginManifest.Load(PathJoin(dir, "Code", .. scope .()), manifest) case .Ok);
		Test.Assert((manifest.Parts[0].Kind == "Engine") && (manifest.Parts[1].Kind == "Pipeline") && (manifest.Parts[2].Kind == "Editor"));
		let pipelineProject = Read(PathJoin(dir, "Code/Game.Pipeline/BeefProj.toml", .. scope .()), .. scope .());
		Test.Assert(pipelineProject.Contains("Name = \"Game.Pipeline\"") && pipelineProject.Contains("\"Sedulous.Pipeline.Importer\" = \"*\""), pipelineProject);
		let pipelineSource = Read(PathJoin(dir, "Code/Game.Pipeline/src/GamePipeline.bf", .. scope .()), .. scope .());
		Test.Assert(pipelineSource.Contains("using Sedulous.Pipeline.Importer;") && pipelineSource.Contains("context.Find<PipelinePluginServices>()"), pipelineSource);
		Test.Assert(pipelineSource.Contains("public override PluginPartKind Kind => .Pipeline;") && pipelineSource.Contains("class GamePipelinePart"), pipelineSource);
		let editorSource = Read(PathJoin(dir, "Code/Game.Editor/src/GameEditor.bf", .. scope .()), .. scope .());
		Test.Assert(editorSource.Contains("context.Find<EditorContext>()") && !editorSource.Contains("@"), editorSource);
		Test.Assert(Read(PathJoin(dir, "Code/Game.Editor/BeefProj.toml", .. scope .()), .. scope .()).Contains("\"Sedulous.Editor.Core\" = \"*\""));
		let space = Read(PathJoin(dir, "Code/BeefSpace.toml", .. scope .()), .. scope .());
		Test.Assert(space.Contains("\"Game\" = {Path = \"Game\"}") && space.Contains("\"Game.Pipeline\" = {Path = \"Game.Pipeline\"}")
			&& space.Contains("\"Game.Editor\" = {Path = \"Game.Editor\"}"), space);

		let packages = scope List<ProjectPackage>();
		defer { ClearAndDeleteItems!(packages); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		ProjectBuild.Packages(dir, project.Settings, packages, problems);
		Test.Assert((packages.Count == 1) && (packages[0].Parts.Count == 3) && problems.IsEmpty);
		Test.Assert(GamePackage.Scaffold(project, scope PluginPartKind[](.Pipeline, .Editor)) case .Err(.AlreadyExists), "all there");
	}
}
