namespace Sedulous.Scene.Tests;

/// A component that points at heap data its MANAGER owns, which is the only way a component
/// can have any: a component is a struct in a packed pool, and the pool copies it.
struct Owning
{
	public System.Collections.List<int32> Payload = null;

	public this() {}
}
