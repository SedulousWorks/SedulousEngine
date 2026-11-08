using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// What the level's pieces share: the run's input and sound, a figure's graph, one another's code,
/// and the sums the thief and the guards both do. Each does nothing where its service is missing
/// (a scene simulating outside a run has no input, sound or GUI).
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

	/// The control `action` takes on the device in hand ("F", "Pad South"), appended; the action's
	/// own name outside a run.
	public static void Describe(IRun run, StringView action, String outText)
	{
		let input = Controls(run);
		outText.Append((input != null) ? input.Describe(action) : action);
	}

	/// Whether `action` is held; false outside a run.
	public static bool IsDown(IRun run, StringView action)
	{
		let input = Controls(run);
		return (input != null) && input.IsDown(action);
	}

	/// Plays `clip` once at `at` in `run`; true when a voice started.
	public static bool PlayAt(IRun run, Guid clip, Float3 at)
	{
		let audio = RunServices.Get<AudioFacade>(run);
		return (audio != null) && audio.PlayOneShot3D(clip, at).IsValid;
	}

	/// The skinned mesh that carries a figure's graph: `owner`'s child `name` (the model's
	/// instance), its `rig`, and the mesh named `name` under that. Invalid when any is missing.
	public static EntityHandle Figure(Scene scene, EntityHandle owner, StringView name, StringView rig)
	{
		// FindChildByName searches the roots for an unassigned parent: each step stops at a miss.
		let model = scene.FindChildByName(owner, name);
		if (!scene.IsValid(model))
			return .Invalid;
		let skeleton = scene.FindChildByName(model, rig);
		if (!scene.IsValid(skeleton))
			return .Invalid;
		return scene.FindChildByName(skeleton, name);
	}

	/// The figure's graph parameter `name` set to `value`; nothing before its graph is built.
	public static void SetFloat(Scene scene, EntityHandle figure, StringView name, float value)
	{
		if (let graphs = scene.GetSystem<AnimationGraphComponentManager>())
			graphs.SetFloat(figure, name, value);
	}

	public static void SetBool(Scene scene, EntityHandle figure, StringView name, bool value)
	{
		if (let graphs = scene.GetSystem<AnimationGraphComponentManager>())
			graphs.SetBool(figure, name, value);
	}

	/// The thief behaviour on `entity`, or null.
	public static Thief ThiefOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<Thief>>()?.Get(entity);

	/// The door behaviour on `entity` (a hinge), or null.
	public static Door DoorOn(Scene scene, EntityHandle entity) => scene.GetSystem<BehaviourManager<Door>>()?.Get(entity);

	/// The distance from `a` to `b` along the floor.
	public static float FlatDistance(Float3 a, Float3 b)
	{
		let dx = a.X - b.X;
		let dz = a.Z - b.Z;
		return Sqrt(dx * dx + dz * dz);
	}

	/// Every collision group but `group`: a ray that looks past it.
	public static uint32 MaskWithout(int32 group) => ~((uint32)1 << (int)group);

	/// How bright linear light `light` is to the eye (its luminance).
	public static float Luminance(Float3 light) => 0.2126f * light.X + 0.7152f * light.Y + 0.0722f * light.Z;

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
}
