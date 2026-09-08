using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Shell;

namespace Sedulous.Runtime.Client;

/// The host as the application sees it.
///
/// Implemented by ApplicationHost for a standalone run and by an embedded host for the
/// editor, which is what lets ONE application run either way without a line changing.
interface IApplicationHost
{
	/// Where the application registers its subsystems. The host forces none in.
	Context Context { get; }

	IShell Shell { get; }
	GraphicsDevice Graphics { get; }

	/// The main window's RenderWindow, created by the host before OnStartup. NULL when
	/// running headless, and null for an embedded run, which renders into the embedder's
	/// viewport texture instead. Code that attaches a root UI to it must tolerate that.
	RenderWindow MainRenderWindow { get; }

	/// Opens an OS window with a RenderWindow behind it, the basis for a detachable UI
	/// window. Null when headless.
	RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc);

	/// Queues a window for destruction at FRAME END, once the GPU is done with it.
	void CloseWindow(RenderWindow window);

	void RequestExit(int code = 0);
}
