using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// One physical GPU: ask what it can do, then make a device from it.
interface IAdapter
{
	/// Fills in the name, vendor, features and limits. The caller supplies the object,
	/// because it owns the name string.
	void GetInfo(AdapterInfo outInfo);

	Result<IDevice> CreateDevice(DeviceDesc desc);
}
