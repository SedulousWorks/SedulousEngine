namespace Sedulous.RHI;

/// One colour target of a fragment stage.
struct ColorTargetState
{
	public TextureFormat Format = .Undefined;
	/// Null disables blending for this target, which is not the same as a blend that
	/// happens to be a passthrough: the hardware can skip the read entirely.
	public BlendState? Blend = null;
	public ColorWriteMask WriteMask = .All;

	public this() {}
}
