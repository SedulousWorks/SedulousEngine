using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// How a one-shot plays: its speed, how long it takes to blend in over the pose and back out,
/// and how many times it plays after the first (0: once; -1: until stopped).
struct OneShotSettings
{
	public float Speed = 1.0f;
	public float BlendIn = 0.2f;
	public float BlendOut = 0.2f;
	public int32 Loops = 0;

	public this() {}

	public this(float speed, float blendIn, float blendOut, int32 loops)
	{
		Speed = speed;
		BlendIn = blendIn;
		BlendOut = blendOut;
		Loops = loops;
	}
}

/// What plays over a player's own pose, whatever made it (a single clip, a state machine's
/// layers). Two things, both blended so nothing snaps:
///  - a one-shot: a clip played once (or a set number of times), whatever its own looping, that
///    blends in over the pose, plays, and blends out back to it (a wave, a flinch, a hop), then
///    says it ended. The pose underneath keeps moving all the while, so the character returns to
///    whatever it is doing by then, with no clip to return to.
///  - a fade from a held pose: the pose as it was shown, held and faded into the pose underneath
///    (a crossfade when a player's clip changes: the old clip's last pose eases into the new clip).
/// A player owns one and applies it after its own pose and before its pose modifiers, so inverse
/// kinematics still holds a foot to the ground during a one-shot. A one-shot moves no root and
/// fires no clip events: it is a look laid over the character, not its locomotion.
class PoseOverlay
{
	/// BORROWED; null when none plays.
	private AnimationClip mClip = null;
	private OneShotSettings mSettings = .();
	/// Into the one-shot, in clip seconds, over all its plays.
	private float mTime = 0.0f;
	/// How much of it shows.
	private float mWeight = 0.0f;
	private bool mStopping = false;
	private float mStopFrom = 0.0f;
	private float mStopLeft = 0.0f;
	private float mStopSeconds = 0.0f;
	/// Stopped at once: Update reports it.
	private bool mEndedNow = false;
	/// The pose a fade starts from.
	private List<BoneTransform> mHeld = new .() ~ delete _;
	private float mHoldLeft = 0.0f;
	private float mHoldSeconds = 0.0f;
	/// Scratch: the one-shot's pose.
	private List<BoneTransform> mSampled = new .() ~ delete _;
	/// What was shown last, while a one-shot plays.
	private List<BoneTransform> mShown = new .() ~ delete _;

	/// Plays `clip` over the pose, BORROWED (it must outlive the play). A one-shot already
	/// playing gives way at once: the pose it showed is held and faded from over this one's
	/// blend-in, so the change does not snap.
	public void PlayOneShot(AnimationClip clip, OneShotSettings settings)
	{
		if (clip == null)
			return;
		if ((mClip != null) && (mWeight > 0.0f) && !mShown.IsEmpty)
		{
			FadeFrom(mShown, settings.BlendIn);
			// The held pose carries the change; this one is in at once.
			mWeight = 1.0f;
		}
		else
			mWeight = (settings.BlendIn > 0.0f) ? 0.0f : 1.0f;
		mClip = clip;
		mSettings = settings;
		mSettings.Speed = (settings.Speed > 0.0f) ? settings.Speed : 1.0f;
		mTime = 0.0f;
		mStopping = false;
	}

	/// Blends the one-shot out over `blendOut` seconds from where it is now (0: at once). It
	/// ends, and Update says so, once it is out.
	public void StopOneShot(float blendOut)
	{
		if (mClip == null)
			return;
		if ((blendOut <= 0.0f) || (mWeight <= 0.0f))
		{
			mWeight = 0.0f;
			mEndedNow = true;
			mClip = null;
			return;
		}
		mStopping = true;
		mStopFrom = mWeight;
		mStopLeft = blendOut;
		mStopSeconds = blendOut;
	}

	/// Holds `pose` and fades from it into the pose underneath over `seconds` (0: no fade).
	public void FadeFrom(Span<BoneTransform> pose, float seconds)
	{
		if ((seconds <= 0.0f) || pose.IsEmpty)
		{
			mHoldLeft = 0.0f;
			return;
		}
		mHeld.Count = pose.Length;
		for (int i < pose.Length)
			mHeld[i] = pose[i];
		mHoldLeft = seconds;
		mHoldSeconds = seconds;
	}

