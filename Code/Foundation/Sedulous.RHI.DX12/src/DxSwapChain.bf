#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Win32.Graphics.Dxgi.Common;
using Win32.System.Com;

namespace Sedulous.RHI.DX12;

/// The DXGI swap chain and the back buffers it hands out.
///
/// The swap chain itself is created NON SRGB even when the RHI format is an sRGB one: a flip
/// model swap chain refuses an sRGB back buffer format, and the conversion is done by the
/// render target VIEW instead. That is what stripSrgb is for, and why Resize has to strip it
/// again rather than reuse the stored format directly.
///
/// The textures and views wrapping the back buffers are OWNED here and rebuilt on every
/// resize, because ResizeBuffers invalidates every outstanding reference to them.
class DxSwapChain : ISwapChain
{
	private IDXGISwapChain3* mSwapChain = null; // owned, released in Cleanup
	private ID3D12Device* mD3dDevice = null; // NOT owned

	private TextureFormat mFormat = .RGBA8UnormSrgb;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private uint32 mBufferCount = 2;
	private uint32 mCurrentIndex = 0;
	private PresentMode mPresentMode = .Fifo;

	private List<DxTexture> mTextures = new .() ~ DeleteContainerAndItems!(_);
	private List<DxTextureView> mViews = new .() ~ DeleteContainerAndItems!(_);

	private DxDescriptorHeapAllocator mSrvHeap = null; // none owned, all the device's
	private DxDescriptorHeapAllocator mRtvHeap = null;
	private DxDescriptorHeapAllocator mDsvHeap = null;

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mCurrentIndex;

	public ITexture CurrentTexture =>
		((int)mCurrentIndex < mTextures.Count) ? mTextures[(int)mCurrentIndex] : null;

	public ITextureView CurrentTextureView =>
		((int)mCurrentIndex < mViews.Count) ? mViews[(int)mCurrentIndex] : null;

	public Result<void> Initialize(ID3D12Device* device, IDXGIFactory4* factory,
		ID3D12CommandQueue* gfxQueue, DxSurface surface, SwapChainDesc d,
		DxDescriptorHeapAllocator srvHeap, DxDescriptorHeapAllocator rtvHeap,
		DxDescriptorHeapAllocator dsvHeap)
	{
		mD3dDevice = device;
		mFormat = d.Format;
		mWidth = d.Width;
		mHeight = d.Height;
		mBufferCount = d.BufferCount;
		mPresentMode = d.PresentMode;
		mSrvHeap = srvHeap;
		mRtvHeap = rtvHeap;
		mDsvHeap = dsvHeap;

		let swapFmt = DxConversions.StripSrgb(DxConversions.ToDxgiFormat(d.Format));

		DXGI_SWAP_CHAIN_DESC1 sd = .();
		sd.Width = d.Width;
		sd.Height = d.Height;
		sd.Format = swapFmt;
		sd.SampleDesc.Count = 1;
		sd.SampleDesc.Quality = 0;
		sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		sd.BufferCount = d.BufferCount;
		sd.Scaling = .DXGI_SCALING_STRETCH;
		sd.SwapEffect = .DXGI_SWAP_EFFECT_FLIP_DISCARD;
		sd.AlphaMode = .DXGI_ALPHA_MODE_UNSPECIFIED;
		// Tearing has to be asked for at CREATION, not just at present.
		if (d.PresentMode == .Immediate)
			sd.Flags = (uint32)DXGI_SWAP_CHAIN_FLAG.DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;

		IDXGISwapChain1* sc1 = null;
		let hr = factory.CreateSwapChainForHwnd((IUnknown*)gfxQueue, surface.Handle, &sd, null,
			null, &sc1);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxSwapChain: CreateSwapChainForHwnd failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}
		defer sc1.Release();

		// DXGI's own alt-enter handling fights the shell's, so it is switched off.
		factory.MakeWindowAssociation(surface.Handle, DXGI_MWA_NO_ALT_ENTER);

		if (FAILED(sc1.QueryInterface(IDXGISwapChain3.IID, (void**)&mSwapChain)))
			return .Err;

		if (AcquireBackBuffers() case .Err)
			return .Err;

		mCurrentIndex = mSwapChain.GetCurrentBackBufferIndex();
		return .Ok;
	}

	public Result<void> AcquireNextImage()
	{
		// DXGI has no acquire: the index is simply asked for.
		mCurrentIndex = mSwapChain.GetCurrentBackBufferIndex();
		return .Ok;
	}

	public Result<void> Present(IQueue queue)
	{
		// The queue is not named here. DXGI presents against the queue the swap chain was
		// created with, unlike Vulkan where the present queue is given per call.
		uint32 syncInterval = 1;
		uint32 flags = 0;

		switch (mPresentMode)
		{
		case .Immediate:
			syncInterval = 0;
			flags = DXGI_PRESENT_ALLOW_TEARING;
		case .Mailbox:
			syncInterval = 0;
		case .Fifo, .FifoRelaxed:
			syncInterval = 1;
		}

		return SUCCEEDED(mSwapChain.Present(syncInterval, flags)) ? .Ok : .Err;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		if ((width == 0) || (height == 0))
			return .Ok;

		mWidth = width;
		mHeight = height;

		// Every outstanding reference to a back buffer has to be gone before ResizeBuffers,
		// or it fails.
		ReleaseBackBuffers();

		if (FAILED(mSwapChain.ResizeBuffers(mBufferCount, width, height,
			DxConversions.StripSrgb(DxConversions.ToDxgiFormat(mFormat)), 0)))
			return .Err;

		if (AcquireBackBuffers() case .Err)
			return .Err;

		mCurrentIndex = mSwapChain.GetCurrentBackBufferIndex();
		return .Ok;
	}

	public void Cleanup()
	{
		ReleaseBackBuffers();

		if (mSwapChain != null)
		{
			mSwapChain.Release();
			mSwapChain = null;
		}
	}

	private Result<void> AcquireBackBuffers()
	{
		for (uint32 i = 0; i < mBufferCount; i++)
		{
			ID3D12Resource* resource = null;
			if (FAILED(mSwapChain.GetBuffer(i, ID3D12Resource.IID, (void**)&resource)))
				return .Err;

			let tex = new DxTexture();
			TextureDesc td = .();
			td.Dimension = .Texture2D;
			td.Format = mFormat;
			td.Width = mWidth;
			td.Height = mHeight;
			td.ArrayLayerCount = 1;
			td.MipLevelCount = 1;
			td.SampleCount = 1;
			td.Usage = .RenderTarget;
			tex.InitializeFromExisting(resource, td);
			// InitializeFromExisting took its own reference, so this one goes.
			resource.Release();
			mTextures.Add(tex);

			let view = new DxTextureView();
			TextureViewDesc vd = .();
			vd.Format = mFormat;
			vd.Dimension = .Texture2D;
			vd.MipLevelCount = 1;
			vd.ArrayLayerCount = 1;
			view.Initialize(mD3dDevice, tex, vd, mSrvHeap, mRtvHeap, mDsvHeap).IgnoreError();
			mViews.Add(view);
		}

		return .Ok;
	}

	private void ReleaseBackBuffers()
	{
		// Views first: each holds descriptor slots cut against its texture.
		for (let v in mViews)
			v.Cleanup();
		ClearAndDeleteItems!(mViews);

		for (let t in mTextures)
			t.Cleanup();
		ClearAndDeleteItems!(mTextures);
	}
}

#endif // BF_PLATFORM_WINDOWS
