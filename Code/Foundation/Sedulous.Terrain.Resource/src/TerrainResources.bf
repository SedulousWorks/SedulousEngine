using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Terrain.Resource;

/// Registration for the terrain resource types.
///
/// Without it an instance writes its references fine and reads them back as null, which looks
/// like a missing asset rather than a missing call.
[SerializableRegistry]
static class TerrainResources
{
	/// The manager does not take ownership, so the caller keeps the factories alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, TerrainFactory terrains,
		SplatWeightsFactory weights)
	{
		manager.AddFactory(terrains);
		manager.AddFactory(weights);
	}
}
