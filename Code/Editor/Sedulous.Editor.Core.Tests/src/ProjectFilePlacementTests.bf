using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Render.Pipeline;
using Sedulous.Script.Pipeline;
using Sedulous.Script.Resource;

namespace Sedulous.Editor.Core.Tests;

/// An asset whose file names the files that go with it, one per line, as a .gltf names its
/// buffers and images.
[Serializable]
class CompanionedAsset : Asset
{
	public override void CompanionFiles(StringView fileOnDisk, List<String> outFiles)
	{
		let text = scope String();
		if (File.ReadAllText(fileOnDisk, text) case .Err)
			return;
		for (let line in text.Split('\n'))
		{
			if (!line.IsEmpty)
				outFiles.Add(new String(line));
		}
	}
}

/// A code language for the adoption test alone ("ad" files): its importer is the script one, which
/// imports code; it compiles nothing.
class AdoptedLanguageCook : IScriptLanguageCook
{
	public void NewAssetTemplate(ScriptTier tier, StringView className, String outSource)
	{
		outSource.AppendF("class {}", className);
	}

	public bool Cook(StringView source, StringView sourceName, BehaviorClassSource outRecord, List<String> problems,
		IScriptIncludeReader includes = null) => false;

	public bool Check(StringView source, StringView sourceName, String outClassName, List<String> problems, Span<StringView> hidden,
		IScriptIncludeReader includes = null) => true;

	/// Its declarations take the language's own extension, as a language's may.
	public StringView DeclarationsFile => "engine.d.ad";
}

