using System;

namespace Sedulous.Core.Mathematics;

/// Represents an RGBA color with float components.
/// Values are typically in [0,1] for LDR but can exceed 1.0 for HDR.
[CRepr]
struct Color : IEquatable<Color>, IHashable
{
	public float R;
	public float G;
	public float B;
	public float A;

	/// Black (0, 0, 0, 1).
	public static Color Black => .(0, 0, 0, 1);
	/// White (1, 1, 1, 1).
	public static Color White => .(1, 1, 1, 1);
	/// Fully transparent (0, 0, 0, 0).
	public static Color Transparent => .(0, 0, 0, 0);
	/// Red (1, 0, 0, 1).
	public static Color Red => .(1, 0, 0, 1);
	/// Green (0, 1, 0, 1).
	public static Color Green => .(0, 1, 0, 1);
	/// Blue (0, 0, 1, 1).
	public static Color Blue => .(0, 0, 1, 1);
	/// Yellow (1, 1, 0, 1).
	public static Color Yellow => .(1, 1, 0, 1);
	/// Cyan (0, 1, 1, 1).
	public static Color Cyan => .(0, 1, 1, 1);
	/// Magenta (1, 0, 1, 1).
	public static Color Magenta => .(1, 0, 1, 1);
	/// 50% gray (0.5, 0.5, 0.5, 1).
	public static Color Gray => .(0.5f, 0.5f, 0.5f, 1);

	public this(float r, float g, float b)
	{
		R = r;
		G = g;
		B = b;
		A = 1.0f;
	}

	public this(float r, float g, float b, float a)
	{
		R = r;
		G = g;
		B = b;
		A = a;
	}

	public this(Vector3 v)
	{
		R = v.X;
		G = v.Y;
		B = v.Z;
		A = 1.0f;
	}

	public this(Vector4 v)
	{
		R = v.X;
		G = v.Y;
		B = v.Z;
		A = v.W;
	}

	/// Creates a Color from a Color32 by normalizing uint8 components to [0,1].
	public this(Color32 c)
	{
		R = c.R / 255.0f;
		G = c.G / 255.0f;
		B = c.B / 255.0f;
		A = c.A / 255.0f;
	}

	/// Converts to a packed Color32 (clamped to [0,1]).
	public Color32 ToColor32()
	{
		return Color32(
			(int32)Math.Clamp(R * 255.0f + 0.5f, 0, 255),
			(int32)Math.Clamp(G * 255.0f + 0.5f, 0, 255),
			(int32)Math.Clamp(B * 255.0f + 0.5f, 0, 255),
			(int32)Math.Clamp(A * 255.0f + 0.5f, 0, 255));
	}

	public Vector3 ToVector3()
	{
		return .(R, G, B);
	}

	public Vector4 ToVector4()
	{
		return .(R, G, B, A);
	}

	/// Linear interpolation between two colors.
	public static Color Lerp(Color a, Color b, float t)
	{
		return .(
			a.R + (b.R - a.R) * t,
			a.G + (b.G - a.G) * t,
			a.B + (b.B - a.B) * t,
			a.A + (b.A - a.A) * t);
	}

	/// Component-wise multiply.
	public static Color operator *(Color a, Color b)
	{
		return .(a.R * b.R, a.G * b.G, a.B * b.B, a.A * b.A);
	}

	/// Scalar multiply.
	public static Color operator *(Color c, float s)
	{
		return .(c.R * s, c.G * s, c.B * s, c.A * s);
	}

	/// Scalar multiply (scalar on left).
	public static Color operator *(float s, Color c)
	{
		return .(c.R * s, c.G * s, c.B * s, c.A * s);
	}

	/// Component-wise add.
	public static Color operator +(Color a, Color b)
	{
		return .(a.R + b.R, a.G + b.G, a.B + b.B, a.A + b.A);
	}

	/// Component-wise subtract.
	public static Color operator -(Color a, Color b)
	{
		return .(a.R - b.R, a.G - b.G, a.B - b.B, a.A - b.A);
	}

	public static bool operator ==(Color a, Color b)
	{
		return a.R == b.R && a.G == b.G && a.B == b.B && a.A == b.A;
	}

	public static bool operator !=(Color a, Color b)
	{
		return !(a == b);
	}

	/// Implicit conversion from Color32 to Color.
	public static implicit operator Color(Color32 c)
	{
		return Color(c);
	}

	/// Explicit conversion from Color to Color32 (lossy, clamped).
	public static explicit operator Color32(Color c)
	{
		return c.ToColor32();
	}

	public bool Equals(Color other)
	{
		return this == other;
	}

	public int GetHashCode()
	{
		unchecked
		{
			var hash = 17;
			hash = hash * 23 + R.GetHashCode();
			hash = hash * 23 + G.GetHashCode();
			hash = hash * 23 + B.GetHashCode();
			hash = hash * 23 + A.GetHashCode();
			return hash;
		}
	}

	public override void ToString(String str)
	{
		str.AppendF("({0:F3}, {1:F3}, {2:F3}, {3:F3})", R, G, B, A);
	}
}
