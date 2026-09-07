using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches the acquire, present and resize cycle, which has a strict order that backends
/// enforce with a hang rather than an error.
class ValidatedSwapChain : ISwapChain
{
	private ISwapChain mInner;
	private bool mAcquired = false;

	public this(ISwapChain inner) => mInner = inner;

	public ISwapChain Inner => mInner;

	public TextureFormat Format => mInner.Format;
	public uint32 Width => mInner.Width;
	public uint32 Height => mInner.Height;
	public uint32 BufferCount => mInner.BufferCount;
	public uint32 CurrentImageIndex => mInner.CurrentImageIndex;
	public ITexture CurrentTexture => mInner.CurrentTexture;
	public ITextureView CurrentTextureView => mInner.CurrentTextureView;

	/// Acquiring twice without presenting exhausts the chain and blocks, which reads as a
	/// hang rather than a mistake.
	public Result<void> AcquireNextImage()
	{
		if (mAcquired)
			ValidationLog.Warn("SwapChain.AcquireNextImage: an image is already acquired");
		let result = mInner.AcquireNextImage();
		if (result case .Ok)
			mAcquired = true;
		return result;
	}

	/// Presenting without an acquired image presents whatever was there last.
	public Result<void> Present(IQueue queue)
	{
		if (!mAcquired)
			ValidationLog.Warn("SwapChain.Present: no image has been acquired");
		let result = mInner.Present(queue);
		mAcquired = false;
		return result;
	}

	/// Resizing destroys the back buffers, so doing it while one is held leaves the caller
	/// pointing at freed images. An ERROR rather than a warning: the result is a use after
	/// free, not merely an odd frame.
	public Result<void> Resize(uint32 width, uint32 height)
	{
		if (mAcquired)
		{
			ValidationLog.Error("SwapChain.Resize: cannot resize while an image is acquired");
			return .Err;
		}
		if ((width == 0) || (height == 0))
		{
			ValidationLog.Error("SwapChain.Resize: dimensions are zero");
			return .Err;
		}
		return mInner.Resize(width, height);
	}
}
