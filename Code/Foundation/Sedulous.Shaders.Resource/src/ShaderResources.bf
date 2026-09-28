using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Resource;

/// Registration for the shader resource types.
///
/// When to populate the serializable table, and which factories a host wants, stay the
/// application's business, as everywhere else.
[SerializableRegistry]
static class ShaderResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("shaders", () => RegisterAll(), new .(
		.(typeof(ShaderResource), typeof(ShaderSource), typeof(ShaderSystem), (services) =>
			{
				let system = services.Service(typeof(ShaderSystem)) as ShaderSystem;
				return (system != null) ? new ShaderFactory(system) : null;
			}))));
	private static ResourceModule sModule ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, ShaderFactory shaders)
	{
		manager.AddFactory(shaders);
	}
}
