using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One world space debug vertex: a position and a packed colour.
///
/// The colour's RED is in the LOW byte, which is what a normalised byte vertex attribute
/// reads as the first component.
[CRepr]
struct DebugVertex
{
	public Float3 Position = .(0, 0, 0);
	public uint32 Color = 0xFFFFFFFF;

	public this() {}

	public this(Float3 position, uint32 color)
	{
		Position = position;
		Color = color;
	}
}
