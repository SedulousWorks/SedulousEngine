using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.RHI;
using Sedulous.Shell.Null;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// A host on the null device and shell, its main window's root holding a DockArea of the profiler
/// and the memory panels; the application's opener makes null windows.
class HostWindowsBed
{
	public NullShell Shell = new .();
	public GraphicsDevice Device;
	public IShaderModule Vs;
	public IShaderModule Fs;
	public RenderWindow Main;
	public GuiHost Host;
	public List<RenderWindow> Opened = new .();
	public int Closed = 0;
	public DockController Controller = new .();
	public SceneRoot Root;
	public DockArea Area;

	public this()
	{
		Device = NullGraphics.CreateDevice(2).Value;
		Vs = MakeModule(Device.Raw);
		Fs = MakeModule(Device.Raw);
		Main = Device.CreateRenderWindow(Shell.MainWindow, .()).Value;
		var shaders = VgShaderSet();
		shaders.Vertex = Vs;
		shaders.Fragment = Fs;
		Host = new .(Device, Shell, null, shaders);
		let opener = new GuiHost.WindowOpener();
		opener.Open = new (settings) =>
			{
				if (!(Windows.CreateWindow(settings) case .Ok(let made)))
					return null;
				let rendered = Device.CreateRenderWindow(made, .()).Value;
				Opened.Add(rendered);
				return rendered;
			};
		opener.Close = new (window) =>
			{
				++Closed;
				Windows.DestroyWindow(window.Window);
			};
		Host.SetWindowOpener(opener);
		String[2] ids = .("profiler", "memory");
		String[2] titles = .("Profiler", "Memory");
		for (int i < 2)
			Test.Assert(Controller.Register(PanelNamed(ids[i], titles[i])));
		Root = new SceneRoot(Host.Context);
		Area = new DockArea();
		Area.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Percent(100.0f);
				s.Height = LayoutLength.Percent(100.0f);
			});
		Root.AddChild(Area);
		Host.AttachWindow(Main, Root);
		Area.Show(Controller);
	}

	public ~this()
	{
		// The area and its root, then the host (which held the root), the windows it drew, the
		// device after the modules it made; the controller after the views showing it.
		Area.ReleaseRef();
		Root.ReleaseRef();
		delete Host;
		DeleteContainerAndItems!(Opened);
		delete Main;
		Device.Raw.DestroyShaderModule(ref Fs);
		Device.Raw.DestroyShaderModule(ref Vs);
		delete Device;
		delete Controller;
		delete Shell;
	}

	public NullWindowManager Windows => (NullWindowManager)Shell.WindowManager;

	public void Frame()
	{
		Host.Update(1.0f / 60.0f);
		Device.AdvanceFrame();
	}

	/// A module the caller destroys.
	public static IShaderModule MakeModule(IDevice device)
	{
		uint8[4] code = .(0, 0, 0, 0);
		var desc = ShaderModuleDesc();
		desc.Code = .(&code[0], 4);
		desc.EntryPoint = "main";
		if (device.CreateShaderModule(desc) case .Ok(let module))
			return module;
		return null;
	}

	public static Sedulous.Shell.WindowEvent EventOf(Sedulous.Shell.WindowEventType type, uint32 windowId, int32 x = 0, int32 y = 0)
	{
		var event = Sedulous.Shell.WindowEvent();
		event.Type = type;
		event.WindowId = windowId;
		event.X = x;
		event.Y = y;
		return event;
	}
}

