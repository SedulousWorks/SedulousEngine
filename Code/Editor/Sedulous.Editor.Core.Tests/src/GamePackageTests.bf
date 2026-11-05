using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.VFS;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// Add Native Code's scaffold: the game's package, the NativeSample shape with the game's name.
class GamePackageTests
{
	private const String cRoot = "scratch_game_package";

	private static void Read(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// The package is Plugins/<Game> with its manifest and an Engine part named for the game, the
	/// project enables it and saves, and the project's build finds it.
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
			Test.Assert(GamePackage.Scaffold(project) case .Ok);
			let entry = project.Settings.FindPlugin("nativegame");
			Test.Assert((entry != null) && (entry.Path == "Plugins/NativeGame") && entry.Platforms.IsEmpty);
		}

		let package = PathJoin(dir, "Plugins/NativeGame", .. scope .());
		let manifest = scope PluginManifest();
		Test.Assert(PluginManifest.Load(package, manifest) case .Ok);
		Test.Assert((manifest.Id == "nativegame") && (manifest.Name == "Native Game") && (manifest.Version == "0.1.0"));
		Test.Assert(manifest.EngineVersion == scope $"{EngineVersion.Major}.{EngineVersion.Minor}");
		Test.Assert((manifest.Parts.Count == 1) && manifest.HasPart(.Engine));
		Test.Assert((manifest.FindPlatform("Linux64") != null) && (manifest.FindPlatform("Win64") != null) && (manifest.FindPlatform("Web") != null));

		let partProject = Read(PathJoin(package, "NativeGame.Engine/BeefProj.toml", .. scope .()), .. scope .());
		Test.Assert(partProject.Contains("Name = \"NativeGame.Engine\"") && partProject.Contains("\"Sedulous.Runtime\" = \"*\""), partProject);
		let source = Read(PathJoin(package, "NativeGame.Engine/src/NativeGameEngine.bf", .. scope .()), .. scope .());
		Test.Assert(source.Contains("namespace NativeGame;") && source.Contains("class NativeGameEnginePart : PluginPart"), source);
		Test.Assert(source.Contains("public override StringView PluginId => \"nativegame\";"), source);
		Test.Assert(source.Contains("PluginRegistry.Register(new NativeGameEnginePart());") && !source.Contains("@T@"), source);

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
	}

	/// It never overwrites the game's code: a project that already enables the id, or holds the
	/// folder, is refused and left as it was.
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
		Test.Assert(GamePackage.Scaffold(project) case .Ok);
		let source = PathJoin(dir, "Plugins/Game/Game.Engine/src/GameEngine.bf", .. scope .());
		let edited = "// the game's own code\n";
		Test.Assert(WriteFile(source, .((uint8*)edited.Ptr, edited.Length)) case .Ok);
		Test.Assert(GamePackage.Scaffold(project) case .Err(.AlreadyExists), "enabled already");

		let entry = project.Settings.FindPlugin("game");
		project.Settings.Plugins.Remove(entry);
		delete entry;
		Test.Assert(GamePackage.Scaffold(project) case .Err(.AlreadyExists), "the folder is there");
		Test.Assert(project.Settings.Plugins.IsEmpty, "no entry added for a refusal");
		Test.Assert(Read(source, .. scope .()) == edited, "the game's code untouched");
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
}
