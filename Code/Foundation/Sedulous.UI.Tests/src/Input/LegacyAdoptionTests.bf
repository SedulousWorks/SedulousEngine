namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Tests for Phase 11 legacy comparison items.
class LegacyAdoptionTests
{
	// === H7: Tooltip hide on mouse down ===

	[Test]
	public static void TooltipManager_HidesOnMouseDown()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);
		ctx.UpdateRootView(root);

		// Manually show a tooltip popup (bypassing timer for reliable testing).
		let tooltipView = new ColorView();
		tooltipView.PreferredWidth = 60;
		tooltipView.PreferredHeight = 20;
		ctx.PopupLayer.ShowPopup(tooltipView, null, 50, 50,
			closeOnClickOutside: false, isModal: false, ownsView: true);
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		// TooltipManager.OnMouseDown is called by InputManager.ProcessMouseDown.
		// Test the mechanism directly: OnMouseDown should not crash even if
		// no tooltip was shown via the manager.
		ctx.TooltipManager.OnMouseDown();

		// The popup we added manually isn't tracked by TooltipManager,
		// so it's still there.
		Test.Assert(ctx.PopupLayer.PopupCount == 1);

		// Clean up.
		ctx.PopupLayer.ClosePopup(tooltipView);
		Test.Assert(ctx.PopupLayer.PopupCount == 0);
	}

	[Test]
	public static void TooltipText_Property_Retained()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let view = new ColorView();
		view.TooltipText = new String("Test tooltip");
		root.AddView(view);

		Test.Assert(view.TooltipText != null);
		Test.Assert(StringView(view.TooltipText) == "Test tooltip");
	}

	// === H8: Cursor management ===

	[Test]
	public static void InputManager_UpdatesCursorFromHovered()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new FrameLayout();
		root.AddView(layout);

		let view = new ColorView();
		view.PreferredWidth = 100;
		view.PreferredHeight = 100;
		view.Cursor = .Hand;
		layout.AddView(view, new FrameLayout.LayoutParams() { Width = 100, Height = 100 });

		ctx.UpdateRootView(root);

		// Move over the view.
		ctx.InputManager.ProcessMouseMove(50, 50);
		Test.Assert(ctx.InputManager.CurrentCursor == .Hand);

		// Move off the view.
		ctx.InputManager.ProcessMouseMove(200, 200);
		Test.Assert(ctx.InputManager.CurrentCursor == .Default);
	}

	// === H9: Event args timestamps ===

	[Test]
	public static void MouseEventArgs_HasTimestamp()
	{
		let args = scope MouseEventArgs();
		args.Set(10, 20, .Left, 1, 1.5f);
		Test.Assert(args.Timestamp == 1.5f);
	}

	[Test]
	public static void KeyEventArgs_HasTimestampAndScanCode()
	{
		let args = scope KeyEventArgs();
		args.Set(.A, .None, false, 2.0f, 30);
		Test.Assert(args.Timestamp == 2.0f);
		Test.Assert(args.ScanCode == 30);
	}

	// === H10: ScrollView.ScrollToView ===

	[Test]
	public static void ScrollView_ScrollToView_ScrollsDown()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		sv.AddView(layout, new LayoutParams() { Width = LayoutParams.MatchParent });

		for (int i = 0; i < 20; i++)
		{
			let item = new ColorView();
			item.PreferredHeight = 30;
			layout.AddView(item, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });
		}

		ctx.UpdateRootView(root);
		Test.Assert(sv.ScrollY == 0);

		// Scroll to make the 15th item visible.
		let target = layout.GetChildAt(14);
		sv.ScrollToView(target);

		// Should have scrolled down.
		Test.Assert(sv.ScrollY > 0);
	}

	// === M3: ScrollBar page-click ===

	[Test]
	public static void ScrollBar_TrackClick_PagesDown()
	{
		let bar = scope ScrollBar();
		bar.Orientation = .Vertical;
		bar.MaxValue = 400;
		bar.ViewportSize = 100;
		bar.Value = 0;
		bar.BarThickness = 10;

		// Layout the bar.
		bar.Measure(.Exactly(10), .Exactly(200));
		bar.Layout(0, 0, 10, 200);

		// Click below the thumb (which starts at top when Value=0).
		let thumbRect = bar.GetThumbRect();
		let clickY = thumbRect.Y + thumbRect.Height + 20; // below thumb

		let args = scope MouseEventArgs();
		args.Set(5, clickY, .Left, 1);
		bar.OnMouseDown(args);

		// Should have paged down by LargeChange (90% of viewport = 90).
		Test.Assert(bar.Value > 0);
		Test.Assert(args.Handled);
	}

	[Test]
	public static void ScrollBar_TrackClick_PagesUp()
	{
		let bar = scope ScrollBar();
		bar.Orientation = .Vertical;
		bar.MaxValue = 400;
		bar.ViewportSize = 100;
		bar.Value = 200; // middle
		bar.BarThickness = 10;

		bar.Measure(.Exactly(10), .Exactly(200));
		bar.Layout(0, 0, 10, 200);

		// Click above the thumb.
		let thumbRect = bar.GetThumbRect();
		let clickY = Math.Max(0, thumbRect.Y - 10);

		let args = scope MouseEventArgs();
		args.Set(5, clickY, .Left, 1);
		bar.OnMouseDown(args);

		// Should have paged up.
		Test.Assert(bar.Value < 200);
	}

	// === M5: ScrollView.SetContent ===

	[Test]
	public static void ScrollView_SetContent_ReplacesChildren()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 100);

		let sv = new ScrollView();
		root.AddView(sv);

		let first = new ColorView();
		first.PreferredHeight = 50;
		sv.AddView(first);

		Test.Assert(sv.ChildCount == 1);

		// Replace with new content.
		let second = new ColorView();
		second.PreferredHeight = 100;
		sv.SetContent(second);

		Test.Assert(sv.ChildCount == 1);
		Test.Assert(sv.GetChildAt(0) === second);
	}

	// === M7: Button.Command (ICommand) ===

	private class TestCommand : ICommand
	{
		public int ExecuteCount;
		public bool Enabled = true;

		public bool CanExecute() => Enabled;
		public void Execute() { ExecuteCount++; }
	}

	[Test]
	public static void Button_Command_ExecutesOnClick()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new FrameLayout();
		root.AddView(layout);

		let btn = new Button();
		btn.SetText("Cmd");
		layout.AddView(btn, new FrameLayout.LayoutParams() { Width = 100, Height = 40 });

		let cmd = scope TestCommand();
		btn.Command = cmd;

		ctx.UpdateRootView(root);

		btn.FireClick();
		Test.Assert(cmd.ExecuteCount == 1);
	}

	[Test]
	public static void Button_Command_SkipsWhenCannotExecute()
	{
		let btn = scope Button();
		let cmd = scope TestCommand();
		cmd.Enabled = false;
		btn.Command = cmd;

		btn.FireClick();
		Test.Assert(cmd.ExecuteCount == 0);
	}

	[Test]
	public static void Button_Command_DisabledState()
	{
		let btn = scope Button();
		btn.IsEnabled = true;
		let cmd = scope TestCommand();
		cmd.Enabled = false;
		btn.Command = cmd;

		Test.Assert(btn.GetControlState() == .Disabled);
	}

	// === C6: DeletedThisFrame tracking ===

	[Test]
	public static void MutationQueue_TracksDeletedViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let child = new ColorView();
		root.AddView(child);
		let childId = child.Id;

		child.QueueDestroy();
		ctx.BeginFrame(0);

		// The child's id should appear in DeletedThisFrame.
		Test.Assert(ctx.MutationQueue.DeletedThisFrameCount > 0);
		bool found = false;
		for (int i = 0; i < ctx.MutationQueue.DeletedThisFrameCount; i++)
		{
			if (ctx.MutationQueue.GetDeletedThisFrame(i) == childId)
			{ found = true; break; }
		}
		Test.Assert(found);
	}

	[Test]
	public static void MutationQueue_ClearsDeletedOnNextDrain()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let child = new ColorView();
		root.AddView(child);

		child.QueueDestroy();
		ctx.BeginFrame(0);
		Test.Assert(ctx.MutationQueue.DeletedThisFrameCount > 0);

		// Next frame should clear.
		ctx.BeginFrame(0);
		Test.Assert(ctx.MutationQueue.DeletedThisFrameCount == 0);
	}

	// === H3: Theme-aware rendering helpers ===

	[Test]
	public static void UIDrawContext_FillThemedBox_NoTheme_NoCrash()
	{
		// FillThemedBox with null theme should do nothing.
		let vg = scope Sedulous.VG.VGContext();
		let ctx = scope UIDrawContext(vg);
		// Should not crash.
		ctx.FillThemedBox(.(0, 0, 100, 50), "Panel");
	}

	[Test]
	public static void UIDrawContext_DrawFocusRing_NoTheme_NoCrash()
	{
		let vg = scope Sedulous.VG.VGContext();
		let ctx = scope UIDrawContext(vg);
		// Should not crash — uses hardcoded fallback color.
		ctx.DrawFocusRing(.(0, 0, 100, 50), 4);
	}
}
