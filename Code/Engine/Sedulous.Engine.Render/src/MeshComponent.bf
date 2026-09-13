using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// What to draw at an entity: a mesh, and the materials to draw it with.
///
/// A resource reference is a serialized Guid resolved through the manager's proxy handles, so
/// a hot reload swaps the product behind every holder at once. Code created meshes set the
/// object directly instead, and a direct object wins and is never serialized.
///
/// The material LIST is indexed by the submesh's material index, and slot zero doubles as the
/// whole mesh material: a single material mesh holds one entry, and a submesh whose index is
/// out of range, or whose slot has not resolved, falls back to slot zero.
///
/// The lists are BORROWED from the manager, which creates and frees them: a component is a
/// struct in a packed pool and cannot own heap data.
[SerializableComponent("mesh", 4)]
struct MeshComponent : ISerializable, IComponentResources
{
	public Ref<StaticMesh> Mesh = .(Guid());
	/// The serialized identities.
	public List<Ref<Material>> Materials = null;
	/// The raw view EXTRACTION refreshes from the proxies EVERY frame, so a late cook or a
	/// hot reload heals live. Snapshotting it once at resolve would pin a pre cook null until
	/// the page was reopened.
	public List<Material> MaterialCache = null;
	/// A per instance tint, multiplied into the shaded colour. Distinct per entity even when
	/// many share one mesh and material, so it rides the per instance path.
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	public bool Visible = true;

	/// Per bone skinning matrices, supplied per frame by whoever owns the pose. BORROWED and
	/// valid only for the frame it was set; null draws the bind pose.
	public Float4x4* BoneMatrices = null;
	/// Last frame's, for motion vectors. Null reuses the current ones.
	public Float4x4* PrevBoneMatrices = null;
	public uint32 BoneCount = 0;

	/// Above zero switches to a coarser level sooner, each unit halving the effective screen
	/// coverage; below zero holds detail longer.
	public float LodBias = 0.0f;
	/// Pins one level for a debug view or a cinematic. Minus one is automatic, and anything
	/// else is clamped to the chain.
	public int32 ForceLod = -1;

	public this() {}

	/// Slot zero, for runtime code that has the object rather than an id.
	public void SetMaterial(Material material) mut
	{
		Materials.Clear();
		var reference = Ref<Material>(Guid());
		reference.SetDirect(material);
		Materials.Add(reference);
	}

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

	/// Attaches every reference to the manager's proxies. The material CACHE is deliberately
	/// left alone: extraction refreshes it from the refs once a frame, so a late cook heals
	/// without a second resolve.
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

	/// The refs serialize their identities. The direct objects and the per frame skinning
	/// state never touch disk.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "mesh", ref Mesh.Id);

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

		ar.Key("color");
		Sedulous.Core.Serialization.Serialize(ar, ref Color);
		SerializeValue(ar, "visible", ref Visible);
		SerializeValue(ar, "lodBias", ref LodBias);
		SerializeValue(ar, "forceLod", ref ForceLod);
	}
}
