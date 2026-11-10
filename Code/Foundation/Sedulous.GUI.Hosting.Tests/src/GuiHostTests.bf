using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.RHI;
using Sedulous.Shell.Null;
using Sedulous.VG.Renderer;
using Sedulous.VG.SVG;

namespace Sedulous.GUI.Hosting.Tests;

/// A null shell and device, the two VG shaders every draw needs, and a host on them.
class HostBed
{
	public NullShell Shell;
	public GraphicsDevice Device;
	public IShaderModule Vs;
	public IShaderModule Fs;
	public RenderWindow Main;
	public GuiHost Host;

	public this()
	{
		Shell = new .();
		Device = NullGraphics.CreateDevice(2).Value;
		Vs = HostingFixtures.MakeModule(Device.Raw);
		Fs = HostingFixtures.MakeModule(Device.Raw);
		Main = Device.CreateRenderWindow(Shell.MainWindow, .()).Value;
		var shaders = VgShaderSet();
		shaders.Vertex = Vs;
		shaders.Fragment = Fs;
		Host = new .(Device, Shell, null, shaders);
	}

	public ~this()
	{
		// The host before the window it drew (the window's payload frees after it), the window
		// before the device, the device after the modules it made.
		delete Host;
		delete Main;
		Device.Raw.DestroyShaderModule(ref Fs);
		Device.Raw.DestroyShaderModule(ref Vs);
		delete Device;
		delete Shell;
	}

	public NullWindow MainWindow => (NullWindow)Shell.MainWindow;
	public NullWindowManager Windows => (NullWindowManager)Shell.WindowManager;

	/// A root of the host's GUI; the caller releases it.
	public SceneRoot MakeRoot() => new SceneRoot(Host.Context);

	/// One frame of the windows: the host's update, then each rendered, then the device's turn.
	public void Frame(RenderWindow first, RenderWindow second = null)
	{
		Host.Update(1.0f / 60.0f);
		RenderWindow[2] windows = .(first, second);
		for (let window in windows)
		{
			if (window == null)
				continue;
			var frame = window.BeginFrame();
			Test.Assert(frame.Valid);
			Host.RenderWindow(ref frame);
			window.EndFrame(ref frame);
		}
		Device.AdvanceFrame();
	}
}

/// A mouse the test moves and presses, with this frame's edges.
class DrivenMouse : Sedulous.Shell.IMouse
{
	public float PointerX = 0.0f;
	public float PointerY = 0.0f;
	public bool Down = false;
	public bool Pressed = false;
	public bool Released = false;

	public float X => PointerX;
	public float Y => PointerY;
	public float GlobalX => PointerX;
	public float GlobalY => PointerY;
	public float DeltaX => 0.0f;
	public float DeltaY => 0.0f;
	public float ScrollX => 0.0f;
	public float ScrollY => 0.0f;
	public bool IsButtonDown(Sedulous.Shell.MouseButton button) => (button == .Left) && Down;
	public bool IsButtonPressed(Sedulous.Shell.MouseButton button) => (button == .Left) && Pressed;
	public bool IsButtonReleased(Sedulous.Shell.MouseButton button) => (button == .Left) && Released;
	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) {}
	public bool CursorVisible => true;
	public void SetCursorVisible(bool visible) {}
	public void SetCursor(Sedulous.Shell.CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}

/// The null devices with the driven mouse, and the window under it.
class DrivenInput : Sedulous.Shell.IInputManager
{
	public NullKeyboard NullKeys = new .() ~ delete _;
	public DrivenMouse Driven = new .() ~ delete _;
	public NullTouch NullFingers = new .() ~ delete _;
	public uint32 Hover = 0;

	public Sedulous.Shell.IKeyboard Keyboard => NullKeys;
	public Sedulous.Shell.IMouse Mouse => Driven;
	public Sedulous.Shell.ITouch Touch => NullFingers;
	public int32 GamepadCount => 0;
	public Sedulous.Shell.IGamepad GetGamepad(int32 index) => null;
	public Span<Sedulous.Shell.InputEvent> Events => .();
	public uint32 HoverWindow => Hover;
	public uint32 FocusedWindow => Hover;
	public void Update() {}
}

/// The null shell with input the test drives.
class DrivenShell : Sedulous.Shell.IShell
{
	public NullShell Inner = new .() ~ delete _;
	public DrivenInput DrivenDevices = new .() ~ delete _;

