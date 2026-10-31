namespace Sedulous.UI;

/// How far along an event is in its journey through the tree: Capture runs root to target,
/// then Target, then Bubble runs target back to root.
enum EventPhase
{
	Capture,
	Target,
	Bubble
}
