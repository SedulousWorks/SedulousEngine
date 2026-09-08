namespace Sedulous.VG.Renderer;

/// A scissor rectangle in FRAMEBUFFER coordinates, which is what the encoder takes.
struct ScissorRect
{
	public int32 X = 0;
	public int32 Y = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;

	public this() {}
}
