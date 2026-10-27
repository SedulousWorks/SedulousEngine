using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.GUI; // with GUI.Docking's controller
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// What an EditorPages works over. The services are borrowed for its life; the delegates are
/// its own.
class EditorPagesServices
{
	public EditorContext Context = null;
	public EditorDock Dock = null;
	/// Null: a page's missing products are not cooked.
	public EditorCookService Cook = null;
	/// The open project (its sources name the pages' assets); unset or null: none. Owned.
	public delegate EditorProject() Project ~ delete _;
	/// The project's resources (unresolved references cook with the page); unset or null: none.
	/// Owned.
	public delegate ResourceManager() Resources ~ delete _;
	/// Where its dialogs show; unset or null: none shows (a dirty page then stays open). Owned.
	public delegate SceneRoot() DialogRoot ~ delete _;
}

/// The open pages in the dock (Raptor's editor-gui spec, 5.1, layer 6). A page is a panel of
/// its own, by its asset's guid (a Game tab by its play id: `game-page`, `game-page-1`, ...),
/// the ids a saved layout and the MCP layout tools name; it opens in the central stack, or where
/// a restored layout kept its place. Its tab says its asset's name, a ` *` and the `dirty` class
/// while it has unsaved changes, and the `active` class on the page the editor acts on (Save,
/// the inspector): the chosen tab of the stack the focus was last in. Closing a page with unsaved
/// changes asks first (Save, Discard, Cancel); a close always runs at the next frame, never
/// inside the event that asked for it, and takes the page's panel with it. The open pages and
/// the active one are saved with the project and reopen with it.
class EditorPages
{
	private struct OpenPage
	{
		/// The context owns it.
		public UIEditorPage Page;
		/// Its panel's id, ours.
		public String Panel;

		public this(UIEditorPage page, String panel)
		{
			Page = page;
			Panel = panel;
		}
	}

	private EditorPagesServices mServices ~ delete _;
	private List<OpenPage> mOpen = new .() ~ { for (let open in _) delete open.Panel; delete _; };
	/// Closes asked for, run at the next frame.
	private List<EditorPage> mClosing = new .() ~ delete _;
	/// The primary Game tab.
	private UIEditorPage mGamePage = null;
	/// The Game tabs beside it, ever.
	private uint32 mGamePages = 0;
	/// The last unsaved-changes question, a reference of ours: its answer's event runs on the
	/// question after its close, which may have let the tree's reference go. One at a time: it is
	/// modal, so only code could ask a second while it is open.
	private MessageBox mAsking = null ~ _?.ReleaseRef();

	/// TAKES OWNERSHIP of the services; the dock's active panel and the context's reveal come to
	/// it until it goes.
	public this(EditorPagesServices services)
	{
		mServices = services;
		mServices.Dock.Controller.SetOnActiveChanged(new (panel) => { NoteActivePanel(panel); });
		delete mServices.Context.OnRevealPage;
		mServices.Context.OnRevealPage = new (page) => { Reveal(page); };
	}

	public ~this()
	{
		mServices.Dock.Controller.SetOnActiveChanged(null);
		DeleteAndNullify!(mServices.Context.OnRevealPage);
		// An open question would answer into a gone EditorPages: it goes unanswered.
		if ((mAsking != null) && mAsking.IsOpen)
			mAsking.Close();
	}

	/// Opens (or brings forward) the page for `instance`; null, said to the user, when no page
	/// edits its type.
	public UIEditorPage Open(Instance instance)
	{
		let context = mServices.Context;
		let before = context.OpenPages.Count;
		let page = context.OpenPage(instance);
		if (page == null)
		{
			// The toast stays short; the log carries what identifies it, since an unresolvable
			// type is a retired or unregistered identity and its spelling is the clue.
			GlobalLog(.Warning, "Editor: no editor page for asset '{}', stored type '{}', guid {} (unknown type name, or no page factory registered)",
				instance.Name, instance.TypeName, instance.Id);
			context.Notify(.Warning, "No editor registered for this asset type.");
			return null;
		}
		// Every factory in this application makes a UIEditorPage (UIEditorPage's contract); one
		// that broke it has nowhere to show, so it does not stay open unseen.
		let uiPage = page as UIEditorPage;
		if (uiPage == null)
		{
			GlobalLog(.Error, "Editor: the page factory for '{}' made a page that is not a UIEditorPage", instance.TypeName);
			context.ClosePage(page);
			return null;
		}
		if (context.OpenPages.Count == before)
		{
			Reveal(uiPage); // open already: its tab to front
			return uiPage;
		}
		Dock(uiPage, PanelIdOf(instance.Id, .. new .()));
		CookMissing(instance);
		return uiPage;
	}

