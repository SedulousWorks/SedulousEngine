using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Vegetation;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Engine.Vegetation;

/// One authored vegetation layer.
///
/// The scatter parameters mirror Sedulous.Vegetation's ScatterLayer FLAT, the inspector
/// editing leaf fields; ToScatterLayer is the bridge to the pure scatter.
[Reflect(.All)]
class VegetationLayer : ISerializable
{
	/// The inspector's slot label.
	public String Name = new .("Layer") ~ delete _;
	/// The instanced mesh: a grass card, a tuft, a rock.
	[Description("The instanced mesh: a grass card, a tuft, a rock.")]
	public Ref<StaticMesh> Mesh = .(Guid());
	/// An optional override; none uses the mesh's own.
	[Description("Optional override; none uses the mesh's own.")]
	public Ref<Material> Material = .(Guid());

	[Description("Where it grows: everywhere (Uniform), where a terrain splat layer is painted (Splat), a painted mask (Mask), or authored instances (Scattered).")]
	public VegetationPlacement Placement = .Splat;
	[DisplayName("Splat Layer")]
	[Description("Splat placement: the terrain palette index to follow.")]
	public uint32 SplatLayer = 0;
	[DisplayName("Splat Threshold")]
	[Description("Splat placement: the painted share, nought to one, below which nothing grows.")]
	public float SplatThreshold = 0.25f;
	[DisplayName("Mask Plane")]
	[Description("Mask placement: the plane of the component's mask this layer follows; the Paint Vegetation brush paints it.")]
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
	public ScatterLayer ToScatterLayer()
	{
		var layer = ScatterLayer();
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

	public void ResolveResources(ResourceManager manager)
	{
		Mesh.Bind(manager);
		Material.Bind(manager);
	}

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
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

/// The vegetation over one terrain: its layers, on the terrain component's entity, or on a
/// child of it since the manager walks the ancestry.
[SerializableComponent("terrainVegetation")]
[DisplayName("Terrain Vegetation")]
[Category("Terrain")]
struct TerrainVegetationComponent : ISerializable, IComponentResources
{
	/// OWNED, but created and freed by the manager: a struct component cannot carry a field
	/// destructor.
	public List<VegetationLayer> Layers = null;
	/// The painted mask, density planes over the footprint; none means no Mask placement
	/// grows. A layer with Mask or SplatTimesMask placement names its plane.
	[Description("The painted vegetation mask, one density plane per layer that uses Mask placement; the Paint Vegetation brush paints it.")]
	public Ref<VegetationMask> Mask = .(Guid());
	public bool Visible = true;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Mask.Bind(manager);
		for (let layer in Layers)
			layer.ResolveResources(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "mask", ref Mask.Id);
		ar.Key("layers");
		SerializeList(ar, Layers);
		SerializeValue(ar, "visible", ref Visible);
	}
}
