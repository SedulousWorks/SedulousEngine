using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;

namespace SkyHopper;

/// What the behaviours do to show and sound what happened: an effect's prefab spawned, a one-shot
/// played into the run, the pad rumbled. Each does nothing where its service is missing (a scene
/// without prefab spawns, a scene simulating outside a run).
static class Feedback
{
	/// Spawns `prefab` (an FX prefab, which removes itself) at `at` in `scene`.
	public static void Spawn(Scene scene, Guid prefab, Float3 at)
	{
		if (let spawner = scene.GetSystem<PrefabSpawnSystem>())
			spawner.Spawn(prefab, at);
	}

	/// Plays `clip` once in `run`, on `bus`.
	public static void Play(IRun run, Guid clip, AudioBus bus = .Effects, float volume = 1.0f, float pitch = 1.0f)
	{
		if (let audio = RunServices.Get<AudioFacade>(run))
			audio.PlayOneShot(clip, bus, volume, pitch);
	}

	/// Rumbles the run's first pad: its low and high motors for `seconds`.
	public static void Rumble(IRun run, float low, float high, float seconds)
	{
		if (let input = RunServices.Get<InputFacade>(run))
			input.Rumble(low, high, seconds);
	}
}
