using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Heightfield.Resource;

/// Registration for the heightfield resource types.
///
/// Without it an instance writes its metadata fine and reads it back as null, which looks
/// like a missing asset rather than a missing call.
[SerializableRegistry]
static class HeightfieldResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("heightfield", () => RegisterAll(), new .(
		.ByDefault<Heightfield, HeightfieldSource, HeightfieldFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, HeightfieldFactory heightfields)
	{
		manager.AddFactory(heightfields);
	}
}
