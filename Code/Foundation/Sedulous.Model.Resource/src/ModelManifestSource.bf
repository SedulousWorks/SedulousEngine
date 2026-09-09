using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Model.Resource;

/// The cooked manifest: the ids of every leaf a model is assembled from, and the hierarchy
/// that arranges them.
///
/// A model owns NOTHING here. Every mesh, material, texture, skeleton and clip is its own
/// cooked resource, referenced by id, so two models sharing a material share one copy of it
/// and reimporting one leaf does not recook the rest.
///
/// FLAT PARALLEL ARRAYS, so the serializer never nests: the node hierarchy is spread across
/// six arrays rather than an array of records holding strings.
[Serializable]
class ModelManifestSource
{
	// Per mesh.
	public List<Guid> MeshGuid = new .() ~ delete _;
	/// Whether the mesh at the same index is skinned, which decides what it binds as.
	public List<bool> MeshSkinned = new .() ~ delete _;
	/// The material index per mesh, minus one for none.
	public List<int32> MeshMaterial = new .() ~ delete _;
	/// The cooked collision shape per mesh, nil for none.
	public List<Guid> CollisionGuid = new .() ~ delete _;

	// Per material.
	public List<Guid> MaterialGuid = new .() ~ delete _;
	/// The albedo texture per material, nil for none.
	public List<Guid> MaterialAlbedo = new .() ~ delete _;

	// Per node.
	public List<String> NodeName = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> NodeParent = new .() ~ delete _;
	public List<Float3> NodeTranslation = new .() ~ delete _;
	public List<Quaternion> NodeRotation = new .() ~ delete _;
	public List<Float3> NodeScale = new .() ~ delete _;
	public List<int32> NodeMesh = new .() ~ delete _;

	/// Nil when the model has no skin at all.
	public Guid SkeletonGuid = .();
	public List<Guid> AnimationGuid = new .() ~ delete _;

	/// The model space bounds, which is what a spawn fits or places against without having to
	/// load a single mesh.
	public Float3 BoundsMin = .(0, 0, 0);
	public Float3 BoundsMax = .(0, 0, 0);

	/// Rebuilds the hierarchy into owned nodes.
	///
	/// The PARENT array is what says how many nodes there are: it is the one field every node
	/// must have, and a name or a transform missing from a short array falls back rather than
	/// truncating the hierarchy.
	public void FillNodes(List<ModelNode> outNodes)
	{
		ClearAndDeleteItems!(outNodes);

		for (int i = 0; i < NodeParent.Count; i++)
		{
			let node = new ModelNode();
			node.ParentIndex = NodeParent[i];
			if (i < NodeName.Count)
				node.Name.Set(NodeName[i]);
			node.LocalTransform = .(
				(i < NodeTranslation.Count) ? NodeTranslation[i] : Float3(0, 0, 0),
				(i < NodeRotation.Count) ? NodeRotation[i] : Quaternion.Identity,
				(i < NodeScale.Count) ? NodeScale[i] : Float3(1, 1, 1));
			node.MeshIndex = (i < NodeMesh.Count) ? NodeMesh[i] : -1;
			outNodes.Add(node);
		}
	}
}
