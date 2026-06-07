namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class ViewTests
{
	[Test]
	public static void Id_IsUniquePerView()
	{
		let a = scope TestView();
		let b = scope TestView();
		Test.Assert(a.Id != b.Id);
		Test.Assert(a.Id.IsValid);
		Test.Assert(b.Id.IsValid);
	}

	[Test]
	public static void Handle_CreatedAtConstruction()
	{
		let view = scope TestView();
		Test.Assert(view.Handle != null);
		Test.Assert(view.Handle.IsValid);
		Test.Assert(view.Handle.View === view);
	}

	[Test]
	public static void StyleClasses_AddRemoveHasToggle()
	{
		let view = scope TestView();

		view.AddClass("primary");
		Test.Assert(view.HasClass("primary"));
		Test.Assert(view.StyleClasses.Count == 1);

		view.AddClass("large");
		Test.Assert(view.StyleClasses.Count == 2);

		// Duplicate add is no-op
		view.AddClass("primary");
		Test.Assert(view.StyleClasses.Count == 2);

		view.RemoveClass("primary");
		Test.Assert(!view.HasClass("primary"));
		Test.Assert(view.StyleClasses.Count == 1);

		view.ToggleClass("large");
		Test.Assert(!view.HasClass("large"));

		view.ToggleClass("large");
		Test.Assert(view.HasClass("large"));
	}

	[Test]
	public static void Visibility_Default()
	{
		let view = scope TestView();
		Test.Assert(view.Visibility.Value == .Visible);
	}

	[Test]
	public static void PropertyChange_TriggersInvalidation()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		// Clear flags
		view.ClearRedrawFlag();
		view.ClearLayoutFlag();

		// Layout property change should trigger layout invalidation
		view.IsEnabled.Value = false;
		Test.Assert(view.NeedsLayout);
		Test.Assert(view.NeedsRedraw);
	}

	[Test]
	public static void PropertyChange_VisualOnly()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		view.ClearRedrawFlag();
		view.ClearLayoutFlag();

		// Visual-only property should only trigger redraw
		view.Opacity.Value = 0.5f;
		Test.Assert(view.NeedsRedraw);
		// Layout flag should NOT be set for visual-only changes
		// (Opacity is tagged .Visual)
		Test.Assert(!view.NeedsLayout);
	}

	[Test]
	public static void Measure_SetsMeasuredSize()
	{
		let view = scope TestView(100, 50);
		view.Measure(BoxConstraints.Expand());
		Test.Assert(view.MeasuredSize.X == 100);
		Test.Assert(view.MeasuredSize.Y == 50);
	}

	[Test]
	public static void Layout_SetsBounds()
	{
		let view = scope TestView();
		view.Layout(10, 20, 100, 50);
		Test.Assert(view.Bounds.X == 10);
		Test.Assert(view.Bounds.Y == 20);
		Test.Assert(view.Width == 100);
		Test.Assert(view.Height == 50);
	}

	[Test]
	public static void HitTest_InsideBounds()
	{
		let view = scope TestView();
		view.Layout(0, 0, 100, 100);
		let hit = view.HitTest(.(50, 50));
		Test.Assert(hit === view);
	}

	[Test]
	public static void HitTest_OutsideBounds()
	{
		let view = scope TestView();
		view.Layout(0, 0, 100, 100);
		let hit = view.HitTest(.(150, 50));
		Test.Assert(hit == null);
	}

	[Test]
	public static void HitTest_NotVisible()
	{
		let view = scope TestView();
		view.Layout(0, 0, 100, 100);
		view.Visibility.Value = .Hidden;
		let hit = view.HitTest(.(50, 50));
		Test.Assert(hit == null);
	}

	[Test]
	public static void HitTest_NotHitTestVisible()
	{
		let view = scope TestView();
		view.Layout(0, 0, 100, 100);
		view.IsHitTestVisible.Value = false;
		let hit = view.HitTest(.(50, 50));
		Test.Assert(hit == null);
	}

	[Test]
	public static void LocalToScreen_ScreenToLocal()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);
		group.Layout(10, 20, 200, 200);

		let child = new TestView();
		group.AddView(child);
		child.Layout(30, 40, 50, 50);

		let screen = child.LocalToScreen(.(5, 5));
		// 5 + 30 (child) + 10 (group) = 45
		// 5 + 40 (child) + 20 (group) = 65
		Test.Assert(screen.X == 45);
		Test.Assert(screen.Y == 65);

		let local = child.ScreenToLocal(screen);
		Test.Assert(Math.Abs(local.X - 5) < 0.001f);
		Test.Assert(Math.Abs(local.Y - 5) < 0.001f);
	}

	[Test]
	public static void IsEffectivelyEnabled_WalksParentChain()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);

		Test.Assert(child.IsEffectivelyEnabled);

		group.IsEnabled.Value = false;
		Test.Assert(!child.IsEffectivelyEnabled);
	}

	[Test]
	public static void GetControlState_ReturnsFlags()
	{
		let view = scope TestView();

		// Default state: Normal (no flags)
		let state = view.GetControlState();
		Test.Assert(state == .Normal);

		// Disabled
		view.IsEnabled.Value = false;
		let disabled = view.GetControlState();
		Test.Assert(disabled.HasFlag(.Disabled));
	}
}
