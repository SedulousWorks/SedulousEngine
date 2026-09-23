using System;
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
	/// An optional override; none uses the mesh's own.
	[Description("Optional override; none uses the mesh's own.")]
	public Ref<Material> Material = .(Guid());
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
		Material.Bind(manager);
	}

	/// The shared prefix of both layer kinds' payloads, so the two stay in step.
	public void SerializeBase(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		SerializeValue(ar, "mesh", ref Mesh.Id);
		SerializeValue(ar, "material", ref Material.Id);
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
	}

	public virtual void Serialize(ISerializer ar) => SerializeBase(ar);
}
