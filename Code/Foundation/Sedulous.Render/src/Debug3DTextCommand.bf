using Sedulous.Core;

namespace Sedulous.Render;

/// One piece of text anchored at a world position, projected to the screen when it is drawn.
struct Debug3DTextCommand
{
	public Float3 WorldPosition = .(0, 0, 0);
	public Color Color = .(1, 1, 1, 1);
	public int32 TextStart = 0;
	public int32 TextLength = 0;

	public this() {}
}
