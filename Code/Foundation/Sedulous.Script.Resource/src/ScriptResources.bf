using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Script.Resource;

/// Registration for the script resource types.
[SerializableRegistry]
static class ScriptResources
{
	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, ScriptClassFactory classes)
	{
		manager.AddFactory(classes);
	}
}
