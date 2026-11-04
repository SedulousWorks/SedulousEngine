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
	private bool mAsksForFrames = true;

	/// OWNERSHIP of `tick` transfers. A clock (`asksForFrames` false) runs every GUI update but
	/// asks for no frames itself, as for a timer whose effects invalidate what they change.
	public this(Tick tick, bool asksForFrames = true)
	{
		mTick = tick;
		mAsksForFrames = asksForFrames;
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
	public override bool AsksForFrames => mAsksForFrames;
}
