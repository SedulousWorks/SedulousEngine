using Sedulous.Graphics;

namespace Sedulous.Runtime.Client;

/// The application, which IS the game or the tool. Exactly one per host.
///
/// Configure is the ONLY place subsystems are registered, and the application owns that
/// list. That is the whole point: the subsystem set is identical whether the application
/// runs standalone or embedded in an editor. A host that forced its own defaults in would
/// mean neither run honoured what the game actually asked for.
///
/// OnLaunch and OnExit bracket PLAY. A standalone host fires them once around the loop;
/// an editor fires them on play and stop, so the same application does both.
interface IApplication
{
	/// Read once, before Configure.
	ApplicationSettings Settings => .();

	/// The main window's render configuration, the SAME descriptor OpenWindow takes. Read
	/// once by the host when it wraps the shell's main window. Override to uncap the frame
	/// rate, change the format, and so on.
	RenderWindowDesc MainRenderWindow => .();

	/// Register subsystems and types.
	void Configure(IApplicationHost host) {}

	/// After the context started.
	void OnStartup(IApplicationHost host) {}

	/// Entering play.
	void OnLaunch(IApplicationHost host) {}

	void OnUpdate(IApplicationHost host, float deltaTime) {}
	void OnFixedUpdate(IApplicationHost host, float fixedDeltaTime) {}

	/// Record this window's contents. Called once per window per frame, between the host's
	/// BeginFrame and EndFrame.
	void OnRenderWindow(IApplicationHost host, ref FrameContext frame) {}

	/// Leaving play.
	void OnExit(IApplicationHost host) {}

	/// Before the context shuts down.
	void OnShutdown(IApplicationHost host) {}
}
