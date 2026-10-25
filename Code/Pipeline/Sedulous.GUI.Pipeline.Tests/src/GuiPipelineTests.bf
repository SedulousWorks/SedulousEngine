using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.GUI.Pipeline;
using Sedulous.GUI.Resources;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.GUI.Pipeline.Tests;

/// Raptor's GUI.Pipeline tests: a `.gml` document and a `.css` sheet cooked through their
/// validating builders and loaded as products; what cannot be read fails the cook, what was dropped
/// is said with its line; the guids a source names are found; the importer takes the two
/// extensions and the creators make the two kinds.
static class GuiPipelineTests
{
	/// A scratch sources tree and a scratch cooked database over it, with a build context wired to
	/// both: real mounts, as a cook runs against.
	private class Bed
	{
		public NativeFileSystem Sources ~ delete _;
		public NativeFileSystem CookedMount ~ delete _;
		public SerializerFactory Factory ~ delete _;
		public ContentDatabase Cooked ~ delete _;
		public AssetBuildContext Context = new .() ~ delete _;
		private String mSourcesRoot = new .() ~ delete _;
		private String mCookedRoot = new .() ~ delete _;

		public this(StringView name)
		{
			mSourcesRoot.AppendF("scratch_guipipe_{}_src", name);
			mCookedRoot.AppendF("scratch_guipipe_{}_db", name);
			RemoveDirectoryRecursive(mSourcesRoot);
			RemoveDirectoryRecursive(mCookedRoot);
			CreateDirectory(mSourcesRoot);
			CreateDirectory(mCookedRoot);
			Sources = new NativeFileSystem(mSourcesRoot);
			CookedMount = new NativeFileSystem(mCookedRoot);
			Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Cooked = new ContentDatabase(CookedMount, Factory, "rasset");
			Context.Sources = Sources;
			Context.Database = Cooked;
			Context.Serializers = Factory;
			GuiResources.RegisterAll();
			GuiPipeline.RegisterAll();
		}

		public ~this()
		{
			// The mounts close before their folders go.
			delete Cooked;
			Cooked = null;
			delete CookedMount;
			CookedMount = null;
			delete Sources;
			Sources = null;
			RemoveDirectoryRecursive(mSourcesRoot);
			RemoveDirectoryRecursive(mCookedRoot);
		}

		public void Stage(StringView fileName, StringView text)
		{
			let path = PathJoin(mSourcesRoot, fileName, .. scope .());
			WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
		}

		public Instance Output(StringView name, Type type) => Cooked.RootGroup.CreateInstance(name, type.GetFullName(.. scope .()));
	}

	private static bool Says(List<GuiDiagnostic> all, StringView part)
	{
		for (let d in all)
		{
			if (d.Message.Contains(part))
				return true;
		}
		return false;
	}

	private const String cTitle =
		"""
		<Screen covers="true" nav-default="play">
		  <Button id="play" text="@menu.play"/>
		  <Prompt action="pause"/>
		</Screen>

		""";

	private const String cSheet =
		"""
		screen:entering { opacity: 0; }
		button { background-image: url("{6b1c0d3e-0000-4000-8000-000000000001}"); }

		""";

	[Test]
	public static void ADocumentAndASheetCookValidatedAndLoadAsTheirProducts()
	{
		let bed = scope Bed("roundtrip");
		bed.Stage("title.gml", cTitle);
		bed.Stage("game.css", cSheet);

		let documentInstance = bed.Output("title", typeof(GuiDocumentSource));
		{
			let asset = scope GuiDocumentAsset();
			asset.FileName.Set("title.gml");
			bed.Context.Output = documentInstance;
			Test.Assert(scope GuiDocumentAssetBuilder().Build(asset, bed.Context) case .Ok);
		}
		let sheetInstance = bed.Output("game", typeof(GuiStyleSheetSource));
		{
			let asset = scope GuiStyleSheetAsset();
			asset.FileName.Set("game.css");
			bed.Context.Output = sheetInstance;
			Test.Assert(scope GuiStyleSheetAssetBuilder().Build(asset, bed.Context) case .Ok);
		}

		// Through the resource manager, as a game reaches them.
		let documents = scope GuiDocumentFactory();
		let sheets = scope GuiStyleSheetFactory();
		let manager = scope ResourceManager(bed.Cooked);
		manager.AddFactory(documents);
		manager.AddFactory(sheets);
		let document = manager.Bind<GuiDocument>(documentInstance.Id);
		let sheet = manager.Bind<GuiStyleSheet>(sheetInstance.Id);
		Test.Assert((document.Get != null) && (sheet.Get != null));
		Test.Assert(document.Get.Markup == cTitle);
		Test.Assert(sheet.Get.Css == cSheet);
	}

