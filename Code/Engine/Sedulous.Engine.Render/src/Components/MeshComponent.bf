namespace Sedulous.Engine.Render;

using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Component for a renderable static mesh.
/// One component per mesh - supports multiple materials via per-submesh material slots.
///
/// The app sets ResourceRefs (mesh, materials). MeshComponentManager resolves them
/// to loaded resources, uploads to GPU, and creates MaterialInstances automatically.
[Component]
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

		// Per-instance color tint. Component default is white; round-trip
		// is unconditional so authored values persist across saves.
		s.BeginObject("Color");
		s.Float("X", ref Color.X);
		s.Float("Y", ref Color.Y);
		s.Float("Z", ref Color.Z);
		s.Float("W", ref Color.W);
		s.EndObject();

		// Material refs
		var matCount = (int32)mMaterialRefs.Count;
		s.BeginArray("MaterialRefs", ref matCount);
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
	[Property(.Default, "Mesh Ref", "MeshRef")]
	[ResourceRefType(".mesh")]
	private ResourceRef mMeshRef ~ _.Dispose();

	/// GPU mesh handle (runtime - set by manager after resource resolution).
	public GPUMeshHandle MeshHandle = .Invalid;

	/// Material resource references per slot (serialized).
	[Property(.Default, "Material Refs", "MaterialRefs")]
	[ResourceRefType(".material")]
	private List<ResourceRef> mMaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	/// Resolved material instances per slot (runtime - created by manager).
	public List<MaterialInstance> Materials = new .() ~ { for (let m in _) m?.ReleaseRef(); delete _; };

	/// Local-space bounding box.
	public BoundingBox LocalBounds;

	/// World-space bounding box, refreshed in PostTransform when the entity
	/// moves or LocalBounds changes. Read at extraction time and by future
	/// frustum-culling consumers - never recompute on demand.
	public BoundingBox WorldBounds;

	/// Set when LocalBounds is written (mesh ref swap, mesh resolution).
	/// Forces a WorldBounds refresh next PostTransform even if the entity
	/// itself didn't move. Cleared during the refresh.
	public bool BoundsDirty;

	/// Render layer mask (for filtering in extraction).
	[Property(.Default, "Layer Mask", "LayerMask")]
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether this mesh casts shadows.
	[Property(.Default, "Casts Shadows", "CastsShadows")]
	public bool CastsShadows = true;

	/// Whether this mesh is visible.
	[Property(.Default, "Is Visible", "IsVisible")]
	public bool IsVisible = true;

	/// Per-instance color tint applied on top of the material's albedo.
	/// Multiplied with vertex color + albedo texture in the forward
	/// shader, so default (1,1,1,1) is a no-op. Use for damage flash,
	/// team colors, status-effect overlays, etc. without cloning the
	/// material per entity.
	[Property(.Color, "Color", "Color")]
	public Vector4 Color = .(1, 1, 1, 1);

	/// Gets the mesh resource ref.
	public ResourceRef MeshRef => mMeshRef;

	/// Sets the mesh resource ref (deep copy - allocates new String for path).
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
	/// Takes ownership - AddRefs the new material, ReleaseRefs the old.
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
