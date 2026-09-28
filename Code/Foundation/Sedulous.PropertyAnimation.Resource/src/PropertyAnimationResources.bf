using Sedulous.Resource;
using System;
using Sedulous.Core.Serialization;

namespace Sedulous.PropertyAnimation.Resource;

/// Registration for the property animation resource types.
///
/// Without it an instance writes its clip source fine and reads it back as null, which looks
/// like a missing asset rather than a missing call.
[SerializableRegistry]
static class PropertyAnimationResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module => sModule ?? (sModule = new .("property-animation", () => RegisterAll(), new .(
		.ByDefault<PropertyAnimationClip, PropertyAnimationClipSource, PropertyAnimationClipFactory>())));
	private static ResourceModule sModule ~ delete _;
}
