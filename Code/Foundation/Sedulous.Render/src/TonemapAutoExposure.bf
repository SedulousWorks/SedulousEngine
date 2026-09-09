using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// The auto exposure inputs the tone map reads: the exposure pass's adapted luminance, and
/// the window it is clamped into.
///
/// A null view, or the flag being off, disables it.
struct TonemapAutoExposure
{
	public bool Enabled = false;
	/// Declared as a read, which orders this after the measure pass.
	public RGHandle Handle = .Invalid;
	public ITextureView View = null;
	public uint64 Generation = 0;

	/// The middle grey the image is exposed toward.
	public float Key = 0.18f;
	/// The clamp, as LINEAR multipliers.
	public float MinExposure = 0.0625f;
	public float MaxExposure = 16.0f;

	public this() {}
}
