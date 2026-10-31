using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Shaders;

namespace Sedulous.Materials.Resource;

/// Registration for the material resource types.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else.
[SerializableRegistry]
static class MaterialResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	/// The material factory is made in every host and given the host's shader system when it has
	/// one (the effects' tables; MaterialFactory), never gated on it.
	public static ResourceModule Module => sModule ?? (sModule = new .("materials", () => RegisterAll(), new .(
		.(typeof(Material), typeof(MaterialSource), null,
			(services) => new MaterialFactory(services.Service(typeof(ShaderSystem)) as ShaderSystem)))));
	private static ResourceModule sModule ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, MaterialFactory materials)
	{
		manager.AddFactory(materials);
	}
}
