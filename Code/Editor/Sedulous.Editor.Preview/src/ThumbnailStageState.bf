namespace Sedulous.Editor.Preview;

enum ThumbnailStageState : uint8
{
	/// No job; Update polls the service.
	case Idle;
	/// The generator is populating the scene (Pending until its resources resolve).
	case Staging;
	/// Staged and framed; the next Render declares the scene view.
	case RenderPending;
	/// View declared; the graph renders at EndRendering, after the frame encoder's commands,
	/// so the readback copy waits for the next frame's encoder to be ordered behind it.
	case CopyPending;
	/// The copy was submitted on a frame index; retire when the ring revisits it.
	case AwaitReadback;
}
