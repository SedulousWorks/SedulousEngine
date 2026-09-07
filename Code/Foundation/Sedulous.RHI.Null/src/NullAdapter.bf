using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// The single adapter the null backend offers, reporting itself as a CPU device.
///
/// Cpu rather than Unknown so it sorts LAST: a process that also has a real GPU backend
/// should never pick this one by taking element zero.
class NullAdapter : IAdapter
{
	private List<NullDevice> mDevices = new .() ~ DeleteContainerAndItems!(_);

	public void GetInfo(AdapterInfo outInfo)
	{
		outInfo.Name.Set("Null Device");
		outInfo.VendorId = 0;
		outInfo.DeviceId = 0;
		outInfo.Type = .Cpu;
	}

	/// The adapter OWNS the devices it makes, so a caller may drop one without leaking.
	/// IDevice.Destroy is a no op for the same reason.
	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		let device = new NullDevice();
		device.Features = desc.RequiredFeatures;
		mDevices.Add(device);
		return .Ok(device);
	}
}
