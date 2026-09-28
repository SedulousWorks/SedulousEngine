using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Script.Resource;

/// Registration for the script resource types.
[SerializableRegistry]
static class ScriptResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module = new .("script", () => RegisterAll(), new .(
		.ByDefault<ScriptClass, ScriptClassSource, ScriptClassFactory>())) ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, ScriptClassFactory classes)
	{
		manager.AddFactory(classes);
	}
}
