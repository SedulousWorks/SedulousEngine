using System;
using Sedulous.Engine.GUI;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.VFS;

namespace Sedulous.Editor.GUI.Tests;

/// A headless host whose subsystem manager has the GUI, started, reading its built-in font through
/// the data root: what a page's preview builds in. No shell, graphics or windows, so a page
/// never binds its viewport.
class GuiPageHost : IApplicationHost
{
	public SubsystemManager Subsystems { get; } = new .() ~ delete _;
	/// Declared before the subsystem that borrows it, so it goes after.
	public NativeFileSystem DataMount ~ delete _;
	/// OWNED: RegisterSubsystem borrows, and the subsystem takes a constructor argument.
	public GuiSubsystem Gui ~ delete _;

	public this()
	{
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		if (!dataRoot.IsEmpty)
			DataMount = new NativeFileSystem(dataRoot);
		Gui = new GuiSubsystem(DataMount);
		Subsystems.RegisterSubsystem<GuiSubsystem>(Gui);
		Subsystems.Startup();
	}

	public ~this()
	{
		// DISPOSED rather than shut down: unregistering has to happen while the borrowed subsystem
		// is still alive, and the field destructors run after this body.
		Subsystems.Dispose();
	}

	public IShell Shell => null;
	public GraphicsDevice Graphics => null;
	public RenderWindow MainRenderWindow => null;

	public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) =>
		null;

	public void CloseWindow(RenderWindow window) {}
	public void RequestExit(int code = 0) {}
}
