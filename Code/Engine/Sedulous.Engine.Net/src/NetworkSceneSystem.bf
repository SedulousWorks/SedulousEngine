using System;
using Sedulous.Scene;
using Sedulous.Net.Manager;

namespace Sedulous.Engine.Net;

/// The per scene replication driver, ticked on the scene's FIXED lane.
///
/// The fixed lane rather than the variable one because replication has to be deterministic
/// and in lockstep with physics. It holds the endpoint that replicates THIS scene, and is
/// inert until something sets one: a scene that is not the endpoint's current replicated
/// scene does nothing here.
///
/// The endpoint is a plain setter rather than a service, because the run's controller wires
/// and clears it at the edges it already owns.
class NetworkSceneSystem : SceneSystem
{
	/// BORROWED: the run's network controller owns it and clears this before it goes.
	private NetworkManager mEndpoint = null;

	public NetworkManager Endpoint
	{
		get => mEndpoint;
		set => mEndpoint = value;
	}

	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		// Server: capture and send. Client: sample, interpolate and apply.
		if (mEndpoint != null)
			mEndpoint.UpdateReplication();
	}
}
