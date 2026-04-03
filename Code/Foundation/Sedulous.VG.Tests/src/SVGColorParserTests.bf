namespace Sedulous.VG.Tests;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG.SVG;

class SVGColorParserTests
{
	[Test]
	public static void Hex6_Parse()
	{
		if (SVGColorParser.Parse("#ff0000") case .Ok(let c))
		{
			Test.Assert(c.R == 255);
			Test.Assert(c.G == 0);
			Test.Assert(c.B == 0);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void Hex3_Parse()
	{
		if (SVGColorParser.Parse("#f00") case .Ok(let c))
		{
			Test.Assert(c.R == 255);
			Test.Assert(c.G == 0);
			Test.Assert(c.B == 0);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void NamedColor_Red()
	{
		if (SVGColorParser.Parse("red") case .Ok(let c))
		{
			Test.Assert(c.R == 255);
			Test.Assert(c.G == 0);
			Test.Assert(c.B == 0);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void NamedColor_Blue()
	{
		if (SVGColorParser.Parse("blue") case .Ok(let c))
		{
			Test.Assert(c.R == 0);
			Test.Assert(c.G == 0);
			Test.Assert(c.B == 255);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void RgbFunction()
	{
		if (SVGColorParser.Parse("rgb(128, 64, 32)") case .Ok(let c))
		{
			Test.Assert(c.R == 128);
			Test.Assert(c.G == 64);
			Test.Assert(c.B == 32);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void Hex_MixedCase()
	{
		if (SVGColorParser.Parse("#FfAa00") case .Ok(let c))
		{
			Test.Assert(c.R == 255);
			Test.Assert(c.G == 170);
			Test.Assert(c.B == 0);
		}
		else
		{
			Test.Assert(false);
		}
	}

	[Test]
	public static void None_Transparent()
	{
		if (SVGColorParser.Parse("none") case .Ok(let c))
		{
			Test.Assert(c.A == 0);
		}
		else
		{
			Test.Assert(false);
		}
	}
}