	[Test]
	public static void MarkupThatCannotBeReadFailsTheCookAndWhatWasDroppedIsSaidWithItsLine()
	{
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		Test.Assert(GuiPipeline.ValidateDocument(cTitle, said), "the gamekit's Screen and Prompt are known");
		Test.Assert(said.IsEmpty);

		ClearAndDeleteItems!(said);
		Test.Assert(!GuiPipeline.ValidateDocument("<Panel>\n  <Label text=\"unclosed\"\n</Panel>", said));
		Test.Assert(Says(said, "does not parse"));
		ClearAndDeleteItems!(said);
		Test.Assert(!GuiPipeline.ValidateDocument("<NotAnElement/>", said), "nothing to make");
		ClearAndDeleteItems!(said);
		Test.Assert(!GuiPipeline.ValidateDocument("", said));
		ClearAndDeleteItems!(said);
		Test.Assert(GuiPipeline.ValidateDocument("<Panel><Lable/><Label txet=\"x\"/></Panel>", said), "read, with what it dropped");
		Test.Assert(Says(said, "<Lable>"));
		Test.Assert(Says(said, "'txet'"));

		ClearAndDeleteItems!(said);
		GuiPipeline.ValidateStyleSheet(".a { colour: red; }\n.b:hovr { color: blue; }\nscreen { covers: true; }\n", said);
		Test.Assert(Says(said, "'colour'"));
		Test.Assert(Says(said, ".b:hovr"));
		Test.Assert(!Says(said, "covers"), "the gamekit's Screen takes it");
		for (let d in said)
			Test.Assert(d.Line != 0);

		// The builder: an unreadable document, no link, or a missing file fails.
		let bed = scope Bed("bad");
		bed.Stage("bad.gml", "<Panel><Label text=\"x\"</Panel>");
		bed.Context.Output = bed.Output("bad", typeof(GuiDocumentSource));
		let builder = scope GuiDocumentAssetBuilder();
		let bad = scope GuiDocumentAsset();
		bad.FileName.Set("bad.gml");
		Test.Assert(builder.Build(bad, bed.Context) case .Err);
		let unlinked = scope GuiDocumentAsset();
		Test.Assert(builder.Build(unlinked, bed.Context) case .Err);
		let missing = scope GuiDocumentAsset();
		missing.FileName.Set("missing.gml");
		Test.Assert(builder.Build(missing, bed.Context) case .Err);
	}

	[Test]
	public static void TheGuidsASourceNamesAreFoundEachOnce()
	{
		let found = scope List<Guid>();
		GuiPipeline.FindGuidReferences("url(\"{6b1c0d3e-0000-4000-8000-000000000001}\") source=\"{6b1c0d3e-0000-4000-8000-000000000002}\" again {6b1c0d3e-0000-4000-8000-000000000001} not {a-guid} nor {}", found);
		Test.Assert(found.Count == 2);
		Test.Assert(found[0] == Guid.Parse("6b1c0d3e-0000-4000-8000-000000000001").Value);
		Test.Assert(found[1] == Guid.Parse("6b1c0d3e-0000-4000-8000-000000000002").Value);
	}

	/// What a source names by guid is the product's runtime reference when it is an asset; a guid
	/// naming no asset is not.
	[Test]
	public static void TheGuidsThatAreAssetsAreTheProductsReferences()
	{
		let bed = scope Bed("refs");
		let icon = bed.Output("icon", typeof(GuiStyleSheetSource));
		let css = scope $"button {{ background-image: url(\"{{{icon.Id}}}\"); }}\nlabel {{ background-image: url(\"{{6b1c0d3e-0000-4000-8000-000000000009}}\"); }}\n";
		bed.Stage("refs.css", css);
		let asset = scope GuiStyleSheetAsset();
		asset.FileName.Set("refs.css");
		let deps = scope AssetDependencies();
		scope GuiStyleSheetAssetBuilder().ScanDependencies(asset, bed.Context, deps);
		Test.Assert((deps.References.Count == 1) && (deps.References[0] == icon.Id));
	}

	[Test]
	public static void TheImporterTakesGmlAndCssAndTheCreatorsMakeADocumentAndASheet()
	{
		let importer = scope GuiFileImporter();
		Test.Assert(importer.Accepts("gml"));
		Test.Assert(importer.Accepts("css"));
		Test.Assert(!importer.Accepts("xml"));
		Test.Assert(!importer.Accepts("sml"));
		let creators = scope AssetCreatorRegistry();
		GuiCreators.Register(creators);
		Test.Assert(creators.Count == 2);
		// The starters cook clean.
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		Test.Assert(GuiPipeline.ValidateDocument(GuiPipeline.cDocumentStarter, said));
		GuiPipeline.ValidateStyleSheet(GuiPipeline.cStyleSheetStarter, said);
		Test.Assert(said.IsEmpty);
	}
}
