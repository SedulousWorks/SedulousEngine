using System;

namespace Sedulous.RHI;

struct PipelineCacheDesc
{
	/// A blob from a previous run's GetData, or empty to start cold. A driver that does not
	/// recognise it ignores it rather than failing.
	public Span<uint8> InitialData = default;
	public StringView Label = default;

	public this() {}
}
