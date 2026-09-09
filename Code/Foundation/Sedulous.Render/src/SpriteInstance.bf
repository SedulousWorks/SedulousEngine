using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One sprite's instance record, laid out exactly as the vertex shader's inputs.
[CRepr]
struct SpriteInstance
{
	/// The world centre in the first three, and the width in the fourth.
	public Float4 PositionSize = .(0, 0, 0, 1);
	/// The height in the first, and the orientation mode in the second.
	public Float4 SizeOrientation = .(1, 0, 0, 0);
	public Float4 Tint = .(1, 1, 1, 1);
	/// The atlas sub rectangle, as an origin and an extent.
	public Float4 UvRect = .(0, 0, 1, 1);
	/// The oriented case's own right and up axes.
	public Float4 AxisRight = .(1, 0, 0, 0);
	public Float4 AxisUp = .(0, 1, 0, 0);

	public this() {}
}
