using System;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The geometry and stroke style descriptors.
class StyleTests
{
	[Test]
	public static void AStrokeDefaultsToAHairlineMiter()
	{
		let style = StrokeStyle();
		Test.Assert(style.Width == 1.0f);
		Test.Assert(style.Cap == .Butt);
		Test.Assert(style.Join == .Miter);
		Test.Assert(style.MiterLimit == 4.0f, "past which a miter becomes a bevel");
		Test.Assert(style.DashOffset == 0.0f);
	}

	[Test]
	public static void AStrokeCanBeStatedByWidthAlone()
	{
		let style = StrokeStyle(6.0f);
		Test.Assert(style.Width == 6.0f);
		Test.Assert(style.Cap == .Butt, "and the rest keep their defaults");
		Test.Assert(style.MiterLimit == 4.0f);

		let full = StrokeStyle(2.0f, .Round, .Bevel, 8.0f);
		Test.Assert(full.Cap == .Round);
		Test.Assert(full.Join == .Bevel);
		Test.Assert(full.MiterLimit == 8.0f);
	}

	[Test]
	public static void CornerRadiiReportUniformAndZero()
	{
		let none = CornerRadii();
		Test.Assert(none.IsZero);
		Test.Assert(none.IsUniform, "all zero is all the same");

		let uniform = CornerRadii(4.0f);
		Test.Assert(uniform.IsUniform);
		Test.Assert(!uniform.IsZero);
		Test.Assert(uniform.TopLeft == 4.0f);
		Test.Assert(uniform.BottomLeft == 4.0f);

		// Clockwise from the top left, which is the order everything states them in.
		let varied = CornerRadii(1.0f, 2.0f, 3.0f, 4.0f);
		Test.Assert(!varied.IsUniform);
		Test.Assert(!varied.IsZero);
		Test.Assert(varied.TopLeft == 1.0f);
		Test.Assert(varied.TopRight == 2.0f);
		Test.Assert(varied.BottomRight == 3.0f);
		Test.Assert(varied.BottomLeft == 4.0f);
	}

	/// One non zero corner is enough to make it not uniform, which is what decides whether
	/// the shape builder takes its fast path.
	[Test]
	public static void OneDifferentCornerBreaksUniformity()
	{
		let almost = CornerRadii(4.0f, 4.0f, 4.0f, 2.0f);
		Test.Assert(!almost.IsUniform);
		Test.Assert(!CornerRadii(0, 0, 0, 1.0f).IsZero);
	}
}
