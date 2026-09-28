using System;
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
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module = new .("materials", () => RegisterAll(), new .(
		.ByDefault<Material, MaterialSource, MaterialFactory>())) ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, MaterialFactory materials)
	{
		manager.AddFactory(materials);
	}
}
