using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.Vulkan;
using Sedulous.RHI.WebGPU;

namespace Sedulous.Engine.DefaultApp.Tests;

/// ScreenshotCapture: the flags, the row unpack, and the whole path on real GPUs, a texture
/// cleared to a known colour in RGBA8 and BGRA8, recorded the way FinishFrame records the
/// backbuffer, completed, written as a PNG and read back through the image loader. It pins
/// that the file exists and is right, which a GPU copy alone never did.
class ScreenshotTests
{
	private static ScreenshotOptions Parse(params String[] args)
	{
		return ScreenshotOptions.FromArguments(args);
	}

	[Test]
	public static void FlagsParseDefaultToFrame30AndIgnoreWhatIsNotTheirs()
	{
		let none = Parse("--data-root", "x", "--vulkan");
		defer delete none;
		Test.Assert(!none.Requested);

		let byFrame = Parse("--screenshot", "out.png", "--screenshot-frame", "7");
		defer delete byFrame;
		Test.Assert(byFrame.Requested);
		Test.Assert(byFrame.Path == "out.png");
		Test.Assert(byFrame.Frame == 7);
		Test.Assert(byFrame.AfterSeconds == 0.0f);
		Test.Assert(!byFrame.ExitAfter);
		Test.Assert(byFrame.Due(7, 0.0f));
		Test.Assert(!byFrame.Due(6, 100.0f)); // frames decide when no time was asked for

		let bySeconds = Parse("--screenshot", "shot.png", "--screenshot-after", "15.5", "--screenshot-exit");
		defer delete bySeconds;
		Test.Assert(Math.Abs(bySeconds.AfterSeconds - 15.5f) < 0.001f);
		Test.Assert(bySeconds.ExitAfter);
		Test.Assert(!bySeconds.Due(30, 15.4f));
		Test.Assert(bySeconds.Due(1, 15.5f)); // time decides, whatever the frame

		let defaulted = Parse("--screenshot", "a.png");
		defer delete defaulted;
		Test.Assert(defaulted.Frame == 30);

		let zero = Parse("--screenshot", "a.png", "--screenshot-frame", "0");
		defer delete zero;
		Test.Assert(zero.Frame == 1); // never "frame 0"

		let dangling = Parse("--screenshot");
		defer delete dangling;
		Test.Assert(!dangling.Requested); // a dangling flag asks for nothing
	}

	[Test]
	public static void RowsUnpackFromTheAlignedPitchAndBgraSwizzlesToRgba()
	{
		// 3x2 pixels in a 256 byte pitch; each row's tail is garbage the unpack must skip.
		const uint32 w = 3;
		const uint32 h = 2;
		const uint32 pitch = 256;
		uint8[pitch * h] mapped = .();
		for (int i = 0; i < mapped.Count; i++)
			mapped[i] = 0xEE;
		uint8[2][3][4] px = .(
			.(.(1, 2, 3, 4), .(5, 6, 7, 8), .(9, 10, 11, 12)),
			.(.(13, 14, 15, 16), .(17, 18, 19, 20), .(21, 22, 23, 24)));
		for (int y = 0; y < h; y++)
			for (int x = 0; x < w; x++)
				for (int c = 0; c < 4; c++)
					mapped[y * pitch + x * 4 + c] = px[y][x][c];

		uint8[w * h * 4] rgba = .();
		ScreenshotCapture.UnpackRows(&mapped[0], pitch, w, h, false, .(&rgba[0], rgba.Count));
		Test.Assert(rgba[0] == 1);
		Test.Assert(rgba[3] == 4);
		Test.Assert(rgba[(1 * w + 2) * 4 + 0] == 21); // last pixel, straight through
		Test.Assert(rgba[(1 * w + 2) * 4 + 2] == 23);

		ScreenshotCapture.UnpackRows(&mapped[0], pitch, w, h, true, .(&rgba[0], rgba.Count));
		Test.Assert(rgba[0] == 3); // B to R
		Test.Assert(rgba[1] == 2);
		Test.Assert(rgba[2] == 1); // R to B
		Test.Assert(rgba[3] == 4);
		Test.Assert(rgba[(1 * w + 2) * 4 + 0] == 23);
		Test.Assert(rgba[(1 * w + 2) * 4 + 2] == 21);

		Test.Assert(ScreenshotCapture.CanCapture(.BGRA8UnormSrgb));
		Test.Assert(ScreenshotCapture.CanCapture(.RGBA8Unorm));
		Test.Assert(!ScreenshotCapture.CanCapture(.RGBA16Float));
		Test.Assert(ScreenshotCapture.IsBgra(.BGRA8Unorm));
		Test.Assert(!ScreenshotCapture.IsBgra(.RGBA8UnormSrgb));
	}

