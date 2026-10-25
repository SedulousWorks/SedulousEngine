using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// MenuBar: a horizontal strip of buttons, each opening a Menu below it - the classic
// application menu bar. Modeled on eepp's UIMenuBar (role only). Clicking a button opens its menu,
// a popup of the button; a press on the button again, outside the menu, closes it without
// reopening, as the popup stack consumes it. While a menu is open, hovering a different button
// switches to it: opening that menu closes the other (it does not hold the new one's button), and
// the closed menu's notice clears the bar's state.
//
// The keyboard and the pad: F10 (the `menu.enter-bar` command) focuses the bar's first button;
// Down, Return, Space or a pad's South on a button opens its menu with its first item lit; Left
// and Right move between the buttons, and between the menus while one is open (a submenu's item
// takes Right first, and a submenu Left); Escape closes the menu, focus going back to its button.
//
// In markup its children are its menus, each `<Menu text="File">` a button.

[GuiReflect(true), Scriptable]
class MenuBar : UIWidget
{
	private struct BarEntry
	{
		// Its child.
		public Button BarButton;
		// A reference held.
		public Menu BarMenu;

		public this(Button button, Menu menu)
		{
			BarButton = button;
			BarMenu = menu;
		}
	}

	private List<BarEntry> mEntries = new .() ~ { for (let e in _) e.BarMenu.ReleaseRef(); delete _; };
	// Where markup's menus land, then taken in.
	private Node mMarkupHost = null ~ _?.ReleaseRef();
	// The open menu (not owned).
	private Menu mCurrent = null;
	// Its button (not owned).
	private Button mCurrentButton = null;
	private float mBarHeight = 28.0f;
	private float mHPad = 12.0f;
	private Color mBarColor = .(0.13f, 0.15f, 0.18f, 1.0f);

	public this()
	{
		Tag = "menubar";
		AccessRoleName = "menubar"; // what a screen reader takes it for
		SetBox(FilledBox(mBarColor, scope NodeBox())); // its own face, which a sheet's (a theme's) replaces
		// Its keys are bindings in the menu key context: Left and Right from a button or an open
		// menu (which passes them on here) move along the bar, Down opens a button's.
		KeyContext = cMenuKeyContext;
		OnCommand(cMenuLeftCommand, new (command) => { Along(false); });
		OnCommand(cMenuRightCommand, new (command) => { Along(true); });
		OnCommand(cMenuDownCommand, new (command) =>
			{
				if (!OpenFromButton())
					command.Propagate = true;
			});
	}

	/// F10: its first button takes focus.
	public override bool EnterFromKeyboard()
	{
		if (mEntries.IsEmpty || !IsTreeVisible || !IsTreeEnabled)
			return false;
		mEntries[0].BarButton.RequestFocus();
		return true;
	}

	public void SetBarHeight(float height)
	{
		mBarHeight = Math.Max(1.0f, height);
		Relayout();
	}

	public void SetItemPadding(float padding)
	{
		mHPad = Math.Max(0.0f, padding);
		Relayout();
	}

	/// Adds a top-level menu with its button label; returns the (empty) Menu to populate.
	public Menu AddMenu(StringView text)
	{
		let menu = new Menu();
		AdoptMenu(menu, text);
		menu.ReleaseRef(); // the bar's reference keeps it
		return menu;
	}

	/// Takes `menu` (made elsewhere: markup's) under a new button titled `text`. It takes a
	/// reference of its own: the caller keeps its.
	public Menu AdoptMenu(Menu menu, StringView text)
	{
		let button = new Button();
		button.Text = text;
		ShareTextStyle(button, false);
		button.AddClass("menubutton"); // flat bar styling (class beats the button tag)
		ShareTextStyle(menu, false);

		button.SetOnClick(new () => { ToggleMenu(button, menu); });
		button.AddEventListener(.MouseEnter, new (e) => { HoverMenu(button, menu); });
		menu.SetOnClosed(new (reason) => { OnMenuClosed(menu); });

		AddChild(button);
		button.ReleaseRef(); // the tree's reference keeps it
		menu.AddRef();
		mEntries.Add(.(button, menu));
		Relayout();
		return menu;
	}

	/// Markup's children are its menus (each taken as it arrives).
	public override Node ChildHost
	{
		get
		{
			if (mMarkupHost == null)
			{
				mMarkupHost = new MarkupChildHost(new (host) =>
					{
						while (host.ChildCount != 0)
						{
							let child = host.GetChildAt(0);
							child.AddRef(); // held across its move
							host.RemoveChild(child);
							if (let menu = child as Menu)
								AdoptMenu(menu, menu.Title);
							child.ReleaseRef();
						}
					});
			}
			return mMarkupHost;
		}
	}

