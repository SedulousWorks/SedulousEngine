namespace Sedulous.RHI;

/// A presentable surface, created from a native window handle.
///
/// Separate from the swap chain because the surface outlives it: a resize destroys and
/// rebuilds the chain against the same surface.
interface ISurface
{
}
