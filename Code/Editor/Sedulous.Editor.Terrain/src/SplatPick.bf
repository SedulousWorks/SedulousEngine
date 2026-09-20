using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;

namespace Sedulous.Editor.Terrain;

/// Where the splat brush's ray met a terrain: the weights it paints, in raster UV.
struct SplatPick
{
	/// The weights reference as the terrain holds it: the live rasters plus the SOURCE
	/// asset guid the stroke persists back to, which may be nil for in memory rasters.
	public Ref<SplatWeights> Weights = default;
	public float UvX = 0.0f;
	public float UvY = 0.0f;
	/// The heightfield's world extent, which maps the brush's world radius onto UV.
	public float WorldSizeX = 1.0f;
	public float WorldSizeY = 1.0f;
	public Float3 WorldHit = .Zero;
	public Float3 WorldNormal = .(0.0f, 1.0f, 0.0f);
	public bool Valid = false;

	public this() {}
}