/// A DockArea's floats in OS windows on the GUI's host (D6 of Specs/gui-lab-evolution-3.md), on
/// the Null RHI backend and the null shell: a float opens a window of its own at its bounds, titled,
/// its content a root of the host's GUI; retitled and placed as the layout has it; the user's moves
/// come back to the layout and the window's close closes its panels; where the shell's windows hold
/// no place, a window opens where the system puts it.
class DockHostWindowsTests
{
	[Test]
	public static void AFloatOpensAWindowOfItsOwnAtItsBoundsTitledPlacedAndRetitledAsTheLayoutHasItMovedAndClosedByTheUser()
	{
		let bed = scope HostWindowsBed();
		DockSurfaceId floating = cNoDock;
		Test.Assert(bed.Controller.Edit(scope [&] (l) => l.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f), &floating)).Ok);
		bed.Frame();
		{
			let windows = scope DockHostWindows(bed.Host, bed.Area);
			Test.Assert(windows.CanOpen);
			SceneRoot made = null;
			windows.SetOnRootMade(new [&] (root) => { made = root; });
			bed.Area.SetWindows(windows);
			Test.Assert(bed.Host.WindowCount == 2);
			let root = windows.RootOf(floating);
			Test.Assert(root != null);
			let window = bed.Host.WindowFor(root);
			Test.Assert(window != null);
			let os = (NullWindow)window.Window;
			// The main window is at the screen's origin: the area's 100,80 is the screen's.
			Test.Assert(os.X == 100);
			Test.Assert(os.Y == 80);
			Test.Assert(os.Width == 300);
			Test.Assert(os.Title == "Profiler");
			Test.Assert(bed.Area.WindowSpaceOf(floating).RootNode == root);
			Test.Assert(made == root); // told, to style it
			bed.Frame();

			// Another panel in it: retitled. The layout moving it: placed there.
			Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
			Test.Assert(os.Title == "Memory +1");
			bed.Controller.NoteSurfaceBounds(floating, .(400.0f, 300.0f, 320.0f, 240.0f));
			bed.Area.ShowLayout();
			Test.Assert(os.X == 400);
			Test.Assert(os.Height == 240);

			// Moved by the user (the system moves it): the layout hears where it is.
			os.SetPosition(500, 350);
			bed.Windows.PostEvent(HostWindowsBed.EventOf(.Moved, os.Id, 500, 350));
			bed.Frame();
			bed.Windows.ClearEvents();
			Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.X, 500.0f));

			// Its close button: its panels close, and the window with its surface.
			bed.Windows.PostEvent(HostWindowsBed.EventOf(.CloseRequested, os.Id));
			bed.Frame();
			bed.Windows.ClearEvents();
			Test.Assert(bed.Controller.Layout.FindSurface(floating) == null);
			Test.Assert(bed.Controller.Layout.StackOf("profiler") == cNoDock);
			Test.Assert(bed.Closed == 1);
			Test.Assert(bed.Host.WindowCount == 1);
			bed.Area.SetWindows(null);
		}
	}

	[Test]
	public static void WhereTheShellsWindowsHoldNoPlaceAFloatsWindowOpensWhereTheSystemPutsIt()
	{
		let bed = scope HostWindowsBed();
		bed.Windows.SetCapabilities(.(true, false)); // as Wayland is
		DockSurfaceId floating = cNoDock;
		Test.Assert(bed.Controller.Edit(scope [&] (l) => l.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f), &floating)).Ok);
		bed.Frame();
		let windows = scope DockHostWindows(bed.Host, bed.Area);
		defer { bed.Area.SetWindows(null); }
		bed.Area.SetWindows(windows);
		let root = windows.RootOf(floating);
		Test.Assert(root != null);
		let os = bed.Host.WindowFor(root).Window;
		Test.Assert(os.X == 0); // not positioned: where the system puts it (the null shell's origin)
		Test.Assert(os.Width == 300);
		// Its place is not known: the layout keeps its size alone.
		Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.X, 0.0f));
		Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.Width, 300.0f));
		bed.Area.SetWindows(null);
		Test.Assert(bed.Host.WindowCount == 1);
	}

	/// A float's window resized by the user (the system sizes it): the layout hears its size, and
	/// the window is not placed again for it; the surface cycle raises the window it goes to.
	[Test]
	public static void AFloatsWindowResizedByTheUserGivesTheLayoutItsSizeTheSurfaceCycleRaisesIt()
	{
		let bed = scope HostWindowsBed();
		DockSurfaceId floating = cNoDock;
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.CentralStack)).Ok);
		Test.Assert(bed.Controller.Edit(scope [&] (l) => l.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f), &floating)).Ok);
		bed.Frame();
		let windows = scope DockHostWindows(bed.Host, bed.Area);
		defer { bed.Area.SetWindows(null); }
		bed.Area.SetWindows(windows);
		let os = (NullWindow)bed.Host.WindowFor(windows.RootOf(floating)).Window;
		os.Resize(420, 260);
		bed.Windows.PostEvent(HostWindowsBed.EventOf(.Resized, os.Id));
		bed.Frame();
		bed.Windows.ClearEvents();
		let bounds = bed.Controller.Layout.FindSurface(floating).Bounds;
		Test.Assert(Near(bounds.Width, 420.0f));
		Test.Assert(Near(bounds.Height, 260.0f));
		Test.Assert(Near(bounds.X, 100.0f)); // where it is: it was not moved
		bed.Area.ShowLayout(); // its window is where the layout has it: placed again, nothing changes
		Test.Assert(os.Width == 420);
		Test.Assert(os.X == 100);

		// From the main surface's stack, the next surface is the float's window: raised.
		let raised = os.RaiseCount;
		Test.Assert(bed.Area.MainSpace.FocusStack(bed.Controller.Layout.CentralStack));
		Test.Assert(bed.Area.FocusNextSurface(false));
		Test.Assert(os.RaiseCount == raised + 1);
		Test.Assert(bed.Area.WindowSpaceOf(floating).FocusedStack == bed.Controller.Layout.StackOf("profiler"));
		bed.Area.SetWindows(null);
	}
}
