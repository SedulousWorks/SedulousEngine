using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.GUI.Pipeline;
using Sedulous.GUI.Resources;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.GUI.Pipeline.Tests;

/// The GUI pipeline's tests: a `.xml` document and a `.css` sheet cooked through their
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
		bed.Stage("title.xml", cTitle);
		bed.Stage("game.css", cSheet);

		let documentInstance = bed.Output("title", typeof(GuiDocumentSource));
		{
			let asset = scope GuiDocumentAsset();
			asset.FileName.Set("title.xml");
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
		bed.Stage("bad.xml", "<Panel><Label text=\"x\"</Panel>");
		bed.Context.Output = bed.Output("bad", typeof(GuiDocumentSource));
		let builder = scope GuiDocumentAssetBuilder();
		let bad = scope GuiDocumentAsset();
		bad.FileName.Set("bad.xml");
		Test.Assert(builder.Build(bad, bed.Context) case .Err);
		let unlinked = scope GuiDocumentAsset();
		Test.Assert(builder.Build(unlinked, bed.Context) case .Err);
		let missing = scope GuiDocumentAsset();
		missing.FileName.Set("missing.xml");
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
	public static void TheImporterTakesXmlAndCssAndTheCreatorsMakeADocumentAndASheet()
	{
		let importer = scope GuiFileImporter();
		Test.Assert(importer.Accepts("xml"));
		Test.Assert(importer.Accepts("css"));
		Test.Assert(!importer.Accepts("gml"));
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

	private static void Write(StringView path, StringView text)
		=> Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);

	/// The asset file an instance names.
	private static void FileOf(Instance instance, String outFileName)
	{
		let object = instance.ReadObject();
		defer delete object;
		outFileName.Append((Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset).FileName.Value);
	}

	private static void ReadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// The import's name clash rule, through the GUI importer (a document and a sheet share a stem
	/// easily): a sheet over a document of the same name is refused, the document untouched;
	/// re-importing the document's own file replaces it in place (its guid kept); another folder's
	/// file of the same name is refused, kept beside ("menu.2", its own copy "menu.2.xml"), or takes
	/// the asset over (guid kept, the other file's bytes in the asset's own copy, nothing left
	/// behind), as the context says; and the window's check (FindClash) says so first.
	[Test]
	public static void AnImportsNameClashesAnotherTypeRefusedAnotherFileRefusedKeptBesideOrReplacing()
	{
		GuiPipeline.RegisterAll();
		let root = "scratch_guipipe_clash";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let sources = PathJoin(root, "Sources", .. scope .());
		let one = PathJoin(root, "one", .. scope .());
		let two = PathJoin(root, "two", .. scope .());
		let dbRoot = PathJoin(root, "db", .. scope .());
		for (let folder in scope StringView[](sources, one, two, dbRoot))
			Test.Assert(CreateDirectory(folder));
		let doc = PathJoin(one, "menu.xml", .. scope .());
		let sheet = PathJoin(one, "menu.css", .. scope .());
		let otherDoc = PathJoin(two, "menu.xml", .. scope .());
		Write(doc, "<Panel/>\n");
		Write(sheet, "label { color: #fff; }\n");
		Write(otherDoc, "<Label/>\n");

		let mount = scope NativeFileSystem(dbRoot);
		SerializerFactory factory = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let sourceDb = scope ContentDatabase(mount, factory, "asset");
		let group = sourceDb.RootGroup;
		IFileImporter importer = scope GuiFileImporter();
		let context = scope ImportContext(sources);
		ImportPaths.ImportLedgerPath(PathJoin(root, ".cache", .. scope .()), context.LedgerPath);

		Instance firstInstance = null;
		if (importer.Import(doc, context, group, null, null, null) case .Ok(let made))
			firstInstance = made;
		Test.Assert(firstInstance != null);
		let id = firstInstance.Id;
		Test.Assert(firstInstance.TypeName == "Sedulous.GUI.Pipeline.GuiDocumentAsset");

		// A sheet named "menu": another type holds it. Said first, refused, nothing changed.
		let plan = scope ImportPlan();
		ImportPaths.SingleAssetPlan(sheet, plan);
		let typeClash = scope ImportClash();
		importer.FindClash(group, sheet, plan, context.LedgerPath, typeClash);
		Test.Assert(typeClash.Kind == .OtherType);
		Test.Assert(ImportPaths.DescribeImportClash(typeClash, .. scope .()).Contains("GuiDocumentAsset"));
		context.OnConflict = .Replace; // no choice lets another type through
		Test.Assert(importer.Import(sheet, context, group, null, null, null) case .Err);
		Test.Assert(group.GetInstance("menu").TypeName == "Sedulous.GUI.Pipeline.GuiDocumentAsset");
		// Under another name it comes in.
		let named = scope ImportOptions();
		ImportPaths.SingleAssetPlan(sheet, named.Selection);
		named.Selection.Entries[0].TargetName.Set("menu sheet");
		Test.Assert(importer.Import(sheet, context, group, named, null, null) case .Ok);
		context.OnConflict = .Refuse;

		// The document's own file again (edited): a re-import, in place, no question.
		Write(doc, "<Panel id=\"edited\"/>\n");
		let reimport = scope ImportClash();
		importer.FindClash(group, doc, null, context.LedgerPath, reimport);
		Test.Assert(reimport.Kind == .Reimport);
		Instance again = null;
		if (importer.Import(doc, context, group, null, null, null) case .Ok(let made))
			again = made;
		Test.Assert((again != null) && (again.Id == id));
		Test.Assert(FileOf(again, .. scope .()) == "menu.xml");

		// Another folder's menu.xml: refused by default.
		let other = scope ImportClash();
		importer.FindClash(group, otherDoc, null, context.LedgerPath, other);
		Test.Assert(other.Kind == .SameType);
		Test.Assert(importer.Import(otherDoc, context, group, null, null, null) case .Err);
		Test.Assert(group.GetInstance("menu.2") == null);
		// Kept beside: its own asset and its own copy; the first's untouched.
		context.OnConflict = .KeepBoth;
		Instance beside = null;
		if (importer.Import(otherDoc, context, group, null, null, null) case .Ok(let made))
			beside = made;
		Test.Assert((beside != null) && (beside.Name == "menu.2") && (beside.Id != id));
		Test.Assert(FileOf(beside, .. scope .()) == "menu.2.xml");
		Test.Assert(FileOf(group.GetInstance("menu"), .. scope .()) == "menu.xml");
		// Replacing: the first asset takes the other file, its guid kept, into its own copy (no copy
		// beside it, none orphaned); the kept-beside asset's copy is untouched.
		context.OnConflict = .Replace;
		Instance replaced = null;
		if (importer.Import(otherDoc, context, group, null, null, null) case .Ok(let made))
			replaced = made;
		Test.Assert((replaced != null) && (replaced.Id == id));
		Test.Assert(FileOf(replaced, .. scope .()) == "menu.xml");
		Test.Assert(ReadText(PathJoin(sources, "menu.xml", .. scope .()), .. scope .()) == "<Label/>\n");
		Test.Assert(FileOf(group.GetInstance("menu.2"), .. scope .()) == "menu.2.xml");
		Test.Assert(!FileExists(PathJoin(sources, "menu.3.xml", .. scope .())));
		Test.Assert(ImportPaths.ImportOriginOf(context.LedgerPath, "menu.xml", .. scope .()) == otherDoc);
	}

	/// Replace over an asset whose copy another asset shares (the same bytes imported from two
	/// folders share one copy): the shared copy is left as it is, for the other asset, and the
	/// replaced asset takes a copy of its own.
	[Test]
	public static void ReplaceLeavesACopyAnotherAssetSharesAndCopiesInBesideIt()
	{
		GuiPipeline.RegisterAll();
		let root = "scratch_guipipe_shared";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let sources = PathJoin(root, "Sources", .. scope .());
		let one = PathJoin(root, "one", .. scope .());
		let two = PathJoin(root, "two", .. scope .());
		let three = PathJoin(root, "three", .. scope .());
		let dbRoot = PathJoin(root, "db", .. scope .());
		for (let folder in scope StringView[](sources, one, two, three, dbRoot))
			Test.Assert(CreateDirectory(folder));
		let first = PathJoin(one, "menu.xml", .. scope .());
		let twin = PathJoin(two, "menu.xml", .. scope .());
		let other = PathJoin(three, "menu.xml", .. scope .());
		Write(first, "<Panel/>\n");
		Write(twin, "<Panel/>\n"); // the same bytes
		Write(other, "<Label/>\n");

		let mount = scope NativeFileSystem(dbRoot);
		SerializerFactory factory = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let sourceDb = scope ContentDatabase(mount, factory, "asset");
		let group = sourceDb.RootGroup;
		IFileImporter importer = scope GuiFileImporter();
		let context = scope ImportContext(sources);
		ImportPaths.ImportLedgerPath(PathJoin(root, ".cache", .. scope .()), context.LedgerPath);

		Test.Assert(importer.Import(first, context, group, null, null, null) case .Ok);
		context.OnConflict = .KeepBoth;
		Instance beside = null;
		if (importer.Import(twin, context, group, null, null, null) case .Ok(let made))
			beside = made;
		Test.Assert((beside != null) && (beside.Name == "menu.2"));
		Test.Assert(FileOf(beside, .. scope .()) == "menu.xml", "shared: the very same bytes");

		context.OnConflict = .Replace;
		Instance replaced = null;
		if (importer.Import(other, context, group, null, null, null) case .Ok(let made))
			replaced = made;
		Test.Assert((replaced != null) && (replaced.Name == "menu"));
		Test.Assert(FileOf(replaced, .. scope .()) != "menu.xml");
		Test.Assert(ReadText(PathJoin(sources, "menu.xml", .. scope .()), .. scope .()) == "<Panel/>\n", "the other asset's, untouched");
		Test.Assert(FileOf(group.GetInstance("menu.2"), .. scope .()) == "menu.xml");
	}
}
