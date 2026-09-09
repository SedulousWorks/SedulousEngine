namespace Sedulous.Render;

/// One atlas tile and the scene whose casters render into it.
struct AtlasDraw
{
	public LocalShadowTile Tile = .();
	/// Borrowed from the frame's pool.
	public SceneShadowContext Context = null;

	public this() {}

	public this(LocalShadowTile tile, SceneShadowContext context)
	{
		Tile = tile;
		Context = context;
	}
}
