namespace Sedulous.Core;

/// A run's random numbers: one seeded generator per run, which its game code draws from
/// (`RunServices.Get<RunRandom>(run)`) and its scripts reach as `Random`, so a run replays from
/// a seed whatever else in the process is drawing numbers. A replay or a test seeds it; the
/// run puts it back to the default seed as each session stops, so a second play starts the same
/// sequence the first did.
///
/// A plain class over Random, below scripting and runs both, so the script facade and the run
/// that holds it share one without either depending on the other.
class RunRandom
{
	private Random mRandom = .();

	/// Restarts the sequence from `seed`.
	public void Seed(uint64 seed) => mRandom = Random(seed);

	/// Back to the default seed's sequence, as a fresh run starts.
	public void Reset() => mRandom = .();

	/// In [0, 1).
	public float Value() => mRandom.NextFloat();

	/// In [min, max).
	public float Range(float min, float max) => mRandom.NextFloat(min, max);

	/// In [min, max], min when the range is empty.
	public int32 IntRange(int32 min, int32 max) => (max >= min) ? mRandom.NextInt(min, max) : min;

	public bool Bool() => mRandom.NextBool();

	/// The next raw 32 bits, for a draw the verbs above do not cover.
	public uint32 NextU32() => mRandom.NextU32();
}
