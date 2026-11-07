using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Engine.Gameplay;

namespace NativeSample;

/// The round ran out: what Arena emits on its run when its clock reaches zero.
struct ArenaTimeUp
{
	/// The limit the round had.
	public float TimeLimit;

	public this(float timeLimit)
	{
		TimeLimit = timeLimit;
	}
}

/// The reference game's level: a round clock for a scene that turns it on. It counts its time
/// limit down while the scene simulates and, at zero, logs it once and emits ArenaTimeUp; each
/// start (a play, or Active turned on again) begins a full round.
[Level("nativesample.arena")]
[DisplayName("Arena")]
[Category("Native Sample")]
[Description("A round clock: counts its time limit down while the scene plays, and says when it runs out.")]
class Arena : Level
{
	[DisplayName("Time Limit"), Description("The round's length, in seconds.")]
	public float TimeLimit = 60.0f;

	/// The seconds left in the round. Runtime state, neither saved nor shown.
	private float mRemaining = 0.0f;
	/// The round ran out, and that was said.
	private bool mTimeUp = false;

	/// The seconds left in the round; nought once it ran out.
	public float Remaining => mRemaining;
	public bool TimeUp => mTimeUp;

	protected override void OnStart()
	{
		mRemaining = TimeLimit;
		mTimeUp = false;
	}

	protected override void OnUpdate(float dt)
	{
		if (mTimeUp)
			return;
		mRemaining -= dt;
		if (mRemaining > 0.0f)
			return;
		mRemaining = 0.0f;
		mTimeUp = true;
		GlobalLog(.Information, scope $"NativeSample: the arena's {TimeLimit} seconds are up");
		Emit(ArenaTimeUp(TimeLimit));
	}
}
