using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// THE animation manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one, so a
/// manager added here reaches both rather than only the path someone remembered.
static class AnimationScene
{
	public static void AddAnimationSceneManagers(Scene scene)
	{
		scene.AddSystem<AnimationGraphComponentManager>();
		scene.AddSystem<SkeletalAnimationComponentManager>();
		scene.AddSystem<InstancedSkinningComponentManager>();
		scene.AddSystem<PropertyAnimatorComponentManager>();
	}
}
