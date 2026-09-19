using System;

namespace Sedulous.Core;

/// Position, Rotation and Scale, composed as S * R * T.
///
/// REFLECTED, because a property animation track names the transform as a target and resolves
/// its path against this type. Beef's reflection is opt in, so a track over an unreflected
/// transform would simply not resolve.
[CRepr, Reflect(.Type | .NonStaticFields)]
[Scriptable(.AllPublic)]
struct Transform
{
	public Float3 Position = Float3.Zero;
	public Quaternion Rotation = Quaternion.Identity;
	public Float3 Scale = Float3.One;

	[Inline]
	[Scriptable]
	public this() { }
	[Inline]
	[Scriptable]
	public this(Float3 position, Quaternion rotation, Float3 scale)
	{
		this.Position = position; this.Rotation = rotation; this.Scale = scale;
	}

	[Scriptable]
	public Float4x4 ToMatrix()
	{
		var result = Float4x4.Scale(Scale) * RotationMatrix(Rotation);
		result.M[3][0] = Position.X;
		result.M[3][1] = Position.Y;
		result.M[3][2] = Position.Z;
		return result;
	}

	/// ToMatrix's inverse: decompose a TRS matrix, with identity components on a
	/// degenerate one. This is the editor's world-preserving reparent seam.
	public static Transform FromMatrix(Float4x4 m)
	{
		Transform t = .();
		Decompose(m, out t.Position, out t.Rotation, out t.Scale);
		return t;
	}

	/// Component-wise: Position and Scale lerp, Rotation slerps.
	public static Transform Lerp(Transform a, Transform b, float t) => .(
		Sedulous.Core.Lerp(a.Position, b.Position, t),
		Slerp(a.Rotation, b.Rotation, t),
		Sedulous.Core.Lerp(a.Scale, b.Scale, t));
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
	[Scriptable]
	public static Float4x4 RigidPart(Float4x4 m)
	{
		var t = Transform.FromMatrix(m);
		t.Scale = Float3.One;
		return t.ToMatrix();
	}
}
