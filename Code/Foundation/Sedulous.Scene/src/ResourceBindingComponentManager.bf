using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Scene;

/// A serializable pool whose components hold resource references.
///
/// Subclass this rather than SerializableComponentManager when the component implements
/// IComponentResources, and the post load bind happens for every one of them without a
/// line of per manager code.
///
/// The manager the scene was resolved with is kept, so a runtime swap of a reference (a
/// script changing a clip by id) binds through the same one. Before the first resolve there
/// is none, and a swap sets the identity only; the resolve, when it comes, binds it.
class ResourceBindingComponentManager<T> : SerializableComponentManager<T>
	where T : struct, ISerializable, IComponentResources, new
{
	/// BORROWED, from the last resolve. Null until then.
	private ResourceManager mResources = null;

	public ResourceManager Resources => mResources;

	public override void ResolveResources(ResourceManager manager)
	{
		mResources = manager;
		ForEach(scope (component, owner) =>
		{
			component.ResolveResources(manager);
		});
	}
}
