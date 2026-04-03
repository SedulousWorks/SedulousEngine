using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Special values for size dimensions.
public enum SizeMode
{
	/// A fixed pixel value.
	Fixed,
	/// Size is determined by content (desired size).
	Auto,
	/// Size fills available space.
	Fill,
	/// Size is a proportion of available space (like WPF Star sizing).
	Proportional
}

/// Represents a single dimension value that can be fixed, auto, fill, or proportional.
public struct SizeDimension : IEquatable<SizeDimension>, IHashable
{
	/// Special value indicating automatic sizing based on content.
	public static readonly SizeDimension Auto = .(.Auto, 0);
	/// Special value indicating the element should fill available space.
	public static readonly SizeDimension Fill = .(.Fill, 1);

	public SizeMode Mode;
	public float Value;

	public this(SizeMode mode, float value)
	{
		Mode = mode;
		Value = value;
	}

	/// Creates a fixed pixel size.
	public static SizeDimension Fixed(float pixels)
	{
		return .(.Fixed, pixels);
	}

	/// Creates a proportional size (like 2* meaning 2 parts of available space).
	public static SizeDimension Proportional(float proportion)
	{
		return .(.Proportional, proportion);
	}

	/// Whether this is a fixed pixel value.
	public bool IsFixed => Mode == .Fixed;

	/// Whether this is automatic sizing.
	public bool IsAuto => Mode == .Auto;

	/// Whether this fills available space.
	public bool IsFill => Mode == .Fill;

	/// Whether this is proportional sizing.
	public bool IsProportional => Mode == .Proportional;

	public bool Equals(SizeDimension other)
	{
		return Mode == other.Mode && Value == other.Value;
	}

	public int GetHashCode()
	{
		return ((int)Mode * 31) ^ Value.GetHashCode();
	}

	/// Implicit conversion from float to fixed size.
	public static implicit operator SizeDimension(float pixels)
	{
		return Fixed(pixels);
	}

	public override void ToString(String strBuffer)
	{
		switch (Mode)
		{
		case .Fixed:
			strBuffer.AppendF("{0}", Value);
		case .Auto:
			strBuffer.Append("Auto");
		case .Fill:
			strBuffer.Append("Fill");
		case .Proportional:
			strBuffer.AppendF("{0}*", Value);
		}
	}
}

/// Represents desired size with optional width and height constraints.
public struct DesiredSize : IEquatable<DesiredSize>, IHashable
{
	public float Width;
	public float Height;

	public this(float width, float height)
	{
		Width = width;
		Height = height;
	}

	public this(Vector2 size)
	{
		Width = size.X;
		Height = size.Y;
	}

	/// Zero size.
	public static DesiredSize Zero => .(0, 0);

	/// Converts to Vector2.
	public Vector2 ToVector2() => .(Width, Height);

	public bool Equals(DesiredSize other)
	{
		return Width == other.Width && Height == other.Height;
	}

	public int GetHashCode()
	{
		return Width.GetHashCode() * 31 + Height.GetHashCode();
	}

	public static bool operator ==(DesiredSize lhs, DesiredSize rhs)
	{
		return lhs.Equals(rhs);
	}

	public static bool operator !=(DesiredSize lhs, DesiredSize rhs)
	{
		return !lhs.Equals(rhs);
	}

	public override void ToString(String strBuffer)
	{
		strBuffer.AppendF("({0}, {1})", Width, Height);
	}
}
