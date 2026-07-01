using Sedulous.RuntimeGraphics;

namespace Sedulous.Runtime.Client;

/// The application/game. Exactly one per host. Configure() registers the app's
/// subsystems (the ONLY place subsystems are registered -- pluggable). OnLaunch/
/// OnExit bracket "play": for a standalone host they fire once around the loop;
/// an editor fires them on Play/Stop, so the same app runs embedded or standalone.
public interface IApplication
{
	/// Read once by the host before Configure() (frame pacing).
	ApplicationSettings Settings() => .();

	/// Register subsystems, component types, configure the host's context.
	/// This is the ONLY place subsystems should be registered.
	void Configure(IApplicationHost host) {}

	/// Called after Context.Startup(). Subsystems are initialized.
	void OnStartup(IApplicationHost host) {}

	/// Enter play. Standalone: once before the main loop. Editor: on Play.
	void OnLaunch(IApplicationHost host) {}

	/// Per-frame update.
	void OnUpdate(IApplicationHost host, float deltaTime) {}

	/// Fixed-timestep update.
	void OnFixedUpdate(IApplicationHost host, float fixedDeltaTime) {}

	/// Render into a window. Called once per window per frame.
	void OnRenderWindow(IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame) {}

	/// Leave play. Mirrors OnLaunch.
	void OnExit(IApplicationHost host) {}

	/// Called before Context.Shutdown(). Mirrors OnStartup.
	void OnShutdown(IApplicationHost host) {}
}
