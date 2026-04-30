namespace Sedulous.Audio;

using System;
using System.Collections;

/// Selection mode for choosing entries from a sound cue.
public enum CueSelectionMode
{
	/// Random selection weighted by entry Weight values.
	Random,
	/// Sequential round-robin through entries.
	Sequential,
	/// Random but avoids repeating the previous entry.
	Shuffle
}

/// A single entry in a SoundCue.
public struct SoundCueEntry
{
	/// Audio clip for this entry.
	public AudioClip Clip;

	/// Selection weight (higher = more likely in Random mode).
	public float Weight = 1.0f;

	/// Volume range - actual volume randomized within [VolumeMin, VolumeMax].
	public float VolumeMin = 1.0f;
	public float VolumeMax = 1.0f;

	/// Pitch range - actual pitch randomized within [PitchMin, PitchMax].
	public float PitchMin = 1.0f;
	public float PitchMax = 1.0f;
}

/// Defines a group of sound variations for a single logical sound event.
/// Example: a footstep cue with 4 clip variations, randomized pitch/volume.
public class SoundCue
{
	/// Display name.
	public String Name ~ delete _;

	/// Entries in this cue.
	public List<SoundCueEntry> Entries = new .() ~ delete _;

	/// How entries are selected.
	public CueSelectionMode SelectionMode = .Random;

	/// Maximum simultaneous instances of this cue. 0 = unlimited.
	public int32 MaxInstances = 0;

	/// Priority for voice stealing (higher = more important, keeps playing).
	public int32 Priority = 0;

	/// Minimum seconds between plays. Prevents machine-gun repetition.
	public float Cooldown = 0.0f;

	/// Name of the bus this cue routes to.
	public String BusName ~ delete _;

	// Runtime state
	private int32 mSequentialIndex;
	private int32 mLastSelectedIndex = -1;
	private int32 mActiveInstances;
	private float mLastPlayTime = -1000.0f;
	private Random mRandom = new .() ~ delete _;

	public this()
	{
		Name = new .("Untitled");
		BusName = new .("SFX");
	}

	public this(StringView name)
	{
		Name = new .(name);
		BusName = new .("SFX");
	}

	/// Number of currently active instances.
	public int32 ActiveInstances => mActiveInstances;

	/// Selects the next entry to play, applying selection mode and randomization.
	/// Returns null if max instances reached or cooldown not elapsed.
	/// currentTime: current time in seconds (for cooldown tracking).
	public SoundCueEntry? SelectEntry(float currentTime)
	{
		if (Entries.Count == 0)
			return null;

		// Check instance limit
		if (MaxInstances > 0 && mActiveInstances >= MaxInstances)
			return null;

		// Check cooldown
		if (Cooldown > 0 && (currentTime - mLastPlayTime) < Cooldown)
			return null;

		int index = 0;

		switch (SelectionMode)
		{
		case .Random:
			index = SelectWeightedRandom();
		case .Sequential:
			index = mSequentialIndex;
			mSequentialIndex = (mSequentialIndex + 1) % (int32)Entries.Count;
		case .Shuffle:
			index = SelectShuffle();
		}

		mLastPlayTime = currentTime;
		mLastSelectedIndex = (int32)index;
		return Entries[index];
	}

	/// Marks an instance as started.
	public void NotifyInstanceStarted()
	{
		mActiveInstances++;
	}

	/// Marks an instance as finished.
	public void NotifyInstanceFinished()
	{
		mActiveInstances = Math.Max(0, mActiveInstances - 1);
	}

	/// Resets runtime state (selection index, active count, cooldown).
	public void ResetState()
	{
		mSequentialIndex = 0;
		mLastSelectedIndex = -1;
		mActiveInstances = 0;
		mLastPlayTime = -1000.0f;
	}

	private int SelectWeightedRandom()
	{
		float totalWeight = 0;
		for (let entry in Entries)
			totalWeight += entry.Weight;

		if (totalWeight <= 0)
			return 0;

		var roll = (float)mRandom.NextDouble() * totalWeight;
		for (int i = 0; i < Entries.Count; i++)
		{
			roll -= Entries[i].Weight;
			if (roll <= 0)
				return i;
		}
		return Entries.Count - 1;
	}

	private int SelectShuffle()
	{
		if (Entries.Count == 1)
			return 0;

		// Pick randomly but avoid the last-selected index
		var index = (int32)(mRandom.NextDouble() * (Entries.Count - 1));
		if (index >= mLastSelectedIndex)
			index++;
		return index;
	}

	/// Generates a randomized volume from the entry's range.
	public static float RandomizeVolume(SoundCueEntry entry, Random rng)
	{
		if (entry.VolumeMin == entry.VolumeMax)
			return entry.VolumeMin;
		return entry.VolumeMin + (float)rng.NextDouble() * (entry.VolumeMax - entry.VolumeMin);
	}

	/// Generates a randomized pitch from the entry's range.
	public static float RandomizePitch(SoundCueEntry entry, Random rng)
	{
		if (entry.PitchMin == entry.PitchMax)
			return entry.PitchMin;
		return entry.PitchMin + (float)rng.NextDouble() * (entry.PitchMax - entry.PitchMin);
	}
}
