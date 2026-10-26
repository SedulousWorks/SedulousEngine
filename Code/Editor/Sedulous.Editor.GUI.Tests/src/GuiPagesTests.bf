using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.UI.Toolkit;
using Sedulous.GUI.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GUI.Tests;

/// The GUI asset pages: their registration, what the cook reports marking the editor's lines, the
/// markup a sheet is first previewed over, and a page's preview built in the runtime's GUI.
class GuiPagesTests
{
	/// A scratch source database to open pages on: the asset there, its linked file not (the page
	/// opens empty, and a test types into it with SetText).
	class PageBed
	{
		private String mDirectory = new .() ~ delete _;
		private NativeFileSystem mMount ~ delete _;
		private SerializerFactory mSerializers ~ delete _;
		public ContentDatabase Database ~ delete _;
		public EditorContext Context = new .() ~ delete _;

		public this(StringView directory)
		{
			GuiPipeline.RegisterAll();
			mDirectory.Set(directory);
			RemoveDirectoryRecursive(mDirectory);
			CreateDirectory(mDirectory);
			mMount = new NativeFileSystem(mDirectory);
			mSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(mMount, mSerializers, "rasset");
		}

		public ~this()
		{
			delete Database;
			Database = null;
			delete mMount;
			mMount = null;
			RemoveDirectoryRecursive(mDirectory);
		}

		public Instance Document(StringView name)
		{
			let instance = Database.RootGroup.CreateInstance(name, typeof(GuiDocumentAsset).GetFullName(.. scope .()));
			Test.Assert(instance.WriteObject(scope GuiDocumentAsset()) case .Ok);
			return instance;
		}

		public Instance StyleSheet(StringView name, StringView previewMarkup)
		{
			let instance = Database.RootGroup.CreateInstance(name, typeof(GuiStyleSheetAsset).GetFullName(.. scope .()));
			let asset = scope GuiStyleSheetAsset();
			asset.PreviewMarkup.Set(previewMarkup);
			Test.Assert(instance.WriteObject(asset) case .Ok);
			return instance;
		}
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 0.5f;

	[Test]
	public static void RegisteringRoutesBothAssetsToTheirPages()
	{
		let context = scope EditorContext();
		GuiEditor.Register(context, null, null);
		let document = context.Pages.FindFactory(typeof(GuiDocumentAsset));
		Test.Assert((document != null) && (document.PrimaryType == typeof(GuiDocumentAsset)));
		let sheet = context.Pages.FindFactory(typeof(GuiStyleSheetAsset));
		Test.Assert((sheet != null) && (sheet.PrimaryType == typeof(GuiStyleSheetAsset)));
	}

	[Test]
	public static void WhatTheCookReportsMarksTheEditorsLinesAndClearsWhenClean()
	{
		let editor = new CodeEditView();
		defer editor.ReleaseRef();
		let broken = "<Panel>\n  <NoSuchElement/>\n</Panel>";
		editor.SetText(broken);
		let found = scope List<Sedulous.GUI.GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		GuiPipeline.ValidateDocument(broken, found);
		Test.Assert(!found.IsEmpty, "an element nothing makes is dropped, and said so");
		GuiPages.MarkLines(editor, found);
		Test.Assert(editor.Document.DiagnosticCount == found.Count);
		Test.Assert(found[0].Line == 2, "the dropped element's own line");
		Test.Assert(editor.Document.GetDiagnostic(0).Line == 1, "the editor counts from 0");
		Test.Assert(!editor.Document.GetDiagnostic(0).Message.IsEmpty);

		GuiPages.MarkLines(editor, scope List<Sedulous.GUI.GuiDiagnostic>());
		Test.Assert(editor.Document.DiagnosticCount == 0);
	}

	[Test]
	public static void TheMarkupASheetIsFirstPreviewedOverBuildsClean()
	{
		let found = scope List<Sedulous.GUI.GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		Test.Assert(GuiPipeline.ValidateDocument(GuiPages.cStockPreviewMarkup, found));
		Test.Assert(found.IsEmpty);
	}

