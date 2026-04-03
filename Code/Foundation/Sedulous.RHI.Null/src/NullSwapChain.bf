namespace Sedulous.RHI.Null;

using System;

class NullSwapChain : ISwapChain
{
	private TextureFormat mFormat;
	private uint32 mWidth;
	private uint32 mHeight;
	private uint32 mBufferCount;
	private uint32 mCurrentIndex;
	private NullTexture mTexture ~ delete _;
	private NullTextureView mTextureView ~ delete _;

	public this(SwapChainDesc desc)
	{
		mFormat = desc.Format;
		mWidth = desc.Width;
		mHeight = desc.Height;
		mBufferCount = desc.BufferCount;
		CreateBackingResources();
	}

	private void CreateBackingResources()
	{
		delete mTexture;
		delete mTextureView;

		mTexture = new NullTexture(TextureDesc.RenderTarget(mFormat, mWidth, mHeight, 1, "SwapChainTexture"));
		mTextureView = new NullTextureView(mTexture, .() { Format = mFormat });
	}

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mCurrentIndex;
	public ITexture CurrentTexture => mTexture;
	public ITextureView CurrentTextureView => mTextureView;

	public Result<void> AcquireNextImage()
	{
		mCurrentIndex = (mCurrentIndex + 1) % mBufferCount;
		return .Ok;
	}

	public Result<void> Present(IQueue queue)
	{
		return .Ok;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
		CreateBackingResources();
		return .Ok;
	}
}
