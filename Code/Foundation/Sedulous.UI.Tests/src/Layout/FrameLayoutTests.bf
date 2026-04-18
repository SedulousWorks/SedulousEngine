namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class FrameLayoutTests
{
	[Test]
	public static void Gravity_Center()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 80;
		child.PreferredHeight = 40;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 80, Height = 40, Gravity = .Center });

		ctx.UpdateRootView(root);

		let centerX = (400 - 80) * 0.5f;
		let centerY = (300 - 40) * 0.5f;
		Test.Assert(Math.Abs(child.Bounds.X - centerX) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - centerY) < 1);
	}

	[Test]
	public static void Gravity_BottomRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		child.PreferredWidth = 60;
		child.PreferredHeight = 30;
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 60, Height = 30, Gravity = .Right | .Bottom });

		ctx.UpdateRootView(root);

		Test.Assert(Math.Abs(child.Bounds.X - (400 - 60)) < 1);
		Test.Assert(Math.Abs(child.Bounds.Y - (300 - 30)) < 1);
	}

	[Test]
	public static void Gravity_Fill()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let frame = new FrameLayout();
		root.AddView(frame);

		let child = new ColorView();
		frame.AddView(child, new FrameLayout.LayoutParams() { Width = 50, Height = 30, Gravity = .Fill });

		ctx.UpdateRootView(root);

		// Fill gravity should expand the child to fill the container.
		Test.Assert(Math.Abs(child.Bounds.Width - 400) < 1);
		Test.Assert(Math.Abs(child.Bounds.Height - 300) < 1);
	}
}
