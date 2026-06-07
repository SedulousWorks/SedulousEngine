namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class ThicknessTests
{
	[Test]
	public static void Default_IsZero()
	{
		let t = Thickness();
		Test.Assert(t.IsZero);
		Test.Assert(t.Left == 0 && t.Top == 0 && t.Right == 0 && t.Bottom == 0);
	}

	[Test]
	public static void Uniform_AllSidesEqual()
	{
		let t = Thickness(10);
		Test.Assert(t.Left == 10 && t.Top == 10 && t.Right == 10 && t.Bottom == 10);
		Test.Assert(!t.IsZero);
	}

	[Test]
	public static void HorizontalVertical_SetsPairs()
	{
		let t = Thickness(8, 4);
		Test.Assert(t.Left == 8 && t.Right == 8);
		Test.Assert(t.Top == 4 && t.Bottom == 4);
	}

	[Test]
	public static void Explicit_SetsEachSide()
	{
		let t = Thickness(1, 2, 3, 4);
		Test.Assert(t.Left == 1 && t.Top == 2 && t.Right == 3 && t.Bottom == 4);
	}

	[Test]
	public static void TotalHorizontal()
	{
		let t = Thickness(10, 5, 20, 5);
		Test.Assert(t.TotalHorizontal == 30);
	}

	[Test]
	public static void TotalVertical()
	{
		let t = Thickness(10, 5, 10, 15);
		Test.Assert(t.TotalVertical == 20);
	}
}
