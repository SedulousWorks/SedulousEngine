namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Emission mode for continuous spawning.
public enum EmissionMode : uint8
{
	/// Continuous emission at a fixed rate (particles/sec).
	Continuous,

	/// Burst emission (spawns BurstCount particles at intervals).
	Burst,

	/// Both continuous and burst emission.
	ContinuousAndBurst
}

/// Particle emitter - handles spawning logic only (rate, burst, shape).
/// Does NOT own simulation or behaviors. Those belong to ParticleSystem.
/// Multiple emitters can feed into the same ParticleSystem's stream container.
public class ParticleEmitter
{
	/// Emission mode.
	public EmissionMode Mode = .Continuous;

	/// Continuous spawn rate (particles/sec).
	public float SpawnRate = 10.0f;

	/// Burst count (particles per burst).
	public int32 BurstCount = 0;

	/// Time between bursts in seconds (0 = single burst on start).
	public float BurstInterval = 0;

	/// Number of burst cycles (0 = infinite).
	public int32 BurstCycles = 0;

	/// Whether this emitter is actively spawning.
	public bool IsEmitting = true;

	// --- Internal emission state ---
	private float mSpawnAccumulator = 0;
	private float mBurstTimer = 0;
	private int32 mBurstCyclesCompleted = 0;

	/// Calculates how many particles to spawn this frame.
	/// Does NOT actually spawn them - the ParticleSystem handles that.
	public int32 CalculateSpawnCount(float deltaTime)
	{
		if (!IsEmitting)
			return 0;

		int32 spawnCount = 0;

		// Continuous emission
		if (Mode == .Continuous || Mode == .ContinuousAndBurst)
		{
			if (SpawnRate > 0)
			{
				mSpawnAccumulator += SpawnRate * deltaTime;
				spawnCount = (int32)mSpawnAccumulator;
				mSpawnAccumulator -= (float)spawnCount;
			}
		}

		// Burst emission
		if (Mode == .Burst || Mode == .ContinuousAndBurst)
		{
			if (BurstCount > 0)
			{
				mBurstTimer += deltaTime;
				let canBurst = BurstCycles == 0 || mBurstCyclesCompleted < BurstCycles;

				if (canBurst)
				{
					if (BurstInterval <= 0)
					{
						if (mBurstCyclesCompleted == 0)
						{
							spawnCount += BurstCount;
							mBurstCyclesCompleted++;
						}
					}
					else
					{
						while (mBurstTimer >= BurstInterval &&
							   (BurstCycles == 0 || mBurstCyclesCompleted < BurstCycles))
						{
							spawnCount += BurstCount;
							mBurstTimer -= BurstInterval;
							mBurstCyclesCompleted++;
						}
					}
				}
			}
		}

		return spawnCount;
	}

	/// Resets emission state.
	public void Reset()
	{
		mSpawnAccumulator = 0;
		mBurstTimer = 0;
		mBurstCyclesCompleted = 0;
	}
}
