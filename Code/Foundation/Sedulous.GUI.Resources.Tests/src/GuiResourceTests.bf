using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.GUI.Resources.Tests;

/// A cooked GUI document and style sheet read back through their factories, their text intact,
/// and the module the engine composition takes them from.
class GuiResourceTests
{
	private const String cRoot = "scratch_guiresource_db";
	private const String cMarkup = "<Screen covers=\"true\"><Button id=\"play\" text=\"@menu.play\"/></Screen>";
	private const String cCss = "screen:entering { opacity: 0; } button { background: url(\"{6b1c0d3e-0000-4000-8000-000000000001}\"); }";

	[Test]
	public static void ACookedDocumentAndSheetBindAsTheirProductsTheTextIntact()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		let serializables = scope SerializableRegistry();
		GuiResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete serializers;
		let database = scope ContentDatabase(mount, serializers, "rasset", serializables);

		let title = database.RootGroup.CreateInstance("title", "Sedulous.GUI.Resources.GuiDocumentSource");
		let theme = database.RootGroup.CreateInstance("theme", "Sedulous.GUI.Resources.GuiStyleSheetSource");
		Test.Assert(title != null);
		Test.Assert(theme != null);
		let document = scope GuiDocumentSource();
		document.Markup.Set(cMarkup);
		Test.Assert(title.WriteObject(document) case .Ok);
		let sheet = scope GuiStyleSheetSource();
		sheet.Css.Set(cCss);
		Test.Assert(theme.WriteObject(sheet) case .Ok);

		let documents = scope GuiDocumentFactory();
		let sheets = scope GuiStyleSheetFactory();
		Test.Assert(documents.ProductTypeId == ResourceManager.ProductTypeIdOf<GuiDocument>());
		Test.Assert(documents.CookedType == typeof(GuiDocumentSource));
		Test.Assert(sheets.ProductTypeId == ResourceManager.ProductTypeIdOf<GuiStyleSheet>());
		Test.Assert(sheets.CookedType == typeof(GuiStyleSheetSource));
		let manager = scope ResourceManager(database, null);
		manager.AddFactory(documents);
		manager.AddFactory(sheets);
		let boundDocument = manager.Bind<GuiDocument>(title.Id);
		let boundSheet = manager.Bind<GuiStyleSheet>(theme.Id);
		Test.Assert(boundDocument.Get != null);
		Test.Assert(boundSheet.Get != null);
		Test.Assert(boundDocument.Get.Markup == cMarkup);
		Test.Assert(boundSheet.Get.Css == cCss);
	}

	[Test]
	public static void TheModuleOffersBothFactoriesUnderItsOwnId()
	{
		Test.Assert(GuiResources.Module.Id == "gui");
		Test.Assert(GuiResources.Module.Factories.Length == 2);
		Test.Assert(GuiResources.Module.Factories[0].Cooked == typeof(GuiDocumentSource));
		Test.Assert(GuiResources.Module.Factories[1].Cooked == typeof(GuiStyleSheetSource));
	}
}
