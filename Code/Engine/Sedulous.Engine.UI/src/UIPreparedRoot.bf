using Sedulous.VG.Renderer;

namespace Sedulous.Engine.UI;

/// One root recorded and uploaded for a pass: the renderer and slice it was drawn with, and the
/// viewport it draws into. No renderer: nothing to draw.
struct UIPreparedRoot
{
	public VGRenderer Renderer = null;
	public VGRenderSlice Slice = .();
	public int32 ViewportX = 0;
	public int32 ViewportY = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;
	public int32 FrameIndex = 0;

	public this() {}
}
