namespace Sedulous.Net;

/// Injectable network conditions. Probabilities run nought to one.
///
/// The seed is what makes a run REPRODUCIBLE: with a manual clock and a seeded generator, a
/// reliability or replication test is a deterministic headless unit test rather than a flaky
/// one.
struct SimConditions
{
	/// One way latency, before jitter.
	public float LatencyMs = 0.0f;
	/// Uniform, plus or minus, added to the latency.
	public float JitterMs = 0.0f;
	public float LossPct = 0.0f;
	public float DupPct = 0.0f;
	/// The chance of an extra random delay, which is what lets a packet arrive after a later
	/// one.
	public float ReorderPct = 0.0f;
	public uint64 Seed = 0x9E3779B97F4A7C15UL;

	public this() {}
}
