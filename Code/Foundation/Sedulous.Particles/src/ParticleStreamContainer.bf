namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Container that owns a set of particle streams.
/// Behaviors declare which streams they need; the container allocates them.
/// Provides typed accessors for well-known streams.
public class ParticleStreamContainer
{
	private ParticleStream[(int)ParticleStreamId.MaxStreams] mStreams;
	private int32 mCapacity;

	/// Number of alive particles (shared across all streams).
	public int32 AliveCount;

	/// Maximum particle capacity.
	public int32 Capacity => mCapacity;

	public this(int32 capacity)
	{
		mCapacity = capacity;
		AliveCount = 0;

		// Core streams always allocated
		EnsureStream(.Position, .Float3);
		EnsureStream(.Age, .Float);
		EnsureStream(.Lifetime, .Float);
	}

	/// Gets a stream by ID, or null if not allocated.
	public ParticleStream GetStream(ParticleStreamId id)
	{
		return mStreams[(int)id];
	}

	/// Gets a typed CPU stream by ID. Returns null if not allocated or not a CPU stream.
	public CPUStream<T> GetCPUStream<T>(ParticleStreamId id) where T : struct
	{
		let stream = mStreams[(int)id];
		if (stream == null) return null;
		return stream as CPUStream<T>;
	}

	/// Ensures a stream is allocated. No-op if already present.
	public void EnsureStream(ParticleStreamId id, StreamElementType elementType)
	{
		if (mStreams[(int)id] != null)
			return;

		// For now, always create CPU streams. GPU streams created by GPUSimulator.
		switch (elementType)
		{
		case .Float:
			mStreams[(int)id] = new CPUStream<float>(id, elementType, mCapacity);
		case .Float2:
			mStreams[(int)id] = new CPUStream<Vector2>(id, elementType, mCapacity);
		case .Float3:
			mStreams[(int)id] = new CPUStream<Vector3>(id, elementType, mCapacity);
		case .Float4:
			mStreams[(int)id] = new CPUStream<Vector4>(id, elementType, mCapacity);
		case .Int32:
			mStreams[(int)id] = new CPUStream<int32>(id, elementType, mCapacity);
		}
	}

	// ==================== Typed Accessors ====================

	/// Position stream (Vector3, always present).
	public CPUStream<Vector3> Positions => GetCPUStream<Vector3>(.Position);

	/// Age stream (float, always present).
	public CPUStream<float> Ages => GetCPUStream<float>(.Age);

	/// Lifetime stream (float, always present).
	public CPUStream<float> Lifetimes => GetCPUStream<float>(.Lifetime);

	/// Velocity stream (Vector3, allocated on demand).
	public CPUStream<Vector3> Velocities => GetCPUStream<Vector3>(.Velocity);

	/// StartVelocity stream (Vector3, allocated on demand).
	public CPUStream<Vector3> StartVelocities => GetCPUStream<Vector3>(.StartVelocity);

	/// Color stream (Vector4 RGBA, allocated on demand).
	public CPUStream<Vector4> Colors => GetCPUStream<Vector4>(.Color);

	/// Size stream (Vector2, allocated on demand).
	public CPUStream<Vector2> Sizes => GetCPUStream<Vector2>(.Size);

	/// Rotation stream (float radians, allocated on demand).
	public CPUStream<float> Rotations => GetCPUStream<float>(.Rotation);

	/// RotationSpeed stream (float rad/s, allocated on demand).
	public CPUStream<float> RotationSpeeds => GetCPUStream<float>(.RotationSpeed);

	// ==================== Particle Management ====================

	/// Gets the normalized life ratio [0, 1] for a particle.
	public float GetLifeRatio(int32 index)
	{
		let lifetime = Ages[index];
		let maxLife = Lifetimes[index];
		if (maxLife <= 0)
			return 1.0f;
		return Math.Min(lifetime / maxLife, 1.0f);
	}

	/// Swap-removes a particle at `index` with the last alive particle.
	public void SwapRemove(int32 index)
	{
		for (int i = 0; i < (int)ParticleStreamId.MaxStreams; i++)
		{
			let stream = mStreams[i];
			if (stream == null || !stream.IsCPU) continue;

			switch (stream.ElementType)
			{
			case .Float:  (stream as CPUStream<float>).SwapRemove(index, AliveCount);
			case .Float2: (stream as CPUStream<Vector2>).SwapRemove(index, AliveCount);
			case .Float3: (stream as CPUStream<Vector3>).SwapRemove(index, AliveCount);
			case .Float4: (stream as CPUStream<Vector4>).SwapRemove(index, AliveCount);
			case .Int32:  (stream as CPUStream<int32>).SwapRemove(index, AliveCount);
			}
		}
		AliveCount--;
	}

	/// Removes dead particles (Age >= Lifetime) by compacting. Returns death count.
	public int32 CompactDead()
	{
		let ages = Ages;
		let lifetimes = Lifetimes;
		if (ages == null || lifetimes == null) return 0;

		int32 deadCount = 0;
		for (int32 i = AliveCount - 1; i >= 0; i--)
		{
			if (ages[i] >= lifetimes[i])
			{
				SwapRemove(i);
				deadCount++;
			}
		}
		return deadCount;
	}

	public ~this()
	{
		for (int i = 0; i < (int)ParticleStreamId.MaxStreams; i++)
		{
			if (mStreams[i] != null)
				delete mStreams[i];
		}
	}
}
