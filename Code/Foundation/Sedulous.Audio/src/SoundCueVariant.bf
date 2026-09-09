namespace Sedulous.Audio;

/// One slot of a cue.
struct SoundCueVariant
{
	/// BORROWED. Null is an empty slot, which is skipped.
	public AudioClip Clip = null;
	/// Nought or less disables the slot.
	public float Weight = 1.0f;

	public this() {}

	public this(AudioClip clip, float weight = 1.0f)
	{
		Clip = clip;
		Weight = weight;
	}
}
