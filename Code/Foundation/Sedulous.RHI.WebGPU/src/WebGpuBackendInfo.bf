using System;
using wgpu_Beef;

namespace Sedulous.RHI.WebGPU;

/// The backend's first foothold: it proves the binding links and reports what the
/// loaded wgpu-native actually is, which is the one thing worth knowing before any
/// device exists.
///
/// The rest of the backend lands on top of this. Everything here is desktop only:
/// wgpuGetVersion is a wgpu-native extension, absent from a browser's webgpu.h.
static class WebGpuBackendInfo
{
	/// The wgpu-native build this links against, as the packed version word.
	public static uint32 NativeVersion => wgpuGetVersion();

	/// The same, spelled the way the release tags do.
	public static void NativeVersionString(String outVersion)
	{
		let packed = NativeVersion;
		outVersion.AppendF("{}.{}.{}.{}", (packed >> 24) & 0xFF, (packed >> 16) & 0xFF,
			(packed >> 8) & 0xFF, packed & 0xFF);
	}
}
