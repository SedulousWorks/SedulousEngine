using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Fonts.Resource;

/// Registration for the font resource types.
///
/// When to populate the serializable table, and which factories a host wants, stay the
/// application's business, as everywhere else.
[SerializableRegistry]
static class FontResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("fonts", () => RegisterAll(), new .(
		.ByDefault<Font, FontResource, FontFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, FontFactory fonts)
	{
		manager.AddFactory(fonts);
	}
}
