using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;

namespace Sedulous.Model.Resource;

/// The runtime model: the hierarchy, and everything it was assembled from, resolved.
///
/// Every leaf is held as a PROXY rather than a pointer, because the manager owns them and a
/// reload has to reach the model without it noticing: a proxy answers whatever is bound to
/// its id now. The dependency edges the bind recorded are what keep them all alive.
class ModelResource
{
	public List<ModelNode> Nodes = new .() ~ DeleteContainerAndItems!(_);

	/// The meshes, in manifest order. Held as the base type: a skinned mesh sits here too,
	/// and the renderer asks whether it is skinned rather than being told twice.
	public List<Proxy<StaticMesh>> Meshes = new .() ~ delete _;
	public List<bool> MeshSkinned = new .() ~ delete _;
	/// The material index per mesh, minus one for none.
	public List<int32> MeshMaterial = new .() ~ delete _;

	public List<Proxy<Material>> Materials = new .() ~ delete _;

	/// Null when the model has no skin.
	public Proxy<Skeleton> Skeleton = .(null);
	public List<Proxy<AnimationClip>> Animations = new .() ~ delete _;

	public Float3 BoundsMin = .(0, 0, 0);
	public Float3 BoundsMax = .(0, 0, 0);

	/// The mesh at an index, or null when the index names nothing or nothing is bound there.
	public StaticMesh Mesh(int index) =>
		((index >= 0) && (index < Meshes.Count)) ? Meshes[index].Get : null;

	/// The material a mesh draws with, or null when it has none.
	public Material MaterialForMesh(int meshIndex)
	{
		if ((meshIndex < 0) || (meshIndex >= MeshMaterial.Count))
			return null;
		let index = MeshMaterial[meshIndex];
		return ((index >= 0) && (index < Materials.Count)) ? Materials[index].Get : null;
	}
}
