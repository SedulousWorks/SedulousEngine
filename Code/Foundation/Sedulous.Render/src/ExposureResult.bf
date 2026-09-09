using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// What the exposure measurement leaves behind: the adapted value as a graph handle, so the
/// tonemap's read is a proper edge, and the raw view and a generation for its bind group.
struct ExposureResult
{
	public RGHandle Handle;
	public ITextureView View;
	/// Bumps when the underlying texture changes, so a cached bind group knows to rebuild.
	public uint64 Generation;

	public this()
	{
		Handle = default;
		View = null;
		Generation = 0;
	}
}
