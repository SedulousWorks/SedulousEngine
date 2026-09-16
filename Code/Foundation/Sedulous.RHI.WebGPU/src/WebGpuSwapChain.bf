using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The swap chain, over a CONFIGURED WGPUSurface.
///
/// WebGPU has no swapchain object: the surface is configured with a format, a size and a
/// present mode, and each frame BORROWS the current texture. AcquireNextImage wraps the
/// borrowed WGPUTexture - the surface owns it - and creates its view; Present hands it to
/// the compositor and drops the borrow. There is no image index in the API, so a frame
/// counter modulo the buffer count satisfies the RHI's shape.
class WebGpuSwapChain : ISwapChain
{
	private WGPUAdapter mAdapter;
	private WGPUDevice mDevice;
	/// Deferred surface texture release on web; see Present.
	private WebGpuQueue mQueue;
	private WebGpuSurface mSurface;

	private TextureFormat mFormat = .BGRA8UnormSrgb;
	private PresentMode mPresentMode = .Fifo;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private uint32 mBufferCount = 2;
	private uint32 mFrameIndex = 0;
	private bool mConfigured = false;
	private bool mHaveImage = false;

	private WebGpuTexture mCurrentTexture;
	private WebGpuTextureView mCurrentView;
	private WGPUTexture mOwnedHandle = null;

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mFrameIndex % mBufferCount;

	public ITexture CurrentTexture => mHaveImage ? mCurrentTexture : null;
	public ITextureView CurrentTextureView => mHaveImage ? mCurrentView : null;

	public ~this()
	{
		Cleanup();
	}

	public Result<void> Initialize(WGPUAdapter adapter, WGPUDevice device, WebGpuQueue queue,
		WebGpuSurface surface, SwapChainDesc desc)
	{
		mAdapter = adapter;
		mDevice = device;
		mQueue = queue;
		mSurface = surface;
		mFormat = desc.Format;
		mPresentMode = desc.PresentMode;
		mBufferCount = desc.BufferCount;
		return Configure(desc.Width, desc.Height);
	}

	public Result<void> AcquireNextImage()
	{
		DropCurrent();

		WGPUSurfaceTexture surfaceTexture = .();
		wgpuSurfaceGetCurrentTexture(mSurface.Handle, &surfaceTexture);
		if ((surfaceTexture.status != .WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal)
			&& (surfaceTexture.status != .WGPUSurfaceGetCurrentTextureStatus_SuccessSuboptimal))
		{
			if (surfaceTexture.texture != null)
				wgpuTextureRelease(surfaceTexture.texture);

			return .Err; // lost or outdated: the host resizes and retries
		}

		// Size the frame from the TEXTURE WE GOT, not the size we configured: on the browser
		// the canvas can resize between configure and acquire, and Chrome hands back the
		// canvas's CURRENT backing texture - rendering with the configured size then fails
		// validation ("Scissor rect ... not contained in the render area") and the whole frame
		// drops. Width and Height feed the frame context AFTER acquire, so every downstream
		// viewport and scissor agrees with the real attachment.
		let acquiredWidth = wgpuTextureGetWidth(surfaceTexture.texture);
		let acquiredHeight = wgpuTextureGetHeight(surfaceTexture.texture);
		if ((acquiredWidth != 0) && (acquiredHeight != 0)
			&& ((acquiredWidth != mWidth) || (acquiredHeight != mHeight)))
		{
			mWidth = acquiredWidth;
			mHeight = acquiredHeight;
		}

		TextureDesc textureDesc = .();
		textureDesc.Format = mFormat;
		textureDesc.Width = mWidth;
		textureDesc.Height = mHeight;
		textureDesc.Usage = .RenderTarget;

		mCurrentTexture = new WebGpuTexture();
		mCurrentTexture.WrapExternal(surfaceTexture.texture, textureDesc);
		// Released at the next AcquireNextImage, or at Cleanup.
		mOwnedHandle = surfaceTexture.texture;

		TextureViewDesc viewDesc = .();
		viewDesc.Format = mFormat;

		mCurrentView = new WebGpuTextureView();
		if (mCurrentView.Initialize(surfaceTexture.texture, mCurrentTexture, viewDesc) case .Err)
		{
			// Torn down HERE rather than through DropCurrent: the image is not current yet,
			// so DropCurrent returns early and would strand the borrow. Raptor calls it
			// anyway and leaks the surface texture down this path.
			DeleteAndNullify!(mCurrentView);
			DeleteAndNullify!(mCurrentTexture);
			wgpuTextureRelease(mOwnedHandle);
			mOwnedHandle = null;
			return .Err;
		}

		mHaveImage = true;
		mFrameIndex++;
		return .Ok;
	}

