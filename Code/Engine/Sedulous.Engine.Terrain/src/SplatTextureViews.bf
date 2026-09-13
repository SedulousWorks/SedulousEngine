using Sedulous.RHI;

namespace Sedulous.Engine.Terrain;

/// The derived GPU views for one splat raster. Both are null while it is unresolved.
struct SplatTextureViews
{
	/// The per texel blend weights.
	public ITextureView WeightView = null;
	/// The per texel layer indices, read as data rather than filtered.
	public ITextureView IndexView = null;

	public this() {}

	public this(ITextureView weightView, ITextureView indexView)
	{
		WeightView = weightView;
		IndexView = indexView;
	}
}
