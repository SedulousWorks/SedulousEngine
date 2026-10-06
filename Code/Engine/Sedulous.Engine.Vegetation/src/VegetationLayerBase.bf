using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Vegetation;

namespace Sedulous.Engine.Vegetation;

/// What EVERY layer has, grown or placed: the mesh, how an instance stands, how it fades,
/// what it costs.
///
/// Mirrors Sedulous.Vegetation's ScatterLayer FLAT, the inspector editing leaf fields;
/// FillScatterLayer is the bridge to the pure scatter's per instance rules.
[Reflect(.All)]
class VegetationLayerBase : ISerializable
{
	/// The inspector's slot label.
	public String Name = new .("Layer") ~ delete _;
	/// The instanced mesh: a grass card, a tuft, a rock.
	[Description("The instanced mesh: a grass card, a tuft, a rock.")]
	public Ref<StaticMesh> Mesh = .(Guid());
	/// One material per mesh slot, as a mesh component's: a pine's bark, needles and snow each
	/// their own. None draws the default material: a layer has no "the mesh's own" to fall
	/// back to.
	[Description("One material per mesh slot, as on a mesh component; none draws the default material.")]
	public List<Ref<Material>> Materials = new .() ~ delete _;
	[DisplayName("Scale Range")]
	public Float2 ScaleRange = .(0.8f, 1.2f);
	[DisplayName("Max Slope")]
	[Description("Degrees from flat above which nothing grows.")]
	public float MaxSlopeDegrees = 35.0f;
	[DisplayName("Height Range")]
	[Description("The terrain local Y window the layer grows in.")]
	public Float2 HeightRange = .(-1.0e6f, 1.0e6f);
	[DisplayName("Align To Normal")]
	public bool AlignToNormal = false;
	[DisplayName("Fade Start")]
	[Description("Metres from the camera: full density inside.")]
	public float FadeStart = 40.0f;
	[DisplayName("Fade End")]
	[Description("Metres from the camera: nothing beyond.")]
	public float FadeEnd = 80.0f;
	[DisplayName("Cast Shadows")]
	[Description("Off for grass, the single most expensive thing a grass layer can do; on for rocks and props.")]
	public bool CastShadows = false;
	[DisplayName("Max Per Chunk")]
	[Description("What one chunk may hold; placing stops there rather than the density scaling down.")]
	public uint32 MaxInstancesPerChunk = 4096;
	public bool Visible = true;
	// What of an instance is solid (vegetation colliders): an upright trunk this radius round and
	// this tall from its foot, both scaled with the instance, in this physics collision group.
	// Radius 0 is scenery only (the default). The view toggles (Visible, the component's) do not
	// change it.
	[DisplayName("Collision Radius")]
	[Description("A solid trunk this radius round (metres, scaled with each instance); 0 is scenery only.")]
	public float CollisionRadius = 0.0f;
	[DisplayName("Collision Height")]
	[Description("The trunk's height from its foot to its top (metres, scaled with each instance).")]
	public float CollisionHeight = 0.0f;
	[DisplayName("Collision Group")]
	[Description("The physics collision group of the trunks (0 to 31): the scene's group matrix decides what they stop, and a query finds them by it.")]
	public uint8 CollisionGroup = 0;

	public this() {}

	/// The rules every layer shares, written into a scatter layer the caller then completes.
	public void FillScatterLayer(ref ScatterLayer layer)
	{
		layer.ScaleRange = ScaleRange;
		layer.MaxSlopeDegrees = MaxSlopeDegrees;
		layer.HeightRange = HeightRange;
		layer.AlignToNormal = AlignToNormal;
		layer.FadeStart = FadeStart;
		layer.FadeEnd = FadeEnd;
		layer.CastShadows = CastShadows;
		layer.MaxInstancesPerChunk = MaxInstancesPerChunk;
	}

	public void ResolveResources(ResourceManager manager)
	{
		Mesh.Bind(manager);
		for (int i < Materials.Count)
		{
			var reference = Materials[i];
			reference.Bind(manager);
			Materials[i] = reference;
		}
	}

	/// The shared prefix of both layer kinds' payloads, so the two stay in step.
	public void SerializeBase(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		SerializeValue(ar, "mesh", ref Mesh.Id);
		// Version 2 carried one optional material. Tested as EXACTLY 2, not as below 3: a
		// payload with no version scope reads as nought and is the current layout.
		if ((ar.Mode == .Read) && (ar.Version == 2))
			ReadSingleMaterial(ar, Materials);
		else
			SerializeMaterials(ar);
		ar.Key("scaleRange");
		Sedulous.Core.Serialization.Serialize(ar, ref ScaleRange);
		SerializeValue(ar, "maxSlopeDegrees", ref MaxSlopeDegrees);
		ar.Key("heightRange");
		Sedulous.Core.Serialization.Serialize(ar, ref HeightRange);
		SerializeValue(ar, "alignToNormal", ref AlignToNormal);
		SerializeValue(ar, "fadeStart", ref FadeStart);
		SerializeValue(ar, "fadeEnd", ref FadeEnd);
		SerializeValue(ar, "castShadows", ref CastShadows);
		SerializeValue(ar, "maxInstancesPerChunk", ref MaxInstancesPerChunk);
		SerializeValue(ar, "visible", ref Visible);
		// Data version 4 added the collision. Version 0 is no version scope (a bare round
		// trip), which this type never stores, its versions starting at 1: the current layout.
		if ((ar.Mode == .Write) || (ar.Version == 0) || (ar.Version >= 4))
		{
			SerializeValue(ar, "collisionRadius", ref CollisionRadius);
			SerializeValue(ar, "collisionHeight", ref CollisionHeight);
			SerializeValue(ar, "collisionGroup", ref CollisionGroup);
		}
	}

	public virtual void Serialize(ISerializer ar) => SerializeBase(ar);

	/// The material list, one id per slot.
	private void SerializeMaterials(ISerializer ar)
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

	/// The single "material" of versions 1 and 2, as the list's one entry; nil, as no entry.
	public static void ReadSingleMaterial(ISerializer ar, List<Ref<Material>> outMaterials)
	{
		var id = Guid();
		SerializeValue(ar, "material", ref id);
		outMaterials.Clear();
		if (id != Guid())
			outMaterials.Add(.(id));
	}
}
