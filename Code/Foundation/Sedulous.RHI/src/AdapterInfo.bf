using System;

namespace Sedulous.RHI;

/// What one physical adapter is, and what it can do.
///
/// The name is a String this OWNS, so an AdapterInfo is filled by GetInfo rather than
/// returned by value: the caller supplies the storage and keeps it as long as it needs the
/// name.
class AdapterInfo
{
	public String Name = new .() ~ delete _;
	public uint32 VendorId = 0;
	public uint32 DeviceId = 0;
	public AdapterType Type = .Unknown;

	/// Read before creating a device, and narrowed into the DeviceDesc that creates it.
	public DeviceFeatures SupportedFeatures = .();
}