	/// Typing rebuilds the preview in the runtime's GUI; a document that does not build keeps the
	/// last good one, its error on the line; what was dropped is a warning that still previews.
	[Test]
	public static void ADocumentsPreviewRebuildsAsItIsTypedAndKeepsTheLastGoodOne()
	{
		let host = scope GuiPageHost();
		let bed = scope PageBed("scratch_gui_document_page");
		let page = new GuiAssetEditorPage(bed.Context, host, null, bed.Document("menu"), .Document);
		defer delete page;
		Test.Assert(page.Title == "menu");
		Test.Assert(page.Text.IsEmpty, "no linked file: the page opens empty");
		Test.Assert(page.PreviewRoot == null);
		Test.Assert(!page.IsDirty);
		Test.Assert(page.PreviewEditor == null, "a document is previewed as it is");

		page.SetText("<Panel><Label id=\"title\" text=\"Menu\"/></Panel>");
		Test.Assert(page.IsDirty);
		let good = page.PreviewRoot;
		Test.Assert(good != null);
		Test.Assert(good.FindElement("title") != null);
		Test.Assert(page.StatusText == "OK");

		page.SetText("<Panel>\n  <Label text=\"a\">\n</Panel>");
		Test.Assert(page.PreviewRoot === good, "the last good preview stays");
		Test.Assert(page.StatusText.StartsWith("Does not build"));
		let editor = page.Editor;
		Test.Assert((editor != null) && (editor.Document.DiagnosticCount > 0) && editor.Document.GetDiagnostic(0).IsError);

		page.SetText("<Panel id=\"menu\">\n  <NoSuchElement/>\n</Panel>");
		Test.Assert((page.PreviewRoot != null) && (page.PreviewRoot !== good), "a warning still previews");
		Test.Assert(page.PreviewRoot.FindElement("menu") != null);
		Test.Assert(page.StatusText.StartsWith("Warning: "));
		Test.Assert(editor.Document.DiagnosticCount > 0);
		Test.Assert((editor.Document.GetDiagnostic(0).Line == 1) && !editor.Document.GetDiagnostic(0).IsError);

		page.OnClose();
		Test.Assert(page.PreviewRoot == null, "closing lets the preview go");
	}

	/// A sheet is previewed over its asset's own markup, the sheet over that tree alone; with none
	/// kept, over the stock markup.
	[Test]
	public static void ASheetIsPreviewedOverItsOwnMarkup()
	{
		let host = scope GuiPageHost();
		let bed = scope PageBed("scratch_gui_sheet_page");
		let page = new GuiAssetEditorPage(bed.Context, host, null,
			bed.StyleSheet("theme", "<Panel><Panel class=\"title\" id=\"t\"/></Panel>"), .StyleSheet);
		defer delete page;
		Test.Assert(page.PreviewMarkup == "<Panel><Panel class=\"title\" id=\"t\"/></Panel>");
		Test.Assert(page.PreviewRoot != null, "the markup previews before the sheet has text");
		Test.Assert((page.PreviewEditor != null) && (page.PreviewEditor.Document.DiagnosticCount == 0));

		page.SetText(".title { width: 66px; height: 4px; }");
		let preview = page.PreviewRoot;
		Test.Assert(preview != null);
		Test.Assert(page.StatusText == "OK");
		// Styled and laid out as RenderPreview does before it draws.
		preview.ViewportSize = .(320.0f, 200.0f);
		host.Gui.Styles.MediaContext = preview.MediaContext;
		host.Gui.Styles.ApplyTree(preview);
		preview.UpdateLayout();
		let title = preview.FindElement("t");
		Test.Assert(title != null);
		Test.Assert(Near(title.Size.X, 66.0f), "the sheet styled its preview");
		Test.Assert(host.Gui.ScreenRoot.FindElement("t") == null, "and nothing of the game's");

		let stock = new GuiAssetEditorPage(bed.Context, host, null, bed.StyleSheet("plain", ""), .StyleSheet);
		defer delete stock;
		Test.Assert(stock.PreviewMarkup == GuiPages.cStockPreviewMarkup);
		Test.Assert(stock.PreviewRoot != null);
	}

	/// With no GUI in the runtime there is nothing to preview in; the page still edits, and says so.
	[Test]
	public static void WithoutTheRuntimesGuiThePageSaysThereIsNoPreview()
	{
		let bed = scope PageBed("scratch_gui_headless_page");
		let page = new GuiAssetEditorPage(bed.Context, null, null, bed.Document("menu"), .Document);
		defer delete page;
		page.SetText("<Panel/>");
		Test.Assert(page.Text == "<Panel/>");
		Test.Assert(page.PreviewRoot == null);
		Test.Assert(page.StatusText == "No GUI in the runtime: no preview.");
		Test.Assert(page.Save() case .Err(.NotFound), "no project to save into");
	}
}
