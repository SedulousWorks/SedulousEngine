using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// A bone/node in the model hierarchy
public class ModelBone
{
	private String mName ~ delete _;
	private List<ModelBone> mChildren ~ delete _;

	/// Index of this bone in the model's bone array
	public int32 Index;

	/// Parent bone index (-1 if root)
	public int32 ParentIndex = -1;

	/// Local transform relative to parent
	public Matrix LocalTransform = Matrix.Identity;

	/// Inverse bind matrix for skinning (transforms from mesh space to bone space)
	public Matrix InverseBindMatrix = Matrix.Identity;

	/// Translation component of local transform
	public Vector3 Translation = .Zero;

	/// Rotation component of local transform (quaternion)
	public Quaternion Rotation = .Identity;

	/// Scale component of local transform
	public Vector3 Scale = .(1, 1, 1);

	/// Mesh index if this node has a mesh (-1 if none)
	public int32 MeshIndex = -1;

	/// Skin index if this is a skinned mesh node (-1 if none)
	public int32 SkinIndex = -1;

	public StringView Name => mName;
	public List<ModelBone> Children => mChildren;

	public this()
	{
		mName = new String();
		mChildren = new List<ModelBone>();
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}

	/// Add a child bone (does not take ownership)
	public void AddChild(ModelBone child)
	{
		mChildren.Add(child);
	}

	/// Update local transform from TRS components
	public void UpdateLocalTransform()
	{
		let t = Matrix.CreateTranslation(Translation);
		let r = Matrix.CreateFromQuaternion(Rotation);
		let s = Matrix.CreateScale(Scale);

		// TRS order: Scale -> Rotate -> Translate
		LocalTransform = s * r * t;
	}
}
