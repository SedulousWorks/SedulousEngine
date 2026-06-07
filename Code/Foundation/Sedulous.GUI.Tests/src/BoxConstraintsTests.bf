namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class BoxConstraintsTests
{
	[Test]
	public static void Tight_SetsMinEqualMax()
	{
		let c = BoxConstraints.Tight(100, 50);
		Test.Assert(c.MinWidth == 100);
		Test.Assert(c.MaxWidth == 100);
		Test.Assert(c.MinHeight == 50);
		Test.Assert(c.MaxHeight == 50);
		Test.Assert(c.IsTight);
	}

	[Test]
	public static void Loose_SetsZeroMin()
	{
		let c = BoxConstraints.Loose(200, 100);
		Test.Assert(c.MinWidth == 0);
		Test.Assert(c.MaxWidth == 200);
		Test.Assert(c.MinHeight == 0);
		Test.Assert(c.MaxHeight == 100);
		Test.Assert(c.IsLoose);
		Test.Assert(!c.IsTight);
	}

	[Test]
	public static void Expand_IsUnconstrained()
	{
		let c = BoxConstraints.Expand();
		Test.Assert(c.MinWidth == 0);
		Test.Assert(c.MaxWidth == float.MaxValue);
		Test.Assert(c.MinHeight == 0);
		Test.Assert(c.MaxHeight == float.MaxValue);
	}

	[Test]
	public static void Deflate_ShrinksByPadding()
	{
		let c = BoxConstraints.Tight(200, 100);
		let deflated = c.Deflate(.(10, 5, 10, 5)); // left, top, right, bottom

		Test.Assert(Math.Abs(deflated.MinWidth - 180) < 0.01f);
		Test.Assert(Math.Abs(deflated.MaxWidth - 180) < 0.01f);
		Test.Assert(Math.Abs(deflated.MinHeight - 90) < 0.01f);
		Test.Assert(Math.Abs(deflated.MaxHeight - 90) < 0.01f);
	}

	[Test]
	public static void Deflate_ClampsToZero()
	{
		let c = BoxConstraints.Tight(10, 10);
		let deflated = c.Deflate(.(20, 20, 20, 20));

		Test.Assert(deflated.MinWidth == 0);
		Test.Assert(deflated.MaxWidth == 0);
		Test.Assert(deflated.MinHeight == 0);
		Test.Assert(deflated.MaxHeight == 0);
	}

	[Test]
	public static void ConstrainWidth_ClampsToRange()
	{
		let c = BoxConstraints(50, 200, 0, 100);

		Test.Assert(c.ConstrainWidth(30) == 50);   // below min
		Test.Assert(c.ConstrainWidth(100) == 100);  // within range
		Test.Assert(c.ConstrainWidth(300) == 200);  // above max
	}

	[Test]
	public static void ConstrainHeight_ClampsToRange()
	{
		let c = BoxConstraints(0, 100, 25, 75);

		Test.Assert(c.ConstrainHeight(10) == 25);
		Test.Assert(c.ConstrainHeight(50) == 50);
		Test.Assert(c.ConstrainHeight(100) == 75);
	}

	[Test]
	public static void Loosen_KeepsMaxZeroesMin()
	{
		let c = BoxConstraints(50, 200, 30, 100);
		let loose = c.Loosen();

		Test.Assert(loose.MinWidth == 0);
		Test.Assert(loose.MaxWidth == 200);
		Test.Assert(loose.MinHeight == 0);
		Test.Assert(loose.MaxHeight == 100);
	}

	[Test]
	public static void TightenToMax_SetsMinToMax()
	{
		let c = BoxConstraints.Loose(300, 150);
		let tight = c.TightenToMax();

		Test.Assert(tight.MinWidth == 300);
		Test.Assert(tight.MaxWidth == 300);
		Test.Assert(tight.MinHeight == 150);
		Test.Assert(tight.MaxHeight == 150);
		Test.Assert(tight.IsTight);
	}
}
