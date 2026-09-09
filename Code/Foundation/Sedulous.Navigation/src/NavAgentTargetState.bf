namespace Sedulous.Navigation;

/// Where an agent's move request has got to.
enum NavAgentTargetState : uint8
{
	case None = 0;
	/// Queued or running. The backend has several in flight stages; they read as one here,
	/// because the difference between them is its business rather than a caller's.
	case Requesting = 1;
	case Valid = 2;
	/// Driven by velocity, with no corridor behind it.
	case Velocity = 3;
	case Failed = 4;
}
