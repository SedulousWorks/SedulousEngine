using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.RHI;
using Sedulous.Shell.Null;

// Not Sedulous.GUI.Viewport.Tests: that would make Sedulous.GUI.Viewport a namespace beside the
// Viewport class it tests.
namespace Sedulous.GUI.ViewportTests;

/// A null shell and device, the two VG shaders every draw needs, a host on them, and a 320 by 200
/// viewport in the main window's root (800 by 600), hosted.
class ViewportBed
{
	public NullShell Shell;
	public GraphicsDevice Device;
	public IShaderModule Vs;
	public IShaderModule Fs;
	public RenderWindow Main;
	public GuiHost Host;
	public SceneRoot Root;
	/// The bed's reference (the root holds one of its own); null once a test let it go.
	public Viewport Viewport;

	public this()
	{
		Shell = new .();
		Device = NullGraphics.CreateDevice(2).Value;
		Vs = MakeModule(Device.Raw);
		Fs = MakeModule(Device.Raw);
		Main = Device.CreateRenderWindow(Shell.MainWindow, .()).Value;
		var shaders = VgShaderSet();
		shaders.Vertex = Vs;
		shaders.Fragment = Fs;
		Host = new .(Device, Shell, null, shaders);
		((NullWindow)Shell.MainWindow).Resize(800, 600);
		Root = new .(Host.Context);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Viewport = new .();
		Viewport.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(320.0f);
				s.Height = LayoutLength.Px(200.0f);
			});
		Root.AddChild(Viewport);
		Host.AttachWindow(Main, Root);
		Viewport.HostIn(Host);
	}

	public ~this()
	{
		// The viewport and root before the host (which holds the root, and with it the viewport,
		// until it goes), the host before the window it drew, the window before the device, the
		// device after the modules it made.
		if (Viewport != null)
			Viewport.ReleaseRef();
		Root.ReleaseRef();
		delete Host;
		delete Main;
		Device.Raw.DestroyShaderModule(ref Fs);
		Device.Raw.DestroyShaderModule(ref Vs);
		delete Device;
		delete Shell;
	}

	/// A module of four dummy bytes (the Null backend compiles nothing), the caller destroys.
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

/// The Viewport widget hosted on GuiHost, on the Null RHI backend and the null shell: bound to the
/// renderer of the window its node is in, its targets at the node's device pixels and its colour
/// target registered with that renderer, its drawing recorded on that window's frame (a clear when
/// it has none), bound again when its node moves to another window, and let go when it leaves.
class ViewportHostingTests
{
	[Test]
	public static void BoundToItsWindowsRendererItsTargetsAtTheNodesDevicePixelsItsDrawingRecorded()
	{
		let bed = scope ViewportBed();
		int renders = 0;
		bed.Viewport.OnRender = new [&renders] (viewport, encoder, frameIndex) =>
			{
				renders++;
				Test.Assert(viewport.IsReady);
			};
		bed.Frame(bed.Main);
		Test.Assert(bed.Viewport.WindowId == bed.Shell.MainWindow.Id);
		Test.Assert(bed.Viewport.IsReady);
		Test.Assert(bed.Viewport.RenderWidth == 320);
		Test.Assert(bed.Viewport.RenderHeight == 200);
		Test.Assert(renders == 1); // on the window's frame
		Test.Assert(bed.Viewport.Mouse != null);
		bed.Frame(bed.Main);
		Test.Assert(renders == 2); // live content: every frame

		// At twice the density, twice the pixels.
		bed.Host.UiScale = 2.0f;
		bed.Frame(bed.Main);
		Test.Assert(bed.Viewport.RenderWidth == 640);
		Test.Assert(bed.Viewport.RenderHeight == 400);
	}

	[Test]
	public static void WithNothingToDrawItClearsHiddenItRecordsNothing()
	{
		let bed = scope ViewportBed();
		bed.Frame(bed.Main);
		Test.Assert(bed.Viewport.IsReady); // cleared to its colour, sampled by the GUI
		int renders = 0;
		bed.Viewport.OnRender = new [&renders] (viewport, encoder, frameIndex) => { renders++; };
		bed.Viewport.Visible = false;
		bed.Frame(bed.Main);
		Test.Assert(renders == 0);
	}

	[Test]
	public static void MovedToAnotherWindowItIsBoundThereTakenOutOfEveryWindowItLetsGo()
	{
		let bed = scope ViewportBed();
		let second = bed.Shell.WindowManager.CreateWindow(.());
		Test.Assert(second case .Ok);
		let other = bed.Device.CreateRenderWindow(second.Value, .()).Value;
		let otherRoot = new SceneRoot(bed.Host.Context);
		bed.Host.AttachWindow(other, otherRoot);
		bed.Frame(bed.Main, other);
		Test.Assert(bed.Viewport.WindowId == bed.Shell.MainWindow.Id);

		int renders = 0;
		bed.Viewport.OnRender = new [&renders] (viewport, encoder, frameIndex) => { renders++; };
		bed.Viewport.RemoveFromParent();
		otherRoot.AddChild(bed.Viewport); // a panel floated into a window of its own
		bed.Frame(bed.Main, other);
		Test.Assert(bed.Viewport.WindowId == second.Value.Id);
		Test.Assert(renders == 1); // on the other window's frame only

		bed.Viewport.RemoveFromParent();
		bed.Frame(bed.Main, other);
		Test.Assert(bed.Viewport.WindowId == 0);
		Test.Assert(renders == 1);
		bed.Host.DetachWindow(other);
		delete other;
		otherRoot.ReleaseRef();
	}

