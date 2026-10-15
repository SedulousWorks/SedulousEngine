using System;
using Sedulous.Scene;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Resource;

namespace Sedulous.Engine.Render;

/// ONE shared mesh and its materials drawn at N per instance transforms, which live on the GPU
/// in a buffer the renderer owns.
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
///
/// Data version 2 adds the materials list (version 1 saved one material, read as slot 0) and
/// the pose policy, indices and clips.
[SerializableComponent("instanced_mesh", 2, 1)]
[DisplayName("Instanced Mesh")]
[Category("Rendering")]
[Scriptable]
[Description("Draws one mesh with its materials at many instance transforms in a single draw, for scatter and crowds.")]
struct InstancedMeshComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public Ref<StaticMesh> Mesh = .(Guid());
	/// The material list, indexed by the submesh's material index, as a mesh's: slot 0 doubles
	/// as the whole mesh's material, so a single material mesh holds one entry and a mesh of
	/// several parts (a guest's body, gown and mask) one per slot.
	[Description("Material slots, indexed by the mesh's submesh material index. Slot 0 also covers single-material meshes and any submesh whose index has no slot.")]
	public List<Ref<Material>> Materials = null;
	/// The raw view EXTRACTION refreshes from the refs every frame, so a late cook or a hot
	/// reload heals live.
	[Hidden]
	public List<Material> MaterialCache = null;
	/// ENTITY RELATIVE: instance i draws at Instances[i] times the entity's world matrix, so
	/// moving the entity moves the whole set.
	public List<Float4x4> Instances = null;
	/// The shared tint, used when the per instance list is empty.
	[Scriptable]
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	/// Optional, parallel to the instances. Read at UPLOAD, so set it before the instances.
	public List<Color> Tints = null;
	[Scriptable]
	public bool Visible = true;

	/// A shared pose pool for a skinned crowd, set per frame by the animation side: instance
	/// i uses pose i modulo the count, so N animated instances cost only PoseCount palette
	/// computes. BORROWED for the frame; null draws the set static.
	public Float4x4* PosePool = null;
	/// Last frame's palettes, for per bone motion vectors. Null reuses the current ones.
	public Float4x4* PrevPosePool = null;
	/// The number of distinct phase buckets.
	[Hidden]
	public uint32 PoseCount = 0;
	[Hidden]
	public uint32 BoneCount = 0;

	/// How an animated instance picks its phase. Hashed scatters each one to an unrelated
	/// pose, which is what an independent agent crowd wants; Sequential goes by its order;
	/// Explicit reads the indices below, for a layout the renderer cannot derive from a flat
	/// index (columns, clusters, gameplay), and falls back to Hashed with a missing or
	/// mismatched list; Unison puts every instance on a clip in step.
	///
	/// NOT a mutator: it is read each frame while filling the offsets rather than uploaded.
	[Scriptable, Description("How an animated instance picks its phase: Hashed (scattered), Sequential (by its order), Explicit (its pose index), Unison (all in step)")]
	public PoseAssignment PoseAssignment = .Hashed;
	[Hidden]
	public List<uint32> PoseIndices = null;
	/// A clip per instance, parallel to the instances, when the pose pool holds several clips
	/// (an instanced skinning with a clip list): the clip picks its block of poses, the policy
	/// the phase in it. Empty or mismatched puts every instance on clip nought. Read each
	/// frame, like the pose indices: not a mutator.
	[Hidden]
	public List<uint32> InstanceClips = null;
	/// Palettes per clip in the pose pool, set with the pool. Runtime only.
	[Hidden]
	public uint32 PosesPerClip = 0;

	/// Its instance members this frame (their world transforms and clips), gathered by
	/// extraction and drawn after the authored instances; never saved. The draw lists are the
	/// authored and member lists together, when there are members. Runtime only.
	[Hidden]
	public List<Float4x4> MemberWorld = null;
	[Hidden]
	public List<uint32> MemberClips = null;
	/// Their own tints, linear, beside the clips.
	[Hidden]
	public List<Color> MemberTints = null;
	[Hidden]
	public List<Float4x4> DrawTransforms = null;
	[Hidden]
	public List<uint32> DrawClips = null;
	[Hidden]
	public List<Color> DrawTints = null;

	/// Bumped by every mutator. Starts at one so the first extract, which has uploaded
	/// version zero, always uploads.
	[Hidden]
	public uint32 Version = 1;

	/// The composed world transforms, rebuilt by extraction when the authored set OR the
	/// entity's world matrix changed. ComposedVersion is what the renderer keys its upload
	/// on, so moving the entity re uploads like any other mutation. Runtime only.
	[Hidden]
	public List<Float4x4> WorldTransforms = null;
	/// Tints decoded to linear for the renderer (authored colours are sRGB), rebuilt with
	/// WorldTransforms since the renderer reads tints at the same upload. Runtime only.
	[Hidden]
	public List<Color> LinearTints = null;
	public Float4x4 ComposedEntityWorld = Float4x4.Identity();
	/// The authored version the cache was built from. Zero means never.
	[Hidden]
	public uint32 ComposedFromVersion = 0;
	[Hidden]
	public uint32 ComposedVersion = 0;

	/// The merged world bounds, recomputed at extraction when they fall behind the composed
	/// version. This is what lets a static set skip the per frame bounds pass.
	[Hidden]
	public Float3 CachedCenter = .Zero;
	[Hidden]
	public float CachedRadius = 0.0f;
	[Hidden]
	public uint32 BoundsVersion = 0;

	public this() {}

	public uint32 Count => (uint32)Instances.Count;

	public void ResolveResources(ResourceManager manager) mut
	{
		Mesh.Bind(manager);
		for (int i < Materials.Count)
		{
			var reference = Materials[i];
			reference.Bind(manager);
			Materials[i] = reference;
		}
	}

	/// One material for the whole mesh, for runtime code that has the object rather than an id.
	public void SetMaterial(Material material) mut
	{
		Materials.Clear();
		var reference = Ref<Material>(Guid());
		reference.SetDirect(material);
		Materials.Add(reference);
	}

	/// A material per submesh slot, in slot order.
	public void SetMaterials(Span<Material> list) mut
	{
		Materials.Clear();
		for (let material in list)
		{
			var reference = Ref<Material>(Guid());
			reference.SetDirect(material);
			Materials.Add(reference);
		}
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
			Instances[(int)index] = transform;
			Version++;
		}
	}

	public void Reserve(uint32 count) mut => Instances.Reserve((int)count);

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
		// Version 1 saved one material, which is slot 0.
		if ((ar.Mode == .Read) && (ar.Version == 1))
		{
			var reference = Ref<Material>(Guid());
			SerializeValue(ar, "material", ref reference.Id);
			Materials.Clear();
			Materials.Add(reference);
		}
		else
		{
			ar.Key("materials");
			uint32 count = (uint32)Materials.Count;
			ar.BeginArray(ref count);
			if (ar.Mode == .Read)
			{
				Materials.Clear();
				Materials.Reserve((int)count);
				for (uint32 i < count)
				{
					var reference = Ref<Material>(Guid());
					SerializeValue(ar, ref reference.Id);
					Materials.Add(reference);
				}
			}
			else
			{
				for (int i < Materials.Count)
				{
					var id = Materials[i].Id;
					SerializeValue(ar, ref id);
				}
			}
			ar.EndArray();
		}

		ar.Key("instances");
		SerializeList(ar, Instances);

		ar.Key("color");
		Sedulous.Core.Serialization.Serialize(ar, ref Color);

		ar.Key("tints");
		SerializeList(ar, Tints);

		SerializeValue(ar, "visible", ref Visible);

		// Version 1 had no pose policy: an animated set hashed its phases, as a fresh one does.
		if ((ar.Mode == .Read) && (ar.Version == 1))
			return;
		var policy = (uint8)PoseAssignment;
		SerializeValue(ar, "poseAssignment", ref policy);
		PoseAssignment = (PoseAssignment)policy;
		ar.Key("poseIndices");
		SerializeList(ar, PoseIndices);
		ar.Key("instanceClips");
		SerializeList(ar, InstanceClips);
	}
}
