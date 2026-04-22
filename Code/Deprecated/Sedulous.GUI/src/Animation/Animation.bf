using System;
using Sedulous.Core.Mathematics;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Animation state enumeration.
public enum AnimationState
{
	Pending,    // Not yet started
	Running,    // Currently playing
	Paused,     // Paused mid-animation
	Completed,  // Finished (reached end)
	Cancelled   // Stopped before completion
}

/// Fill behavior after animation completes.
public enum FillBehavior
{
	HoldEnd,    // Keep the final value (default)
	Reset       // Reset to original value
}

/// Base class for all property animations.
public abstract class Animation
{
	// Target element (weak reference via handle)
	protected ElementHandle<UIElement> mTarget;

	// Timing
	protected float mDuration = 0.3f;           // Duration in seconds
	protected float mDelay = 0.0f;              // Delay before starting
	protected float mElapsedTime = 0.0f;        // Current elapsed time
	protected float mDelayElapsed = 0.0f;       // Elapsed delay time

	// Easing
	protected EasingFunction mEasingFunction = Easings.EaseInOutCubic;

	// State
	protected AnimationState mState = .Pending;
	protected FillBehavior mFillBehavior = .HoldEnd;

	// Looping
	protected bool mIsLooping = false;
	protected int mLoopCount = 0;              // 0 = infinite, >0 = specific count
	protected int mCurrentLoop = 0;
	protected bool mAutoReverse = false;       // Ping-pong animation
	protected bool mIsReversing = false;       // Currently in reverse pass

	// Events
	private EventAccessor<delegate void(Animation)> mCompleted = new .() ~ delete _;
	private EventAccessor<delegate void(Animation)> mCancelled = new .() ~ delete _;

	/// Duration of the animation in seconds.
	public float Duration
	{
		get => mDuration;
		set => mDuration = Math.Max(0.001f, value);
	}

	/// Delay before the animation starts.
	public float Delay
	{
		get => mDelay;
		set => mDelay = Math.Max(0, value);
	}

	/// The easing function to use.
	public EasingFunction EasingFunction
	{
		get => mEasingFunction;
		set => mEasingFunction = value ?? Easings.EaseInLinear;
	}

	/// Current animation state.
	public AnimationState State => mState;

	/// Whether the animation is currently active (Running or Paused).
	public bool IsActive => mState == .Running || mState == .Paused;

	/// Whether animation should loop.
	public bool IsLooping
	{
		get => mIsLooping;
		set => mIsLooping = value;
	}

	/// Number of times to loop (0 = infinite).
	public int LoopCount
	{
		get => mLoopCount;
		set => mLoopCount = Math.Max(0, value);
	}

	/// Whether to reverse animation on each loop (ping-pong).
	public bool AutoReverse
	{
		get => mAutoReverse;
		set => mAutoReverse = value;
	}

	/// Behavior when animation completes.
	public FillBehavior FillBehavior
	{
		get => mFillBehavior;
		set => mFillBehavior = value;
	}

	/// Progress from 0.0 to 1.0 (with easing applied).
	public float Progress
	{
		get
		{
			if (mDuration <= 0) return 1.0f;
			let rawProgress = Math.Clamp(mElapsedTime / mDuration, 0.0f, 1.0f);
			let easedProgress = mEasingFunction(rawProgress);
			return mIsReversing ? (1.0f - easedProgress) : easedProgress;
		}
	}

	/// Raw progress (0.0 to 1.0) without easing.
	public float RawProgress => mDuration > 0 ? Math.Clamp(mElapsedTime / mDuration, 0.0f, 1.0f) : 1.0f;

	/// Event fired when animation completes normally.
	public EventAccessor<delegate void(Animation)> Completed => mCompleted;

	/// Event fired when animation is cancelled.
	public EventAccessor<delegate void(Animation)> Cancelled => mCancelled;

	/// The target element (may be null if element was deleted).
	public UIElement Target => mTarget.TryResolve();

	/// Sets the target element.
	public void SetTarget(UIElement element)
	{
		mTarget = element;
	}

	/// Starts or restarts the animation.
	public void Start()
	{
		mElapsedTime = 0;
		mDelayElapsed = 0;
		mCurrentLoop = 0;
		mIsReversing = false;
		mState = .Running;
		OnStart();
	}

	/// Pauses the animation.
	public void Pause()
	{
		if (mState == .Running)
			mState = .Paused;
	}

	/// Resumes a paused animation.
	public void Resume()
	{
		if (mState == .Paused)
			mState = .Running;
	}

	/// Stops and cancels the animation.
	public void Cancel()
	{
		if (mState == .Running || mState == .Paused)
		{
			mState = .Cancelled;
			if (mFillBehavior == .Reset)
				OnReset();
			mCancelled.[Friend]Invoke(this);
		}
	}

	/// Updates the animation. Called by AnimationManager.
	/// Returns true if animation should continue, false if complete/cancelled.
	public bool Update(float deltaTime)
	{
		var deltaTime;
		if (mState != .Running)
			return mState == .Paused; // Paused animations stay active but don't update

		// Check if target is still valid
		if (mTarget.TryResolve() == null)
		{
			mState = .Cancelled;
			return false;
		}

		// Handle delay
		if (mDelayElapsed < mDelay)
		{
			mDelayElapsed += deltaTime;
			if (mDelayElapsed < mDelay)
				return true; // Still in delay
			// Delay just completed, use remaining time for animation
			deltaTime = mDelayElapsed - mDelay;
		}

		// Update elapsed time
		mElapsedTime += deltaTime;

		// Apply the current value
		OnUpdate(Progress);

		// Check completion
		if (mElapsedTime >= mDuration)
		{
			if (mAutoReverse && !mIsReversing)
			{
				// Start reverse pass
				mIsReversing = true;
				mElapsedTime = 0;
				return true;
			}

			if (mIsLooping && (mLoopCount == 0 || mCurrentLoop < mLoopCount - 1))
			{
				// Loop
				mCurrentLoop++;
				mElapsedTime = 0;
				mIsReversing = false;
				return true;
			}

			// Animation complete
			mState = .Completed;
			OnComplete();
			mCompleted.[Friend]Invoke(this);
			return false;
		}

		return true;
	}

	/// Called when animation starts. Override to capture initial values.
	protected virtual void OnStart() { }

	/// Called each frame to apply interpolated value.
	protected abstract void OnUpdate(float progress);

	/// Called when animation completes normally.
	protected virtual void OnComplete() { }

	/// Called when animation is cancelled with FillBehavior.Reset.
	protected virtual void OnReset() { }
}
