namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// A keyframe for a float curve.
[CRepr]
public struct CurveKeyFloat
{
	/// Time position [0, 1] (normalized over particle lifetime).
	public float Time;

	/// Value at this keyframe.
	public float Value;

	/// Incoming tangent (slope arriving at this key).
	public float TangentIn;

	/// Outgoing tangent (slope leaving this key).
	public float TangentOut;

	public this(float time, float value, float tangentIn = 0, float tangentOut = 0)
	{
		Time = time;
		Value = value;
		TangentIn = tangentIn;
		TangentOut = tangentOut;
	}
}

/// A keyframe for a color curve.
[CRepr]
public struct CurveKeyColor
{
	/// Time position [0, 1].
	public float Time;

	/// Color value (RGBA as Vector4).
	public Vector4 Color;

	public this(float time, Vector4 color)
	{
		Time = time;
		Color = color;
	}
}

/// Float curve with Hermite interpolation and up to 8 keyframes.
/// When KeyCount == 0, the curve is disabled and callers should use default behavior.
[CRepr]
public struct ParticleCurveFloat
{
	public const int MaxKeys = 8;

	public CurveKeyFloat[MaxKeys] Keys;
	public int32 KeyCount;

	/// Whether this curve has any keys (is active).
	public bool IsActive => KeyCount > 0;

	/// Evaluates the curve at normalized time t [0, 1].
	public float Evaluate(float t)
	{
		if (KeyCount == 0)
			return 0;
		if (KeyCount == 1)
			return Keys[0].Value;

		// Clamp to curve range
		if (t <= Keys[0].Time)
			return Keys[0].Value;
		if (t >= Keys[KeyCount - 1].Time)
			return Keys[KeyCount - 1].Value;

		// Find segment
		for (int32 i = 0; i < KeyCount - 1; i++)
		{
			if (t >= Keys[i].Time && t <= Keys[i + 1].Time)
			{
				let segmentLength = Keys[i + 1].Time - Keys[i].Time;
				if (segmentLength < 0.0001f)
					return Keys[i].Value;

				let localT = (t - Keys[i].Time) / segmentLength;
				return HermiteFloat(
					Keys[i].Value, Keys[i].TangentOut * segmentLength,
					Keys[i + 1].Value, Keys[i + 1].TangentIn * segmentLength,
					localT
				);
			}
		}

		return Keys[KeyCount - 1].Value;
	}

	/// Cubic Hermite interpolation.
	private static float HermiteFloat(float p0, float m0, float p1, float m1, float t)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		return (2 * t3 - 3 * t2 + 1) * p0
			 + (t3 - 2 * t2 + t) * m0
			 + (-2 * t3 + 3 * t2) * p1
			 + (t3 - t2) * m1;
	}

	/// Creates a constant curve.
	public static Self Constant(float value)
	{
		var curve = Self();
		curve.Keys[0] = .(0, value);
		curve.KeyCount = 1;
		return curve;
	}

	/// Creates a linear curve from start to end.
	public static Self Linear(float start, float end)
	{
		var curve = Self();
		curve.Keys[0] = .(0, start, 0, end - start);
		curve.Keys[1] = .(1, end, end - start, 0);
		curve.KeyCount = 2;
		return curve;
	}

	/// Creates a curve that eases in (starts slow, ends fast).
	public static Self EaseIn(float start, float end)
	{
		var curve = Self();
		curve.Keys[0] = .(0, start, 0, 0);
		curve.Keys[1] = .(1, end, (end - start) * 2, 0);
		curve.KeyCount = 2;
		return curve;
	}

	/// Creates a curve that eases out (starts fast, ends slow).
	public static Self EaseOut(float start, float end)
	{
		var curve = Self();
		curve.Keys[0] = .(0, start, 0, (end - start) * 2);
		curve.Keys[1] = .(1, end, 0, 0);
		curve.KeyCount = 2;
		return curve;
	}

	/// Creates a curve that fades out at the end (value sustained, then drops to 0).
	/// fadeStart: normalized time [0,1] when fade begins.
	public static Self FadeOut(float value, float fadeStart = 0.75f)
	{
		var curve = Self();
		curve.Keys[0] = .(0, value, 0, 0);
		curve.Keys[1] = .(fadeStart, value, 0, 0);
		curve.Keys[2] = .(1, 0, -value / (1.0f - fadeStart), 0);
		curve.KeyCount = 3;
		return curve;
	}

	/// Creates a curve that peaks at a given time then falls off.
	public static Self PeakAt(float peakValue, float peakTime = 0.3f)
	{
		var curve = Self();
		curve.Keys[0] = .(0, 0, 0, peakValue / peakTime);
		curve.Keys[1] = .(peakTime, peakValue, peakValue / peakTime, -peakValue / (1.0f - peakTime));
		curve.Keys[2] = .(1, 0, -peakValue / (1.0f - peakTime), 0);
		curve.KeyCount = 3;
		return curve;
	}

	/// Adds a key to the curve. Returns false if at max capacity.
	public bool AddKey(float time, float value, float tangentIn = 0, float tangentOut = 0) mut
	{
		if (KeyCount >= MaxKeys)
			return false;

		// Insert in sorted order by time
		int32 insertIdx = KeyCount;
		for (int32 i = 0; i < KeyCount; i++)
		{
			if (Keys[i].Time > time)
			{
				insertIdx = i;
				break;
			}
		}

		// Shift keys after insert point
		for (int32 i = KeyCount; i > insertIdx; i--)
			Keys[i] = Keys[i - 1];

		Keys[insertIdx] = .(time, value, tangentIn, tangentOut);
		KeyCount++;
		return true;
	}
}

