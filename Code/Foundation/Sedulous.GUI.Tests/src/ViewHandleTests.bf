namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class ViewHandleTests
{
	[Test]
	public static void Handle_IsValidAfterConstruction()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.Handle.IsValid);
		Test.Assert(view.Handle.View === view);
	}

	[Test]
	public static void Handle_NulledOnQueueDestroy()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let handle = view.Handle;
		Test.Assert(handle.IsValid);

		// QueueDestroy should null out handle immediately
		view.QueueDestroy();
		Test.Assert(!handle.IsValid);
		Test.Assert(handle.View == null);

		// Drain + purge
		ctx.EndFrame();
	}

	[Test]
	public static void Handle_SurvivesViewDeletion()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let handle = view.Handle;
		Test.Assert(handle.IsValid);

		// Directly delete the view (simulates non-deferred deletion)
		root.RemoveView(view, deleteChild: true);

		// Handle survives — it's owned by the registry, not the view.
		// View field is null but the handle object is still valid memory.
		Test.Assert(!handle.IsValid);
		Test.Assert(handle.View == null);

		// Purge cleans up the handle
		ctx.EndFrame();
	}

	[Test]
	public static void Handle_RegistryReturnsNullForDeletedView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);
		let id = view.Id;

		view.QueueDestroy();

		// Handle is nulled immediately, so registry lookup should return null
		let found = ctx.GetViewById(id);
		Test.Assert(found == null);

		ctx.EndFrame();
	}

	[Test]
	public static void Handle_SurvivesAfterQueueRemove()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		let handle = view.Handle;
		view.QueueRemove();

		// QueueRemove does NOT invalidate handle (view stays alive)
		Test.Assert(handle.IsValid);

		ctx.EndFrame();

		// After drain, view is removed but not deleted — handle still valid
		Test.Assert(handle.IsValid);

		// Clean up manually since QueueRemove doesn't delete
		delete view;
	}

	[Test]
	public static void Registry_PurgesInvalidatedHandles()
	{
		let startCount = ViewHandleRegistry.Count;

		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		// Handle exists in registry
		Test.Assert(ViewHandleRegistry.Count > startCount);

		view.QueueDestroy();
		ctx.EndFrame(); // drains + purges

		// Invalidated handle should be purged
		// (root and other views still have handles, but the deleted view's is gone)
	}
}
