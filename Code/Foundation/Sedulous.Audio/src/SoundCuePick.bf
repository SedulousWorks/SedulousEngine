namespace Sedulous.Audio;

/// One resolved trigger: which variant, and this trigger's jitter as MULTIPLIERS to fold onto
/// the caller's own parameters.
struct SoundCuePick
{
	/// Minus one when the cue has no playable variant at all.
	public int32 VariantIndex = -1;
	public float Pitch = 1.0f;
	public float Volume = 1.0f;

	public this() {}

	public bool IsValid => VariantIndex >= 0;
}
