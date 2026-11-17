using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Pipeline;
using Sedulous.Engine.Composition;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Script.Tests;

/// The script page over its markup without a host (AngelScript): the source read into the code and
/// checked, a broken edit's problem on its line, one history (the code's steps on the page's stack,
/// its Ctrl+Z the page's), Save writing the source, a missing source a problem and no save, the API
/// browser built when opened and searched, a breakpoint the editor's.
class ScriptPageTests
{
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

	/// A project with a behaviour from the cook's starter ("Hero", Sources/Hero.as) and one whose
	/// source is not there ("Gone").
	private class Bed
	{
		public String Dir = new .("scratch_script_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public CodeLanguages Languages = new .(new (path, outText) => ReadData(path, outText)) ~ delete _;
		public Instance Hero;
		public Instance Gone;
		public String Source = new .() ~ delete _;
		/// What the pages' API is described against: the engine's, as the editor binds it.
		public ScriptSurface Surface = new .() ~ delete _;

		public this()
		{
			ScriptPipeline.RegisterAll(); // the instances' type, written and read back
			ScriptSourceDocumentTests.EnsureCook();
			AngelScriptBackend.Register(); // the API's throwaway runtime
			EngineScriptSurface.Populate(Surface);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let cook = ScriptLanguageCooks.Find("angelscript");
			Test.Assert(cook != null);
			cook.NewAssetTemplate(.Behavior, "Hero", Source);
			Test.Assert(System.IO.File.WriteAllText(PathJoin(Project.SourcesRoot(.. scope .()), "Hero.as", .. scope .()), Source) case .Ok);
			let typeName = typeof(ScriptClassAsset).GetFullName(.. scope .());
			Hero = Project.SourceDb.RootGroup.CreateInstance("Hero", typeName);
			Gone = Project.SourceDb.RootGroup.CreateInstance("Gone", typeName);
			Test.Assert((Hero != null) && (Gone != null));
			let asset = scope ScriptClassAsset();
			asset.Language.Set("angelscript");
			asset.FileName.Set("Hero.as");
			Test.Assert(Hero.WriteObject(asset) case .Ok);
			asset.FileName.Set("Gone.as");
			Test.Assert(Gone.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it (before the bed).
		public ScriptEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			services.Languages = Languages;
			return new ScriptEditorPage(Context, services, instance, Surface);
		}

		public void OnDisk(String outText)
		{
			System.IO.File.ReadAllText(PathJoin(Project.SourcesRoot(.. scope .()), "Hero.as", .. scope .()), outText, true).IgnoreError();
		}
	}

	[Test]
	public static void RegisteredForTheScriptAsset()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		ScriptEditor.Register(context, none, null);
		let found = context.Pages.FindFactory(typeof(ScriptClassAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(ScriptClassAsset)));
	}

	/// Discard puts back the source as last saved, and the code's own history goes with the page's.
	[Test]
	public static void DiscardPutsBackTheSourceAsLastSaved()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hero);
		defer delete page;
		Test.Assert(page.Code != null);
		page.Code.SetCaret(.(0, 0));
		page.Code.Type("// saved\n");
		Test.Assert(page.Save() case .Ok);
		page.Code.Type("// not saved\n");
		Test.Assert(page.IsDirty);

		Test.Assert(page.DiscardChanges());
		Test.Assert(!page.IsDirty);
		let text = page.Text(.. scope .());
		Test.Assert(text.StartsWith("// saved\n"));
		Test.Assert(!text.Contains("// not saved"));
		Test.Assert(!page.Commands.CanUndo);
		Test.Assert(page.Code.Document.UndoCount == 0);

