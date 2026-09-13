using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// THE audio manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one. The
/// runtime only wiring, handing the scene system its engine, stays with the subsystem: the
/// system is engine less, and silent, until it arrives.
static class AudioScene
{
	public static void AddAudioSceneManagers(Scene scene)
	{
		scene.AddSystem<AudioSourceComponentManager>();
		scene.AddSystem<AudioListenerComponentManager>();
		scene.AddSystem<AudioReverbZoneComponentManager>();
		scene.AddSystem<AudioSceneSystem>();
	}
}
