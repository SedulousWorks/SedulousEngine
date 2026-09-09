namespace Sedulous.Net;

/// Per peer link telemetry, for a net profiler and for budgeting replication bandwidth.
struct TransportStats
{
	public float RttMs = 0.0f;
	public float LossPct = 0.0f;
	public uint32 SentBytes = 0;
	public uint32 RecvBytes = 0;
	public uint32 QueuedBytes = 0;

	public this() {}
}
