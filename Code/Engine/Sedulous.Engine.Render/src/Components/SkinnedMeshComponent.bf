namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;

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

	/// GPU mesh handle (runtime - set by manager after resource resolution).
	public GPUMeshHandle MeshHandle = .Invalid;

	/// GPU bone buffer handle (storage buffer for skinning matrices).
	public GPUBoneBufferHandle BoneBufferHandle = .Invalid;

	/// Material resource references per slot (serialized).
	private List<ResourceRef> mMaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	/// Resolved material instances per slot (runtime).
	public List<MaterialInstance> Materials = new .() ~ { for (let m in _) m?.ReleaseRef(); delete _; };

	/// Local-space bounding box.
	public BoundingBox LocalBounds;

	/// Whether this mesh is visible.
	public bool IsVisible = true;

	/// Whether this mesh casts shadows.
	public bool CastsShadows = true;

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
