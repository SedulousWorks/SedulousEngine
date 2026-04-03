using System;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents a two-dimensional size with integer components.
/// </summary>
struct Size2 : IEquatable<Size2>, IInterpolatable<Size2>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="Size2"/> structure.
    /// </summary>
    /// <param name="width">The size's width.</param>
    /// <param name="height">The size's height.</param>
    public this(int32 width, int32 height)
    {
        this.Width = width;
        this.Height = height;
    }
    
    /// <summary>
    /// Adds a <see cref="Size2"/> to another <see cref="Size2"/>.
    /// </summary>
    /// <param name="s1">The <see cref="Size2"/> on the left side of the operator.</param>
    /// <param name="s2">The <see cref="Size2"/> on the right side of the operator.</param>
    /// <returns>The result of adding the two instances.</returns>
    public static Size2 operator +(Size2 s1, Size2 s2)
    {
        Size2 result;

        result.Width = s1.Width + s2.Width;
        result.Height = s1.Height + s2.Height;

        return result;
    }

    /// <summary>
    /// Subtracts a <see cref="Size2"/> from another <see cref="Size2"/>.
    /// </summary>
    /// <param name="s1">The <see cref="Size2"/> on the left side of the operator.</param>
    /// <param name="s2">The <see cref="Size2"/> on the right side of the operator.</param>
    /// <returns>The result of subtracting the two instances.</returns>
    public static Size2 operator -(Size2 s1, Size2 s2)
    {
        Size2 result;

        result.Width = s1.Width - s2.Width;
        result.Height = s1.Height - s2.Height;

        return result;
    }

    /// <summary>
    /// Multiplies a <see cref="Size2"/> by a scalar multiplier.
    /// </summary>
    /// <param name="size">The size to multiply.</param>
    /// <param name="multiplier">The multiplier to apply to the size.</param>
    /// <returns>A <see cref="Size2"/> which is the result of the muliplication.</returns>
    public static Size2 operator *(Size2 size, int32 multiplier)
    {
        Size2 result;

        result.Width = size.Width * multiplier;
        result.Height = size.Height * multiplier;

        return result;
    }

    /// <summary>
    /// Multiplies a <see cref="Size2"/> by a scalar multiplier.
    /// </summary>
    /// <param name="size">The size to multiply.</param>
    /// <param name="multiplier">The multiplier to apply to the size.</param>
    /// <returns>A <see cref="Size2F"/> which is the result of the muliplication.</returns>
    public static Size2F operator *(Size2 size, float multiplier)
    {
        Size2F result;

        result.Width = size.Width * multiplier;
        result.Height = size.Height * multiplier;

        return result;
    }

    /// <summary>
    /// Multiplies a <see cref="Size2"/> by a scalar multiplier.
    /// </summary>
    /// <param name="size">The size to multiply.</param>
    /// <param name="multiplier">The multiplier to apply to the size.</param>
    /// <returns>A <see cref="Size2D"/> which is the result of the muliplication.</returns>
    public static Size2D operator *(Size2 size, double multiplier)
    {
        Size2D result;

        result.Width = size.Width * multiplier;
        result.Height = size.Height * multiplier;

        return result;
    }

    /// <summary>
    /// Divides a <see cref="Size2"/> by a scalar divisor.
    /// </summary>
    /// <param name="size">The size to divide.</param>
    /// <param name="divisor">The divisor to apply to the size.</param>
    /// <returns>A <see cref="Size2"/> which is the result of the muliplication.</returns>
    public static Size2 operator /(Size2 size, int32 divisor)
    {
        Size2 result;

        result.Width = size.Width / divisor;
        result.Height = size.Height / divisor;

        return result;
    }

    /// <summary>
    /// Divides a <see cref="Size2"/> by a scalar divisor.
    /// </summary>
    /// <param name="size">The size to divide.</param>
    /// <param name="divisor">The divisor to apply to the size.</param>
    /// <returns>A <see cref="Size2F"/> which is the result of the muliplication.</returns>
    public static Size2F operator /(Size2 size, float divisor)
    {
        Size2F result;

        result.Width = size.Width / divisor;
        result.Height = size.Height / divisor;

        return result;
    }

    /// <summary>
    /// Divides a <see cref="Size2"/> by a scalar divisor.
    /// </summary>
    /// <param name="size">The size to divide.</param>
    /// <param name="divisor">The divisor to apply to the size.</param>
    /// <returns>A <see cref="Size2D"/> which is the result of the muliplication.</returns>
    public static Size2D operator /(Size2 size, double divisor)
    {
        Size2D result;

        result.Width = size.Width / divisor;
        result.Height = size.Height / divisor;

        return result;
    }

    /// <summary>
    /// Explicitly converts a <see cref="Size2"/> structure to a <see cref="Vector2"/> structure.
    /// </summary>
    /// <param name="size">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator Vector2(Size2 size)
    {
        Vector2 result;

        result.X = size.Width;
        result.Y = size.Height;

        return result;
    }

    /// <summary>
    /// Explicitly converts a <see cref="Size2"/> structure to a <see cref="Point2"/> structure.
    /// </summary>
    /// <param name="size">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator Point2(Size2 size)
    {
        Point2 result;

        result.X = size.Width;
        result.Y = size.Height;

        return result;
    }

    /// <summary>
    /// Explicitly converts a <see cref="Size2"/> structure to a <see cref="Point2F"/> structure.
    /// </summary>
    /// <param name="size">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator Point2F(Size2 size)
    {
        Point2F result;

        result.X = size.Width;
        result.Y = size.Height;

        return result;
    }

    /// <summary>
    /// Explicitly converts a <see cref="Size2"/> structure to a <see cref="Point2D"/> structure.
    /// </summary>
    /// <param name="size">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator Point2D(Size2 size)
    {
        Point2D result;

        result.X = size.Width;
        result.Y = size.Height;

        return result;
    }

    /// <summary>
    /// Implicitly converts a <see cref="Size2"/> structure to a <see cref="Size2F"/> structure.
    /// </summary>
    /// <param name="size">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static implicit operator Size2F(Size2 size)
    {
        Size2F result;

        result.Width = size.Width;
        result.Height = size.Height;

        return result;
    }

    /// <summary>
    /// Implicitly converts a <see cref="Size2"/> structure to a <see cref="Size2D"/> structure.
    /// </summary>
    /// <param name="size">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static implicit operator Size2D(Size2 size)
    {
        Size2D result;

        result.Width = size.Width;
        result.Height = size.Height;

        return result;
    }

    /// <inheritdoc/>
    public override void ToString(String str) => str.Append( scope $"{{Width:{Width} Height:{Height}}}");

    /// <summary>
    /// Interpolates between this value and the specified value.
    /// </summary>
    /// <param name="target">The target value.</param>
    /// <param name="t">A value between 0.0 and 1.0 representing the interpolation factor.</param>
    /// <returns>The interpolated value.</returns>
    public Size2 Interpolate(Size2 target, float t)
    {
        Size2 result;

        result.Width = Tweening.Lerp(this.Width, target.Width, t);
        result.Height = Tweening.Lerp(this.Height, target.Height, t);

        return result;
    }

    /// <summary>
    /// Gets a size with zero width and height.
    /// </summary>
    public static Size2 Zero
    {
        get { return Size2(0, 0); }
    }

    /// <summary>
    /// Gets the size's total area (width times height).
    /// </summary>
    public int32 Area
    {
        get { return Width * Height; }
    }

    /// <summary>
    /// The size's width.
    /// </summary>
    public int32 Width;

    /// <summary>
    /// The size's height.
    /// </summary>
    public int32 Height;
}
