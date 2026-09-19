using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Audio;

/// ONE TRIGGER, one of several clips, weighted, with per trigger jitter.
///
/// The cue is pure DATA, and resolving one is a pure function: the caller owns the play state,
/// which is the last pick and the sequential cursor, and the generator. That is what makes a
/// pick reproducible under test, and it keeps the engine clip based, a resolved pick playing
/// through the ordinary voice path like anything else.
/// On the script surface as an opaque handle: a script holds one and hands it back.
[Scriptable]
class SoundCue
{
	/// The most variants a cue resolves over. A wheel of this size is walked on the stack.
	public const int cMaxVariants = 64;

	public List<SoundCueVariant> Variants = new .() ~ delete _;
	public SoundCueMode Mode = .RandomNoRepeat;

	/// The jitter applied per trigger, on top of the play parameters.
	public float PitchMin = 1.0f;
	public float PitchMax = 1.0f;
	public float VolumeMin = 1.0f;
	public float VolumeMax = 1.0f;

	/// Resolves one trigger.
	///
	/// The last index is the caller's PREVIOUS pick, minus one for none, which is what the no
	/// repeat mode avoids; the cursor advances in sequential mode. Both belong to the caller,
	/// one per component or per cue identity, so two things triggering the same cue do not
	/// share a sequence.
	public static SoundCuePick Resolve(SoundCue cue, ref Sedulous.Core.Random rng, int32 lastVariantIndex,
		ref uint32 sequentialCursor)
	{
		var pick = SoundCuePick();

		// The eligible set: a slot with a clip and a positive weight.
		var eligible = scope int32[cMaxVariants];
		var eligibleCount = 0;
		var totalWeight = 0.0f;

		let slotCount = Min(cue.Variants.Count, cMaxVariants);
		for (int i < slotCount)
		{
			let variant = cue.Variants[i];
			if ((variant.Clip == null) || (variant.Weight <= 0.0f))
				continue;

			eligible[eligibleCount++] = (int32)i;
			totalWeight += variant.Weight;
		}

		if (eligibleCount == 0)
			return pick;

		if (cue.Mode == .Sequential)
		{
			pick.VariantIndex = eligible[(int)(sequentialCursor % (uint32)eligibleCount)];
			sequentialCursor++;
		}
		else
		{
			// No repeat with more than one choice: cut the previous pick out of the wheel
			// rather than rolling again until it differs, which has no bound.
			let avoidLast = (cue.Mode == .RandomNoRepeat) && (eligibleCount > 1)
				&& (lastVariantIndex >= 0);

			var wheelWeight = totalWeight;
			if (avoidLast)
			{
				for (int i < eligibleCount)
				{
					if (eligible[i] == lastVariantIndex)
					{
						wheelWeight -= cue.Variants[lastVariantIndex].Weight;
						break;
					}
				}
			}

			var roll = rng.NextFloat(0.0f, wheelWeight);
			for (int i < eligibleCount)
			{
				let index = eligible[i];
				if (avoidLast && (index == lastVariantIndex))
					continue;

				// Assigned before the test, so numeric drift lands on the last VALID
				// candidate rather than on nothing at all.
				pick.VariantIndex = index;

				let weight = cue.Variants[index].Weight;
				if (roll < weight)
					break;
				roll -= weight;
			}
		}

		pick.Pitch = rng.NextFloat(Min(cue.PitchMin, cue.PitchMax), Max(cue.PitchMin, cue.PitchMax));
		pick.Volume = rng.NextFloat(Min(cue.VolumeMin, cue.VolumeMax),
			Max(cue.VolumeMin, cue.VolumeMax));
		return pick;
	}
}
