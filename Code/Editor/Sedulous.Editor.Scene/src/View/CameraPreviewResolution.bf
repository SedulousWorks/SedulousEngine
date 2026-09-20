using Sedulous.Scene;

namespace Sedulous.Editor.Scene;

/// What the camera preview should do this frame.
struct CameraPreviewResolution
{
	/// The camera entity to preview; unassigned for none.
	public EntityHandle Target = .Invalid;
	/// Whether the preview renders this frame.
	public bool Visible = false;
	/// The caller should clear its pin: the pinned entity went stale.
	public bool Unpin = false;

	public this() {}
	public this(EntityHandle target, bool visible, bool unpin)
	{
		Target = target;
		Visible = visible;
		Unpin = unpin;
	}
}
