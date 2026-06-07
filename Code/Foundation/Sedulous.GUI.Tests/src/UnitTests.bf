namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class UnitTests
{
	[Test]
	public static void Dp_ResolveAtScale1()
	{
		let u = Unit.Dp(100);
		Test.Assert(u.Resolve(1.0f) == 100.0f);
	}

	[Test]
	public static void Dp_ResolveAtScale2()
	{
		let u = Unit.Dp(100);
		Test.Assert(u.Resolve(2.0f) == 200.0f);
	}

	[Test]
	public static void Dp_ResolveAtScale1_5()
	{
		let u = Unit.Dp(100);
		Test.Assert(Math.Abs(u.Resolve(1.5f) - 150.0f) < 0.01f);
	}

	[Test]
	public static void Px_IgnoresScale()
	{
		let u = Unit.Px(50);
		Test.Assert(u.Resolve(1.0f) == 50.0f);
		Test.Assert(u.Resolve(2.0f) == 50.0f);
		Test.Assert(u.Resolve(0.5f) == 50.0f);
	}

	[Test]
	public static void Pt_ResolveAtScale1()
	{
		// 14pt at 96dpi = 14 * 1.0 * (96/72) = 18.667
		let u = Unit.Pt(14);
		let resolved = u.Resolve(1.0f);
		let expected = 14.0f * (96.0f / 72.0f);
		Test.Assert(Math.Abs(resolved - expected) < 0.01f);
	}

	[Test]
	public static void Pt_ResolveAtScale2()
	{
		let u = Unit.Pt(14);
		let resolved = u.Resolve(2.0f);
		let expected = 14.0f * 2.0f * (96.0f / 72.0f);
		Test.Assert(Math.Abs(resolved - expected) < 0.01f);
	}

	[Test]
	public static void RawValue_ReturnsUnscaled()
	{
		Test.Assert(Unit.Dp(42).RawValue == 42.0f);
		Test.Assert(Unit.Pt(14).RawValue == 14.0f);
		Test.Assert(Unit.Px(7).RawValue == 7.0f);
	}
}
