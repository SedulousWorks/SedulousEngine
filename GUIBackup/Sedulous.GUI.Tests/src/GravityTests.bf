namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class GravityTests
{
	[Test]
	public static void None_IsZero()
	{
		Test.Assert(Gravity.None == 0);
	}

	[Test]
	public static void Center_IsCenterHOrCenterV()
	{
		Test.Assert(Gravity.Center == (Gravity.CenterH | Gravity.CenterV));
	}

	[Test]
	public static void Fill_IsFillHOrFillV()
	{
		Test.Assert(Gravity.Fill == (Gravity.FillH | Gravity.FillV));
	}

	[Test]
	public static void Combinations_Work()
	{
		let topRight = Gravity.Top | Gravity.Right;
		Test.Assert(topRight == Gravity.TopRight);

		let bottomLeft = Gravity.Bottom | Gravity.Left;
		Test.Assert(bottomLeft == Gravity.BottomLeft);
	}

	[Test]
	public static void FlagsAreDistinct()
	{
		Test.Assert((Gravity.Left & Gravity.Right) == 0);
		Test.Assert((Gravity.Top & Gravity.Bottom) == 0);
		Test.Assert((Gravity.CenterH & Gravity.FillH) == 0);
		Test.Assert((Gravity.CenterV & Gravity.FillV) == 0);
		Test.Assert((Gravity.Left & Gravity.Top) == 0);
	}
}
