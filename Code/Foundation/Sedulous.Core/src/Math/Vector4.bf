using System;
using System.Numerics;

namespace Sedulous.Core;

/// A four lane SIMD compute vector.
///
/// NOT a storage type. Float4 is the storage type: it is [CRepr] and packed, which is what
/// vertex buffers and constant buffers require. This one is sixteen byte aligned and lives in
/// a register, and its layout is nobody's contract. Store data as Float4, convert here to
/// compute, convert back at the edge.
///
/// The conversions are EXPLICIT on purpose. Crossing packed to SIMD is a deliberate boundary,
/// not something that should happen because two overloads looked alike.
///
/// System.Numerics.float4 is a native vector type lowered through LLVM, so it gets SSE2,
/// NEON and wasm SIMD alike, and Beef passes it in a REGISTER rather than through memory
/// the way it passes an ordinary small struct. That is why there is no hand-rolled f32x4
/// layer selecting SSE2 by hand: corlib already is one, and a better one.
[Align(16)]
struct Vector4
{
	public float4 R = .(0, 0, 0, 0);

	[Inline] public this() {}
	[Inline] public this(float x, float y, float z, float w) { R = .(x, y, z, w); }
	[Inline] public this(float s) { R = .(s, s, s, s); }
	/// Wraps a register directly. NAME THE TYPE when converting from packed: `Vector4(.(x, y,
	/// z, w))` is ambiguous between this and the Float4 constructor, because an inferred
	/// literal has nothing to resolve against. `Vector4(Float4(...))` says which, and says it
	/// at the boundary, which is where it should be said.
	[Inline] public this(float4 v) { R = v; }
	[Inline] public this(Float4 f) { R = .(f.X, f.Y, f.Z, f.W); }

	[Inline] public Float4 ToFloat4() => .(R.x, R.y, R.z, R.w);

	[Inline] public float X => R.x;
	[Inline] public float Y => R.y;
	[Inline] public float Z => R.z;
	[Inline] public float W => R.w;

	[Inline] public static Vector4 operator-(Vector4 v) => .(-v.R);
	[Inline] public static Vector4 operator+(Vector4 a, Vector4 b) => .(a.R + b.R);
	[Inline] public static Vector4 operator-(Vector4 a, Vector4 b) => .(a.R - b.R);
	/// COMPONENT WISE. Dot is the dot product.
	[Inline] public static Vector4 operator*(Vector4 a, Vector4 b) => .(a.R * b.R);
	[Inline, Commutable] public static Vector4 operator*(Vector4 v, float s) => .(v.R * s);
	[Inline] public static Vector4 operator/(Vector4 v, float s) => .(v.R / s);

	[Inline] public void operator+=(Vector4 o) mut { R += o.R; }
	[Inline] public void operator-=(Vector4 o) mut { R -= o.R; }
	[Inline] public void operator*=(float s) mut { R *= s; }
}

static
{
	/// float4 has no horizontal add, so the product folds: xy+zw, then x+y.
	[Inline]
	public static float Dot(Vector4 a, Vector4 b)
	{
		return float4.HorizontalSum(a.R * b.R);
	}

	[Inline] public static float LengthSquared(Vector4 v) => Dot(v, v);
	[Inline] public static float Length(Vector4 v) => Sqrt(LengthSquared(v));

	public static Vector4 Normalized(Vector4 v)
	{
		let lengthSq = LengthSquared(v);
		if (lengthSq <= Epsilon * Epsilon)
			return .();
		return .(v.R * (1.0f / Sqrt(lengthSq)));
	}

	[Inline] public static Vector4 Lerp(Vector4 a, Vector4 b, float t) => a + (b - a) * t;
	[Inline] public static Vector4 Min(Vector4 a, Vector4 b) => .(float4.Min(a.R, b.R));
	[Inline] public static Vector4 Max(Vector4 a, Vector4 b) => .(float4.Max(a.R, b.R));
}
