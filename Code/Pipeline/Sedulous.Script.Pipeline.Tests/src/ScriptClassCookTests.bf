using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using System.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript.Pipeline;
using Sedulous.Script.Fixture;
using Sedulous.Script.Pipeline;
using Sedulous.Script.Resource;
using Sedulous.VFS;

namespace Sedulous.Script.Pipeline.Tests;

/// The cook: a script file to its class record, through the language's cook, into a
/// database a fresh session binds from.
static class ScriptClassCookTests
{
	private const String cRoot = "scratch_script_cook";
	private const String cProductType = "Sedulous.Script.Resource.ScriptClassSource";

	private static ScriptSurface sSurface = null ~ delete _;

	private static void Registered()
	{
		if (sSurface != null)
			return;
		sSurface = new ScriptSurface();
		FixtureSurface.Populate(sSurface);
		AngelScriptCook.Register(sSurface);
		ScriptResources.RegisterAll();
		ScriptPipeline.RegisterAll();
	}

	[Test]
	public static void ACookedClassBindsInAFreshSession()
	{
		Registered();
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }
		CreateDirectory(scope $"{cRoot}/scripts");
		let source = """
			// The mover.
			class Mover
			{
				Entity self;
				[2.5, "How fast"] float speed;
				[3] int lives;
				["m"] string label;
				int plain = 1;
				private int state = 0;
				void onStart() { startCoroutine(ScriptCoroutine(this.run)); }
				void onUpdate(float dt) {}
				void onHit(int damage) {}
				void run() { wait(1); }
			}
			""";
		Test.Assert(File.WriteAllText(scope $"{cRoot}/scripts/Mover.as", source) case .Ok);

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("mover", cProductType);
			id = instance.Id;

			let asset = scope ScriptClassAsset();
			asset.FileName.Set("scripts/Mover.as");
			asset.Language.Set("angelscript");

