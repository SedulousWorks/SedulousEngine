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
///
/// Data version 2 records the per mesh material slots. There is ONE supported layout, so a
/// manifest written before it is refused rather than guessed at: the remedy is a re-import,
/// which rewrites the manifest beside freshly cooked meshes.
[Serializable(2)]
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
	/// The material slots every mesh uses, concatenated; MeshSlotStart and MeshSlotCount cut
	/// it up per mesh. Each entry is an index into MaterialGuid, and a cooked submesh's
	/// material index is a POSITION in its mesh's run rather than an index into MaterialGuid
	/// directly. A mesh with no parts, a held LOD slot among them, has a count of nought.
	public List<int32> MeshMaterialSlot = new .() ~ delete _;
	/// Parallel to MeshGuid.
	public List<int32> MeshSlotStart = new .() ~ delete _;
	public List<int32> MeshSlotCount = new .() ~ delete _;

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

	/// Appends one mesh's material slots, keeping the three arrays in step. Called once per
	/// mesh, in the same order the mesh ids are added.
	public void AddMeshMaterialSlots(Span<int32> slots)
	{
		MeshSlotStart.Add((int32)MeshMaterialSlot.Count);
		MeshSlotCount.Add((int32)slots.Length);
		for (let slot in slots)
			MeshMaterialSlot.Add(slot);
	}

	/// One mesh's material slots, empty when it has none or the manifest records none.
	public Span<int32> MaterialSlotsOf(int meshIndex)
	{
		if ((meshIndex < 0) || (meshIndex >= MeshSlotStart.Count) || (meshIndex >= MeshSlotCount.Count))
			return .();
		let start = MeshSlotStart[meshIndex];
		let count = MeshSlotCount[meshIndex];
		if ((start < 0) || (count <= 0) || (start + count > MeshMaterialSlot.Count))
			return .();
		return .(&MeshMaterialSlot[start], count);
	}

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
