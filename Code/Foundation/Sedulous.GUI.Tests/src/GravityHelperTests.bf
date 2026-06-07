namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class GravityHelperTests
{
	[Test]
	public static void None_TopLeft()
	{
		let r = GravityHelper.Apply(.None, 400, 300, 100, 50, .());
		Test.Assert(Math.Abs(r.X) < 0.01f);
		Test.Assert(Math.Abs(r.Y) < 0.01f);
		Test.Assert(Math.Abs(r.Width - 100) < 0.01f);
		Test.Assert(Math.Abs(r.Height - 50) < 0.01f);
	}

	[Test]
	public static void Center()
	{
		let r = GravityHelper.Apply(.Center, 400, 300, 100, 50, .());
		Test.Assert(Math.Abs(r.X - 150) < 0.01f);
		Test.Assert(Math.Abs(r.Y - 125) < 0.01f);
	}

	[Test]
	public static void BottomRight()
	{
		let r = GravityHelper.Apply(.Bottom | .Right, 400, 300, 100, 50, .());
		Test.Assert(Math.Abs(r.X - 300) < 0.01f);
		Test.Assert(Math.Abs(r.Y - 250) < 0.01f);
	}

	[Test]
	public static void Fill()
	{
		let r = GravityHelper.Apply(.Fill, 400, 300, 100, 50, .());
		Test.Assert(Math.Abs(r.X) < 0.01f);
		Test.Assert(Math.Abs(r.Y) < 0.01f);
		Test.Assert(Math.Abs(r.Width - 400) < 0.01f);
		Test.Assert(Math.Abs(r.Height - 300) < 0.01f);
	}

	[Test]
	public static void WithMargin()
	{
		let r = GravityHelper.Apply(.Center, 400, 300, 100, 50, .(10, 20, 10, 20));
		Test.Assert(Math.Abs(r.X - 150) < 0.01f); // 10 + (380-100)/2
		Test.Assert(Math.Abs(r.Y - 125) < 0.01f); // 20 + (260-50)/2
	}

	[Test]
	public static void FillWithMargin()
	{
		let r = GravityHelper.Apply(.Fill, 400, 300, 100, 50, .(10, 20, 30, 40));
		Test.Assert(Math.Abs(r.X - 10) < 0.01f);
		Test.Assert(Math.Abs(r.Y - 20) < 0.01f);
		Test.Assert(Math.Abs(r.Width - 360) < 0.01f);
		Test.Assert(Math.Abs(r.Height - 240) < 0.01f);
	}
}
