using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// A swap chain that cycles an index over back buffers that do not exist.
///
/// Cycling matters: a caller that keys per frame resources on CurrentImageIndex is
/// exercised properly headlessly, and one that assumed the index never moved would be
/// caught here rather than on a real device.
class NullSwapChain : ISwapChain
{
	private NullTexture mTexture = new .() ~ delete _;
	private NullTextureView mView = new .() ~ delete _;

	private TextureFormat mFormat = .BGRA8UnormSrgb;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private uint32 mBufferCount = 2;
	private uint32 mImageIndex = 0;

	public void Initialize(SwapChainDesc desc)
	{
		mFormat = desc.Format;
		mWidth = desc.Width;
		mHeight = desc.Height;
		// At least one, so AcquireNextImage cannot divide by zero on a descriptor that
		// asked for none.
		mBufferCount = (desc.BufferCount > 0) ? desc.BufferCount : 1;

		var textureDesc = TextureDesc();
		textureDesc.Format = mFormat;
		textureDesc.Width = mWidth;
		textureDesc.Height = mHeight;
		textureDesc.Usage = .RenderTarget;
		mTexture.Initialize(textureDesc);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = mFormat;
		mView.Initialize(mTexture, viewDesc);
	}

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mImageIndex;

	public Result<void> AcquireNextImage()
	{
		mImageIndex = (mImageIndex + 1) % mBufferCount;
		return .Ok;
	}

	public ITexture CurrentTexture => mTexture;
	public ITextureView CurrentTextureView => mView;

	/// The queue the last Present was given.
	///
	/// Recorded because a real backend CASTS this to its own queue type, so a layer that
	/// forwards a wrapper instead of the queue it wraps silently fails to present. Nothing
	/// here casts, so without this the Null backend cannot show that difference and a
	/// validation layer that forgot to unwrap would pass its tests.
	public IQueue LastPresentQueue { get; private set; } = null;

	public Result<void> Present(IQueue queue)
	{
		LastPresentQueue = queue;
		return .Ok;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
		return .Ok;
	}
}
