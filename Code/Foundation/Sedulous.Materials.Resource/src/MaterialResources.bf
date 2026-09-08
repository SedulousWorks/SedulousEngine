using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Materials.Resource;

/// Registration for the material resource types.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else.
[SerializableRegistry]
static class MaterialResources
{
	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, MaterialFactory materials)
	{
		manager.AddFactory(materials);
	}
}
