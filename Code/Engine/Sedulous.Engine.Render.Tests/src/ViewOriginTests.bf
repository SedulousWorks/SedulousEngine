using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.VFS;

namespace Sedulous.Engine.Render.Tests;

/// The view's position rides on a scene's snapshot before the providers extract into it, for
/// those that thin by distance (vegetation's fade). The camera was resolved only after
/// extraction, so a provider always read no origin and the fade never ran.
class ViewOriginTests
{
	/// Records what the snapshot said when it was asked to extract.
	private class OriginProbe : IRenderDataProvider
	{
		public bool Asked = false;
		public bool HadOrigin = false;
		public Float3 Origin = .(0, 0, 0);

		public void ExtractRenderData(ExtractedScene snapshot)
		{
			Asked = true;
			HadOrigin = snapshot.HasViewOrigin;
			Origin = snapshot.ViewOrigin;
		}
	}

	[Test]
	public static void AProviderSeesTheViewsPositionOnTheSnapshot()
	{
		let dataRoot = FindDataRoot(.. scope String());
		if (dataRoot.IsEmpty)
			return;
		let mount = scope NativeFileSystem(dataRoot);

		let backend = NullRhi.CreateBackend();
		defer { backend.Destroy(); delete backend; }
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		defer device.Destroy();

		var textureDesc = TextureDesc.RenderTarget(.BGRA8Unorm, 64, 64, 1, "origin.color");
		var target = device.CreateTexture(textureDesc).Value;
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .BGRA8Unorm;
		var targetView = device.CreateTextureView(target, viewDesc).Value;
		defer device.DestroyTextureView(ref targetView);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var encoder = pool.CreateEncoder().Value;
		defer pool.DestroyEncoder(ref encoder);

		let subsystem = scope RenderSubsystem(device, 2, mount);
		subsystem.Init();
		defer subsystem.Shutdown();
		// No shader compiler or pack on this machine: the renderer stays inert, nothing to test.
		if (subsystem.Shaders == null)
			return;

		let scene = scope Scene("origin");
		let probe = scope OriginProbe();
		subsystem.RegisterProvider(scene, probe);

		var cameraOverride = CameraOverride();
		cameraOverride.Camera.Position = .(3.0f, 4.0f, 5.0f);
		cameraOverride.Camera.View = Float4x4.LookAtRH(.(3, 4, 5), .(0, 0, 0), .(0, 1, 0));
		cameraOverride.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);

		subsystem.BeginRendering(encoder, 0);
		subsystem.RenderScene(scene, targetView, .BGRA8Unorm, 64, 64, .(), &cameraOverride);
		subsystem.EndRendering();

		Test.Assert(probe.Asked, "the provider extracted");
		Test.Assert(probe.HadOrigin, "the snapshot carried the view's position");
		Test.Assert((probe.Origin.X == 3.0f) && (probe.Origin.Y == 4.0f) && (probe.Origin.Z == 5.0f),
			scope $"at the camera, got ({probe.Origin.X}, {probe.Origin.Y}, {probe.Origin.Z})");
	}
}
