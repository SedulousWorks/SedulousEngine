using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.Pipeline.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The type the pages tests' assets are; only its name is stored, the instances never written.
class PagesTestAsset
{
}

/// One a builder cooks (PagesTestBuilder): its page comes from PagesTestAsset's factory.
class PagesTestBuiltAsset : PagesTestAsset
{
}

/// One no page edits.
class PagesTestUnpagedAsset
{
}

/// One whose factory breaks the contract: its page is not a UIEditorPage.
class PagesTestHeadlessAsset
{
}

/// A builder for PagesTestBuiltAsset, so the cook counts one never cooked as missing. Build is
/// never reached: the bed holds the cook's mutation lock while a page opens.
class PagesTestBuilder : IAssetBuilder
{
	public Type AssetType => typeof(PagesTestBuiltAsset);
	public Type ProductType => typeof(PagesTestBuiltAsset);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context) => .Err(.Unknown);
}

/// What the test pages were asked to do, across them all.
class PagesTestCounts
{
	public int Closed = 0;
	public int Updates = 0;
	public int Renders = 0;
	public int Overlays = 0;
}

class PagesTestPage : UIEditorPage
{
	private String mTitle = new .() ~ delete _;
	private Sedulous.GUI.Panel mContent = null ~ _?.ReleaseRef();
	/// Borrowed; null counts nothing.
	private PagesTestCounts mCounts;
	public int Saves = 0;
	/// Its next saves fail.
	public bool FailSave = false;

	public this(StringView title, PagesTestCounts counts)
	{
		mTitle.Set(title);
		mCounts = counts;
	}

	public override StringView Title => mTitle;

	public override Result<void, ErrorCode> Save()
	{
		if (FailSave)
			return .Err(.Unknown);
		Saves++;
		ClearDirty();
		return .Ok;
	}

	public override Node Content
	{
		get
		{
			if (mContent == null)
				mContent = new .();
			return mContent;
		}
	}

	public override void OnClose()
	{
		if (mCounts != null)
			mCounts.Closed++;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mCounts != null)
			mCounts.Updates++;
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mCounts != null)
			mCounts.Renders++;
	}

	public override void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame)
	{
		if (mCounts != null)
			mCounts.Overlays++;
	}
}

/// A page that is not a UIEditorPage: what a Game page factory breaking the contract makes.
class PagesTestHeadlessPage : EditorPage
{
	public override StringView Title => "Headless";
	public override Result<void, ErrorCode> Save() => .Ok;
}

class PagesTestFactory : IEditorPageFactory
{
	/// Borrowed.
	private PagesTestCounts mCounts;

	public this(PagesTestCounts counts)
	{
		mCounts = counts;
	}

	public Type PrimaryType => typeof(PagesTestAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new PagesTestPage(instance.Name, mCounts);
}

class PagesTestHeadlessFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(PagesTestHeadlessAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new PagesTestHeadlessPage();
}

/// EditorPages over a real EditorContext and EditorDock (opened into a panel 800 by 600 of a
/// GUI of its own, with no host, as DockBed's) and a scratch project with two assets a test page
/// edits. The notices land in Said, the status lines in Statuses. With `withCook`, the real cook
/// service over the project with PagesTestBuilder, its mutation lock the bed's Locked, and
/// resources over the cooked database.
class PagesBed
{
	public PagesTestCounts Counts = new .();
	public String Dir = new .();
	public EditorProject Project;
	/// Borrowed from the project's sources.
	public Instance One;
	public Instance Two;
	public EditorContext Context = new .();
	public List<String> Said = new .();
	public List<String> Statuses = new .();
	public SceneRoot Root;
	public Sedulous.GUI.Panel Into = new .();
	public EditorDock Dock = new .();
	public BuilderRegistry Builders = null;
	public EditorCookService Cook = null;
	public ResourceManager Resources = null;
	/// Holds the cook's mutation lock: a request waits instead of starting a worker.
	public bool Locked = false;
	/// The pages are given no project (Sources null).
	public bool NoProject = false;
	/// The pages are given no dialog root.
	public bool NoDialogs = false;
	public EditorPages Pages;

