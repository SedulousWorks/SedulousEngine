using Sedulous.Core;

namespace Sedulous.Render;

/// One two dimensional overlay command, in pixels. A text command's characters live in the
/// accumulator's shared store, which is what keeps a per frame allocation out of it.
struct Debug2DCommand
{
	public Debug2DKind Kind = .Text;
	/// In pixels, from the top left. A NEGATIVE horizontal position means the text is right
	/// aligned, the value being the margin from the right edge.
	public Float2 Position = .(0, 0);
	/// In pixels, for a rectangle.
	public Float2 Size = .(0, 0);
	public Color Color = .(1, 1, 1, 1);
	public int32 TextStart = 0;
	public int32 TextLength = 0;
	public float Scale = 1.0f;

	public this() {}
}