	/// From the play until it has blended out.
	public bool IsPlayingOneShot => mClip != null;
	public AnimationClip OneShotClip => mClip;
	/// How much of the one-shot shows over the pose now (0 to 1).
	public float OneShotWeight => (mClip != null) ? mWeight : 0.0f;
	/// Whether its player must update it: a one-shot playing, a fade under way, or a stop at
	/// once whose end Update has still to report.
	public bool Active => (mClip != null) || (mHoldLeft > 0.0f) || mEndedNow;

	/// Advances by `deltaTime`. True when a one-shot ended in this step (it played its last
	/// loop and blended out, or a stop finished blending it out).
	public bool Update(float deltaTime)
	{
		let ended = mEndedNow;
		mEndedNow = false;
		if (mHoldLeft > 0.0f)
			mHoldLeft = Max(0.0f, mHoldLeft - deltaTime);
		if (mClip == null)
			return ended;

		mTime += deltaTime * mSettings.Speed;
		if (mStopping)
		{
			mStopLeft = Max(0.0f, mStopLeft - deltaTime);
			mWeight = mStopFrom * (mStopLeft / mStopSeconds);
			if (mStopLeft <= 0.0f)
			{
				mClip = null;
				return true;
			}
			return ended;
		}
		let total = TotalSeconds();
		if ((total >= 0.0f) && (mTime >= total))
		{
			mWeight = 0.0f;
			mClip = null;
			return true;
		}
		// In over BlendIn from the start; out over BlendOut before the end (in real seconds,
		// so a fast one-shot blends as long as a slow one).
		let elapsed = mTime / mSettings.Speed;
		var weight = (mSettings.BlendIn > 0.0f) ? Min(1.0f, elapsed / mSettings.BlendIn) : 1.0f;
		if ((total >= 0.0f) && (mSettings.BlendOut > 0.0f))
		{
			let left = (total - mTime) / mSettings.Speed;
			weight = Min(weight, left / mSettings.BlendOut);
		}
		mWeight = Clamp(weight, 0.0f, 1.0f);
		return ended;
	}

	/// Lays the overlay over `pose` (the player's own, in; what to show, out): the held pose
	/// fading into it, then the one-shot blended over that by its weight.
	public void Apply(Skeleton skeleton, Span<BoneTransform> pose)
	{
		if ((mHoldLeft > 0.0f) && (mHoldSeconds > 0.0f))
		{
			// 1 just held, 0 faded out.
			let held = mHoldLeft / mHoldSeconds;
			let count = Min(pose.Length, mHeld.Count);
			for (int i < count)
				pose[i] = BoneTransform.Lerp(pose[i], mHeld[i], held);
		}
		if ((mClip != null) && (mWeight > 0.0f))
		{
			// The whole body (a bone the clip does not move takes its bind pose, as any clip's
			// sample does): a one-shot is a full-body look, not a layer of some bones.
			mSampled.Count = pose.Length;
			AnimationSampler.SampleClip(mClip, skeleton, ClipTime(), mSampled);
			for (int i < pose.Length)
				pose[i] = BoneTransform.Lerp(pose[i], mSampled[i], mWeight);
		}
		// What was shown, for a one-shot that takes over from this one.
		if (mClip != null)
		{
			mShown.Count = pose.Length;
			for (int i < pose.Length)
				mShown[i] = pose[i];
		}
	}

	/// All its plays, in clip seconds; -1 while it loops until stopped.
	private float TotalSeconds()
	{
		if (mClip == null)
			return 0.0f;
		if (mSettings.Loops < 0)
			return -1.0f;
		return mClip.Duration * (float)(mSettings.Loops + 1);
	}

	/// Where in the clip it is: each play from its start, the last held at its end.
	private float ClipTime()
	{
		let duration = mClip.Duration;
		if (duration <= 0.0f)
			return 0.0f;
		let total = TotalSeconds();
		if ((total >= 0.0f) && (mTime >= total))
			return duration;
		var t = mTime;
		while (t >= duration)
			t -= duration;
		return t;
	}
}
