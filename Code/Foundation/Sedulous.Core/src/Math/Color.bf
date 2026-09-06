using System;

namespace Sedulous.Core;

/// Linear float RGBA: the runtime colour currency, where blending and shading happen.
///
/// The packed byte counterpart is Color32; conversions between them live there.
[CRepr]
struct Color
{
	public float r = 0.0f;
	public float g = 0.0f;
	public float b = 0.0f;
	public float a = 1.0f;

	public this() { }
	public this(float r, float g, float b, float a = 1.0f)
	{
		this.r = r; this.g = g; this.b = b; this.a = a;
	}

	public const Color White = .(1.0f, 1.0f, 1.0f, 1.0f);
	public const Color Black = .(0.0f, 0.0f, 0.0f, 1.0f);
	public const Color Red = .(1.0f, 0.0f, 0.0f, 1.0f);
	public const Color Green = .(0.0f, 1.0f, 0.0f, 1.0f);
	public const Color Blue = .(0.0f, 0.0f, 1.0f, 1.0f);
	public const Color Transparent = .(0.0f, 0.0f, 0.0f, 0.0f);

	[Inline]
	private static uint32 ByteOf(float c) => (uint32)(Clamp(c, 0.0f, 1.0f) * 255.0f + 0.5f);

	/// Packs to 0xRRGGBBAA, with components clamped to 0..1.
	public uint32 ToRGBA8() =>
		(ByteOf(r) << 24) | (ByteOf(g) << 16) | (ByteOf(b) << 8) | ByteOf(a);

	public static Color FromRGBA8(uint32 packed) => .(
		(float)((packed >> 24) & 0xFF) / 255.0f,
		(float)((packed >> 16) & 0xFF) / 255.0f,
		(float)((packed >> 8) & 0xFF) / 255.0f,
		(float)(packed & 0xFF) / 255.0f);

	/// From 0-255 channel bytes, the common literal form: Color.Rgb(28, 28, 33). Saves
	/// every UI widget rolling its own 0-255 helper.
	public static Color Rgb(uint8 r, uint8 g, uint8 b, uint8 a = 255) => .(
		(float)r / 255.0f, (float)g / 255.0f, (float)b / 255.0f, (float)a / 255.0f);

	public static Color operator*(Color c, float s) => .(c.r * s, c.g * s, c.b * s, c.a * s);
	public static Color operator+(Color a, Color b) => .(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a);
	public static bool operator==(Color a, Color b) =>
		(a.r == b.r) && (a.g == b.g) && (a.b == b.b) && (a.a == b.a);
}

static
{
	public static Color Lerp(Color a, Color b, float t) => .(
		Lerp(a.r, b.r, t), Lerp(a.g, b.g, t), Lerp(a.b, b.b, t), Lerp(a.a, b.a, t));

	public static bool NearlyEqual(Color a, Color b, float epsilon = Epsilon) =>
		NearlyEqual(a.r, b.r, epsilon) && NearlyEqual(a.g, b.g, epsilon) &&
		NearlyEqual(a.b, b.b, epsilon) && NearlyEqual(a.a, b.a, epsilon);
}
