using Sedulous.Core;

namespace Sedulous.Navigation;

/// The tile grid a blob was baked on, which a partial rebake needs to stay aligned to.
struct NavigationTileGridDesc
{
	/// The horizontal anchor the tiles line up with, which is the ORIGINAL bake's minimum
	/// corner. The vertical range is always taken from the geometry as it is now, so a rebake
	/// may add taller or lower content without invalidating the grid.
	public Float3 Origin = .(0, 0, 0);
	public float TileWorldSize = 0.0f;
	public int32 CountX = 0;
	public int32 CountY = 0;

	public this() {}
}
