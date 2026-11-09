using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// A one-shot a script asked for (the Animation facade's PlayOneShot), on either kind of
/// animated entity: the manager starts it over the entity's pose once its clip has loaded, and
/// reports its end. Runtime only.
struct OneShotRuntime
{
	/// Asked for, then playing.
	public Ref<AnimationClip> Clip = .(Guid());
	public OneShotSettings Settings = .();
	/// Asked for, its clip not yet started.
	public bool Pending = false;
	/// Started over the pose, not yet reported ended.
	public bool Playing = false;
	/// Its clip's id (nil for a clip made in code).
	public Guid PlayingId = Guid();

	public this() {}
}

/// A one-shot that ended: its entity and its clip, for the animation subsystem's listeners.
struct OneShotEnded
{
	public EntityHandle Entity;
	public Guid Clip;

	public this(EntityHandle entity, Guid clip)
	{
		Entity = entity;
		Clip = clip;
	}
}

/// What the two animation managers do with a one-shot each tick.
static class OneShots
{
	/// Starts a requested one-shot over `overlay` once its clip has loaded.
	public static void Start(ref OneShotRuntime oneShot, PoseOverlay overlay)
	{
		if (!oneShot.Pending)
			return;
		let clip = oneShot.Clip.Get;
		// Still loading.
		if (clip == null)
			return;
		overlay.PlayOneShot(clip, oneShot.Settings);
		oneShot.Playing = true;
		oneShot.PlayingId = oneShot.Clip.Id;
		oneShot.Pending = false;
	}

	/// After the player's tick: a one-shot that ended joins `ended` (a new one asked for since
	/// has not started yet, so the end is the old one's).
	public static void Ended(ref OneShotRuntime oneShot, bool endedNow, EntityHandle owner,
		List<OneShotEnded> ended)
	{
		if (!endedNow || !oneShot.Playing)
			return;
		ended.Add(.(owner, oneShot.PlayingId));
		oneShot.Playing = false;
	}

	/// Asks for `clip` (by asset id, bound through `resources`) to play over the entity's
	/// animation. Nothing without a clip or a manager to bind it through.
	public static void Request(ref OneShotRuntime oneShot, ResourceManager resources, Guid clip,
		OneShotSettings settings)
	{
		if ((clip == Guid.Empty) || (resources == null))
			return;
		oneShot.Clip.SetId(clip);
		oneShot.Clip.Rebind(resources);
		var clamped = settings;
		clamped.BlendIn = Max(0.0f, settings.BlendIn);
		clamped.BlendOut = Max(0.0f, settings.BlendOut);
		oneShot.Settings = clamped;
		oneShot.Pending = true;
	}

	/// Blends the entity's one-shot out over `blendOut` seconds; one only asked for is dropped.
	public static void Stop(ref OneShotRuntime oneShot, PoseOverlay overlay, float blendOut)
	{
		oneShot.Pending = false;
		overlay?.StopOneShot(Max(0.0f, blendOut));
	}

	/// From the request until the one-shot has blended out.
	public static bool IsPlaying(OneShotRuntime oneShot, PoseOverlay overlay) =>
		oneShot.Pending || ((overlay != null) && overlay.IsPlayingOneShot);
}
