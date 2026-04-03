namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for ICommandPool.
class ValidatedCommandPool : ICommandPool
{
	private ICommandPool mInner;

	public this(ICommandPool inner)
	{
		mInner = inner;
	}

	public Result<ICommandEncoder> CreateEncoder()
	{
		let result = mInner.CreateEncoder();
		if (result case .Ok(let encoder))
		{
			return .Ok(new ValidatedCommandEncoder(encoder));
		}
		return .Err;
	}

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (encoder != null)
		{
			if (let validated = encoder as ValidatedCommandEncoder)
			{
				var inner = validated.Inner;
				mInner.DestroyEncoder(ref inner);
			}
			delete encoder;
			encoder = null;
		}
	}

	public void Reset()
	{
		mInner.Reset();
	}

	public ICommandPool Inner => mInner;
}
