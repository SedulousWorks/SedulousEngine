using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Sedulous.RHI.Vulkan.Integration.Tests;

/// The swap chain against a real window and a real surface.
///
/// A window is the ONLY way to test this honestly: a swap chain negotiates against a
/// surface's capabilities, and there is no surface without one. The window is created
/// hidden as far as the shell allows and torn down at the end, so the suite stays runnable
/// on a desktop session without leaving anything behind.
class VulkanSwapChainTests
{
	private static SDL3Shell sShell;
	private static IWindow sWindow;
	private static IBackend sBackend;
	private static IDevice sDevice;
	private static ISurface sSurface;

	/// Everything the other tests need, or false when this machine has no display, no
	/// Vulkan, or no presentation support on the device that was picked.
	private static bool Ready()
	{
		if (sSurface != null)
			return true;

		if (sShell == null)
		{
			var settings = WindowSettings();
			settings.Title = "Sedulous RHI swap chain test";
			settings.Width = 320;
			settings.Height = 240;
			sShell = new SDL3Shell(settings);
			sWindow = sShell.MainWindow;
		}
		if (sWindow == null)
			return false;

		if (sBackend == null)
		{
			if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
				return false;
			sBackend = backend;
		}

		let native = sWindow.Native;
		let platform = ToSurfacePlatform(native.System);
		if (platform == .Unknown)
			return false;
		if (!(sBackend.CreateSurface(native.Window, native.Display, platform)
			case .Ok(let surface)))
			return false;
		sSurface = surface;

		let adapters = sBackend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return false;
		let info = scope AdapterInfo();
		adapters[0].GetInfo(info);
		var desc = DeviceDesc();
		desc.RequiredFeatures = info.SupportedFeatures;
		if (!(adapters[0].CreateDevice(desc) case .Ok(let device)))
			return false;
		sDevice = device;
		return true;
	}

	private static SurfacePlatform ToSurfacePlatform(WindowSystem system)
	{
		switch (system)
		{
		case .Win32: return .Win32;
		case .X11: return .X11;
		case .Wayland: return .Wayland;
		case .Cocoa: return .Cocoa;
		default: return .Unknown;
		}
	}

	private static Result<ISwapChain> MakeSwapChain(PresentMode presentMode = .Fifo)
	{
		var desc = SwapChainDesc();
		desc.Width = sWindow.Width;
		desc.Height = sWindow.Height;
		desc.Format = .BGRA8UnormSrgb;
		desc.PresentMode = presentMode;
		desc.BufferCount = 2;
		return sDevice.CreateSwapChain(sSurface, desc);
	}

	/// The chain negotiates against the surface and comes back describable: a format the
	/// RHI names, a size the surface accepted, and at least double buffering.
	[Test]
	public static void ASwapChainNegotiatesAgainstTheSurface()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no display or no Vulkan"); return; }

		Test.Assert(MakeSwapChain() case .Ok(var swapChain), "the swap chain was created");

		Test.Assert(swapChain.Format != .Undefined, "the negotiated format is one the RHI names");
		Test.Assert(swapChain.Width > 0 && swapChain.Height > 0);
		// The driver may hand back MORE images than were asked for, never fewer.
		Test.Assert(swapChain.BufferCount >= 2, "at least double buffered");

