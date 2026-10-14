using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullRenderBundle : IRenderBundle
{
	/// What it recorded, counted each time it is executed.
	public RecordedCounts Counts;
}
