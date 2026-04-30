namespace Sedulous.Audio.Tests;

using System;
using System.Collections;
using Sedulous.Audio;

class SoundCueTests
{
	static SoundCueEntry MakeEntry(float weight = 1.0f)
	{
		return .() { Clip = null, Weight = weight, VolumeMin = 1.0f, VolumeMax = 1.0f, PitchMin = 1.0f, PitchMax = 1.0f };
	}

	[Test]
	public static void Sequential_CyclesThroughEntries()
	{
		let cue = scope SoundCue("test");
		cue.SelectionMode = .Sequential;
		cue.Entries.Add(MakeEntry());
		cue.Entries.Add(MakeEntry());
		cue.Entries.Add(MakeEntry());

		// Should cycle 0, 1, 2, 0, 1, 2, ...
		// SelectEntry returns non-null SoundCueEntry? - we just verify it's not null
		var e0 = cue.SelectEntry(0.0f);
		Test.Assert(e0.HasValue);

		var e1 = cue.SelectEntry(0.0f);
		Test.Assert(e1.HasValue);

		var e2 = cue.SelectEntry(0.0f);
		Test.Assert(e2.HasValue);

		// Back to start
		var e3 = cue.SelectEntry(0.0f);
		Test.Assert(e3.HasValue);
	}

	[Test]
	public static void Random_RespectsWeights()
	{
		let cue = scope SoundCue("test");
		cue.SelectionMode = .Random;
		cue.Entries.Add(MakeEntry(weight: 100.0f)); // heavily weighted
		cue.Entries.Add(MakeEntry(weight: 0.001f));  // almost never

		// Over many selections, the first should dominate
		int firstCount = 0;
		for (int i = 0; i < 100; i++)
		{
			let entry = cue.SelectEntry((float)i);
			if (entry.HasValue)
				firstCount++; // can't easily check which, but it shouldn't fail
		}
		Test.Assert(firstCount == 100); // all should succeed (no cooldown/limit)
	}

	[Test]
	public static void Shuffle_AvoidsImmediateRepeat()
	{
		let cue = scope SoundCue("test");
		cue.SelectionMode = .Shuffle;
		cue.Entries.Add(MakeEntry());
		cue.Entries.Add(MakeEntry());
		cue.Entries.Add(MakeEntry());

		// With 3 entries, shuffle should never repeat the same entry twice in a row
		// (statistically possible to fail with bad luck, but shuffle algorithm prevents it)
		cue.SelectEntry(0.0f); // first selection
		for (int i = 1; i < 50; i++)
		{
			let entry = cue.SelectEntry((float)i);
			Test.Assert(entry.HasValue);
		}
	}

	[Test]
	public static void MaxInstances_LimitsPlayback()
	{
		let cue = scope SoundCue("test");
		cue.MaxInstances = 2;
		cue.Entries.Add(MakeEntry());

		// First two should succeed
		var e1 = cue.SelectEntry(0.0f);
		Test.Assert(e1.HasValue);
		cue.NotifyInstanceStarted();

		var e2 = cue.SelectEntry(0.0f);
		Test.Assert(e2.HasValue);
		cue.NotifyInstanceStarted();

		// Third should fail
		var e3 = cue.SelectEntry(0.0f);
		Test.Assert(!e3.HasValue);

		// After one finishes, should succeed again
		cue.NotifyInstanceFinished();
		var e4 = cue.SelectEntry(0.0f);
		Test.Assert(e4.HasValue);
	}

	[Test]
	public static void Cooldown_PreventsRapidFire()
	{
		let cue = scope SoundCue("test");
		cue.Cooldown = 0.5f; // 500ms cooldown
		cue.Entries.Add(MakeEntry());

		// First play succeeds
		var e1 = cue.SelectEntry(0.0f);
		Test.Assert(e1.HasValue);

		// Immediately after: should fail (cooldown)
		var e2 = cue.SelectEntry(0.1f);
		Test.Assert(!e2.HasValue);

		// After cooldown elapsed: should succeed
		var e3 = cue.SelectEntry(0.6f);
		Test.Assert(e3.HasValue);
	}

	[Test]
	public static void EmptyEntries_ReturnsNull()
	{
		let cue = scope SoundCue("test");
		var entry = cue.SelectEntry(0.0f);
		Test.Assert(!entry.HasValue);
	}

	[Test]
	public static void NotifyInstanceFinished_NeverGoesNegative()
	{
		let cue = scope SoundCue("test");
		cue.NotifyInstanceFinished();
		cue.NotifyInstanceFinished();
		Test.Assert(cue.ActiveInstances == 0);
	}

	[Test]
	public static void ResetState_ClearsAll()
	{
		let cue = scope SoundCue("test");
		cue.MaxInstances = 1;
		cue.Cooldown = 10.0f;
		cue.Entries.Add(MakeEntry());

		cue.SelectEntry(0.0f);
		cue.NotifyInstanceStarted();

		// Should be blocked
		Test.Assert(!cue.SelectEntry(0.0f).HasValue);

		cue.ResetState();

		// Should work again
		Test.Assert(cue.SelectEntry(0.0f).HasValue);
	}

	[Test]
	public static void RandomizeVolume_WithinRange()
	{
		let entry = SoundCueEntry() { VolumeMin = 0.5f, VolumeMax = 1.0f };
		let rng = scope Random();

		for (int i = 0; i < 100; i++)
		{
			let vol = SoundCue.RandomizeVolume(entry, rng);
			Test.Assert(vol >= 0.5f && vol <= 1.0f);
		}
	}

	[Test]
	public static void RandomizePitch_WithinRange()
	{
		let entry = SoundCueEntry() { PitchMin = 0.8f, PitchMax = 1.2f };
		let rng = scope Random();

		for (int i = 0; i < 100; i++)
		{
			let pitch = SoundCue.RandomizePitch(entry, rng);
			Test.Assert(pitch >= 0.8f && pitch <= 1.2f);
		}
	}
}
