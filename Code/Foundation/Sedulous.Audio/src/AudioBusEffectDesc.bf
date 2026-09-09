namespace Sedulous.Audio;

/// One link of an effect chain, as DATA. Only the fields its kind reads matter.
struct AudioBusEffectDesc
{
	public AudioBusEffectKind Kind = .None;
	/// The cutoff, for the two filters.
	public float FrequencyHz = 1000.0f;
	public float DelaySeconds = 0.25f;
	/// The delay's feedback, nought to one.
	public float DelayDecay = 0.3f;
	public float RoomSize = 0.6f;
	public float Damping = 0.4f;
	public float WetLevel = 0.4f;

	public this() {}
}