	public Result<void> Present(IQueue queue)
	{
		if (!mHaveImage)
			return .Err;

#if BF_PLATFORM_WASM
		// The browser presents the canvas automatically once the requestAnimationFrame
		// callback - the web runner's frame - returns; emdawnwebgpu ABORTS on an explicit
		// wgpuSurfacePresent.
		//
		// Do NOT release the borrowed surface texture here, or on any fixed frame boundary.
		// On web wgpuQueueSubmit validates and executes ASYNCHRONOUSLY - the browser drains
		// the queue after the rAF returns - so releasing our only reference before this
		// frame's submit has been consumed destroys the texture out from under it:
		// "Destroyed texture used in a submit", and Dawn drops the whole command buffer. That
		// is the startup race that silently killed the one shot IBL env bake, and every
		// resize's reconfigure. Hand the borrow to the queue, which releases it from a work
		// done callback, provably after the submit has been consumed whatever the drain
		// latency.
		if ((mQueue != null) && (mOwnedHandle != null))
		{
			mQueue.ReleaseTextureWhenConsumed(mOwnedHandle);
			mOwnedHandle = null; // the callback owns it now
		}

		// The image STAYS current: the wrapper and its view are torn down by the next
		// acquire's DropCurrent, which by then has no handle left to release.
		return .Ok;
#else
		let status = wgpuSurfacePresent(mSurface.Handle);
		DropCurrent();
		return (status == .WGPUStatus_Success) ? .Ok : .Err;
#endif
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		DropCurrent();
		return Configure(width, height);
	}

	public void Cleanup()
	{
		DropCurrent();

		if (mConfigured)
		{
			wgpuSurfaceUnconfigure(mSurface.Handle);
			mConfigured = false;
		}
	}

	/// The non sRGB companion of an sRGB colour format, identity otherwise. A WebGPU canvas
	/// context only accepts a non sRGB config format, so an sRGB swap chain is configured
	/// with this base format plus the sRGB format as a view format.
	private static TextureFormat BaseColorFormat(TextureFormat format)
	{
		switch (format)
		{
		case .BGRA8UnormSrgb: return .BGRA8Unorm;
		case .RGBA8UnormSrgb: return .RGBA8Unorm;
		default: return format;
		}
	}

	/// The sRGB companion of a non sRGB 8 bit colour format, identity otherwise. The inverse
	/// of BaseColorFormat, for adopting the browser's preferred canvas format as an sRGB
	/// backbuffer.
	private static TextureFormat SrgbColorFormat(TextureFormat format)
	{
		switch (format)
		{
		case .BGRA8Unorm: return .BGRA8UnormSrgb;
		case .RGBA8Unorm: return .RGBA8UnormSrgb;
		default: return format;
		}
	}

#if BF_PLATFORM_WASM
	/// The browser's preferred canvas base format, which is formats[0] of the surface caps.
	/// Configuring the canvas with anything else forces an extra copy at present. Falls back
	/// to the engine default when the caps are unavailable, or are not an 8 bit unorm format
	/// this understands.
	private TextureFormat PreferredBaseFormat(TextureFormat fallback)
	{
		WGPUSurfaceCapabilities caps = .();
		if (wgpuSurfaceGetCapabilities(mSurface.Handle, mAdapter, &caps) != .WGPUStatus_Success)
			return fallback;

		if (caps.formatCount == 0)
		{
			// A successful query still allocated the caps members; free before bailing.
			wgpuSurfaceCapabilitiesFreeMembers(caps);
			return fallback;
		}

		let preferred = caps.formats[0];
		wgpuSurfaceCapabilitiesFreeMembers(caps);

		if (preferred == .WGPUTextureFormat_RGBA8Unorm)
			return .RGBA8Unorm;

		if (preferred == .WGPUTextureFormat_BGRA8Unorm)
			return .BGRA8Unorm;

		return fallback;
	}
#endif

