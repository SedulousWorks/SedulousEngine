using System;
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
	/// Visits every LIVE endpoint across every instance. The app sets it, because the app
	/// owns the instance list; re-read each frame, so no endpoint pointer is held across
	/// one. BORROWED, like everything else handed in.
	private delegate void(delegate void(NetworkManager)) mEndpoints = null;

	/// Clear this at shutdown, so a stored visitor never outlives the app that made it.
	public void SetEndpointSource(delegate void(delegate void(NetworkManager)) source) =>
		mEndpoints = source;

	// The component's own reflection is what the serializer reads, so there is no reflected
	// component to register and no OnInit to write.

	/// The transport pump, on the Context lane.
	///
	/// PostUpdate rather than BeginFrame so a server's sends, queued this frame by the per
	/// scene fixed lane, flush on the SAME frame whatever order the subsystems sort in.
	/// What arrives is buffered here and applied by the next frame's fixed lane, where
	/// interpolation absorbs the lag.
	public override void PostUpdate(float deltaTime)
	{
		if (mEndpoints == null)
			return;

		let deltaMs = deltaTime * 1000.0f;
		mEndpoints(scope (endpoint) => endpoint.UpdateTransport(deltaMs));
	}
}
