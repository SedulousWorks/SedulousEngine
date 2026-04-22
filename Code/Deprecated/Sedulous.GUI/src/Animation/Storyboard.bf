using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Entry in a storyboard timeline.
public struct StoryboardEntry
{
	public Animation Animation;
	public float BeginTime;    // When to start (relative to storyboard start)
}

/// Sequences multiple animations with timing control.
public class Storyboard
{
	private List<StoryboardEntry> mEntries = new .() ~ delete _;
	private List<Animation> mOwnedAnimations = new .() ~ DeleteContainerAndItems!(_);
	private float mElapsedTime = 0;
	private AnimationState mState = .Pending;
	private ElementHandle<UIElement> mDefaultTarget;

	// Events
	private EventAccessor<delegate void(Storyboard)> mCompleted = new .() ~ delete _;

	/// Current state.
	public AnimationState State => mState;

	/// Whether the storyboard is active.
	public bool IsActive => mState == .Running || mState == .Paused;

	/// Total duration of the storyboard.
	public float TotalDuration
	{
		get
		{
			float maxEnd = 0;
			for (let entry in mEntries)
			{
				let endTime = entry.BeginTime + entry.Animation.Duration + entry.Animation.Delay;
				if (endTime > maxEnd)
					maxEnd = endTime;
			}
			return maxEnd;
		}
	}

	/// Event fired when all animations complete.
	public EventAccessor<delegate void(Storyboard)> Completed => mCompleted;

	/// Sets the default target for animations that don't have one.
	public void SetTarget(UIElement target)
	{
		mDefaultTarget = target;
	}

	/// Adds an animation to the storyboard at the specified begin time.
	/// The storyboard takes ownership of the animation.
	public void Add(Animation animation, float beginTime = 0)
	{
		mOwnedAnimations.Add(animation);
		mEntries.Add(.() { Animation = animation, BeginTime = beginTime });
	}

	/// Adds an animation to start when another animation completes.
	public void AddAfter(Animation animation, Animation after)
	{
		float afterEndTime = 0;
		for (let entry in mEntries)
		{
			if (entry.Animation == after)
			{
				afterEndTime = entry.BeginTime + after.Duration + after.Delay;
				break;
			}
		}
		Add(animation, afterEndTime);
	}

	/// Starts the storyboard.
	public void Start()
	{
		mElapsedTime = 0;
		mState = .Running;

		// Set default targets for animations without one
		// and start animations that begin at time 0
		for (let entry in mEntries)
		{
			if (entry.Animation.Target == null)
			{
				let defaultTarget = mDefaultTarget.TryResolve();
				if (defaultTarget != null)
					entry.Animation.SetTarget(defaultTarget);
			}

			// Start animations with BeginTime=0 immediately
			if (entry.BeginTime == 0 && entry.Animation.State == .Pending)
				entry.Animation.Start();
		}
	}

	/// Pauses the storyboard.
	public void Pause()
	{
		if (mState == .Running)
		{
			mState = .Paused;
			for (let entry in mEntries)
				entry.Animation.Pause();
		}
	}

	/// Resumes the storyboard.
	public void Resume()
	{
		if (mState == .Paused)
		{
			mState = .Running;
			for (let entry in mEntries)
				entry.Animation.Resume();
		}
	}

	/// Cancels the storyboard.
	public void Cancel()
	{
		mState = .Cancelled;
		for (let entry in mEntries)
			entry.Animation.Cancel();
	}

	/// Updates the storyboard. Called by AnimationManager.
	/// Returns true if storyboard should continue, false if complete/cancelled.
	public bool Update(float deltaTime)
	{
		if (mState != .Running)
			return mState == .Paused;

		let previousTime = mElapsedTime;
		mElapsedTime += deltaTime;

		bool anyActive = false;

		for (let entry in mEntries)
		{
			// Check if animation should start this frame
			bool startedThisFrame = false;
			if (previousTime < entry.BeginTime && mElapsedTime >= entry.BeginTime)
			{
				if (entry.Animation.State == .Pending)
				{
					entry.Animation.Start();
					startedThisFrame = true;
				}
			}

			// Update running animations
			if (entry.Animation.State == .Running)
			{
				// If animation started this frame, only give it the time since its begin time
				float animDelta = startedThisFrame ? (mElapsedTime - entry.BeginTime) : deltaTime;
				entry.Animation.Update(animDelta);
				// Only mark as active if still running after update
				if (entry.Animation.State == .Running)
					anyActive = true;
			}
			else if (entry.Animation.State == .Pending && mElapsedTime < entry.BeginTime)
			{
				anyActive = true; // Animation hasn't started yet
			}
		}

		if (!anyActive)
		{
			mState = .Completed;
			mCompleted.[Friend]Invoke(this);
			return false;
		}

		return true;
	}
}
