namespace Sedulous.Net;

/// Tunables for a ReliableTransport. Every time is in milliseconds.
struct ReliableConfig
{
	/// Stamped on every packet, so a foreign or mismatched-version sender is rejected before
	/// its bytes are interpreted as a header.
	public uint16 ProtocolId = 0xDCE7;
	/// Send an ack-only packet after this long idle, which is what keeps acks flowing when
	/// neither side has anything to say.
	public float KeepAliveMs = 100.0f;
	public float ConnectResendMs = 100.0f;
	/// Nothing received for this long means the peer is gone.
	public float TimeoutMs = 5000.0f;
	/// A reliable message resends no faster than this, whatever the round trip says.
	public float MinResendMs = 20.0f;
	/// The ceiling on the round-trip-scaled backoff.
	public float MaxResendMs = 1000.0f;
	/// The largest message, reassembled. Bigger is refused rather than fragmented forever.
	public uint32 MaxMessageBytes = 256 * 1024;
	/// The per datagram budget, kept under a typical path MTU so a packet is not fragmented
	/// by the network underneath us. A large reliable message is split into pieces this size
	/// and reassembled by the receiver.
	public uint32 MaxPacketBytes = 1200;

	public this() {}
}
