using System;

namespace Sedulous.Net.Manager;

/// The owner of a running game's networking (a GameInstance's NetworkController), as a run holds
/// it: what reaches the run's live endpoint from below the runtime layer. The engine's network
/// subsystem pumps each run's endpoint through it, since it cannot name the runtime's controller
/// (Raptor's run-context spec). The controller outlives every endpoint it opens; the endpoint
/// comes and goes.
interface INetworkController
{
	/// The live endpoint, or null when offline (before a host or a join, after a disconnect).
	/// BORROWED.
	NetworkManager NetEndpoint { get; }
}
