using System;
using Sedulous.Audio;
using Sedulous.Core;

namespace Sedulous.Audio.Tests;

/// Resolving a cue: which variant, and this trigger's jitter.
class SoundCueTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// A cue with two playable slots and two that are not: one has no clip, the other no
	/// weight. Both are skipped, so only the two real ones are ever picked.
	private static SoundCue MakeCue(AudioClip first, AudioClip second)
	{
		let cue = new SoundCue();
		cue.Variants.Add(.(first, 1.0f));
		// An empty slot.
		cue.Variants.Add(.(null, 5.0f));
		// A disabled one.
		cue.Variants.Add(.(second, 0.0f));
		cue.Variants.Add(.(second, 3.0f));
		return cue;
	}

	/// With two eligible slots, no repeat has to ALTERNATE: there is nowhere else to go.
	[Test]
	public static void NoRepeatNeverPicksTheSameSlotTwiceRunning()
	{
		let a = scope AudioClip();
		let b = scope AudioClip();
		let cue = scope SoundCue();
		cue.Variants.Add(.(a, 1.0f));
		cue.Variants.Add(.(null, 5.0f));
		cue.Variants.Add(.(b, 0.0f));
		cue.Variants.Add(.(b, 3.0f));
		cue.PitchMin = 0.9f;
		cue.PitchMax = 1.1f;

		var rng = Random(42);
		uint32 cursor = 0;
		int32 last = -1;

		for (int i < 50)
		{
			let pick = SoundCue.Resolve(cue, ref rng, last, ref cursor);
			Test.Assert((pick.VariantIndex == 0) || (pick.VariantIndex == 3));
			if (last >= 0)
				Test.Assert(pick.VariantIndex != last);

			Test.Assert(pick.Pitch >= 0.9f);
			Test.Assert(pick.Pitch <= 1.1f);
			Test.Assert(Near(pick.Volume, 1.0f));

			last = pick.VariantIndex;
		}
	}

	/// The weights bias the wheel: a slot weighted three to one is picked about three times
	/// as often. The floor is generous, this being a statistical claim.
	[Test]
	public static void TheWeightsBiasTheWheel()
	{
		let a = scope AudioClip();
		let b = scope AudioClip();
		let cue = scope SoundCue();
		cue.Variants.Add(.(a, 1.0f));
		cue.Variants.Add(.(b, 3.0f));
		cue.Mode = .Random;

		var rng = Random(42);
		uint32 cursor = 0;
		var light = 0;
		var heavy = 0;

		for (int i < 400)
		{
			let pick = SoundCue.Resolve(cue, ref rng, -1, ref cursor);
			if (pick.VariantIndex == 0)
				light++;
			if (pick.VariantIndex == 1)
				heavy++;
		}

		Test.Assert((light + heavy) == 400);
		Test.Assert(heavy > (light * 2));
	}

	/// Sequential walks the ELIGIBLE set in slot order, skipping the slots that are not
	/// playable rather than stalling on them.
	[Test]
	public static void SequentialWalksTheEligibleSlotsInOrder()
	{
		let a = scope AudioClip();
		let b = scope AudioClip();
		let cue = scope SoundCue();
		cue.Variants.Add(.(a, 1.0f));
		cue.Variants.Add(.(null, 5.0f));
		cue.Variants.Add(.(b, 0.0f));
		cue.Variants.Add(.(b, 3.0f));
		cue.Mode = .Sequential;

		var rng = Random(1);
		uint32 cursor = 0;

		Test.Assert(SoundCue.Resolve(cue, ref rng, -1, ref cursor).VariantIndex == 0);
		Test.Assert(SoundCue.Resolve(cue, ref rng, -1, ref cursor).VariantIndex == 3);
		Test.Assert(SoundCue.Resolve(cue, ref rng, -1, ref cursor).VariantIndex == 0);
	}

	/// A cue with nothing playable answers no variant, rather than the first slot regardless.
	[Test]
	public static void ACueWithNothingPlayableAnswersNothing()
	{
		let cue = scope SoundCue();
		cue.Variants.Add(.(null, 1.0f));

		var rng = Random(1);
		uint32 cursor = 0;

		let pick = SoundCue.Resolve(cue, ref rng, -1, ref cursor);
		Test.Assert(pick.VariantIndex == -1);
		Test.Assert(!pick.IsValid);
	}

	/// A cue with ONE eligible slot cannot alternate, so no repeat picks it every time rather
	/// than answering nothing.
	[Test]
	public static void OneEligibleSlotIsPickedEveryTime()
	{
		let a = scope AudioClip();
		let cue = scope SoundCue();
		cue.Variants.Add(.(a, 1.0f));

		var rng = Random(7);
		uint32 cursor = 0;
		int32 last = -1;

		for (int i < 10)
		{
			let pick = SoundCue.Resolve(cue, ref rng, last, ref cursor);
			Test.Assert(pick.VariantIndex == 0);
			last = pick.VariantIndex;
		}
	}

	/// The jitter is a MULTIPLIER, and a range given backwards is still read as a range
	/// rather than producing nothing.
	[Test]
	public static void TheJitterRangeIsReadEitherWayRound()
	{
		let a = scope AudioClip();
		let cue = scope SoundCue();
		cue.Variants.Add(.(a, 1.0f));
		cue.PitchMin = 1.5f;
		cue.PitchMax = 0.5f;
		cue.VolumeMin = 0.25f;
		cue.VolumeMax = 0.75f;

		var rng = Random(3);
		uint32 cursor = 0;

		for (int i < 20)
		{
			let pick = SoundCue.Resolve(cue, ref rng, -1, ref cursor);
			Test.Assert(pick.Pitch >= 0.5f);
			Test.Assert(pick.Pitch <= 1.5f);
			Test.Assert(pick.Volume >= 0.25f);
			Test.Assert(pick.Volume <= 0.75f);
		}
	}

	/// The cursor belongs to the CALLER, so two things triggering one cue keep their own
	/// place in the sequence rather than advancing each other's.
	[Test]
	public static void TwoCallersKeepTheirOwnPlaceInTheSequence()
	{
		let a = scope AudioClip();
		let b = scope AudioClip();
		let cue = scope SoundCue();
		cue.Variants.Add(.(a, 1.0f));
		cue.Variants.Add(.(b, 1.0f));
		cue.Mode = .Sequential;

		var rng = Random(1);
		uint32 first = 0;
		uint32 second = 0;

		Test.Assert(SoundCue.Resolve(cue, ref rng, -1, ref first).VariantIndex == 0);
		Test.Assert(SoundCue.Resolve(cue, ref rng, -1, ref first).VariantIndex == 1);
		// The second caller starts where IT left off, which is the beginning.
		Test.Assert(SoundCue.Resolve(cue, ref rng, -1, ref second).VariantIndex == 0);
	}
}