	/// Opens (or brings forward) the page for the source asset `id`; null when there is none.
	public UIEditorPage Open(Guid id)
	{
		let sources = Sources;
		let instance = (sources != null) ? sources.GetInstance(id) : null;
		return (instance != null) ? Open(instance) : null;
	}

	/// The Game tab (`newInstance`: another one beside it, with a game instance of its own),
	/// made through the context's GamePageFactory, the seam the play library registers.
	public void OpenGame(bool newInstance)
	{
		let context = mServices.Context;
		if (!newInstance && (mGamePage != null))
		{
			Reveal(mGamePage);
			return;
		}
		if (context.GamePageFactory == null)
		{
			context.Notify(.Info, "No game page registered in this build.");
			return;
		}
		let id = new String("game-page");
		if (newInstance)
			id.AppendF("-{}", mGamePages + 1);
		let made = context.GamePageFactory(newInstance, id);
		let page = made as UIEditorPage;
		if (page == null)
		{
			delete made; // none, or one with nowhere to show
			delete id;
			return;
		}
		context.AdoptPage(page);
		if (newInstance)
			++mGamePages;
		else
			mGamePage = page;
		Dock(page, id);
	}

	/// Closes a page as its tab does: one with unsaved changes asks first.
	public void RequestClose(EditorPage page)
	{
		let index = IndexOf(page);
		if (index >= 0)
			mServices.Dock.Controller.Close(mOpen[index].Panel);
	}

	/// Closes a page for good at the next frame, without asking (a deleted asset's, an agent's).
	public void Close(EditorPage page)
	{
		if ((IndexOf(page) >= 0) && !mClosing.Contains(page))
			mClosing.Add(page);
	}

	/// Closes every page now (the project closing): their resources go while the device lives.
	public void CloseAll()
	{
		mClosing.Clear();
		while (!mOpen.IsEmpty)
			CloseNow(mOpen.Back.Page);
	}

	/// Saves a page, then what live tools edited in cooked products (any save flushes them).
	public void Save(EditorPage page)
	{
		let sources = Sources;
		let context = mServices.Context;
		if (page.Save() case .Ok)
			context.Notify(.Success, scope $"Saved '{page.Title}'.");
		else
			context.Notify(.Error, "Save FAILED (see Console).");
		if ((sources != null) && context.HasPendingAssetEdits)
		{
			if (context.DrainAssetEdits(sources) case .Ok)
				context.Notify(.Success, "Persisted live asset edits.");
			else
				context.Notify(.Error, "Asset-edit persist FAILED (see Console).");
		}
	}

	/// One frame, after the GUI laid out (viewport rects are current): Tick, then each page's
	/// frame hook.
	public void Update(IApplicationHost host, float dt)
	{
		Tick();
		for (let open in mOpen)
			open.Page.OnUpdate(host, dt);
	}

	/// The closes asked for run, and the tabs say each page's name, unsaved mark and active mark.
	public void Tick()
	{
		RunCloses();
		SyncTabs();
	}

	/// Each page's offscreen content, inside the scene renderer's bracket.
	public void Render(IApplicationHost host, ref FrameContext frame)
	{
		for (let open in mOpen)
			open.Page.OnRenderWindow(host, ref frame);
	}

	/// Each page's overlays on the composed targets (the Game tab's screen-tier UI), after the
	/// bracket.
	public void AfterSceneRender(IApplicationHost host, ref FrameContext frame)
	{
		for (let open in mOpen)
			open.Page.OnAfterSceneRender(host, ref frame);
	}

