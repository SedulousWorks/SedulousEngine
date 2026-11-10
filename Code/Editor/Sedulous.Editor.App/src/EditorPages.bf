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
	/// A dialog's markup by its path under the data root (Save As's), its one reference the
	/// caller's; unset, or null back: no dialog. Owned.
	public delegate Node(StringView path) LoadMarkup ~ delete _;
}

/// The open pages in the dock. A page is a panel of
/// its own, by its asset's guid (a Game tab by its play id: `game-page`, `game-page-1`, ...),
/// the ids a saved layout and the MCP layout tools name; it opens in the central stack, or where
/// a restored layout kept its place. Its tab says its asset's name, a ` *` and the `dirty` class
/// while it has unsaved changes, and the `active` class on the page the editor acts on (Save,
/// the inspector): the chosen tab of the stack the focus was last in. Closing a page with unsaved
/// changes asks first (Save, Discard, Cancel); a close always runs at the next frame, never
/// inside the event that asked for it, and takes the page's panel with it. The open pages and
/// the active one are saved with the project and reopen with it. Before an exit (or a
/// project's close) the unsaved pages are asked about as one: save them all, cancel,
/// or go on without saving. Save As writes a page into a new asset beside its own, named in a
/// dialog of its own markup (Data/Editor/SaveAs.xml); the page edits the new asset after.
class EditorPages
{
	/// Save As's dialog, under the data root.
	public const String cSaveAsPath = "Editor/SaveAs.xml";
	private const float cSaveAsWidth = 420.0f;
	private const float cSaveAsHeight = 200.0f;

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
	/// The last Save As dialog, a reference of ours: its buttons close it from inside their own
	/// click, which may let the tree's reference go. One at a time, as the questions.
	private Sedulous.GUI.Window mSavingAs = null ~ _?.ReleaseRef();

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
		// And an open Save As saves into nothing.
		if ((mSavingAs != null) && mSavingAs.IsOpen)
			mSavingAs.Close();
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

