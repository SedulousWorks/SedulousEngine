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

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (let validated = encoder as ValidatedCommandEncoder)
		{
			var inner = validated.Inner;
			mInner.DestroyEncoder(ref inner);
			encoder = null;
			return;
		}
		mInner.DestroyEncoder(ref encoder);
	}

	/// Resetting invalidates every encoder and bundle from this pool, so the wrappers go
	/// with them: keeping one would let a caller record into a reset allocator, which is
	/// exactly the DX12 crash the pool contract exists to prevent.
	public void Reset()
	{
		ClearAndDeleteItems!(mEncoders);
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
