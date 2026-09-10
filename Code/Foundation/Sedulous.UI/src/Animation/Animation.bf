using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// The base of every property animation: a clock, a delay, an easing, and a repeat policy.
///
/// A subclass supplies only Apply, which is handed the eased progress. Everything about WHEN
/// that happens lives here, so a new animated property is a few lines rather than another
/// timing implementation to get subtly wrong.
abstract class Animation
{
	/// Fired once, when the animation finishes for good rather than at the end of a repeat.
	public Event<delegate void(Animation)> OnComplete ~ _.Dispose();

	private float mElapsed = 0.0f;
	private float mDuration = 0.0f;
	private float mDelay = 0.0f;
	private EasingFunction mEasing = null;
	private bool mIsRunning = false;
	private bool mIsComplete = false;
	private bool mAutoReverse = false;
	/// Nought plays once; -1 repeats forever.
	private int32 mRepeatCount = 0;
	private int32 mCurrentRepeat = 0;
	/// BORROWED: what this animates, for AnimationManager.CancelForView.
	private View mTarget = null;

	public this(float duration, EasingFunction easing = null)
	{
		mDuration = Max(duration, 0.0f);
		mEasing = easing;
	}

	public View Target
	{
		get => mTarget;
		set => mTarget = value;
	}

	/// One cycle's length in seconds.
	public float Duration
	{
		get => mDuration;
		set => mDuration = Max(value, 0.0f);
	}

	public float Delay
	{
		get => mDelay;
		set => mDelay = Max(value, 0.0f);
	}

	/// Null is linear.
	public EasingFunction Easing
	{
		get => mEasing;
		set => mEasing = value;
	}

	/// Plays backward on the odd repeats, so a pulse is one animation rather than two.
	public bool AutoReverse
	{
		get => mAutoReverse;
		set => mAutoReverse = value;
	}

	/// How many times to repeat AFTER the first play. Nought plays once, -1 forever.
	public int32 RepeatCount
	{
		get => mRepeatCount;
		set => mRepeatCount = value;
	}

	public bool IsRunning => mIsRunning;
	public bool IsComplete => mIsComplete;
	public float Elapsed => mElapsed;

	/// Starts, or resumes after a Stop. A finished animation stays finished until Reset.
	public void Start()
	{
		if (!mIsComplete)
			mIsRunning = true;
	}

	/// Pauses WITHOUT resetting, so Start picks up where it left off.
	public void Stop() => mIsRunning = false;

	public virtual void Reset()
	{
		mElapsed = 0;
		mCurrentRepeat = 0;
		mIsRunning = false;
		mIsComplete = false;
	}

	/// Advances the clock. Answers whether the animation is finished for good.
	public virtual bool Update(float deltaTime)
	{
		if (!mIsRunning || mIsComplete)
			return mIsComplete;

		mElapsed += deltaTime;

		if ((mDelay > 0) && (mElapsed < mDelay))
			return false;

		let activeTime = mElapsed - mDelay;

		// A zero duration snaps to the end rather than dividing by nought.
		if (mDuration <= 0)
		{
			Apply(1.0f);
			FinishCycle();
			return mIsComplete;
		}

		if (activeTime >= mDuration)
		{
			// The cycle ended. An auto reversing odd repeat ends where it started.
			Apply((mAutoReverse && ((mCurrentRepeat & 1) != 0)) ? 0.0f : 1.0f);
			FinishCycle();
			return mIsComplete;
		}

		var t = activeTime / mDuration;
		if (mAutoReverse && ((mCurrentRepeat & 1) != 0))
			t = 1.0f - t;

		Apply((mEasing != null) ? mEasing(t) : t);
		return false;
	}

	/// Applies the value at the eased progress, nought to one.
	protected abstract void Apply(float t);

	/// Marks the animation finished and fires OnComplete. For a subclass that overrides
	/// Update rather than Apply.
	protected void MarkComplete()
	{
		mIsRunning = false;
		mIsComplete = true;
		OnComplete(this);
	}

	private void FinishCycle()
	{
		if ((mRepeatCount == -1) || (mCurrentRepeat < mRepeatCount))
		{
			// Rewound to the END of the delay, not to nought: a delay is a lead in, not
			// something to sit through again on every repeat.
			mCurrentRepeat++;
			mElapsed = mDelay;
			return;
		}

		MarkComplete();
	}
}
