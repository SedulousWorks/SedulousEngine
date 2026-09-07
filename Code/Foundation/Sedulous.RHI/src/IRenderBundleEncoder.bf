namespace Sedulous.RHI;

/// Records draws into a bundle. The shared surface only: a bundle carries no pass level
/// state, inheriting it from whichever pass executes it.
interface IRenderBundleEncoder : IRenderCommandEncoder
{
	/// Ends recording and returns the bundle, which the POOL owns.
	IRenderBundle Finish();
}
