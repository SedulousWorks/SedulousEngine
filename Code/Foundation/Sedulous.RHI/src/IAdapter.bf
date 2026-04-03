namespace Sedulous.RHI;

using System;

/// A GPU adapter (physical device).
/// Obtained from IBackend.EnumerateAdapters().
interface IAdapter
{
	/// Returns information about this adapter.
	/// Caller must `delete` the returned AdapterInfo.
	AdapterInfo GetInfo();

	/// Creates a logical device from this adapter.
	Result<IDevice> CreateDevice(DeviceDesc desc);
}
