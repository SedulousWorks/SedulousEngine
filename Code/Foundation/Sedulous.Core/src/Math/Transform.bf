using System;

namespace Sedulous.Core;

/// Position, rotation and scale, composed as S * R * T.
[CRepr]
struct Transform
{
	public Float3 position = Float3.Zero;
	public Quaternion rotation = Quaternion.Identity;
	public Float3 scale = Float3.One;

	public this() { }
	public this(Float3 position, Quaternion rotation, Float3 scale)
	{
		this.position = position; this.rotation = rotation; this.scale = scale;
	}

	public Float4x4 ToMatrix()
	{
		var result = Float4x4.Scale(scale) * RotationMatrix(rotation);
		result.m[3][0] = position.x;
		result.m[3][1] = position.y;
		result.m[3][2] = position.z;
		return result;
	}

	/// ToMatrix's inverse: decompose a TRS matrix, with identity components on a
	/// degenerate one. This is the editor's world-preserving reparent seam.
	public static Transform FromMatrix(Float4x4 m)
	{
		Transform t = .();
		Decompose(m, out t.position, out t.rotation, out t.scale);
		return t;
	}

	/// Component-wise: position and scale lerp, rotation slerps.
	public static Transform Lerp(Transform a, Transform b, float t) => .(
		Sedulous.Core.Lerp(a.position, b.position, t),
		Slerp(a.rotation, b.rotation, t),
		Sedulous.Core.Lerp(a.scale, b.scale, t));
}

static
{
	/// The identity transform, which is also the default-constructed value.
	///
	/// Spelled out rather than written `.()`: a const is folded at compile time without
	/// running the field initializers, so the default-constructed form yields all zeros
	/// here and a zero scale. The runtime `Transform t = .()` does run them, which is
	/// what makes the discrepancy easy to miss.
	public const Transform IdentityTransform = .(Float3.Zero, Quaternion.Identity, Float3.One);

	/// The affine transform with scale removed, leaving translation and rotation.
	///
	/// Used where a matrix must PLACE something whose dimensions are absolute in world
	/// units and so must not be warped by the placing entity's scale. A baked navmesh is
	/// the case that forced it: its agent radius and cell size are world-unit
	/// quantities, so both the bake frame and the runtime placement have to be rigid. A
	/// zone sharing a scaled entity with its geometry would otherwise un-scale the
	/// geometry the bake sees and erode the navmesh to nothing.
	public static Float4x4 RigidPart(Float4x4 m)
	{
		var t = Transform.FromMatrix(m);
		t.scale = Float3.One;
		return t.ToMatrix();
	}
}