			let context = scope AssetBuildContext();
			context.Sources = mount;
			context.Output = instance;
			let builder = scope ScriptClassAssetBuilder();
			Test.Assert(builder.Version == 7, "the shell's 6 plus the cook's 1");
			Test.Assert(builder.Build(asset, context) case .Ok, "cooked");
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope ScriptClassFactory();
		manager.AddFactory(factory);
		let proxy = manager.Bind<ScriptClass>(id);
		let product = proxy.Get;
		Test.Assert(product != null, "bound");
		Test.Assert(product.Language == "angelscript");
		Test.Assert(product.ClassName == "Mover", "its only class, found through the comment");
		Test.Assert(product.SourceName == "scripts/Mover.as");
		Test.Assert(product.Source == source);
		Test.Assert(product.Properties.Count == 3, scope $"{product.Properties.Count} properties: the annotated ones, not self, not a plain field, not the private state");
		Test.Assert(product.FindProperty("plain") == null);
		Test.Assert(product.FindProperty("speed").Description == "How fast");
		Test.Assert((product.FindProperty("speed").Type == .Float) && (product.FindProperty("speed").Default.Number == 2.5));
		Test.Assert(product.FindProperty("label").Default.Text == "m");
		Test.Assert(product.HasHandler("onStart") && product.HasHandler("onUpdate") && product.HasHandler("onHit"));
		Test.Assert(!product.HasHandler("run"), "a helper is not a handler");
		Test.Assert(product.UsesCoroutines);
	}

	/// An include resolves against the including file, inside the sources: the builder declares
	/// every included file as a cook input (an edit to one recooks), the record carries them,
	/// and a handler inherited from a class in one is found. The builder read includes from
	/// nowhere and never declared them.
	[Test]
	public static void AnIncludedFileIsACookInputAndTravelsWithTheRecord()
	{
		Registered();
		let root = "scratch_script_include";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer { RemoveDirectoryRecursive(root); }
		CreateDirectory(scope $"{root}/scripts");
		CreateDirectory(scope $"{root}/scripts/lib");
		CreateDirectory(scope $"{root}/common");
		Test.Assert(File.WriteAllText(scope $"{root}/scripts/Player.as",
			"#include \"lib/Base.as\"\nclass Player : Base\n{\n\tint lives = 3;\n}\n") case .Ok);
		Test.Assert(File.WriteAllText(scope $"{root}/scripts/lib/Base.as",
			"#include \"../../common/Math.as\"\nclass Base\n{\n\tint ticks = 0;\n\tvoid onUpdate(float dt) { ticks = twice(ticks); }\n}\n") case .Ok);
		Test.Assert(File.WriteAllText(scope $"{root}/common/Math.as", "int twice(int x) { return x * 2; }\n") case .Ok);

		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("player", cProductType);
		let asset = scope ScriptClassAsset();
		asset.FileName.Set("scripts/Player.as");
		asset.Language.Set("angelscript");
		let context = scope AssetBuildContext();
		context.Sources = mount;
		context.Output = instance;
		let builder = scope ScriptClassAssetBuilder();

		let deps = scope AssetDependencies();
		builder.ScanDependencies(asset, context, deps);
		Test.Assert(deps.Files.Count == 2, scope $"{deps.Files.Count} inputs");
		Test.Assert(builder.Build(asset, context) case .Ok, "cooked");

		let record = instance.ReadObject() as ScriptClassSource;
		Test.Assert(record != null);
		defer delete record;
		Test.Assert(record.Includes.Count == 2);
		Test.Assert(record.Includes[0].Path == "scripts/lib/Base.as");
		Test.Assert(record.Includes[1].Path == "common/Math.as");
		bool inherited = false;
		for (let handler in record.Handlers)
			inherited |= (handler == "onUpdate");
		Test.Assert(inherited, "a handler inherited from the included base");

		// A file that cannot be read, or a path out of the sources, fails the cook and says so.
		let cook = ScriptLanguageCooks.Find("angelscript");
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		let missing = scope ScriptClassSource();
		Test.Assert(!cook.Cook("#include \"lib/Nope.as\"\nclass Player {}\n", "scripts/Player.as", "", missing, problems, scope FolderIncludeReader(root)));
		Test.Assert(!problems.IsEmpty && problems.Back.Contains("scripts/lib/Nope.as"), problems.IsEmpty ? "" : problems.Back);
		Test.Assert(!cook.Cook("#include \"../../outside.as\"\nclass Player {}\n", "scripts/Player.as", "", missing, problems, scope FolderIncludeReader(root)));
		Test.Assert(problems.Back.Contains("leaves"), problems.Back);
	}

	[Test]
	public static void AnIncludeResolvesAgainstItsFileInsideTheSources()
	{
		let path = scope String();
		Test.Assert(ScriptIncludes.Resolve("Scripts/Player.as", "Lib/Math.as", path) && (path == "Scripts/Lib/Math.as"));
		Test.Assert(ScriptIncludes.Resolve("Scripts/A/b.as", "../Common.as", path) && (path == "Scripts/Common.as"));
		Test.Assert(ScriptIncludes.Resolve("Player.as", "./x\\y.as", path) && (path == "x/y.as"));
		Test.Assert(!ScriptIncludes.Resolve("Player.as", "../x.as", path), "out of the sources");
		Test.Assert(!ScriptIncludes.Resolve("Player.as", "/x.as", path), "absolute");
		Test.Assert(!ScriptIncludes.Resolve("Player.as", "C:x.as", path), "a drive");
		Test.Assert(!ScriptIncludes.Resolve("Player.as", "", path));
	}

	[Test]
	public static void ABrokenScriptDoesNotCookAndSaysWhere()
	{
		Registered();
		let cook = ScriptLanguageCooks.Find("angelscript");
		Test.Assert(cook != null);
		let record = scope ScriptClassSource();
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		Test.Assert(!cook.Cook("class Broken { void onStart() { Nope(); } }", "Broken.as", "", record, problems));
		Test.Assert(!problems.IsEmpty && problems[0].Contains("Broken.as"), problems[0]);

		// Several classes and none named as asked is a failure naming them, not a guess.
		ClearAndDeleteItems(problems);
		Test.Assert(!cook.Cook("class Fine {}\nclass Also {}\n", "Fine.as", "Other", record, problems));
		Test.Assert(problems.Back.Contains("'Other'") && problems.Back.Contains("Fine, Also"), problems.Back);

		// A script reaching beyond the surface it is cooked against is refused here.
		ClearAndDeleteItems(problems);
		Test.Assert(!cook.Cook("class Reach { void onStart() { PhysicsSceneSystem@ p; } }", "Reach.as", "", record, problems));

		// An annotated field of a type a property cannot be is refused, by name, rather than
		// silently dropped; so is a Guid without its asset tag.
		ClearAndDeleteItems(problems);
		Test.Assert(!cook.Cook("class Odd { [0] array<int> list; }", "Odd.as", "", record, problems));
		Test.Assert(problems.Back.Contains("Odd.as") && problems.Back.Contains("'list'") && problems.Back.Contains("unsupported"), problems.Back);
		ClearAndDeleteItems(problems);
		Test.Assert(!cook.Cook("class Untagged { [null] Guid clip; }", "Untagged.as", "", record, problems));
		Test.Assert(problems.Back.Contains("'clip'"), problems.Back);
	}

	/// What the editor checks as a script is typed: a compile as the cook's, with nothing in
	/// the source run and nothing harvested. Neither runs script: a global initializer's fault
	/// is the game's to meet when it loads the script, under the call budget.
	[Test]
	public static void ACheckCompilesWithoutRunningTheScript()
	{
		Registered();
		let cook = ScriptLanguageCooks.Find("angelscript");
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		// An initializer that faults when run; the check and the cook pass it.
		let faulting = """
			int Zero() { return 0; }
			int boom = 10 / Zero();
			class Mover
			{
				[4.5] float speed;
			}
			""";
		let className = scope String();
		Test.Assert(cook.Check(faulting, "Mover.as", "", className, problems, default), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(className == "Mover");
		Test.Assert(problems.IsEmpty);
		let record = scope ScriptClassSource();
		Test.Assert(cook.Cook(faulting, "Mover.as", "", record, problems), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(record.ClassName == "Mover");

		// A compile error still fails it, where it is.
		ClearAndDeleteItems(problems);
		Test.Assert(!cook.Check("class Broken { void onStart() { Nope(); } }", "Broken.as", "", className, problems, default));
		Test.Assert(className.IsEmpty);
		Test.Assert(!problems.IsEmpty && problems.Back.StartsWith("Broken.as(1,"), problems.IsEmpty ? "" : problems.Back);
	}

	/// Checks share one runtime, each script in a module of its own: every check bound the whole
	/// surface into a new runtime, about half a second, for a compile of a few milliseconds.
	[Test]
	public static void ChecksShareOneRuntimeEachScriptInAModuleOfItsOwn()
	{
		let surface = scope ScriptSurface();
		FixtureSurface.Populate(surface);
		let cook = scope AngelScriptCook(surface);
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		let className = scope String();
		Test.Assert(cook.CheckRuntimeBuildCount == 0);
		Test.Assert(cook.Check("class Alpha { int x; }\n", "Alpha.as", "Alpha", className, problems, default), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(cook.CheckRuntimeBuildCount == 1);

		// The next checks make no runtime, and see nothing of the scripts checked before them.
		Test.Assert(!cook.Check("class Beta { Alpha@ a; }\n", "Beta.as", "Beta", className, problems, default));
		Test.Assert(!problems.IsEmpty);
		ClearAndDeleteItems(problems);
		Test.Assert(cook.Check("class Alpha { float y; }\n", "Alpha.as", "Alpha", className, problems, default), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(cook.CheckRuntimeBuildCount == 1);

		// A check with types hidden binds a runtime of its own, the shared one kept.
		StringView[1] hidden = .("Fixture.NoSuchType");
		Test.Assert(cook.Check("class Gamma { }\n", "Gamma.as", "Gamma", className, problems, hidden), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(cook.CheckRuntimeBuildCount == 1);

		// The surface changed (a plugin's types joined): it is made again, once.
		surface.AddType("Fixture.Joined", .Enum, ScriptDomains.Runtime);
		Test.Assert(cook.Check("class Alpha { }\n", "Alpha.as", "Alpha", className, problems, default), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(cook.Check("class Alpha { }\n", "Alpha.as", "Alpha", className, problems, default));
		Test.Assert(cook.CheckRuntimeBuildCount == 2);
	}

	/// The API a page's completion and browser read comes from the cook's check runtime for the
	/// surface it checks against, and from nothing for another.
	[Test]
	public static void TheCookDescribesTheApiOfItsOwnSurfaceOnly()
	{
		let surface = scope ScriptSurface();
		FixtureSurface.Populate(surface);
		let cook = scope AngelScriptCook(surface);
		let types = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems!(types); }
		Test.Assert(cook.DescribeApi(surface, types));
		Test.Assert(!types.IsEmpty);
		Test.Assert(cook.CheckRuntimeBuildCount == 1);
		let other = scope ScriptSurface();
		let none = scope List<ScriptApiType>();
		Test.Assert(!cook.DescribeApi(other, none));
		Test.Assert(none.IsEmpty);
	}

	/// A compiler warning is reported as a warning, and the check still passes.
	[Test]
	public static void ACompilerWarningIsReportedAsAWarningAndTheCheckStillPasses()
	{
		Registered();
		let cook = ScriptLanguageCooks.Find("angelscript");
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		let className = scope String();
		Test.Assert(cook.Check("class Shade { int f() { int a = 1; { int a = 2; return a; } } }\n", "Shade.as", "Shade", className, problems, default));
		Test.Assert(problems.Count == 1, problems.IsEmpty ? "" : problems[0]);
		Test.Assert(ScriptProblems.IsWarning(problems[0]), problems[0]);
		Test.Assert(className == "Shade");
	}

	/// A check against a surface without some types (a platform without the plugin that registers
	/// them) fails a script that uses one and passes one that does not; the full surface passes
	/// both, and the types that name a hidden one in a member still bind without that member.
	[Test]
	public static void ACheckWithoutATypeFailsTheScriptThatUsesItAndOnlyThatOne()
	{
		Registered();
		let cook = ScriptLanguageCooks.Find("angelscript");
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		let usesVec2 = """
			class Mover
			{
				float reach() { Vec2 v = Vec2(1, 2); return v.X; }
			}
			""";
		let usesThing = """
			class Holder
			{
				Thing@ held;
			}
			""";
		let hidden = scope StringView[]("Sedulous.Script.Fixture.Vec2");
		let className = scope String();
		Test.Assert(cook.Check(usesVec2, "Mover.as", "", className, problems, default), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(!cook.Check(usesVec2, "Mover.as", "", className, problems, hidden));
		Test.Assert(!problems.IsEmpty && problems.Back.StartsWith("Mover.as(3,"), problems.IsEmpty ? "" : problems.Back);
		ClearAndDeleteItems(problems);
		Test.Assert(cook.Check(usesThing, "Holder.as", "", className, problems, hidden), problems.IsEmpty ? "" : problems[0]);
		Test.Assert(className == "Holder");
		Test.Assert(cook.Check("double twice(double v) { return v * 2.0; }", "Twice.as", "", className, problems, hidden));
		Test.Assert(problems.IsEmpty);
	}

	/// The class scan lists every top-level class in order, comments and strings aside; the
	/// class a script plays is the preferred one (the asset's, else its file's stem), else its
	/// only one; several and none preferred is a problem naming them; none is a utility module.
	[Test]
	public static void TheClassAScriptPlaysIsThePreferredOneOrItsOnlyOneNeverAGuess()
	{
		let two = scope List<String>();
		defer { ClearAndDeleteItems!(two); }
		ScriptClasses.ListClasses("class Helper {\n}\nclass Mover {\n}\n", two);
		Test.Assert((two.Count == 2) && (two[0] == "Helper") && (two[1] == "Mover"));
		let real = scope List<String>();
		defer { ClearAndDeleteItems!(real); }
		ScriptClasses.ListClasses("// class Fake {\n/* class Ghost { */\nstring s = \"class Quoted\";\nclass Real {\n}\n", real);
		Test.Assert((real.Count == 1) && (real[0] == "Real"));

		let several = scope List<String>();
		defer { ClearAndDeleteItems!(several); }
		ScriptClasses.ListClasses("class EffectDef {}\nclass Fighter {}\nclass Battle {}\n", several);
		let played = scope String();
		let problem = scope String();
		Test.Assert(ScriptClasses.Choose(several, "Battle", played, problem) && (played == "Battle") && problem.IsEmpty);
		Test.Assert(!ScriptClasses.Choose(several, "Battle.2", played, problem) && played.IsEmpty, "a copy's stem names none");
		Test.Assert(problem.Contains("EffectDef, Fighter, Battle") && problem.Contains("'Battle.2'"), problem);

		let one = scope List<String>() { "Game" };
		problem.Clear();
		Test.Assert(ScriptClasses.Choose(one, "Lamplight", played, problem) && (played == "Game") && problem.IsEmpty);
		Test.Assert(ScriptClasses.Choose(scope List<String>(), "Twice", played, problem) && played.IsEmpty && problem.IsEmpty);

		// An asset prefers the class it records, else the one named like its file.
		let asset = scope ScriptClassAsset();
		asset.FileName.Set("Battle.2.as");
		Test.Assert(ScriptClasses.Preferred(asset, .. scope .()) == "Battle.2");
		asset.ClassName.Set("Battle");
		Test.Assert(ScriptClasses.Preferred(asset, .. scope .()) == "Battle");
		Test.Assert(ScriptClasses.StarterClassName(.Level, "Mover") == "Level");
		Test.Assert(ScriptClasses.StarterClassName(.Game, "Mover") == "Game");
		Test.Assert(ScriptClasses.StarterClassName(.Behavior, "Mover") == "Mover");
	}

	/// An imported script plays the class its file is named for, wherever its copy lands: kept
	/// beside another file's ("Battle.2.as") it still plays Battle, where the first class
	/// (EffectDef) used to be played. With no class recorded, a file declaring several and none
	/// named like it does not cook; a class set by hand survives a re-import of the same file.
	[Test]
	public static void AnImportedScriptPlaysTheClassItsFileIsNamedForWhereverItsCopyLands()
	{
		Registered();
		let root = "scratch_scriptpipe_import_class";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let sources = PathJoin(root, "Sources", .. scope .());
		let one = PathJoin(root, "one", .. scope .());
		let two = PathJoin(root, "two", .. scope .());
		let dbRoot = PathJoin(root, "db", .. scope .());
		CreateDirectory(root);
		for (let folder in scope StringView[](sources, one, two, dbRoot))
			Test.Assert(CreateDirectory(folder));
		let first = PathJoin(one, "Battle.as", .. scope .());
		let second = PathJoin(two, "Battle.as", .. scope .());
		Test.Assert(File.WriteAllText(first, "class EffectDef { int turns; }\nclass Battle { void onStart() {} }\n") case .Ok);
		Test.Assert(File.WriteAllText(second, "class EffectDef { int turns; }\nclass Fighter { int hp; }\nclass Battle { void onUpdate(float dt) {} }\n") case .Ok);

		let mount = scope NativeFileSystem(dbRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let sourceDb = scope ContentDatabase(mount, serializers, "asset");
		let group = sourceDb.RootGroup;
		let context = scope Sedulous.Pipeline.Importer.ImportContext(sources);
		Sedulous.Pipeline.Importer.ImportPaths.ImportLedgerPath(PathJoin(root, ".cache", .. scope .()), context.LedgerPath);
		let importer = scope ScriptFileImporter();

		ScriptClassAsset AssetOf(Instance instance)
		{
			let object = instance.ReadObject();
			let asset = object as ScriptClassAsset;
			Test.Assert(asset != null);
			return asset;
		}
		let sourcesMount = scope NativeFileSystem(sources);
		let cookedMount = scope NativeFileSystem(PathJoin(root, "cooked", .. scope .()));
		CreateDirectory(PathJoin(root, "cooked", .. scope .()));
		let cooked = scope ContentDatabase(cookedMount, serializers, "rasset");
		let output = cooked.RootGroup.CreateInstance("cooked", cProductType);
		bool CookClass(ScriptClassAsset asset, String outClass)
		{
			let build = scope AssetBuildContext();
			build.Sources = sourcesMount;
			build.Output = output;
			let builder = scope ScriptClassAssetBuilder();
			if (builder.Build(asset, build) case .Err)
				return false;
			let object = output.ReadObject();
			defer delete object;
			if (let record = object as ScriptClassSource)
				outClass.Set(record.ClassName);
			return true;
		}

		Instance made = null;
		if (importer.Import(first, context, group, null, null, null) case .Ok(let instance))
			made = instance;
		Test.Assert(made != null);
		{
			let asset = AssetOf(made);
			defer delete asset;
			Test.Assert(asset.ClassName == "Battle");
		}

		context.OnConflict = .KeepBoth;
		Instance beside = null;
		if (importer.Import(second, context, group, null, null, null) case .Ok(let besideInstance))
			beside = besideInstance;
		Test.Assert(beside != null);
		let kept = AssetOf(beside);
		defer delete kept;
		Test.Assert(kept.FileName.Value == "Battle.2.as", scope String(kept.FileName.Value));
		Test.Assert(kept.ClassName == "Battle");
		let played = scope String();
		Test.Assert(CookClass(kept, played));
		Test.Assert(played == "Battle");

		// Nothing recorded: Battle.2 names no class of the three, and the cook says so.
		kept.ClassName.Clear();
		Test.Assert(!CookClass(kept, played));

		// A class chosen by hand survives a re-import of the same file (under its asset's name,
		// as the editor's reimport asks for it).
		kept.ClassName.Set("Fighter");
		Test.Assert(beside.WriteObject(kept) case .Ok);
		context.OnConflict = .Refuse;
		let named = scope Sedulous.Pipeline.Importer.ImportOptions();
		Sedulous.Pipeline.Importer.ImportPaths.SingleAssetPlan(second, named.Selection);
		named.Selection.Entries[0].TargetName.Set(beside.Name);
		Instance again = null;
		if (importer.Import(second, context, group, named, null, null) case .Ok(let againInstance))
			again = againInstance;
		Test.Assert(again === beside);
		let reimported = AssetOf(again);
		defer delete reimported;
		Test.Assert(reimported.ClassName == "Fighter");
	}

	[Test]
	public static void AUtilityModuleCooksWithNoClass()
	{
		Registered();
		let cook = ScriptLanguageCooks.Find("angelscript");
		let record = scope ScriptClassSource();
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		Test.Assert(cook.Cook("float Helper(float x) { return x * 2; }", "Helpers.as", "", record, problems));
		Test.Assert(record.ClassName.IsEmpty && record.Properties.IsEmpty && record.Handlers.IsEmpty);
	}

	[Test]
	public static void TheImporterClaimsTheCooksExtension()
	{
		Registered();
		let importer = scope ScriptFileImporter();
		Test.Assert(importer.Accepts("as") && !importer.Accepts("lua"));
		let template = scope String();
		ScriptLanguageCooks.Find("angelscript").NewAssetTemplate(.Behavior, "", template);
		Test.Assert(template.Contains("class NewBehavior") && template.Contains("onUpdate"));
	}

	/// Each tier's starter declares its reserved class. That they compile against the engine
	/// surface is the MCP golden's to prove: this suite's cook binds the fixture surface, which
	/// has no Scene.
	[Test]
	public static void EveryTiersStarterNamesItsClass()
	{
		Registered();
		let cook = ScriptLanguageCooks.Find("angelscript");
		for (let (tier, className) in scope (ScriptTier, StringView)[](
			(.Behavior, "class NewBehavior"), (.Level, "class Level"), (.Game, "class Game")))
		{
			let source = scope String();
			cook.NewAssetTemplate(tier, "", source);
			Test.Assert(source.Contains(className), scope $"{tier}");
		}
	}
}
