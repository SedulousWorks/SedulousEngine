using System;
using Sedulous.Core;

namespace Sedulous.Particles;

/// Particle state held structure of arrays: one typed stream per attribute in a fixed slot
/// table indexed by ParticleStreamId, with ONE alive count shared across all of them.
///
/// Death is an O(1) swap remove, so particle ORDER IS NOT PRESERVED. Nothing may hold an
/// index across an update.
class ParticleStreamContainer
{
	private const int cSlotCount = (int)ParticleStreamId.MaxStreams;

	private ParticleStream[] mStreams = new ParticleStream[cSlotCount] ~ FreeStreams(_);
	private int32 mCapacity;

	/// Indices in [0, AliveCount) are live.
	public int32 AliveCount = 0;

	public this(int32 capacity)
	{
		mCapacity = capacity;

		// The three every system has.
		EnsureStream(.Position, .Float3);
		EnsureStream(.Age, .Float);
		EnsureStream(.Lifetime, .Float);
	}

	private static void FreeStreams(ParticleStream[] streams)
	{
		for (let stream in streams)
			delete stream;
		delete streams;
	}

	public int32 Capacity => mCapacity;

	public ParticleStream GetStream(ParticleStreamId id) => mStreams[(int)id];

	/// Typed access. Null when the stream is not allocated OR its element type is not T, so a
	/// mismatched id reads nothing rather than reinterpreting someone else's bytes.
	public CPUStream<T> GetCPUStream<T>(ParticleStreamId id) where T : struct
	{
		let stream = mStreams[(int)id];
		if ((stream == null) || !stream.IsCPU || (stream.ElementType != StreamElement.Of<T>()))
			return null;
		return stream as CPUStream<T>;
	}

	/// Allocates a stream into its slot if absent. Idempotent, so every module that wants a
	/// channel may declare it without knowing who else did.
	public void EnsureStream(ParticleStreamId id, StreamElementType elementType)
	{
		let slot = (int)id;
		if (mStreams[slot] != null)
			return;

		switch (elementType)
		{
		case .Float: mStreams[slot] = new CPUStream<float>(id, elementType, mCapacity);
		case .Float2: mStreams[slot] = new CPUStream<Float2>(id, elementType, mCapacity);
		case .Float3: mStreams[slot] = new CPUStream<Float3>(id, elementType, mCapacity);
		case .Float4: mStreams[slot] = new CPUStream<Float4>(id, elementType, mCapacity);
		case .Int32: mStreams[slot] = new CPUStream<int32>(id, elementType, mCapacity);
		}
	}

	// The standard channels, null when not allocated.
	public CPUStream<Float3> Positions => GetCPUStream<Float3>(.Position);
	public CPUStream<float> Ages => GetCPUStream<float>(.Age);
	public CPUStream<float> Lifetimes => GetCPUStream<float>(.Lifetime);
	public CPUStream<Float3> Velocities => GetCPUStream<Float3>(.Velocity);
	public CPUStream<Float3> StartVelocities => GetCPUStream<Float3>(.StartVelocity);
	public CPUStream<Float4> Colors => GetCPUStream<Float4>(.Color);
	public CPUStream<Float2> Sizes => GetCPUStream<Float2>(.Size);
	public CPUStream<float> Rotations => GetCPUStream<float>(.Rotation);
	public CPUStream<float> RotationSpeeds => GetCPUStream<float>(.RotationSpeed);
	public CPUStream<Float3> Axes => GetCPUStream<Float3>(.Axis);

	/// Normalised life in [0, 1]. One for a particle with no lifetime, so a curve reads its
	/// end rather than dividing by zero.
	public float GetLifeRatio(int32 index)
	{
		let ages = Ages;
		let lifetimes = Lifetimes;
		if ((ages == null) || (lifetimes == null))
			return 1.0f;

		let life = lifetimes[index];
		if (life <= 0.0f)
			return 1.0f;
		return Min(ages[index] / life, 1.0f);
	}

	/// Swap removes one particle from EVERY allocated stream, then shrinks the alive count.
	public void SwapRemove(int32 index)
	{
		for (let stream in mStreams)
		{
			if (stream != null)
				stream.SwapRemoveElement(index, AliveCount);
		}
		AliveCount--;
	}

	/// Removes every particle whose age has reached its lifetime, and returns how many went.
	///
	/// The scan runs BACKWARD because a swap remove pulls the tail into `index`: walking down
	/// means the element swapped in has already been tested.
	public int32 CompactDead()
	{
		let ages = Ages;
		let lifetimes = Lifetimes;
		if ((ages == null) || (lifetimes == null))
			return 0;

		int32 removed = 0;
		for (int32 i = AliveCount - 1; i >= 0; i--)
		{
			if (ages[i] >= lifetimes[i])
			{
				SwapRemove(i);
				removed++;
			}
		}
		return removed;
	}
}
