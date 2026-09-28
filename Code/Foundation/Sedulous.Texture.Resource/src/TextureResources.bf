using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.RHI;

namespace Sedulous.Texture.Resource;

/// Registration for the texture resource types.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else. Without the registration an instance writes
/// its primary fine and reads it back as null, which looks like a missing asset rather
/// than a missing call.
[SerializableRegistry]
static class TextureResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module = new .("texture", () => RegisterAll(), new .(
		.(typeof(Texture), typeof(TextureResource), typeof(IDevice), (services) =>
			{
				let device = services.Service(typeof(IDevice)) as IDevice;
				return (device != null) ? new TextureFactory(device) : null;
			}))) ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, TextureFactory textures)
	{
		manager.AddFactory(textures);
	}
}
