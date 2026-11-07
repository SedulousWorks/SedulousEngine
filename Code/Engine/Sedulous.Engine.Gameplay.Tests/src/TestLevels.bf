using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A level that overrides every hook, logging each into the lifecycle log as "G.<call> ", with
/// fields of the kinds a block holds, runtime state of its own, a listener for doors from its
/// OnStart, and hooks a test sets to act from inside a call.
[Level("test.gauntlet"), DisplayName("Gauntlet"), Category("Tests")]
class Gauntlet : Level
{
	/// Run after the call is logged, when set. BORROWED: a test's scoped delegate, which the
	/// test clears before it goes.
	public static delegate void(Gauntlet level) StartHook = null;
	public static delegate void(Gauntlet level) UpdateHook = null;

	public float TimeLimit = 30.0f;
	public int32 Rounds = 3;
	public String Title = new .("gauntlet") ~ delete _;

	private float mElapsed = 0.0f;
	private int mFixedCount = 0;
	private int32 mDoors = 0;
	private bool mListening = false;

	/// The time its updates were handed, summed: runtime state, neither saved nor shown.
	public float Elapsed => mElapsed;
	public int FixedCount => mFixedCount;
	/// The doors heard, summed.
	public int32 Doors => mDoors;
	/// What Listen answered at the last start: false outside a run.
	public bool Listening => mListening;

	protected override void OnStart()
	{
		LifecycleLog.Text.Append("G.Start ");
		mListening = Listen<DoorOpened>(new [=this] (evt) =>
			{
				mDoors += evt.Door;
				LifecycleLog.Text.AppendF("G.Door{} ", evt.Door);
			});
		if (StartHook != null)
			StartHook(this);
	}

	protected override void OnUpdate(float dt)
	{
		LifecycleLog.Text.Append("G.Update ");
		mElapsed += dt;
		if (UpdateHook != null)
			UpdateHook(this);
	}

	protected override void OnFixedStep(float dt)
	{
		LifecycleLog.Text.Append("G.Fixed ");
		mFixedCount++;
	}

	protected override void OnStop()
	{
		LifecycleLog.Text.Append("G.Stop ");
	}
}

/// A second level with a field of its own and no hooks: its block is Active and Laps.
[Level("test.trial")]
class Trial : Level
{
	public int32 Laps = 2;
}
