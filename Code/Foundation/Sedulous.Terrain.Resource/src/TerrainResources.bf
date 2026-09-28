using System;
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
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module = new .("terrain", () => RegisterAll(), new .(
		.ByDefault<TerrainResource, TerrainSource, TerrainFactory>(),
		.ByDefault<SplatWeights, SplatWeightsSource, SplatWeightsFactory>())) ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factories alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, TerrainFactory terrains,
		SplatWeightsFactory weights)
	{
		manager.AddFactory(terrains);
		manager.AddFactory(weights);
	}
}
