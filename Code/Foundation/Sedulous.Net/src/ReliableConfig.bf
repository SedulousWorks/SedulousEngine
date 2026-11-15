namespace Sedulous.Net;

/// Tunables for a ReliableTransport. Every time is in milliseconds.
struct ReliableConfig
{
	/// Stamped on every packet, so a foreign or mismatched-version sender is rejected before
	/// its bytes are interpreted as a header. Bumped with the wire format.
	public uint16 ProtocolId = 0xDCE8;
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
	/// Before the first round trip is measured: a reliable message's first resend waits this,
	/// and each one after twice the last, up to MaxResendMs.
	public float InitialResendMs = 200.0f;
	/// The largest message, reassembled. Bigger is refused rather than fragmented forever.
	public uint32 MaxMessageBytes = 256 * 1024;
	/// The per datagram budget, kept under a typical path MTU so a packet is not fragmented
	/// by the network underneath us. A large reliable message is split into pieces this size
	/// and reassembled by the receiver.
	public uint32 MaxPacketBytes = 1200;
	/// The most Data packets one update sends a connection: a burst's cap.
	public uint32 MaxPacketsPerUpdate = 64;
	/// The live connections a server holds; a handshake past them is refused.
	public uint32 MaxPeers = 64;
	/// Reliable messages queued to one peer and not yet acked. A peer that stays connected but
	/// stops acking past this is disconnected, rather than the queue growing without end.
	public uint32 MaxQueuedReliable = 16384;

	public this() {}
}
