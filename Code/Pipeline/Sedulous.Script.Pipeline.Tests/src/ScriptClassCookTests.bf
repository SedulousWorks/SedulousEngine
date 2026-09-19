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

	private static ScriptSurface sSurface = null;

	private static void Registered()
	{
		if (sSurface != null)
			return;
		sSurface = new ScriptSurface();
		FixtureSurface.Populate(sSurface);
		AngelScriptCook.Register(sSurface);
		ScriptResources.RegisterAll();
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
				float speed = 2.5;
				int lives = 3;
				string label = "m";
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
			Test.Assert(builder.Version == 2, "the shell's plus the cook's");
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
		Test.Assert(product.ClassName == "Mover", "the first class, found through the comment");
		Test.Assert(product.SourceName == "scripts/Mover.as");
		Test.Assert(product.Source == source);
		Test.Assert(product.Properties.Count == 3, scope $"{product.Properties.Count} properties: the public authored ones, not self, not the private state");
		Test.Assert((product.FindProperty("speed").Type == .Float) && (product.FindProperty("speed").Default.Number == 2.5));
		Test.Assert(product.FindProperty("label").Default.Text == "m");
		Test.Assert(product.HasHandler("onStart") && product.HasHandler("onUpdate") && product.HasHandler("onHit"));
		Test.Assert(!product.HasHandler("run"), "a helper is not a handler");
		Test.Assert(product.UsesCoroutines);
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

		// The wrong class name is a failure too, not a silent empty record.
		problems.Clear();
		Test.Assert(!cook.Cook("class Fine {}", "Fine.as", "Other", record, problems));
		Test.Assert(problems.Back.Contains("Other"));

		// A script reaching beyond the surface it is cooked against is refused here.
		problems.Clear();
		Test.Assert(!cook.Cook("class Reach { void onStart() { PhysicsSceneSystem@ p; } }", "Reach.as", "", record, problems));
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
		ScriptLanguageCooks.Find("angelscript").NewAssetTemplate(template);
		Test.Assert(template.Contains("class NewBehavior") && template.Contains("onUpdate"));
	}
}
