using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.Engine.Render.Tests;

/// The screen overlay pass: what it tells the window space overlays about their target.
class ScreenOverlayTests
{
	/// Records the view each pass hands it, and the one its prepare step had.
	private class RecordingOverlay : IScreenOverlay
	{
		public ScreenOverlayView Last;
		public ScreenOverlayView Prepared;
		public int Calls;
		public int Prepares;
		public bool PreparedBeforeRender;

		public void PrepareOverlay(ICommandEncoder encoder, ScreenOverlayView view)
		{
			Prepared = view;
			Prepares++;
			PreparedBeforeRender = Prepares == Calls + 1;
		}

		public void Render(IRenderPassEncoder encoder, ScreenOverlayView view)
		{
			Last = view;
			Calls++;
		}
	}

	/// A host with a UNORM view of its sRGB target hands it to the overlay pass: the overlays are
	/// told the target is encoded, and its format is the view's, so VG blends encoded values.
	/// Without one, the target as it is.
	[Test]
	public static void TheOverlayPassDrawsThroughTheTargetsUnormViewWhenGivenOne()
	{
		let device = scope NullDevice();
		let subsystem = scope RenderSubsystem(device, 2, null);
		// Shut down at the end, which is what frees the pass's depth stencil.
		subsystem.Init();
		defer subsystem.Shutdown();
		let overlay = scope RecordingOverlay();
		subsystem.RegisterOverlay(overlay);
		defer subsystem.UnregisterOverlay(overlay);

		var textureDesc = TextureDesc.RenderTarget(.RGBA8UnormSrgb, 8, 8);
		textureDesc.AlternateViewFormat = .RGBA8Unorm;
		Test.Assert(device.CreateTexture(textureDesc) case .Ok(var target));
		defer device.DestroyTexture(ref target);
		Test.Assert(device.CreateTextureView(target, .()) case .Ok(var view));
		defer device.DestroyTextureView(ref view);
		var unormDesc = TextureViewDesc();
		unormDesc.Format = .RGBA8Unorm;
		Test.Assert(device.CreateTextureView(target, unormDesc) case .Ok(var unorm));
		defer device.DestroyTextureView(ref unorm);
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);

		subsystem.RenderOverlays(encoder, view, .RGBA8UnormSrgb, 8, 8, 0);
		Test.Assert(overlay.Calls == 1);
		Test.Assert(!overlay.Last.EncodedTarget);
		Test.Assert(overlay.Last.TargetFormat == .RGBA8UnormSrgb);

		subsystem.RenderOverlays(encoder, view, .RGBA8UnormSrgb, 8, 8, 0, unorm);
		Test.Assert(overlay.Calls == 2);
		Test.Assert(overlay.Last.EncodedTarget);
		Test.Assert(overlay.Last.TargetFormat == .RGBA8Unorm);
		// Each pass is prepared first, outside it, with the view the pass then hands the overlay.
		Test.Assert(overlay.Prepares == 2);
		Test.Assert(overlay.PreparedBeforeRender);
		Test.Assert(overlay.Prepared.EncodedTarget);
		Test.Assert(overlay.Prepared.TargetFormat == overlay.Last.TargetFormat);
		Test.Assert(overlay.Prepared.DepthStencilFormat == overlay.Last.DepthStencilFormat);

		// A target with no twin draws as it is, whatever view is offered.
		subsystem.RenderOverlays(encoder, view, .RGBA16Float, 8, 8, 0, unorm);
		Test.Assert(overlay.Calls == 3);
		Test.Assert(!overlay.Last.EncodedTarget);
		Test.Assert(overlay.Last.TargetFormat == .RGBA16Float);
	}

	/// The overlay pass makes its stencil target on first use, on a subsystem initialized or not,
	/// so the subsystem lets it go when it is destroyed as well as when it shuts down.
	[Test]
	public static void ASubsystemNeverInitializedLetsItsOverlayDepthTargetGo()
	{
		let device = scope NullDevice();
		{
			let subsystem = scope RenderSubsystem(device, 2, null);
			let overlay = scope RecordingOverlay();
			subsystem.RegisterOverlay(overlay);
			Test.Assert(device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 8, 8)) case .Ok(var target));
			Test.Assert(device.CreateTextureView(target, .()) case .Ok(var view));
			Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
			Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

			subsystem.RenderOverlays(encoder, view, .RGBA8Unorm, 8, 8, 0);
			Test.Assert(overlay.Calls == 1);

			subsystem.UnregisterOverlay(overlay);
			pool.DestroyEncoder(ref encoder);
			device.DestroyCommandPool(ref pool);
			device.DestroyTextureView(ref view);
			device.DestroyTexture(ref target);
			Test.Assert(device.Counters().Textures == 1, "the overlay pass's depth target");
		}
		Test.Assert(device.Counters().Textures == 0);
	}
}
