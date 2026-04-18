namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class CursorTests
{
	[Test]
	public static void EffectiveCursor_InheritsFromParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let frame = new FrameLayout();
		frame.Cursor = .Hand;
		root.AddView(frame);

		let child = new ColorView();
		frame.AddView(child);

		// Child has default cursor -> inherits Hand from parent.
		Test.Assert(child.EffectiveCursor == .Hand);
	}

	[Test]
	public static void EffectiveCursor_ChildOverridesParent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let frame = new FrameLayout();
		frame.Cursor = .Hand;
		root.AddView(frame);

		let child = new ColorView();
		child.Cursor = .IBeam;
		frame.AddView(child);

		Test.Assert(child.EffectiveCursor == .IBeam);
	}

	[Test]
	public static void EffectiveCursor_DefaultReturnsDefault()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let child = new ColorView();
		root.AddView(child);

		Test.Assert(child.EffectiveCursor == .Default);
	}
}
