using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// What the course's pieces share: the run's input, sound and pad, prefab spawns, the board's code,
/// random draws and the angle sums. Each does nothing where its service is missing (a scene
/// simulating outside a run has no input or sound).
static class Pieces
{
	/// The run's input; null outside a run.
	public static InputFacade Controls(IRun run) => RunServices.Get<InputFacade>(run);

	/// Whether `action` was pressed this frame; false outside a run.
	public static bool WasPressed(IRun run, StringView action)
	{
		let input = Controls(run);
		return (input != null) && input.WasPressed(action);
	}

	/// Whether `action` is held; false outside a run.
	public static bool IsDown(IRun run, StringView action)
	{
		let input = Controls(run);
		return (input != null) && input.IsDown(action);
	}

	/// Plays `clip` once in `run`, on `bus`.
	public static void Play(IRun run, Guid clip, AudioBus bus, float volume, float pitch = 1.0f)
	{
		if (let audio = RunServices.Get<AudioFacade>(run))
			audio.PlayOneShot(clip, bus, volume, pitch);
	}

	/// Rumbles the run's first pad: its low and high motors for `seconds`.
	public static void Rumble(IRun run, float low, float high, float seconds)
	{
		if (let input = Controls(run))
			input.Rumble(low, high, seconds);
	}

	/// Spawns `prefab` at `at` in `scene`, a root turned by `rotation`; an unassigned handle when
	/// it could not.
	public static EntityHandle Spawn(Scene scene, Guid prefab, Float3 at, Quaternion rotation = .Identity)
	{
		if (let spawner = scene.GetSystem<PrefabSpawnSystem>())
			return spawner.Spawn(prefab, at, rotation);
		return .Invalid;
	}

	/// The board behaviour on `entity` (the rider), or null.
	public static Board BoardOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<Board>>()?.Get(entity);

	/// A draw between `min` and `max` from the run's random numbers; their middle outside a run
	/// (a scene simulating in the editor), so the code still runs the same way there.
	public static float Range(RunRandom random, float min, float max)
	{
		return (random != null) ? random.Range(min, max) : (min + max) * 0.5f;
	}

	/// `angle` brought within a half turn either way, so a turn toward it goes the short way round.
	public static float Wrap(float angle)
	{
		var wrapped = angle;
		while (wrapped > Pi)
			wrapped -= TwoPi;
		while (wrapped < -Pi)
			wrapped += TwoPi;
		return wrapped;
	}

	/// The heading (radians; 0 faces +Z) that `rotation` turns +Z to, along the ground.
	public static float Yaw(Quaternion rotation)
	{
		let forward = RotateVector(rotation, .(0.0f, 0.0f, 1.0f));
		return Atan2(forward.X, forward.Z);
	}

	/// How far a point `offset` from a piece lies along the course heading `heading` (radians; 0
	/// runs toward +Z).
	public static float Along(Float3 offset, float heading) => offset.X * Sin(heading) + offset.Z * Cos(heading);

	/// How far a point `offset` from a piece lies across the course heading `heading`, + toward
	/// the right.
	public static float Across(Float3 offset, float heading) => offset.X * Cos(heading) - offset.Z * Sin(heading);
}
