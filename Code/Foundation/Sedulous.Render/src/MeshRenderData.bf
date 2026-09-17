using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;

namespace Sedulous.Render;

/// One mesh draw: a mesh and a material at a world transform.
///
/// Every pointer here is BORROWED for the frame; the producer keeps the resources alive.
class MeshRenderData : RenderData
{
	/// Subclasses inherit the stamp, which is what makes a MultiMeshRenderData answer Mesh too.
	public this()
	{
		Kind = .Mesh;
	}

	public Float4x4 World = .Identity();
	/// A per instance tint.
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);

	public StaticMesh Mesh = null;
	public Material Material = null;

	/// Optional per submesh materials, indexed by each submesh's material index. When they
	/// are here each submesh draws with its own; otherwise the one material covers the mesh.
	public Material* SubmeshMaterials = null;
	public uint32 SubmeshMaterialCount = 0;

	/// An opaque tag the producer may set, a packed entity handle say, for picking. It means
	/// nothing to the renderer.
	public uint64 EntityId = 0;

	/// GPU skinning: the per bone matrices, borrowed for the frame from an animation player.
	/// With these and a skinned mesh the renderer uploads them and draws the skinned
	/// permutation; without them the mesh draws in its bind pose.
	public Float4x4* BoneMatrices = null;
	/// Last frame's, for motion vectors. Null reuses the current ones, which is a pose that
	/// did not move.
	public Float4x4* PreviousBoneMatrices = null;
	public uint32 BoneCount = 0;

	/// The level of detail knobs, copied from the component at extraction. The SELECTION is
	/// per view, since extraction is one snapshot shared by every view.
	public float LodBias = 0.0f;
	/// Minus one is automatic.
	public int32 ForceLod = -1;

	/// True when this is really an instanced SET. The resolve loop sees mesh data and
	/// branches on this rather than asking what type it is.
	public bool MultiMesh = false;
}