	public Sedulous.Shell.IWindowManager WindowManager => Inner.WindowManager;
	public Sedulous.Shell.IWindow MainWindow => Inner.MainWindow;
	public Sedulous.Shell.IInputManager Input => DrivenDevices;
	public Sedulous.Shell.IDialogService Dialogs => Inner.Dialogs;
	public void ProcessEvents() => Inner.ProcessEvents();
	public bool IsRunning => Inner.IsRunning;
	public void RequestExit() => Inner.RequestExit();
	public void SetMainWindowCloseHandler(delegate bool() handler) => Inner.SetMainWindowCloseHandler(handler);
	public void DrainDroppedFiles(List<Sedulous.Shell.DroppedFile> outFiles) => Inner.DrainDroppedFiles(outFiles);
	public void SetClipboardText(StringView text) => Inner.SetClipboardText(text);
	public void GetClipboardText(String outText) => Inner.GetClipboardText(outText);
	public bool HasClipboardText => Inner.HasClipboardText;
}

/// Content a node shows from outside the GUI, recording what the host asks of it.
class RecordingContent : IHostedContent
{
	public Node Shown = null; // borrowed
	public VGRenderer BoundRenderer = null;
	public uint32 BoundWindow = 0;
	public int Binds = 0;
	public int Records = 0;
	public Rectangle Placed = .();
	public Rectangle PlacedUnits = .();
	public Float2 PlacedWindow = .();
	/// Placing changes what its node shows (as a viewport made again at a new size does).
	public bool ChangesWhenPlaced = false;

	public Node HostedNode => Shown;

	public void Bind(IDevice device, VGRenderer renderer, Sedulous.Shell.IInputManager input, uint32 windowId)
	{
		Binds++;
		BoundRenderer = renderer;
		BoundWindow = windowId;
	}

	public void Place(Rectangle windowPixels, Rectangle windowUnits, Float2 windowSize)
	{
		Placed = windowPixels;
		PlacedUnits = windowUnits;
		PlacedWindow = windowSize;
		if (ChangesWhenPlaced)
			Shown.Invalidate();
	}

	public void Record(ICommandEncoder encoder, int32 frameIndex)
	{
		Records++;
	}

	public Sedulous.Shell.InputSurface HostedSurface => null;
}

/// Hosted content with an input surface of its own, as a viewport has: made on each bind to a
/// window, gone when let go.
class SurfaceContent : IHostedContent
{
	private Node mNode; // borrowed
	private Sedulous.Shell.InputSurface mSurface = null ~ delete _;

	public this(Node node)
	{
		mNode = node;
	}

	public Node HostedNode => mNode;

	public void Bind(IDevice device, VGRenderer renderer, Sedulous.Shell.IInputManager input, uint32 windowId)
	{
		DeleteAndNullify!(mSurface);
		if ((input != null) && (windowId != 0))
			mSurface = new .(input, windowId, ContentFit());
	}

	public void Place(Rectangle windowPixels, Rectangle windowUnits, Float2 windowSize)
	{
	}

	public void Record(ICommandEncoder encoder, int32 frameIndex)
	{
	}

	public Sedulous.Shell.InputSurface HostedSurface => mSurface;
}

/// GuiHost on the Null RHI backend and the null shell: a window's root gets the window's size and
/// its own renderer; a root is drawn when it needs a frame and its last batch encoded again when
/// not; the baker serves every window's renderer and a detached window's forgets its bakes; a
/// window opened for a root through the application's opener, its events told by root, the root
/// under a screen point, and closed again. (The null shell injects no input: routing is
/// checked by the sandbox on the host, and by the driven shell below.)
class GuiHostTests
{
	private static Sedulous.Shell.WindowEvent EventOf(Sedulous.Shell.WindowEventType type, uint32 windowId, int32 x = 0, int32 y = 0)
	{
		var event = Sedulous.Shell.WindowEvent();
		event.Type = type;
		event.WindowId = windowId;
		event.X = x;
		event.Y = y;
		return event;
	}

