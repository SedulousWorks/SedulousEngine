namespace Sedulous.Resource;

/// What the cache is holding, for one product type.
///
/// The instrumentation an eviction policy has to be designed against: measure what is
/// resident before deciding what to throw away. Unreferenced is the interesting column,
/// because those are the products nothing outside the cache is using.
struct LiveProductRow
{
	/// Zero for handles whose product type never resolved.
	public uint64 ProductTypeId;
	/// A product is present.
	public int Live;
	/// A decode is in flight.
	public int Pending;
	/// Failed or empty, and still cached.
	public int Failed;
	/// Live AND watched by nothing but the cache: exactly what a purge would release.
	///
	/// Counted from the WEAK references, because a Proxy here observes its handle weakly
	/// and the cache is the only strong owner; a proxy that owned the handle would ask the
	/// same question of the strong count.
	public int Unreferenced;

	public this()
	{
		ProductTypeId = 0; Live = 0; Pending = 0; Failed = 0; Unreferenced = 0;
	}
}
