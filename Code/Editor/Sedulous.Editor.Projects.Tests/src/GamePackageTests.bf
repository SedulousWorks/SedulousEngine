using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.VFS;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Projects.Tests;

/// Add Native Code's scaffold over a project's directory and settings: the texts it writes into
/// Code/ and the workspace, the NativeSample shape, and the parts a package gains.
class GamePackageTests
{
	private const String cRoot = "scratch_game_package";

	private static void Read(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
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
		Test.Assert(ProjectScaffold.Create(dir, "Game") case .Ok);
		Test.Assert(CreateDirectory(PathJoin(dir, "Code", .. scope .())));
		let ignore = "# mine\n";
		let space = "FileVersion = 1\n\n[Workspace]\nStartupProject = \"Mine\"\n\n[Projects]\n\"Mine\" = {Path = \"Mine\"}\n";
		Test.Assert(WriteFile(PathJoin(dir, "Code/.gitignore", .. scope .()), .((uint8*)ignore.Ptr, ignore.Length)) case .Ok);
		Test.Assert(WriteFile(PathJoin(dir, "Code/BeefSpace.toml", .. scope .()), .((uint8*)space.Ptr, space.Length)) case .Ok);
		let settings = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(scope NativeFileSystem(dir), settings) case .Ok);
		Test.Assert(GamePackage.Scaffold(dir, settings, scope PluginPartKind[](.Engine)) case .Ok);
		Test.Assert(Read(PathJoin(dir, "Code/.gitignore", .. scope .()), .. scope .()) == ignore, "the user's .gitignore");
		let merged = Read(PathJoin(dir, "Code/BeefSpace.toml", .. scope .()), .. scope .());
		Test.Assert(merged.StartsWith(scope $"{space}\"Game\" = {{Path = \"Game\"}}\n"), merged);
		Test.Assert(merged.Contains("StartupProject = \"Mine\"") && !merged.Contains("StartupProject = \"GameEditor\""), merged);
	}

	/// NativeSample is the scaffold's shape: its manifest in Code/ names its Engine part, and its
	/// project enables the package as Code.
	[Test]
	public static void NativeSampleEnablesItsOwnPackage()
	{
		const String cManifest = Compiler.ReadText("../../../Data/SampleProjects/NativeSample/Code/Plugin.xml");
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
		Test.Assert((entry != null) && (entry.Path == "Code") && entry.Platforms.IsEmpty && entry.Settings.IsEmpty);
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
		Test.Assert(ProjectScaffold.Create(dir, "Game") case .Ok);
		let settings = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(scope NativeFileSystem(dir), settings) case .Ok);
		let info = scope GamePackageInfo();
		Test.Assert(!GamePackage.Find(dir, settings, info) && (info.Path == "Code") && (info.Id == "game"));
		Test.Assert(GamePackage.Scaffold(dir, settings, scope PluginPartKind[](.Engine)) case .Ok);
		Test.Assert(GamePackage.Scaffold(dir, settings, scope PluginPartKind[](.Editor, .Engine, .Pipeline)) case .Ok);
		Test.Assert(GamePackage.Find(dir, settings, info));
		Test.Assert((info.Parts.Count == 3) && (info.Parts[0] == .Engine) && (info.Parts[1] == .Pipeline) && (info.Parts[2] == .Editor));
		Test.Assert(settings.Plugins.Count == 1, "one entry");

		let manifest = scope PluginManifest();
		Test.Assert(PluginManifest.Load(PathJoin(dir, "Code", .. scope .()), manifest) case .Ok);
		Test.Assert((manifest.Parts[0].Kind == "Engine") && (manifest.Parts[1].Kind == "Pipeline") && (manifest.Parts[2].Kind == "Editor"));
		let pipelineProject = Read(PathJoin(dir, "Code/Game.Pipeline/BeefProj.toml", .. scope .()), .. scope .());
		Test.Assert(pipelineProject.Contains("Name = \"Game.Pipeline\"") && pipelineProject.Contains("\"Sedulous.Pipeline.Importer\" = \"*\""), pipelineProject);
		let pipelineSource = Read(PathJoin(dir, "Code/Game.Pipeline/src/GamePipeline.bf", .. scope .()), .. scope .());
		Test.Assert(pipelineSource.Contains("using Sedulous.Pipeline.Importer;") && pipelineSource.Contains("context.Find<PipelinePluginServices>()"), pipelineSource);
		Test.Assert(pipelineSource.Contains("public override PluginPartKind Kind => .Pipeline;") && pipelineSource.Contains("class GamePipelinePart"), pipelineSource);
		// The tiers and the starter behaviour are the Engine part's alone.
		Test.Assert(!pipelineProject.Contains("Sedulous.Engine.Gameplay") && !pipelineSource.Contains("EnginePluginServices"), pipelineSource);
		Test.Assert(!FileExists(PathJoin(dir, "Code/Game.Pipeline/src/Rotator.bf", .. scope .())) && FileExists(PathJoin(dir, "Code/Game/src/Rotator.bf", .. scope .())));
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
		ProjectBuild.Packages(dir, settings, packages, problems);
		Test.Assert((packages.Count == 1) && (packages[0].Parts.Count == 3) && problems.IsEmpty);
		Test.Assert(GamePackage.Scaffold(dir, settings, scope PluginPartKind[](.Pipeline, .Editor)) case .Err(.AlreadyExists), "all there");
	}
}
