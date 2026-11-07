using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A coin taken: more than eight bytes, so a post carries a copy the bus owns.
struct CoinTaken
{
	public int32 Points;
	public EntityHandle By;
	public Float3 At;

	public this(int32 points, EntityHandle by, Float3 at)
	{
		Points = points;
		By = by;
		At = at;
	}
}

/// A door opened: four bytes, carried in the Variant itself.
struct DoorOpened
{
	public int32 Door;

	public this(int32 door)
	{
		Door = door;
	}
}

/// Listens to both events from its OnStart, logging each into the lifecycle log as
/// "C:<entity>.Coin<points>" and "C:<entity>.Door<door>", with a hook a test sets to act from
/// inside the coin handler.
[Behaviour("test.collector")]
class Collector : Behaviour
{
	/// Run after the coin is logged, when set. BORROWED: a test's scoped delegate, which the
	/// test clears before it goes.
	public static delegate void(Collector collector, CoinTaken evt) CoinHook = null;

	private int32 mScore = 0;
	private bool mListening = false;

	public int32 Score => mScore;
	/// What Listen answered at the start: false outside a run.
	public bool Listening => mListening;

	protected override void OnStart()
	{
		mListening = Listen<CoinTaken>(new [=this] (evt) =>
			{
				mScore += evt.Points;
				LifecycleLog.Add(this, "C", scope $"Coin{evt.Points}");
				if (CoinHook != null)
					CoinHook(this, evt);
			});
		Listen<DoorOpened>(new [=this] (evt) => { LifecycleLog.Add(this, "C", scope $"Door{evt.Door}"); });
	}
}