/// Color curve with linear interpolation between keyframes (up to 8 keys).
/// When KeyCount == 0, the curve is disabled.
[CRepr]
public struct ParticleCurveColor
{
	public const int MaxKeys = 8;

	public CurveKeyColor[MaxKeys] Keys;
	public int32 KeyCount;

	/// Whether this curve has any keys (is active).
	public bool IsActive => KeyCount > 0;

	/// Evaluates the color curve at normalized time t [0, 1].
	public Vector4 Evaluate(float t)
	{
		if (KeyCount == 0)
			return .(1, 1, 1, 1);
		if (KeyCount == 1)
			return Keys[0].Color;

		// Clamp to curve range
		if (t <= Keys[0].Time)
			return Keys[0].Color;
		if (t >= Keys[KeyCount - 1].Time)
			return Keys[KeyCount - 1].Color;

		// Find segment and lerp
		for (int32 i = 0; i < KeyCount - 1; i++)
		{
			if (t >= Keys[i].Time && t <= Keys[i + 1].Time)
			{
				let segmentLength = Keys[i + 1].Time - Keys[i].Time;
				if (segmentLength < 0.0001f)
					return Keys[i].Color;

				let localT = (t - Keys[i].Time) / segmentLength;
				return LerpColor(Keys[i].Color, Keys[i + 1].Color, localT);
			}
		}

		return Keys[KeyCount - 1].Color;
	}

	private static Vector4 LerpColor(Vector4 a, Vector4 b, float t)
	{
		return Vector4(
			a.X + (b.X - a.X) * t,
			a.Y + (b.Y - a.Y) * t,
			a.Z + (b.Z - a.Z) * t,
			a.W + (b.W - a.W) * t
		);
	}

	/// Creates a constant color curve.
	public static Self Constant(Vector4 color)
	{
		var curve = Self();
		curve.Keys[0] = .(0, color);
		curve.KeyCount = 1;
		return curve;
	}

	/// Creates a linear color ramp.
	public static Self Linear(Vector4 start, Vector4 end)
	{
		var curve = Self();
		curve.Keys[0] = .(0, start);
		curve.Keys[1] = .(1, end);
		curve.KeyCount = 2;
		return curve;
	}

	/// Creates a curve that fades alpha to 0.
	public static Self FadeAlpha(Vector4 color, float fadeStart = 0.75f)
	{
		var curve = Self();
		curve.Keys[0] = .(0, color);
		curve.Keys[1] = .(fadeStart, color);
		curve.Keys[2] = .(1, Vector4(color.X, color.Y, color.Z, 0));
		curve.KeyCount = 3;
		return curve;
	}

