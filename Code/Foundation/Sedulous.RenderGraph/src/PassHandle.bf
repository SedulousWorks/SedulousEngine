using System;

namespace Sedulous.RenderGraph;

/// A handle to a graph pass.
///
/// No generation: passes live only for the frame they were declared in, and the graph is
/// rebuilt from nothing each time.
struct PassHandle
{
	public const uint32 InvalidIndex = 0xFFFFFFFF;

	public uint32 Index = InvalidIndex;

	public this() {}

	public this(uint32 index)
	{
		Index = index;
	}

	public static PassHandle Invalid => .();

	public bool IsValid => Index != InvalidIndex;

	[Commutable]
	public static bool operator==(PassHandle a, PassHandle b) => a.Index == b.Index;
}
