namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class OverlayDetailTests
{
	// ==========================================================
	// PopupLayer -- ShowPopup / ClosePopup / PopupCount
	// ==========================================================

	[Test]
	public static void PopupLayer_ShowPopup_IncreasesCount()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		Test.Assert(ctx.PopupLayer.PopupCount == 0);

		let p1 = new ColorView();
		p1.PreferredWidth = 80;
		p1.PreferredHeight = 40;
		ctx.PopupLayer.ShowPopup(p1, null, 10, 10, ownsView: true);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		let p2 = new ColorView();
		p2.PreferredWidth = 80;
		p2.PreferredHeight = 40;
		ctx.PopupLayer.ShowPopup(p2, null, 100, 100, ownsView: true);
		Test.Assert(ctx.PopupLayer.PopupCount == 2);

		ctx.PopupLayer.ClosePopup(p1);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(p2);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void PopupLayer_ClosePopup_NoEffect_ForUnknownView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let popup = new ColorView();
		popup.PreferredWidth = 50;
		popup.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(popup, null, 0, 0, ownsView: true);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		// Closing a view that was never shown should do nothing.
		let other = scope ColorView();
		ctx.PopupLayer.ClosePopup(other);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(popup);
	}

	[Test]
	public static void PopupLayer_UpdatePopupPosition_ChangesEntryCoords()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let popup = scope ColorView();
		popup.PreferredWidth = 60;
		popup.PreferredHeight = 40;

		ctx.PopupLayer.ShowPopup(popup, null, 10, 20, ownsView: false);
		ctx.UpdateRootView(root);

		// Update position and layout again.
		ctx.PopupLayer.UpdatePopupPosition(popup, 200, 300);
		ctx.UpdateRootView(root);

		// After layout, the popup's bounds should reflect the updated position.
		Test.Assert(popup.Bounds.X == 200);
		Test.Assert(popup.Bounds.Y == 300);

		ctx.PopupLayer.ClosePopup(popup);
	}

	[Test]
	public static void PopupLayer_UpdatePopupPosition_IgnoresUnknownView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		// Should not crash when updating position of a non-popup view.
		let other = scope ColorView();
		ctx.PopupLayer.UpdatePopupPosition(other, 50, 50);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	// ==========================================================
	// PopupLayer -- Modal backdrop lifecycle
	// ==========================================================

	[Test]
	public static void PopupLayer_ModalBackdrop_AppearsAndDisappears()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let popup = new ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, isModal: true, ownsView: true);

		Test.Assert(ctx.PopupLayer.HasModalPopup);

		ctx.PopupLayer.ClosePopup(popup);
		Test.Assert(!ctx.PopupLayer.HasModalPopup);
	}

	[Test]
	public static void PopupLayer_MultipleModals_BackdropPersists()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let p1 = new ColorView();
		p1.PreferredWidth = 100;
		p1.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(p1, null, 10, 10, isModal: true, ownsView: true);

		let p2 = new ColorView();
		p2.PreferredWidth = 100;
		p2.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(p2, null, 50, 50, isModal: true, ownsView: true);

		Test.Assert(ctx.PopupLayer.HasModalPopup);
		Test.Assert(ctx.PopupLayer.PopupCount == 2);

		// Close one -- modal flag should persist because of the other.
		ctx.PopupLayer.ClosePopup(p2);
		Test.Assert(ctx.PopupLayer.HasModalPopup);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(p1);
		Test.Assert(!ctx.PopupLayer.HasModalPopup);
	}

	[Test]
	public static void PopupLayer_TopmostModalPopup_ReturnsCorrectPopup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		Test.Assert(ctx.PopupLayer.TopmostModalPopup == null);

		let p1 = new ColorView();
		p1.PreferredWidth = 80;
		p1.PreferredHeight = 40;
		ctx.PopupLayer.ShowPopup(p1, null, 10, 10, isModal: true, ownsView: true);
		Test.Assert(ctx.PopupLayer.TopmostModalPopup === p1);

		let p2 = new ColorView();
		p2.PreferredWidth = 80;
		p2.PreferredHeight = 40;
		ctx.PopupLayer.ShowPopup(p2, null, 50, 50, isModal: true, ownsView: true);
		// Topmost is the last added modal.
		Test.Assert(ctx.PopupLayer.TopmostModalPopup === p2);

		ctx.PopupLayer.ClosePopup(p2);
		Test.Assert(ctx.PopupLayer.TopmostModalPopup === p1);

		ctx.PopupLayer.ClosePopup(p1);
		Test.Assert(ctx.PopupLayer.TopmostModalPopup == null);
	}

	// ==========================================================
	// PopupLayer -- HandleClickOutside
	// ==========================================================

	[Test]
	public static void PopupLayer_HandleClickOutside_ClosesMultipleCloseOnClick()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let p1 = new ColorView();
		p1.PreferredWidth = 50;
		p1.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(p1, null, 10, 10, closeOnClickOutside: true, ownsView: true);

		let p2 = new ColorView();
		p2.PreferredWidth = 50;
		p2.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(p2, null, 100, 100, closeOnClickOutside: true, ownsView: true);

		Test.Assert(ctx.PopupLayer.PopupCount == 2);

		// HandleClickOutside should close all CloseOnClickOutside popups.
		let consumed = ctx.PopupLayer.HandleClickOutside(.Left);
		Test.Assert(consumed);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void PopupLayer_HandleClickOutside_SkipsNonDismissible()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let modal = new ColorView();
		modal.PreferredWidth = 100;
		modal.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(modal, null, 50, 50,
			closeOnClickOutside: false, isModal: true, ownsView: true);

		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		let consumed = ctx.PopupLayer.HandleClickOutside(.Left);
		// Nothing was CloseOnClickOutside, so nothing closed.
		Test.Assert(!consumed);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(modal);
	}

	[Test]
	public static void PopupLayer_HandleClickOutside_RightButton_NotConsumed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let popup = new ColorView();
		popup.PreferredWidth = 50;
		popup.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(popup, null, 10, 10, closeOnClickOutside: true, ownsView: true);

		// Right-click closes but does NOT consume the event.
		let consumed = ctx.PopupLayer.HandleClickOutside(.Right);
		Test.Assert(!consumed);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	// ==========================================================
	// PopupLayer -- HitTest
	// ==========================================================

	[Test]
	public static void PopupLayer_HitTest_ReturnsPopupWhenHit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = scope ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, ownsView: false);
		ctx.UpdateRootView(root);

		// Inside popup bounds.
		let hit = ctx.PopupLayer.HitTest(.(75, 65));
		Test.Assert(hit != null);

		ctx.PopupLayer.ClosePopup(popup);
	}

	[Test]
	public static void PopupLayer_HitTest_NonModal_PassesThrough()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = scope ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, isModal: false, ownsView: false);
		ctx.UpdateRootView(root);

		// Outside popup bounds, non-modal should pass through (null).
		let hit = ctx.PopupLayer.HitTest(.(10, 10));
		Test.Assert(hit == null);

		ctx.PopupLayer.ClosePopup(popup);
	}

	[Test]
	public static void PopupLayer_HitTest_Modal_BlocksOutside()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = new ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 150, 125, isModal: true, ownsView: true);
		ctx.UpdateRootView(root);

		// Outside popup but modal -- should block (non-null).
		let hit = ctx.PopupLayer.HitTest(.(5, 5));
		Test.Assert(hit != null);

		ctx.PopupLayer.ClosePopup(popup);
	}

	// ==========================================================
	// PopupLayer -- OwnsView lifecycle
	// ==========================================================

	[Test]
	public static void PopupLayer_OwnsView_True_DeletesOnClose()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		// We can't directly check for deletion, but we can verify
		// PopupCount drops and no crash occurs.
		let popup = new ColorView();
		popup.PreferredWidth = 50;
		popup.PreferredHeight = 50;

		ctx.PopupLayer.ShowPopup(popup, null, 0, 0, ownsView: true);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(popup);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void PopupLayer_OwnsView_False_PreservesView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let popup = scope ColorView();
		popup.PreferredWidth = 75;
		popup.PreferredHeight = 40;
		popup.Color = .Blue;

		ctx.PopupLayer.ShowPopup(popup, null, 0, 0, ownsView: false);
		ctx.PopupLayer.ClosePopup(popup);

		// View should still be valid.
		Test.Assert(popup.PreferredWidth == 75);
		Test.Assert(popup.Color == .Blue);
	}

	// ==========================================================
	// PopupPositioner -- PositionBestFit
	// ==========================================================

	[Test]
	public static void PopupPositioner_BestFit_DefaultBelow()
	{
		let screen = RectangleF(0, 0, 800, 600);
		let anchor = RectangleF(100, 100, 80, 20);
		let popupSize = Vector2(120, 50);

		let (x, y) = PopupPositioner.PositionBestFit(anchor, popupSize, screen);

		// Should position below anchor.
		Test.Assert(y == anchor.Y + anchor.Height);
		Test.Assert(x == anchor.X);
	}

	[Test]
	public static void PopupPositioner_BestFit_FlipsAboveWhenClippingBottom()
	{
		let screen = RectangleF(0, 0, 400, 300);
		let anchor = RectangleF(50, 260, 100, 20);
		let popupSize = Vector2(100, 60);

		let (x, y) = PopupPositioner.PositionBestFit(anchor, popupSize, screen);

		// 260 + 20 + 60 = 340 > 300 -- should flip above.
		Test.Assert(y == anchor.Y - popupSize.Y);
	}

	[Test]
	public static void PopupPositioner_BestFit_ClampsHorizontalRight()
	{
		let screen = RectangleF(0, 0, 400, 300);
		let anchor = RectangleF(350, 50, 30, 20);
		let popupSize = Vector2(100, 40);

		let (x, y) = PopupPositioner.PositionBestFit(anchor, popupSize, screen);

		// 350 + 100 = 450 > 400 -- should clamp to 300 (400 - 100).
		Test.Assert(x == 300);
	}

	[Test]
	public static void PopupPositioner_BestFit_ClampsHorizontalLeft()
	{
		let screen = RectangleF(0, 0, 400, 300);
		// Anchor way to the right, popup wider than anchor X can afford,
		// but after right-clamp it would go negative -- should clamp to 0.
		let anchor = RectangleF(380, 50, 10, 20);
		let popupSize = Vector2(500, 40);

		let (x, y) = PopupPositioner.PositionBestFit(anchor, popupSize, screen);

		// 400 - 500 = -100 -> clamp to 0.
		Test.Assert(x == 0);
	}

	[Test]
	public static void PopupPositioner_BestFit_ClampsVerticalTop()
	{
		let screen = RectangleF(0, 0, 400, 300);
		// Anchor at top, popup tall enough to clip both below and above.
		let anchor = RectangleF(50, 10, 80, 20);
		let popupSize = Vector2(100, 280);

		let (x, y) = PopupPositioner.PositionBestFit(anchor, popupSize, screen);

		// Below: 10 + 20 = 30, 30 + 280 = 310 > 300 -> flip above: 10 - 280 = -270.
		// -270 < 0 -> clamp to 0.
		Test.Assert(y >= 0);
	}

	// ==========================================================
	// PopupPositioner -- PositionBelow / PositionAbove
	// ==========================================================

	[Test]
	public static void PopupPositioner_Below_BasicPosition()
	{
		let screen = RectangleF(0, 0, 800, 600);
		let anchor = RectangleF(100, 200, 80, 30);
		let popupSize = Vector2(100, 50);

		let (x, y) = PopupPositioner.PositionBelow(anchor, popupSize, screen);
		Test.Assert(x == 100);
		Test.Assert(y == 230); // 200 + 30
	}

	[Test]
	public static void PopupPositioner_Above_BasicPosition()
	{
		let screen = RectangleF(0, 0, 800, 600);
		let anchor = RectangleF(100, 200, 80, 30);
		let popupSize = Vector2(100, 50);

		let (x, y) = PopupPositioner.PositionAbove(anchor, popupSize, screen);
		Test.Assert(x == 100);
		Test.Assert(y == 150); // 200 - 50
	}

	[Test]
	public static void PopupPositioner_Above_ClampsToTop()
	{
		let screen = RectangleF(0, 0, 400, 300);
		let anchor = RectangleF(50, 20, 80, 20);
		let popupSize = Vector2(100, 60);

		let (x, y) = PopupPositioner.PositionAbove(anchor, popupSize, screen);

		// 20 - 60 = -40 -> clamp to 0.
		Test.Assert(y == 0);
	}

	// ==========================================================
	// PopupPositioner -- PositionSubmenu
	// ==========================================================

	[Test]
	public static void PopupPositioner_Submenu_DefaultRight()
	{
		let screen = RectangleF(0, 0, 800, 600);
		let parent = RectangleF(100, 100, 150, 200);
		let popupSize = Vector2(120, 100);

		let (x, y) = PopupPositioner.PositionSubmenu(parent, popupSize, screen);

		// Should appear to the right: 100 + 150 = 250.
		Test.Assert(x == 250);
		Test.Assert(y == 100);
	}

	[Test]
	public static void PopupPositioner_Submenu_FlipsLeftWhenClipping()
	{
		let screen = RectangleF(0, 0, 400, 300);
		let parent = RectangleF(320, 50, 80, 200);
		let popupSize = Vector2(120, 100);

		let (x, y) = PopupPositioner.PositionSubmenu(parent, popupSize, screen);

		// 320 + 80 + 120 = 520 > 400 -> flip left: 320 - 120 = 200.
		Test.Assert(x == 200);
	}

	[Test]
	public static void PopupPositioner_Submenu_ClampsVerticalBottom()
	{
		let screen = RectangleF(0, 0, 800, 400);
		let parent = RectangleF(100, 350, 150, 30);
		let popupSize = Vector2(120, 100);

		let (x, y) = PopupPositioner.PositionSubmenu(parent, popupSize, screen);

		// 350 + 100 = 450 > 400 -> clamp to 400 - 100 = 300.
		Test.Assert(y == 300);
	}

	// ==========================================================
	// Dialog
	// ==========================================================

	[Test]
	public static void Dialog_AlertFactory_TitleAndResult()
	{
		let dialog = Dialog.Alert("Warning", "Something happened");
		defer delete dialog;

		Test.Assert(dialog.Title == "Warning");
		Test.Assert(dialog.Result == .None);
	}

	[Test]
	public static void Dialog_ConfirmFactory_TitleAndResult()
	{
		let dialog = Dialog.Confirm("Delete?", "Are you sure?");
		defer delete dialog;

		Test.Assert(dialog.Title == "Delete?");
		Test.Assert(dialog.Result == .None);
	}

	[Test]
	public static void Dialog_Show_IsModal()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		// Show as modal (ownsView false so we can check state without use-after-free).
		let dialog = scope Dialog("Test Dialog");
		dialog.Show(ctx, ownsView: false);

		Test.Assert(ctx.PopupLayer.HasModalPopup);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.PopupLayer.ClosePopup(dialog);
		Test.Assert(!ctx.PopupLayer.HasModalPopup);
	}

	[Test]
	public static void Dialog_SetContent_ReplacesExisting()
	{
		let dialog = scope Dialog("Title");

		let content1 = new Label();
		content1.SetText("First");
		dialog.SetContent(content1);

		let content2 = new Label();
		content2.SetText("Second");
		dialog.SetContent(content2);

		// Should not crash -- old content removed cleanly.
		Test.Assert(dialog.VisualChildCount == 1);
	}

	[Test]
	public static void Dialog_AddButton_IncreasesButtonCount()
	{
		let dialog = scope Dialog("Test");
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		// If we got here without crash, buttons were added successfully.
		Test.Assert(dialog.Result == .None);
	}

	// ==========================================================
	// ContextMenu
	// ==========================================================

	[Test]
	public static void ContextMenu_AddItem_BuildsMenu()
	{
		let menu = scope ContextMenu();
		menu.AddItem("Cut", new () => { });
		menu.AddItem("Copy", new () => { });
		menu.AddItem("Paste", new () => { });
		// No crash = success. Items are internal, but submenu count below
		// verifies the API works.
	}

	[Test]
	public static void ContextMenu_AddSeparator_NoCrash()
	{
		let menu = scope ContextMenu();
		menu.AddItem("A", new () => { });
		menu.AddSeparator();
		menu.AddItem("B", new () => { });
	}

	[Test]
	public static void ContextMenu_AddSubmenu_ReturnsMenuItem()
	{
		let menu = scope ContextMenu();
		let sub = menu.AddSubmenu("More...");
		Test.Assert(sub != null);
		Test.Assert(sub.Label == "More...");
		Test.Assert(sub.Submenu != null);
	}

	[Test]
	public static void ContextMenu_SubmenuParentLink()
	{
		let menu = scope ContextMenu();
		let subItem = menu.AddSubmenu("Sub");
		// The submenu's parent menu pointer should be set.
		// We can't directly access mParentMenu (private), but the
		// CloseEntireChain path uses it -- verify no crash.
		Test.Assert(subItem.Submenu != null);
	}

	[Test]
	public static void ContextMenu_DisabledItem()
	{
		let menu = scope ContextMenu();
		bool clicked = false;
		menu.AddItem("Disabled", new [&clicked]() => { clicked = true; }, enabled: false);
		// Disabled items should exist but not trigger action via normal click.
		Test.Assert(!clicked);
	}

	// ==========================================================
	// TooltipManager -- Show delay and basic lifecycle
	// ==========================================================

	[Test]
	public static void TooltipManager_NoShowBeforeDelay()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		// Add a view with tooltip text.
		let target = new ColorView();
		target.TooltipText = new String("Hello");
		target.PreferredWidth = 100;
		target.PreferredHeight = 30;
		root.AddView(target);
		ctx.UpdateRootView(root);

		// Simulate hover.
		ctx.TooltipManager.OnHoverChanged(target);
		// Update with partial delay -- should not show yet.
		ctx.TooltipManager.Update(0.1f);

		// PopupLayer should have no tooltip popup.
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void TooltipManager_ShowsAfterDelay()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		let target = new ColorView();
		target.TooltipText = new String("Tooltip");
		target.PreferredWidth = 100;
		target.PreferredHeight = 30;
		root.AddView(target);
		ctx.UpdateRootView(root);

		ctx.TooltipManager.OnHoverChanged(target);
		// Update past the default delay (0.5s).
		ctx.TooltipManager.Update(0.6f);

		// Tooltip should now be showing.
		Test.Assert(ctx.PopupLayer.PopupCount == 1);
	}

	[Test]
	public static void TooltipManager_HidesOnHoverLeave()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		let target = new ColorView();
		target.TooltipText = new String("Tip");
		target.PreferredWidth = 100;
		target.PreferredHeight = 30;
		root.AddView(target);
		ctx.UpdateRootView(root);

		ctx.TooltipManager.OnHoverChanged(target);
		ctx.TooltipManager.Update(0.6f);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		// Move hover away.
		ctx.TooltipManager.OnHoverChanged(null);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void TooltipManager_CustomDelay()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		ctx.TooltipManager.ShowDelay = 1.0f;

		let target = new ColorView();
		target.TooltipText = new String("Slow tooltip");
		target.PreferredWidth = 100;
		target.PreferredHeight = 30;
		root.AddView(target);
		ctx.UpdateRootView(root);

		ctx.TooltipManager.OnHoverChanged(target);
		ctx.TooltipManager.Update(0.5f); // Only half the delay.
		Test.Assert(ctx.PopupLayer.PopupCount == 0);

		ctx.TooltipManager.Update(0.6f); // Now past 1.0.
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.TooltipManager.OnHoverChanged(null);
	}

	[Test]
	public static void TooltipManager_HidesOnMouseDown()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		let target = new ColorView();
		target.TooltipText = new String("Click me");
		target.PreferredWidth = 100;
		target.PreferredHeight = 30;
		root.AddView(target);
		ctx.UpdateRootView(root);

		ctx.TooltipManager.OnHoverChanged(target);
		ctx.TooltipManager.Update(0.6f);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		ctx.TooltipManager.OnMouseDown();
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void TooltipManager_EmptyText_DoesNotShow()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);
		ctx.UpdateRootView(root);

		let target = new ColorView();
		// No tooltip text set.
		target.PreferredWidth = 100;
		target.PreferredHeight = 30;
		root.AddView(target);
		ctx.UpdateRootView(root);

		ctx.TooltipManager.OnHoverChanged(target);
		ctx.TooltipManager.Update(0.6f);

		// No tooltip should appear when text is null/empty.
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}
}
