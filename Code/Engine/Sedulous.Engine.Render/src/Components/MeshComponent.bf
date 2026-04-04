namespace Sedulous.Engine.Render;

using System.Collections;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// Component for a renderable static mesh.
/// One component per mesh — supports multiple materials via per-submesh material slots.
class MeshComponent : Component
{
	/// GPU mesh handle. Resolved to vertex/index buffers at draw time.
	public GPUMeshHandle MeshHandle;

	/// Material resource references per slot (serialized — persists in scene files).
	public List<ResourceRef> MaterialRefs = new .() ~ delete _;

	/// Resolved material instances per slot (runtime — created from MaterialRefs).
	public List<MaterialInstance> Materials = new .() ~ delete _;

	/// Local-space bounding box.
	public BoundingBox LocalBounds;

	/// Render layer mask (for filtering in extraction).
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether this mesh casts shadows.
	public bool CastsShadows = true;

	/// Whether this mesh is visible.
	public bool IsVisible = true;

	/// Gets the material for a given slot, or null if not assigned.
	public MaterialInstance GetMaterial(int32 slot)
	{
		if (slot >= 0 && slot < Materials.Count)
			return Materials[slot];
		return null;
	}

	/// Sets a material instance at the given slot, growing the list if needed.
	public void SetMaterial(int32 slot, MaterialInstance material)
	{
		while (Materials.Count <= slot)
			Materials.Add(null);
		Materials[slot] = material;
	}

	/// Sets a material resource ref at the given slot, growing the list if needed.
	/// The MeshComponentManager resolves refs to instances during its update phase.
	public void SetMaterialRef(int32 slot, ResourceRef @ref)
	{
		while (MaterialRefs.Count <= slot)
			MaterialRefs.Add(.());
		MaterialRefs[slot] = @ref;
	}
}
