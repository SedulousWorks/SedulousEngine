using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shell;
using Sedulous.Shell.Null;
using Sedulous.UI;
using Sedulous.UI.Viewport;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.UI.Viewport.Tests;

/// The viewport, headless over the null backend.
///
/// Headless is enough because what is worth pinning is the PLUMBING: that layout creates the
/// targets, that the colour target is registered so the UI can sample it, that the render
/// callback is bracketed by the right transitions, and that input maps in physical pixels.
/// None of that needs a real GPU.
class ViewportViewTests
{
	/// A device, a renderer wired to it, and the two shader modules the renderer needs.
	private class Harness
	{
		public NullDevice Device = new .() ~ delete _;
		public VGRenderer Renderer = new .() ~ delete _;
		private IShaderModule mVertex;
		private IShaderModule mFragment;

		public this()
		{
			mVertex = MakeModule();
			mFragment = MakeModule();
			Renderer.Initialize(Device, mVertex, mFragment, .BGRA8UnormSrgb, 2);
		}

		public ~this()
		{
			Renderer.Dispose();
			if (mVertex != null)
				Device.DestroyShaderModule(ref mVertex);
			if (mFragment != null)
				Device.DestroyShaderModule(ref mFragment);
		}

		private IShaderModule MakeModule()
		{
			uint8[4] code = .();
			var desc = ShaderModuleDesc();
			desc.Code = .(&code[0], 4);

			if (Device.CreateShaderModule(desc) case .Ok(let module))
				return module;

			return null;
		}
	}

	// ---- Targets ------------------------------------------------------------------------------

	/// Layout is what creates the targets, and the colour one is registered with the renderer
	/// so the UI can sample it. Registered, it survives all the way to a usable draw slice; an
	/// unregistered pixel-less key would produce no bind group at all.
	[Test]
	public static void LayoutCreatesTheTargetsAndRegistersTheColourOne()
	{
		let harness = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();

		Test.Assert(view.IsFocusable, "a viewport is an input target");
		Test.Assert(!view.IsReady, "nothing before layout");

		view.Initialize(harness.Device, harness.Renderer, null, 0);
		view.Layout(0, 0, 200, 150);

		Test.Assert(view.IsReady);
		Test.Assert(view.RenderWidth == 200);
		Test.Assert(view.RenderHeight == 150);
		Test.Assert(view.ColorTargetView != null);
		Test.Assert(view.DepthTargetView != null);

		// The draw emits a textured quad keyed on the viewport's image.
		let vg = scope VGContext();
		let ctx = scope UIDrawContext(vg, 1.0f);
		view.OnDraw(ctx);

		let batch = vg.GetBatch();
		Test.Assert(batch.Textures.Count >= 1);

		harness.Renderer.BeginFrame(0);
		Test.Assert(harness.Renderer.Prepare(batch, 0, 800, 600).IsValid,
			"the external texture is usable end to end");
	}

	/// Resizing rebuilds the targets and re-registers, and tearing down afterwards is clean.
	[Test]
	public static void ResizingRebuildsAndTearingDownIsClean()
	{
		let harness = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();
		view.Initialize(harness.Device, harness.Renderer, null, 0);

		view.Layout(0, 0, 100, 80);
		Test.Assert(view.RenderWidth == 100);

		view.Layout(0, 0, 240, 120);
		Test.Assert(view.RenderWidth == 240);
		Test.Assert(view.RenderHeight == 120);
		Test.Assert(view.IsReady, "rebuilt at the new size, not left torn down");

		// NOT asserted: that the new view is a different POINTER. An allocator may hand back
		// the address it just freed, which is the stale-identity trap this port has hit before.
		// The size is the observable fact; the address is not.

		// Still registered, so the renderer can sample the rebuilt target.
		let vg = scope VGContext();
		let ctx = scope UIDrawContext(vg, 1.0f);
		view.OnDraw(ctx);
		harness.Renderer.BeginFrame(0);
		Test.Assert(harness.Renderer.Prepare(vg.GetBatch(), 0, 800, 600).IsValid);

		// Shutdown releases while the device and renderer are still alive, which is the whole
		// point of it existing: a view can outlive the window it was drawn in.
		view.Shutdown();
		Test.Assert(!view.IsReady);
	}