	private Result<void> Configure(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;

		if ((width == 0) || (height == 0))
		{
			// A zero size surface is illegal - WebGPU errors "size is zero" - and a canvas
			// hits this transiently across a fullscreen or minimize transition. Skip
			// configuring: the last valid configuration stays, AcquireNextImage fails, the
			// host skips the frame, and the resize pump reconfigures once a real size arrives.
			return .Ok;
		}

		WGPUSurfaceConfiguration config = .();
		config.device = mDevice;
		// The pipeline's final hop COPIES the tonemapped output into the backbuffer, so the
		// surface needs CopyDst alongside RenderAttachment, which wgpu surfaces universally
		// support.
		config.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_CopyDst;
		config.width = width;
		config.height = height;
		config.presentMode =
			SupportedPresentMode(WebGpuConversions.ToWgpuPresentMode(mPresentMode));

#if BF_PLATFORM_WASM
		// A WebGPU canvas context does not accept an sRGB config format, so configure with the
		// base format and expose the sRGB format as a view format. AcquireNextImage then
		// creates the per frame view in mFormat, the sRGB format, so the engine's default sRGB
		// swap chain renders correctly with no app side change. Desktop wgpu-native accepts
		// sRGB config formats directly and is left exactly as it was.
		//
		// ADOPT THE BROWSER'S PREFERRED base format - rgba8unorm against bgra8unorm varies by
		// device. Configuring the canvas with a non preferred format forces the browser to
		// copy the whole frame at every present ("configured with a different format than
		// preferred"). Take the preferred base and retarget the engine to its sRGB companion,
		// so the renderer still produces an sRGB backbuffer, just in the format the compositor
		// wants.
		let baseFormat = PreferredBaseFormat(BaseColorFormat(mFormat));
		mFormat = SrgbColorFormat(baseFormat);
		config.format = WebGpuConversions.ToWgpuTextureFormat(baseFormat);
		var viewFormat = WebGpuConversions.ToWgpuTextureFormat(mFormat);
		if (baseFormat != mFormat)
		{
			config.viewFormatCount = 1;
			config.viewFormats = &viewFormat;
		}
#else
		config.format = WebGpuConversions.ToWgpuTextureFormat(mFormat);

		// Refuse CLEANLY when this adapter cannot present to the surface: wgpu-native PANICS
		// inside configure otherwise ("Surface does not support the adapter's queue family",
		// seen on Windows hybrid and multi adapter machines). Zero supported formats means no
		// present support for this surface and adapter pair; the backend logs the adapter list
		// at startup and ENV_WEBGPU_ADAPTER overrides the pick.
		{
			WGPUSurfaceCapabilities caps = .();
			if (wgpuSurfaceGetCapabilities(mSurface.Handle, mAdapter, &caps)
				== .WGPUStatus_Success)
			{
				let presentable = caps.formatCount > 0;
				wgpuSurfaceCapabilitiesFreeMembers(caps);

				if (!presentable)
				{
					GlobalLog(.Error, "[webgpu] this adapter cannot present to the window surface - set ENV_WEBGPU_ADAPTER=<index> (adapter list logged at startup)");
					return .Err;
				}
			}
		}
#endif

		wgpuSurfaceConfigure(mSurface.Handle, &config);
		mConfigured = true;
		mWidth = width;
		mHeight = height;
		return .Ok;
	}

	/// The requested mode when the surface offers it, else the closest match: Immediate and
	/// Mailbox degrade toward each other, everything else to Fifo, the only mode WebGPU
	/// guarantees.
	private WGPUPresentMode SupportedPresentMode(WGPUPresentMode requested)
	{
		WGPUSurfaceCapabilities capabilities = .();
		if (wgpuSurfaceGetCapabilities(mSurface.Handle, mAdapter, &capabilities)
			!= .WGPUStatus_Success)
			return .WGPUPresentMode_Fifo;

		WGPUPresentMode chosen = .WGPUPresentMode_Fifo;
		if (Offers(capabilities, requested))
			chosen = requested;
		else if (((requested == .WGPUPresentMode_Immediate)
			|| (requested == .WGPUPresentMode_Mailbox))
			&& Offers(capabilities, .WGPUPresentMode_Mailbox))
			chosen = .WGPUPresentMode_Mailbox;

		wgpuSurfaceCapabilitiesFreeMembers(capabilities);
		return chosen;
	}

	private static bool Offers(WGPUSurfaceCapabilities capabilities, WGPUPresentMode mode)
	{
		for (uint i = 0; i < capabilities.presentModeCount; i++)
		{
			if (capabilities.presentModes[i] == mode)
				return true;
		}

		return false;
	}

	private void DropCurrent()
	{
		if (!mHaveImage)
			return;

		DeleteAndNullify!(mCurrentView);
		DeleteAndNullify!(mCurrentTexture);

		if (mOwnedHandle != null)
		{
			wgpuTextureRelease(mOwnedHandle);
			mOwnedHandle = null;
		}

		mHaveImage = false;
	}
}