	public this(StringView dir, bool withCook = false)
	{
		Dir.Set(dir);
		RemoveDirectoryRecursive(Dir);
		Test.Assert(EditorProject.Create(Dir, "Pages") case .Ok);
		Project = EditorProject.Open(Dir);
		Test.Assert(Project != null);
		One = Project.SourceDb.RootGroup.CreateInstance("One", typeof(PagesTestAsset).GetFullName(.. scope .()));
		Two = Project.SourceDb.RootGroup.CreateInstance("Two", typeof(PagesTestAsset).GetFullName(.. scope .()));
		Test.Assert((One != null) && (Two != null));
		Context.Pages.Register(new PagesTestFactory(Counts));
		Context.Pages.Register(new PagesTestHeadlessFactory());
		let said = Said;
		Context.OnNotice = new [=said] (kind, message) => { said.Add(new String(message)); };
		let statuses = Statuses;
		Context.OnStatus = new [=statuses] (text) => { statuses.Add(new String(text)); };

		let context = new GUIContext();
		Root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		Root.Size = .(800.0f, 600.0f);
		Into.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(800.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		Root.AddChild(Into);
		Dock.Open(Into, null, new EditorDockContents());
		Root.UpdateLayout();

		let bed = this;
		if (withCook)
		{
			Builders = new .();
			Builders.Register(new PagesTestBuilder());
			Cook = new .();
			Cook.ExternalMutationLock = new [=bed] () => bed.Locked;
			Cook.Initialize(Project, Builders);
			Resources = new ResourceManager(Project.CookedDb);
		}
		let services = new EditorPagesServices();
		services.Context = Context;
		services.Dock = Dock;
		services.Cook = Cook;
		services.Project = new [=bed] () => bed.NoProject ? null : bed.Project;
		services.Resources = new [=bed] () => bed.Resources;
		services.DialogRoot = new [=bed] () => bed.NoDialogs ? null : bed.Root;
		Pages = new EditorPages(services);
	}

	public ~this()
	{
		// The pages first (they reach the dock and the context), the cook before the project it
		// reads, the dock before the tree, the context (the pages left open) before their counts.
		delete Pages;
		if (Cook != null)
		{
			Cook.Shutdown();
			delete Cook;
		}
		delete Builders;
		delete Resources;
		delete Dock;
		delete Context;
		Into.ReleaseRef();
		Root.ReleaseRef();
		delete Project;
		RemoveDirectoryRecursive(Dir);
		delete Dir;
		DeleteContainerAndItems!(Said);
		DeleteContainerAndItems!(Statuses);
		delete Counts;
	}

	/// The GUI laid out, then the pages' tick (the closes asked for run).
	public void Frame()
	{
		Root.UpdateLayout();
		Pages.Tick();
	}

	public DockLayout Layout => Dock.Controller.Layout;

	public static void PanelId(Instance instance, String outPanel) => EditorPages.PanelIdOf(instance.Id, outPanel);

	public StringView LastSaid => Said.IsEmpty ? "" : Said.Back;

	/// The open message box in the tree; null with none.
	public static MessageBox FindBox(Node node)
	{
		if (let question = node as MessageBox)
		{
			if (question.IsOpen)
				return question;
		}
		for (int i < node.ChildCount)
		{
			if (let found = FindBox(node.GetChildAt(i)))
				return found;
		}
		return null;
	}

	/// How many message boxes are open in the tree.
	public static int OpenBoxes(Node node)
	{
		int count = 0;
		if (let question = node as MessageBox)
		{
			if (question.IsOpen)
				count++;
		}
		for (int i < node.ChildCount)
			count += OpenBoxes(node.GetChildAt(i));
		return count;
	}

	public static Sedulous.GUI.Button ButtonNamed(MessageBox question, StringView text)
	{
		for (int i < question.ButtonCount)
		{
			if (question.ButtonAt(i).Text == text)
				return question.ButtonAt(i);
		}
		return null;
	}

	/// Asks to close `page` as its tab would, and the question it shows (asserted).
	public MessageBox Ask(EditorPage page)
	{
		Pages.RequestClose(page);
		Root.UpdateLayout();
		let question = FindBox(Root);
		Test.Assert(question != null, "the question shows");
		return question;
	}
}

/// EditorPages: a page docked by its asset's guid in the central stack (and brought forward when
/// opened again), its tab's name, unsaved mark and active mark; a close run at the next frame, a
/// page with unsaved changes asking first (Save, Discard, Cancel); the active page following the
/// dock; the Game tabs; the open pages through the store and back. Then what Sedulous adds to
/// Raptor's suite so each behaviour has a test: an asset no page edits, the save and its asset
/// edits, the frame hooks, closing everything, a dirty page with nowhere to ask, a failed save in
/// the question, the restore's progress and a restored place, the cook of what a page lacks, and
/// the hooks and the question let go with the pages.
class EditorPagesTests
{
	[Test]
	public static void APageDocksByItsGuidInTheCentralStackOnceItsTabSaysItsNameUnsavedAndActiveMarks()
	{
		let bed = scope PagesBed("scratch_editor_pages_dock");
		let one = bed.Pages.Open(bed.One);
		Test.Assert(one != null);
		let panel = PagesBed.PanelId(bed.One, .. scope .());
		Test.Assert(bed.Layout.StackOf(panel) == bed.Layout.CentralStack);
		Test.Assert(bed.Context.ActivePage === one);
		Test.Assert(bed.Dock.Controller.Content(panel) === one.Content);

		let two = bed.Pages.Open(bed.Two);
		Test.Assert(two != null);
		Test.Assert(bed.Pages.Open(bed.One) === one, "open already: brought forward, not opened again");
		Test.Assert(bed.Pages.Count == 2);
		Test.Assert(bed.Context.ActivePage === one);
		let central = bed.Layout.FindNode(bed.Layout.CentralStack);
		Test.Assert(central.Panels[(int)central.Active] == panel, "its tab to front");

		one.MarkDirty();
		bed.Frame();
		let described = bed.Dock.Controller.Describe(panel);
		Test.Assert(described != null);
		Test.Assert(described.Title == "One *");
		Test.Assert(described.TabClasses == "dirty active");
		Test.Assert(bed.Dock.Controller.Describe(PagesBed.PanelId(bed.Two, .. scope .())).TabClasses.IsEmpty);
		Test.Assert(bed.Pages.DirtyCount == 1);

		// The asset renamed: its tab follows.
		Test.Assert(bed.Project.SourceDb.RenameInstance(bed.One.Id, "First") case .Ok);
		one.ClearDirty();
		bed.Frame();
		Test.Assert(described.Title == "First");
		Test.Assert(described.TabClasses == "active");
		Test.Assert(bed.Pages.DirtyCount == 0);
		Test.Assert(bed.Pages.PanelOf(one) == panel);
		Test.Assert(bed.Pages.PanelOf(null) == null);
	}

