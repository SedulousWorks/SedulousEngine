namespace Sedulous.Animation;

using System;
using Sedulous.Core.Mathematics;

/// Represents a single bone in a skeleton hierarchy.
public class Bone
{
	/// The name of this bone.
	public String Name ~ delete _;

	/// Index of this bone in the skeleton's bone array.
	public int32 Index;

	/// Index of the parent bone, or -1 if this is a root bone.
	public int32 ParentIndex = -1;

	/// Local transform relative to parent (bind pose).
	public BoneTransform LocalBindPose;

	/// Inverse bind pose matrix (transforms from model space to bone space).
	public Matrix InverseBindPose;

	/// Correction matrix for root bones to include missing ancestor transforms.
	/// For skeleton root bones whose model ancestors are not part of the skeleton
	/// (e.g. FBX coordinate conversion nodes), this captures those transforms.
	/// Identity for non-root bones or when no correction is needed.
	public Matrix RootCorrection;

	/// Child bone indices.
	public int32[] Children ~ delete _;

	public this()
	{
		Name = new .();
		LocalBindPose = .Identity;
		InverseBindPose = .Identity;
		RootCorrection = .Identity;
	}

	public this(StringView name, int32 index, int32 parentIndex = -1)
	{
		Name = new .(name);
		Index = index;
		ParentIndex = parentIndex;
		LocalBindPose = .Identity;
		InverseBindPose = .Identity;
		RootCorrection = .Identity;
	}
}

/// A compact transform representation for animation.
[CRepr]
public struct BoneTransform
{
	public Vector3 Position;
	public Quaternion Rotation;
	public Vector3 Scale;

	public static BoneTransform Identity => .()
	{
		Position = .Zero,
		Rotation = .Identity,
		Scale = .One
	};

	public this()
	{
		Position = .Zero;
		Rotation = .Identity;
		Scale = .One;
	}

	public this(Vector3 position, Quaternion rotation, Vector3 scale)
	{
		Position = position;
		Rotation = rotation;
		Scale = scale;
	}

	/// Converts this transform to a 4x4 matrix.
	public Matrix ToMatrix()
	{
		let scaleMatrix = Matrix.CreateScale(Scale);
		let rotationMatrix = Matrix.CreateFromQuaternion(Rotation);
		let translationMatrix = Matrix.CreateTranslation(Position);
		return scaleMatrix * rotationMatrix * translationMatrix;
	}

	/// Creates a transform from a 4x4 matrix.
	public static BoneTransform FromMatrix(Matrix matrix)
	{
		BoneTransform result = .();
		matrix.Decompose(out result.Scale, out result.Rotation, out result.Position);
		return result;
	}

	/// Interpolates between two transforms.
	public static BoneTransform Lerp(BoneTransform a, BoneTransform b, float t)
	{
		return .()
		{
			Position = Vector3.Lerp(a.Position, b.Position, t),
			Rotation = Quaternion.Slerp(a.Rotation, b.Rotation, t),
			Scale = Vector3.Lerp(a.Scale, b.Scale, t)
		};
	}
}
