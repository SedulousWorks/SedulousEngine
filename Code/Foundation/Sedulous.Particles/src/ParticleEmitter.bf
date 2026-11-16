using System;
using Sedulous.Core;

namespace Sedulous.Particles;

/// Spawn TIMING only. It answers how many particles are due this frame and spawns none of
/// them, which is what keeps the emission window, the bursts and the budget in one place.
[Scriptable(.AllPublic)]
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
class ParticleEmitter
{
	public EmissionMode Mode = .Continuous;
	// Each row where it does something: the spawn rate in the continuous modes, the bursts in the
	// burst modes (VisibleWhen of the mode's raw value).
	/// Particles per second, for the continuous modes.
	[VisibleWhen("Mode=0,2"), Description("Particles a second")]
	public float SpawnRate = 10.0f;
	[VisibleWhen("Mode=1,2")]
	public int32 BurstCount = 0;
	/// Seconds between bursts. Nought or less means ONE burst, on the first frame.
	[VisibleWhen("Mode=1,2"), Description("Seconds between bursts; 0 bursts once")]
	public float BurstInterval = 0.0f;
	/// How many bursts before stopping. Nought is forever.
	[VisibleWhen("Mode=1,2"), Description("Bursts in all; 0 bursts on and on")]
	public int32 BurstCycles = 0;
	[DisplayName("Emits"), Description("Off: it emits only when another system's sub-emitter link spawns it")]
	public bool IsEmitting = true;
	/// The emission window in seconds. Nought emits forever.
	[Description("Seconds it emits; 0 emits on and on")]
	public float Duration = 0.0f;
	/// Whether the window restarts when it runs out, rather than emitting once and stopping.
	[Description("With a duration: emits for it again and again")]
	public bool Looping = true;

	private float mCycleTime = 0.0f;
	private float mSpawnAccumulator = 0.0f;
	private float mBurstTimer = 0.0f;
	private int32 mBurstCyclesCompleted = 0;
	private bool mSingleBurstDone = false;

	/// How many particles are due this frame.
	///
	/// The continuous rate is ACCUMULATED rather than rounded per frame, so a rate below one
	/// per frame still emits at the right average and a frame rate change does not change how
	/// many particles come out. `rateScale` thins the emission (level of detail): applied to the
	/// rate before it gathers, so a slow emitter at half detail still spawns, at half its rate.
	public int32 CalculateSpawnCount(float deltaTime, float rateScale = 1.0f)
	{
		if (!IsEmitting)
			return 0;

		if (Duration > 0.0f)
		{
			mCycleTime += deltaTime;
			if (mCycleTime >= Duration)
			{
				if (!Looping)
				{
					IsEmitting = false; // a one-shot done: the effect can finish
					return 0;
				}
				// A loop rather than a modulo, so a step longer than the whole window still
				// lands inside it.
				while (mCycleTime >= Duration)
					mCycleTime -= Duration;
				// The new cycle re-arms the bursts, which is what makes a looping one-shot
				// burst fire again.
				mSingleBurstDone = false;
				mBurstCyclesCompleted = 0;
			}
		}

		int32 count = 0;

		if ((Mode == .Continuous) || (Mode == .ContinuousAndBurst))
		{
			mSpawnAccumulator += SpawnRate * rateScale * deltaTime;
			let whole = (int32)mSpawnAccumulator;
			count += whole;
			// The fraction is KEPT, which is the whole point of the accumulator.
			mSpawnAccumulator -= (float)whole;
		}

		if ((Mode == .Burst) || (Mode == .ContinuousAndBurst))
		{
			if (BurstInterval <= 0.0f)
			{
				if (!mSingleBurstDone)
				{
					count += ScaledBurst(rateScale);
					mSingleBurstDone = true;
				}
			}
			else
			{
				mBurstTimer += deltaTime;
				// A while rather than an if, so a long step fires every burst it covers.
				while ((mBurstTimer >= BurstInterval)
					&& ((BurstCycles == 0) || (mBurstCyclesCompleted < BurstCycles)))
				{
					count += ScaledBurst(rateScale);
					mBurstTimer -= BurstInterval;
					mBurstCyclesCompleted++;
				}
			}
		}

		return count;
	}

	/// A one-shot whose duration has run out (its cycle starts over on Reset).
	public bool CycleDone => (Duration > 0.0f) && !Looping && (mCycleTime >= Duration);

	/// A burst thinned by the level of detail, rounded: a burst of one at half detail still fires.
	private int32 ScaledBurst(float rateScale)
		=> (rateScale >= 1.0f) ? BurstCount : (int32)((float)BurstCount * rateScale + 0.5f);

	/// Forgets the timing state, leaving the configuration alone.
	public void Reset()
	{
		mSpawnAccumulator = 0.0f;
		mBurstTimer = 0.0f;
		mBurstCyclesCompleted = 0;
		mSingleBurstDone = false;
		mCycleTime = 0.0f;
	}
}
