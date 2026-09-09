namespace Sedulous.Navigation;

/// What a live agent is doing, as OUR stable contract rather than the backend's internals,
/// so a script or a tool may key on it.
enum NavAgentCrowdState : uint8
{
	case Invalid = 0;
	case Walking = 1;
	/// Crossing an off mesh connection, where it is not steering at all.
	case OffMesh = 2;
}