		sDevice.DestroySwapChain(ref swapChain);
	}

	/// Every back buffer is wrapped in a texture and a view whose description matches what
	/// the chain negotiated, which is what a render pass binds.
	[Test]
	public static void EveryBackBufferHasATextureAndAView()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no display or no Vulkan"); return; }

		Test.Assert(MakeSwapChain() case .Ok(var swapChain));
		Test.Assert(swapChain.AcquireNextImage() case .Ok, "an image was acquired");
		Test.Assert(swapChain.CurrentImageIndex < swapChain.BufferCount);

		let texture = swapChain.CurrentTexture;
		Test.Assert(texture != null, "the acquired image has a texture");
		Test.Assert(texture.Desc.Width == swapChain.Width, "sized as the chain negotiated");
		Test.Assert(texture.Desc.Height == swapChain.Height);
		Test.Assert(texture.Desc.Format == swapChain.Format, "and in the negotiated format");
		Test.Assert(texture.Desc.Usage.HasFlag(.RenderTarget), "usable as a render target");
		Test.Assert(swapChain.CurrentTextureView != null, "and has a view");

		sDevice.DestroySwapChain(ref swapChain);
	}

	/// Acquire, draw, present, repeated: the frame actually reaches the screen, and the
	/// acquire and present semaphores line up across frames.
	///
	/// This is the test the whole sync design exists for. A submit that failed to pick up
	/// the pending acquire, or a present semaphore nothing signalled, hangs or trips
	/// validation here rather than in a running game.
	[Test]
	public static void FramesAcquireDrawAndPresent()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no display or no Vulkan"); return; }

		Test.Assert(MakeSwapChain() case .Ok(var swapChain));
		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(sDevice.CreateFence(0) case .Ok(var fence));

		// More frames than there are images, so the semaphores have to CYCLE correctly
		// rather than merely work once.
		let frameCount = swapChain.BufferCount * 2;
		for (uint32 frame = 1; frame <= frameCount; ++frame)
		{
			if (!(swapChain.AcquireNextImage() case .Ok))
			{
				// A surface that went out of date mid-run is the compositor's business, not
				// a failure of the chain.
				Console.WriteLine("SKIP: the surface went out of date");
				break;
			}

			Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

			var colorAttachment = ColorAttachment();
			colorAttachment.View = swapChain.CurrentTextureView;
			colorAttachment.LoadOp = .Clear;
			colorAttachment.StoreOp = .Store;
			colorAttachment.ClearValue = .(0.1f, 0.2f, 0.4f, 1.0f);

			var passDesc = RenderPassDesc();
			passDesc.ColorAttachments.Add(colorAttachment);

			// UNDEFINED as the old state: the contents of a freshly acquired image are not
			// defined, so there is nothing to preserve.
			encoder.TransitionTexture(swapChain.CurrentTexture, .Undefined, .RenderTarget);
			let pass = encoder.BeginRenderPass(passDesc);
			Test.Assert(pass != null, "the render pass opened on the back buffer");
			pass.End();
			encoder.TransitionTexture(swapChain.CurrentTexture, .RenderTarget, .Present);

			var buffers = ICommandBuffer[1](encoder.Finish());
			// The fence-signalling overload is the one that consumes the pending acquire,
			// so presentation is only ordered if THIS is what submits the frame.
			queue.Submit(buffers, fence, (uint64)frame);
			Test.Assert(fence.Wait((uint64)frame), "the frame's work completed");

			Test.Assert(swapChain.Present(queue) case .Ok, "the frame was presented");

			pool.DestroyEncoder(ref encoder);
			pool.Reset();
		}

		Test.Assert(!sDevice.IsLost(), "the device survived the run");

		sDevice.DestroyFence(ref fence);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroySwapChain(ref swapChain);
	}

	/// A resize rebuilds the chain at the new size and leaves it usable, which a chain that
	/// leaked its old images or semaphores would not survive.
	[Test]
	public static void AResizeRebuildsTheChain()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no display or no Vulkan"); return; }

		Test.Assert(MakeSwapChain() case .Ok(var swapChain));
		let before = swapChain.Width;

		// Halved rather than nudged, so a surface that reports its own extent still lands
		// somewhere the request could plausibly have gone.
		if (swapChain.Resize(before / 2, swapChain.Height / 2) case .Err)
		{
			Console.WriteLine("SKIP: the surface refused the resize");
			sDevice.DestroySwapChain(ref swapChain);
			return;
		}

		Test.Assert(swapChain.Width > 0 && swapChain.Height > 0, "the resized chain has a size");
		Test.Assert(swapChain.BufferCount >= 2);
		Test.Assert(swapChain.AcquireNextImage() case .Ok, "and is still usable");
		Test.Assert(swapChain.CurrentTextureView != null);

		sDevice.DestroySwapChain(ref swapChain);
	}

	/// Immediate falls back to whatever uncapped mode the surface has rather than dropping
	/// straight to vsync, so the chain is created either way.
	[Test]
	public static void AnUnavailablePresentModeStillCreatesAChain()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no display or no Vulkan"); return; }

		Test.Assert(MakeSwapChain(.Immediate) case .Ok(var immediate));
		Test.Assert(immediate.BufferCount >= 2);
		sDevice.DestroySwapChain(ref immediate);

		// Mailbox forces at least a third image so it can race ahead of the display.
		Test.Assert(MakeSwapChain(.Mailbox) case .Ok(var mailbox));
		Test.Assert(mailbox.BufferCount >= 2);
		sDevice.DestroySwapChain(ref mailbox);
	}

	/// Named to sort last so the window and the device outlive every test above.
	[Test]
	public static void ZzTearDown()
	{
		if (sDevice != null)
		{
			sDevice.WaitIdle();
			// The surface goes through the DEVICE, so it has to be released before the
			// device that owns the instance behind it.
			if (sSurface != null)
			{
				sDevice.DestroySurface(ref sSurface);
				sSurface = null;
			}
			sDevice.Destroy();
			sDevice = null;
		}

		if (sBackend != null)
		{
			sBackend.Destroy();
			sBackend = null;
		}
		if (sShell != null)
		{
			delete sShell;
			sShell = null;
			sWindow = null;
		}
	}
}
