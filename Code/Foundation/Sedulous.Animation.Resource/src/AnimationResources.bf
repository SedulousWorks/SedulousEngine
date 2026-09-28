using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Animation.Resource;

/// Registration for the animation resource types.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else. Without the registration an instance writes
/// its primary fine and reads it back as null, which looks like a missing asset rather
/// than a missing call.
[SerializableRegistry]
static class AnimationResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from. The factories belong here, with the resources they
	/// produce, not with an engine subsystem and not with an executable.
	public static ResourceModule Module = new .("animation", () => RegisterAll(), new .(
		.ByDefault<Skeleton, SkeletonSource, SkeletonFactory>(),
		.ByDefault<AnimationClip, AnimationClipSource, AnimationClipFactory>(),
		.ByDefault<AnimationGraph, AnimationGraphSource, AnimationGraphFactory>())) ~ delete _;

	/// The manager does not take ownership, so the caller keeps the factories alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, SkeletonFactory skeletons,
		AnimationClipFactory clips, AnimationGraphFactory graphs)
	{
		manager.AddFactory(skeletons);
		manager.AddFactory(clips);
		manager.AddFactory(graphs);
	}
}
