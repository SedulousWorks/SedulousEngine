namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class UIContextTests
{
	[Test]
	public static void GetViewById_FindsRegisteredView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let found = ctx.GetViewById(view.Id);
		Test.Assert(found === view);
	}

	[Test]
	public static void GetViewById_ReturnsNullForInvalid()
	{
		let ctx = scope UIContext();
		let found = ctx.GetViewById(ViewId.Invalid);
		Test.Assert(found == null);
	}

	[Test]
	public static void GetViewById_ReturnsNullAfterDetach()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);
		let id = view.Id;

		root.RemoveView(view);
		let found = ctx.GetViewById(id);
		Test.Assert(found == null);

		delete view;
	}

	[Test]
	public static void GetViewById_Typed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let found = ctx.GetViewById<TestView>(view.Id);
		Test.Assert(found === view);

		// Wrong type returns null
		let wrong = ctx.GetViewById<TestGroup>(view.Id);
		Test.Assert(wrong == null);
	}

	[Test]
	public static void NameRegistry_FindByName()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.Name.Value = "my-button";
		root.AddView(view);

		let found = ctx.FindByName("my-button");
		Test.Assert(found === view);
	}

	[Test]
	public static void NameRegistry_FindByName_Typed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		view.Name.Value = "test-view";
		root.AddView(view);

		let found = ctx.FindByName<TestView>("test-view");
		Test.Assert(found === view);
	}

	[Test]
	public static void NameRegistry_ReturnsNullForUnknown()
	{
		let ctx = scope UIContext();
		let found = ctx.FindByName("nonexistent");
		Test.Assert(found == null);
	}

	[Test]
	public static void FrameLifecycle()
	{
		let ctx = scope UIContext();
		Test.Assert(ctx.CurrentPhase == .Idle);

		ctx.BeginFrame(0.016f);
		Test.Assert(ctx.CurrentPhase == .Layout);
		Test.Assert(ctx.DeltaTime == 0.016f);

		ctx.BeginDraw();
		Test.Assert(ctx.CurrentPhase == .Drawing);

		ctx.EndDraw();
		Test.Assert(ctx.CurrentPhase == .Idle);

		ctx.EndFrame();
		Test.Assert(ctx.CurrentPhase == .Idle);
	}

	[Test]
	public static void EndFrame_DrainsMutationQueue()
	{
		let ctx = scope UIContext();
		int counter = 0;
		ctx.QueueMutation(new [&counter] () => { counter++; });

		ctx.EndFrame();
		Test.Assert(counter == 1);
	}

	[Test]
	public static void AttachView_PropagatesContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		group.AddView(child);

		// Not attached yet
		Test.Assert(group.Context == null);
		Test.Assert(child.Context == null);

		root.AddView(group);

		// Now both should be attached
		Test.Assert(group.Context === ctx);
		Test.Assert(child.Context === ctx);
	}

	[Test]
	public static void DetachView_ClearsContext()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let group = new TestGroup();
		let child = new TestView();
		group.AddView(child);
		root.AddView(group);

		Test.Assert(child.Context === ctx);

		root.RemoveView(group);
		Test.Assert(group.Context == null);
		Test.Assert(child.Context == null);

		delete group;
	}
}
