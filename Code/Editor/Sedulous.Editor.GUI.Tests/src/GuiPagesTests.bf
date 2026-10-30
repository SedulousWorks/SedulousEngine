using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.GUI.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GUI.Tests;

/// The GUI asset pages over their markup: a document's code checked as the cook checks it, its
/// problems on their lines; a sheet previewed over markup of the page's own (first a little of
/// everything, which builds clean), whose edits never dirty the sheet and are kept in the project's
/// editor settings, whose problems are named apart, and which can be a copy of a document's markup;
/// and (Sedulous's) a document's preview built in the runtime's GUI, kept while the code does not
/// build.
class GuiPagesTests
{
	const String cHud = "<Panel class=\"hud\">\n    <Label class=\"score\" text=\"0\"/>\n</Panel>\n";
	const String cSheet = ".hud { padding: 8px; }\n.score { color: #ffcc00; }\n";

	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	static bool ReadData(StringView relative, String outText)
	{
		let data = scope String();
		return DataRoot(data) && (System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), outText, true) case .Ok);
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let text = scope String();
		Test.Assert(ReadData(relative, text));
		RegisterGuiElements();
		RegisterToolkitElements();
		RegisterCodeElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A project with a document ("Hud", Sources/Hud.gml) and a sheet ("Theme", Sources/Theme.css),
	/// its editor settings the context's.
	private class Bed
	{
		public String Dir = new .("scratch_gui_page_project") ~ delete _;
		public EditorProject Project;
		/// Declared before the context, which borrows it: it goes after.
		public Settings Store = new .() ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public CodeLanguages Languages = new .(new (path, outText) => ReadData(path, outText)) ~ delete _;
		public Instance Hud;
		public Instance Theme;

		public this()
		{
			GuiPipeline.RegisterAll(); // the instances' types, written and read back
			GuiEditorSerializables.RegisterAll(); // the settings section's type
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			let sources = Project.SourcesRoot(.. scope .());
			Test.Assert(System.IO.File.WriteAllText(PathJoin(sources, "Hud.gml", .. scope .()), cHud) case .Ok);
			Test.Assert(System.IO.File.WriteAllText(PathJoin(sources, "Theme.css", .. scope .()), cSheet) case .Ok);
			Hud = Project.SourceDb.RootGroup.CreateInstance("Hud", typeof(GuiDocumentAsset).GetFullName(.. scope .()));
			Theme = Project.SourceDb.RootGroup.CreateInstance("Theme", typeof(GuiStyleSheetAsset).GetFullName(.. scope .()));
			Test.Assert((Hud != null) && (Theme != null));
			let document = scope GuiDocumentAsset();
			document.FileName.Set("Hud.gml");
			Test.Assert(Hud.WriteObject(document) case .Ok);
			let sheet = scope GuiStyleSheetAsset();
			sheet.FileName.Set("Theme.css");
			Test.Assert(Theme.WriteObject(sheet) case .Ok);
		}

		public ~this()
		{
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it (before the bed). `host` (may be null) is
		/// the runtime the preview builds in.
		public GuiAssetEditorPage Open(Instance instance, GuiAssetEditorPage.Kind kind, GuiPageHost host = null)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			services.Languages = Languages;
			services.Host = host;
			return new GuiAssetEditorPage(Context, services, instance, kind);
		}
	}

	[Test]
	public static void RegisteredForTheDocumentAndTheSheet()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		GuiEditor.Register(context, none);
		Test.Assert(context.Pages.FindFactory(typeof(GuiDocumentAsset)) != null);
		Test.Assert(context.Pages.FindFactory(typeof(GuiStyleSheetAsset)) != null);
	}

	[Test]
	public static void TheMarkupASheetIsFirstPreviewedOverBuildsClean()
	{
		let found = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		Test.Assert(GuiPipeline.ValidateDocument(GuiPages.cStockPreviewMarkup, found));
		Test.Assert(found.IsEmpty);
	}

	[Test]
	public static void ADocumentsCodeCheckedAsTheCookChecksItItsProblemsOnTheirLines()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hud, .Document);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Code != null);
		Test.Assert(page.Text(.. scope .()) == cHud);
		Test.Assert(page.ErrorCount == 0, page.Found.IsEmpty ? "" : page.Found[0].Message);
		Test.Assert(page.PreviewMarkupEditor == null, "a document is previewed as it is");
		Test.Assert(!page.Code.TokensOf(0).IsEmpty);

		page.Code.SetCaret(.(1, 0));
		page.Code.Type("<Label text=\"unclosed\n");
		page.CheckNow();
		Test.Assert(page.ErrorCount > 0);
		Test.Assert(page.Found[0].File.IsEmpty);
		page.Commands.Undo();
		page.CheckNow();
		Test.Assert(page.ErrorCount == 0);
	}

	[Test]
	public static void ASheetOverMarkupOfThePagesOwnKeptApartFromTheAssetItsProblemsNamedApart()
	{
		let bed = scope Bed();
		var page = bed.Open(bed.Theme, .StyleSheet);
		defer { delete page; } // the block reads page as it is then: the one opened again
		Test.Assert(page.PreviewMarkupEditor != null);
		Test.Assert(page.PreviewMarkup(.. scope .()) == GuiPages.cStockPreviewMarkup);
		Test.Assert(page.ErrorCount == 0, page.Found.IsEmpty ? "" : page.Found[0].Message);

		// Its edits: the preview's, not the sheet's.
		page.PreviewMarkupEditor.SetCaret(.(0, 0));
		page.PreviewMarkupEditor.Type("<Broken\n");
		Test.Assert(!page.IsDirty);
		Test.Assert(!page.Commands.CanUndo);
		page.CheckNow();
		Test.Assert(page.ErrorCount > 0);
		Test.Assert(page.Found[0].File == GuiPages.cPreviewMarkupName);

		// Kept for the sheet in the project's editor settings.
		let kept = bed.Store.Find<GuiSheetPreviewSettings>();
		Test.Assert(kept != null);
		Test.Assert(kept.Sheets.Count == 1);
		Test.Assert(kept.Sheets[0].Asset == bed.Theme.Id);
		Test.Assert(kept.Sheets[0].Markup.StartsWith("<Broken"));

		// Over a copy of a document's markup; the sheet opened again shows what was kept.
		page.PreviewOverDocument(bed.Hud.Id);
		Test.Assert(page.PreviewMarkup(.. scope .()) == cHud);
		Test.Assert(page.ErrorCount == 0, page.Found.IsEmpty ? "" : page.Found[0].Message);
		delete page;
		page = bed.Open(bed.Theme, .StyleSheet);
		Test.Assert(page.PreviewMarkup(.. scope .()) == cHud);
	}

	/// Sedulous's: with the runtime's GUI the preview builds from the code; code that does not build
	/// keeps the last good one and says so; closing lets it go.
	[Test]
	public static void ADocumentsPreviewBuildsInTheRuntimesGuiAndKeepsTheLastGoodOne()
	{
		let host = scope GuiPageHost();
		let bed = scope Bed();
		let page = bed.Open(bed.Hud, .Document, host);
		defer delete page;
		let good = page.PreviewRoot;
		Test.Assert(good != null);
		Test.Assert(!page.PreviewStale);

		page.Code.SetCaret(.(1, 0));
		page.Code.Type("<Label text=\"unclosed\n");
		page.CheckNow();
		Test.Assert(page.PreviewRoot === good, "the last good preview stays");
		Test.Assert(page.PreviewStale);

		page.OnClose();
		Test.Assert(page.PreviewRoot == null, "closing lets the preview go");
	}
}
