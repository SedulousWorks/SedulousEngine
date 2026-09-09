namespace Sedulous.Net;

/// A connected remote, as seen by one transport. NOT stable across processes: it is an index
/// into this side's connection table, not an identity the wire carries.
typealias PeerId = uint32;

static
{
	/// No peer. Zero, so a default constructed handle is invalid rather than peer one.
	public const PeerId InvalidPeer = 0;
}
