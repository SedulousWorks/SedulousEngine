using Sedulous.RuntimeGraphics;
using Sedulous.Shell;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Client;

/// The host as seen by the application: register subsystems via Ctx, reach
/// platform/graphics services, manage runtime windows, request exit.
/// Implemented by ApplicationHost (and by the editor for its embedded runtime).
public interface IApplicationHost
{
	/// The subsystem container. Register subsystems here in Configure().
	Context Ctx { get; }

	/// The platform shell (windowing, input, clipboard).
	IShell Shell { get; }

	/// The shared GPU device (null for headless runs).
	GraphicsDevice Graphics { get; }

	/// The main window (created during Start). Null for headless runs.
	RenderWindow MainWindow { get; }

	/// Open an OS window at runtime backed by a RenderWindow.
	/// Returns null when running headless (no graphics).
	RenderWindow OpenWindow(WindowSettings settings, RenderWindowDesc renderDesc);

	/// Close a window (deferred to frame end).
	void CloseWindow(RenderWindow window);

	/// Request the host to exit. Standalone exits the process; editor stops the play session.
	void RequestExit(int32 code = 0);
}
