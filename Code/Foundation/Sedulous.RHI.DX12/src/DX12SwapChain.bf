namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

/// DX12 implementation of ISwapChain.
/// Wraps an IDXGISwapChain3 for presentation.
class DX12SwapChain : ISwapChain
{
	private DX12Device mDevice;
	private IDXGISwapChain3* mSwapChain;
	private TextureFormat mFormat;
	private uint32 mWidth;
	private uint32 mHeight;
	private uint32 mBufferCount;
	private uint32 mCurrentIndex;
	private PresentMode mPresentMode;

	private List<DX12Texture> mTextures = new .() ~ DeleteContainerAndItems!(_);
	private List<DX12TextureView> mTextureViews = new .() ~ DeleteContainerAndItems!(_);

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mCurrentIndex;

	public ITexture CurrentTexture => (mCurrentIndex < (uint32)mTextures.Count) ? mTextures[(.)mCurrentIndex] : null;
	public ITextureView CurrentTextureView => (mCurrentIndex < (uint32)mTextureViews.Count) ? mTextureViews[(.)mCurrentIndex] : null;

	public this() { }

	public Result<void> Init(DX12Device device, DX12Surface surface, SwapChainDesc desc)
	{
		mDevice = device;
		mFormat = desc.Format;
		mWidth = desc.Width;
		mHeight = desc.Height;
		mBufferCount = desc.BufferCount;
		mPresentMode = desc.PresentMode;

		// Use the same DXGI factory that enumerated the adapter
		IDXGIFactory4* factory = device.Adapter.Factory;
		if (factory == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12SwapChain: DXGI factory is null");
			return .Err;
		}

		// Get the command queue from the first graphics queue
		let queue = device.GetQueue(.Graphics) as DX12Queue;
		if (queue == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12SwapChain: graphics queue is null");
			return .Err;
		}

		// Flip model swap chains require non-sRGB format for the buffer.
		// The sRGB format is applied via the RTV (texture view) instead.
		let swapChainDxgiFormat = StripSrgb(DX12Conversions.ToDxgiFormat(desc.Format));

		DXGI_SWAP_CHAIN_DESC1 swapDesc = .()
		{
			Width = desc.Width,
			Height = desc.Height,
			Format = swapChainDxgiFormat,
			Stereo = FALSE,
			SampleDesc = .() { Count = 1, Quality = 0 },
			BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT,
			BufferCount = desc.BufferCount,
			Scaling = .DXGI_SCALING_STRETCH,
			SwapEffect = .DXGI_SWAP_EFFECT_FLIP_DISCARD,
			AlphaMode = .DXGI_ALPHA_MODE_UNSPECIFIED,
			Flags = 0
		};

		// Allow tearing for immediate mode
		if (desc.PresentMode == .Immediate)
			swapDesc.Flags = (uint32)DXGI_SWAP_CHAIN_FLAG.DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;

		IDXGISwapChain1* swapChain1 = null;
		HRESULT hr = factory.CreateSwapChainForHwnd(
			(Win32.System.Com.IUnknown*)queue.Handle,
			surface.Handle,
			&swapDesc, null, null, &swapChain1);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12SwapChain: CreateSwapChainForHwnd failed (0x{hr:X})");
			return .Err;
		}

		// Disable Alt+Enter fullscreen
		factory.MakeWindowAssociation(surface.Handle, (uint32)1); // DXGI_MWA_NO_ALT_ENTER

