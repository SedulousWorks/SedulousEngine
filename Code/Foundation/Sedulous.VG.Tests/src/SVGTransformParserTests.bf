namespace Sedulous.VG.Tests;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG.SVG;

class SVGTransformParserTests
{
	[Test]
	public static void Translate_CorrectMatrix()
	{
		if (SVGTransformParser.Parse("translate(10, 20)") case .Ok(let m))
		{
			Test.Assert(Math.Abs(m.M41 - 10) < 0.01f);
			Test.Assert(Math.Abs(m.M42 - 20) < 0.01f);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void Scale_CorrectMatrix()
	{
		if (SVGTransformParser.Parse("scale(2, 3)") case .Ok(let m))
		{
			Test.Assert(Math.Abs(m.M11 - 2) < 0.01f);
			Test.Assert(Math.Abs(m.M22 - 3) < 0.01f);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void Scale_Uniform()
	{
		if (SVGTransformParser.Parse("scale(2)") case .Ok(let m))
		{
			Test.Assert(Math.Abs(m.M11 - 2) < 0.01f);
			Test.Assert(Math.Abs(m.M22 - 2) < 0.01f);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void Rotate_CorrectMatrix()
	{
		if (SVGTransformParser.Parse("rotate(90)") case .Ok(let m))
		{
			// 90 degrees: cos(90) ≈ 0, sin(90) ≈ 1
			Test.Assert(Math.Abs(m.M11) < 0.01f);
			Test.Assert(Math.Abs(m.M12 - 1) < 0.01f);
			Test.Assert(Math.Abs(m.M21 + 1) < 0.01f);
			Test.Assert(Math.Abs(m.M22) < 0.01f);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void CombinedTransforms()
	{
		let result = SVGTransformParser.Parse("translate(10, 20) scale(2)");
		Test.Assert(result case .Ok);
	}

	[Test]
	public static void Matrix_Parse()
	{
		let result = SVGTransformParser.Parse("matrix(1 0 0 1 10 20)");
		if (result case .Ok(let m))
		{
			Test.Assert(Math.Abs(m.M11 - 1) < 0.01f);
			Test.Assert(Math.Abs(m.M41 - 10) < 0.01f);
			Test.Assert(Math.Abs(m.M42 - 20) < 0.01f);
		}
		else
		{
			Test.Assert(false);
		}
	}
}
