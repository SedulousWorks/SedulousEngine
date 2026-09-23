using System;
using Sedulous.Core;

namespace Sedulous.Vegetation;

/// The placement source: what decides whether a candidate point grows.
enum VegetationPlacement : uint8
{
	/// Everywhere on the terrain; the slope and height rules still apply.
	case Uniform;
	/// Where the terrain's painted splat layer clears the threshold.
	case Splat;
	/// Where the painted vegetation mask plane has density.
	case Mask;
	// Three WAS Scattered, authored instances, until the props moved to their own list on
	// the component: a prop layer is a kind of layer now rather than a placement. The
	// enumerator is RETIRED rather than reused, so every value already written still means
	// what it did.
	/// The splat share TIMES the mask density, so a mask carves a painted layer.
	case SplatTimesMask = 4;
}

/// The parameters of one vegetation layer: WHERE it grows, the placement source, HOW DENSE,
/// and the per instance rules, scale, slope, height and alignment, plus the distance fade.
///
/// Plain data, hashed for cache invalidation. The scene component mirrors these fields flat,
/// the reflected inspector editing leaf fields rather than nested structs.
struct ScatterLayer
{
	/// The base, unpainted terrain layer as a SplatLayer value: grows where NO palette layer
	/// is painted, which is the implicit base weight.
	public const uint32 cSplatBaseLayer = 0xFFFFFFFF;

	public VegetationPlacement Placement = .Splat;
	/// Splat: the palette index, or cSplatBaseLayer.
	public uint32 SplatLayer = 0;
	/// Splat: the share, nought to one, below which nothing grows.
	public float SplatThreshold = 0.25f;
	/// Mask: the plane index in the mask asset.
	public uint32 MaskPlane = 0;
	/// Instances per square metre, for Uniform, Splat and Mask.
	public float Density = 2.0f;
	public Float2 ScaleRange = .(0.8f, 1.2f);
	/// Reject where the surface tilts more than this.
	public float MaxSlopeDegrees = 35.0f;
	/// The terrain local Y window, which is the heightfield's Y.
	public Float2 HeightRange = .(-1.0e6f, 1.0e6f);
	/// Tilt each instance onto the sampled surface normal.
	public bool AlignToNormal = false;
	/// Metres: full density inside this.
	public float FadeStart = 40.0f;
	/// Metres: nothing beyond this.
	public float FadeEnd = 80.0f;
	/// Grass defaults OFF, casting being the most expensive thing grass can do.
	public bool CastShadows = false;
	/// The memory bound per set; the density scales down to fit.
	public uint32 MaxInstancesPerChunk = 4096;

	public this() {}
}

static class VegetationLayers
{
	/// A hash of every parameter that changes the SCATTER, which is the cache invalidation key
	/// for a layer. The fade and the shadow flag are per frame draw state, so not part of it.
	public static uint64 LayerScatterHash(ScatterLayer layer)
	{
		var layer;
		var h = HashBytes(&layer.Placement, sizeof(VegetationPlacement));
		h = HashBytes(&layer.SplatLayer, sizeof(uint32), h);
		h = HashBytes(&layer.SplatThreshold, sizeof(float), h);
		h = HashBytes(&layer.MaskPlane, sizeof(uint32), h);
		h = HashBytes(&layer.Density, sizeof(float), h);
		h = HashBytes(&layer.ScaleRange, sizeof(Float2), h);
		h = HashBytes(&layer.MaxSlopeDegrees, sizeof(float), h);
		h = HashBytes(&layer.HeightRange, sizeof(Float2), h);
		h = HashBytes(&layer.AlignToNormal, sizeof(bool), h);
		h = HashBytes(&layer.MaxInstancesPerChunk, sizeof(uint32), h);
		return h;
	}
}
