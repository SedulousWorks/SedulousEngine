using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Editor.Vegetation;

/// What a brush ray found: the mask to paint, where on it, and the terrain it belongs to.
struct VegetationPick
{
	public bool Valid = false;
	public Ref<VegetationMask> Mask = default;
	/// The entity carrying the vegetation component, so a stamp can scope its regrow.
	public EntityHandle Owner = .();
	/// The footprint uv the ray hit.
	public float UvX = 0.0f;
	public float UvY = 0.0f;
	/// The terrain's world span, which turns a world radius into a uv one.
	public float WorldSizeX = 1.0f;
	public float WorldSizeY = 1.0f;
	/// The heightfield's sample grid side, for mapping a footprint rect onto it.
	public int32 GridSize = 0;
	public Float3 WorldHit = .Zero;
	public Float3 WorldNormal = .(0.0f, 1.0f, 0.0f);

	public this() {}
}
