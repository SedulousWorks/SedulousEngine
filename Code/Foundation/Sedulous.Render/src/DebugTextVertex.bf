using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One text or screen debug vertex: a position in pixels or in the world, a coordinate into
/// the font's atlas, and a packed colour.
[CRepr]
struct DebugTextVertex
{
	public Float3 Position = .(0, 0, 0);
	public Float2 Uv = .(0, 0);
	public uint32 Color = 0xFFFFFFFF;

	public this() {}

	public this(Float3 position, Float2 uv, uint32 color)
	{
		Position = position;
		Uv = uv;
		Color = color;
	}
}
