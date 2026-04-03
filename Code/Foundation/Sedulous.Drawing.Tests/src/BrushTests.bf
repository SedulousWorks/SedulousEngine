using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.Drawing.Tests;

class BrushTests
{
	// === SolidBrush Tests ===

	[Test]
	public static void SolidBrush_BaseColor_ReturnsSetColor()
	{
		let brush = scope SolidBrush(Color.Red);

		Test.Assert(brush.BaseColor == Color.Red);
	}

	[Test]
	public static void SolidBrush_RequiresInterpolation_ReturnsFalse()
	{
		let brush = scope SolidBrush(Color.Blue);

		Test.Assert(!brush.RequiresInterpolation);
	}

	[Test]
	public static void SolidBrush_Texture_ReturnsNull()
	{
		let brush = scope SolidBrush(Color.Green);

		Test.Assert(brush.Texture == null);
	}

	[Test]
	public static void SolidBrush_GetColorAt_ReturnsSameColor()
	{
		let brush = scope SolidBrush(Color.Yellow);
		let bounds = RectangleF(0, 0, 100, 100);

		let color1 = brush.GetColorAt(.(0, 0), bounds);
		let color2 = brush.GetColorAt(.(50, 50), bounds);
		let color3 = brush.GetColorAt(.(100, 100), bounds);

		Test.Assert(color1 == Color.Yellow);
		Test.Assert(color2 == Color.Yellow);
		Test.Assert(color3 == Color.Yellow);
	}

	[Test]
	public static void SolidBrush_SetColor_ChangesColor()
	{
		let brush = scope SolidBrush(Color.Red);
		brush.SetColor(Color.Blue);

		Test.Assert(brush.BaseColor == Color.Blue);
	}

	// === LinearGradientBrush Tests ===

	[Test]
	public static void LinearGradient_BaseColor_ReturnsStartColor()
	{
		let brush = scope LinearGradientBrush(.(0, 0), .(100, 0), Color.Red, Color.Blue);

		Test.Assert(brush.BaseColor == Color.Red);
	}

	[Test]
	public static void LinearGradient_RequiresInterpolation_ReturnsTrue()
	{
		let brush = scope LinearGradientBrush(.(0, 0), .(100, 0), Color.Red, Color.Blue);

		Test.Assert(brush.RequiresInterpolation);
	}

	[Test]
	public static void LinearGradient_GetColorAt_Start_ReturnsStartColor()
	{
		let brush = scope LinearGradientBrush(.(0, 0), .(100, 0), Color.Red, Color.Blue);
		let bounds = RectangleF(0, 0, 100, 100);

		let color = brush.GetColorAt(.(0, 0), bounds);

		Test.Assert(color == Color.Red);
	}

	[Test]
	public static void LinearGradient_GetColorAt_End_ReturnsEndColor()
	{
		let brush = scope LinearGradientBrush(.(0, 0), .(100, 0), Color.Red, Color.Blue);
		let bounds = RectangleF(0, 0, 100, 100);

		let color = brush.GetColorAt(.(100, 0), bounds);

		Test.Assert(color == Color.Blue);
	}

	[Test]
	public static void LinearGradient_GetColorAt_Middle_ReturnsInterpolatedColor()
	{
		let brush = scope LinearGradientBrush(.(0, 0), .(100, 0), Color(255, 0, 0, 255), Color(0, 0, 255, 255));
		let bounds = RectangleF(0, 0, 100, 100);

		let color = brush.GetColorAt(.(50, 0), bounds);

		// At midpoint, should be roughly equal mix
		Test.Assert(color.R > 100 && color.R < 160);
		Test.Assert(color.B > 100 && color.B < 160);
	}

	[Test]
	public static void LinearGradient_Properties_ReturnCorrectValues()
	{
		let brush = scope LinearGradientBrush(.(10, 20), .(30, 40), Color.Red, Color.Blue);

		Test.Assert(brush.StartPoint == Vector2(10, 20));
		Test.Assert(brush.EndPoint == Vector2(30, 40));
		Test.Assert(brush.StartColor == Color.Red);
		Test.Assert(brush.EndColor == Color.Blue);
	}

	// === RadialGradientBrush Tests ===

	[Test]
	public static void RadialGradient_BaseColor_ReturnsCenterColor()
	{
		let brush = scope RadialGradientBrush(.(50, 50), 50, Color.White, Color.Black);

		Test.Assert(brush.BaseColor == Color.White);
	}

	[Test]
	public static void RadialGradient_RequiresInterpolation_ReturnsTrue()
	{
		let brush = scope RadialGradientBrush(.(50, 50), 50, Color.White, Color.Black);

		Test.Assert(brush.RequiresInterpolation);
	}

	[Test]
	public static void RadialGradient_GetColorAt_Center_ReturnsCenterColor()
	{
		let brush = scope RadialGradientBrush(.(50, 50), 50, Color.White, Color.Black);
		let bounds = RectangleF(0, 0, 100, 100);

		let color = brush.GetColorAt(.(50, 50), bounds);

		Test.Assert(color == Color.White);
	}

	[Test]
	public static void RadialGradient_GetColorAt_Edge_ReturnsEdgeColor()
	{
		let brush = scope RadialGradientBrush(.(50, 50), 50, Color.White, Color.Black);
		let bounds = RectangleF(0, 0, 100, 100);

		let color = brush.GetColorAt(.(100, 50), bounds);

		Test.Assert(color == Color.Black);
	}

	[Test]
	public static void RadialGradient_Properties_ReturnCorrectValues()
	{
		let brush = scope RadialGradientBrush(.(25, 35), 75, Color.Red, Color.Green);

		Test.Assert(brush.Center == Vector2(25, 35));
		Test.Assert(brush.Radius == 75);
		Test.Assert(brush.CenterColor == Color.Red);
		Test.Assert(brush.EdgeColor == Color.Green);
	}
}
