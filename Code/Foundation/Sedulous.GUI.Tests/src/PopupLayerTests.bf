namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class PopupLayerTests
{
	[Test]
	public static void RootView_HasPopupLayer()
	{
		let root = scope RootView();
		Test.Assert(root.PopupLayer != null);
	}

	[Test]
	public static void RootView_PopupLayerIsLastChild()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		// Add a normal child - PopupLayer should still be last
		root.AddView(new TestView());
		Test.Assert(root.GetChildAt(root.ChildCount - 1) === root.PopupLayer);
	}

	[Test]
	public static void RootView_PopupLayerStaysLast()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		root.AddView(new TestView());
		root.AddView(new TestView());
		root.AddView(new TestView());

		// PopupLayer should always be the last child
		Test.Assert(root.GetChildAt(root.ChildCount - 1) === root.PopupLayer);
	}

	[Test]
	public static void ShowPopup_IncreasesCount()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, ownsView: true);

		Test.Assert(root.PopupLayer.PopupCount == 1);
	}

	[Test]
	public static void ClosePopup_DecreasesCount()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, ownsView: true);
		root.PopupLayer.ClosePopup(popup);

		Test.Assert(root.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void ShowPopup_OwnedView_DeletedOnClose()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		let popupId = popup.Id;
		root.PopupLayer.ShowPopup(popup, null, 10, 10, ownsView: true);
		root.PopupLayer.ClosePopup(popup);

		// popup should be deleted - lookup should return null
		Test.Assert(ctx.GetViewById(popupId) == null);
	}

	[Test]
	public static void ShowPopup_NotOwned_NotDeletedOnClose()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, ownsView: false);
		root.PopupLayer.ClosePopup(popup);

		// popup should still be alive (not deleted)
		Test.Assert(popup.Id.IsValid);
		delete popup;
	}

	[Test]
	public static void ShowPopup_NotifiesOwner()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		bool notified = false;
		View closedPopup = null;
		let owner = scope TestPopupOwner(&notified, &closedPopup);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, owner, 10, 10, ownsView: true);
		root.PopupLayer.ClosePopup(popup);

		Test.Assert(notified);
	}

	[Test]
	public static void Modal_HasModalPopup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, isModal: true, ownsView: true);

		Test.Assert(root.PopupLayer.HasModalPopup);
		Test.Assert(root.PopupLayer.TopmostModalPopup === popup);
	}

	[Test]
	public static void Modal_HitTestBlocksBackground()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 800, 600);
		TestSetup.Layout(ctx, root);

		let bg = new TestView(800, 600);
		root.AddView(bg);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, isModal: true, ownsView: true);
		TestSetup.Layout(ctx, root);

		// Hit test on background area (outside popup) should not return bg
		let hit = root.HitTest(.(700, 500));
		Test.Assert(hit !== bg);
	}

	[Test]
	public static void HandleClickOutside_ClosesCloseOnClick()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);
		TestSetup.Layout(ctx, root);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10,
			closeOnClickOutside: true, ownsView: true);

		Test.Assert(root.PopupLayer.PopupCount == 1);
		root.PopupLayer.HandleClickOutside(0); // LMB
		Test.Assert(root.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void ShowPopup_PushesFocus()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);
		ctx.FocusManager.SetFocus(view);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, ownsView: true);

		// Focus should be cleared (pushed to stack)
		Test.Assert(ctx.FocusManager.FocusedView == null);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);
	}

	[Test]
	public static void ClosePopup_PopsFocus()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		root.ViewportSize = .(800, 600);

		let view = new TestView();
		view.IsFocusable = true;
		root.AddView(view);
		ctx.FocusManager.SetFocus(view);

		let popup = new TestView(100, 50);
		root.PopupLayer.ShowPopup(popup, null, 10, 10, ownsView: true);
		root.PopupLayer.ClosePopup(popup);

		// Focus should be restored
		Test.Assert(ctx.FocusManager.FocusedView === view);
	}
}

class TestPopupOwner : IPopupOwner
{
	bool* mNotified;
	View* mClosedPopup;

	public this(bool* notified, View* closedPopup)
	{
		mNotified = notified;
		mClosedPopup = closedPopup;
	}

	public void OnPopupClosed(View popup)
	{
		*mNotified = true;
		*mClosedPopup = popup;
	}
}
