using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Model.Resource;

/// Registration for the model resource types.
///
/// The LEAF families register themselves: a model references meshes, materials, textures and
/// animation, and each of those modules owns the registration of its own types. Raptor
/// registers the whole family from here, which puts one module in charge of five others'
/// identities.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else.
[SerializableRegistry]
static class ModelResources
{
	/// The manager does not take ownership, so the caller keeps the factory alive for as long
	/// as it keeps the manager.
	public static void AddFactories(ResourceManager manager, ModelFactory models)
	{
		manager.AddFactory(models);
	}
}
