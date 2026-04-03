namespace Sedulous.Animation.Tests;

using System;
using Sedulous.Core.Mathematics;

class EasingTypeTests
{
	[Test]
	public static void Linear_ReturnsInputUnchanged()
	{
		Test.Assert(EasingTypeUtil.Apply(.Linear, 0.0f) == 0.0f);
		Test.Assert(EasingTypeUtil.Apply(.Linear, 0.5f) == 0.5f);
		Test.Assert(EasingTypeUtil.Apply(.Linear, 1.0f) == 1.0f);
	}

	[Test]
	public static void ToFunction_ReturnsNonNull_ForAllTypes()
	{
		for (let easingType in Enum.GetValues<EasingType>())
		{
			let fn = EasingTypeUtil.ToFunction(easingType);
			Test.Assert(fn != null);
		}
	}

	[Test]
	public static void Apply_BoundaryValues()
	{
		// All easing functions should return 0 at t=0 and 1 at t=1
		for (let easingType in Enum.GetValues<EasingType>())
		{
			let atZero = EasingTypeUtil.Apply(easingType, 0.0f);
			let atOne = EasingTypeUtil.Apply(easingType, 1.0f);
			Test.Assert(Math.Abs(atZero) < 0.01f);
			Test.Assert(Math.Abs(atOne - 1.0f) < 0.01f);
		}
	}

	[Test]
	public static void EaseInQuadratic_SlowerStart()
	{
		let mid = EasingTypeUtil.Apply(.EaseInQuadratic, 0.5f);
		// EaseIn at midpoint should be less than linear midpoint
		Test.Assert(mid < 0.5f);
	}

	[Test]
	public static void EaseOutQuadratic_FasterStart()
	{
		let mid = EasingTypeUtil.Apply(.EaseOutQuadratic, 0.5f);
		// EaseOut at midpoint should be greater than linear midpoint
		Test.Assert(mid > 0.5f);
	}

	[Test]
	public static void EaseInOutCubic_SymmetricAtMidpoint()
	{
		let mid = EasingTypeUtil.Apply(.EaseInOutCubic, 0.5f);
		Test.Assert(Math.Abs(mid - 0.5f) < 0.01f);
	}
}
