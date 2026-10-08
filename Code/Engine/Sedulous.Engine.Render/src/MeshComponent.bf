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
/// Data version 5 adds the fade; a version 4 record reads as solid.
[SerializableComponent("mesh", 5, 4)]
[DisplayName("Mesh")]
[Category("Rendering")]
[Scriptable]
struct MeshComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public Ref<StaticMesh> Mesh = .(Guid());
	/// The serialized identities.
	[Description("Material slots, indexed by the mesh's submesh material index. Slot 0 also covers single-material meshes and any submesh whose index has no slot.")]
	public List<Ref<Material>> Materials = null;
	/// The raw view EXTRACTION refreshes from the proxies EVERY frame, so a late cook or a
	/// hot reload heals live. Snapshotting it once at resolve would pin a pre cook null until
	/// the page was reopened.
	[Hidden]
	public List<Material> MaterialCache = null;
	/// A per instance tint, multiplied into the shaded colour. Distinct per entity even when
	/// many share one mesh and material, so it rides the per instance path.
	[Scriptable]
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	[Scriptable]
	public bool Visible = true;
	/// How far the mesh is faded out, nought (solid) to one (gone), drawn as a screen door
	/// dither: a cutaway wall between the camera and the player. Only its camera pixels thin
	/// out; it still casts its whole shadow, so the room behind a cut away wall stays as dark as
	/// it was. Hiding it by Visible would pop it and drop its shadow with it.
	[Scriptable]
	[Range(0.0f, 1.0f, 0.01f)]
	[Description("Fades the mesh out with a dither, 0 = solid, 1 = gone (a cutaway). Its shadow stays whole.")]
	public float Fade = 0.0f;

	/// Material properties set for this mesh alone (runtime, not saved): its material in a slot
	/// draws with an instance of its own carrying them (a glow, a tint, a flash), the shared
	/// material untouched. BORROWED from the manager like the material lists; each entry's
	/// name is the component's, freed when the entry goes.
	[Hidden]
	public List<MaterialPropertyOverride> MaterialOverrides = null;
	/// Changes with every set or clear, so the renderer applies them again.
	[Hidden]
	public uint32 MaterialOverrideVersion = 0;

	/// Per bone skinning matrices, supplied per frame by whoever owns the pose. BORROWED and
	/// valid only for the frame it was set; null draws the bind pose.
	public Float4x4* BoneMatrices = null;
	/// Last frame's, for motion vectors. Null reuses the current ones.
	public Float4x4* PrevBoneMatrices = null;
	[Hidden]
	public uint32 BoneCount = 0;

	/// Above zero switches to a coarser level sooner, each unit halving the effective screen
	/// coverage; below zero holds detail longer.
	[Scriptable]
	[DisplayName("LOD Bias")]
	[Description("Positive selects coarser LODs sooner (each unit halves the effective screen coverage); negative holds detail longer.")]
	public float LodBias = 0.0f;
	/// Pins one level for a debug view or a cinematic. Minus one is automatic, and anything
	/// else is clamped to the chain.
	[Scriptable]
	[DisplayName("Force LOD")]
	[Description("Pin one LOD level (0 = finest). -1 = automatic selection.")]
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

	/// Sets (or replaces) a property's value in `slot` for this mesh alone; `size` is 4 for a
	/// float, 16 for a Float4.
	public void SetMaterialProperty(uint32 slot, StringView name, Float4 value, uint32 size) mut
	{
		MaterialOverrideVersion++;
		for (var entry in ref MaterialOverrides)
		{
			if ((entry.Slot == slot) && (entry.Name == name))
			{
				entry.Value = value;
				entry.Size = size;
				return;
			}
		}

		var entry = MaterialPropertyOverride();
		entry.Slot = slot;
		entry.Size = size;
		entry.Value = value;
		entry.Name = new String(name);
		MaterialOverrides.Add(entry);
	}

	/// Puts a property back to the material's own value; false if it was not set.
	public bool ClearMaterialProperty(uint32 slot, StringView name) mut
	{
		for (int i < MaterialOverrides.Count)
		{
			let entry = MaterialOverrides[i];
			if ((entry.Slot == slot) && (entry.Name == name))
			{
				delete entry.Name;
				MaterialOverrides.RemoveAt(i);
				MaterialOverrideVersion++;
				return true;
			}
		}
		return false;
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
		if ((ar.Mode == .Write) || (ar.Version >= 5))
			SerializeValue(ar, "fade", ref Fade);
		SerializeValue(ar, "lodBias", ref LodBias);
		SerializeValue(ar, "forceLod", ref ForceLod);
	}
}
