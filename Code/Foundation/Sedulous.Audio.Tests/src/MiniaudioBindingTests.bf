using System;
using miniaudio_Beef;

namespace Sedulous.Audio.Tests;

/// The binding itself: that the native library links, and that a headless engine comes up.
///
/// These call the C surface directly rather than through the engine, so a link or ABI fault
/// shows up here rather than as a mysterious failure somewhere in the mixer.
class MiniaudioBindingTests
{
	[Test]
	public static void TheLibraryLinksAndReportsItsVersion()
	{
		uint32 major = 0;
		uint32 minor = 0;
		uint32 revision = 0;
		mab_version(&major, &minor, &revision);

		// The binding was generated against 0.11.x, and a major change would break it.
		Test.Assert(major == 0);
		Test.Assert(minor == 11);
	}

	/// A HEADLESS engine opens no device at all and is pumped by hand, which is what makes
	/// the mixer testable on a machine with no sound card and in a build with no audio at all.
	[Test]
	public static void AHeadlessEngineComesUpAtTheRateItWasAsked()
	{
		let engine = mab_engine_create(null, 1, 1, 2, 48000);
		Test.Assert(engine != null);
		defer mab_engine_destroy(engine);

		Test.Assert(mab_engine_get_channels(engine) == 2);
		Test.Assert(mab_engine_get_sample_rate(engine) == 48000);
		Test.Assert(mab_engine_get_listener_count(engine) == 1);
	}

	/// A graph with NOTHING ATTACHED produces nothing, rather than a block of silence: the
	/// read succeeds and answers no frames at all. A pump loop therefore has to treat a read
	/// of nought as the end of what there is, not as a failure to make progress.
	[Test]
	public static void AnEmptyGraphProducesNothingRatherThanSilence()
	{
		let engine = mab_engine_create(null, 1, 1, 2, 48000);
		Test.Assert(engine != null);
		defer mab_engine_destroy(engine);

		let frames = scope float[512 * 2];
		uint64 read = 0;
		Test.Assert(mab_engine_read_pcm_frames(engine, &frames[0], 512, &read) == 0);
		Test.Assert(read == 0);
	}

	/// The graph's endpoint exists on a headless engine too, so a bus has something to
	/// attach to whether or not a device was opened.
	[Test]
	public static void AHeadlessEngineStillHasAGraphEndpoint()
	{
		let engine = mab_engine_create(null, 1, 1, 2, 48000);
		Test.Assert(engine != null);
		defer mab_engine_destroy(engine);

		Test.Assert(mab_engine_get_endpoint(engine) != null);
	}

	[Test]
	public static void AGroupWiresIntoTheGraphAndBackOut()
	{
		let engine = mab_engine_create(null, 1, 1, 2, 48000);
		Test.Assert(engine != null);
		defer mab_engine_destroy(engine);

		let group = mab_sound_group_create(engine, 0, null);
		Test.Assert(group != null);
		defer mab_sound_group_destroy(group);

		let node = mab_sound_group_get_node(group);
		Test.Assert(node != null);
		Test.Assert(mab_node_attach_output_bus(node, 0, mab_engine_get_endpoint(engine), 0) == 0);
	}

	/// The effect nodes are created against the engine, so they inherit its channel count
	/// and rate rather than being told them twice.
	[Test]
	public static void TheEffectNodesBuildAgainstTheEngine()
	{
		let engine = mab_engine_create(null, 1, 1, 2, 48000);
		Test.Assert(engine != null);
		defer mab_engine_destroy(engine);

		let lowpass = mab_lpf_node_create(engine, 800.0, 2);
		Test.Assert(lowpass != null);
		Test.Assert(mab_lpf_node_set_cutoff(lowpass, engine, 400.0, 2) == 0);
		mab_lpf_node_destroy(lowpass);

		let highpass = mab_hpf_node_create(engine, 200.0, 2);
		Test.Assert(highpass != null);
		mab_hpf_node_destroy(highpass);

		let delay = mab_delay_node_create(engine, 4800, 0.4f);
		Test.Assert(delay != null);
		mab_delay_node_destroy(delay);

		let splitter = mab_splitter_node_create(engine);
		Test.Assert(splitter != null);
		mab_splitter_node_destroy(splitter);
	}

	private static int sProcessedFrames = 0;

	private static void CountFrames(void* user, float* framesIn, float* framesOut,
		uint32 frameCount, uint32 channels)
	{
		sProcessedFrames += (int)frameCount;
		Internal.MemCpy(framesOut, framesIn, (int)frameCount * (int)channels * sizeof(float));
	}

	/// A custom node's processing runs on the AUDIO THREAD, and here that is the pumping
	/// thread, so the count is observable straight after.
	[Test]
	public static void ACustomNodeProcessesWhatTheEngineMixes()
	{
		let engine = mab_engine_create(null, 1, 1, 2, 48000);
		Test.Assert(engine != null);
		defer mab_engine_destroy(engine);

		sProcessedFrames = 0;
		let node = mab_custom_node_create(engine, => CountFrames, null);
		Test.Assert(node != null);
		defer mab_custom_node_destroy(node);

		Test.Assert(mab_node_attach_output_bus(node, 0, mab_engine_get_endpoint(engine), 0) == 0);

		let frames = scope float[256 * 2];
		uint64 read = 0;
		Test.Assert(mab_engine_read_pcm_frames(engine, &frames[0], 256, &read) == 0);
		Test.Assert(read == 256);
		// It processes CONTINUOUSLY, so it runs even with nothing feeding it.
		Test.Assert(sProcessedFrames > 0);
	}
}