	[Test]
	public static void ACleanPageClosesAtTheNextFrameWithItsPanelOneWithUnsavedChangesAsks()
	{
		let bed = scope PagesBed("scratch_editor_pages_close");
		let one = bed.Pages.Open(bed.One);
		Test.Assert(one != null);
		let panel = PagesBed.PanelId(bed.One, .. scope .());
		Test.Assert(!bed.Dock.Controller.Close(panel).Ok, "its tab's close: the page decides");
		Test.Assert(bed.Pages.Count == 1, "not inside the event");
		bed.Frame();
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Counts.Closed == 1);
		Test.Assert(bed.Context.OpenPages.Count == 0);
		Test.Assert(bed.Dock.Controller.Describe(panel) == null);
		Test.Assert(bed.Layout.StackOf(panel) == cNoDock);

		var page = (PagesTestPage)bed.Pages.Open(bed.One);
		Test.Assert(page != null);
		page.MarkDirty();
		var question = bed.Ask(page);
		Test.Assert(question.Title == "Unsaved changes");
		Test.Assert(question.Message == "'One' has unsaved changes.");
		Test.Assert(question.ButtonCount == 3);
		Test.Assert(question.GetButtonRole(0) == .Destructive); // Discard
		Test.Assert(question.GetButtonRole(1) == .Cancel);
		Test.Assert(question.GetButtonRole(2) == .Primary); // Save
		Test.Assert(PagesBed.ButtonNamed(question, "Cancel").HandleActivate());
		bed.Frame();
		Test.Assert(bed.Pages.Count == 1, "kept");

