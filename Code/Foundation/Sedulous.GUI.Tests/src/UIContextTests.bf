namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class UIContextTests
{
	[Test]
	public static void AddRootView_RegistersAndSetsActive()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		Test.Assert(ctx.RootViewCount == 1);
		Test.Assert(ctx.ActiveInputRoot === root);
		Test.Assert(root.Context === ctx);
	}

	[Test]
	public static void AddRootView_FirstBecomesActive()
	{
		let ctx = scope UIContext();
		let root1 = scope RootView();
		let root2 = scope RootView();

		ctx.AddRootView(root1);
		ctx.AddRootView(root2);

		Test.Assert(ctx.ActiveInputRoot === root1);
	}

	[Test]
	public static void RemoveRootView_UpdatesActive()
	{
		let ctx = scope UIContext();
		let root1 = scope RootView();
		let root2 = scope RootView();

		ctx.AddRootView(root1);
		ctx.AddRootView(root2);
		ctx.RemoveRootView(root1);

		Test.Assert(ctx.RootViewCount == 1);
		Test.Assert(ctx.ActiveInputRoot === root2);
	}

	[Test]
	public static void RemoveRootView_ClearsContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		ctx.RemoveRootView(root);

		Test.Assert(root.Context == null);
		Test.Assert(ctx.RootViewCount == 0);
		Test.Assert(ctx.ActiveInputRoot == null);
	}

	[Test]
	public static void Register_ViewLookupByIdWorks()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);

		let found = ctx.GetViewById(child.Id);
		Test.Assert(found === child);
	}

	[Test]
	public static void Register_TypedLookup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);

		let found = ctx.GetViewById<TestView>(child.Id);
		Test.Assert(found === child);
	}

	[Test]
	public static void Unregister_LookupReturnsNull()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new TestView();
		root.AddView(child);
		let id = child.Id;

		root.RemoveView(child, true); // delete child

		Test.Assert(ctx.GetViewById(id) == null);
	}

	[Test]
	public static void AttachView_RegistersSubtree()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		// Build subtree before attaching
		group.AddView(child);
		// Now attach to root - should register both
		root.AddView(group);

		Test.Assert(ctx.GetViewById(group.Id) === group);
		Test.Assert(ctx.GetViewById(child.Id) === child);
		Test.Assert(child.Context === ctx);
	}

	[Test]
	public static void DetachView_UnregistersSubtree()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		root.AddView(group);
		group.AddView(child);
		let groupId = group.Id;
		let childId = child.Id;

		root.RemoveView(group);
		Test.Assert(ctx.GetViewById(groupId) == null);
		Test.Assert(ctx.GetViewById(childId) == null);
		delete group; // also deletes child
	}

	[Test]
	public static void BeginFrame_UpdatesTime()
	{
		let ctx = scope UIContext();
		ctx.BeginFrame(0.016f);
		Test.Assert(Math.Abs(ctx.DeltaTime - 0.016f) < 0.001f);
		Test.Assert(Math.Abs(ctx.TotalTime - 0.016f) < 0.001f);

		ctx.BeginFrame(0.016f);
		Test.Assert(Math.Abs(ctx.TotalTime - 0.032f) < 0.001f);
	}

	[Test]
	public static void Managers_CreatedByDefault()
	{
		let ctx = scope UIContext();
		Test.Assert(ctx.InputManager != null);
		Test.Assert(ctx.FocusManager != null);
		Test.Assert(ctx.DragDropManager != null);
		Test.Assert(ctx.Animations != null);
		Test.Assert(ctx.Shortcuts != null);
		Test.Assert(ctx.Tooltips != null);
	}

	[Test]
	public static void DpiScale_DefaultsTo1()
	{
		let ctx = scope UIContext();
		Test.Assert(ctx.DpiScale == 1.0f);
	}

	[Test]
	public static void DpiScale_FromActiveRoot()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.DpiScale = 2.0f;
		ctx.AddRootView(root);

		Test.Assert(ctx.DpiScale == 2.0f);
	}
}
