using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Wraps an adapter so the devices it creates are watched.
class ValidatedAdapter : IAdapter
{
	private IAdapter mInner;
	private List<ValidatedDevice> mDevices = new .() ~ DeleteContainerAndItems!(_);

	public this(IAdapter inner) => mInner = inner;

	public IAdapter Inner => mInner;

	public void GetInfo(AdapterInfo outInfo) => mInner.GetInfo(outInfo);

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		if (mInner.CreateDevice(desc) case .Ok(let inner))
		{
			let device = new ValidatedDevice(inner);
			mDevices.Add(device);
			return .Ok(device);
		}
		return .Err;
	}
}
