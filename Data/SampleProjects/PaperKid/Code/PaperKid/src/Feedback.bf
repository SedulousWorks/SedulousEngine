using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Audio;
using Sedulous.GUI;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.Animation;

namespace PaperKid;

/// What the game's code does to show and sound what happened: a prefab spawned, a clip played on
/// a model, a one-shot played into the run, the pad rumbled, a random draw. Each does nothing
/// where its service is missing (a scene without prefab spawns, a scene simulating outside a run).
static class Feedback
{
	/// Spawns `prefab` at `at` in `scene`, a root; an unassigned handle when it could not.
	public static EntityHandle Spawn(Scene scene, Guid prefab, Float3 at)
	{
		if (let spawner = scene.GetSystem<PrefabSpawnSystem>())
			return spawner.Spawn(prefab, at);
		return .Invalid;
	}

	/// Sets `model`'s clip animator on `clip` and plays it from its start.
	public static void PlayClip(Scene scene, EntityHandle model, Guid clip)
	{
		if (let animation = scene.GetSystem<SkeletalAnimationComponentManager>())
		{
			animation.SetClip(model, clip);
			animation.Play(model);
		}
	}

	/// The playback rate of `model`'s clip animator; nothing without one.
	public static void ClipSpeed(Scene scene, EntityHandle model, float speed)
	{
		let animator = scene.GetComponent<SkeletalAnimationComponent>(model);
		if (animator != null)
			animator.Speed = speed;
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
}

/// The run GUI's screens as the game's code reaches them: the screen stack and an element by id.
static class Hud
{
	/// The run GUI's screen stack; null in a run without a GUI, or outside a run.
	public static ScreenStack Screens(IRun run)
	{
		let gui = RunServices.Get<GuiFacade>(run);
		let root = (gui != null) ? gui.Root() : null;
		return (root != null) ? (root.FindElement("screens") as ScreenStack) : null;
	}

	/// The element `id`, the top screen first: a screen just cleared or popped away is still in
	/// the tree while its exit plays, with the same ids, and would be found first. Null when there
	/// is none (the HUD is not up).
	public static Node Find(IRun run, StringView id)
	{
		let gui = RunServices.Get<GuiFacade>(run);
		let root = (gui != null) ? gui.Root() : null;
		if (root == null)
			return null;
		let stack = root.FindElement("screens") as ScreenStack;
		let top = (stack != null) ? stack.Top : null;
		let found = (top != null) ? top.FindElement(id) : null;
		return (found != null) ? found : root.FindElement(id);
	}

	/// The label `id`'s text; nothing when there is no such label.
	public static void SetText(IRun run, StringView id, StringView text)
	{
		if (let label = Find(run, id) as Label)
			label.Text = text;
	}

	/// The element `id`'s `property` set at once: a tween of no length, which replaces the last.
	public static void Snap(IRun run, StringView id, StringView property, StringView value)
	{
		if (let node = Find(run, id))
			Snap(node, property, value);
	}

	/// `node`'s `property` set at once.
	public static void Snap(Node node, StringView property, StringView value)
	{
		node.Animate(property, value, 0.0f, "linear").ReleaseRef();
	}
}
