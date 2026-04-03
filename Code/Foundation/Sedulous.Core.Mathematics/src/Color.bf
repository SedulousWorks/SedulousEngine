using System;
using System.Collections;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents an RGBA color.
/// </summary>
struct Color : IEquatable<Color>, IInterpolatable<Color>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes the <see cref="Color"/> type.
    /// </summary>
    /*static this()
    {
        var namedColorProperties = typeof(Color).GetProperties(BindingFlags.Public | BindingFlags.Static)
            .Where(x => x.PropertyType == typeof(Color));

        for (var namedColorProperty in namedColorProperties)
        {
            var name = namedColorProperty.Name;
            var value = (Color)namedColorProperty.GetValue(null, null);

            NamedColorRegistry[name] = value;
        }
    }*/

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure.
    /// </summary>
    /// <param name="packedValue">The color's packed value in ABGR format.</param>
    public this(uint32 packedValue)
    {
        this.packedValue = packedValue;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure with the specified component values.
    /// </summary>
    /// <param name="r">The red component.</param>
    /// <param name="g">The green component.</param>
    /// <param name="b">The blue component.</param>
    public this(float r, float g, float b)
    {
		var r;
		var g;
		var b;

        if (r < 0) r = 0;
        if (r > 1) r = 1;
        if (g < 0) g = 0;
        if (g > 1) g = 1;
        if (b < 0) b = 0;
        if (b > 1) b = 1;

        var rbyte = (uint8)(r * uint8.MaxValue);
        var gbyte = (uint8)(g * uint8.MaxValue);
        var bbyte = (uint8)(b * uint8.MaxValue);

        this.packedValue = (uint32)((rbyte) | ((uint32)gbyte << 8) | ((uint32)bbyte << 16) | (255 << 24));
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure with the specified component values.
    /// </summary>
    /// <param name="r">The red component.</param>
    /// <param name="g">The green component.</param>
    /// <param name="b">The blue component.</param>
    /// <param name="a">The alpha component.</param>
    public this(float r, float g, float b, float a)
    {
		var r;
		var g;
		var b;
		var a;

        if (r < 0) r = 0;
        if (r > 1) r = 1;
        if (g < 0) g = 0;
        if (g > 1) g = 1;
        if (b < 0) b = 0;
        if (b > 1) b = 1;
        if (a < 0) a = 0;
        if (a > 1) a = 1;

        var rbyte = (uint8)(r * uint8.MaxValue);
        var gbyte = (uint8)(g * uint8.MaxValue); 
        var bbyte = (uint8)(b * uint8.MaxValue);
        var abyte = (uint8)(a * uint8.MaxValue);

        this.packedValue = (uint32)((rbyte) | ((uint32)gbyte << 8) | ((uint32)bbyte << 16) | ((uint32)abyte << 24));
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure with the specified component values.
    /// </summary>
    /// <param name="r">The red component.</param>
    /// <param name="g">The green component.</param>
    /// <param name="b">The blue component.</param>
    public this(int32 r, int32 g, int32 b)
    {
		var r;
		var g;
		var b;

        if (r < 0) r = 0;
        if (r > uint8.MaxValue) r = uint8.MaxValue;
        if (g < 0) g = 0;
        if (g > uint8.MaxValue) g = uint8.MaxValue;
        if (b < 0) b = 0;
        if (b > uint8.MaxValue) b = uint8.MaxValue;

        this.packedValue = (uint32)((uint32)(r) | ((uint32)g << 8) | ((uint32)b << 16) | ((uint32)255 << 24));
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure with the specified component values.
    /// </summary>
    /// <param name="r">The red component.</param>
    /// <param name="g">The green component.</param>
    /// <param name="b">The blue component.</param>
    /// <param name="a">The alpha component.</param>
    public this(int32 r, int32 g, int32 b, int32 a)
    {
		var r;
		var g;
		var b;
		var a;

        if (r < 0) r = 0;
        if (r > uint8.MaxValue) r = uint8.MaxValue;
        if (g < 0) g = 0;
        if (g > uint8.MaxValue) g = uint8.MaxValue;
        if (b < 0) b = 0;
        if (b > uint8.MaxValue) b = uint8.MaxValue;
        if (a < 0) a = 0;
        if (a > uint8.MaxValue) a = uint8.MaxValue;

        this.packedValue = (uint32)((r) | (g << 8) | (b << 16) | (a << 24));
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure using the x, y, and z components
    /// of the specified vector as normalized red, green, and blue values.
    /// </summary>
    /// <param name="vector">The vector from which to create the color.</param>
    public this(Vector3 vector)
        : this(vector.X, vector.Y, vector.Z)
    {

    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Color"/> structure using the x, y, z, and w components
    /// of the specified vector as normalized red, green, blue, and alpha values.
    /// </summary>
    /// <param name="vector">The vector from which to create the color.</param>
    public this(Vector4 vector)
        : this(vector.X, vector.Y, vector.Z, vector.W)
    {

    }
    
    /// <summary>
    /// Multiplies each of the color's components by the specified scaling factor.
    /// </summary>
    /// <param name="color">The <see cref="Color"/> to multiply.</param>
    /// <param name="alpha">The scaling factor by which to multiply the color.</param>
    /// <returns>The scaled <see cref="Color"/>.</returns>
    public static Color operator *(Color color, float alpha)
    {
		var alpha;

        if (alpha < 0)
            alpha = 0;

        if (alpha > 1)
            alpha = 1;

        var r = (uint8)(color.R * alpha);
        var g = (uint8)(color.G * alpha);
        var b = (uint8)(color.B * alpha);
        var a = (uint8)(color.A * alpha);

        return Color(r, g, b, a);
    }
    
    /// <summary>
    /// Creates a <see cref="Color"/> from a 32-bit integer in ARGB format.
    /// </summary>
    /// <param name="value">The integer from which to create a color.</param>
    /// <returns>The <see cref="Color"/> that corresponds to the specified integer value.</returns>
    public static Color FromArgb(uint32 value)
    {
        var a = (uint8)(value >> 24);
        var r = (uint8)(value >> 16);
        var g = (uint8)(value >> 8);
        var b = (uint8)(value);

        return Color((uint32)((uint32)(r) | ((uint32)g << 8) | ((uint32)b << 16) | ((uint32)a << 24)));
    }

    /// <summary>
    /// Creates a <see cref="Color"/> from a 32-bit integer in RGBA format.
    /// </summary>
    /// <param name="value">The integer from which to create a color.</param>
    /// <returns>The <see cref="Color"/> that corresponds to the specified integer value.</returns>
    public static Color FromRgba(uint32 value)
    {
        var r = (uint8)(value >> 24);
        var g = (uint8)(value >> 16);
        var b = (uint8)(value >> 8);
        var a = (uint8)(value);

        return Color((uint32)((uint32)(r) | ((uint32)g << 8) | ((uint32)b << 16) | ((uint32)a << 24)));
    }

    /// <summary>
    /// Creates a <see cref="Color"/> from a 32-bit integer in BGRA format.
    /// </summary>
    /// <param name="value">The integer from which to create a color.</param>
    /// <returns>The <see cref="Color"/> that corresponds to the specified integer value.</returns>
    public static Color FromBgra(uint32 value)
    {
        var b = (uint8)(value >> 24);
        var g = (uint8)(value >> 16);
        var r = (uint8)(value >> 8);
        var a = (uint8)(value);

        return Color((uint32)(((uint32)r) | ((uint32)g << 8) | ((uint32)b << 16) | ((uint32)a << 24)));
    }

    /// <summary>
    /// Converts a normalized color channel from sRGB to linear.
    /// </summary>
    /// <param name="x">The normalized color channel value to convert.</param>
    /// <returns>The converted color channel value.</returns>
    [Inline]
    public static uint8 ConvertSrgbColorChannelToLinear(uint8 x)
    {
        return (uint8)(255f * ConvertSrgbColorChannelToLinear(x / 255f));
    }

    /// <summary>
    /// Converts a color channel from linear to sRGB.
    /// </summary>
    /// <param name="x">The color channel value to convert.</param>
    /// <returns>The converted color channel value.</returns>
    [Inline]
    public static uint8 ConvertLinearColorChannelToSrgb(uint8 x)
    {
        return (uint8)(255f * ConvertLinearColorChannelToSrgb(x / 255f));
    }

    /// <summary>
    /// Converts a normalized color channel from sRGB to linear.
    /// </summary>
    /// <param name="c">The normalized color channel value to convert.</param>
    /// <returns>The converted color channel value.</returns>
    [Inline]
    public static float ConvertSrgbColorChannelToLinear(float c)
    {
        return (c < 0.04045f) ? c / 12.92f : (float)Math.Pow((c + 0.055) / 1.055, 2.4);
    }

    /// <summary>
    /// Converts a normalized color channel from linear to sRGB.
    /// </summary>
    /// <param name="c">The normalized color channel value to convert.</param>
    /// <returns>The converted color channel value.</returns>
    [Inline]
    public static float ConvertLinearColorChannelToSrgb(float c)
    {
        return (c < 0.0031308f) ? c * 12.92f : 1.055f * (float)Math.Pow(c, 1.0 / 2.4) - 0.055f;
    }

    /// <summary>
    /// Converts an sRGB color value to a linear color value.
    /// </summary>
    [Inline]
    public static Color ConvertSrgbColorToLinear(Color c)
    {
        var r = ConvertSrgbColorChannelToLinear(c.R / 255.0f);
        var g = ConvertSrgbColorChannelToLinear(c.G / 255.0f);
        var b = ConvertSrgbColorChannelToLinear(c.B / 255.0f);
        var a = c.A / 255.0f;
        return Color(r, g, b, a);
    }

    /// <summary>
    /// Converts a linear color value to an sRGB color value.
    /// </summary>
    [Inline]
    public static Color ConvertLinearColorToSrgb(Color c)
    {
        var r = ConvertLinearColorChannelToSrgb(c.R / 255.0f);
        var g = ConvertLinearColorChannelToSrgb(c.G / 255.0f);
        var b = ConvertLinearColorChannelToSrgb(c.B / 255.0f);
        var a = c.A / 255.0f;
        return Color(r, g, b, a);
    }

    /// <inheritdoc/>
    public override void ToString(String str) => str.Append( scope $"#{A:x2}{R:x2}{G:x2}{B:x2}");

    /// <summary>
    /// Converts the <see cref="Color"/> to a 32-bit integer in ARGB format.
    /// </summary>
    /// <returns>The ARGB value that corresponds to this <see cref="Color"/>.</returns>
    public uint32 ToArgb()
    {
        return (uint32)(((uint32)A << 24) | ((uint32)R << 16) | ((uint32)G << 8) | (B));
    }

    /// <summary>
    /// Converts the <see cref="Color"/> to a 32-bit integer in RGBA format.
    /// </summary>
    /// <returns>The RGBA value that corresponds to this <see cref="Color"/>.</returns>
    public uint32 ToRgba()
    {
        return (uint32)(((uint32)R << 24) | ((uint32)G << 16) | ((uint32)B << 8) | (A));
    }

    /// <summary>
    /// Converts the <see cref="Color"/> to a 32-bit integer in BGRA format.
    /// </summary>
    /// <returns>The BGRA value that corresponds to this <see cref="Color"/>.</returns>
    public uint32 ToBgra()
    {
        return (uint32)(((uint32)B << 24) | ((uint32)G << 16) | ((uint32)R << 8) | (A));
    }

    /// <summary>
    /// Converts the <see cref="Color"/> to a normalized 3-vector containing red, green, and blue components.
    /// </summary>
    /// <returns>The <see cref="Vector3"/> that corresponds to this <see cref="Color"/>.</returns>
    public Vector3 ToVector3()
    {
        return Vector3(
            R / (float)uint8.MaxValue, 
            G / (float)uint8.MaxValue, 
            B / (float)uint8.MaxValue);
    }

    /// <summary>
    /// Converts the <see cref="Color"/> to a normalized 4-vector containing red, green, blue, and alpha components.
    /// </summary>
    /// <returns>The <see cref="Vector4"/> that corresponds to this <see cref="Color"/>.</returns>
    public Vector4 ToVector4()
    {
        return Vector4(
            R / (float)uint8.MaxValue, 
            G / (float)uint8.MaxValue, 
            B / (float)uint8.MaxValue, 
            A / (float)uint8.MaxValue);
    }

    /// <summary>
    /// Interpolates between this value and the specified value.
    /// </summary>
    /// <param name="target">The target value.</param>
    /// <param name="t">A value between 0.0 and 1.0 representing the interpolation factor.</param>
    /// <returns>The interpolated value.</returns>
    public Color Interpolate(Color target, float t)
    {
        var a = Tweening.Lerp(this.A, target.A, t);
        var r = Tweening.Lerp(this.R, target.R, t);
        var g = Tweening.Lerp(this.G, target.G, t);
        var b = Tweening.Lerp(this.B, target.B, t);
        return Color(r, g, b, a);
    }

    /// <summary>
    /// Gets the color's packed value.
    /// </summary>
    public uint32 PackedValue
    {
        get { return packedValue; }
    }

    /// <summary>
    /// Gets the color's alpha component.
    /// </summary>
    public uint8 A
    {
        get { return (uint8)(packedValue >> 24); }
    }

    /// <summary>
    /// Gets the color's red component.
    /// </summary>
    public uint8 R
    {
        get { return (uint8)(packedValue); }
    }

    /// <summary>
    /// Gets the color's green component.
    /// </summary>
    public uint8 G
    {
        get { return (uint8)(packedValue >> 8); }
    }

    /// <summary>
    /// Gets the color's blue component.
    /// </summary>
    public uint8 B
    {
        get { return (uint8)(packedValue >> 16); }
    }

    // Associates the names of colors with their values.
    /*private static readonly Dictionary<String, Color> NamedColorRegistry =
        new Dictionary<String, Color>(StringComparer.Ordinal);*/

    // The packed value of the color in RGBA format.
    private readonly uint32 packedValue;
}
