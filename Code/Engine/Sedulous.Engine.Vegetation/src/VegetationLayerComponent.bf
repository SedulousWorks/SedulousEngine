using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Vegetation;

namespace Sedulous.Engine.Vegetation;

/// One vegetation layer on an entity.
///
/// ONE LAYER PER COMPONENT: a grass layer, a rock layer and a flower layer are three entities
/// under, or on, the terrain entity, each with one of these. The manager finds the terrain by
/// walking the entity's ancestry for a TerrainComponent, so the entity's name IS the layer's
/// name, its active flag toggles the layer, the hierarchy orders it, and a prefab can carry it.
///
/// The scatter parameters mirror Sedulous.Vegetation's VegetationLayer FLAT, the inspector
/// editing leaf fields rather than nested structs; ToLayer is the bridge to the pure scatter.
[SerializableComponent("vegetationLayer")]
[DisplayName("Vegetation Layer")]
[Category("Terrain")]
struct VegetationLayerComponent : ISerializable, IComponentResources
{
	/// The instanced mesh: a grass card, a tuft, a rock.
	[Description("The instanced mesh: a grass card, a tuft, a rock.")]
	public Ref<StaticMesh> Mesh = .(Guid());
	/// An optional override; none uses the mesh's own.
	[Description("Optional override; none uses the mesh's own.")]
	public Ref<Material> Material = .(Guid());

	[Description("Where it grows: everywhere (Uniform), where a terrain splat layer is painted (Splat), a painted mask (Mask), or authored instances (Scattered).")]
	public VegetationPlacement Placement = .Splat;
	/// Splat placement: the terrain palette index to follow.
	[DisplayName("Splat Layer")]
	[Description("Splat placement: the terrain palette index to follow.")]
	public uint32 SplatLayer = 0;
	[DisplayName("Splat Threshold")]
	[Description("Splat placement: the painted share, nought to one, below which nothing grows.")]
	public float SplatThreshold = 0.25f;
	[DisplayName("Mask Plane")]
	public uint32 MaskPlane = 0;
	[Description("Instances per square metre.")]
	public float Density = 2.0f;
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
	[Description("The memory bound per chunk set; the density scales down to fit.")]
	public uint32 MaxInstancesPerChunk = 4096;
	public bool Visible = true;

	public this() {}

	/// The bridge to the pure scatter.
	public VegetationLayer ToLayer()
	{
		var layer = VegetationLayer();
		layer.Placement = Placement;
		layer.SplatLayer = SplatLayer;
		layer.SplatThreshold = SplatThreshold;
		layer.MaskPlane = MaskPlane;
		layer.Density = Density;
		layer.ScaleRange = ScaleRange;
		layer.MaxSlopeDegrees = MaxSlopeDegrees;
		layer.HeightRange = HeightRange;
		layer.AlignToNormal = AlignToNormal;
		layer.FadeStart = FadeStart;
		layer.FadeEnd = FadeEnd;
		layer.CastShadows = CastShadows;
		layer.MaxInstancesPerChunk = MaxInstancesPerChunk;
		return layer;
	}

	public void ResolveResources(ResourceManager manager) mut
	{
		Mesh.Bind(manager);
		Material.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "mesh", ref Mesh.Id);
		SerializeValue(ar, "material", ref Material.Id);
		ar.Key("placement");
		SerializeEnum(ar, ref Placement);
		SerializeValue(ar, "splatLayer", ref SplatLayer);
		SerializeValue(ar, "splatThreshold", ref SplatThreshold);
		SerializeValue(ar, "maskPlane", ref MaskPlane);
		SerializeValue(ar, "density", ref Density);
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
}
