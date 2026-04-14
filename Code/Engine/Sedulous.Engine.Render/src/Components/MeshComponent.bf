namespace Sedulous.Engine.Render;

using System.Collections;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// Component for a renderable static mesh.
/// One component per mesh — supports multiple materials via per-submesh material slots.
///
/// The app sets ResourceRefs (mesh, materials). MeshComponentManager resolves them
/// to loaded resources, uploads to GPU, and creates MaterialInstances automatically.
class MeshComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("MeshRef", ref mMeshRef);
		s.Bool("CastsShadows", ref CastsShadows);
		s.Bool("IsVisible", ref IsVisible);
		var layerMask = (int32)LayerMask;
		s.Int32("LayerMask", ref layerMask);
		if (s.IsReading) LayerMask = (uint32)layerMask;

		// Material refs
		var matCount = (int32)mMaterialRefs.Count;
		s.BeginArray("Materials", ref matCount);
		if (s.IsReading)
		{
			for (int32 i = 0; i < matCount; i++)
			{
				var matRef = ResourceRef();
				s.ResourceRef("", ref matRef);
				while (mMaterialRefs.Count <= i) mMaterialRefs.Add(.());
				mMaterialRefs[i].Dispose();
				mMaterialRefs[i] = matRef;
			}
		}
		else
		{
			for (int32 i = 0; i < matCount; i++)
				s.ResourceRef("", ref mMaterialRefs[i]);
		}
		s.EndArray();
	}

	/// Mesh resource reference (serialized). Resolved to GPU handle by manager.
	private ResourceRef mMeshRef ~ _.Dispose();

	/// GPU mesh handle (runtime — set by manager after resource resolution).
	public GPUMeshHandle MeshHandle;

	/// Material resource references per slot (serialized).
	private List<ResourceRef> mMaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	/// Resolved material instances per slot (runtime — created by manager).
	public List<MaterialInstance> Materials = new .() ~ { for (let m in _) m?.ReleaseRef(); delete _; };

	/// Local-space bounding box.
	public BoundingBox LocalBounds;

	/// Render layer mask (for filtering in extraction).
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether this mesh casts shadows.
	public bool CastsShadows = true;

	/// Whether this mesh is visible.
	public bool IsVisible = true;

	/// Gets the mesh resource ref.
	public ResourceRef MeshRef => mMeshRef;

	/// Sets the mesh resource ref (deep copy — allocates new String for path).
	public void SetMeshRef(ResourceRef @ref)
	{
		mMeshRef.Dispose();
		mMeshRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Gets the material ref count.
	public int32 MaterialRefCount => (int32)mMaterialRefs.Count;

	/// Gets the material ref at a slot.
	public ResourceRef GetMaterialRef(int32 slot)
	{
		if (slot >= 0 && slot < mMaterialRefs.Count)
			return mMaterialRefs[slot];
		return .();
	}

	/// Sets a material resource ref at the given slot (deep copy).
	/// The MeshComponentManager resolves refs to instances during its update phase.
	public void SetMaterialRef(int32 slot, ResourceRef @ref)
	{
		while (mMaterialRefs.Count <= slot)
			mMaterialRefs.Add(.());
		mMaterialRefs[slot].Dispose();
		mMaterialRefs[slot] = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Gets the material for a given slot, or null if not assigned.
	public MaterialInstance GetMaterial(int32 slot)
	{
		if (slot >= 0 && slot < Materials.Count)
			return Materials[slot];
		return null;
	}

	/// Sets a material instance at the given slot, growing the list if needed.
	/// Takes ownership — AddRefs the new material, ReleaseRefs the old.
	public void SetMaterial(int32 slot, MaterialInstance material)
	{
		while (Materials.Count <= slot)
			Materials.Add(null);

		let old = Materials[slot];
		if (old == material) return;

		material?.AddRef();
		old?.ReleaseRef();
		Materials[slot] = material;
	}
}
