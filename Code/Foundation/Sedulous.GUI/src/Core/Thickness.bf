using System;

namespace Sedulous.GUI;

/// Represents the thickness of a frame around a rectangle.
/// Used for margins, padding, and border thickness.
public struct Thickness : IEquatable<Thickness>, IEquatable, IHashable
{
	public float Left;
	public float Top;
	public float Right;
	public float Bottom;

	/// Creates a uniform thickness on all sides.
	public this(float uniformThickness)
	{
		Left = uniformThickness;
		Top = uniformThickness;
		Right = uniformThickness;
		Bottom = uniformThickness;
	}

	/// Creates a thickness with horizontal and vertical values.
	public this(float horizontal, float vertical)
	{
		Left = horizontal;
		Top = vertical;
		Right = horizontal;
		Bottom = vertical;
	}

	/// Creates a thickness with individual values for each side.
	public this(float left, float top, float right, float bottom)
	{
		Left = left;
		Top = top;
		Right = right;
		Bottom = bottom;
	}

	/// Zero thickness on all sides.
	public static Thickness Zero => .(0);

	/// Total horizontal thickness (Left + Right).
	public float TotalHorizontal => Left + Right;

	/// Total vertical thickness (Top + Bottom).
	public float TotalVertical => Top + Bottom;

	/// Whether all sides are zero.
	public bool IsZero => Left == 0 && Top == 0 && Right == 0 && Bottom == 0;

	/// Whether all sides have the same value.
	public bool IsUniform => Left == Top && Top == Right && Right == Bottom;

	public bool Equals(Thickness other)
	{
		return Left == other.Left && Top == other.Top && Right == other.Right && Bottom == other.Bottom;
	}

	public bool Equals(Object other)
	{
		if (other is Thickness)
			return Equals((Thickness)other);
		return false;
	}

	public int GetHashCode()
	{
		int hash = 17;
		hash = hash * 31 + Left.GetHashCode();
		hash = hash * 31 + Top.GetHashCode();
		hash = hash * 31 + Right.GetHashCode();
		hash = hash * 31 + Bottom.GetHashCode();
		return hash;
	}

	public static bool operator ==(Thickness lhs, Thickness rhs)
	{
		return lhs.Equals(rhs);
	}

	public static bool operator !=(Thickness lhs, Thickness rhs)
	{
		return !lhs.Equals(rhs);
	}

	public static Thickness operator +(Thickness lhs, Thickness rhs)
	{
		return .(lhs.Left + rhs.Left, lhs.Top + rhs.Top, lhs.Right + rhs.Right, lhs.Bottom + rhs.Bottom);
	}

	public static Thickness operator -(Thickness lhs, Thickness rhs)
	{
		return .(lhs.Left - rhs.Left, lhs.Top - rhs.Top, lhs.Right - rhs.Right, lhs.Bottom - rhs.Bottom);
	}

	public static Thickness operator *(Thickness thickness, float scale)
	{
		return .(thickness.Left * scale, thickness.Top * scale, thickness.Right * scale, thickness.Bottom * scale);
	}

	public override void ToString(String strBuffer)
	{
		if (IsUniform)
			strBuffer.AppendF("Thickness({0})", Left);
		else if (Left == Right && Top == Bottom)
			strBuffer.AppendF("Thickness({0}, {1})", Left, Top);
		else
			strBuffer.AppendF("Thickness({0}, {1}, {2}, {3})", Left, Top, Right, Bottom);
	}
}
