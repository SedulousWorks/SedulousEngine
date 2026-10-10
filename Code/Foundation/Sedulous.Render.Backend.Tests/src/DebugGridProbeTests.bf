using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// The shader grid on a real device: a metre grid on the XY plane seen from 5 m draws its
/// lines on world metres, dark between them, and the line through the origin along Y in Y's
/// green.
class DebugGridProbeTests
{
	private const uint32 cSize = 64;

	/// Renders `scene` from 5 m up +Z, looking at the origin, into a fresh sRGB target and
	/// reads it back.
	private static CapturedImage RenderProbe(IDevice device, RenderFrame frame, ExtractedScene scene)
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 5), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 5);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8UnormSrgb;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "probe.target";
		var target = device.CreateTexture(textureDesc).Value;
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8UnormSrgb;
		var targetView = device.CreateTextureView(target, viewDesc).Value;
		defer device.DestroyTextureView(ref targetView);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var fence = device.CreateFence(0).Value;
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);

		var settings = ViewSettings();
		settings.Clear = .(0.0f, 0.0f, 0.0f, 1.0f);
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;
		for (uint32 i < 2)
		{
			var encoder = pool.CreateEncoder().Value;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8UnormSrgb, cSize, cSize);
			frame.End();
			let commandBuffer = encoder.Finish();
			Test.Assert(commandBuffer != null);
			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}
		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		device.WaitIdle();
		return image;
	}

	[Test]
	public static void TheShaderGridDrawsItsLinesOnWorldMetresDarkBetween()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;
		let registry = scope RendererRegistry();
		let tonemap = scope TonemapPass(device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let debugPass = scope DebugDrawPass(device, fixture.Shaders, 2);
		Test.Assert(debugPass.Initialize() case .Ok);
		let frame = scope RenderFrame(device, registry, 2, null, tonemap);

		// A metre grid on the XY plane (U is X, V is Y), the camera on +Z looking at the origin.
		let global = scope DebugDraw();
		var grid = GridPlaneDesc();
		grid.Origin = .(0, 0, 0);
		grid.Extent = 50.0f;
		grid.AxisU = .(1, 0, 0);
		grid.AxisV = .(0, 1, 0);
		grid.Spacing = 1.0f;
		grid.Blend = 0.0f;
		grid.CameraPosition = .(0, 0, 5);
		grid.FadeDistance = 200.0f;
		global.DrawGridPlane(grid);
		frame.SetDebug(debugPass, global, null);

		let scene = scope ExtractedScene();
		let image = RenderProbe(device, frame, scene);
		defer delete image;
		Test.Assert(image.Valid);

		// A metre is this many pixels at 5 m with a 60 degree view across 64 pixels.
		let pixelsPerMetre = (float)cSize / (2.0f * 5.0f * Math.Tan(0.5f * 1.0472f));
		int32 ColumnOf(float x) => (int32)(0.5f * cSize + x * pixelsPerMetre);
		uint32 Brightest(int32 column, uint32 row)
		{
			uint32 best = 0;
			for (int32 c = column - 1; c <= column + 1; c++)
			{
				let p = image.At((uint32)c, row);
				best = Math.Max(best, (uint32)p[0] + p[1] + p[2]);
			}
			return best;
		}
		// A row half a metre above the origin, between the lines along X.
		let row = (uint32)(0.5f * cSize - 0.5f * pixelsPerMetre);
		let onLine = Brightest(ColumnOf(1.0f), row);
		let between = image.At((uint32)ColumnOf(0.5f), row);
		let betweenSum = (uint32)between[0] + between[1] + between[2];
		let report = scope $"on the x = 1 line {onLine}, half way to it {betweenSum}";
		Test.Assert(onLine > 60, report);
		Test.Assert(betweenSum < 20, report);

		// The line through the origin along Y (x = 0) is Y's green.
		var bestColumn = (uint32)ColumnOf(0.0f);
		for (int32 c = ColumnOf(0.0f) - 1; c <= ColumnOf(0.0f) + 1; c++)
		{
			if (image.At((uint32)c, row)[1] > image.At(bestColumn, row)[1])
				bestColumn = (uint32)c;
		}
		let axis = image.At(bestColumn, row);
		let axisReport = scope $"the Y axis line {axis[0]}, {axis[1]}, {axis[2]}";
		Test.Assert(axis[1] > axis[0] + 40, axisReport);
		Test.Assert(axis[1] > axis[2] + 40, axisReport);
	}
}
