using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Shaders.Resource;

/// Registration for the shader resource types.
///
/// When to populate the serializable table, and which factories a host wants, stay the
/// application's business, as everywhere else.
[SerializableRegistry]
static class ShaderResources
{
	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, ShaderFactory shaders)
	{
		manager.AddFactory(shaders);
	}
}