		// QueryInterface for IDXGISwapChain3
		hr = swapChain1.QueryInterface(IDXGISwapChain3.IID, (void**)&mSwapChain);
		swapChain1.Release();
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12SwapChain: QueryInterface for IDXGISwapChain3 failed (0x{hr:X})");
			return .Err;
		}

		// Get back buffers
		if (AcquireBackBuffers() case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12SwapChain: AcquireBackBuffers failed");
			return .Err;
		}

		mCurrentIndex = mSwapChain.GetCurrentBackBufferIndex();
		return .Ok;
	}

	public Result<void> AcquireNextImage()
	{
		mCurrentIndex = mSwapChain.GetCurrentBackBufferIndex();
		return .Ok;
	}

	public Result<void> Present(IQueue queue)
	{
		uint32 syncInterval = 1;
		uint32 flags = 0;

		switch (mPresentMode)
		{
		case .Immediate:
			syncInterval = 0;
			flags = 0x00000200; // DXGI_PRESENT_ALLOW_TEARING
		case .Mailbox:
			syncInterval = 0;
		case .Fifo:
			syncInterval = 1;
		case .FifoRelaxed:
			syncInterval = 1;
		}

		HRESULT hr = mSwapChain.Present(syncInterval, flags);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12SwapChain: Present failed (0x{hr:X})");
			return .Err;
		}

		return .Ok;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		if (width == 0 || height == 0) return .Ok;

		mWidth = width;
		mHeight = height;

		// Release existing back buffers
		ReleaseBackBuffers();

		HRESULT hr = mSwapChain.ResizeBuffers(mBufferCount,
			width, height,
			StripSrgb(DX12Conversions.ToDxgiFormat(mFormat)), 0);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12SwapChain: ResizeBuffers failed (0x{hr:X})");
			return .Err;
		}

		if (AcquireBackBuffers() case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12SwapChain: AcquireBackBuffers failed after resize");
			return .Err;
		}
		mCurrentIndex = mSwapChain.GetCurrentBackBufferIndex();
		return .Ok;
	}

	private Result<void> AcquireBackBuffers()
	{
		for (uint32 i = 0; i < mBufferCount; i++)
		{
			ID3D12Resource* resource = null;
			HRESULT hr = mSwapChain.GetBuffer(i, ID3D12Resource.IID, (void**)&resource);
			if (!SUCCEEDED(hr))
			{
				System.Diagnostics.Debug.WriteLine(scope $"DX12SwapChain: GetBuffer({i}) failed (0x{hr:X})");
				return .Err;
			}

			let texture = new DX12Texture();
			TextureDesc texDesc = .()
			{
				Dimension = .Texture2D,
				Format = mFormat,
				Width = mWidth,
				Height = mHeight,
				ArrayLayerCount = 1,
				MipLevelCount = 1,
				SampleCount = 1,
				Usage = .RenderTarget
			};
			texture.InitFromExisting(resource, texDesc);
			mTextures.Add(texture);

			let view = new DX12TextureView();
			TextureViewDesc viewDesc = .()
			{
				Format = mFormat,
				Dimension = .Texture2D,
				BaseMipLevel = 0,
				MipLevelCount = 1,
				BaseArrayLayer = 0,
				ArrayLayerCount = 1
			};
			if (view.Init(mDevice, texture, viewDesc) case .Err)
			{
				System.Diagnostics.Debug.WriteLine("DX12SwapChain: back buffer texture view Init failed");
				delete view;
				return .Err;
			}
			mTextureViews.Add(view);
		}

		return .Ok;
	}

	private void ReleaseBackBuffers()
	{
		for (let view in mTextureViews)
		{
			view.Cleanup(mDevice);
			delete view;
		}
		mTextureViews.Clear();

		for (let tex in mTextures)
		{
			tex.Cleanup(mDevice);
			delete tex;
		}
		mTextures.Clear();
	}

	public void Cleanup(DX12Device device)
	{
		ReleaseBackBuffers();
		if (mSwapChain != null)
		{
			mSwapChain.Release();
			mSwapChain = null;
		}
	}

	/// Strips sRGB from a DXGI format. Flip model swap chains require non-sRGB buffer formats;
	/// sRGB is applied via the RTV instead.
	private static DXGI_FORMAT StripSrgb(DXGI_FORMAT format)
	{
		switch (format)
		{
		case .DXGI_FORMAT_R8G8B8A8_UNORM_SRGB: return .DXGI_FORMAT_R8G8B8A8_UNORM;
		case .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB: return .DXGI_FORMAT_B8G8R8A8_UNORM;
		case .DXGI_FORMAT_BC1_UNORM_SRGB:       return .DXGI_FORMAT_BC1_UNORM;
		case .DXGI_FORMAT_BC2_UNORM_SRGB:       return .DXGI_FORMAT_BC2_UNORM;
		case .DXGI_FORMAT_BC3_UNORM_SRGB:       return .DXGI_FORMAT_BC3_UNORM;
		case .DXGI_FORMAT_BC7_UNORM_SRGB:       return .DXGI_FORMAT_BC7_UNORM;
		default: return format;
		}
	}
}
