using System;

namespace Sedulous.GUI;

// The action a widget times itself with: TickAction, a function called each frame on its
// target's clock. What moves properties is the tweens' (Styling/Tween.bf), which took the place
// of eepp's Move, Fade, Scale, Delay, Runnable and Sequence actions.

/// Calls a function with each frame's elapsed time on its target's clock until the function
/// returns false (or the action is stopped): a widget's own timing with nothing to animate, a
/// caret's blink.
class TickAction : Sedulous.GUI.Action
{
	public typealias Tick = delegate bool(TimeSpan elapsed);

	private Tick mTick ~ delete _;
	private bool mDone = false;

	/// OWNERSHIP of `tick` transfers.
	public this(Tick tick)
	{
		mTick = tick;
	}

	public override void Start()
	{
		mDone = false;
	}

	public override void Stop()
	{
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		if (!mDone && ((mTick == null) || !mTick(elapsed)))
		{
			mDone = true;
			FireDone();
		}
	}

	public override bool IsDone => mDone;
	public override float CurrentProgress => mDone ? 1.0f : 0.0f;
	public override TimeSpan TotalTime => default;
}
