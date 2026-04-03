namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for IAdapter.
class ValidatedAdapter : IAdapter
{
	private IAdapter mInner;

	public this(IAdapter inner)
	{
		mInner = inner;
	}

	public AdapterInfo GetInfo()
	{
		return mInner.GetInfo();
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		let result = mInner.CreateDevice(desc);
		if (result case .Ok(let device))
		{
			return .Ok(new ValidatedDevice(device));
		}
		return .Err;
	}

	public IAdapter Inner => mInner;
}
