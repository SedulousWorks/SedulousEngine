using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The menu bar GENERATED from the action registry. Every action with a MenuPath ("File/Save",
/// "Scene/Simulate/Play") lands in the menu its first segment names, the rest as nested
/// submenus. Menus appear in the order their names first appear among the registrations (the
/// application registers its set in menu order, domains add later; a menu holding only leading
/// items comes after them); items order by MenuOrder with a separator between order bands
/// (hundreds). A menu's items are rebuilt when it opens, so every item's enabled state is the
/// registry's answer at that moment, and every item executes through the registry, the one
/// funnel. A menu may carry LEADING items that are not actions, a list-driven set such as File >
/// New <creator>, through AddLeadingItems; they come first, then a separator.
class ActionMenuBar
{
	private class Leading
	{
		public String Menu = new .() ~ delete _;
		/// OWNED.
		public delegate void(ContextMenu menu) Items ~ delete _;
	}

	/// BORROWED: the shell owns the bar, the context the registry; both outlive this.
	private MenuBar mBar;
	private EditorActionRegistry mActions;
	/// Owned by the registry's event while subscribed; removed (and deleted) with this.
	private delegate void() mOnActionsChanged;
	private List<Leading> mLeading = new .() ~ DeleteContainerAndItems!(_);

	public this(MenuBar bar, EditorActionRegistry actions)
	{
		mBar = bar;
		mActions = actions;
		mOnActionsChanged = new => Rebuild;
		mActions.OnActionsChanged.Add(mOnActionsChanged);
		Rebuild();
	}

	public ~this()
	{
		mActions.OnActionsChanged.Remove(mOnActionsChanged, true);
		// The menus' opening hooks capture this.
		mBar.ClearMenus();
	}

	/// Items that are not actions, at the top of `menu` (created when absent): the list-driven
	/// sets. TAKES OWNERSHIP of the delegate. Rebuilt with the menu.
	public void AddLeadingItems(StringView menu, delegate void(ContextMenu menu) items)
	{
		let entry = new Leading();
		entry.Menu.Set(menu);
		entry.Items = items;
		mLeading.Add(entry);
		Rebuild();
	}

	/// The whole bar from the registry: the menus and their current items.
	public void Rebuild()
	{
		mBar.ClearMenus();
		// Menus in the order their names first appear among the actions; a menu that holds
		// only leading items comes after them.
		for (let action in mActions.Actions)
		{
			if (!action.MenuPath.IsEmpty)
				MenuFor(TopLevel(action.MenuPath));
		}
		for (let leading in mLeading)
			MenuFor(leading.Menu);
		for (int i < mBar.MenuCount)
		{
			let menu = mBar.MenuAt(i);
			let title = new String(mBar.MenuTitle(i));
			menu.OnOpening = new [=this, =title](opening) => { Fill(title, opening); } ~ delete title;
			Fill(title, menu);
		}
	}

	/// The items of one top level menu, as the registry answers now.
	public void Fill(StringView title, ContextMenu menu)
	{
		menu.ClearItems();
		bool any = false;
		for (let leading in mLeading)
		{
			if (leading.Menu == title)
			{
				leading.Items(menu);
				any = menu.ItemCount > 0;
			}
		}
		// This menu's actions in MenuOrder, registration order breaking ties, nested by the
		// rest of their path.
		let ordered = scope List<(EditorActionDeclaration action, int index)>();
		for (let action in mActions.Actions)
		{
			if (!action.MenuPath.IsEmpty && (TopLevel(action.MenuPath) == title))
				ordered.Add((action, @action.Index));
		}
		ordered.Sort(scope (a, b) => (a.action.MenuOrder != b.action.MenuOrder) ? (a.action.MenuOrder <=> b.action.MenuOrder) : (a.index <=> b.index));
		if (any && !ordered.IsEmpty)
			menu.AddSeparator();
		int32 band = 0;
		bool first = true;
		for (let entry in ordered)
		{
			let thisBand = entry.action.MenuOrder / 100;
			if (!first && (thisBand != band))
				menu.AddSeparator();
			band = thisBand;
			first = false;
			AddItem(menu, Rest(entry.action.MenuPath), entry.action);
		}
	}

	private static StringView TopLevel(StringView path)
	{
		let slash = path.IndexOf('/');
		return (slash >= 0) ? path.Substring(0, slash) : path;
	}

	private static StringView Rest(StringView path)
	{
		let slash = path.IndexOf('/');
		return (slash >= 0) ? path.Substring(slash + 1) : StringView();
	}

	private ContextMenu MenuFor(StringView title)
	{
		for (int i < mBar.MenuCount)
		{
			if (mBar.MenuTitle(i) == title)
				return mBar.MenuAt(i);
		}
		return mBar.AddMenu(title);
	}

	/// `path` is the part after the top level menu: "Save", or "Simulate/Play" (a submenu
	/// "Simulate" holding "Play", found when present, created when not).
	private void AddItem(ContextMenu menu, StringView path, EditorActionDeclaration action)
	{
		let head = TopLevel(path);
		let tail = Rest(path);
		if (tail.IsEmpty)
		{
			// Captures the registry, not this: the item outlives nothing it needs.
			let registry = mActions;
			menu.AddItem(head, new [=registry, =action]() => { registry.Execute(action.Id).IgnoreError(); }, mActions.IsEnabled(action.Id));
			return;
		}
		ContextMenu submenu = null;
		for (int i < menu.ItemCount)
		{
			let item = menu.ItemAt(i);
			if ((item.Submenu != null) && (item.Label == head))
			{
				submenu = item.Submenu;
				break;
			}
		}
		if (submenu == null)
			submenu = menu.AddSubmenu(head).Submenu;
		AddItem(submenu, tail, action);
	}
}
