namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for ISwapChain.
/// Enforces: acquire before render, present after render.
class ValidatedSwapChain : ISwapChain
{
	private ISwapChain mInner;
	private bool mImageAcquired;

	public this(ISwapChain inner)
	{
		mInner = inner;
	}

	public TextureFormat Format => mInner.Format;
	public uint32 Width => mInner.Width;
	public uint32 Height => mInner.Height;
	public uint32 BufferCount => mInner.BufferCount;
	public uint32 CurrentImageIndex => mInner.CurrentImageIndex;

	public Result<void> AcquireNextImage()
	{
		if (mImageAcquired)
		{
			ValidationLogger.Warn("AcquireNextImage: image already acquired (missing Present call?)");
		}

		let result = mInner.AcquireNextImage();
		if (result case .Ok)
			mImageAcquired = true;
		return result;
	}

	public ITexture CurrentTexture
	{
		get
		{
			if (!mImageAcquired)
			{
				ValidationLogger.Error("CurrentTexture: no image acquired (call AcquireNextImage first)");
			}
			return mInner.CurrentTexture;
		}
	}

	public ITextureView CurrentTextureView
	{
		get
		{
			if (!mImageAcquired)
			{
				ValidationLogger.Error("CurrentTextureView: no image acquired (call AcquireNextImage first)");
			}
			return mInner.CurrentTextureView;
		}
	}

	public Result<void> Present(IQueue queue)
	{
		if (!mImageAcquired)
		{
			ValidationLogger.Error("Present: no image acquired (call AcquireNextImage first)");
			return .Err;
		}

		if (queue == null)
		{
			ValidationLogger.Error("Present: queue is null");
			return .Err;
		}

		// Unwrap validated queue
		IQueue innerQueue = queue;
		if (let vq = queue as ValidatedQueue)
			innerQueue = vq.Inner;

		let result = mInner.Present(innerQueue);
		mImageAcquired = false;
		return result;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		if (mImageAcquired)
		{
			ValidationLogger.Error("Resize: cannot resize while an image is acquired");
		}

		if (width == 0 || height == 0)
		{
			ValidationLogger.Error("Resize: width or height is 0");
			return .Err;
		}

		return mInner.Resize(width, height);
	}

	public ISwapChain Inner => mInner;
}