/// A project's files follow its asset groups: Sources/<group>/, Code/<group>/ for code.
static class ProjectFilePlacementTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	private static void WriteText(StringView path, StringView text)
	{
		Test.Assert(CreateDirectory(PathParent(path, .. scope .())));
		Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	/// The file an instance's asset names, appended.
	private static void FileNameOf(Instance instance, String outFileName)
	{
		let object = instance.ReadObject();
		Test.Assert(object != null);
		defer delete object;
		if (let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset)
			outFileName.Append(asset.FileName.Value);
	}

	/// A file-backed asset `asset` named `name` in `group`, naming `file`.
	private static Guid Add<T>(Group group, StringView name, T asset, StringView file) where T : Asset, ISerializable
	{
		let instance = group.CreateInstance(name, typeof(T).GetFullName(.. scope .()));
		Test.Assert(instance != null);
		asset.FileName.Set(file);
		Test.Assert(instance.WriteObject(asset) case .Ok);
		return instance.Id;
	}

	/// A project from before its files followed their groups: everything flat under Sources/,
	/// scripts too. Opened, each file moves into its group's folder, code under Code/, and its
	/// asset follows (id kept, the import ledger's origin carried); a folder already at
	/// Sources/Code, which Code/ would hide, is renamed and the asset naming a file in it follows;
	/// opening again moves nothing more.
	[Test]
	public static void AnOlderProjectsFilesMoveIntoTheirGroupsFoldersWhenItOpens()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let dir = Scratch("scratch_editor_code_move", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let sources = PathJoin(dir, ProjectLayout.SourcesDir, .. scope .());
		let code = PathJoin(dir, ProjectLayout.CodeDir, .. scope .());
		let ledger = ImportPaths.ImportLedgerPath(PathJoin(dir, ProjectLayout.CacheDir, .. scope .()), .. scope .());

		Guid heroId, projectId, notesId, tilesId;
		{
			// As an older editor left it: the assets naming files under Sources/, a folder Code
			// there.
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let root = project.SourceDb.RootGroup;
			let quality = root.CreateGroup("Quality");
			Test.Assert(quality != null);
			heroId = Add(root, "Hero", scope ScriptClassAsset(), "Hero.as");
			projectId = Add(root, "Game", scope ScriptAssemblyAsset(), "Game/Game.siproj");
			// A script in the folder Code/ will hide.
			notesId = Add(root, "Notes", scope ScriptClassAsset(), "Code/Notes.as");
			// Not code.
			tilesId = Add(quality, "Tiles", scope RenderQualityAsset(), "Tiles.png");
			WriteText(PathJoin(sources, "Hero.as", .. scope .()), "class Hero {}");
			WriteText(PathJoin(sources, "Game/Game.siproj", .. scope .()), "project");
			WriteText(PathJoin(sources, "Code/Notes.as", .. scope .()), "older");
			WriteText(PathJoin(sources, "Tiles.png", .. scope .()), "png");
			ImportPaths.RecordImportOrigin(ledger, "Hero.as", "/elsewhere/Hero.as");
		}

		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let db = project.SourceDb;
			Test.Assert(FileNameOf(db.GetInstance(heroId), .. scope .()) == "Code/Hero.as");
			Test.Assert(FileExists(PathJoin(code, "Hero.as", .. scope .())));
			Test.Assert(!FileExists(PathJoin(sources, "Hero.as", .. scope .())));
			Test.Assert(ImportPaths.ImportOriginOf(ledger, "Code/Hero.as", .. scope .()) == "/elsewhere/Hero.as", "the origin follows the file");
			// In the root group: Code/ itself (its folder under Sources/, Game/, left empty and gone).
			Test.Assert(FileNameOf(db.GetInstance(projectId), .. scope .()) == "Code/Game.siproj");
			Test.Assert(FileExists(PathJoin(code, "Game.siproj", .. scope .())));
			Test.Assert(!DirectoryExists(PathJoin(sources, "Game", .. scope .())));
			// Not code, in the Quality group: Sources/Quality/.
			Test.Assert(FileNameOf(db.GetInstance(tilesId), .. scope .()) == "Quality/Tiles.png");
			Test.Assert(FileExists(PathJoin(sources, "Quality/Tiles.png", .. scope .())));
			// The older folder, renamed; its script followed it and then moved into Code/ as any
			// other (the renamed folder, left empty, gone).
			Test.Assert(FileNameOf(db.GetInstance(notesId), .. scope .()) == "Code/Notes.as");
			Test.Assert(FileExists(PathJoin(code, "Notes.as", .. scope .())));
			Test.Assert(!DirectoryExists(PathJoin(sources, "Code", .. scope .())));
			Test.Assert(!DirectoryExists(PathJoin(sources, "Code.moved", .. scope .())));
			Test.Assert(project.SourceFile("Code/Hero.as", .. scope .()) == PathJoin(code, "Hero.as", .. scope .()));
		}

		// Again: nothing left to move.
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		Test.Assert(FileNameOf(project.SourceDb.GetInstance(heroId), .. scope .()) == "Code/Hero.as");
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](project.SourceDb.GetInstance(heroId), project.SourceDb.GetInstance(tilesId))) == 0);
	}

	/// Files follow their groups: a move into another group moves the file into that group's
	/// folder (made when missing, the old one removed once empty), a file assets in two groups
	/// share stays where it is until they agree, and a name already taken in the folder takes the
	/// next free one.
	[Test]
	public static void AnAssetsFileFollowsItIntoItsGroupsFolder()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let dir = Scratch("scratch_editor_group_folders", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let sources = project.SourcesRoot(.. scope .());
		let root = project.SourceDb.RootGroup;
		let a = root.CreateGroup("A");
		let b = root.CreateGroup("B");
		WriteText(PathJoin(sources, "A/Lone.png", .. scope .()), "lone");
		WriteText(PathJoin(sources, "Shared.png", .. scope .()), "shared");
		WriteText(PathJoin(sources, "B/Lone.png", .. scope .()), "B's own"); // B's folder already has a Lone.png
		let lone = project.SourceDb.GetInstance(Add(a, "Lone", scope RenderQualityAsset(), "A/Lone.png"));
		let sharedA = project.SourceDb.GetInstance(Add(a, "SharedA", scope RenderQualityAsset(), "Shared.png"));
		let sharedB = project.SourceDb.GetInstance(Add(b, "SharedB", scope RenderQualityAsset(), "Shared.png"));

		// Moved to B: the file follows, beside B's own Lone.png under the next free name; A's
		// folder, empty now, goes.
		Test.Assert(project.SourceDb.MoveInstance(lone.Id, b) case .Ok);
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](lone)) == 1);
		Test.Assert(FileNameOf(lone, .. scope .()) == "B/Lone.2.png");
		Test.Assert(FileExists(PathJoin(sources, "B/Lone.2.png", .. scope .())));
		Test.Assert(FileExists(PathJoin(sources, "B/Lone.png", .. scope .())));
		Test.Assert(!DirectoryExists(PathJoin(sources, "A", .. scope .())));

		// Shared by assets in A and B: stays.
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](sharedA, sharedB)) == 0);
		Test.Assert(FileNameOf(sharedA, .. scope .()) == "Shared.png");
		Test.Assert(FileExists(PathJoin(sources, "Shared.png", .. scope .())));
		// Once both are in B, it follows them there.
		Test.Assert(project.SourceDb.MoveInstance(sharedA.Id, b) case .Ok);
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](sharedA, sharedB)) == 1);
		Test.Assert(FileNameOf(sharedA, .. scope .()) == "B/Shared.png");
		Test.Assert(FileNameOf(sharedB, .. scope .()) == "B/Shared.png");
		Test.Assert(!FileExists(PathJoin(sources, "Shared.png", .. scope .())));
	}

	/// A file's companions (a model's buffers and textures beside it) move with it, keeping their
	/// places relative to it, and an asset naming one follows; one never moves on its own, so a
	/// texture in the model's tex/ folder stays there while its model is in place; and a file
	/// whose companion another file shares stays.
	[Test]
	public static void AFilesCompanionsMoveWithItAndNeverOnTheirOwn()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		TestSerializables.RegisterAll();
		let dir = Scratch("scratch_editor_companions", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let sources = project.SourcesRoot(.. scope .());
		let root = project.SourceDb.RootGroup;
		let crate = root.CreateGroup("Crate");
		WriteText(PathJoin(sources, "Crate/Crate.model", .. scope .()), "Crate.bin\ntex/wood.png\n");
		WriteText(PathJoin(sources, "Crate/Crate.bin", .. scope .()), "bin");
		WriteText(PathJoin(sources, "Crate/tex/wood.png", .. scope .()), "png");
		let model = project.SourceDb.GetInstance(Add(crate, "Crate", scope CompanionedAsset(), "Crate/Crate.model"));
		let wood = project.SourceDb.GetInstance(Add(crate, "wood", scope RenderQualityAsset(), "Crate/tex/wood.png"));

		// In place: the texture in tex/ is the model's, and stays.
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](model, wood)) == 0);
		Test.Assert(FileNameOf(wood, .. scope .()) == "Crate/tex/wood.png");

		// The model's group renamed: the model moves, its companions with it, the texture's asset
		// following.
		Test.Assert(project.SourceDb.RenameGroup(crate, "Box") case .Ok);
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](model, wood)) == 1);
		Test.Assert(FileNameOf(model, .. scope .()) == "Box/Crate.model");
		Test.Assert(FileNameOf(wood, .. scope .()) == "Box/tex/wood.png");
		Test.Assert(FileExists(PathJoin(sources, "Box/Crate.bin", .. scope .())));
		Test.Assert(FileExists(PathJoin(sources, "Box/tex/wood.png", .. scope .())));
		Test.Assert(!DirectoryExists(PathJoin(sources, "Crate", .. scope .())));

		// Two files sharing a companion (flat models naming one texture): neither moves, or the
		// other would lose it.
		let twins = root.CreateGroup("Twins");
		WriteText(PathJoin(sources, "One.model", .. scope .()), "shared.png\n");
		WriteText(PathJoin(sources, "Two.model", .. scope .()), "shared.png\n");
		WriteText(PathJoin(sources, "shared.png", .. scope .()), "png");
		let one = project.SourceDb.GetInstance(Add(twins, "One", scope CompanionedAsset(), "One.model"));
		let two = project.SourceDb.GetInstance(Add(twins, "Two", scope CompanionedAsset(), "Two.model"));
		Test.Assert(project.PlaceInGroupFolders(scope Instance[](one, two)) == 0);
		Test.Assert(FileNameOf(one, .. scope .()) == "One.model");
		Test.Assert(FileExists(PathJoin(sources, "shared.png", .. scope .())));
	}

	/// A script made in an outside editor under Code/ becomes an asset where it lies: in the group
	/// its folder names (made), its file not copied; a second report adopts nothing more; a file no
	/// code importer takes, one outside Code/, one removed, and the language's declarations
	/// written there for an outside editor are left alone.
	[Test]
	public static void NewCodeUnderCodeBecomesAnAssetWhereItLies()
	{
		ScriptPipeline.RegisterAll(); // the script asset, read back
		ScriptLanguageCooks.Register("adopted", "ad", new AdoptedLanguageCook());
		let dir = Scratch("scratch_editor_adopt_code", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let importers = scope ImporterRegistry();
		importers.Register(new ScriptFileImporter());

		let code = project.CodeRoot(.. scope .());
		CreateDirectory(code);
		WriteText(PathJoin(code, "Enemies/Boss.ad", .. scope .()), "class Boss {}");
		WriteText(PathJoin(code, "Notes.txt", .. scope .()), "not code");
		WriteText(PathJoin(code, "engine.d.ad", .. scope .()), "class Declared {}");
		String[5] changed = .("Code/Enemies/Boss.ad", "Code/Notes.txt", "Code/Gone.ad", "Models/Crate.png", "Code/engine.d.ad");
		Test.Assert(project.AdoptNewCode(changed, importers) == 1);
		Test.Assert(project.SourceDb.RootGroup.GetInstance("engine.d") == null, "the declarations are not adopted");

		let enemies = project.SourceDb.RootGroup.GetGroup("Enemies");
		Test.Assert(enemies != null);
		let boss = enemies.GetInstance("Boss");
		Test.Assert(boss != null);
		let object = boss.ReadObject();
		defer delete object;
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ScriptClassAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.FileName.Value == "Code/Enemies/Boss.ad", scope String(asset.FileName.Value));
		Test.Assert(!FileExists(PathJoin(code, "Enemies/Boss.2.ad", .. scope .())), "no copy beside it");

		// Reported again: it is an asset's now.
		Test.Assert(project.AdoptNewCode(changed, importers) == 0);
	}
}
