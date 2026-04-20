namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class FocusStackTests
{
	[Test]
	public static void PushFocus_SavesAndClears()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("Test");
		root.AddView(btn);
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		Test.Assert(btn.IsFocused);

		ctx.FocusManager.PushFocus();
		Test.Assert(!btn.IsFocused);
		Test.Assert(ctx.FocusManager.FocusedView == null);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);
	}

	[Test]
	public static void PopFocus_RestoresPrevious()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("Test");
		root.AddView(btn);
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		ctx.FocusManager.PushFocus();
		ctx.FocusManager.PopFocus();

		Test.Assert(btn.IsFocused);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
	}

	[Test]
	public static void NestedPushPop_RestoresCorrectly()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn1 = new Button();
		btn1.SetText("A");
		let btn2 = new Button();
		btn2.SetText("B");
		root.AddView(btn1);
		root.AddView(btn2);
		ctx.UpdateRootView(root);

		// Focus btn1, push (simulates first popup).
		ctx.FocusManager.SetFocus(btn1);
		ctx.FocusManager.PushFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);

		// Focus btn2, push again (simulates nested popup).
		ctx.FocusManager.SetFocus(btn2);
		ctx.FocusManager.PushFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 2);

		// Pop inner -> restores btn2.
		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView === btn2);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);

		// Pop outer -> restores btn1.
		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView === btn1);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
	}

	[Test]
	public static void PopFocus_SkipsDeadViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("WillDie");
		root.AddView(btn);
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		ctx.FocusManager.PushFocus();

		// Delete the view while popup is "open".
		root.RemoveView(btn, true);

		// Pop - saved ID is dead, should not crash, focus stays cleared.
		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView == null);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
	}

	[Test]
	public static void PopFocus_SkipsDeadFindsLive()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn1 = new Button();
		btn1.SetText("Survives");
		let btn2 = new Button();
		btn2.SetText("WillDie");
		root.AddView(btn1);
		root.AddView(btn2);
		ctx.UpdateRootView(root);

		// Push btn1 (first popup).
		ctx.FocusManager.SetFocus(btn1);
		ctx.FocusManager.PushFocus();

		// Push btn2 (nested popup).
		ctx.FocusManager.SetFocus(btn2);
		ctx.FocusManager.PushFocus();

		// Delete btn2 while nested popup is open.
		root.RemoveView(btn2, true);

		// Pop inner -> btn2 is dead, skipped.
		ctx.FocusManager.PopFocus();
		// Stack still has btn1's entry, but PopFocus only pops one level.
		// Since btn2 was dead, focus should be cleared (no live ID at this level).
		// Actually PopFocus pops until it finds a live one or empties the stack.
		// So it should find btn1 and restore it.
		Test.Assert(ctx.FocusManager.FocusedView === btn1);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
	}

	[Test]
	public static void PopFocus_EmptyStack_NoCrash()
	{
		let ctx = scope UIContext();
		// Pop on empty stack should not crash.
		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView == null);
	}

	[Test]
	public static void PopupLayer_PushesAndPopsFocus()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("Test");
		root.AddView(btn);
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		Test.Assert(btn.IsFocused);

		// Show a popup - should push focus (EditText loses focus).
		let popup = new ColorView();
		popup.PreferredWidth = 100;
		popup.PreferredHeight = 50;
		ctx.PopupLayer.ShowPopup(popup, null, 50, 50, ownsView: true);

		Test.Assert(!btn.IsFocused);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);

		// Close popup - should pop focus (btn regains focus).
		ctx.PopupLayer.ClosePopup(popup);

		Test.Assert(btn.IsFocused);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
	}

	[Test]
	public static void PushFocus_NoFocus_PushesInvalid()
	{
		let ctx = scope UIContext();
		// Nothing focused - push should still work.
		ctx.FocusManager.PushFocus();
		Test.Assert(ctx.FocusManager.FocusStackDepth == 1);

		// Pop restores "nothing focused".
		ctx.FocusManager.PopFocus();
		Test.Assert(ctx.FocusManager.FocusedView == null);
		Test.Assert(ctx.FocusManager.FocusStackDepth == 0);
	}
}