	public int MenuCount => mEntries.Count;
	public Menu CurrentMenu => mCurrent;

	public Button ButtonAt(int index) => (index < mEntries.Count) ? mEntries[index].BarButton : null;

	public Menu MenuAt(int index) => (index < mEntries.Count) ? mEntries[index].BarMenu : null;

	// Its buttons sit where Relayout puts them, left to right; right to left, mirrored.
	public override void OnLayout()
	{
		LayoutChildren();
		if (!IsRightToLeft)
			return;
		for (let e in mEntries)
			e.BarButton.Position = .(Size.X - e.BarButton.Position.X - e.BarButton.Size.X, e.BarButton.Position.Y);
	}

	// Its buttons and their menus take its font.
	protected override void OnTextStyleChange()
	{
		for (let e in mEntries)
		{
			ShareTextStyle(e.BarButton, false);
			if (e.BarMenu != null)
				ShareTextStyle(e.BarMenu, false);
		}
		Relayout();
	}

	public override void OnSizeChange()
	{
		Relayout();
	}

	private void ToggleMenu(Button button, Menu menu)
	{
		if (mCurrent == menu)
			menu.Close(); // Close -> OnMenuClosed clears the bar state
		else
			OpenMenu(button, menu);
	}

	private void HoverMenu(Button button, Menu menu)
	{
		// Only switch when a menu is already open (a bare hover must not drop a menu).
		if ((mCurrent != null) && (mCurrent != menu))
			OpenMenu(button, menu);
	}

	private void OpenMenu(Button button, Menu menu)
	{
		let d = EventDispatcher;
		let fromKeys = (d != null) && d.IsUsingKeyboard;
		menu.OpenBelow(button, button);
		if (fromKeys)
			menu.FocusFirstItem();
		// Opening closed any previous menu (its OnMenuClosed cleared mCurrent and deselected its
		// button); now record the new one.
		mCurrent = menu;
		mCurrentButton = button;
		button.AddClass("selected");
	}

	// Left or Right along the bar as it runs (right to left, Left goes on to the next menu): an
	// open menu moves to the next, a focused button to the next button.
	private void Along(bool right)
	{
		let at = FocusedEntry();
		if ((at < 0) || mEntries.IsEmpty)
			return;
		let count = (int32)mEntries.Count;
		let onward = right != IsRightToLeft;
		let next = (at + (onward ? 1 : -1) + count) % count;
		let e = mEntries[next];
		if (mCurrent != null)
		{
			OpenMenu(e.BarButton, e.BarMenu); // the open one closes: it does not hold this button
			e.BarMenu.FocusFirstItem();
		}
		else
			e.BarButton.RequestFocus();
	}

	// Down on a focused button with no menu open opens its menu and goes in.
	private bool OpenFromButton()
	{
		let at = FocusedEntry();
		if ((at < 0) || (mCurrent != null) || !mEntries[at].BarButton.IsFocused)
			return false;
		let e = mEntries[at];
		OpenMenu(e.BarButton, e.BarMenu);
		e.BarMenu.FocusFirstItem();
		return true;
	}

	// The entry whose button holds the focus (its open menu too), or -1.
	private int32 FocusedEntry()
	{
		for (int i = 0; i < mEntries.Count; ++i)
		{
			if (mEntries[i].BarButton.IsFocusWithin)
				return (int32)i;
		}
		return -1;
	}

	private void OnMenuClosed(Menu menu)
	{
		if (mCurrent != menu)
			return;
		if (mCurrentButton != null)
			mCurrentButton.RemoveClass("selected");
		mCurrent = null;
		mCurrentButton = null;
	}

	private void Relayout()
	{
		float x = 0.0f;
		for (let e in mEntries)
		{
			let w = ((e.BarButton.TextPart != null) ? e.BarButton.TextPart.MeasureText().X : 0.0f) + mHPad * 2.0f;
			e.BarButton.Position = .(x, 0.0f);
			e.BarButton.Size = .(w, mBarHeight);
			x += w;
		}
		// Within a device pixel of its size it is that size: the layout snaps its box to the
		// device grid, and sizing it back to the fraction asked for a layout again, every frame.
		let pixel = 1.0f / Math.Max(PixelScale, 0.01f);
		if ((Math.Abs(Size.X - x) >= pixel) || (Math.Abs(Size.Y - mBarHeight) >= pixel))
			Size = .(x, mBarHeight);
	}
}
