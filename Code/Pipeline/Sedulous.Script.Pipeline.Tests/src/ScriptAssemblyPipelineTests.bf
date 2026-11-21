using System;
using System.Collections;
using System.IO;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.Script.Resource;
using Sedulous.VFS;

namespace Sedulous.Script.Pipeline.Tests;

/// A stand-in project build: the image is the paths of the sources it was given, and each
/// source's "class X" is a class with an onUpdate handler. A project file saying "broken" does
/// not build.
class StandInAssemblyCook : IScriptAssemblyCook
{
	public StringView ProjectExtension => "siproj";
	public StringView SourceExtension => "si";

	public bool Build(StringView projectPath, StringView project, Span<ScriptAssemblyFile> sources, ScriptAssemblySource outAssembly,
		List<String> problems)
	{
		if (project.Contains("broken"))
		{
			problems.Add(new String("Broken.si:3: does not build"));
			return false;
		}
		for (let file in sources)
		{
			for (int i < file.Path.Length)
				outAssembly.Image.Add((uint8)file.Path[i]);
			outAssembly.Image.Add((uint8)';');
			let at = file.Text.IndexOf("class ");
			if (at < 0)
				continue;
			let declared = new ScriptAssemblyClass();
			declared.ClassName.Set(StringView(file.Text, at + 6));
			declared.Handlers.Add(new String("onUpdate"));
			outAssembly.Classes.Add(declared);
		}
		return true;
	}

	public void NewProjectTemplate(StringView name, String outText)
	{
		outText.AppendF("project {}", name);
	}

	public void LocalFiles(List<ScriptAssemblyFile> outFiles)
	{
		let file = outFiles.Add(.. new ScriptAssemblyFile());
		file.Path.Set("obj/Local.txt");
		file.Text.Set("this machine");
	}
}

/// The stand-in language's class cook: its classes build in their project, so a class cooks
/// from the assembly, named by its source's "class X". It compiles nothing itself.
class StandInClassCook : IScriptLanguageCook
{
	/// Nought, so the class builder's version stays the shell's plus the other cooks'.
	public int32 CookVersion => 0;

	public void NewAssetTemplate(ScriptTier tier, StringView className, String outSource)
	{
		outSource.AppendF("class {}", className);
	}

	public bool Cook(StringView source, StringView sourceName, BehaviorClassSource outRecord, List<String> problems,
		IScriptIncludeReader includes = null) => false;

	public bool Check(StringView source, StringView sourceName, String outClassName, List<String> problems, Span<StringView> hidden,
		IScriptIncludeReader includes = null) => true;

	public bool BuildsInAssembly => true;

	public bool CookFromAssembly(StringView source, StringView sourceName, ScriptAssemblySource assembly,
		BehaviorClassSource outRecord, List<String> problems)
	{
		let at = source.IndexOf("class ");
		let name = (at < 0) ? StringView() : StringView(source, at + 6);
		let declared = assembly.FindClass(name);
		if (declared == null)
		{
			problems.Add(new String(scope $"{sourceName}: not in the assembly"));
			return false;
		}
		outRecord.Language.Set(ScriptAssemblyPipelineTests.cLanguage);
		outRecord.ClassName.Set(declared.ClassName);
		for (let handler in declared.Handlers)
			outRecord.Handlers.Add(new String(handler));
		return true;
	}
}

/// A language whose classes build together into their project's assembly, through the neutral
/// builders, with a stand-in language (so these are the pipeline's rules, not a compiler's): the
/// project builds from every source of its language under its folder (sorted, an IDE's bin and obj
/// passed over, a file of another language left out), and its sources are the build's inputs; a
/// class finds its project (the nearest when they nest), reads its cooked assembly, takes its
/// description from it and names it; a class in no project, or whose project has not built, fails
/// its cook; a project file imports as the project of its language, and File > New makes one.
static class ScriptAssemblyPipelineTests
{
	public const String cLanguage = "stand-in";
	internal const String cClassType = "Sedulous.Script.Resource.BehaviorClassSource";
	internal const String cAssemblyType = "Sedulous.Script.Resource.ScriptAssemblySource";

	private static bool sRegistered = false;

	internal static void Registered()
	{
		if (sRegistered)
			return;
		ScriptResources.RegisterAll();
		ScriptPipeline.RegisterAll();
		ScriptAssemblyCooks.Register(cLanguage, new StandInAssemblyCook());
		ScriptLanguageCooks.Register(cLanguage, "si", new StandInClassCook());
		sRegistered = true;
	}

	/// A project tree: its sources, the source database its assets live in, and the cooked one.
	private class Bed
	{
		public String Root = new .() ~ delete _;
		public String Src = new .() ~ delete _;
		public NativeFileSystem Sources ~ delete _;
		private NativeFileSystem mSourceMount ~ delete _;
		private NativeFileSystem mOutputMount ~ delete _;
		private SerializerFactory mSerializers ~ delete _;
		public ContentDatabase SourceDb ~ delete _;
		public ContentDatabase OutputDb ~ delete _;
		private int mCooked = 0;

