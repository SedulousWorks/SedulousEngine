using System;
using Sedulous.Audio;

namespace Sedulous.Audio.Tests;

class AudioSourceStateTests
{
	[Test]
	public static void TestStateValues()
	{
		// Verify all expected states exist
		let stopped = AudioSourceState.Stopped;
		let playing = AudioSourceState.Playing;
		let paused = AudioSourceState.Paused;

		Test.Assert(stopped != playing);
		Test.Assert(playing != paused);
		Test.Assert(stopped != paused);
	}

	[Test]
	public static void TestStateComparison()
	{
		let state1 = AudioSourceState.Playing;
		let state2 = AudioSourceState.Playing;
		let state3 = AudioSourceState.Stopped;

		Test.Assert(state1 == state2);
		Test.Assert(state1 != state3);
	}
}