	/// Added in the port: a fixed resolution holds the targets at its size whatever the node's,
	/// is kept while nothing is bound, and OnResized hears each time the targets are made again;
	/// let go, the targets follow the node again.
	[Test]
	public static void AFixedResolutionHoldsTheTargetsAtItsSizeAndOnResizedHearsEachRemake()
	{
		let bed = scope ViewportBed();
		int resizes = 0;
		uint32 lastWidth = 0;
		uint32 lastHeight = 0;
		bed.Viewport.OnResized = new [&resizes, &lastWidth, &lastHeight] (width, height) =>
			{
				resizes++;
				lastWidth = width;
				lastHeight = height;
			};
		bed.Viewport.SetFixedResolution(128, 64); // not bound yet: the size kept, nothing made
		Test.Assert(bed.Viewport.RenderWidth == 128);
		Test.Assert(bed.Viewport.RenderHeight == 64);
		Test.Assert(!bed.Viewport.IsReady);
		Test.Assert(resizes == 0);

		bed.Frame(bed.Main); // bound: made at its own size
		Test.Assert(bed.Viewport.IsReady);
		Test.Assert(resizes == 1);
		Test.Assert(lastWidth == 128);
		Test.Assert(lastHeight == 64);
		let desc = bed.Viewport.ColorTexture.Desc;
		Test.Assert(desc.Width == 128);
		Test.Assert(desc.Height == 64);
		Test.Assert(desc.Usage.HasFlag(.CopySrc)); // a capture copies it out

		bed.Host.UiScale = 2.0f; // the node's pixels change, its own size does not
		bed.Frame(bed.Main);
		Test.Assert(bed.Viewport.RenderWidth == 128);
		Test.Assert(resizes == 1);

		bed.Viewport.SetFixedResolution(0, 0); // the node's device pixels again, from its next placing
		bed.Frame(bed.Main);
		Test.Assert(bed.Viewport.RenderWidth == 640);
		Test.Assert(bed.Viewport.RenderHeight == 400);
		Test.Assert(resizes == 2);
		Test.Assert(lastWidth == 640);
	}

	/// Added in the port: the targets are made in the viewport's formats, RGBA16Float and
	/// Depth32Float by default, and made again when they change (and not when they do not).
	[Test]
	public static void NewFormatsMakeTheTargetsAgainInThem()
	{
		let bed = scope ViewportBed();
		bed.Frame(bed.Main);
		Test.Assert(bed.Viewport.ColorFormat == .RGBA16Float);
		Test.Assert(bed.Viewport.DepthFormat == .Depth32Float);
		Test.Assert(bed.Viewport.ColorTexture.Desc.Format == .RGBA16Float);
		int resizes = 0;
		bed.Viewport.OnResized = new [&resizes] (width, height) => { resizes++; };

		bed.Viewport.SetFormats(.RGBA8Unorm, .Depth24PlusStencil8);
		Test.Assert(resizes == 1);
		Test.Assert(bed.Viewport.IsReady);
		Test.Assert(bed.Viewport.ColorFormat == .RGBA8Unorm);
		Test.Assert(bed.Viewport.DepthFormat == .Depth24PlusStencil8);
		Test.Assert(bed.Viewport.ColorTexture.Desc.Format == .RGBA8Unorm);
		Test.Assert(bed.Viewport.RenderWidth == 320); // at the size it had

		bed.Viewport.SetFormats(.RGBA8Unorm, .Depth24PlusStencil8); // the same: nothing made
		Test.Assert(resizes == 1);
		bed.Frame(bed.Main);
		Test.Assert(resizes == 1);
	}

	/// Added in the port: a viewport that goes takes itself out of its host, so the host's next
	/// frame never reaches it (ASan reads a freed one here).
	[Test]
	public static void AViewportThatGoesLeavesItsHost()
	{
		let bed = scope ViewportBed();
		int renders = 0;
		bed.Viewport.OnRender = new [&renders] (viewport, encoder, frameIndex) => { renders++; };
		bed.Frame(bed.Main);
		Test.Assert(renders == 1);
		bed.Viewport.RemoveFromParent();
		bed.Viewport.ReleaseRef(); // the last reference: it goes now
		bed.Viewport = null;
		bed.Frame(bed.Main);
		Test.Assert(renders == 1);
	}

	/// Added in the port: the clear colour is authored (sRGB) and cleared with its linear value;
	/// alpha is coverage, not decoded.
	[Test]
	public static void TheClearColourIsAuthoredAndClearedWithItsLinearValue()
	{
		let viewport = new Viewport();
		defer viewport.ReleaseRef();
		viewport.ClearColor = .(0.5f, 0.25f, 1.0f, 0.75f);
		let linear = viewport.LinearClearColor;
		Test.Assert(Math.Abs(linear.R - SrgbToLinear(0.5f)) < 1e-6f);
		Test.Assert(Math.Abs(linear.G - SrgbToLinear(0.25f)) < 1e-6f);
		Test.Assert(Math.Abs(linear.B - 1.0f) < 1e-6f);
		Test.Assert(linear.A == 0.75f);
	}

	[Test]
	public static void ItsInputMapsThroughTheFitItWasGivenAndTheSizeItRendersAt()
	{
		let bed = scope ViewportBed();
		bed.Viewport.SetFixedResolution(160, 160);
		bed.Frame(bed.Main);
		let surface = bed.Viewport.HostedSurface;
		Test.Assert(surface != null);
		Test.Assert(surface.Fit.Mode == .Stretch);
		Test.Assert(surface.Fit.ContentSize == Float2(160.0f, 160.0f));
		Test.Assert(surface.Fit.Region.Width == 320.0f);
		bed.Viewport.FitMode = .Letterbox;
		bed.Frame(bed.Main);
		Test.Assert(surface.Fit.Mode == .Letterbox);
	}
}