	/// A fixed resolution renders at that size whatever the panel's size, which is what a
	/// preview mode needs.
	[Test]
	public static void AFixedResolutionIgnoresThePanelSize()
	{
		let harness = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();
		view.Initialize(harness.Device, harness.Renderer, null, 0);

		view.SetFixedResolution(320, 240);
		view.Layout(0, 0, 800, 600);

		Test.Assert(view.RenderWidth == 320);
		Test.Assert(view.RenderHeight == 240);
		Test.Assert(view.FixedWidth == 320);

		// Back to nought and it follows the layout again.
		view.SetFixedResolution(0, 0);
		view.Layout(0, 0, 800, 600);
		Test.Assert(view.RenderWidth == 800);
	}

	/// Moving to another window re-registers the target there, so an undocked panel's UI can
	/// sample what the docked one was sampling.
	[Test]
	public static void AttachingToAnotherWindowReRegistersTheTarget()
	{
		let first = scope Harness();
		let second = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();
		view.Initialize(first.Device, first.Renderer, null, 0);
		view.Layout(0, 0, 128, 128);
		Test.Assert(view.IsReady);

		view.AttachToWindow(second.Renderer, 1);

		// The GPU targets are UNCHANGED; only the registration moved.
		Test.Assert(view.IsReady);
		Test.Assert(view.RenderWidth == 128);

		let vg = scope VGContext();
		let ctx = scope UIDrawContext(vg, 1.0f);
		view.OnDraw(ctx);

		second.Renderer.BeginFrame(0);
		Test.Assert(second.Renderer.Prepare(vg.GetBatch(), 0, 800, 600).IsValid,
			"the new window's renderer can sample it");
	}

	// ---- Formats and fit ----------------------------------------------------------------------

	/// The view owns the formats, so a render callback building a pipeline from them always
	/// agrees with the actual attachments. High dynamic range by default.
	[Test]
	public static void TheViewOwnsItsFormatsAndReconfiguringRecreatesTheTargets()
	{
		let harness = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();

		Test.Assert(view.ColorFormat == .RGBA16Float);
		Test.Assert(view.DepthFormat == .Depth32Float);

		view.Initialize(harness.Device, null, null, 0);
		view.Layout(0, 0, 80, 60);
		Test.Assert(view.IsReady);

		view.SetFormats(.RGBA8Unorm, .Depth32FloatStencil8);

		Test.Assert(view.ColorFormat == .RGBA8Unorm);
		Test.Assert(view.DepthFormat == .Depth32FloatStencil8);
		Test.Assert(view.IsReady, "recreated, not left broken");
		Test.Assert(view.RenderWidth == 80, "at the same size");
	}

	[Test]
	public static void TheFitModeDefaultsToStretch()
	{
		let view = new ViewportView();
		defer view.ReleaseRef();

		Test.Assert(view.FitMode == .Stretch);

		view.FitMode = .Letterbox;
		Test.Assert(view.FitMode == .Letterbox);
	}

	// ---- Rendering ----------------------------------------------------------------------------

	/// The callback fires bracketed by the transitions it needs, so content owns only its
	/// passes. With no callback there is nothing to bracket and nothing happens.
	[Test]
	public static void TheRenderCallbackFiresBracketedByTransitions()
	{
		let harness = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();
		view.Initialize(harness.Device, null, null, 0);
		view.Layout(0, 0, 64, 64);
		Test.Assert(view.IsReady);

		var pool = harness.Device.CreateCommandPool(.Graphics).Value;
		defer harness.Device.DestroyCommandPool(ref pool);
		let encoder = pool.CreateEncoder().Value;

		// No callback: nothing to do, and no crash for having nothing.
		view.RenderContent(encoder, 0);

		var fired = 0;
		var seenFrame = -1;
		ViewportView seenView = null;
		view.OnRender = new [&fired, &seenFrame, &seenView](v, e, frameIndex) =>
			{
				fired++;
				seenFrame = frameIndex;
				seenView = v;
			};

		view.RenderContent(encoder, 7);

		Test.Assert(fired == 1);
		Test.Assert(seenFrame == 7);
		Test.Assert(seenView == view, "handed the view it is rendering for");

		// Afterwards the colour target is readable, which is what the UI pass needs.
		Test.Assert(view.ColorState == .ShaderRead);
	}

