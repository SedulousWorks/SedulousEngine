namespace Sedulous.UI.Tests;

using System;

class ContextMenuTests
{
	[Test]
	public static void MenuItem_Properties()
	{
		let item = scope MenuItem("Test", new () => {}, true);
		Test.Assert(item.Label != null);
		Test.Assert(StringView(item.Label) == "Test");
		Test.Assert(item.Enabled == true);
		Test.Assert(!item.IsSeparator);
		Test.Assert(item.Submenu == null);
	}

	[Test]
	public static void MenuItem_CreateSeparator()
	{
		let item = MenuItem.CreateSeparator();
		defer delete item;
		Test.Assert(item.IsSeparator);
		Test.Assert(item.Label == null);
		Test.Assert(item.Action == null);
	}

	[Test]
	public static void AddItem_IncreasesCount()
	{
		let menu = scope ContextMenu();
		Test.Assert(menu.ItemCount == 0);

		menu.AddItem("Item 1", new () => {});
		Test.Assert(menu.ItemCount == 1);

		menu.AddItem("Item 2", new () => {});
		Test.Assert(menu.ItemCount == 2);
	}

	[Test]
	public static void AddSeparator_IncreasesCount()
	{
		let menu = scope ContextMenu();
		menu.AddItem("Item 1", new () => {});
		menu.AddSeparator();
		menu.AddItem("Item 2", new () => {});
		Test.Assert(menu.ItemCount == 3);
	}

	[Test]
	public static void AddSubmenu_CreatesItemWithSubmenu()
	{
		let menu = scope ContextMenu();
		let sub = menu.AddSubmenu("More");
		Test.Assert(sub != null);
		Test.Assert(sub.Submenu != null);
		Test.Assert(sub.Label != null);
		Test.Assert(StringView(sub.Label) == "More");
		Test.Assert(menu.ItemCount == 1);
	}

	[Test]
	public static void IsFocusable()
	{
		let menu = scope ContextMenu();
		Test.Assert(menu.IsFocusable);
	}
}