		question = bed.Ask(page);
		Test.Assert(PagesBed.ButtonNamed(question, "Save").HandleActivate());
		Test.Assert(page.Saves == 1);
		Test.Assert(bed.Pages.Count == 1, "not inside the event");
		bed.Frame();
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Counts.Closed == 2);

		page = (PagesTestPage)bed.Pages.Open(bed.Two);
		Test.Assert(page != null);
		page.MarkDirty();
		question = bed.Ask(page);
		Test.Assert(PagesBed.ButtonNamed(question, "Discard").HandleActivate());
		Test.Assert(page.Saves == 0);
		bed.Frame();
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Counts.Closed == 3);
	}

	[Test]
	public static void TheActivePageFollowsTheDocksActivePanelAnotherPanelLeavesItRevealBringsATabForward()
	{
		let bed = scope PagesBed("scratch_editor_pages_active");
		let one = bed.Pages.Open(bed.One);
		let two = bed.Pages.Open(bed.Two);
		Test.Assert((one != null) && (two != null));
		Test.Assert(bed.Context.ActivePage === two);

		let dock = bed.Dock.Controller;
		let central = bed.Layout.CentralStack;
		dock.NoteFocused(central); // the focus into the documents: their chosen tab
		dock.NoteActive(PagesBed.PanelId(bed.One, .. scope .()));
		Test.Assert(bed.Context.ActivePage === one);
		dock.NoteFocused(bed.Layout.StackOf(EditorDock.cPanelConsole)); // the Console: the page stays
		Test.Assert(bed.Context.ActivePage === one);

		bed.Context.RevealPage(two);
		let node = bed.Layout.FindNode(central);
		Test.Assert(node != null);
		Test.Assert(node.Panels[(int)node.Active] == PagesBed.PanelId(bed.Two, .. scope .()));
		Test.Assert(bed.Context.ActivePage === two);
	}

	[Test]
	public static void TheGameTabOpensOnceAndIsBroughtForwardAfterANewInstanceOpensBesideItByItsOwnId()
	{
		let bed = scope PagesBed("scratch_editor_pages_game");
		bed.Pages.OpenGame(false);
		Test.Assert(bed.LastSaid == "No game page registered in this build.");
		Test.Assert(bed.Pages.Count == 0);
		// A factory whose page has nowhere to show: none adopted.
		bed.Context.GamePageFactory = new (newInstance, pieId) => new PagesTestHeadlessPage();
		bed.Pages.OpenGame(false);
		Test.Assert(bed.Context.OpenPages.Count == 0);
		Test.Assert(bed.Layout.StackOf("game-page") == cNoDock);

		int made = 0;
		let ids = scope List<String>();
		defer ClearAndDeleteItems(ids);
		delete bed.Context.GamePageFactory;
		bed.Context.GamePageFactory = new [&] (newInstance, pieId) =>
			{
				++made;
				ids.Add(new String(pieId));
				return new PagesTestPage("Game", null);
			};
		bed.Pages.OpenGame(false);
		bed.Pages.OpenGame(false);
		Test.Assert(made == 1);
		Test.Assert(bed.Layout.StackOf("game-page") != cNoDock);
		Test.Assert(ids[0] == "game-page", "the page answers to its tab's id");
		bed.Pages.OpenGame(true);
		Test.Assert(made == 2);
		Test.Assert(bed.Layout.StackOf("game-page-1") != cNoDock);
		bed.Pages.OpenGame(true);
		Test.Assert(bed.Layout.StackOf("game-page-2") != cNoDock, "each new instance its own id");
		Test.Assert(ids[2] == "game-page-2");

		// The primary closed, Play makes another.
		EditorPage primary = null;
		for (let page in bed.Context.OpenPages)
		{
			let panel = bed.Pages.PanelOf(page);
			if ((panel != null) && (panel == "game-page"))
				primary = page;
		}
		Test.Assert(primary != null);
		bed.Pages.Close(primary);
		bed.Frame();
		Test.Assert(bed.Layout.StackOf("game-page") == cNoDock);
		bed.Pages.OpenGame(false);
		Test.Assert(made == 4);
		Test.Assert(bed.Layout.StackOf("game-page") != cNoDock);

		bed.Pages.CloseAll();
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Context.OpenPages.Count == 0);
	}

	[Test]
	public static void TheOpenPagesAndTheActiveOneThroughTheStoreAndBackGameTabsAreNotSaved()
	{
		let bed = scope PagesBed("scratch_editor_pages_store");
		bed.Context.GamePageFactory = new (newInstance, pieId) => new PagesTestPage("Game", null);
		let store = scope Settings();
		Test.Assert(!bed.Pages.Restore(store), "none saved: the caller opens the default");
		let one = bed.Pages.Open(bed.One);
		Test.Assert(bed.Pages.Open(bed.Two) != null);
		bed.Pages.OpenGame(false);
		bed.Context.RevealPage(one);
		bed.Pages.Capture(store);
		let section = store.Find<EditorOpenPagesSettings>();
		Test.Assert((section != null) && (section.Pages.Count == 2), "the Game tab not among them");
		Test.Assert(section.Active == bed.One.Id);
		bed.Pages.CloseAll();
		Test.Assert(bed.Pages.Count == 0);

		Test.Assert(bed.Pages.Restore(store));
		Test.Assert(bed.Pages.Count == 2);
		Test.Assert(bed.Context.ActivePage != null);
		Test.Assert(bed.Context.ActivePage.InstanceId == bed.One.Id);

		// The Game tab active: no asset page is.
		bed.Pages.OpenGame(false);
		bed.Pages.Capture(store);
		Test.Assert(!store.Find<EditorOpenPagesSettings>().Active.IsSet);
	}

	[Test]
	public static void AnAssetNoPageEditsSaysSoAndOpensNothingAPageOpensByGuid()
	{
		let bed = scope PagesBed("scratch_editor_pages_unpaged");
		let unpaged = bed.Project.SourceDb.RootGroup.CreateInstance("Loose", typeof(PagesTestUnpagedAsset).GetFullName(.. scope .()));
		Test.Assert(unpaged != null);
		Test.Assert(bed.Pages.Open(unpaged) == null);
		Test.Assert(bed.LastSaid == "No editor registered for this asset type.");
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Dock.Controller.Describe(PagesBed.PanelId(unpaged, .. scope .())) == null);
		// A page that is not a UIEditorPage has nowhere to show: it does not stay open unseen.
		let headless = bed.Project.SourceDb.RootGroup.CreateInstance("Headless", typeof(PagesTestHeadlessAsset).GetFullName(.. scope .()));
		Test.Assert(bed.Pages.Open(headless) == null);
		Test.Assert(bed.Context.OpenPages.Count == 0);

		Test.Assert(bed.Pages.Open(Guid.Create()) == null, "no such asset");
		let one = bed.Pages.Open(bed.One.Id);
		Test.Assert((one != null) && (one.InstanceId == bed.One.Id));
		Test.Assert(bed.Pages.Count == 1);

		// No project: nothing to open by guid, nothing to restore.
		bed.NoProject = true;
		Test.Assert(bed.Pages.Open(bed.Two.Id) == null);
		let store = scope Settings();
		bed.Pages.Capture(store);
		Test.Assert(!bed.Pages.Restore(store));
	}

	[Test]
	public static void SaveSaysHowItWentAndPersistsTheLiveAssetEdits()
	{
		let bed = scope PagesBed("scratch_editor_pages_save");
		let page = (PagesTestPage)bed.Pages.Open(bed.One);
		page.MarkDirty();
		bed.Pages.Save(page);
		Test.Assert(page.Saves == 1);
		Test.Assert(bed.LastSaid == "Saved 'One'.");

		page.FailSave = true;
		bed.Pages.Save(page);
		Test.Assert(bed.LastSaid == "Save FAILED (see Console).");

		// What a live tool edited goes with any save; a failed persist says so.
		int persisted = 0;
		bed.Context.RegisterAssetEdit(bed.Two.Id, new [&] (db) => { persisted++; return .Ok; });
		page.FailSave = false;
		bed.Pages.Save(page);
		Test.Assert(persisted == 1);
		Test.Assert(!bed.Context.HasPendingAssetEdits);
		Test.Assert(bed.LastSaid == "Persisted live asset edits.");
		bed.Context.RegisterAssetEdit(bed.Two.Id, new (db) => Result<void, ErrorCode>.Err(.Unknown));
		bed.Pages.Save(page);
		Test.Assert(bed.LastSaid == "Asset-edit persist FAILED (see Console).");
	}

	[Test]
	public static void EachFrameRunsTheClosesThenEveryPagesHooks()
	{
		let bed = scope PagesBed("scratch_editor_pages_frame");
		let one = bed.Pages.Open(bed.One);
		Test.Assert(bed.Pages.Open(bed.Two) != null);
		bed.Pages.Update(null, 0.016f);
		Test.Assert(bed.Counts.Updates == 2);
		FrameContext frame = .();
		bed.Pages.Render(null, ref frame);
		Test.Assert(bed.Counts.Renders == 2);
		bed.Pages.AfterSceneRender(null, ref frame);
		Test.Assert(bed.Counts.Overlays == 2);

		// A close asked for runs in the frame's update, before the hooks.
		bed.Pages.Close(one);
		bed.Pages.Close(one); // once, however often asked
		bed.Pages.Update(null, 0.016f);
		Test.Assert(bed.Pages.Count == 1);
		Test.Assert(bed.Counts.Closed == 1);
		Test.Assert(bed.Counts.Updates == 3);
	}

	[Test]
	public static void CloseAllClosesEveryPageNowAndForgetsTheClosesAskedFor()
	{
		let bed = scope PagesBed("scratch_editor_pages_closeall");
		let one = bed.Pages.Open(bed.One);
		Test.Assert(bed.Pages.Open(bed.Two) != null);
		bed.Pages.Close(one);
		bed.Pages.CloseAll();
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Counts.Closed == 2, "each page once");
		Test.Assert(bed.Context.OpenPages.Count == 0);
		Test.Assert(bed.Dock.Controller.Describe(PagesBed.PanelId(bed.One, .. scope .())) == null);
		Test.Assert(bed.Dock.Controller.Describe(PagesBed.PanelId(bed.Two, .. scope .())) == null);
		bed.Frame(); // the close asked for before is gone with its page
		Test.Assert(bed.Counts.Closed == 2);
	}

	[Test]
	public static void ADirtyPageWithNowhereToAskStaysOpenClosingItWithoutAskingSaysItHadChanges()
	{
		let bed = scope PagesBed("scratch_editor_pages_nodialog");
		bed.NoDialogs = true;
		let page = bed.Pages.Open(bed.One);
		page.MarkDirty();
		bed.Pages.RequestClose(page);
		bed.Frame();
		Test.Assert(PagesBed.FindBox(bed.Root) == null);
		Test.Assert(bed.Pages.Count == 1, "nothing to ask over: it stays open");

		// An agent's close (page_close with discard) does not ask; the status says what went.
		bed.Pages.Close(page);
		Test.Assert(bed.Pages.Count == 1);
		bed.Frame();
		Test.Assert(bed.Pages.Count == 0);
		Test.Assert(bed.Statuses.Back == "Closed page had unsaved changes.");
	}

	[Test]
	public static void AFailedSaveInTheQuestionKeepsThePageAnAnswerForAClosedPageDoesNothing()
	{
		let bed = scope PagesBed("scratch_editor_pages_failedsave");
		let page = (PagesTestPage)bed.Pages.Open(bed.One);
		page.MarkDirty();
		page.FailSave = true;
		var question = bed.Ask(page);
		Test.Assert(PagesBed.ButtonNamed(question, "Save").HandleActivate());
		bed.Frame();
		Test.Assert(bed.Pages.Count == 1, "it stays open");
		Test.Assert(bed.LastSaid == "Save FAILED (see Console) - the page stays open.");

		// Asked, then closed by other means before the answer: the answer finds no page. Asked
		// again while it shows, one question stays.
		page.FailSave = false;
		question = bed.Ask(page);
		bed.Pages.RequestClose(page);
		Test.Assert(PagesBed.OpenBoxes(bed.Root) == 1);
		bed.Pages.CloseAll();
		Test.Assert(PagesBed.ButtonNamed(question, "Save").HandleActivate());
		Test.Assert(bed.Counts.Closed == 1);
		bed.Frame();
		Test.Assert(bed.Pages.Count == 0);
	}

	[Test]
	public static void ARestoreTellsItsProgressSkipsADeletedAssetAndKeepsAPlaceTheLayoutGave()
	{
		let bed = scope PagesBed("scratch_editor_pages_restore");
		let store = scope Settings();
		let gone = Guid.Create();
		ProjectEditorSettings.CaptureOpenPages(store, scope Guid[](bed.One.Id, gone, bed.Two.Id), bed.Two.Id);

		// A restored layout placed One's panel beside Assets.
		let onePanel = PagesBed.PanelId(bed.One, .. scope .());
		let assets = bed.Layout.StackOf(EditorDock.cPanelAssets);
		Test.Assert(bed.Dock.Controller.Edit(scope (layout) => layout.InsertTab(onePanel, assets)).Ok);

		let heard = scope List<String>();
		defer ClearAndDeleteItems(heard);
		let shares = scope List<float>();
		Test.Assert(bed.Pages.Restore(store, scope [&] (name, done) =>
			{
				heard.Add(new String(name));
				shares.Add(done);
			}));
		Test.Assert(bed.Pages.Count == 2);
		Test.Assert((heard.Count == 2) && (heard[0] == "One") && (heard[1] == "Two"));
		Test.Assert((shares[0] == 0.0f) && (Math.Abs(shares[1] - 2.0f / 3.0f) < 0.0001f));
		Test.Assert(bed.Layout.StackOf(onePanel) == assets, "where the layout kept it");
		Test.Assert(bed.Layout.StackOf(PagesBed.PanelId(bed.Two, .. scope .())) == bed.Layout.CentralStack);
		Test.Assert(bed.Context.ActivePage.InstanceId == bed.Two.Id);
	}

	[Test]
	public static void APageCooksWhatItLacksItsOwnAssetAndTheReferencesWithASource()
	{
		let bed = scope PagesBed("scratch_editor_pages_cook", true);
		// No builder for its type and nothing unresolved: no cook.
		bed.Locked = true;
		Test.Assert(bed.Pages.Open(bed.One) != null);
		bed.Locked = false;
		Test.Assert(bed.Cook.IsIdle);

		// A reference to a deleted asset stays unresolved and asks for nothing.
		bed.Resources.Bind<PagesTestAsset>(Guid.Create());
		bed.Locked = true;
		Test.Assert(bed.Pages.Open(bed.Two) != null);
		bed.Locked = false;
		Test.Assert(bed.Cook.IsIdle);
		bed.Pages.CloseAll();

		// One with a source does.
		bed.Resources.Bind<PagesTestAsset>(bed.Two.Id);
		bed.Locked = true;
		Test.Assert(bed.Pages.Open(bed.One) != null);
		bed.Locked = false;
		Test.Assert(!bed.Cook.IsIdle);
	}

	[Test]
	public static void APageOfATypeABuilderCooksIsCookedWhenItOpens()
	{
		let bed = scope PagesBed("scratch_editor_pages_cookown", true);
		let built = bed.Project.SourceDb.RootGroup.CreateInstance("Built", typeof(PagesTestBuiltAsset).GetFullName(.. scope .()));
		Test.Assert(built != null);
		bed.Locked = true;
		Test.Assert(bed.Pages.Open(built) != null, "PagesTestAsset's factory edits it");
		bed.Locked = false;
		Test.Assert(!bed.Cook.IsIdle, "never cooked: its cook asked for");
	}

	[Test]
	public static void ThePagesLetTheDockTheContextAndTheirQuestionGoWhenTheyGo()
	{
		let bed = scope PagesBed("scratch_editor_pages_unwire");
		let one = bed.Pages.Open(bed.One);
		Test.Assert(bed.Context.OnRevealPage != null);
		one.MarkDirty();
		bed.Ask(one);
		DeleteAndNullify!(bed.Pages);
		Test.Assert(bed.Context.OnRevealPage == null);
		Test.Assert(PagesBed.FindBox(bed.Root) == null, "its question closed, unanswered");
		// The dock's active panel changing reaches no gone pages.
		bed.Dock.Controller.NoteFocused(bed.Layout.CentralStack);
		bed.Context.RevealPage(one);
		Test.Assert(bed.Context.ActivePage === one);
	}
}
