namespace Sedulous.Resource;

/// Where a resource has got to.
enum ResourceState : uint8
{
	/// Never built.
	Unloaded,
	/// A build is in flight. The product is not there yet.
	Pending,
	Ready,
	/// No instance, no factory, or the build failed. Distinct from Unloaded: this one has
	/// been tried.
	Failed
}
