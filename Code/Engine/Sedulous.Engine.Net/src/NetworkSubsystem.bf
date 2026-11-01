using System;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Net.Manager;

namespace Sedulous.Engine.Net;

/// The once per context networking subsystem, and the owner of the TRANSPORT PUMP.
///
/// Networking splits in two. Injecting the component manager is a once per context concern,
/// which is this; the live endpoint, server or client, is per running game and belongs to
/// that game's controller. Authoring a network component on an entity is then all a game
/// needs for it to replicate.
///
/// Replication itself rides the per scene fixed lane. This is the socket half.
class NetworkSubsystem : Subsystem
{
	// The component's own reflection is what the serializer reads, so there is no reflected
	// component to register and no OnInit to write.

	/// The transport pump, on the subsystem manager's lane.
	///
	/// PostUpdate rather than BeginFrame so a server's sends, queued this frame by the per
	/// scene fixed lane, flush on the SAME frame whatever order the subsystems sort in.
	/// What arrives is buffered here and applied by the next frame's fixed lane, where
	/// interpolation absorbs the lag.
	///
	/// The endpoints are the runs' (Raptor's run-context spec): each run's network controller
	/// (its INetworkController service) holds its live endpoint, re-read every frame, so no
	/// endpoint is held across frames.
	public override void PostUpdate(float deltaTime)
	{
		let runs = (Manager != null) ? Manager.RunManager : null;
		if (runs == null)
			return;

		let deltaMs = deltaTime * 1000.0f;
		runs.ForEachRun(scope (run) =>
			{
				if (let controller = RunServices.Get<INetworkController>(run))
				{
					if (let endpoint = controller.NetEndpoint)
						endpoint.UpdateTransport(deltaMs);
				}
			});
	}
}
