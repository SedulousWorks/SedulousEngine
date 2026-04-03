namespace Sedulous.VG.Tests;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class ShapeBuilderTests
{
	[Test]
	public static void RoundedRect_UniformRadius_HasArcs()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(.(0, 0, 100, 100), .(10), builder);

		let path = builder.ToPath();
		defer delete path;
		// Should have cubics for the corners
		int cubicCount = 0;
		for (let cmd in path.Commands)
		{
			if (cmd == .CubicTo)
				cubicCount++;
		}
		Test.Assert(cubicCount == 4); // 4 corners
	}

	[Test]
	public static void RoundedRect_PerCornerRadii()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(.(0, 0, 100, 100), .(5, 10, 15, 20), builder);

		let path = builder.ToPath();
		defer delete path;
		int cubicCount = 0;
		for (let cmd in path.Commands)
		{
			if (cmd == .CubicTo)
				cubicCount++;
		}
		Test.Assert(cubicCount == 4);
	}

	[Test]
	public static void Circle_CubicApproximation()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(50, 50), 25, builder);

		let path = builder.ToPath();
		defer delete path;
		// Circle uses 4 cubics
		int cubicCount = 0;
		for (let cmd in path.Commands)
		{
			if (cmd == .CubicTo)
				cubicCount++;
		}
		Test.Assert(cubicCount == 4);
	}

	[Test]
	public static void Hexagon_SixSides()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRegularPolygon(.(50, 50), 25, 6, builder);

		let path = builder.ToPath();
		defer delete path;
		// MoveTo + 5 LineTo + Close
		int lineToCount = 0;
		for (let cmd in path.Commands)
		{
			if (cmd == .LineTo)
				lineToCount++;
		}
		Test.Assert(lineToCount == 5);
	}

	[Test]
	public static void Star_CorrectPointCount()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildStar(.(50, 50), 30, 15, 5, builder);

		let path = builder.ToPath();
		defer delete path;
		// 5-point star: MoveTo + 9 LineTo + Close = 11 commands
		int lineToCount = 0;
		for (let cmd in path.Commands)
		{
			if (cmd == .LineTo)
				lineToCount++;
		}
		Test.Assert(lineToCount == 9); // 10 points total, 1 MoveTo + 9 LineTo
	}

	[Test]
	public static void Ellipse_FourCubics()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildEllipse(.(50, 50), 30, 20, builder);

		let path = builder.ToPath();
		defer delete path;
		int cubicCount = 0;
		for (let cmd in path.Commands)
		{
			if (cmd == .CubicTo)
				cubicCount++;
		}
		Test.Assert(cubicCount == 4);
	}
}
