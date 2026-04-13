namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// A float value that can be a constant or a random range.
[CRepr]
public struct RangeFloat
{
	public float Min;
	public float Max;

	/// Creates a constant value.
	public this(float value)
	{
		Min = value;
		Max = value;
	}

	/// Creates a random range.
	public this(float min, float max)
	{
		Min = min;
		Max = max;
	}

	/// Evaluates the range with a random value [0,1].
	public float Evaluate(float t)
	{
		return Min + (Max - Min) * t;
	}

	/// Whether this is a constant (min == max).
	public bool IsConstant => Min == Max;

	public static Self Constant(float value) => .(value, value);
	public static Self Range(float min, float max) => .(min, max);
}

/// A Vector2 value that can be a constant or a random range.
[CRepr]
public struct RangeVector2
{
	public Vector2 Min;
	public Vector2 Max;

	public this(Vector2 value)
	{
		Min = value;
		Max = value;
	}

	public this(Vector2 min, Vector2 max)
	{
		Min = min;
		Max = max;
	}

	public Vector2 Evaluate(float t)
	{
		return Vector2(
			Min.X + (Max.X - Min.X) * t,
			Min.Y + (Max.Y - Min.Y) * t
		);
	}

	public static Self Constant(Vector2 value) => .(value, value);
	public static Self Range(Vector2 min, Vector2 max) => .(min, max);
}

/// A Color value that can be a constant or a random range (component-wise lerp).
[CRepr]
public struct RangeColor
{
	public Vector4 Min;
	public Vector4 Max;

	public this(Vector4 value)
	{
		Min = value;
		Max = value;
	}

	public this(Vector4 min, Vector4 max)
	{
		Min = min;
		Max = max;
	}

	public Vector4 Evaluate(float t)
	{
		return Vector4(
			Min.X + (Max.X - Min.X) * t,
			Min.Y + (Max.Y - Min.Y) * t,
			Min.Z + (Max.Z - Min.Z) * t,
			Min.W + (Max.W - Min.W) * t
		);
	}

	public static Self Constant(Vector4 value) => .(value, value);
	public static Self Range(Vector4 min, Vector4 max) => .(min, max);
}
