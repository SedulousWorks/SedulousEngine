using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Wraps the pool so every encoder it hands out is watched too.
class ValidatedCommandPool : ICommandPool
{
	private ICommandPool mInner;
	private List<ValidatedCommandEncoder> mEncoders = new .() ~ DeleteContainerAndItems!(_);
	private ValidatedRenderBundleEncoder mBundleEncoder ~ delete _;

	public this(ICommandPool inner) => mInner = inner;

	public ICommandPool Inner => mInner;

	public Result<ICommandEncoder> CreateEncoder()
	{
		if (mInner.CreateEncoder() case .Ok(let inner))
		{
			// The backend may hand back the same encoder each time, as the null one does,
			// so an existing wrapper is reused rather than stacking a second one over it.
			for (let existing in mEncoders)
			{
				if (existing.Inner === inner)
					return .Ok(existing);
			}
			let wrapper = new ValidatedCommandEncoder(inner);
			mEncoders.Add(wrapper);
			return .Ok(wrapper);
		}
		return .Err;
	}

	/// Destroys one encoder, wrapper and all.
	///
	/// The wrapper is owned HERE rather than by Reset, because a caller may reset the pool
	/// and then destroy an encoder it still holds. Freeing wrappers on reset would make
	/// that ordinary sequence read freed memory.
	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (let validated = encoder as ValidatedCommandEncoder)
		{
			var inner = validated.Inner;
			mInner.DestroyEncoder(ref inner);
			mEncoders.Remove(validated);
			delete validated;
			encoder = null;
			return;
		}
		mInner.DestroyEncoder(ref encoder);
	}

	/// Resetting invalidates every encoder and bundle this pool produced.
	///
	/// BUNDLE encoders are freed here, since nothing else owns them. Command encoders are
	/// not: destroying one after a reset is an ordinary sequence, and freeing them here
	/// would turn it into a use after free.
	public void Reset()
	{
		delete mBundleEncoder;
		mBundleEncoder = null;
		mInner.Reset();
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		let inner = mInner.CreateRenderBundleEncoder(desc);
		if (inner == null)
			return null;
		delete mBundleEncoder;
		mBundleEncoder = new ValidatedRenderBundleEncoder(inner);
		return mBundleEncoder;
	}
}
