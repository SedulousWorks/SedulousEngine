using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Model;

/// A bone, which is also a node: a model's hierarchy and its skeleton are the same tree.
class ModelBone
{
	public String Name = new .() ~ delete _;

	/// Children, NOT owned. The model owns every bone; this is the shape of the tree.
	private List<ModelBone> mChildren = new .() ~ delete _;

	/// This bone's index in the model's bone list.
	public int32 Index;
	/// The parent's index, or -1 for a root.
	public int32 ParentIndex = -1;

	public Float4x4 LocalTransform = Float4x4.Identity();
	/// Mesh space to bone space, for skinning.
	public Float4x4 InverseBindMatrix = Float4x4.Identity();

	public Float3 Translation = .Zero;
	public Quaternion Rotation = Quaternion.Identity;
	public Float3 Scale = .One;

	/// The mesh this node draws, or -1 for none.
	public int32 MeshIndex = -1;
	/// The skin this node is bound to, or -1 for none.
	public int32 SkinIndex = -1;

	public Span<ModelBone> Children => .(mChildren.Ptr, mChildren.Count);

	/// Adds a child. NOT owned: the model owns every bone.
	public void AddChild(ModelBone child) => mChildren.Add(child);

	/// Drops the child list without deleting anything, since the children belong to the
	/// model rather than to this bone.
	public void ClearChildren() => mChildren.Clear();

	/// Rebuilds LocalTransform from the translation, rotation and scale.
	///
	/// Delegated to Core's Transform, which composes S * R with the translation in the
	/// LAST ROW: the engine's row vector convention, where a point transforms as p * M.
	/// Composing it here by hand would be a second definition of that convention, free to
	/// drift from the one in Transform, which is exactly what happened once.
	public void UpdateLocalTransform()
	{
		LocalTransform = Transform(Translation, Rotation, Scale).ToMatrix();
	}
}
