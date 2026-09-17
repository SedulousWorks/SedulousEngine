using System;

namespace Sedulous.Core;

/// Packed 8-bit RGBA for compact storage: image pixels, vertex colours, asset
/// interchange. The byte counterpart of the float Color, which stays the linear and HDR
/// runtime currency.
///
/// Conversions are plain 0..255 to 0..1 with NO gamma. sRGB and linear are converted
/// explicitly at the texture and format edge, so the transfer functions below are opt-in
/// rather than folded into the cast.
[CRepr]
struct Color32
{
	public uint8 R = 0;
	public uint8 G = 0;
	public uint8 B = 0;
	public uint8 A = 255;

	public this() { }
	public this(uint8 r, uint8 g, uint8 b, uint8 a = 255)
	{
		this.R = r; this.G = g; this.B = b; this.A = a;
	}

	public const Color32 White = .(255, 255, 255, 255);
	public const Color32 Black = .(0, 0, 0, 255);
	public const Color32 Red = .(255, 0, 0, 255);
	public const Color32 Green = .(0, 255, 0, 255);
	public const Color32 Blue = .(0, 0, 255, 255);
	public const Color32 Transparent = .(0, 0, 0, 0);

	/// Packs to 0xRRGGBBAA.
	public uint32 ToRGBA8() =>
		((uint32)R << 24) | ((uint32)G << 16) | ((uint32)B << 8) | (uint32)A;

	public static Color32 FromRGBA8(uint32 packed) => .(
		(uint8)((packed >> 24) & 0xFF),
		(uint8)((packed >> 16) & 0xFF),
		(uint8)((packed >> 8) & 0xFF),
		(uint8)(packed & 0xFF));

	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	public static bool operator==(in Color32 A, in Color32 B) =>
		(A.R == B.R) && (A.G == B.G) && (A.B == B.B) && (A.A == B.A);
}

static
{
	[Inline]
	private static uint8 ByteOf(float v) => (uint8)(Clamp(v, 0.0f, 1.0f) * 255.0f + 0.5f);

	/// Float colour to packed bytes, clamped to 0..1 and rounded.
	public static Color32 ToColor32(in Color c) => .(ByteOf(c.R), ByteOf(c.G), ByteOf(c.B), ByteOf(c.A));

	/// Packed bytes to float colour: exact 0..255 to 0..1, and round-trips ToColor32.
	public static Color ToColor(Color32 c) => .(
		(float)c.R / 255.0f, (float)c.G / 255.0f, (float)c.B / 255.0f, (float)c.A / 255.0f);

	/// The standard IEC 61966-2-1 EOTF, for decoding sRGB-authored colours to linear
	/// before blending or shading in linear space.
	public static float SrgbToLinear(float c) =>
		(c <= 0.04045f) ? (c / 12.92f) : Pow((c + 0.055f) / 1.055f, 2.4f);

	public static float LinearToSrgb(float c) =>
		(c <= 0.0031308f) ? (c * 12.92f) : (1.055f * Pow(c, 1.0f / 2.4f) - 0.055f);

	/// An sRGB-authored Color32 to a linear float Color: RGB through the EOTF, alpha
	/// left linear. For uploading UI and SVG colours to a linear pipeline.
	public static Color ToLinear(Color32 c) => .(
		SrgbToLinear((float)c.R / 255.0f),
		SrgbToLinear((float)c.G / 255.0f),
		SrgbToLinear((float)c.B / 255.0f),
		(float)c.A / 255.0f);
}
