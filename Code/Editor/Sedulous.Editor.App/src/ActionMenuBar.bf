using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The menu bar GENERATED from the action registry (Raptor's editor-gui spec, 5.1, layer 7).
/// Every action with a MenuPath ("File/Save", "Scene/Simulate/Play") lands in the menu its first
/// segment names, the rest as nested submenus. The application declares its menus' order
/// (SetMenuOrder: names, and "*" where every other menu goes), so a domain's menu (Scene), or an
/// extension's, registered later still lands before Help; without a declaration, and for the
/// menus "*" holds, the order their names first appear among the registrations (a menu holding
/// only leading items after them). Items order by MenuOrder, registration order breaking ties,
/// with a separator between order bands (hundreds), each showing its effective chord. The bar is
/// built again when the registry changes (a registration, a rebind); as a menu opens, its items'
/// enabled and checked states are asked of the registry, so they are its answer at that moment;
/// every item executes through the registry, the one funnel. A menu may carry LEADING items that
/// are not actions, a list-driven set such as File > New <creator>, through AddLeadingItems; they
/// come first, then a separator.
class ActionMenuBar
{
	private class Leading
	{
		/// The menu's title.
		public String Title = new .() ~ delete _;
		/// OWNED.
		public delegate void(Menu menu) Items ~ delete _;
	}

	/// An action's item, and the menu (or submenu) it is in. Borrowed: the bar's menus hold them.
	private struct ActionItem
	{
		public Menu Holder;
		public MenuItem Row;
		/// The registry's.
		public EditorActionDeclaration Action;

		public this(Menu holder, MenuItem row, EditorActionDeclaration action)
		{
			Holder = holder;
			Row = row;
			Action = action;
		}
	}

	/// A submenu made from a path segment, so the actions after it under the same segment find
	/// it. Its title is a view of the declaration's MenuPath, which the registry keeps; the list
	/// is made again with the bar.
	private struct KnownSubMenu
	{
		public Menu Parent;
		public StringView Title;
		public Menu SubMenu;

		public this(Menu parent, StringView title, Menu subMenu)
		{
			Parent = parent;
			Title = title;
			SubMenu = subMenu;
		}
	}

	/// BORROWED: the window owns the bar, the context the registry; both outlive this.
	private MenuBar mBar;
	private EditorActionRegistry mActions;
	private List<Leading> mLeading = new .() ~ DeleteContainerAndItems!(_);
	/// SetMenuOrder: names, "*" for every other menu.
	private List<String> mOrder = new .() ~ DeleteContainerAndItems!(_);
	/// The action items of the bar as built.
	private List<ActionItem> mItems = new .() ~ delete _;
	private List<KnownSubMenu> mSubMenus = new .() ~ delete _;
	/// The bar again when the registry changes.
	private Effect mChanged = null ~ delete _;

	public this(MenuBar bar, EditorActionRegistry actions)
	{
		mBar = bar;
		mActions = actions;
		mChanged = new Effect(new () =>
			{
				mActions.TrackChanges();
				// The registry is all it follows: what building the bar reads (its buttons' text)
				// is not recorded, so only a registration or a rebind builds it again.
				Observer.Untracked(scope () => { Rebuild(); });
			});
	}

	/// The bar is left empty and the registry no longer reaches this.
	public ~this()
	{
		DeleteAndNullify!(mChanged);
		// The menus' opening hooks capture this, and a menu may outlive the bar's reference.
		for (int i < mBar.MenuCount)
			mBar.MenuAt(i).SetOnOpening(null);
		for (let known in mSubMenus)
			known.SubMenu.SetOnOpening(null);
		mBar.ClearMenus();
	}

	/// Items that are not actions, at the top of `menu` (made when absent): the list-driven
	/// sets. TAKES OWNERSHIP of the delegate. Made again with the bar.
	public void AddLeadingItems(StringView menu, delegate void(Menu menu) items)
	{
		let entry = new Leading();
		entry.Title.Set(menu);
		entry.Items = items;
		mLeading.Add(entry);
		Rebuild();
	}

	/// The top level menus' order: these names in this order, "*" where every menu not named
	/// goes (in the order it first appears; at the end when there is no "*"). A name with no
	/// actions and no leading items makes no menu.
	public void SetMenuOrder(Span<StringView> order)
	{
		ClearAndDeleteItems!(mOrder);
		for (let name in order)
			mOrder.Add(new .(name));
		Rebuild();
	}

	/// The whole bar from the registry: the menus and their items.
	public void Rebuild()
	{
		mBar.ClearMenus();
		mItems.Clear();
		mSubMenus.Clear();
		// The menus there are, in the order their names first appear among the actions; a menu
		// that holds only leading items comes after them.
		let present = scope List<StringView>();
		for (let action in mActions.Actions)
		{
			if (!action.MenuPath.IsEmpty && !present.Contains(TopLevel(action.MenuPath)))
				present.Add(TopLevel(action.MenuPath));
		}
		for (let leading in mLeading)
		{
			if (!present.Contains(leading.Title))
				present.Add(leading.Title);
		}
		// Then laid out by the declared order; a name declared twice is one menu.
		let titles = scope List<StringView>();
		bool restPlaced = false;
		for (let entry in mOrder)
		{
			if (entry == "*")
			{
				PlaceUndeclared(present, titles);
				restPlaced = true;
			}
			else if (present.Contains(entry) && !titles.Contains(entry))
				titles.Add(entry);
		}
		if (!restPlaced)
			PlaceUndeclared(present, titles);
		for (let title in titles)
			Fill(title, mBar.AddMenu(title));
	}

	/// What each action item of `menu` shows that the registry answers at the moment: enabled (and
	/// why not), and checked for a checkable one.
	public void Refresh(Menu menu)
	{
		for (let item in mItems)
		{
			if (item.Holder != menu)
				continue;
			item.Row.Enabled = mActions.IsEnabled(item.Action.Id);
			item.Row.Tooltip = mActions.DisabledReason(item.Action.Id, .. scope String()); // why it is disabled, when it says
			if (item.Row.Checkable)
				item.Row.SetCheckedSilently(mActions.IsChecked(item.Action.Id));
		}
	}

	/// The present menus the declared order does not name, in the order they first appear.
	private void PlaceUndeclared(List<StringView> present, List<StringView> titles)
	{
		for (let name in present)
		{
			bool declared = false;
			for (let entry in mOrder)
			{
				if (entry == name)
				{
					declared = true;
					break;
				}
			}
			if (!declared && !titles.Contains(name))
				titles.Add(name);
		}
	}

	/// The items of one top level menu.
	private void Fill(StringView title, Menu menu)
	{
		bool any = false;
		for (let leading in mLeading)
		{
			if (leading.Title == title)
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
		Watch(menu);
	}

	/// As it opens, its items' states are the registry's answer.
	private void Watch(Menu menu)
	{
		menu.SetOnOpening(new (opening) => { Refresh(opening); });
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

	/// `path` is the part after the top level menu: "Save", or "Simulate/Play" (a submenu
	/// "Simulate" holding "Play", found when present, made when not).
	private void AddItem(Menu menu, StringView path, EditorActionDeclaration action)
	{
		let head = TopLevel(path);
		let tail = Rest(path);
		if (tail.IsEmpty)
		{
			// Captures the registry, not this: the item needs nothing of the bar to run.
			let registry = mActions;
			let item = menu.AddItem(head, new [=registry, =action]() => { registry.Execute(action.Id).IgnoreError(); });
			item.Shortcut = mActions.Shortcut(action.Id).ToString(.. scope .());
			if (action.Checked != null)
			{
				item.Checkable = true;
				item.SetCheckedSilently(mActions.IsChecked(action.Id));
			}
			item.Enabled = mActions.IsEnabled(action.Id);
			mItems.Add(.(menu, item, action));
			return;
		}
		Menu submenu = null;
		for (let known in mSubMenus)
		{
			if ((known.Parent == menu) && (known.Title == head))
			{
				submenu = known.SubMenu;
				break;
			}
		}
		if (submenu == null)
		{
			submenu = menu.AddSubMenu(head);
			mSubMenus.Add(.(menu, head, submenu));
			Watch(submenu);
		}
		AddItem(submenu, tail, action);
	}
}
