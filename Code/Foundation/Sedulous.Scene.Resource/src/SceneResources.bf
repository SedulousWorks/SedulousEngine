using Sedulous.Resource;
using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// Registration for the scene resource types.
///
/// WHEN the serializable table is populated stays the application's business, as
/// everywhere else. Without this the documents write fine and read back as null: an
/// instance decodes its primary through the registry, by the type name it stored.
[SerializableRegistry]
static class SceneResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("scene", () => RegisterAll(), null));
	private static ResourceModule sModule ~ delete _;
}
