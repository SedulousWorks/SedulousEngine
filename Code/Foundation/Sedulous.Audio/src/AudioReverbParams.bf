namespace Sedulous.Audio;

/// A reverberator's knobs.
struct AudioReverbParams
{
	/// Nought to one: how long the tail rings, which is the combs' feedback.
	public float RoomSize = 0.6f;
	/// Nought to one: how fast the high frequencies die inside the tail.
	public float Damping = 0.4f;
	/// Nought to one: how much of the tail is heard. Nought is a dry passthrough.
	public float Wet = 0.4f;

	/// The dry level. BELOW NOUGHT is the classic insert mix, one minus the wet; an explicit
	/// nought makes it WET ONLY, which is what an auxiliary send wants: the voices' sends
	/// feed it alongside the dry path, so the dry signal must not come through twice.
	public float Dry = -1.0f;

	public this() {}
}
