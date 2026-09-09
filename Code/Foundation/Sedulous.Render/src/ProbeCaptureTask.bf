using Sedulous.Core;

namespace Sedulous.Render;

/// A probe that needs capturing this frame.
///
/// The capture loop renders the six faces into the slot's layers and then marks it captured.
/// The scene is carried because a frame can render several side by side, and a probe must be
/// captured from ITS OWN scene's geometry rather than whichever happens to be current.
struct ProbeCaptureTask
{
	public uint32 Slot = 0;
	public Float3 Center = .(0, 0, 0);
	/// Borrowed: the frame owns it.
	public ExtractedScene Scene = null;

	public this() {}

	public this(uint32 slot, Float3 center, ExtractedScene scene)
	{
		Slot = slot;
		Center = center;
		Scene = scene;
	}
}
