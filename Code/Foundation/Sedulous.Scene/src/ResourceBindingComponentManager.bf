using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Scene;

/// A serializable pool whose components hold resource references.
///
/// Subclass this rather than SerializableComponentManager when the component implements
/// IComponentResources, and the post load bind happens for every one of them without a
/// line of per manager code.
class ResourceBindingComponentManager<T> : SerializableComponentManager<T>
	where T : struct, ISerializable, IComponentResources
{
	public override void ResolveResources(ResourceManager manager)
	{
		ForEach(scope (component, owner) =>
		{
			component.ResolveResources(manager);
		});
	}
}
