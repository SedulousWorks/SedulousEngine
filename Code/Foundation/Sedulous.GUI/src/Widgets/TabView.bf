using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// TabView: a TabBar over the pages its tabs show, Godot's TabContainer. Its pages are its children
// (markup's `<tabpage title="...">`, or AddPage), each with a tab in the bar that follows its
// title, icon and `closable`. Only the selected page is shown; the others stay alive, as they are
// (Godot's way), unless a page builds itself the first time it is shown (a content factory). A
// close request reports `tabclose` at the view, and unless a listener takes it, the page and its
// tab go. Ctrl+Tab and Ctrl+Shift+Tab cycle the pages with the focus anywhere inside the view.

/// One page of a TabView: its tab's title, icon and closable, and what it holds.
[GuiReflect(true), Scriptable]
class TabPage : Panel
{
	private String mTitle = new .() ~ delete _;
	private String mIcon = new .() ~ delete _;
	private String mTabClasses = new .() ~ delete _;
	private bool mClosable = true;
	// Owned by the view's bar.
	private Sedulous.GUI.Tab mTab = null;
	private delegate void(TabPage page) mFactory ~ delete _;

	public this()
	{
		Tag = "tabpage";
		AccessRoleName = "tabpanel"; // what a screen reader takes it for
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		}
	}

	/// Its tab's text.
	[GuiProperty("title", .None, "name"), Scriptable]
	public StringView Title
	{
		get => mTitle;
		set
		{
			let title = scope String(value);
			mTitle.Set(title);
			if (mTab != null)
				mTab.Text = title;
		}
	}

	/// Its tab's icon, by path (loaded through the GUI's resource provider).
	[GuiProperty("icon"), Scriptable]
	public StringView Icon
	{
		get => mIcon;
		set
		{
			let path = scope String(value);
			mIcon.Set(path);
			if (mTab != null)
				mTab.Icon = path;
		}
	}

	/// Its tab can be closed.
	[GuiProperty("closable"), Scriptable]
	public bool Closable
	{
		get => mClosable;
		set
		{
			mClosable = value;
			if (mTab != null)
				mTab.Closable = value;
		}
	}

	/// The classes its tab carries, space-separated (a document's unsaved mark, say): the tab's
	/// own, replacing the ones set before.
	[GuiProperty("tab-class"), Scriptable]
	public StringView TabClasses
	{
		get => mTabClasses;
		set
		{
			let classes = scope String(value);
			if (mTab != null)
			{
				mTab.RemoveClasses(mTabClasses);
				mTab.AddClasses(classes);
			}
			mTabClasses.Set(classes);
		}
	}

	/// Builds what it holds the first time it is shown (a heavy page left unbuilt until wanted).
	/// OWNERSHIP of `factory` transfers.
	public void SetContentFactory(delegate void(TabPage page) factory)
	{
		delete mFactory;
		mFactory = factory;
	}

	/// Its tab (null while it is in no view).
	public Sedulous.GUI.Tab Tab => mTab;

	// Its tab, which then takes its title, icon, closable and classes.
	internal void Attach(Sedulous.GUI.Tab tab)
	{
		mTab = tab;
		if (tab == null)
			return;
		tab.Text = mTitle;
		if (!mIcon.IsEmpty)
			tab.Icon = mIcon;
		tab.Closable = mClosable;
		tab.AddClasses(mTabClasses);
	}

	internal void Realize()
	{
		if (mFactory == null)
			return;
		let factory = mFactory;
		mFactory = null;
		factory(this);
		delete factory;
	}
}

// What holds the pages: it tells its view when they change.
[GuiReflect]
class TabPageHost : Panel
{
	// Its parent, which owns it.
	private TabView mView;

	public this(TabView view)
	{
		mView = view;
		Tag = "tabpages";
		ClipChildren = true;
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Grow = 1.0f;
					s.MinHeight = LayoutLength.Px(0.0f);
				});
		}
	}

	public override void OnChildrenChanged()
	{
		mView.SyncPages();
	}
}

[GuiReflect(true), Scriptable]
class TabView : UIWidget
{
	private TabBar mBar ~ _.ReleaseRef();
	private TabPageHost mHost ~ _.ReleaseRef();
	private delegate void(int32 to) mOnPageMoved ~ delete _;
	private delegate void(int32 index) mOnSelected ~ delete _;

