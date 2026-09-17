using System;

namespace Sedulous.Core;

/// Linear float RGBA: the runtime colour currency, where blending and shading happen.
///
/// The packed byte counterpart is Color32; conversions between them live there.
[CRepr]
struct Color
{
	public float R = 0.0f;
	public float G = 0.0f;
	public float B = 0.0f;
	public float A = 1.0f;

	public this() { }
	public this(float r, float g, float b, float a = 1.0f)
	{
		this.R = r; this.G = g; this.B = b; this.A = a;
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
		(ByteOf(R) << 24) | (ByteOf(G) << 16) | (ByteOf(B) << 8) | ByteOf(A);

	public static Color FromRGBA8(uint32 packed) => .(
		(float)((packed >> 24) & 0xFF) / 255.0f,
		(float)((packed >> 16) & 0xFF) / 255.0f,
		(float)((packed >> 8) & 0xFF) / 255.0f,
		(float)(packed & 0xFF) / 255.0f);

	/// From 0-255 channel bytes, the common literal form: Color.Rgb(28, 28, 33). Saves
	/// every UI widget rolling its own 0-255 helper.
	public static Color Rgb(uint8 R, uint8 G, uint8 B, uint8 A = 255) => .(
		(float)R / 255.0f, (float)G / 255.0f, (float)B / 255.0f, (float)A / 255.0f);

	public static Color operator*(Color c, float s) => .(c.R * s, c.G * s, c.B * s, c.A * s);
	public static Color operator+(Color A, Color B) => .(A.R + B.R, A.G + B.G, A.B + B.B, A.A + B.A);
	/// [Commutable] so Beef can derive != from this one declaration. Without it every use
	/// of != warns, and a warning costs the whole incremental build.
	[Commutable]
	public static bool operator==(Color A, Color B) =>
		(A.R == B.R) && (A.G == B.G) && (A.B == B.B) && (A.A == B.A);
}

static
{
	public static Color Lerp(Color a, Color b, float t) => .(
		Lerp(a.R, b.R, t), Lerp(a.G, b.G, t), Lerp(a.B, b.B, t), Lerp(a.A, b.A, t));

	public static bool NearlyEqual(Color a, Color b, float epsilon = Epsilon) =>
		NearlyEqual(a.R, b.R, epsilon) && NearlyEqual(a.G, b.G, epsilon) &&
		NearlyEqual(a.B, b.B, epsilon) && NearlyEqual(a.A, b.A, epsilon);
}
