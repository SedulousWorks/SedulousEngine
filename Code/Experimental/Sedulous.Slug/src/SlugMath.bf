using System;

namespace Sedulous.Slug;

/// 2D integer coordinates.
[CRepr]
public struct Integer2D
{
	public int32 x, y;

	public this() { x = 0; y = 0; }
	public this(int32 x, int32 y) { this.x = x; this.y = y; }
}

/// 2D floating-point vector.
[CRepr]
public struct Vector2D
{
	public float x, y;

	public this() { x = 0; y = 0; }
	public this(float x, float y) { this.x = x; this.y = y; }

	public static Vector2D Zero => .(0, 0);
	public static Vector2D One => .(1, 1);
}

/// 4D floating-point vector.
[CRepr]
public struct Vector4D
{
	public float x, y, z, w;

	public this() { x = 0; y = 0; z = 0; w = 0; }
	public this(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
}

/// 2D point.
[CRepr]
public struct Point2D
{
	public float x, y;

	public this() { x = 0; y = 0; }
	public this(float x, float y) { this.x = x; this.y = y; }

	public static Point2D Zero => .(0, 0);
}

/// 2x2 matrix.
[CRepr]
public struct Matrix2D
{
	public float m00, m01, m10, m11;

	public this() { m00 = 1; m01 = 0; m10 = 0; m11 = 1; }
	public this(float m00, float m01, float m10, float m11)
	{
		this.m00 = m00; this.m01 = m01;
		this.m10 = m10; this.m11 = m11;
	}

	public static Matrix2D Identity => .(1, 0, 0, 1);
}

/// Axis-aligned bounding box.
[CRepr]
public struct Box2D
{
	public Vector2D min;
	public Vector2D max;

	public this() { min = .Zero; max = .Zero; }
	public this(float minX, float minY, float maxX, float maxY)
	{
		min = .(minX, minY);
		max = .(maxX, maxY);
	}

	public float Width => max.x - min.x;
	public float Height => max.y - min.y;
	public bool IsEmpty => max.x < min.x || max.y < min.y;
}

/// 4-component color with 8-bit unsigned integer channels.
[CRepr]
public struct Color4U
{
	public uint8 r, g, b, a;

	public this() { r = 0; g = 0; b = 0; a = 255; }
	public this(uint8 r, uint8 g, uint8 b, uint8 a) { this.r = r; this.g = g; this.b = b; this.a = a; }

	public static Color4U Black => .(0, 0, 0, 255);
	public static Color4U White => .(255, 255, 255, 255);
}

/// 4-component color with 32-bit floating-point channels.
[CRepr]
public struct ColorRGBA
{
	public float r, g, b, a;

	public this() { r = 0; g = 0; b = 0; a = 1; }
	public this(float r, float g, float b, float a) { this.r = r; this.g = g; this.b = b; this.a = a; }

	public static ColorRGBA Black => .(0, 0, 0, 1);
	public static ColorRGBA White => .(1, 1, 1, 1);
}

/// Quadratic Bézier curve defined by 3 control points in em-space.
[CRepr]
public struct QuadraticBezier2D
{
	public Vector2D p1, p2, p3;

	public this() { p1 = .Zero; p2 = .Zero; p3 = .Zero; }
	public this(Vector2D p1, Vector2D p2, Vector2D p3) { this.p1 = p1; this.p2 = p2; this.p3 = p3; }
}
