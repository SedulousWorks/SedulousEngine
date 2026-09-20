namespace Sedulous.Editor.Navigation;

struct RegionRebakeResult
{
	/// The asset was updated.
	public bool Rebaked = false;
	/// No tiled blob to patch: fell back to a full bake.
	public bool FullBake = false;
	/// The tiles regenerated, including ones that became empty.
	public int TilesRebuilt = 0;
}
