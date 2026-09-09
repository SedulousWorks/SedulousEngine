using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A GPU object waiting to be destroyed.
///
/// A resource the frame just finished with may still be referenced by commands that are in
/// flight, so it is destroyed a whole buffering cycle later rather than now.
struct DeferredDeletion
{
	public ITexture Texture = null;
	public ITextureView View = null;
	/// A second view of the same texture, which is the depth only one.
	public ITextureView SecondView = null;
	public IBuffer Buffer = null;

	public this() {}

	public void Execute(IDevice device) mut
	{
		if (device == null)
			return;

		if (SecondView != null)
			device.DestroyTextureView(ref SecondView);
		if (View != null)
			device.DestroyTextureView(ref View);
		if (Texture != null)
			device.DestroyTexture(ref Texture);
		if (Buffer != null)
			device.DestroyBuffer(ref Buffer);
	}
}
