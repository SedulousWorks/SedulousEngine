using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// Single clip playback for ONE skeleton instance: the clock, the looping, the events, and
/// the skinning matrices it all turns into.
///
/// The skeleton and the clip are BORROWED. A skeleton is shared by every instance wearing
/// it, and a clip by every instance playing it.
class AnimationPlayer
{
	private Skeleton mSkeleton;
	/// BORROWED.
	private AnimationClip mCurrentClip = null;

	private float mCurrentTime = 0.0f;
	private float mPrevTime = 0.0f;
	private PlaybackState mState = .Stopped;

	/// The matrices are recomputed LAZILY, since a scrub and a set of a bone both move the
	/// pose and only the frame that draws it needs the answer.
	private bool mMatricesDirty = true;

	private List<BoneTransform> mLocalPoses = new .() ~ delete _;
	/// The sampled pose after the modifiers. The sampled pose itself is never modified, so a
	/// modifier never compounds on its own last result.
	private List<BoneTransform> mFinalPoses = new .() ~ delete _;
	private PoseModifierStack mModifiers = new .() ~ delete _;
	/// Since the last ConsumeRootMotion.
	private RootMotionDelta mRootMotion = .();
	private List<Float4x4> mSkinningMatrices = new .() ~ delete _;
	/// Last frame's, which is what a motion vector is the difference of.
	private List<Float4x4> mPrevSkinningMatrices = new .() ~ delete _;

	/// OWNED, and replaced rather than added to: one player drives one thing.
	private AnimationEventHandler mEventHandler = null ~ delete _;

	/// The playback rate. Negative runs the clip backwards.
	public float Speed = 1.0f;

	public this(Skeleton skeleton)
	{
		mSkeleton = skeleton;

		let boneCount = skeleton.BoneCount;
		mLocalPoses.Count = boneCount;
		mFinalPoses.Count = boneCount;
		mSkinningMatrices.Count = boneCount;
		mPrevSkinningMatrices.Count = boneCount;
		for (int i < boneCount)
		{
			mSkinningMatrices[i] = Float4x4.Identity();
			mPrevSkinningMatrices[i] = Float4x4.Identity();
		}
		ResetToBind();
	}

	public Skeleton GetSkeleton => mSkeleton;
	public AnimationClip CurrentClip => mCurrentClip;
	public PlaybackState State => mState;
	public float CurrentTime => mCurrentTime;

	/// Scrubbing marks the matrices dirty rather than recomputing them, so a drag through a
	/// timeline costs one evaluation at the end and not one per mouse move.
	public void SetCurrentTime(float time)
	{
		if (mCurrentTime != time)
		{
			mCurrentTime = time;
			mMatricesDirty = true;
		}
	}

	/// Plays a clip, which is BORROWED. Restarting puts the clock back to the beginning.
	public void Play(AnimationClip clip, bool restart = true)
	{
		mCurrentClip = clip;
		if (restart)
		{
			mCurrentTime = 0.0f;
			mPrevTime = 0.0f;
		}
		mState = .Playing;
		mMatricesDirty = true;
	}

	public void Stop()
	{
		mState = .Stopped;
		mCurrentTime = 0.0f;
		mPrevTime = 0.0f;
		mCurrentClip = null;
		ResetToBind();
	}

	public void Pause()
	{
		if (mState == .Playing)
			mState = .Paused;
	}

	public void Resume()
	{
		if (mState == .Paused)
			mState = .Playing;
	}

	/// TAKES OWNERSHIP, replacing whatever was there.
	public void SetEventHandler(AnimationEventHandler handler)
	{
		delete mEventHandler;
		mEventHandler = handler;
	}

	/// Puts every local pose back to the skeleton's bind pose.
	public void ResetToBind()
	{
		for (int32 i = 0; (i < mSkeleton.BoneCount) && (i < mLocalPoses.Count); i++)
		{
			let bone = mSkeleton.GetBone(i);
			mLocalPoses[i] = (bone != null) ? bone.LocalBindPose : BoneTransform();
		}
		mMatricesDirty = true;
	}

