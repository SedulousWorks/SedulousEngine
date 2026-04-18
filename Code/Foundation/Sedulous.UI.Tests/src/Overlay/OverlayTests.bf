namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class OverlayTests
{
	[Test]
	public static void PopupLayer_HitTest_EmptyPassesThrough()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);
		ctx.UpdateRootView(root);

		// PopupLayer with no popups should pass through (return null).
		let hit = ctx.PopupLayer.HitTest(.(100, 100));
		Test.Assert(hit == null);
	}

	[Test]
	public static void PopupLayer_ShowAndClose()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = new ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;
		popup.Color = .Red;

		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, ownsView: true);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(popup);
		// popup was deleted (ownsView=true)
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void PopupLayer_OwnsView_False()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = scope ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, ownsView: false);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(popup);
		// popup NOT deleted — still accessible
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
		Test.Assert(popup.PreferredWidth == 100); // still valid
	}

	[Test]
	public static void PopupLayer_Modal_BlocksInput()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);
		ctx.UpdateRootView(root);

		let popup = new ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 150, 125, isModal: true, ownsView: true);
		ctx.UpdateRootView(root);

		Test.Assert(ctx.PopupLayer.HasModalPopup);

		// Hit outside the popup — modal should block (return PopupLayer itself).
		let hit = ctx.PopupLayer.HitTest(.(10, 10));
		Test.Assert(hit != null); // blocked, not null

		ctx.PopupLayer.ClosePopup(popup);
		Test.Assert(!ctx.PopupLayer.HasModalPopup);
	}

	[Test]
	public static void PopupLayer_ClickOutside_Closes()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = new ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, closeOnClickOutside: true, ownsView: true);
		ctx.UpdateRootView(root);

		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		// Click outside — closes all CloseOnClickOutside popups.
		ctx.PopupLayer.HandleClickOutside(.Left);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void PopupPositioner_BestFit_FlipsAbove()
	{
		let screen = RectangleF(0, 0, 400, 300);
		let anchor = RectangleF(50, 260, 100, 20); // near bottom
		let popupSize = Vector2(100, 60);

		let (x, y) = PopupPositioner.PositionBestFit(anchor, popupSize, screen);

		// Should flip above the anchor (260 - 60 = 200).
		Test.Assert(y < anchor.Y);
	}

	[Test]
	public static void PopupPositioner_Submenu_FlipsLeft()
	{
		let screen = RectangleF(0, 0, 400, 300);
		let parent = RectangleF(320, 50, 80, 200); // near right edge
		let popupSize = Vector2(120, 100);

		let (x, y) = PopupPositioner.PositionSubmenu(parent, popupSize, screen);

		// Should flip left (320 - 120 = 200) since right would clip.
		Test.Assert(x < parent.X);
	}

	[Test]
	public static void ContextMenu_AddItems()
	{
		let menu = scope ContextMenu();
		bool clicked = false;

		menu.AddItem("Item 1", new [&clicked]() => { clicked = true; });
		menu.AddItem("Item 2", new () => { });
		menu.AddSeparator();
		let sub = menu.AddSubmenu("Submenu");

		// 4 items: 2 regular + 1 separator + 1 submenu.
		// (Internal list has 4 entries.)
		// Just verify no crash during construction.
		Test.Assert(!clicked);
	}

	[Test]
	public static void Dialog_AlertFactory()
	{
		let dialog = Dialog.Alert("Title", "Message");
		defer delete dialog;

		Test.Assert(dialog.Title == "Title");
		Test.Assert(dialog.Result == .None);
	}

	[Test]
	public static void Dialog_ConfirmFactory()
	{
		let dialog = Dialog.Confirm("Confirm", "Are you sure?");
		defer delete dialog;

		Test.Assert(dialog.Title == "Confirm");
	}
}