	/// The open pages with an asset, and the active one, into the store.
	public void Capture(Settings store)
	{
		let pages = scope List<Guid>();
		Guid active = .Empty;
		for (let open in mOpen)
		{
			if (!open.Page.InstanceId.IsSet)
				continue; // a Game tab: nothing to reopen
			pages.Add(open.Page.InstanceId);
			if (mServices.Context.ActivePage === open.Page)
				active = open.Page.InstanceId;
		}
		ProjectEditorSettings.CaptureOpenPages(store, pages, active);
	}

	/// The store's open pages opened again (`progress` hears each, its name and the share done
	/// before it: the splash), the active one active. False when none were saved (a project's
	/// first open: the caller opens the default scene).
	public bool Restore(Settings store, delegate void(StringView name, float done) progress = null)
	{
		let sources = Sources;
		if (sources == null)
			return false;
		let pages = scope List<Guid>();
		Guid active;
		if (ProjectEditorSettings.ApplyOpenPages(store, pages, out active) case .Err)
			return false;
		UIEditorPage toActivate = null;
		for (int i < pages.Count)
		{
			let instance = sources.GetInstance(pages[i]);
			if (instance == null)
				continue; // deleted since
			if (progress != null)
				progress(instance.Name, (float)i / (float)pages.Count);
			let page = Open(instance);
			if ((page != null) && (pages[i] == active))
				toActivate = page;
		}
		if (toActivate != null)
			Reveal(toActivate);
		return true;
	}

	/// Brings a page's tab to front (a background tab's viewport never renders) and makes it the
	/// active page.
	public void Reveal(EditorPage page)
	{
		let index = IndexOf(page);
		if (index < 0)
			return;
		let panel = scope String(mOpen[index].Panel);
		mServices.Dock.Controller.Edit(scope (layout) => layout.Activate(panel));
		mServices.Context.SetActivePage(page);
	}

	public int Count => mOpen.Count;

	/// The panel id a page is docked by; null for a page not open here. Ours.
	public String PanelOf(EditorPage page)
	{
		let index = IndexOf(page);
		return (index >= 0) ? mOpen[index].Panel : null;
	}

	/// The panel id of an asset's page: its guid, as the Sedulous.UI dock's persistence ids were
	/// (a saved layout's places carry over).
	public static void PanelIdOf(Guid id, String outPanel)
	{
		id.ToString(outPanel, 'D');
	}

	/// How many pages have unsaved changes.
	public int DirtyCount
	{
		get
		{
			int count = 0;
			for (let open in mOpen)
			{
				if (open.Page.IsDirty)
					++count;
			}
			return count;
		}
	}

	/// A page's panel: its content the page's, closing it asks the page. TAKES OWNERSHIP of
	/// `panel`.
	private void Dock(UIEditorPage page, String panel)
	{
		let dock = mServices.Dock.Controller;
		if (dock.Describe(panel) != null)
			dock.Unregister(panel); // a page closed this frame, open again
		mOpen.Add(.(page, panel));
		let description = new DockPanelDescription();
		description.Id.Set(panel);
		description.Title.Set(page.Title);
		description.Close = .Destroy;
		description.Default.Central = true;
		// The page holds its content; the controller takes a reference of its own.
		description.Factory = new [=page] () =>
			{
				let content = page.Content;
				if (content != null)
					content.AddRef();
				return content;
			};
		// Closing always comes back here: the page asks (unsaved changes) and goes at the next
		// frame, its panel with it.
		description.CanClose = new [=page, =this] () =>
			{
				AskToClose(page);
				return false;
			};
		dock.Register(description);
		if (dock.Layout.StackOf(panel) == cNoDock)
			dock.Show(panel); // else a restored layout placed it
		Reveal(page);
	}

	private void AskToClose(UIEditorPage page)
	{
		if (!page.IsDirty)
		{
			Close(page);
			return;
		}
		let root = (mServices.DialogRoot != null) ? mServices.DialogRoot() : null;
		if (root == null)
			return; // nothing to ask over: it stays open
		if ((mAsking != null) && mAsking.IsOpen)
			return; // asking already
		if (mAsking != null)
			mAsking.ReleaseRef();
		let question = new MessageBox();
		mAsking = question;
		question.Configure("Unsaved changes", scope $"'{page.Title}' has unsaved changes.", .Ok);
		question.ClearButtons();
		question.AddButton("Discard", "discard", .Destructive);
		question.AddButton("Cancel", "cancel", .Cancel);
		question.AddButton("Save", "save", .Primary);
		question.AddEventListener(.Changed, new [=question, =page, =this] (e) => { Answered(page, question.ResultName); });
		question.OpenModal(root);
	}

