using System;

namespace Sedulous.Net;

/// The swappable transport backend everything above it rides on.
///
/// Multiple backends are MANDATORY rather than a nicety: a browser cannot open a raw UDP
/// socket, so the same session, reliability and replication code has to run over reliable
/// UDP, over an in memory sim, and over websocket or webrtc.
///
/// Time is driven by Update rather than read from a clock, which is what lets the sim be
/// deterministic and lets a test advance a connection without waiting for one.
interface INetTransport
{
	void Send(PeerId peer, uint8 channel, Span<uint8> data, Reliability reliability);
	void Disconnect(PeerId peer);

	/// Fills outEvent with one queued event. False when none remain this tick, so this is
	/// called in a loop.
	bool Poll(NetEvent outEvent);

	/// Advances internal time: deliver what is due, run timeouts and resends.
	void Update(float deltaMs);

	TransportStats Stats(PeerId peer);
}
