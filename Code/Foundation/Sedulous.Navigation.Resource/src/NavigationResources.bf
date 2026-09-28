using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Navigation.Resource;

/// Registration for the navigation resource types.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else. Without the registration an instance writes
/// its primary fine and reads it back as null, which looks like a missing asset rather
/// than a missing call.
[SerializableRegistry]
static class NavigationResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("navigation", () => RegisterAll(), new .(
		.ByDefault<NavigationZoneResource, NavigationZoneSource, NavigationZoneFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as long
	/// as it keeps the manager.
	public static void AddFactories(ResourceManager manager, NavigationZoneFactory zones)
	{
		manager.AddFactory(zones);
	}
}