	private void Answered(UIEditorPage page, StringView answer)
	{
		if (IndexOf(page) < 0)
			return; // closed meanwhile
		if (answer == "save")
		{
			if (!(page.Save() case .Ok))
			{
				mServices.Context.Notify(.Error, "Save FAILED (see Console) - the page stays open.");
				return;
			}
			Close(page);
		}
		else if (answer == "discard")
			Close(page);
	}

	private void RunCloses()
	{
		if (mClosing.IsEmpty)
			return;
		// A page's close may ask for another's: that one runs at the frame after.
		let closing = scope List<EditorPage>();
		closing.AddRange(mClosing);
		mClosing.Clear();
		for (let page in closing)
			CloseNow(page);
	}

	private void CloseNow(EditorPage page)
	{
		let index = IndexOf(page);
		if (index < 0)
			return;
		let panel = mOpen[index].Panel;
		let uiPage = mOpen[index].Page;
		mOpen.RemoveAt(index);
		defer delete panel;
		if (uiPage === mGamePage)
			mGamePage = null;
		if (uiPage.IsDirty)
			mServices.Context.SetStatus("Closed page had unsaved changes."); // its changes are gone
		mServices.Dock.Controller.Unregister(panel); // its content out of the GUI first
		uiPage.OnClose(); // its resources while the device and window live
		mServices.Context.ClosePage(uiPage); // destroys it
	}

	private void SyncTabs()
	{
		let sources = Sources;
		let dock = mServices.Dock.Controller;
		let active = mServices.Context.ActivePage;
		let title = scope String();
		for (let open in mOpen)
		{
			// The live asset's name: a rename elsewhere would leave the tab stale.
			let instance = ((sources != null) && open.Page.InstanceId.IsSet) ? sources.GetInstance(open.Page.InstanceId) : null;
			title.Set((instance != null) ? instance.Name : open.Page.Title);
			let dirty = open.Page.IsDirty;
			if (dirty)
				title.Append(" *");
			dock.SetTitle(open.Panel, title);
			let isActive = open.Page === active;
			StringView classes = (dirty && isActive) ? "dirty active" : dirty ? "dirty" : isActive ? "active" : "";
			dock.SetTabClasses(open.Panel, classes);
		}
	}

	/// The dock's active panel changed: a page's makes it the active page; another panel's
	/// (Assets, the Console) leaves the active page as it was.
	private void NoteActivePanel(StringView panel)
	{
		for (let open in mOpen)
		{
			if (open.Panel == panel)
			{
				mServices.Context.SetActivePage(open.Page);
				return;
			}
		}
	}

	/// Its uncooked dependencies cook without a step of the user's: every resource requested in
	/// the page's resolve with no product, and the page's own asset when its cook is missing or
	/// failed.
	private void CookMissing(Instance instance)
	{
		let cook = mServices.Cook;
		if (cook == null)
			return;
		let sources = Sources;
		let roots = scope List<Guid>();
		let resources = (mServices.Resources != null) ? mServices.Resources() : null;
		if (resources != null)
		{
			let unresolved = scope List<Guid>();
			resources.CollectUnresolved(unresolved);
			// Only ids with a live source can cook: a reference to a deleted asset stays
			// unresolved, and must not ask for a cook on every open.
			for (let id in unresolved)
			{
				if ((sources != null) && (sources.GetInstance(id) != null))
					roots.Add(id);
			}
		}
		let badge = cook.BadgeFor(instance);
		if ((badge == .Missing) || (badge == .Failed))
			roots.Add(instance.Id);
		if (!roots.IsEmpty)
			cook.RequestCookFor(roots, false);
	}

	private ContentDatabase Sources
	{
		get
		{
			let project = (mServices.Project != null) ? mServices.Project() : null;
			return (project != null) ? project.SourceDb : null;
		}
	}

	private int IndexOf(EditorPage page)
	{
		for (int i < mOpen.Count)
		{
			if (mOpen[i].Page === page)
				return i;
		}
		return -1;
	}
}
