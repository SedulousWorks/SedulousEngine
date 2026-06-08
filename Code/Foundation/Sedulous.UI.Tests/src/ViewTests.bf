namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class ViewTests
{
	[Test]
	public static void View_HasUniqueId()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let a = new TestView();
		let b = new TestView();
		root.AddView(a);
		root.AddView(b);

		Test.Assert(a.Id != b.Id);
		Test.Assert(a.Id.IsValid);
		Test.Assert(b.Id.IsValid);
	}

	[Test]
	public static void View_ParentSetOnAdd()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);
		Test.Assert(child.Parent === root);
	}

	[Test]
	public static void View_ContextSetOnAttach()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);
		Test.Assert(child.Context === ctx);
	}

	[Test]
	public static void View_ContextClearedOnRemove()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);
		root.RemoveView(child);
		Test.Assert(child.Context == null);
		Test.Assert(child.Parent == null);
		delete child;
	}

	[Test]
	public static void View_RootProperty()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.Root === root);
		Test.Assert(group.Root === root);
		Test.Assert(root.Root === root);
	}

	[Test]
	public static void View_DefaultMeasure_ClampsToZero()
	{
		let view = scope TestView(0, 0);
		view.Measure(BoxConstraints.Loose(100, 100));
		Test.Assert(view.MeasuredSize.X == 0);
		Test.Assert(view.MeasuredSize.Y == 0);
	}

	[Test]
	public static void View_Layout_SetsBounds()
	{
		let view = scope TestView();
		view.Layout(10, 20, 100, 50);
		Test.Assert(view.Bounds.X == 10);
		Test.Assert(view.Bounds.Y == 20);
		Test.Assert(view.Width == 100);
		Test.Assert(view.Height == 50);
	}

	[Test]
	public static void View_Invalidate_MarksRedraw()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);

		Test.Assert(child.NeedsRedraw);
		child.ClearRedrawFlag();
		Test.Assert(!child.NeedsRedraw);

		child.Invalidate();
		Test.Assert(child.NeedsRedraw);
		Test.Assert(ctx.NeedsRedraw);
	}

	[Test]
	public static void View_Visibility_GoneSkipsMeasure()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView(100, 50);
		child.Visibility = .Gone;
		root.AddView(child);

		TestSetup.Layout(ctx, root);
		// Gone views should not affect parent measurement.
		// RootView fills viewport regardless, but the child shouldn't be measured.
	}

	[Test]
	public static void View_UserData_SetAndGet()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let testObj = scope String("hello");
		view.SetUserData("key", testObj);
		let retrieved = view.GetUserData("key");
		Test.Assert(retrieved === testObj);
	}

	[Test]
	public static void View_UserData_NullWhenNotSet()
	{
		let view = scope TestView();
		Test.Assert(view.GetUserData("missing") == null);
	}

	[Test]
	public static void View_UserData_TypedRetrieval()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let str = scope String("test");
		view.SetUserData("str", str);
		let typed = view.GetUserData<String>("str");
		Test.Assert(typed === str);
	}

	[Test]
	public static void View_LocalToScreen_NestedViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		group.Layout(10, 20, 100, 100);
		child.Layout(5, 5, 50, 30);

		let screen = child.LocalToScreen(.(0, 0));
		Test.Assert(Math.Abs(screen.X - 15) < 0.01f);
		Test.Assert(Math.Abs(screen.Y - 25) < 0.01f);
	}

	[Test]
	public static void View_ScreenToLocal_NestedViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		group.Layout(10, 20, 100, 100);
		child.Layout(5, 5, 50, 30);

		let local = child.ScreenToLocal(.(15, 25));
		Test.Assert(Math.Abs(local.X) < 0.01f);
		Test.Assert(Math.Abs(local.Y) < 0.01f);
	}

	[Test]
	public static void View_IsEffectivelyEnabled_WalksParents()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.IsEffectivelyEnabled);

		group.IsEnabled = false;
		Test.Assert(!child.IsEffectivelyEnabled);
		Test.Assert(!group.IsEffectivelyEnabled);
	}

	[Test]
	public static void View_GetControlState_Disabled()
	{
		let view = scope TestView();
		view.IsEnabled = false;
		Test.Assert(view.GetControlState().HasFlag(.Disabled));
	}

	[Test]
	public static void View_EffectiveCursor_InheritsFromParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		group.Cursor = .Hand;
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.EffectiveCursor == .Hand);
		Test.Assert(child.Cursor == .Default);
	}

	[Test]
	public static void View_EffectiveCursor_ChildOverridesParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		group.Cursor = .Hand;
		let child = new TestView();
		child.Cursor = .IBeam;
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.EffectiveCursor == .IBeam);
	}
}