	/// Clears a `format` texture to a colour, captures it the way the application captures
	/// the backbuffer, writes the PNG and loads it back: the pixel at (5, 5) and the size
	/// must match.
	private static void CaptureProbe(IDevice device, TextureFormat format, StringView name)
	{
		const uint32 w = 64;
		const uint32 h = 48;
		var textureDesc = TextureDesc();
		textureDesc.Format = format;
		textureDesc.Width = w;
		textureDesc.Height = h;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "screenshot.probe";
		Test.Assert(device.CreateTexture(textureDesc) case .Ok(var texture), scope $"{name}: the probe texture");
		var viewDesc = TextureViewDesc();
		viewDesc.Format = format;
		Test.Assert(device.CreateTextureView(texture, viewDesc) case .Ok(var view), scope $"{name}: the probe view");
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool), scope $"{name}: the pool");
		Test.Assert(device.CreateFence(0) case .Ok(var fence), scope $"{name}: the fence");
		let queue = device.GetQueue(.Graphics);
		Test.Assert(queue != null, scope $"{name}: the graphics queue");
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder), scope $"{name}: the encoder");

		// The frame: a clear to a colour with distinct channels, so a swizzle slip shows, the
		// texture left in the RenderTarget state as the host leaves the backbuffer.
		encoder.TransitionTexture(texture, .Undefined, .RenderTarget);
		var colorAttachment = ColorAttachment();
		colorAttachment.View = view;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.2f, 0.6f, 1.0f, 1.0f);
		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		let pass = encoder.BeginRenderPass(passDesc);
		Test.Assert(pass != null, scope $"{name}: the clear pass");
		pass.End();

		let path = scope $"screenshot_probe_{name}.png";
		if (File.Exists(path))
			File.Delete(path).IgnoreError();

		let capture = scope ScreenshotCapture();
		Test.Assert(!capture.Record(device, encoder, texture, format, w, h)); // not armed: nothing
		capture.Request(path);
		Test.Assert(capture.Armed);
		Test.Assert(capture.Record(device, encoder, texture, format, w, h), scope $"{name}: recorded");
		Test.Assert(!capture.Armed);
		Test.Assert(capture.Recorded);

		let commandBuffer = encoder.Finish();
		Test.Assert(commandBuffer != null, scope $"{name}: the command buffer");
		var buffers = ICommandBuffer[1](commandBuffer);
		queue.Submit(.(&buffers[0], 1), fence, 1);
		Test.Assert(fence.Wait(1), scope $"{name}: the fence signalled");

		let written = scope Image();
		Test.Assert(capture.Complete(device, written) case .Ok, scope $"{name}: completed and written");
		Test.Assert(!capture.Recorded);
		Test.Assert(written.Width == w);
		Test.Assert(written.Height == h);

		// The file, through the loader: the same pixels in RGBA order whatever the surface.
		let loaded = scope Image();
		Test.Assert(ImageIO.LoadImage(path, loaded) case .Ok, scope $"{name}: the PNG loads back");
		Test.Assert(loaded.Width == w);
		Test.Assert(loaded.Height == h);
		Test.Assert(loaded.Format == .RGBA8);
		let p = loaded.PixelData.Ptr + (5 * w + 5) * 4;
		// 0.2 / 0.6 / 1.0 in unorm: these probes are linear formats, so the bytes are the
		// plain unorm values, not sRGB encoded ones.
		Test.Assert((p[0] >= 49) && (p[0] <= 53), scope $"{name}: red {p[0]}");
		Test.Assert((p[1] >= 151) && (p[1] <= 155), scope $"{name}: green {p[1]}");
		Test.Assert(p[2] == 255, scope $"{name}: blue {p[2]}");
		Test.Assert(p[3] == 255, scope $"{name}: alpha {p[3]}");

		capture.Release(device);
		device.WaitIdle();
		pool.DestroyEncoder(ref encoder);
		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref texture);
		File.Delete(path).IgnoreError();
	}

	private static void ProbeOn(IBackend backend, StringView name)
	{
		if (backend == null)
		{
			Console.WriteLine(scope $"{name} unavailable: screenshot probe skipped");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let device = RhiTestSupport.MakeTestDevice(backend);
		if (device == null)
		{
			Console.WriteLine(scope $"{name} has no device: screenshot probe skipped");
			return;
		}

		CaptureProbe(device, .RGBA8Unorm, scope $"{name}-rgba");
		CaptureProbe(device, .BGRA8Unorm, scope $"{name}-bgra");
		device.Destroy();
	}

	[Test]
	public static void AClearedRgba8AndBgra8TargetRoundTripsToAPngOnVulkanAndWebGpu()
	{
		IBackend vulkan = null;
		if (VulkanRhi.CreateBackend(false) case .Ok(let created))
			vulkan = created;
		ProbeOn(vulkan, "vulkan");

		IBackend webgpu = null;
		if (WebGpuRhi.CreateBackend() case .Ok(let made))
			webgpu = made;
		ProbeOn(webgpu, "webgpu");
	}
}