		// Typing after the discard is a step of its own again.
		page.Code.Type("x");
		Test.Assert(page.IsDirty);
		Test.Assert(page.Commands.CanUndo);
	}

	[Test]
	public static void TheSourceReadAndCheckedABrokenEditsProblemOnItsLineOneHistorySaveWritingIt()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hero);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Code != null);
		Test.Assert(page.Problems != null);
		Test.Assert(page.SourceRead);
		Test.Assert(page.Text(.. scope .()) == bed.Source);
		Test.Assert(page.Language == "angelscript");
		Test.Assert(page.ErrorCount == 0, page.Found.IsEmpty ? "" : page.Found[0].Message);
		Test.Assert(page.Problems.Summary(.. scope .()) == "No problems: compiles class Hero"); // the class it compiled, as the old page said
		Test.Assert(!page.Code.TokensOf(0).IsEmpty, "coloured: its language read");

		// Typing that breaks it: one step on the page's stack, the problem on its line once checked.
		page.Code.SetCaret(.(0, 0));
		page.Code.Type("this does not compile ");
		Test.Assert(page.IsDirty);
		Test.Assert(page.Commands.CanUndo);
		page.CheckNow();
		Test.Assert(page.ErrorCount > 0);
		Test.Assert(page.Found[0].Line == 0);
		let marks = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(marks); }
		page.Code.GetDiagnostics(marks);
		Test.Assert(!marks.IsEmpty);

		// The page's undo walks the code's history; redo puts it back.
		page.Commands.Undo();
		Test.Assert(page.Text(.. scope .()) == bed.Source);
		Test.Assert(!page.Commands.CanUndo);
		page.Commands.Redo();
		Test.Assert(page.Text(.. scope .()).StartsWith("this does not compile "));
		page.Commands.Undo();

		// An edit, saved: the file holds it.
		page.Code.SetCaret(.(0, 0));
		page.Code.Type("// a note\n");
		Test.Assert(page.Save() case .Ok);
		Test.Assert(!page.IsDirty);
		Test.Assert(bed.OnDisk(.. scope .()).StartsWith("// a note\n"));
		Test.Assert(page.ErrorCount == 0);
	}

	[Test]
	public static void ASourceThatIsNotThereIsAProblemTheCodeReadOnlySaveRefused()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Gone);
		defer delete page;
		Test.Assert(!page.SourceRead);
		Test.Assert(page.Code != null);
		Test.Assert(page.Code.IsReadOnly);
		Test.Assert(page.Found.Length == 1);
		Test.Assert(page.Found[0].Message.IndexOf("Gone.as", true) >= 0);
		Test.Assert(page.Save() case .Err);
	}

	[Test]
	public static void TheApiBrowserBuiltWhenItOpensAndSearchedABreakpointTheEditors()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hero);
		defer delete page;
		Test.Assert(!page.ApiShown);
		Test.Assert(page.ApiTree.Nodes.IsEmpty, "not built while closed");
		page.ShowApi(true);
		Test.Assert(page.ApiShown);
		Test.Assert(!page.ApiTree.Roots.IsEmpty);
		Test.Assert(page.ApiModel != null, "the tree's rows, not only the page's list of them");
		Test.Assert(page.ApiModel.RowCount(.()) == page.ApiTree.Roots.Count);
		page.SearchApi("Float3");
		bool float3 = false;
		for (let root in page.ApiTree.Roots)
			float3 = float3 || (page.ApiTree.Nodes[root].Label == "Float3");
		Test.Assert(float3);
		page.ShowApi(false);
		Test.Assert(!page.ApiShown);

		page.ToggleBreakpoint(2);
		Test.Assert(page.HasBreakpointMark(2));
		Test.Assert(bed.Context.HasBreakpoint("Hero.as", 3));
		page.ToggleBreakpoint(2);
		Test.Assert(!page.HasBreakpointMark(2));
		Test.Assert(!bed.Context.HasBreakpoint("Hero.as", 3));
	}

	/// The page compared its text only with what it last read, never the file: Save wrote over an
	/// edit made in another editor without a word.
	[Test]
	public static void ASourceChangedOutsideTheEditorIsNotSavedOverInSilence()
	{
		let bed = scope Bed();
		let outside = scope String("// edited elsewhere\n")..Append(bed.Source);
		let path = PathJoin(bed.Project.SourcesRoot(.. scope .()), "Hero.as", .. scope .());

		// A dirty page: the first Save refused, the disk kept; a second Save overwrites.
		{
			let page = bed.Open(bed.Hero);
			defer delete page;
			Test.Assert(page.Code != null);
			page.Code.SetCaret(.(0, 0));
			page.Code.Type("// mine\n");
			Test.Assert(System.IO.File.WriteAllText(path, outside) case .Ok);
			page.CheckSourceOnDisk();
			Test.Assert(page.IsDirty); // the edits stay
			Test.Assert(page.Save() case .Err(.OutOfDate));
			Test.Assert(bed.OnDisk(.. scope .()) == outside);
			Test.Assert(page.IsDirty);
			Test.Assert(page.Save() case .Ok);
			Test.Assert(bed.OnDisk(.. scope .()).StartsWith("// mine\n"));
			Test.Assert(!page.IsDirty);
		}

		// A clean page takes the change, and then saves without a refusal.
		Test.Assert(System.IO.File.WriteAllText(path, bed.Source) case .Ok);
		{
			let page = bed.Open(bed.Hero);
			defer delete page;
			Test.Assert(System.IO.File.WriteAllText(path, outside) case .Ok);
			page.CheckSourceOnDisk();
			Test.Assert(page.Text(.. scope .()) == outside);
			Test.Assert(!page.IsDirty);
			page.Code.Type("x");
			Test.Assert(page.Save() case .Ok);
		}
	}
}
