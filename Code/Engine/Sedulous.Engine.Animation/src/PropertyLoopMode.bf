namespace Sedulous.Engine.Animation;

/// What a property animator does when its clip reaches an end.
enum PropertyLoopMode : uint8
{
	/// Play through once, then stop.
	Once,
	/// Wrap to the start.
	Loop,
	/// Bounce between the ends.
	PingPong
}
