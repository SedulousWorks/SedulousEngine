namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class BoxConstraintsTests
{
	[Test]
	public static void Tight_MinEqualsMax()
	{
		let bc = BoxConstraints.Tight(100, 50);
		Test.Assert(bc.MinWidth == 100);
		Test.Assert(bc.MaxWidth == 100);
		Test.Assert(bc.MinHeight == 50);
		Test.Assert(bc.MaxHeight == 50);
		Test.Assert(bc.IsTight);
	}

	[Test]
	public static void Loose_MinIsZero()
	{
		let bc = BoxConstraints.Loose(200, 100);
		Test.Assert(bc.MinWidth == 0);
		Test.Assert(bc.MaxWidth == 200);
		Test.Assert(bc.MinHeight == 0);
		Test.Assert(bc.MaxHeight == 100);
		Test.Assert(bc.IsLoose);
	}

	[Test]
	public static void Expand_Unconstrained()
	{
		let bc = BoxConstraints.Expand();
		Test.Assert(bc.MinWidth == 0);
		Test.Assert(bc.MaxWidth == float.MaxValue);
		Test.Assert(bc.IsLoose);
	}

	[Test]
	public static void ConstrainWidth_Clamps()
	{
		let bc = BoxConstraints(50, 200, 0, 100);
		Test.Assert(bc.ConstrainWidth(25) == 50);  // below min
		Test.Assert(bc.ConstrainWidth(100) == 100); // in range
		Test.Assert(bc.ConstrainWidth(300) == 200); // above max
	}

	[Test]
	public static void Deflate_ShrinksByPadding()
	{
		let bc = BoxConstraints(0, 400, 0, 300);
		let deflated = bc.Deflate(Thickness(10, 20, 30, 40));
		Test.Assert(deflated.MaxWidth == 360);  // 400 - 10 - 30
		Test.Assert(deflated.MaxHeight == 240); // 300 - 20 - 40
	}

	[Test]
	public static void Loosen_ZerosMin()
	{
		let bc = BoxConstraints(50, 200, 30, 100);
		let loose = bc.Loosen();
		Test.Assert(loose.MinWidth == 0);
		Test.Assert(loose.MaxWidth == 200);
		Test.Assert(loose.MinHeight == 0);
		Test.Assert(loose.MaxHeight == 100);
	}

	[Test]
	public static void TightenToMax()
	{
		let bc = BoxConstraints(0, 200, 0, 100);
		let tight = bc.TightenToMax();
		Test.Assert(tight.MinWidth == 200);
		Test.Assert(tight.MaxWidth == 200);
		Test.Assert(tight.MinHeight == 100);
		Test.Assert(tight.MaxHeight == 100);
		Test.Assert(tight.IsTight);
	}
}