	/// Advances the clock, fires whatever was crossed, then wraps or stops.
	public void Update(float deltaTime)
	{
		if ((mState != .Playing) || (mCurrentClip == null))
			return;

		// This frame's matrices become last frame's BEFORE the clock moves, which is what
		// makes a motion vector the difference between two drawn frames.
		for (int i < mSkinningMatrices.Count)
			mPrevSkinningMatrices[i] = mSkinningMatrices[i];

		let prevTime = mPrevTime;
		let startTime = mCurrentTime;
		mCurrentTime += deltaTime * Speed;
		// Root motion over the step, from the unwrapped times: a wrap is split at the end.
		mRootMotion = RootMotion.Compose(mRootMotion,
			RootMotion.ClipRootMotion(mCurrentClip, startTime, mCurrentTime, mCurrentClip.IsLooping));

		// The events fire BEFORE the wrap, so a crossing of the end is still visible as one.
		if ((mEventHandler != null) && !mCurrentClip.Events.IsEmpty)
			mCurrentClip.FireEvents(prevTime, mCurrentTime, mEventHandler);

		if (mCurrentClip.IsLooping)
		{
			if (mCurrentClip.Duration > 0.0f)
			{
				while (mCurrentTime >= mCurrentClip.Duration)
					mCurrentTime -= mCurrentClip.Duration;
				while (mCurrentTime < 0.0f)
					mCurrentTime += mCurrentClip.Duration;
			}
		}
		else if (mCurrentTime >= mCurrentClip.Duration)
		{
			mCurrentTime = mCurrentClip.Duration;
			mState = .Stopped;
		}
		else if (mCurrentTime < 0.0f)
		{
			mCurrentTime = 0.0f;
			mState = .Stopped;
		}

		mPrevTime = mCurrentTime;
		mMatricesDirty = true;
	}

	/// Samples the clip when its time moved, runs the pose modifiers over a copy of it, and
	/// computes the skinning matrices. With modifiers it runs every call: their targets move
	/// whether or not the clip does. The sampled pose stays as sampled (GetLocalPoses); the
	/// modified one is GetFinalPoses.
	public void Evaluate()
	{
		let modifying = !mModifiers.IsEmpty;
		if (!mMatricesDirty && !modifying)
			return;

		if (mMatricesDirty && (mCurrentClip != null))
			AnimationSampler.SampleClip(mCurrentClip, mSkeleton, mCurrentTime, mLocalPoses);

		if (modifying)
		{
			for (int i < mLocalPoses.Count)
				mFinalPoses[i] = mLocalPoses[i];
			mModifiers.Apply(mSkeleton, mFinalPoses);
			mSkeleton.ComputeSkinningMatrices(mFinalPoses, mSkinningMatrices);
		}
		else
			mSkeleton.ComputeSkinningMatrices(mLocalPoses, mSkinningMatrices);
		mMatricesDirty = false;
	}

	/// The root motion the clip carried since the last call (root-motion.md P1), composed over
	/// every Update between: zero when the clip extracts none. Reading it resets it.
	public RootMotionDelta ConsumeRootMotion()
	{
		let delta = mRootMotion;
		mRootMotion = .();
		return delta;
	}

	/// The modifiers run between the sample and the palette (inverse kinematics), BORROWED.
	public PoseModifierStack Modifiers => mModifiers;

	/// The pose the palette was last built from: the sampled pose changed by the modifiers, or
	/// the sampled pose itself when there are none.
	public Span<BoneTransform> GetFinalPoses() => mModifiers.IsEmpty ? mLocalPoses : mFinalPoses;

	/// The matrices to upload, evaluated first if anything moved.
	public Span<Float4x4> GetSkinningMatrices()
	{
		Evaluate();
		return mSkinningMatrices;
	}

	public Span<Float4x4> GetPrevSkinningMatrices() => mPrevSkinningMatrices;

	/// Pushes matrices computed elsewhere, which is how a graph drives a player's output
	/// without the player sampling anything itself.
	public void OverrideSkinningMatrices(Span<Float4x4> current, Span<Float4x4> prev)
	{
		let currentCount = Min(current.Length, mSkinningMatrices.Count);
		for (int i < currentCount)
			mSkinningMatrices[i] = current[i];

		let prevCount = Min(prev.Length, mPrevSkinningMatrices.Count);
		for (int i < prevCount)
			mPrevSkinningMatrices[i] = prev[i];

		mMatricesDirty = false;
	}

	public Span<BoneTransform> GetLocalPoses() => mLocalPoses;

	public AnimationPose GetPose() => .(GetLocalPoses());

	/// Sets one bone directly, which is what procedural animation writes through.
	public void SetBonePose(int32 boneIndex, BoneTransform pose)
	{
		if ((boneIndex >= 0) && (boneIndex < mLocalPoses.Count))
		{
			mLocalPoses[boneIndex] = pose;
			mMatricesDirty = true;
		}
	}

	/// Blends another clip ON TOP of the poses already there, which is how a one shot is
	/// layered over whatever is playing.
	public void BlendAnimation(AnimationClip clip, float time, float weight)
	{
		if ((clip == null) || (weight <= 0.0f))
			return;

		let blend = scope BoneTransform[mSkeleton.BoneCount];
		AnimationSampler.SampleClip(clip, mSkeleton, time, blend);

		let count = Min(mLocalPoses.Count, blend.Count);
		for (int i < count)
			mLocalPoses[i] = BoneTransform.Lerp(mLocalPoses[i], blend[i], weight);

		mMatricesDirty = true;
	}
}
