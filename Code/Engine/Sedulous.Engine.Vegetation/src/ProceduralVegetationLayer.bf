using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Vegetation;

namespace Sedulous.Engine.Vegetation;

/// A layer the scatter GROWS from a source: everywhere (Uniform), where a terrain splat
/// layer is painted (Splat), where a plane of the component's mask is painted (Mask), or
/// both (SplatTimesMask).
///
/// Nothing per instance is stored: the scatter is a pure function of the seed and the
/// source, so the layer describes the rule and the chunks are grown on demand.
[Reflect(.All)]
class ProceduralVegetationLayer : VegetationLayerBase
{
	/// Mask by DEFAULT: a new layer follows the plane you paint and grows nothing until the
	/// component has a mask with paint on that plane. Uniform would grow the moment a mesh
	/// was assigned, which reads as a scatter nobody asked for.
	[Description("Where it grows: everywhere (Uniform), where a terrain splat layer is painted (Splat), a painted mask plane (Mask, the default), or the two multiplied (SplatTimesMask).")]
	public VegetationPlacement Placement = .Mask;
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

	public this() {}

	/// The bridge to the pure scatter: the shared rules plus this layer's source.
	public ScatterLayer ToScatterLayer()
	{
		var layer = ScatterLayer();
		FillScatterLayer(ref layer);
		layer.Placement = Placement;
		layer.SplatLayer = SplatLayer;
		layer.SplatThreshold = SplatThreshold;
		layer.MaskPlane = MaskPlane;
		layer.Density = Density;
		return layer;
	}

	public override void Serialize(ISerializer ar)
	{
		SerializeBase(ar);
		ar.Key("placement");
		SerializeEnum(ar, ref Placement);
		SerializeValue(ar, "splatLayer", ref SplatLayer);
		SerializeValue(ar, "splatThreshold", ref SplatThreshold);
		SerializeValue(ar, "maskPlane", ref MaskPlane);
		SerializeValue(ar, "density", ref Density);
	}
}
