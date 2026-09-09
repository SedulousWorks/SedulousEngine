using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Terrain.Resource;

/// One terrain surface layer: its maps, and how often they tile.
///
/// References rather than proxies, because a cooked terrain binds them through the manager
/// while an in memory or procedural one, which is what a playground or a test builds, assigns
/// the products directly.
struct TerrainLayer
{
	public Ref<Texture> Albedo = default;
	/// Tangent space. Unset means flat.
	public Ref<Texture> Normal = default;
	/// Ambient occlusion, roughness and metallic. Unset means the neutral default.
	public Ref<Texture> Orm = default;
	/// The displacement the height blend reads, through its red channel. Unset means none.
	public Ref<Texture> Height = default;
	/// Coverage, on a palette layer only, through its red channel. Unset means opaque.
	public Ref<Texture> Mask = default;

	/// Shared by every map of this layer.
	public float TileScale = 1.0f;

	public this() {}
}
