namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.VG.SVG;

class SVGPathParserTests
{
	[Test]
	public static void MoveTo_Absolute()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 10 20", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 1);
		Test.Assert(path.Commands[0] == .MoveTo);
		Test.Assert(Math.Abs(path.Points[0].X - 10) < 0.01f);
		Test.Assert(Math.Abs(path.Points[0].Y - 20) < 0.01f);
	}

	[Test]
	public static void MoveTo_Relative()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 10 20 m 5 5", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 2);
		// Second point should be absolute (10+5, 20+5)
		Test.Assert(Math.Abs(path.Points[1].X - 15) < 0.01f);
		Test.Assert(Math.Abs(path.Points[1].Y - 25) < 0.01f);
	}

	[Test]
	public static void LineTo_AllVariants()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 L 10 0 H 20 V 10 l 5 5 h 5 v 5", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		// M + L + L(H) + L(V) + L(l) + L(h) + L(v) = 7 commands
		Test.Assert(path.CommandCount == 7);
	}

	[Test]
	public static void CubicBezier_Absolute()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 C 10 20 30 40 50 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 2);
		Test.Assert(path.Commands[1] == .CubicTo);
	}

	[Test]
	public static void CubicBezier_Relative()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 10 10 c 5 10 15 10 20 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.Commands[1] == .CubicTo);
		// Endpoint should be absolute: (10+20, 10+0) = (30, 10)
		Test.Assert(Math.Abs(path.Points[3].X - 30) < 0.01f);
	}

	[Test]
	public static void ShorthandCubic_Reflection()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 C 10 20 30 20 40 0 S 70 -20 80 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		// M + C + C(S) = 3 commands
		Test.Assert(path.CommandCount == 3);
		Test.Assert(path.Commands[2] == .CubicTo);
	}

	[Test]
	public static void QuadBezier_Absolute()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 Q 25 50 50 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.Commands[1] == .QuadTo);
	}

	[Test]
	public static void QuadBezier_Relative()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 10 10 q 15 30 30 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.Commands[1] == .QuadTo);
	}

	[Test]
	public static void ShorthandQuad_Reflection()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 Q 25 50 50 0 T 100 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 3);
		Test.Assert(path.Commands[2] == .QuadTo);
	}

	[Test]
	public static void Arc()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 10 80 A 25 25 0 0 1 50 80", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		// Arc should be converted to cubics
		Test.Assert(path.CommandCount >= 2);
	}

	[Test]
	public static void Close()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 L 10 0 L 10 10 Z", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.Commands[path.CommandCount - 1] == .Close);
	}

	[Test]
	public static void MultipleSubPaths()
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse("M 0 0 L 10 0 Z M 20 0 L 30 0 Z", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.SubPathCount == 2);
	}

	[Test]
	public static void ImplicitLineTo_AfterMoveTo()
	{
		let builder = scope PathBuilder();
		// After M, subsequent coordinate pairs are implicit L
		Test.Assert(SVGPathParser.Parse("M 0 0 10 10 20 0", builder) case .Ok);

		let path = builder.ToPath();
		defer delete path;
		// M + L + L = 3 commands
		Test.Assert(path.CommandCount == 3);
		Test.Assert(path.Commands[1] == .LineTo);
		Test.Assert(path.Commands[2] == .LineTo);
	}

	[Test]
	public static void RealWorldIconPath()
	{
		// Simplified heart icon path
		let builder = scope PathBuilder();
		let result = SVGPathParser.Parse(
			"M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z",
			builder);
		Test.Assert(result case .Ok);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount > 5);
	}
}