	/// Clearing leaves the target readable too, so a host whose content is idle still defines
	/// the texture the UI samples every frame.
	[Test]
	public static void ClearingLeavesTheTargetReadable()
	{
		let harness = scope Harness();

		let view = new ViewportView();
		defer view.ReleaseRef();
		view.Initialize(harness.Device, null, null, 0);
		view.Layout(0, 0, 64, 64);

		var pool = harness.Device.CreateCommandPool(.Graphics).Value;
		defer harness.Device.DestroyCommandPool(ref pool);
		let encoder = pool.CreateEncoder().Value;

		view.ClearContent(encoder);

		Test.Assert(view.ColorState == .ShaderRead);
	}

	// ---- Input --------------------------------------------------------------------------------

	/// The surface region is in PHYSICAL pixels.
	///
	/// The UI lays out in logical units, dividing by the root's DPI scale, but the router
	/// transforms the RAW mouse, which is physical. Mixing them drifts hover and picking by
	/// the scale factor at any UI scale but one. The CONTENT size stays the target's own
	/// resolution, which is what a mouse ray divides by.
	[Test]
	public static void TheInputRegionIsPhysicalWhileTheContentSizeIsTheTargets()
	{
		let harness = scope Harness();
		let input = scope NullInputManager();

		let root = new RootView();
		defer root.ReleaseRef();

		let view = new ViewportView();
		view.Initialize(harness.Device, harness.Renderer, input, 0);
		Test.Assert(view.Surface != null, "an input manager means a surface");

		root.DpiScale = 1.25f;
		root.AddView(view);

		view.Layout(0, 0, 200, 150);
		view.SyncInputRegion();

		let fit = view.Surface.Fit;
		Test.Assert(fit.Region.Width == 200 * 1.25f);
		// The content size is the TARGET's resolution, not the scaled region.
		Test.Assert(fit.ContentSize.X == view.RenderWidth);
		Test.Assert(fit.ContentSize.Y == view.RenderHeight);

		// At 100 per cent the region is simply the logical rect, which is the regression guard.
		root.DpiScale = 1.0f;
		view.Layout(0, 0, 200, 150);
		view.SyncInputRegion();

		Test.Assert(view.Surface.Fit.Region.Width == 200);
		Test.Assert(view.Surface.Fit.Region.Height == 150);
	}

	/// ONE app keyboard: the viewport yields only when the host UI's focus is on something
	/// else. Absent focus does NOT count as elsewhere, or clicking dead editor space would
	/// mute a running game.
	[Test]
	public static void OnlyAFocusedNonViewportViewTakesTheKeyboard()
	{
		let context = new UIContext();
		let root = new RootView();
		root.ViewportSize = .(800, 600);
		context.AddRootView(root);
		defer { root.ReleaseRef(); delete context; }

		let view = new ViewportView();
		root.AddView(view);

		let other = new TestFocusable();
		root.AddView(other);

		Test.Assert(!view.HostKeyboardFocusElsewhere, "nothing focused is not elsewhere");

		context.GetFocusManager().SetFocus(view);
		Test.Assert(!view.HostKeyboardFocusElsewhere, "the viewport itself is not elsewhere");

		context.GetFocusManager().SetFocus(other);
		Test.Assert(view.HostKeyboardFocusElsewhere);

		context.GetFocusManager().ClearFocus();
		Test.Assert(!view.HostKeyboardFocusElsewhere, "and back to nothing");
	}

	/// The viewport reports text input on its HOSTED content's behalf, so the host window's
	/// IME follows the embedded focus rather than two bridges fighting over it.
	[Test]
	public static void TheViewportReportsTextInputForItsHostedContent()
	{
		let view = new ViewportView();
		defer view.ReleaseRef();

		Test.Assert(!view.WantsTextInput());

		view.SetHostedTextInputWanted(true);
		Test.Assert(view.WantsTextInput());

		view.SetHostedTextInputWanted(false);
		Test.Assert(!view.WantsTextInput());
	}

	/// A focusable stand-in for whatever else the host UI might focus.
	private class TestFocusable : View
	{
		public this()
		{
			IsFocusable = true;
		}
	}
}
