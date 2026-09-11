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
		fileMenu.AddItem("Open", new [&]() => { ran = true; });
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
}
