using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The menu bar's bookkeeping. Opening a dropdown needs a root and a popup layer, so what is
/// pinned here is that the menus it hands back are live and owned for the bar's whole life.
class MenuBarTests
{
	[Test]
	public static void AddMenuTracksCountAndReturnsDistinctMenus()
	{
		let bar = new MenuBar();
		defer bar.ReleaseRef();

		Test.Assert(bar.MenuCount == 0);

		let fileMenu = bar.AddMenu("File");
		Test.Assert(fileMenu != null);
		Test.Assert(bar.MenuCount == 1);

		let editMenu = bar.AddMenu("Edit");
		Test.Assert(editMenu != null);
		Test.Assert(bar.MenuCount == 2);
		Test.Assert(fileMenu != editMenu);
	}

	/// The returned menus stay usable, which is the point of the bar owning them rather than
	/// building one per open.
	[Test]
	public static void TheReturnedMenusAcceptItems()
	{
		let bar = new MenuBar();
		defer bar.ReleaseRef();

		let fileMenu = bar.AddMenu("File");
		let editMenu = bar.AddMenu("Edit");

		var ran = false;
		fileMenu.AddItem("Open", new [&ran]() => { ran = true; });
		fileMenu.AddSeparator();
		editMenu.AddItem("Undo", new () => {});

		Test.Assert(fileMenu.ItemCount == 2);
		Test.Assert(editMenu.ItemCount == 1);
		Test.Assert(!ran, "adding an item does not run it");
	}

	[Test]
	public static void TheBarIsItsOwnPopupOwner()
	{
		let bar = new MenuBar();
		defer bar.ReleaseRef();

		Test.Assert(bar.OwnerView == bar);
	}

	[Test]
	public static void MenuAtAndMenuTitleAnswerInOrderAndClearMenusEmptiesTheBar()
	{
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		let fileMenu = bar.AddMenu("File");
		let editMenu = bar.AddMenu("Edit");
		Test.Assert(bar.MenuAt(0) == fileMenu);
		Test.Assert(bar.MenuAt(1) == editMenu);
		Test.Assert(bar.MenuAt(2) == null);
		Test.Assert(bar.MenuTitle(0) == "File");
		Test.Assert(bar.MenuTitle(1) == "Edit");
		Test.Assert(bar.MenuTitle(2).IsEmpty);
		bar.ClearMenus();
		Test.Assert(bar.MenuCount == 0);
		Test.Assert(bar.MenuAt(0) == null);
		// A bar rebuilt after clearing is a fresh bar.
		let again = bar.AddMenu("File");
		Test.Assert((again != null) && (bar.MenuCount == 1) && (bar.MenuTitle(0) == "File"));
	}

	/// The bar shows a menu through the popup layer directly, so it runs the menu's opening
	/// hook itself: a menu built from live state fills as its title opens it.
	[Test]
	public static void OpeningAMenuRunsItsOpeningHook()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		root.ViewportSize = .(800, 600);
		context.AddRootView(root);
		let bar = new MenuBar();
		root.AddView(bar);

		let fileMenu = bar.AddMenu("File");
		int opened = 0;
		fileMenu.OnOpening = new [&opened](menu) =>
			{
				opened++;
				menu.ClearItems();
				menu.AddItem("Save", new () => {});
			};
		bar.OpenMenuAt(0);
		Test.Assert(opened == 1);
		Test.Assert(bar.ActiveIndex == 0);
		Test.Assert((fileMenu.ItemCount == 1) && (fileMenu.ItemAt(0).Label == "Save"));
		Test.Assert(root.GetPopupLayer().PopupCount == 1);
		// Clearing the bar closes the open menu first.
		bar.ClearMenus();
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
		context.MutationQueue.Drain();
	}
}
