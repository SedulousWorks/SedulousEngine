using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// ONE shared mesh and material drawn at N per instance transforms, which live on the GPU in
/// a buffer the renderer owns.
///
/// Its per frame CPU cost is constant in the instance count: the set extracts as one item,
/// culls as one merged bounds, and draws once per pass, with depth, forward and every shadow
/// cascade reading the same buffer. That is what makes it right for a static crowd or a
/// scatter, while the per entity mesh stays for genuinely dynamic objects.
///
/// The instance list is the source of truth, and every mutator bumps the version. The
/// renderer re uploads, and extraction recomputes the merged bounds, ONLY when that changes.
///
/// Every list here is BORROWED from the manager, which creates and frees them.
[SerializableComponent("instanced_mesh")]
struct InstancedMeshComponent : ISerializable, IComponentResources
{
	public Ref<StaticMesh> Mesh = .(Guid());
	public Ref<Material> Material = .(Guid());
	/// Optional per submesh materials, indexed by the submesh's material index. Non empty
	/// means each submesh draws with its own; otherwise the one above covers the whole mesh.
	/// Runtime only, because a per submesh material REF belongs to a prefab.
	public List<Material> SubmeshMaterials = null;
	/// ENTITY RELATIVE: instance i draws at Instances[i] times the entity's world matrix, so
	/// moving the entity moves the whole set.
	public List<Float4x4> Instances = null;
	/// The shared tint, used when the per instance list is empty.
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	/// Optional, parallel to the instances. Read at UPLOAD, so set it before the instances.
	public List<Color> Tints = null;
	public bool Visible = true;

	/// A shared pose pool for a skinned crowd, set per frame by the animation side: instance
	/// i uses pose i modulo the count, so N animated instances cost only PoseCount palette
	/// computes. BORROWED for the frame; null draws the set static.
	public Float4x4* PosePool = null;
	/// Last frame's palettes, for per bone motion vectors. Null reuses the current ones.
	public Float4x4* PrevPosePool = null;
	/// The number of distinct phase buckets.
	public uint32 PoseCount = 0;
	public uint32 BoneCount = 0;

	/// How an instance picks its pose. Hashed scatters each one to an unrelated pose, which
	/// is what an independent agent crowd wants. Explicit reads the indices below, for a
	/// layout the renderer cannot derive from a flat index: columns, clusters, gameplay.
	/// Explicit with a missing or mismatched list falls back to Hashed.
	///
	/// NOT a mutator: it is read each frame while filling the offsets rather than uploaded.
	public PoseAssignment PoseAssignment = .Hashed;
	public List<uint32> PoseIndices = null;

	/// Bumped by every mutator. Starts at one so the first extract, which has uploaded
	/// version zero, always uploads.
	public uint32 Version = 1;

	/// The composed world transforms, rebuilt by extraction when the authored set OR the
	/// entity's world matrix changed. ComposedVersion is what the renderer keys its upload
	/// on, so moving the entity re uploads like any other mutation. Runtime only.
	public List<Float4x4> WorldTransforms = null;
	public Float4x4 ComposedEntityWorld = Float4x4.Identity();
	/// The authored version the cache was built from. Zero means never.
	public uint32 ComposedFromVersion = 0;
	public uint32 ComposedVersion = 0;

	/// The merged world bounds, recomputed at extraction when they fall behind the composed
	/// version. This is what lets a static set skip the per frame bounds pass.
	public Float3 CachedCenter = .Zero;
	public float CachedRadius = 0.0f;
	public uint32 BoundsVersion = 0;

	public this() {}

	public uint32 Count => (uint32)Instances.Count;

	public void ResolveResources(ResourceManager manager) mut
	{
		Mesh.Bind(manager);
		Material.Bind(manager);
	}

	/// Replaces the whole set in one go, which is the fast path for static content: one
	/// version bump rather than one per instance.
	public void SetInstances(Span<Float4x4> transforms) mut
	{
		Instances.Clear();
		for (let transform in transforms)
			Instances.Add(transform);
		Version++;
	}

	public void Add(Float4x4 transform) mut
	{
		Instances.Add(transform);
		Version++;
	}

	public void SetInstance(uint32 index, Float4x4 transform) mut
	{
		if (index < (uint32)Instances.Count)
		{
			Instances[index] = transform;
			Version++;
		}
	}

	public void Reserve(uint32 count) mut => Instances.Reserve(count);

	public void Clear() mut
	{
		Instances.Clear();
		Version++;
	}

	/// The refs and the AUTHORED placement persist. The pose pool and every cache are runtime
	/// only, so a loaded set starts at version one with no bounds, and the first extract
	/// uploads and measures it.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "mesh", ref Mesh.Id);
		SerializeValue(ar, "material", ref Material.Id);

		ar.Key("instances");
		SerializeList(ar, Instances);

		ar.Key("color");
		Sedulous.Core.Serialization.Serialize(ar, ref Color);

		ar.Key("tints");
		SerializeList(ar, Tints);

		SerializeValue(ar, "visible", ref Visible);
	}
}
