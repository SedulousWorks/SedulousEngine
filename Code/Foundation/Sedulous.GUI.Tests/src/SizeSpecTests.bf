namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class SizeSpecTests
{
	[Test]
	public static void Fixed_CarriesUnit()
	{
		let spec = SizeSpec.Fixed(.Dp(120));
		Test.Assert(spec.IsFixed);
		Test.Assert(Math.Abs(spec.ResolveFixed(1.0f) - 120.0f) < 0.01f);
		Test.Assert(Math.Abs(spec.ResolveFixed(2.0f) - 240.0f) < 0.01f);
	}

	[Test]
	public static void Fixed_WithPx()
	{
		let spec = SizeSpec.Fixed(.Px(50));
		Test.Assert(spec.IsFixed);
		Test.Assert(spec.ResolveFixed(1.0f) == 50.0f);
		Test.Assert(spec.ResolveFixed(2.0f) == 50.0f); // Px ignores scale
	}

	[Test]
	public static void Match_IsNotFixed()
	{
		let spec = SizeSpec.Match;
		Test.Assert(!spec.IsFixed);
		Test.Assert(spec.ResolveFixed(1.0f) == 0.0f);
	}

	[Test]
	public static void Wrap_IsNotFixed()
	{
		let spec = SizeSpec.Wrap;
		Test.Assert(!spec.IsFixed);
		Test.Assert(spec.ResolveFixed(1.0f) == 0.0f);
	}
}
