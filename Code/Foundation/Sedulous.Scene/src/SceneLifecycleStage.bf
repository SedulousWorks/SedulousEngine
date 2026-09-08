namespace Sedulous.Scene;

/// The explicit, ordered lifecycle a scene walks.
///
/// Assembly does NOT happen through observation any more: a module installs systems, and
/// an observer merely reacts at one of these stages.
///
/// There is deliberately no Started or Stopped stage. Both were declared in the first cut
/// and fired nowhere, since Start and Stop are called on the scene directly and out of the
/// registry's sight, and domain logic already has the system hooks. Ship only the stages
/// that fire.
enum SceneLifecycleStage : uint8
{
	/// A scene object exists and systems are being installed into it.
	Composing = 0,
	/// Every module has installed, so cross system state is now reachable.
	SystemsReady,
	/// The scene is being torn down. Drop references here.
	Destroying,

	Count
}
