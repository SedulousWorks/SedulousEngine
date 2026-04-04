namespace Sedulous.Engine.Render;

using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// Component for a renderable static mesh.
/// Holds a GPU mesh handle (from GPUResourceManager) and material.
class MeshComponent : Component
{
	/// GPU mesh handle. Resolved to vertex/index buffers at draw time.
	public GPUMeshHandle MeshHandle;

	/// Submesh index within the mesh.
	public uint32 SubMeshIndex;

	/// Material instance for this mesh.
	public MaterialInstance Material;

	/// Material bind group (set 2). Created from the material's textures/params.
	public Sedulous.RHI.IBindGroup MaterialBindGroup;

	/// Material sort key (hash for batching draws with same material).
	public uint32 MaterialSortKey;

	/// Local-space bounding box.
	public BoundingBox LocalBounds;

	/// Render layer mask (for filtering in extraction).
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether this mesh casts shadows.
	public bool CastsShadows = true;

	/// Whether this mesh is visible.
	public bool IsVisible = true;
}
