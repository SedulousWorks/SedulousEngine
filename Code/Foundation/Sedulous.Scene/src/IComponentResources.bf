using Sedulous.Resource;

namespace Sedulous.Scene;

/// A component that holds RESOURCE REFERENCES, and knows how to bind them.
///
/// Loading a scene deliberately leaves a reference unbound: binding needs a manager over
/// the database the scene came from, which the loader has no business knowing about. The
/// post load pass walks the scene and calls this.
///
/// DIVERGES from Raptor, which finds a free ResolveResources by argument dependent lookup
/// and so needs no declaration at all. Beef has no such thing, so a component with
/// references says so, and a component with none pays nothing.
interface IComponentResources
{
	/// Binds every reference this component holds. IDEMPOTENT: re binding something
	/// already bound is a cache hit, and the pass runs whenever a manager arrives.
	void ResolveResources(ResourceManager manager) mut;
}
