namespace Sedulous.RHI;

/// A global ordering point, naming no resource.
///
/// For where the dependency is real but not attached to one object, such as ordering all
/// shader writes before all shader reads.
struct MemoryBarrier
{
	public ResourceState OldState = .Undefined;
	public ResourceState NewState = .Undefined;

	public this() {}
}
