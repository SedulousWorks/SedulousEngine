namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Inspection;

/// Component for a renderable skinned mesh.
/// Rendering only - does not own animation. Bone matrices come from a
/// SkeletalAnimationComponent (or AnimationGraphComponent) on the same entity.
/// The manager reads matrices from the animation component and uploads to GPU.
[Component]
class SkinnedMeshComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("MeshRef", ref mMeshRef);
		s.Bool("CastsShadows", ref CastsShadows);
		s.Bool("IsVisible", ref IsVisible);
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
	[ResourceRefType(".skinnedmesh")]
	private ResourceRef mMeshRef ~ _.Dispose();

	/// GPU mesh handle (runtime - set by manager after resource resolution).
	public GPUMeshHandle MeshHandle = .Invalid;

	/// GPU bone buffer handle (storage buffer for skinning matrices).
	public GPUBoneBufferHandle BoneBufferHandle = .Invalid;

	/// Material resource references per slot (serialized).
	[Property(.Default, "Material Refs", "MaterialRefs")]
	[ResourceRefType(".material")]
	private List<ResourceRef> mMaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	/// Resolved material instances per slot (runtime).
	public List<MaterialInstance> Materials = new .() ~ { for (let m in _) m?.ReleaseRef(); delete _; };

	/// Local-space bounding box. Captured from the resource at the rest
	/// pose - animated poses (windups, stretches) may extend outside.
	/// Conservative-loose by design for culling.
	public BoundingBox LocalBounds;

	/// World-space bounding box, refreshed in PostTransform when the entity
	/// moves or LocalBounds changes. AABB of the rest-pose mesh transformed
	/// by the entity's world matrix - same conservative-loose tradeoff as
	/// LocalBounds for animated meshes.
	public BoundingBox WorldBounds;

	/// Set when LocalBounds is written (mesh ref swap, mesh resolution).
	/// Forces a WorldBounds refresh next PostTransform even if the entity
	/// itself didn't move. Cleared during the refresh.
	public bool BoundsDirty;

	/// Whether this mesh is visible.
	public bool IsVisible = true;

	/// Whether this mesh casts shadows.
	public bool CastsShadows = true;

	/// Per-instance color tint applied on top of the material's albedo
	/// (mirror of MeshComponent.Color). Default (1,1,1,1) is a no-op;
	/// gameplay code drives damage flashes / team colors / status overlays
	/// without cloning materials per entity.
	[Property(.Color, "Color", "Color")]
	public Vector4 Color = .(1, 1, 1, 1);

	/// Gets the mesh resource ref.
	public ResourceRef MeshRef => mMeshRef;

	/// Sets the mesh resource ref (deep copy).
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
