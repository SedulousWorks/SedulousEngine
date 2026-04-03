namespace Sedulous.RHI;

/// A set of GPU queries (timestamps, occlusion, or pipeline statistics).
/// Destroyed via IDevice.DestroyQuerySet().
interface IQuerySet
{
	/// Type of queries in this set.
	QueryType Type { get; }

	/// Number of queries in this set.
	uint32 Count { get; }
}