	public this()
	{
		Tag = "tabview";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.AlignItems = .Stretch;
				});
		}
		mBar = new TabBar();
		AddChild(mBar);
		mHost = new TabPageHost(this);
		AddChild(mHost);

		mBar.SetOnSelectionChanged(new (index) => { ShowSelected(); });
		mBar.SetOnSelected(new (index) =>
			{
				if (mOnSelected != null)
					mOnSelected(index);
				SendEvent(scope Event(.Changed, this));
			});
		mBar.SetOnTabMoved(new (from, to) =>
			{
				// The pages keep the tabs' order (a script's children read as the strip does).
				let page = mBar.GetTab(to).Page;
				if (page != null)
					mHost.SetChildIndex(page, to);
				if (mOnPageMoved != null)
					mOnPageMoved(to);
			});
		mBar.SetOnTabRemoved(new (tab) =>
			{
				// Code removed the tab from the bar: its page goes with it.
				let page = tab.Page;
				if ((page != null) && (page.Parent == mHost))
					mHost.RemoveChild(page);
			});
		mBar.SetCloseHandler(new (index) => { RequestClose(index); });
		// A tab dropped here from another view brings its page.
		mBar.SetPageAdopter(new (page, index) => { mHost.AddChildAt(page, Math.Max(0, index)); });
	}

	// === Pages ===

	/// Adds a page titled `title` at the end and returns it to fill.
	public TabPage AddPage(StringView title)
	{
		let page = new TabPage();
		page.Title = title;
		mHost.AddChild(page);
		page.ReleaseRef(); // the host's reference keeps it
		return page;
	}

	/// Adds a page made elsewhere (any node: one not a TabPage has an empty tab). The host takes a
	/// reference of its own: the caller keeps its.
	public void AddPage(Node page)
	{
		mHost.AddChild(page);
	}

	[Scriptable]
	public void RemovePage(int32 index)
	{
		let page = GetPage(index);
		if (page != null)
			mHost.RemoveChild(page);
	}

	[Scriptable]
	public int32 PageCount => mBar.TabCount;

	/// A page by its tab's index (the tabs' order, which a drag changes).
	public Node GetPage(int32 index)
	{
		let tab = mBar.GetTab(index);
		return (tab != null) ? tab.Page : null;
	}

	// === Selection (the bar's) ===

	[GuiProperty("selected", .TwoWay), Scriptable]
	public int32 SelectedIndex
	{
		get => mBar.SelectedIndex;
		set => mBar.SelectedIndex = value;
	}

	public Node SelectedPage => GetPage(mBar.SelectedIndex);

	/// The user selected a page (the `change` event's). OWNERSHIP of `callback` transfers.
	public void SetOnSelected(delegate void(int32 index) callback)
	{
		delete mOnSelected;
		mOnSelected = callback;
	}

	/// The user dragged a page's tab to another place in the strip; `to` is where it is now.
	/// OWNERSHIP of `callback` transfers.
	public void SetOnPageMoved(delegate void(int32 to) callback)
	{
		delete mOnPageMoved;
		mOnPageMoved = callback;
	}

	// === The bar's settings, from markup ===

	[GuiProperty("close-display"), Scriptable]
	public StringView CloseDisplayName
	{
		get => mBar.CloseDisplayName;
		set => mBar.CloseDisplayName = value;
	}

	[GuiProperty("list-display"), Scriptable]
	public StringView ListDisplayName
	{
		get => mBar.ListDisplayName;
		set => mBar.ListDisplayName = value;
	}

	[GuiProperty("close-all"), Scriptable]
	public bool ShowsCloseAll
	{
		get => mBar.ShowsCloseAll;
		set => mBar.ShowsCloseAll = value;
	}

	[GuiProperty("reorderable"), Scriptable]
	public bool Reorderable
	{
		get => mBar.Reorderable;
		set => mBar.Reorderable = value;
	}

	[GuiProperty("group"), Scriptable]
	public StringView Group
	{
		get => mBar.Group;
		set => mBar.Group = value;
	}

	/// Asks to close a page, as its tab's close part does: `tabclose` is reported here, and unless
	/// a listener takes it, the page goes.
	public void RequestClose(int32 index)
	{
		let tab = mBar.GetTab(index);
		if ((tab == null) || !tab.Closable)
			return;
		let request = scope TabEvent(.TabClose, this, index);
		SendEvent(request);
		if (!request.Handled)
			RemovePage(index);
	}

	public TabBar Bar => mBar;
	/// Markup's children are its pages.
	public override Node ChildHost => mHost;

	// A torn-out tab of its group dropped anywhere over the view (not only its strip) goes last;
	// over the strip, the strip places it.
	protected override void OnDragQuery(DropQuery query)
	{
		mBar.OfferTab(query, mBar.TabCount);
	}

	protected override void OnDragLeave(DragEvent e)
	{
		mBar.ClearTabMark();
	}

	protected override void OnDrop(DragEvent e)
	{
		mBar.DropTab(e.Payload);
	}

	// Its bar writes in its font (and the bar's tabs).
	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mBar, false);
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let step = TabBar.CycleStep(e);
		if (step == 0)
			return;
		mBar.CycleSelection(step);
		e.Handled = true;
	}

	// The pages changed: a tab for each new one (in the pages' order), none for one gone.
	internal void SyncPages()
	{
		for (int32 i = mBar.TabCount; i-- > 0;)
		{
			let tab = mBar.GetTab(i);
			let page = tab.Page;
			if ((page != null) && (page.Parent == mHost))
				continue;
			if (let tp = page as TabPage)
				tp.Attach(null);
			tab.Page = null;
			mBar.RemoveTab(i);
		}
		for (int i = 0; i < mHost.ChildCount; ++i)
		{
			let page = mHost.GetChildAt(i);
			if (TabOf(page) != null)
				continue;
			let tab = mBar.InsertTab((int32)i, default);
			tab.Page = page;
			if (let tp = page as TabPage)
				tp.Attach(tab);
		}
		ShowSelected();
	}

	private Tab TabOf(Node page)
	{
		for (int32 i = 0; i < mBar.TabCount; ++i)
		{
			if (mBar.GetTab(i).Page == page)
				return mBar.GetTab(i);
		}
		return null;
	}

	// The selected tab's page alone is shown (built now if it builds itself).
	private void ShowSelected()
	{
		let selected = mBar.SelectedTab;
		for (int i = 0; i < mHost.ChildCount; ++i)
		{
			let page = mHost.GetChildAt(i);
			let shown = (selected != null) && (selected.Page == page);
			if (shown)
			{
				if (let tp = page as TabPage)
					tp.Realize();
			}
			page.Displayed = shown;
		}
	}
}
