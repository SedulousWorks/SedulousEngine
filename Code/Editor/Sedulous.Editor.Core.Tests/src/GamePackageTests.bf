using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.VFS;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// Add Native Code's scaffold through an open project: the game's package in Code/ with its
/// Engine part named for the game, the project enabling it and saved, and what it refuses.
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
	/// which depends on the game tiers' libraries, finds the engine's service in its Load and
	/// registers its starter behaviour there, written beside it; the workspace lists the part, a .gitignore keeps what builds write out, the project enables
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
		for (let library in StringView[3]("Sedulous.Scene", "Sedulous.Engine.Composition", "Sedulous.Engine.Gameplay"))
			Test.Assert(partProject.Contains(scope $"\"{library}\" = \"*\""), partProject);
		Test.Assert(source.Contains("using Sedulous.Engine.Composition;") && source.Contains("using Sedulous.Engine.Gameplay;"), source);
		Test.Assert(source.Contains("let engine = context.Find<EnginePluginServices>();\n\t\tif (engine == null)\n\t\t\treturn;"), source);
		Test.Assert(source.Contains("\t\tGameplayServices.AddBehaviour<Rotator>(engine);\n"), source);
		let starter = Read(PathJoin(package, "NativeGame/src/Rotator.bf", .. scope .()), .. scope .());
		Test.Assert(starter.Contains("namespace NativeGame;") && starter.Contains("[Behaviour(\"nativegame.Rotator\")]"), starter);
		Test.Assert(starter.Contains("class Rotator : Behaviour") && starter.Contains("protected override void OnUpdate(float dt)"), starter);
		Test.Assert(starter.Contains("using Sedulous.Engine.Gameplay;") && !starter.Contains("@"), starter);

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
}
