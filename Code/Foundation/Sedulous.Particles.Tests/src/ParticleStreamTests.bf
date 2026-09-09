using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The structure of arrays container: lazy allocation, checked typed access, and the swap
/// remove that keeps it dense.
class ParticleStreamTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void TheCoreStreamsExistAndTheRestAreLazy()
	{
		let streams = scope ParticleStreamContainer(64);
		Test.Assert(streams.Positions != null);
		Test.Assert(streams.Ages != null);
		Test.Assert(streams.Lifetimes != null);
		Test.Assert(streams.Velocities == null);

		streams.EnsureStream(.Velocity, .Float3);
		Test.Assert(streams.Velocities != null);
	}

	[Test]
	public static void EnsureStreamIsIdempotent()
	{
		let streams = scope ParticleStreamContainer(64);
		streams.EnsureStream(.Velocity, .Float3);
		let before = streams.GetStream(.Velocity);
		streams.EnsureStream(.Velocity, .Float3);
		// The SAME object, so a second module declaring the channel does not discard what the
		// first one already wrote.
		Test.Assert(streams.GetStream(.Velocity) == before);
	}

	[Test]
	public static void TypedAccessRefusesTheWrongElementType()
	{
		let streams = scope ParticleStreamContainer(64);
		streams.EnsureStream(.Velocity, .Float3);
		// Null rather than a reinterpreted read of somebody else's bytes.
		Test.Assert(streams.GetCPUStream<float>(.Velocity) == null);
		Test.Assert(streams.GetCPUStream<Float3>(.Velocity) != null);
	}

	[Test]
	public static void SwapRemoveKeepsTheArraysDense()
	{
		let streams = scope ParticleStreamContainer(16);
		for (int32 i = 0; i < 5; i++)
		{
			streams.Positions[i] = .((float)i, 0, 0);
			streams.Ages[i] = 0.0f;
			streams.Lifetimes[i] = 1.0f;
		}
		streams.AliveCount = 5;

		// Killing one pulls the LAST particle into its slot.
		streams.SwapRemove(1);
		Test.Assert(streams.AliveCount == 4);
		Test.Assert(Near(streams.Positions[1].X, 4.0f));
	}

	[Test]
	public static void CompactDeadDropsEverythingPastItsLifetime()
	{
		let streams = scope ParticleStreamContainer(16);
		for (int32 i = 0; i < 5; i++)
		{
			streams.Positions[i] = .((float)i, 0, 0);
			streams.Ages[i] = 0.0f;
			streams.Lifetimes[i] = 1.0f;
		}
		streams.AliveCount = 5;

		streams.Ages[0] = 2.0f;
		streams.Ages[2] = 2.0f;
		Test.Assert(streams.CompactDead() == 2);
		Test.Assert(streams.AliveCount == 3);
	}

	[Test]
	public static void TheLifeRatioIsAgeOverLifetime()
	{
		let streams = scope ParticleStreamContainer(4);
		streams.AliveCount = 2;
		streams.Ages[0] = 0.5f;
		streams.Lifetimes[0] = 2.0f;
		Test.Assert(Near(streams.GetLifeRatio(0), 0.25f));

		// A particle with no lifetime reads the END of every curve rather than dividing by
		// nothing.
		streams.Ages[1] = 1.0f;
		streams.Lifetimes[1] = 0.0f;
		Test.Assert(Near(streams.GetLifeRatio(1), 1.0f));
	}
}