		public this(StringView root)
		{
			ScriptAssemblyPipelineTests.Registered();
			Root.Set(root);
			RemoveDirectoryRecursive(Root);
			Test.Assert(CreateDirectory(Root));
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), scope $"{root}/src", Src);
			let db = scope $"{root}/db";
			let output = scope $"{root}/out";
			for (let folder in scope StringView[](Src, db, output))
				Test.Assert(CreateDirectory(folder));
			Sources = new NativeFileSystem(Src);
			mSourceMount = new NativeFileSystem(db);
			mOutputMount = new NativeFileSystem(output);
			mSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			SourceDb = new ContentDatabase(mSourceMount, mSerializers, "asset");
			OutputDb = new ContentDatabase(mOutputMount, mSerializers, "rasset");
		}

		public ~this()
		{
			// The databases before the mounts they read.
			delete OutputDb;
			OutputDb = null;
			delete SourceDb;
			SourceDb = null;
			RemoveDirectoryRecursive(Root);
		}

		public void Write(StringView path, StringView text)
		{
			Test.Assert(Sources.Save(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
		}

		public String Read(StringView path, String outText)
		{
			outText.Clear();
			File.ReadAllText(PathJoin(Src, path, .. scope .()), outText).IgnoreError();
			return outText;
		}

		public Instance AddProject(StringView name, StringView file)
		{
			let asset = scope ScriptAssemblyAsset();
			asset.FileName.Set(file);
			asset.Language.Set(ScriptAssemblyPipelineTests.cLanguage);
			let instance = SourceDb.RootGroup.CreateInstance(name, ScriptAssemblies.cAssetType);
			Test.Assert(instance != null);
			Test.Assert(instance.WriteObject(asset) case .Ok);
			return instance;
		}

		/// A build's context: the sources, both databases, the output.
		public void Context(AssetBuildContext context, Instance output)
		{
			context.Sources = Sources;
			context.SourceDatabase = SourceDb;
			context.Database = OutputDb;
			context.Output = output;
		}

		/// The project's product, written where a class's cook looks for it: its asset's id.
		public Result<void, ErrorCode> BuildProject(Instance project)
		{
			var product = OutputDb.GetInstance(project.Id);
			if (product == null)
				product = OutputDb.RootGroup.CreateInstanceWithId(project.Id, project.Name, ScriptAssemblyPipelineTests.cAssemblyType);
			let object = project.ReadObject();
			defer delete object;
			let context = scope AssetBuildContext();
			Context(context, product);
			let builder = scope ScriptAssemblyAssetBuilder();
			return builder.Build((ScriptAssemblyAsset)object, context);
		}

		/// The project's cooked record; null when it has none. The caller deletes it.
		public ScriptAssemblySource BuiltProject(Instance project)
		{
			let product = OutputDb.GetInstance(project.Id);
			if (product == null)
				return null;
			let object = product.ReadObject();
			let built = object as ScriptAssemblySource;
			if (built == null)
				delete object;
			return built;
		}

		/// Cooks the class at `file` into `outRecord`; with `deps`, scans it first as the cook
		/// driver does, the source database as the scan context's Database.
		public Result<void, ErrorCode> CookClass(StringView file, BehaviorClassSource outRecord, AssetDependencies deps = null)
		{
			let asset = scope ScriptClassAsset();
			asset.FileName.Set(file);
			asset.Language.Set(ScriptAssemblyPipelineTests.cLanguage);
			let product = OutputDb.RootGroup.CreateInstance(scope $"class{mCooked++}", ScriptAssemblyPipelineTests.cClassType);
			let builder = scope ScriptClassAssetBuilder();
			if (deps != null)
			{
				let scan = scope AssetBuildContext();
				scan.Sources = Sources;
				scan.Database = SourceDb;
				builder.ScanDependencies(asset, scan, deps);
			}
			let context = scope AssetBuildContext();
			Context(context, product);
			let built = builder.Build(asset, context);
			if (built case .Ok)
			{
				let object = product.ReadObject();
				defer delete object;
				let cooked = object as BehaviorClassSource;
				Test.Assert(cooked != null);
				outRecord.ClassName.Set(cooked.ClassName);
				ClearAndDeleteItems!(outRecord.Handlers);
				for (let handler in cooked.Handlers)
					outRecord.Handlers.Add(new String(handler));
				outRecord.Source.Set(cooked.Source);
				outRecord.Assembly = cooked.Assembly;
			}
			return built;
		}
	}

	private static StringView ImageText(ScriptAssemblySource assembly) => StringView((char8*)assembly.Image.Ptr, assembly.Image.Count);

	private static bool IsNotFound(Result<void, ErrorCode> result)
	{
		if (result case .Err(let error))
			return error == .NotFound;
		return false;
	}

	[Test]
	public static void AProjectBuildsEverySourceUnderItsFolderAndItsClassesCookFromIt()
	{
		let bed = scope Bed("scratch_scriptassembly");
		bed.Write("Game/Game.siproj", "project");
		bed.Write("Game/Player.si", "class Player");
		bed.Write("Game/Enemies/Wolf.si", "class Wolf");
		bed.Write("Game/Helpers.si", "helpers, no class");
		bed.Write("Game/bin/Stale.si", "class Stale"); // an IDE's build output: not a source
		bed.Write("Game/Notes.txt", "class Notes"); // another language's file
		bed.Write("Tools/Tools.siproj", "project");
		bed.Write("Tools/Inner/Inner.siproj", "project");
		bed.Write("Tools/Inner/Deep.si", "class Deep");
		bed.Write("Loose.si", "class Loose"); // in no project
		let game = bed.AddProject("Game", "Game/Game.siproj");
		let tools = bed.AddProject("Tools", "Tools/Tools.siproj");
		let inner = bed.AddProject("Inner", "Tools/Inner/Inner.siproj");

		// The sources a project builds from are its inputs, sorted.
		{
			let object = game.ReadObject();
			defer delete object;
			let context = scope AssetBuildContext();
			bed.Context(context, null);
			let deps = scope AssetDependencies();
			let builder = scope ScriptAssemblyAssetBuilder();
			builder.ScanDependencies((ScriptAssemblyAsset)object, context, deps);
			Test.Assert(deps.Files.Count == 3, scope $"{deps.Files.Count} inputs");
			Test.Assert(deps.Files[0].Value == "Game/Enemies/Wolf.si");
			Test.Assert(deps.Files[1].Value == "Game/Helpers.si");
			Test.Assert(deps.Files[2].Value == "Game/Player.si");
		}
		Test.Assert(bed.BuildProject(game) case .Ok);
		{
			let built = bed.BuiltProject(game);
			Test.Assert(built != null);
			defer delete built;
			Test.Assert(built.Language == cLanguage);
			Test.Assert(ImageText(built) == "Game/Enemies/Wolf.si;Game/Helpers.si;Game/Player.si;");
			Test.Assert(built.FindClass("Wolf") != null);
		}

		// A class reads its project (which cooks first) and names it; its description is the build's.
		let player = scope BehaviorClassSource();
		let deps = scope AssetDependencies();
		Test.Assert(bed.CookClass("Game/Player.si", player, deps) case .Ok);
		Test.Assert((deps.Reads.Count == 1) && (deps.Reads[0] == game.Id), "the scan finds the class's project");
		Test.Assert((deps.References.Count == 1) && (deps.References[0] == game.Id));
		Test.Assert(deps.Files.IsEmpty);
		Test.Assert(player.Assembly == game.Id);
		Test.Assert(player.ClassName == "Player");
		Test.Assert((player.Handlers.Count == 1) && (player.Handlers[0] == "onUpdate"));
		Test.Assert(player.Source == "class Player", "the record keeps its source");

		// Nested projects: the nearest holds the file.
		Test.Assert(bed.BuildProject(inner) case .Ok);
		let deep = scope BehaviorClassSource();
		Test.Assert(bed.CookClass("Tools/Inner/Deep.si", deep) case .Ok);
		Test.Assert(deep.Assembly == inner.Id);
		Test.Assert(deep.Assembly != tools.Id);

		// In no project, or in one that has not built: the cook fails.
		let loose = scope BehaviorClassSource();
		Test.Assert(IsNotFound(bed.CookClass("Loose.si", loose)));
		bed.Write("Tools/Tool.si", "class Tool");
		let tool = scope BehaviorClassSource();
		Test.Assert(IsNotFound(bed.CookClass("Tools/Tool.si", tool)));
	}

	[Test]
	public static void AProjectThatDoesNotBuildWritesNothingAndItsFileImportsAsItsLanguagesProject()
	{
		let bed = scope Bed("scratch_scriptassembly_broken");
		bed.Write("Game/Game.siproj", "broken");
		bed.Write("Game/Player.si", "class Player");
		let game = bed.AddProject("Game", "Game/Game.siproj");
		Test.Assert(bed.BuildProject(game) case .Err);
		let built = bed.BuiltProject(game);
		Test.Assert(built == null, "nothing written");
		delete built;

		let importer = scope ScriptAssemblyFileImporter();
		Test.Assert(importer.Accepts("siproj"));
		Test.Assert(!importer.Accepts("si"));
		Test.Assert(importer.AssetTypeName("Game.siproj") == ScriptAssemblies.cAssetType);
	}

	/// A project's local files (this machine's, for an IDE) are written beside it when it is made
	/// and at each cook, again when they are no longer what the cook would write, and are never an
	/// input to its build.
	[Test]
	public static void AProjectsLocalFilesAreWrittenBesideItWhenItIsMadeAndAtEachCook()
	{
		let bed = scope Bed("scratch_scriptassembly_local");
		let text = scope String();

		// Made: the project file from its build's template in the project's code folder (its file
		// name Code/Made.siproj) and, beside it, the local files; nothing under the sources folder.
		let code = PathJoin(Directory.GetCurrentDirectory(.. scope .()), scope $"{bed.Root}/code", .. scope .());
		String ReadAt(StringView path, String outText)
		{
			outText.Clear();
			File.ReadAllText(PathJoin(code, path, .. scope .()), outText).IgnoreError();
			return outText;
		}
		let made = ScriptCreators.CreateProject(.(null, bed.SourceDb.RootGroup, bed.Src, "Made", default, code), cLanguage, "siproj");
		Test.Assert(made != null);
		Test.Assert(made.TypeName == ScriptAssemblies.cAssetType);
		Test.Assert(ReadAt("Made.siproj", text) == "project Made");
		Test.Assert(ReadAt("obj/Local.txt", text) == "this machine");
		Test.Assert(!File.Exists(PathJoin(bed.Src, "Made.siproj", .. scope .())));
		{
			let object = made.ReadObject();
			defer delete object;
			let asset = object as ScriptAssemblyAsset;
			Test.Assert((asset != null) && (asset.FileName.Value == "Code/Made.siproj"));
		}
		// Made in a group: in that group's folder under Code/, its local files beside it.
		let tools = bed.SourceDb.RootGroup.CreateGroup("Tools");
		let grouped = ScriptCreators.CreateProject(.(tools, bed.SourceDb.RootGroup, bed.Src, "Builder", default, code), cLanguage, "siproj");
		Test.Assert(grouped != null);
		{
			let object = grouped.ReadObject();
			defer delete object;
			let asset = object as ScriptAssemblyAsset;
			Test.Assert((asset != null) && (asset.FileName.Value == "Code/Tools/Builder.siproj"));
		}
		Test.Assert(ReadAt("Tools/Builder.siproj", text) == "project Builder");
		Test.Assert(ReadAt("Tools/obj/Local.txt", text) == "this machine");

		// Cooked: written beside the project's file, and written again when another machine's (or
		// an edit) is there.
		bed.Write("Game/Game.siproj", "project");
		bed.Write("Game/Player.si", "class Player");
		let game = bed.AddProject("Game", "Game/Game.siproj");
		Test.Assert(bed.BuildProject(game) case .Ok);
		Test.Assert(bed.Read("Game/obj/Local.txt", text) == "this machine");
		bed.Write("Game/obj/Local.txt", "another machine");
		Test.Assert(bed.BuildProject(game) case .Ok);
		Test.Assert(bed.Read("Game/obj/Local.txt", text) == "this machine");

		// Never an input: the project still builds only its sources.
		let built = bed.BuiltProject(game);
		Test.Assert(built != null);
		defer delete built;
		Test.Assert(ImageText(built) == "Game/Player.si;");
	}

	/// File > New has a project creator for a language whose classes build together, beside its
	/// three class creators, and it makes the project's asset.
	[Test]
	public static void ALanguageThatBuildsInAProjectGetsAProjectCreator()
	{
		let bed = scope Bed("scratch_scriptassembly_creator");
		let creators = scope AssetCreatorRegistry();
		ScriptCreators.Register(creators);
		let languages = scope List<String>();
		defer { ClearAndDeleteItems!(languages); }
		ScriptLanguageCooks.CollectLanguages(languages);
		int projectLanguages = 0;
		for (let language in languages)
		{
			if (ScriptAssemblyCooks.Find(language) != null)
				projectLanguages++;
		}
		Test.Assert(projectLanguages >= 1);
		Test.Assert(creators.Count == ScriptCreators.CountFor(languages.Count, projectLanguages), scope $"{creators.Count} creators");
		let creator = creators.FindByLabel(scope $"{cLanguage} Project");
		Test.Assert(creator != null);
		let instance = creator.Create(null, bed.SourceDb.RootGroup, bed.Src);
		Test.Assert((instance != null) && (instance.TypeName == ScriptAssemblies.cAssetType));
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as ScriptAssemblyAsset;
		Test.Assert(asset != null);
		// Code, with no code folder given: a folder Code under the sources.
		Test.Assert((asset.Language == cLanguage) && (asset.FileName.Value == "Code/Game.siproj"));
		let text = scope String();
		Test.Assert(bed.Read("Code/Game.siproj", text) == "project Game");
	}
}
