using System.Threading;

namespace Sedulous.RHI;

/// The source of texture view identities.
///
/// A free standing counter rather than something on ITextureView, because an interface
/// carries no storage and every backend's view must draw from the SAME sequence for the
/// ids to mean anything.
static class TextureViewIds
{
	private static int64 sNext = 0;

	/// The next id. Monotonic and thread safe; ids are never reused, which is the point.
	public static uint64 Next() => (uint64)Interlocked.Increment(ref sNext);
}
