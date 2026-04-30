namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio;

class SoundAttenuatorTests
{
	// ==================== Distance Gain ====================

	[Test]
	public static void Linear_AtMinDistance_FullVolume()
	{
		SoundAttenuator att = .() { MinDistance = 5, MaxDistance = 100, Curve = .Linear };
		Test.Assert(att.CalculateGain(5.0f) == 1.0f);
		Test.Assert(att.CalculateGain(3.0f) == 1.0f); // below min
	}

	[Test]
	public static void Linear_AtMaxDistance_Silent()
	{
		SoundAttenuator att = .() { MinDistance = 5, MaxDistance = 100, Curve = .Linear };
		Test.Assert(att.CalculateGain(100.0f) == 0.0f);
		Test.Assert(att.CalculateGain(150.0f) == 0.0f); // beyond max
	}

	[Test]
	public static void Linear_Midpoint()
	{
		SoundAttenuator att = .() { MinDistance = 0, MaxDistance = 100, Curve = .Linear };
		let gain = att.CalculateGain(50.0f);
		Test.Assert(Math.Abs(gain - 0.5f) < 0.001f);
	}

	[Test]
	public static void InverseDistance_AtMinDistance_FullVolume()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, Curve = .InverseDistance };
		Test.Assert(att.CalculateGain(1.0f) == 1.0f);
	}

	[Test]
	public static void InverseDistance_AtDouble_HalfVolume()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, Curve = .InverseDistance };
		let gain = att.CalculateGain(2.0f);
		Test.Assert(Math.Abs(gain - 0.5f) < 0.001f);
	}

	[Test]
	public static void InverseDistanceSquared_AtDouble_QuarterVolume()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, Curve = .InverseDistanceSquared };
		let gain = att.CalculateGain(2.0f);
		Test.Assert(Math.Abs(gain - 0.25f) < 0.001f);
	}

	[Test]
	public static void Logarithmic_BetweenMinMax()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, Curve = .Logarithmic };
		let gain = att.CalculateGain(10.0f);
		// log(10/1) / log(100/1) = 1/2, so gain = 1 - 0.5 = 0.5
		Test.Assert(Math.Abs(gain - 0.5f) < 0.01f);
	}

	// ==================== Cone ====================

	[Test]
	public static void Cone_InsideInner_FullVolume()
	{
		SoundAttenuator att = .() { ConeInnerAngle = 60, ConeOuterAngle = 120, ConeOuterGain = 0 };
		Test.Assert(att.CalculateConeGain(20.0f) == 1.0f);
	}

	[Test]
	public static void Cone_OutsideOuter_OuterGain()
	{
		SoundAttenuator att = .() { ConeInnerAngle = 60, ConeOuterAngle = 120, ConeOuterGain = 0.2f };
		let gain = att.CalculateConeGain(70.0f);
		Test.Assert(Math.Abs(gain - 0.2f) < 0.001f);
	}

	[Test]
	public static void Cone_BetweenInnerOuter_Interpolated()
	{
		SoundAttenuator att = .() { ConeInnerAngle = 60, ConeOuterAngle = 120, ConeOuterGain = 0 };
		// halfInner=30, halfOuter=60, angle=45 -> t = (45-30)/(60-30) = 0.5
		let gain = att.CalculateConeGain(45.0f);
		Test.Assert(Math.Abs(gain - 0.5f) < 0.001f);
	}

	[Test]
	public static void Cone_360_IsOmnidirectional()
	{
		SoundAttenuator att = .() { ConeInnerAngle = 360, ConeOuterAngle = 360, ConeOuterGain = 0 };
		Test.Assert(att.CalculateConeGain(180.0f) == 1.0f);
	}

	// ==================== Distance Low-Pass ====================

	[Test]
	public static void LowPass_Disabled_ReturnsNyquist()
	{
		SoundAttenuator att = .() { MaxDistanceLowPassHz = 0 };
		Test.Assert(att.CalculateLowPassCutoff(50.0f) == 22050.0f);
	}

	[Test]
	public static void LowPass_AtMinDistance_NoFiltering()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, MaxDistanceLowPassHz = 500 };
		Test.Assert(att.CalculateLowPassCutoff(0.5f) == 22050.0f);
	}

	[Test]
	public static void LowPass_AtMaxDistance_CutoffApplied()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, MaxDistanceLowPassHz = 500 };
		let cutoff = att.CalculateLowPassCutoff(100.0f);
		Test.Assert(Math.Abs(cutoff - 500.0f) < 1.0f);
	}

	[Test]
	public static void LowPass_BetweenMinMax_Interpolated()
	{
		SoundAttenuator att = .() { MinDistance = 1, MaxDistance = 100, MaxDistanceLowPassHz = 500 };
		let cutoff = att.CalculateLowPassCutoff(50.0f);
		// Should be between 500 and 22050 (logarithmic interpolation)
		Test.Assert(cutoff > 500.0f);
		Test.Assert(cutoff < 22050.0f);
	}
}
