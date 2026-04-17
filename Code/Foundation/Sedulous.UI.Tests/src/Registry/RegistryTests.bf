namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class RegistryTests
{
	[Test]
	public static void ViewRegistered_OnAttach()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);

		// Should be findable via ID.
		let found = ctx.GetElementById(child.Id);
		Test.Assert(found === child);
	}

	[Test]
	public static void ViewUnregistered_OnRemove()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);
		let id = child.Id;

		ctx.Root.RemoveView(child, true); // dispose

		// Should no longer be findable.
		let found = ctx.GetElementById(id);
		Test.Assert(found == null);
	}

	[Test]
	public static void ElementHandle_ResolvesLive()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);

		let handle = ElementHandle<ColorView>(child);
		let resolved = handle.TryResolve(ctx);
		Test.Assert(resolved === child);
	}

	[Test]
	public static void ElementHandle_NullAfterDestroy()
	{
		let ctx = scope UIContext();
		let child = new ColorView();
		ctx.Root.AddView(child);
		let handle = ElementHandle<ColorView>(child);

		ctx.Root.RemoveView(child, true);

		let resolved = handle.TryResolve(ctx);
		Test.Assert(resolved == null);
	}

	[Test]
	public static void ViewId_UniqueAcrossViews()
	{
		let a = scope ColorView();
		let b = scope ColorView();
		Test.Assert(a.Id != b.Id);
		Test.Assert(a.Id.IsValid);
		Test.Assert(b.Id.IsValid);
	}
}
