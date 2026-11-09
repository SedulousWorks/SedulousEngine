using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// The clips, in the Guests entity's instanced skinning order (Tools/maps.py): what a guest or a
/// hunter is doing is the clip it plays.
static class Clips
{
	public const int32 Idle = 0;
	public const int32 Walk = 1;
	public const int32 Talk = 2;
	public const int32 Dance = 3;
}

/// The orchestra's cues: what the ball does.
static class Cues
{
	/// Wander from place to place.
	public const int32 Stroll = 0;
	/// Go to the nearest place and talk there.
	public const int32 Gather = 1;
	/// Dance, there and then.
	public const int32 Dance = 2;
}

/// What the ball's pieces share: the run's input and network, its random numbers, one another's
/// code, and the sums along the floor. Each does what an offline run would where its service is
/// missing (a scene simulating outside a run has no input or network).
static class Pieces
{
	/// The ball's hunters: the player and three bots, or the players who take the bots' seats.
	public const int32 Hunters = 4;
	/// The costumes every guest and hunter wears one of.
	public const int32 Costumes = 6;

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

	/// The run's network; null outside a run.
	public static NetFacade Net(IRun run) => RunServices.Get<NetFacade>(run);

	/// Whether this run is a client of a host; false offline and outside a run.
	public static bool IsClient(IRun run)
	{
		let net = Net(run);
		return (net != null) && net.IsClient;
	}

	/// The player this peer plays as: 0 the host (and offline), else the id the host gave it.
	public static int32 LocalPlayer(IRun run)
	{
		let net = Net(run);
		let me = (net != null) ? net.LocalPlayer : -1;
		return (me < 0) ? 0 : me;
	}

	/// A draw between `min` and `max` from the run's random numbers; their middle outside a run
	/// (a scene simulating in the editor), so the code still runs the same way there.
	public static float Range(RunRandom random, float min, float max)
	{
		return (random != null) ? random.Range(min, max) : (min + max) * 0.5f;
	}

	/// A whole number from `min` to `max`; `min` outside a run.
	public static int32 IntRange(RunRandom random, int32 min, int32 max)
	{
		return (random != null) ? random.IntRange(min, max) : min;
	}

	/// A coin toss; false outside a run.
	public static bool Toss(RunRandom random)
	{
		return (random != null) && random.Bool();
	}

	/// The ball behaviour on `entity`, or null.
	public static Ball BallOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<Ball>>()?.Get(entity);

	/// The player behaviour on `entity` (a player's hunter), or null.
	public static Player PlayerOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<Player>>()?.Get(entity);

	/// The guest behaviour on `entity` (a guest, or a bot), or null.
	public static Guest GuestOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<Guest>>()?.Get(entity);

	/// The camera rig on `entity`, or null.
	public static CameraRig RigOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<CameraRig>>()?.Get(entity);

	/// The distance from `a` to `b` along the floor.
	public static float FlatDistance(Float3 a, Float3 b)
	{
		let dx = a.X - b.X;
		let dz = a.Z - b.Z;
		return Sqrt(dx * dx + dz * dz);
	}

	/// `angle` brought within a half turn either way, so a turn toward it goes the short way round.
	public static float Wrap(float angle)
	{
		var wrapped = angle;
		while (wrapped > 3.14159265f)
			wrapped -= 6.2831853f;
		while (wrapped < -3.14159265f)
			wrapped += 6.2831853f;
		return wrapped;
	}
}