	[Test]
	public static void AWindowsRootTakesTheWindowsSizeAndARendererOfItsOwn()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		bed.Host.AttachWindow(bed.Main, root);
		Test.Assert(bed.Host.WindowCount == 1);
		Test.Assert(bed.Host.RendererFor(bed.Main) != null);
		Test.Assert(bed.Host.WindowFor(root) == bed.Main);
		let window = bed.Shell.MainWindow;
		Test.Assert(HostingFixtures.Near(root.ViewportSize.X, (float)window.Width));
		Test.Assert(HostingFixtures.Near(root.ViewportSize.Y, (float)window.Height));
		Test.Assert(bed.Host.Context.PictureBaker == (IPictureBaker)bed.Host.Baker); // its skins bake
		// A resized window resizes its root.
		bed.MainWindow.Resize(640, 360);
		bed.Frame(bed.Main);
		Test.Assert(HostingFixtures.Near(root.ViewportSize.X, 640.0f));
		Test.Assert(HostingFixtures.Near(root.ViewportSize.Y, 360.0f));
	}

	[Test]
	public static void AWindowsMultisampledTargetsFollowTheBackbufferEachFrameDrawsIntoNotTheWindowAndNeverWait()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		bed.Host.AttachWindow(bed.Main, root);
		bed.Frame(bed.Main);
		var targets = bed.Host.PassTargetsFor(bed.Main);
		Test.Assert(targets != null); // the null device takes the multisampled pass
		let width = bed.Main.Swap.Width;
		let height = bed.Main.Swap.Height;
		Test.Assert(targets.Matches(width, height));

		// Resized, the swapchain not yet (a live resize: the backbuffer lags the window). The frame
		// draws at the backbuffer's size, the targets with it.
		bed.MainWindow.Resize(640, 360);
		bed.Frame(bed.Main);
		Test.Assert(bed.Main.Swap.Width == width);
		Test.Assert(targets.Matches(width, height));

		Test.Assert(bed.Host.RetiredTargetsFor(bed.Main) == 0); // nothing replaced

		// The swapchain catches up: new targets at its size, made without waiting for the GPU; the
		// old kept while the frames in flight (two) may still draw into them.
		Test.Assert(bed.Main.SyncSize());
		bed.Frame(bed.Main);
		targets = bed.Host.PassTargetsFor(bed.Main);
		Test.Assert(targets != null);
		Test.Assert(targets.Matches(640, 360));
		Test.Assert(bed.Host.RetiredTargetsFor(bed.Main) == 1);
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.RetiredTargetsFor(bed.Main) == 1);
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.RetiredTargetsFor(bed.Main) == 0);
	}

	[Test]
	public static void SizePanesGivesTheRootsAResizedWindowsSizeBeforeTheFramesUpdate()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		bed.Host.AttachWindow(bed.Main, root);
		bed.Frame(bed.Main);
		bed.MainWindow.Resize(700, 420);
		bed.Host.SetPaneRegion(root, .(0.0f, 0.0f, 500.0f, 420.0f)); // an application's layout of its panes
		bed.Host.SizePanes(); // what it lays out from is this frame's, not the last's
		Test.Assert(HostingFixtures.Near(root.ViewportSize.X, 500.0f));
		Test.Assert(HostingFixtures.Near(root.ViewportSize.Y, 420.0f));
		let drawn = bed.Host.FramesDrawn;
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.FramesDrawn == drawn + 1); // the new size is drawn
	}

	[Test]
	public static void ARootDrawsWhenItNeedsAFrameElseItsWindowEncodesTheLastBatchAgain()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		root.AddChild(panel);
		bed.Host.AttachWindow(bed.Main, root);
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.FramesDrawn == 1);
		bed.Frame(bed.Main); // nothing changed
		Test.Assert(bed.Host.FramesDrawn == 1);
		Test.Assert(bed.Host.FramesReused == 1);
		panel.Invalidate(); // something did
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.FramesDrawn == 2);
	}

	[Test]
	public static void TheBakerServesEveryWindowAndADetachedWindowsRendererForgetsItsBakes()
	{
		let bed = scope HostBed();
		let second = bed.Shell.WindowManager.CreateWindow(.());
		Test.Assert(second case .Ok);
		let other = bed.Device.CreateRenderWindow(second.Value, .()).Value;
		defer delete other;
		let mainRoot = bed.MakeRoot();
		defer mainRoot.ReleaseRef();
		let otherRoot = bed.MakeRoot();
		defer otherRoot.ReleaseRef();
		bed.Host.AttachWindow(bed.Main, mainRoot);
		bed.Host.AttachWindow(other, otherRoot);
		Test.Assert(bed.Host.WindowCount == 2);
		Test.Assert(bed.Host.Baker != null);

		let document = HostingFixtures.LoadPicture(HostingFixtures.cSquarePicture);
		defer delete document;
		Test.Assert(bed.Host.Baker.Baked(document, 16, 16) == null); // queued
		bed.Frame(bed.Main, other);
		let key = bed.Host.Baker.Baked(document, 16, 16);
		Test.Assert(key != null);
		Test.Assert(bed.Host.RendererFor(bed.Main).IsExternalTextureRegistered(key));
		Test.Assert(bed.Host.RendererFor(other).IsExternalTextureRegistered(key));

		let gone = bed.Host.RendererFor(other);
		let held = otherRoot.RefCount;
		bed.Host.DetachWindow(other);
		Test.Assert(otherRoot.RefCount == held - 1); // the root let go at once, not when the window goes
		Test.Assert(bed.Host.WindowCount == 1);
		Test.Assert(bed.Host.WindowFor(otherRoot) == null);
		Test.Assert(!gone.IsExternalTextureRegistered(key)); // the payload lives until its window goes
		Test.Assert(bed.Host.RendererFor(bed.Main).IsExternalTextureRegistered(key));
		bed.Frame(bed.Main);
	}

	[Test]
	public static void AnOffscreenTargetDrawsARootAtItsOwnSizeTimedAndReadsItBack()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		root.AddChild(panel);
		let offscreen = scope GuiOffscreen(bed.Host, 320, 200);
		Test.Assert(offscreen.IsReady);
		let picture = scope Sedulous.Image.Image();
		let folder = "scratch_gui_hosting";
		Directory.CreateDirectory(folder).IgnoreError();
		let path = scope $"{folder}/offscreen.png";
		defer { File.Delete(path).IgnoreError(); }
		GuiOffscreen.Times times = .();
		Test.Assert(offscreen.Picture(root, path, picture, out times));
		Test.Assert(File.Exists(path));
		Test.Assert(HostingFixtures.Near(root.ViewportSize.X, 320.0f));
		Test.Assert(HostingFixtures.Near(root.ViewportSize.Y, 200.0f));
		Test.Assert(picture.Width == 320);
		Test.Assert(picture.Height == 200);
		Test.Assert(times.Draw >= 0.0);
		Test.Assert(times.Gpu >= 0.0);
		Test.Assert(root.LastFrameStats.FramesDrawn == 1); // a frame of the root's, counted as a window's are
		Test.Assert(offscreen.Draw(root)); // again, nothing read back or written
	}

	[Test]
	public static void APaneIsAnotherRootOverARegionOfAWindowLaidOutAtItsSize()
	{
		let bed = scope HostBed();
		bed.MainWindow.Resize(800, 600);
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let pane = bed.MakeRoot();
		defer pane.ReleaseRef();
		bed.Host.AttachWindow(bed.Main, root);
		bed.Host.SetPaneRegion(root, .(0.0f, 0.0f, 600.0f, 600.0f));
		bed.Host.AddPane(bed.Main, pane, .(600.0f, 0.0f, 200.0f, 600.0f));
		bed.Frame(bed.Main);
		Test.Assert(HostingFixtures.Near(root.ViewportSize.X, 600.0f));
		Test.Assert(HostingFixtures.Near(pane.ViewportSize.X, 200.0f));
		Test.Assert(HostingFixtures.Near(pane.ViewportSize.Y, 600.0f));
		Test.Assert(bed.Host.WindowFor(pane) == bed.Main);
		Test.Assert(HostingFixtures.Near(bed.Host.PaneArea(pane).X, 600.0f));
		let drawn = bed.Host.FramesDrawn;
		bool overlaid = false;
		bed.Host.SetOverlay(new [&] (overWindow, overContext) => { overlaid = true; });
		bed.Host.SetPaneRegion(pane, .(560.0f, 0.0f, 240.0f, 600.0f)); // the pane widened
		bed.Host.SetPaneRegion(root, .(0.0f, 0.0f, 560.0f, 600.0f));
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.FramesDrawn == drawn + 1);
		Test.Assert(overlaid);
		Test.Assert(HostingFixtures.Near(pane.ViewportSize.X, 240.0f));
		let before = bed.Host.FramesDrawn;
		bed.Host.SetPaneRegion(pane, .(560.0f, 0.0f, 240.0f, 600.0f)); // the same again, as a host's layout does each frame
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.FramesDrawn == before); // nothing to draw
		bed.Host.RemovePane(pane);
		Test.Assert(bed.Host.WindowFor(pane) == null);
		Test.Assert(bed.Host.WindowFor(root) == bed.Main);
	}

	[Test]
	public static void AWindowOpenedForARootItsEventsToldByItsRootTheRootUnderAScreenPointClosedAgain()
	{
		let bed = scope HostBed();
		let mainRoot = bed.MakeRoot();
		defer mainRoot.ReleaseRef();
		bed.Host.AttachWindow(bed.Main, mainRoot);
		Test.Assert(!bed.Host.CanOpenWindows);
		let stray = bed.MakeRoot();
		defer stray.ReleaseRef();
		Test.Assert(bed.Host.OpenWindow(stray, .()) == null); // no opener, no window

		let windows = bed.Windows;
		let opened = scope List<RenderWindow>();
		defer { ClearAndDeleteItems!(opened); }
		int closed = 0;
		let opener = new GuiHost.WindowOpener();
		opener.Open = new [&] (asked) =>
			{
				if (!(windows.CreateWindow(asked) case .Ok(let made)))
					return null;
				let rendered = bed.Device.CreateRenderWindow(made, .()).Value;
				opened.Add(rendered);
				return rendered;
			};
		opener.Close = new [&] (closing) =>
			{
				closed++;
				windows.DestroyWindow(closing.Window);
			};
		bed.Host.SetWindowOpener(opener);
		Test.Assert(bed.Host.CanOpenWindows);
		Test.Assert(bed.Host.PlacesWindows); // the null shell is no Wayland

		var settings = Sedulous.Shell.WindowSettings();
		settings.Positioned = true;
		settings.X = 1500;
		settings.Y = 100;
		settings.Width = 300;
		settings.Height = 200;
		let second = bed.MakeRoot();
		defer second.ReleaseRef();
		let window = bed.Host.OpenWindow(second, settings);
		Test.Assert(window != null);
		Test.Assert(bed.Host.WindowCount == 2);
		Test.Assert(bed.Host.WindowFor(second) == window);
		bed.Frame(bed.Main, window);
		Test.Assert(HostingFixtures.Near(second.ViewportSize.X, 300.0f));

		// Where each root is on the screen.
		Float2 local = .();
		Test.Assert(bed.Host.RootAt(.(1550.0f, 150.0f), out local) == second);
		Test.Assert(HostingFixtures.Near(local.X, 50.0f));
		Test.Assert(HostingFixtures.Near(local.Y, 50.0f));
		Test.Assert(bed.Host.RootAt(.(10.0f, 10.0f)) == mainRoot);
		Test.Assert(bed.Host.RootAt(.(-50.0f, -50.0f)) == null);
		Float2 screen = .();
		Test.Assert(bed.Host.ToScreen(second, .(5.0f, 6.0f), out screen));
		Test.Assert(HostingFixtures.Near(screen.X, 1505.0f));
		Test.Assert(HostingFixtures.Near(screen.Y, 106.0f));
		// The same, as its GUI's drags ask it.
		let places = bed.Host.Context.RootPlaces;
		Test.Assert(places != null);
		Test.Assert(places.DispatcherAt(.(1550.0f, 150.0f), out local) == second.EventDispatcher);
		Test.Assert(places.ToScreen(second.EventDispatcher, .(5.0f, 6.0f), out screen));
		Test.Assert(HostingFixtures.Near(screen.X, 1505.0f));

		// Overlapping, the window focused last is on top.
		window.Window.SetPosition(5, 5);
		windows.PostEvent(EventOf(.FocusGained, window.Window.Id));
		bed.Frame(bed.Main, window);
		windows.ClearEvents();
		Test.Assert(bed.Host.RootAt(.(50.0f, 50.0f)) == second);
		windows.PostEvent(EventOf(.FocusGained, bed.Main.Window.Id));
		bed.Frame(bed.Main, window);
		windows.ClearEvents();
		Test.Assert(bed.Host.RootAt(.(50.0f, 50.0f)) == mainRoot);

		// Its events, told by its root; a close asked for closes nothing by itself.
		let told = scope List<Sedulous.Shell.WindowEvent>();
		SceneRoot toldRoot = null;
		int alsoTold = 0;
		bed.Host.AddWindowEventListener(new [&] (byRoot, happened) =>
			{
				toldRoot = byRoot;
				told.Add(happened);
			});
		let also = bed.Host.AddWindowEventListener(new [&] (byRoot, happened) => { alsoTold++; });
		windows.PostEvent(EventOf(.Moved, window.Window.Id, 40, 30));
		windows.PostEvent(EventOf(.CloseRequested, window.Window.Id));
		windows.PostEvent(EventOf(.Moved, 999)); // no window of its own
		bed.Frame(bed.Main, window);
		windows.ClearEvents();
		Test.Assert(told.Count == 2);
		Test.Assert(toldRoot == second);
		Test.Assert(told[0].Type == .Moved);
		Test.Assert(told[0].X == 40);
		Test.Assert(told[1].Type == .CloseRequested);
		Test.Assert(alsoTold == 2); // every listener is told
		Test.Assert(bed.Host.WindowCount == 2);
		bed.Host.RemoveWindowEventListener(also);
		windows.PostEvent(EventOf(.FocusLost, window.Window.Id));
		bed.Frame(bed.Main, window);
		windows.ClearEvents();
		Test.Assert(told.Count == 3);
		Test.Assert(alsoTold == 2); // removed: told no more
		// One removed by another while they are told is told no more, that time included.
		int laterTold = 0;
		uint32 later = 0;
		bed.Host.AddWindowEventListener(new [&] (byRoot, happened) => { bed.Host.RemoveWindowEventListener(later); });
		later = bed.Host.AddWindowEventListener(new [&] (byRoot, happened) => { laterTold++; });
		windows.PostEvent(EventOf(.FocusLost, window.Window.Id));
		bed.Frame(bed.Main, window);
		windows.ClearEvents();
		Test.Assert(told.Count == 4);
		Test.Assert(laterTold == 0);

		// Where the shell's windows hold no place (Wayland), nothing is said of where roots are.
		windows.SetCapabilities(.(true, false));
		Test.Assert(!bed.Host.PlacesWindows);
		Test.Assert(bed.Host.RootAt(.(50.0f, 50.0f)) == null);
		Test.Assert(!bed.Host.ToScreen(second, .(5.0f, 6.0f), out screen));
		Test.Assert(bed.Host.CanOpenWindows);
		// Where it opens no window beside the main one (the web), the host opens none.
		windows.SetCapabilities(.(false, false));
		Test.Assert(!bed.Host.CanOpenWindows);
		let refused = bed.MakeRoot();
		defer refused.ReleaseRef();
		Test.Assert(bed.Host.OpenWindow(refused, settings) == null);
		windows.SetCapabilities(.(true, true));

		bed.Host.CloseWindow(second);
		Test.Assert(closed == 1);
		Test.Assert(bed.Host.WindowCount == 1);
		Test.Assert(bed.Host.WindowFor(second) == null);
		Test.Assert(bed.Host.RootAt(.(50.0f, 50.0f)) == mainRoot);
		bed.Frame(bed.Main);
	}

	[Test]
	public static void TheReleaseOfAPressReachesItsWindowThoughThePointerIsOverNoWindowWithOthersOpen()
	{
		let shell = scope DrivenShell();
		let device = NullGraphics.CreateDevice(2).Value;
		var vs = HostingFixtures.MakeModule(device.Raw);
		var fs = HostingFixtures.MakeModule(device.Raw);
		{
			let main = device.CreateRenderWindow(shell.MainWindow, .()).Value;
			let windows = (NullWindowManager)shell.WindowManager;
			var settings = Sedulous.Shell.WindowSettings();
			settings.Width = 200;
			settings.Height = 150;
			let other = device.CreateRenderWindow(windows.CreateWindow(settings).Value, .()).Value;
			var shaders = VgShaderSet();
			shaders.Vertex = vs;
			shaders.Fragment = fs;
			let host = new GuiHost(device, shell, null, shaders);
			let mainRoot = new SceneRoot(host.Context);
			let otherRoot = new SceneRoot(host.Context);
			let panel = new Panel();
			panel.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(100.0f);
					s.Height = LayoutLength.Px(100.0f);
				});
			mainRoot.AddChild(panel);
			int downs = 0;
			int ups = 0;
			panel.AddEventListener(.MouseDown, new [&] (e) => { downs++; });
			panel.AddEventListener(.MouseUp, new [&] (e) => { ups++; });
			host.AttachWindow(main, mainRoot);
			host.AttachWindow(other, otherRoot);
			let mouse = shell.DrivenDevices.Driven;
			void Frame(uint32 hover, float x, float y, bool down, bool edge)
			{
				shell.DrivenDevices.Hover = hover;
				mouse.PointerX = x;
				mouse.PointerY = y;
				mouse.Pressed = edge && down;
				mouse.Released = edge && !down;
				mouse.Down = down;
				host.Update(1.0f / 60.0f);
				device.AdvanceFrame();
			}
			let mainId = main.Window.Id;
			Frame(mainId, 50.0f, 50.0f, false, false); // laid out, the pointer over the panel
			Frame(mainId, 50.0f, 50.0f, true, true); // pressed on it
			Test.Assert(downs == 1);
			Frame(0, 900.0f, 50.0f, true, false); // dragged off every window
			Frame(0, 900.0f, 50.0f, false, true); // let go there
			Test.Assert(ups == 1);
			host.DetachWindow(other);
			host.DetachWindow(main);
			delete host;
			panel.ReleaseRef();
			otherRoot.ReleaseRef();
			mainRoot.ReleaseRef();
			delete other;
			delete main;
		}
		device.Raw.DestroyShaderModule(ref fs);
		device.Raw.DestroyShaderModule(ref vs);
		delete device;
	}

	[Test]
	public static void OnAScaledDisplayTheGuiFillsTheWindowsPixelsAndThePointerInWindowUnitsLandsWhereItShows()
	{
		let shell = scope DrivenShell();
		// 175%: the OS counts the window in units, each 1.75 pixels (a 4K screen's 3840 is 2194 units).
		let window = (NullWindow)shell.MainWindow;
		window.Resize(800, 600);
		window.SetPixelDensity(1.75f);
		let device = NullGraphics.CreateDevice(2).Value;
		var vs = HostingFixtures.MakeModule(device.Raw);
		var fs = HostingFixtures.MakeModule(device.Raw);
		{
			let main = device.CreateRenderWindow(window, .()).Value;
			Test.Assert(main.Swap.Width == 1400, "the swapchain is the window's pixels");
			Test.Assert(main.Swap.Height == 1050);
			var shaders = VgShaderSet();
			shaders.Vertex = vs;
			shaders.Fragment = fs;
			let host = new GuiHost(device, shell, null, shaders);
			let root = new SceneRoot(host.Context);
			// A panel in the bottom right quarter of what the root lays out.
			let panel = new Panel();
			panel.EditLayoutStyle(scope (s) =>
				{
					s.Placement = .Absolute;
					s.Left = LayoutLength.Px(1050.0f);
					s.Top = LayoutLength.Px(787.0f);
					s.Width = LayoutLength.Px(350.0f);
					s.Height = LayoutLength.Px(263.0f);
				});
			root.AddChild(panel);
			int downs = 0;
			panel.AddEventListener(.MouseDown, new [&] (e) => { downs++; });
			host.AttachWindow(main, root);
			Test.Assert(Math.Abs(root.ViewportSize.X - 1400.0f) < 0.01f, "all of it, not the 800 units' corner");
			Test.Assert(Math.Abs(root.ViewportSize.Y - 1050.0f) < 0.01f);
			let mouse = shell.DrivenDevices.Driven;
			let id = main.Window.Id;
			void Frame(float x, float y, bool down, bool edge)
			{
				shell.DrivenDevices.Hover = id;
				mouse.PointerX = x;
				mouse.PointerY = y;
				mouse.Pressed = edge && down;
				mouse.Released = edge && !down;
				mouse.Down = down;
				host.Update(1.0f / 60.0f);
				device.AdvanceFrame();
			}
			// The pointer at (700, 525) units is (1225, 919) pixels: on the panel.
			Frame(700.0f, 525.0f, false, false);
			Frame(700.0f, 525.0f, true, true);
			Test.Assert(downs == 1);
			Frame(700.0f, 525.0f, false, true);
			// At (500, 400) units it is (875, 700) pixels: above and left of it, though in units the
			// panel's own numbers would have held it.
			Frame(500.0f, 400.0f, false, false);
			Frame(500.0f, 400.0f, true, true);
			Test.Assert(downs == 1);
			host.DetachWindow(main);
			delete host;
			panel.ReleaseRef();
			root.ReleaseRef();
			delete main;
		}
		device.Raw.DestroyShaderModule(ref fs);
		device.Raw.DestroyShaderModule(ref vs);
		delete device;
	}

	/// Added in the port: content a node shows from outside the GUI is bound to the renderer of the
	/// window its node is in, placed over the node, recorded on that window's frames, and let go
	/// when the window goes.
	[Test]
	public static void HostedContentIsBoundToItsNodesWindowPlacedOverTheNodeRecordedAndLetGoWithTheWindow()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		panel.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(50.0f);
			});
		root.AddChild(panel);
		let content = scope RecordingContent();
		content.Shown = panel;
		bed.Host.AddContent(content);
		bed.Host.AddContent(content); // twice: still once
		bed.Frame(bed.Main);
		Test.Assert(content.Binds == 0); // its node is in no window yet

		bed.Host.AttachWindow(bed.Main, root);
		bed.Frame(bed.Main);
		Test.Assert(content.Binds == 1);
		Test.Assert(content.BoundRenderer == bed.Host.RendererFor(bed.Main));
		Test.Assert(content.BoundWindow == bed.Main.Window.Id);
		Test.Assert(HostingFixtures.Near(content.Placed.Width, 100.0f));
		Test.Assert(HostingFixtures.Near(content.Placed.Height, 50.0f));
		Test.Assert(HostingFixtures.Near(content.PlacedWindow.X, (float)bed.Main.Window.Width));
		Test.Assert(HostingFixtures.Near(content.PlacedWindow.Y, (float)bed.Main.Window.Height));
		Test.Assert(content.Records == 1);
		bed.Frame(bed.Main);
		Test.Assert(content.Binds == 1); // the same window: bound once
		Test.Assert(content.Records == 2); // each of its window's frames

		// Its window goes: it lets the window's renderer go.
		bed.Host.DetachWindow(bed.Main);
		Test.Assert(content.Binds == 2);
		Test.Assert(content.BoundRenderer == null);
		Test.Assert(content.BoundWindow == 0);
		bed.Host.RemoveContent(content);
		Test.Assert(content.Binds == 2); // already let go: told nothing more
	}

	/// Added in the port: what changes as content is placed (after the panes were asked whether
	/// they need a frame) is drawn that frame, never left to a reused batch that may show what
	/// the content just freed.
	[Test]
	public static void ContentThatChangesAsItIsPlacedIsDrawnThatFrameNotReused()
	{
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		root.AddChild(panel);
		let content = scope RecordingContent();
		content.Shown = panel;
		bed.Host.AddContent(content);
		bed.Host.AttachWindow(bed.Main, root);
		bed.Frame(bed.Main);
		bed.Frame(bed.Main);
		let drawn = bed.Host.FramesDrawn;
		let reused = bed.Host.FramesReused;
		Test.Assert(reused > 0); // idle: the last batch again
		content.ChangesWhenPlaced = true;
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.FramesDrawn == drawn + 1);
		Test.Assert(bed.Host.FramesReused == reused);
		content.ChangesWhenPlaced = false;
		bed.Host.RemoveContent(content);
	}

	[Test]
	public static void TheUiScaleKeepsBetweenHalfAndThreeTimes()
	{
		let bed = scope HostBed();
		Test.Assert(bed.Host.UiScale == 1.0f);
		bed.Host.UiScale = 1.5f;
		Test.Assert(bed.Host.UiScale == 1.5f);
		bed.Host.UiScale = 10.0f;
		Test.Assert(bed.Host.UiScale == 3.0f);
		bed.Host.UiScale = 0.1f;
		Test.Assert(bed.Host.UiScale == 0.5f);
	}

	[Test]
	public static void ContentWhoseNodeIsNotShownLeavesTheInputRouterUntilItIs()
	{
		// Two pages' viewports in one place: the one behind kept that place, and the router's last
		// match gave it the pointer meant for the one in front.
		let bed = scope HostBed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let front = new Panel();
		defer front.ReleaseRef();
		let behind = new Panel();
		defer behind.ReleaseRef();
		root.AddChild(front);
		root.AddChild(behind);
		let first = scope SurfaceContent(front);
		let second = scope SurfaceContent(behind);
		bed.Host.AttachWindow(bed.Main, root);
		bed.Host.AddContent(first);
		bed.Host.AddContent(second);
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.Routes(first));
		Test.Assert(bed.Host.Routes(second));

		behind.Displayed = false; // its tab goes behind
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.Routes(first));
		Test.Assert(!bed.Host.Routes(second));
		behind.Displayed = true; // and comes to the front again
		bed.Frame(bed.Main);
		Test.Assert(bed.Host.Routes(second));

		bed.Host.RemoveContent(second);
		bed.Host.RemoveContent(first);
	}
}