	/// Adds a key to the curve. Returns false if at max capacity.
	public bool AddKey(float time, Vector4 color) mut
	{
		if (KeyCount >= MaxKeys)
			return false;

		int32 insertIdx = KeyCount;
		for (int32 i = 0; i < KeyCount; i++)
		{
			if (Keys[i].Time > time)
			{
				insertIdx = i;
				break;
			}
		}

		for (int32 i = KeyCount; i > insertIdx; i--)
			Keys[i] = Keys[i - 1];

		Keys[insertIdx] = .(time, color);
		KeyCount++;
		return true;
	}
}

/// Vector2 curve (per-component Hermite, shares keys).
/// Used for size over lifetime.
[CRepr]
public struct ParticleCurveVector2
{
	public const int MaxKeys = 8;

	/// Keyframe data: Time + Vector2 Value + Vector2 TangentIn + Vector2 TangentOut.
	public float[MaxKeys] Times;
	public Vector2[MaxKeys] Values;
	public Vector2[MaxKeys] TangentsIn;
	public Vector2[MaxKeys] TangentsOut;
	public int32 KeyCount;

	/// Whether this curve has any keys (is active).
	public bool IsActive => KeyCount > 0;

	/// Evaluates the curve at normalized time t [0, 1].
	public Vector2 Evaluate(float t)
	{
		if (KeyCount == 0)
			return .Zero;
		if (KeyCount == 1)
			return Values[0];

		if (t <= Times[0])
			return Values[0];
		if (t >= Times[KeyCount - 1])
			return Values[KeyCount - 1];

		for (int32 i = 0; i < KeyCount - 1; i++)
		{
			if (t >= Times[i] && t <= Times[i + 1])
			{
				let segLen = Times[i + 1] - Times[i];
				if (segLen < 0.0001f)
					return Values[i];

				let localT = (t - Times[i]) / segLen;
				return Vector2(
					Hermite(Values[i].X, TangentsOut[i].X * segLen, Values[i + 1].X, TangentsIn[i + 1].X * segLen, localT),
					Hermite(Values[i].Y, TangentsOut[i].Y * segLen, Values[i + 1].Y, TangentsIn[i + 1].Y * segLen, localT)
				);
			}
		}

		return Values[KeyCount - 1];
	}

	private static float Hermite(float p0, float m0, float p1, float m1, float t)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		return (2 * t3 - 3 * t2 + 1) * p0
			 + (t3 - 2 * t2 + t) * m0
			 + (-2 * t3 + 3 * t2) * p1
			 + (t3 - t2) * m1;
	}

	/// Creates a constant Vector2 curve.
	public static Self Constant(Vector2 value)
	{
		var curve = Self();
		curve.Times[0] = 0;
		curve.Values[0] = value;
		curve.TangentsIn[0] = .Zero;
		curve.TangentsOut[0] = .Zero;
		curve.KeyCount = 1;
		return curve;
	}

	/// Creates a linear Vector2 curve.
	public static Self Linear(Vector2 start, Vector2 end)
	{
		var curve = Self();
		let delta = end - start;
		curve.Times[0] = 0;
		curve.Values[0] = start;
		curve.TangentsIn[0] = .Zero;
		curve.TangentsOut[0] = delta;
		curve.Times[1] = 1;
		curve.Values[1] = end;
		curve.TangentsIn[1] = delta;
		curve.TangentsOut[1] = .Zero;
		curve.KeyCount = 2;
		return curve;
	}

	/// Adds a key. Returns false if at capacity.
	public bool AddKey(float time, Vector2 value, Vector2 tangentIn = .Zero, Vector2 tangentOut = .Zero) mut
	{
		if (KeyCount >= MaxKeys)
			return false;

		int32 insertIdx = KeyCount;
		for (int32 i = 0; i < KeyCount; i++)
		{
			if (Times[i] > time)
			{
				insertIdx = i;
				break;
			}
		}

		for (int32 i = KeyCount; i > insertIdx; i--)
		{
			Times[i] = Times[i - 1];
			Values[i] = Values[i - 1];
			TangentsIn[i] = TangentsIn[i - 1];
			TangentsOut[i] = TangentsOut[i - 1];
		}

		Times[insertIdx] = time;
		Values[insertIdx] = value;
		TangentsIn[insertIdx] = tangentIn;
		TangentsOut[insertIdx] = tangentOut;
		KeyCount++;
		return true;
	}
}
