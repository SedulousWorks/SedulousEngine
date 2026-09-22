using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Vegetation.Resource;

/// Registration for the vegetation resource types.
///
/// Without it an instance writes its references fine and reads them back as null, which looks
/// like a missing asset rather than a missing call.
[SerializableRegistry]
static class VegetationResources
{
	/// The manager does not take ownership, so the caller keeps the factory alive for as long
	/// as it keeps the manager.
	public static void AddFactories(ResourceManager manager, VegetationMaskFactory masks)
	{
		manager.AddFactory(masks);
	}
}
