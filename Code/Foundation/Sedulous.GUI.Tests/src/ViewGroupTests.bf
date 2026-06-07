namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class ViewGroupTests
{
	[Test]
	public static void AddView_IncreasesChildCount()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		Test.Assert(group.ChildCount == 0);
		let child = new TestView();
		group.AddView(child);
		Test.Assert(group.ChildCount == 1);
		Test.Assert(group.GetChildAt(0) === child);
	}

	[Test]
	public static void AddView_SetsParentAndContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);
		Test.Assert(child.Parent === group);
		Test.Assert(child.Context === ctx);
	}

	[Test]
	public static void AddView_RejectsNull()
	{
		let group = scope TestGroup();
		group.AddView(null);
		Test.Assert(group.ChildCount == 0);
	}

	[Test]
	public static void AddView_RejectsSelf()
	{
		let group = scope TestGroup();
		group.AddView(group);
		Test.Assert(group.ChildCount == 0);
	}

	[Test]
	public static void AddView_RejectsDuplicate()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);
		group.AddView(child); // duplicate
		Test.Assert(group.ChildCount == 1);
	}

	[Test]
	public static void AddView_ReparentsFromOldParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let groupA = new TestGroup();
		let groupB = new TestGroup();
		root.AddView(groupA);
		root.AddView(groupB);

		let child = new TestView();
		groupA.AddView(child);
		Test.Assert(groupA.ChildCount == 1);

		groupB.AddView(child);
		Test.Assert(groupA.ChildCount == 0);
		Test.Assert(groupB.ChildCount == 1);
		Test.Assert(child.Parent === groupB);
	}

	[Test]
	public static void AddView_CreatesDefaultLayoutParams()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		Test.Assert(child.LayoutParams == null);
		group.AddView(child);
		Test.Assert(child.LayoutParams != null);
	}

	[Test]
	public static void AddView_ReplacesOldLayoutParams()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		let oldLp = new LayoutParams();
		child.LayoutParams = oldLp;

		let newLp = new LayoutParams();
		group.AddView(child, newLp);
		Test.Assert(child.LayoutParams === newLp);
	}

	[Test]
	public static void RemoveView_ClearsParentAndContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);
		group.RemoveView(child);

		Test.Assert(child.Parent == null);
		Test.Assert(child.Context == null);
		Test.Assert(group.ChildCount == 0);
		delete child;
	}

	[Test]
	public static void RemoveView_WithDelete()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);
		group.RemoveView(child, true); // deleteChild = true
		Test.Assert(group.ChildCount == 0);
		// child is deleted, no leak
	}

	[Test]
	public static void RemoveAllViews_ClearsAll()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		group.AddView(new TestView());
		group.AddView(new TestView());
		group.AddView(new TestView());
		Test.Assert(group.ChildCount == 3);

		group.RemoveAllViews(true);
		Test.Assert(group.ChildCount == 0);
	}

	[Test]
	public static void InsertView_AtIndex()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let a = new TestView();
		let b = new TestView();
		let c = new TestView();
		group.AddView(a);
		group.AddView(c);
		group.InsertView(b, 1);

		Test.Assert(group.ChildCount == 3);
		Test.Assert(group.GetChildAt(0) === a);
		Test.Assert(group.GetChildAt(1) === b);
		Test.Assert(group.GetChildAt(2) === c);
	}

	[Test]
	public static void ContentBounds_AccountsForPadding()
	{
		let group = scope TestGroup();
		group.Padding = .(10, 5, 10, 5);
		group.Layout(0, 0, 200, 100);

		let cb = group.ContentBounds;
		Test.Assert(cb.X == 10);
		Test.Assert(cb.Y == 5);
		Test.Assert(Math.Abs(cb.Width - 180) < 0.01f);
		Test.Assert(Math.Abs(cb.Height - 90) < 0.01f);
	}

	[Test]
	public static void HitTest_ReturnsDeepestChild()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(400, 300);
		group.AddView(child);

		TestSetup.Layout(ctx, root);

		// Hit passes through RootView -> TestGroup -> TestView
		let hit = root.HitTest(.(10, 10));
		Test.Assert(hit === child);
	}

	[Test]
	public static void HitTest_ReturnsNullOutsideBounds()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		TestSetup.Layout(ctx, root);

		let hit = root.HitTest(.(500, 500));
		Test.Assert(hit == null);
	}

	[Test]
	public static void HitTest_SkipsNotVisible()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let child = new TestView(400, 300);
		child.Visibility = .Hidden;
		root.AddView(child);

		TestSetup.Layout(ctx, root);

		let hit = root.HitTest(.(10, 10));
		Test.Assert(hit !== child);
	}

	[Test]
	public static void HitTest_SkipsNotInteractionEnabled()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let child = new TestView(400, 300);
		child.IsInteractionEnabled = false;
		root.AddView(child);

		TestSetup.Layout(ctx, root);

		let hit = root.HitTest(.(10, 10));
		Test.Assert(hit !== child);
	}

	[Test]
	public static void HitTest_PassThroughNonHitTestVisible()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let group = new TestGroup();
		group.IsHitTestVisible = false;
		root.AddView(group);

		let child = new TestView(400, 300);
		group.AddView(child);

		TestSetup.Layout(ctx, root);

		// Should pass through the group and hit the child.
		let hit = root.HitTest(.(10, 10));
		Test.Assert(hit === child);
	}

	[Test]
	public static void HitTest_ReverseOrder_TopmostFirst()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let a = new TestView(400, 300);
		let b = new TestView(400, 300);
		root.AddView(a);
		root.AddView(b); // b is on top

		TestSetup.Layout(ctx, root);

		let hit = root.HitTest(.(10, 10));
		Test.Assert(hit === b); // topmost wins
	}
}