	/// A user's open of the source asset `id` (the browser's, a slot's Open): an editor that claims
	/// it takes it first (the scene page on screen takes a property animation clip into its panel);
	/// else its page opens. False when nothing took it.
	public bool OpenForUser(Guid id)
	{
		let sources = Sources;
		let instance = (sources != null) ? sources.GetInstance(id) : null;
		if (instance == null)
			return false;
		if ((mServices.Context != null) && mServices.Context.TryInterceptOpenAsset(instance))
			return true;
		return Open(instance) != null;
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

	/// Closes every page editing `asset` now, without asking: what deletes the asset calls it
	/// before the instance goes, outside an event's dispatch. A close asked for one of them is
	/// forgotten with it.
	public void CloseAssetNow(Guid asset)
	{
		let pages = scope List<EditorPage>();
		for (let open in mOpen)
		{
			if (open.Page.InstanceId == asset)
				pages.Add(open.Page);
		}
		for (let page in pages)
		{
			mClosing.Remove(page);
			CloseNow(page);
		}
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
		if (context.SavePage(page) case .Ok) // a page whose file went on disk writes it back
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

	/// The unsaved pages, before `proceed` (an exit; a project's close): with none it
	/// runs now; else the user is asked to save them all, keep working, or go on without saving,
	/// the verbs the caller's (`saveVerb` "Save All and Exit", `discardVerb` "Exit Without
	/// Saving"), and it runs only when they chose to go on and every page saved. With nowhere to
	/// ask, or a question showing already, the unsaved work stays and nothing runs. Answers
	/// whether it ran now. TAKES OWNERSHIP of `proceed`.
	public bool ConfirmUnsavedThen(StringView saveVerb, StringView discardVerb, delegate void() proceed)
	{
		let dirty = DirtyCount;
		if (dirty == 0)
		{
			defer delete proceed;
			proceed();
			return true;
		}
		let root = (mServices.DialogRoot != null) ? mServices.DialogRoot() : null;
		if ((root == null) || ((mAsking != null) && mAsking.IsOpen))
		{
			delete proceed; // nothing to ask over, or asking already: the unsaved work stays
			return false;
		}
		if (mAsking != null)
			mAsking.ReleaseRef();
		let question = new MessageBox();
		mAsking = question;
		// Each named, as the page's tab and its panels name them (a count says nothing of where).
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		for (let open in mOpen)
			UnsavedLines(open.Page, lines);
		question.Configure("Unsaved changes", UnsavedText(lines, .. scope String()), .Ok);
		question.ClearButtons();
		question.AddButton(discardVerb, "discard", .Destructive);
		question.AddButton("Cancel", "cancel", .Cancel);
		question.AddButton(saveVerb, "save", .Primary);
		question.AddEventListener(.Changed, new [=question, =proceed, =this] (e) => { AnsweredUnsaved(question.ResultName, proceed); } ~ delete proceed);
		question.OpenModal(root);
		return false;
	}

	/// Saves every page with unsaved changes; false when one failed (the rest still tried).
	public bool SaveAll()
	{
		bool all = true;
		for (let open in mOpen)
		{
			if (open.Page.IsDirty && !(mServices.Context.SavePage(open.Page) case .Ok))
				all = false;
			if (open.Page.HasUnsavedWork && !(open.Page.SaveBesides() case .Ok))
				all = false; // a clip its panel edits
		}
		return all;
	}

	/// Save As: the page's content into a new asset beside its own, named in a dialog (a name
	/// AssetNames refuses keeps the dialog open, saying why under the field); the page edits the new
	/// asset after, its panel by the new guid. Nothing with nowhere to show the dialog, or with
	/// one open already.
	public void SaveAs(EditorPage page)
	{
		let sources = Sources;
		let original = ((sources != null) && page.InstanceId.IsSet) ? sources.GetInstance(page.InstanceId) : null;
		if (original == null)
		{
			mServices.Context.Notify(.Warning, "This page has no source asset to copy.");
			return;
		}
		let root = (mServices.DialogRoot != null) ? mServices.DialogRoot() : null;
		if ((root == null) || ((mSavingAs != null) && mSavingAs.IsOpen))
			return;
		let body = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(cSaveAsPath) : null;
		if (body == null)
			return;
		defer body.ReleaseRef(); // the window holds its own
		let prompt = body.FindElement("save-as-prompt") as Sedulous.GUI.Label;
		let name = body.FindElement("save-as-name") as Sedulous.GUI.TextField;
		let error = body.FindElement("save-as-error") as Sedulous.GUI.Label;
		let save = body.FindElement("save-as-save") as Sedulous.GUI.Button;
		let cancel = body.FindElement("save-as-cancel") as Sedulous.GUI.Button;
		if ((name == null) || (save == null))
			return;

		let group = original.OwningGroup;
		let suggested = scope String()..AppendF("{} Copy", original.Name);
		while (group.GetInstance(suggested) != null)
			suggested.Append(" Copy");
		if (prompt != null)
			prompt.Text = scope $"A new asset beside '{original.Name}', named:";
		name.Text = suggested;

		if (mSavingAs != null)
			mSavingAs.ReleaseRef();
		let window = new Sedulous.GUI.Window();
		mSavingAs = window;
		window.Title = "Save As";
		window.AddClass("save-as-window");
		window.Size = .(cSaveAsWidth, cSaveAsHeight);
		window.Content.AddChild(body);
		// The page by its asset's guid: it may close, or its asset go, while the dialog shows.
		let pageId = page.InstanceId;
		save.SetOnClick(new [=pageId, =name, =error, =this] () => { CommitSaveAs(pageId, name, error); });
		name.SetOnSubmit(new [=pageId, =name, =error, =this] (text) => { CommitSaveAs(pageId, name, error); });
		if (cancel != null)
			cancel.SetOnClick(new [=window] () => { window.Close(); });
		window.OpenModal(root);
		name.FocusElement();
		name.SelectAll();
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

	/// What is unsaved on `page`, a line each (the caller's to delete): its own changes by its name
	/// ("Level1"), the work it holds besides with its name ("The clip 'Bounce', in Level1").
	private static void UnsavedLines(EditorPage page, List<String> outLines)
	{
		if (page.IsDirty)
			outLines.Add(new String(page.Title));
		let besides = scope List<String>();
		defer { ClearAndDeleteItems!(besides); }
		page.ListUnsavedBesides(besides);
		for (let work in besides)
			outLines.Add(new String()..AppendF("{}, in {}", work, page.Title));
	}

	/// The prompt's words for `lines`: one in a sentence, several listed.
	private static void UnsavedText(List<String> lines, String outText)
	{
		if (lines.Count == 1)
		{
			outText.AppendF("{} has unsaved changes.", lines[0]);
			return;
		}
		outText.Append("These have unsaved changes:");
		for (let line in lines)
			outText.AppendF("\n    {}", line);
	}

	/// How many pages have unsaved changes, or hold unsaved work of their own (a clip).
	public int DirtyCount
	{
		get
		{
			int count = 0;
			for (let open in mOpen)
			{
				if (open.Page.HasUnsavedWork)
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
		if (!page.HasUnsavedWork)
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
		// What is unsaved, each named: the page's own changes, the work it holds besides (a clip).
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		UnsavedLines(page, lines);
		question.Configure("Unsaved changes", UnsavedText(lines, .. scope String()), .Ok);
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
			if ((page.IsDirty && !(mServices.Context.SavePage(page) case .Ok)) || !(page.SaveBesides() case .Ok))
			{
				mServices.Context.Notify(.Error, "Save FAILED (see Console) - the page stays open.");
				return;
			}
			Close(page);
		}
		else if (answer == "discard")
			Close(page);
	}

	/// The unsaved-pages question answered: discard goes on, save goes on once every page saved,
	/// cancel (or the box closed) stays.
	private void AnsweredUnsaved(StringView answer, delegate void() proceed)
	{
		if (answer == "discard")
			proceed();
		else if (answer == "save")
		{
			if (SaveAll())
				proceed();
			else
				mServices.Context.Notify(.Error, "Save FAILED (see Console) - nothing closed.");
		}
	}

	/// Save As's Save (or Enter in the name): a name AssetNames refuses (empty or taken among them)
	/// is refused under the field, the dialog kept for the retry; else the page saves into the new asset and the dialog goes.
	private void CommitSaveAs(Guid pageId, Sedulous.GUI.TextField name, Sedulous.GUI.Label error)
	{
		let sources = Sources;
		let original = (sources != null) ? sources.GetInstance(pageId) : null;
		if (original == null)
		{
			mSavingAs.Close(); // its asset gone meanwhile: nothing to save beside
			return;
		}
		let group = original.OwningGroup;
		let newName = scope String(name.Text);
		let refused = AssetNames.Refusal(group, newName, .. scope .()); // the rule Create Asset keeps
		if (!refused.IsEmpty)
		{
			if (error != null)
				error.Text = refused;
			return; // the dialog stays for the retry
		}
		SaveAsNamed(pageId, group, newName);
		mSavingAs.Close();
	}

	/// The page `pageId` (if still open) saved into a new asset `newName` in `group`, as Sedulous's
	/// pages write one: the instance made by the original's stored type name, the page rebound to
	/// it (OnSavedAs), its panel by the new guid, then its Save.
	private void SaveAsNamed(Guid pageId, Group group, StringView newName)
	{
		let context = mServices.Context;
		let sources = Sources;
		let original = (sources != null) ? sources.GetInstance(pageId) : null;
		int index = -1;
		for (int i < mOpen.Count)
		{
			if (mOpen[i].Page.InstanceId == pageId)
				index = i;
		}
		if ((index < 0) || (original == null))
			return; // closed meanwhile
		let target = mOpen[index].Page;
		// CreateInstance hands back whatever holds a taken name, and the save below would write over
		// it: the dialog refuses one, and this holds the same rule for any caller.
		let refused = AssetNames.Refusal(group, newName, .. scope .());
		if (!refused.IsEmpty)
		{
			context.Notify(.Error, scope String()..AppendF("Not saved: {}", refused));
			return;
		}
		let fresh = group.CreateInstance(newName, original.TypeName);
		if (fresh == null)
		{
			context.Notify(.Error, "Not saved: the new asset could not be made.");
			return;
		}
		target.OnSavedAs(fresh);
		// The page's panel follows its new asset: the old one goes, one by the new guid comes.
		let oldPanel = mOpen[index].Panel;
		mOpen.RemoveAt(index);
		mServices.Dock.Controller.Unregister(oldPanel);
		delete oldPanel;
		Dock(target, PanelIdOf(fresh.Id, .. new .()));
		if (target.Save() case .Ok)
			context.Notify(.Success, scope $"Saved as '{fresh.Name}'.");
		else
			context.Notify(.Error, "Save As FAILED (see Console).");
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
			// The binds that found no product logged nothing each (the resource manager is told
			// they wait for the cook): one line says it, for the page.
			if (!roots.IsEmpty)
				GlobalLog(.Information, "Editor: '{}': {} referenced assets wait for the cook", instance.Name, roots.Count);
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
