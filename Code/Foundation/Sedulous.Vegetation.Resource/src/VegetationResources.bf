using System;
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
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("vegetation", () => RegisterAll(), new .(
		.ByDefault<VegetationMask, VegetationMaskSource, VegetationMaskFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as long
	/// as it keeps the manager.
	public static void AddFactories(ResourceManager manager, VegetationMaskFactory masks)
	{
		manager.AddFactory(masks);
	}
}
