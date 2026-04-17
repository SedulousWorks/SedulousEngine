namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class DeferredMutationTests
{
	[Test]
	public static void QueueDestroy_SetsPendingImmediately()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);

		Test.Assert(!child.IsPendingDeletion);

		child.QueueDestroy();

		// Flag set immediately, before drain.
		Test.Assert(child.IsPendingDeletion);
	}

	[Test]
	public static void QueueDestroy_ViewGoneAfterDrain()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);
		let id = child.Id;

		child.QueueDestroy();

		// Still in registry before drain (just flagged).
		Test.Assert(ctx.GetElementById(id) != null);

		ctx.BeginFrame(0); // drains the queue

		// Now gone.
		Test.Assert(ctx.GetElementById(id) == null);
	}

	[Test]
	public static void QueueRemove_DetachesWithoutDelete()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);
		let id = child.Id;

		child.QueueRemove();
		ctx.BeginFrame(0);

		// Removed from tree (unregistered) but not deleted — we can
		// still access the object since we hold a ref.
		Test.Assert(ctx.GetElementById(id) == null);
		Test.Assert(child.Parent == null);

		// Clean up manually since QueueRemove doesn't delete.
		delete child;
	}

	[Test]
	public static void OnElementDeleted_ClearsInputManagerHover()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let frame = new FrameLayout();
		ctx.Root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 100;
		child.PreferredHeight = 100;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 100, Height = 100 });

		ctx.DoLayout();

		// Hover over the child.
		ctx.InputManager.ProcessMouseMove(50, 50);
		Test.Assert(ctx.InputManager.HoveredId == child.Id);

		// Remove child → InputManager.OnElementDeleted called via UnregisterElement.
		frame.RemoveView(child, true);

		// Hover should be cleared.
		Test.Assert(ctx.InputManager.HoveredId == ViewId.Invalid);
	}
}
