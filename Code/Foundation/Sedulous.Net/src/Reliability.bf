namespace Sedulous.Net;

/// What a Send promises. Channels are INDEPENDENT ordering domains, so a dropped cosmetic
/// update never delays a command.
enum Reliability : uint8
{
	/// May drop, reorder and duplicate. For continuous data where the next one supersedes
	/// this one anyway.
	case Unreliable;
	/// May drop, but never arrives out of order: a stale one is discarded rather than
	/// applied after a newer one.
	case UnreliableSequenced;
	/// Guaranteed, and in order. The commands and orders channel.
	case ReliableOrdered;
}
