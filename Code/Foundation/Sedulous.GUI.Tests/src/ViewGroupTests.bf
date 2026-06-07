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
	public static void RemoveView_DecreasesChildCount()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);
		Test.Assert(group.ChildCount == 1);

		group.RemoveView(child);
		Test.Assert(group.ChildCount == 0);
		Test.Assert(child.Parent == null);

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
		let handle = child.Handle;
		group.AddView(child);

		group.RemoveView(child, deleteChild: true);
		Test.Assert(group.ChildCount == 0);
		// Handle should be invalidated by destructor
		Test.Assert(!handle.IsValid);
	}

	[Test]
	public static void RemoveAllViews()
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

		group.RemoveAllViews(deleteChildren: true);
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

		let first = new TestView();
		let second = new TestView();
		let inserted = new TestView();

		group.AddView(first);
		group.AddView(second);
		group.InsertView(inserted, 1);

		Test.Assert(group.ChildCount == 3);
		Test.Assert(group.GetChildAt(0) === first);
		Test.Assert(group.GetChildAt(1) === inserted);
		Test.Assert(group.GetChildAt(2) === second);
	}

	[Test]
	public static void AddView_ReparentsFromPreviousParent()
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
	public static void Padding_AffectsContentBounds()
	{
		let group = scope TestGroup();
		group.Padding.Value = .(10, 20, 10, 20);
		group.Layout(0, 0, 100, 100);

		let cb = group.ContentBounds;
		Test.Assert(cb.X == 10);
		Test.Assert(cb.Y == 20);
		Test.Assert(cb.Width == 80);
		Test.Assert(cb.Height == 60);
	}
}
