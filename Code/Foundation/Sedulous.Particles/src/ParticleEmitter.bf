namespace Sedulous.Particles;

/// Spawn TIMING only. It answers how many particles are due this frame and spawns none of
/// them, which is what keeps the emission window, the bursts and the budget in one place.
class ParticleEmitter
{
	public EmissionMode Mode = .Continuous;
	/// Particles per second, for the continuous modes.
	public float SpawnRate = 10.0f;
	public int32 BurstCount = 0;
	/// Seconds between bursts. Nought or less means ONE burst, on the first frame.
	public float BurstInterval = 0.0f;
	/// How many bursts before stopping. Nought is forever.
	public int32 BurstCycles = 0;
	public bool IsEmitting = true;
	/// The emission window in seconds. Nought emits forever.
	public float Duration = 0.0f;
	/// Whether the window restarts when it runs out, rather than emitting once and stopping.
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
	/// many particles come out.
	public int32 CalculateSpawnCount(float deltaTime)
	{
		if (!IsEmitting)
			return 0;

		if (Duration > 0.0f)
		{
			mCycleTime += deltaTime;
			if (mCycleTime >= Duration)
			{
				if (!Looping)
					return 0;
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
			mSpawnAccumulator += SpawnRate * deltaTime;
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
					count += BurstCount;
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
					count += BurstCount;
					mBurstTimer -= BurstInterval;
					mBurstCyclesCompleted++;
				}
			}
		}

		return count;
	}

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
