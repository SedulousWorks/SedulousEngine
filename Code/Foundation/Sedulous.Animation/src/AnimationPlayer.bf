namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Playback state for an animation.
public enum PlaybackState
{
	Stopped,
	Playing,
	Paused
}

/// Manages animation playback for a single skeleton instance.
public class AnimationPlayer
{
	/// The skeleton this player animates.
	public Skeleton Skeleton { get; private set; }

	/// Current animation clip being played.
	public AnimationClip CurrentClip { get; private set; }

	/// Current playback time in seconds.
	/// Setting this value marks the skinning matrices as dirty.
	public float CurrentTime
	{
		get => mCurrentTime;
		set
		{
			if (mCurrentTime != value)
			{
				mCurrentTime = value;
				mMatricesDirty = true;
			}
		}
	}
	private float mCurrentTime;

	/// Playback speed multiplier (1.0 = normal speed).
	public float Speed = 1.0f;

	/// Current playback state.
	public PlaybackState State { get; private set; } = .Stopped;

	/// Current local bone transforms.
	private BoneTransform[] mLocalPoses ~ delete _;

	/// Current skinning matrices (for upload to GPU).
	private Matrix[] mSkinningMatrices ~ delete _;

	/// Previous frame skinning matrices (for motion blur).
	private Matrix[] mPrevSkinningMatrices ~ delete _;

	/// Whether the skinning matrices have been updated this frame.
	private bool mMatricesDirty = true;

	/// Previous frame's playback time (for event detection).
	private float mPrevTime;

	/// Animation event callback (owned).
	private AnimationEventHandler mEventHandler ~ delete _;

	/// Creates an animation player for the specified skeleton.
	public this(Skeleton skeleton)
	{
		Skeleton = skeleton;
		let boneCount = skeleton.BoneCount;

		mLocalPoses = new BoneTransform[boneCount];
		mSkinningMatrices = new Matrix[boneCount];
		mPrevSkinningMatrices = new Matrix[boneCount];

		// Initialize to bind pose
		ResetToBind();
	}

	/// Plays the specified animation clip.
	public void Play(AnimationClip clip, bool restart = true)
	{
		CurrentClip = clip;
		if (restart)
		{
			CurrentTime = 0;
			mPrevTime = 0;
		}
		State = .Playing;
		mMatricesDirty = true;
	}

	/// Stops playback and resets to bind pose.
	public void Stop()
	{
		State = .Stopped;
		CurrentTime = 0;
		mPrevTime = 0;
		CurrentClip = null;
		ResetToBind();
	}

	/// Pauses playback at current time.
	public void Pause()
	{
		if (State == .Playing)
			State = .Paused;
	}

	/// Resumes playback from current time.
	public void Resume()
	{
		if (State == .Paused)
			State = .Playing;
	}

	/// Sets the animation event handler. The player takes ownership of the delegate.
	public void SetEventHandler(AnimationEventHandler handler)
	{
		delete mEventHandler;
		mEventHandler = handler;
	}

	/// Resets all poses to the skeleton's bind pose.
	public void ResetToBind()
	{
		for (int i = 0; i < Skeleton.BoneCount; i++)
		{
			let bone = Skeleton.Bones[i];
			if (bone != null)
				mLocalPoses[i] = bone.LocalBindPose;
			else
				mLocalPoses[i] = .Identity;
		}
		mMatricesDirty = true;
	}

	/// Updates the animation by the given delta time.
	/// @param deltaTime Time elapsed since last update in seconds.
	public void Update(float deltaTime)
	{
		if (State != .Playing || CurrentClip == null)
			return;

		// Store previous matrices for motion blur
		mSkinningMatrices.CopyTo(mPrevSkinningMatrices);

		let prevTime = mPrevTime;

		// Advance time (raw, before wrapping)
		mCurrentTime += deltaTime * Speed;

		// Fire events before wrapping (so we can detect loop crossings)
		if (mEventHandler != null && CurrentClip.Events.Count > 0)
			CurrentClip.FireEvents(prevTime, mCurrentTime, mEventHandler);

		// Handle looping or clamping
		if (CurrentClip.IsLooping)
		{
			if (CurrentClip.Duration > 0)
			{
				while (mCurrentTime >= CurrentClip.Duration)
					mCurrentTime -= CurrentClip.Duration;
				while (mCurrentTime < 0)
					mCurrentTime += CurrentClip.Duration;
			}
		}
		else
		{
			if (mCurrentTime >= CurrentClip.Duration)
			{
				mCurrentTime = CurrentClip.Duration;
				State = .Stopped;
			}
			else if (mCurrentTime < 0)
			{
				mCurrentTime = 0;
				State = .Stopped;
			}
		}

		mPrevTime = mCurrentTime;
		mMatricesDirty = true;
	}

	/// Evaluates the current animation state and updates skinning matrices.
	/// Call this after Update() and before rendering.
	public void Evaluate()
	{
		if (!mMatricesDirty)
			return;

		if (CurrentClip != null)
		{
			// Sample the animation
			AnimationSampler.SampleClip(CurrentClip, Skeleton, CurrentTime, mLocalPoses);
		}

		// Compute skinning matrices
		Skeleton.ComputeSkinningMatrices(mLocalPoses, mSkinningMatrices);

		mMatricesDirty = false;
	}

	/// Gets the current skinning matrices for GPU upload.
	/// Returns a span of matrices, one per bone.
	public Span<Matrix> GetSkinningMatrices()
	{
		Evaluate();
		return mSkinningMatrices;
	}

	/// Gets the previous frame's skinning matrices for motion blur.
	public Span<Matrix> GetPrevSkinningMatrices()
	{
		return mPrevSkinningMatrices;
	}

	/// Overrides the skinning matrices directly (used by graph animation to push results).
	public void OverrideSkinningMatrices(Span<Matrix> current, Span<Matrix> prev)
	{
		let count = Math.Min(current.Length, mSkinningMatrices.Count);
		for (int i = 0; i < count; i++)
			mSkinningMatrices[i] = current[i];
		let prevCount = Math.Min(prev.Length, mPrevSkinningMatrices.Count);
		for (int i = 0; i < prevCount; i++)
			mPrevSkinningMatrices[i] = prev[i];
		mMatricesDirty = false;
	}

	/// Gets the current local bone transforms.
	public Span<BoneTransform> GetLocalPoses()
	{
		return mLocalPoses;
	}

	/// Returns the current animation pose as a view.
	public AnimationPose GetPose()
	{
		return .(mLocalPoses);
	}

	/// Sets a specific bone's local transform (for procedural animation).
	public void SetBonePose(int32 boneIndex, BoneTransform pose)
	{
		if (boneIndex >= 0 && boneIndex < mLocalPoses.Count)
		{
			mLocalPoses[boneIndex] = pose;
			mMatricesDirty = true;
		}
	}

	/// Blends another animation on top of the current state.
	/// @param clip The clip to blend in.
	/// @param time The time to sample the blend clip at.
	/// @param weight Blend weight (0 = no effect, 1 = fully replace).
	public void BlendAnimation(AnimationClip clip, float time, float weight)
	{
		if (clip == null || weight <= 0)
			return;

		// Sample the blend clip
		BoneTransform[] blendPoses = scope BoneTransform[Skeleton.BoneCount];
		AnimationSampler.SampleClip(clip, Skeleton, time, blendPoses);

		// Blend with current poses
		for (int i = 0; i < Skeleton.BoneCount; i++)
		{
			mLocalPoses[i] = BoneTransform.Lerp(mLocalPoses[i], blendPoses[i], weight);
		}

		mMatricesDirty = true;
	}
}
