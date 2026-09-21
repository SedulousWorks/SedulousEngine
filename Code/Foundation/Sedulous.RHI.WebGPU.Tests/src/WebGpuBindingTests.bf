using System;
using wgpu_Beef;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The binding actually reaches wgpu-native, which is the one thing that has to be
/// true before any of the backend is worth writing.
///
/// These call the library rather than inspecting the declarations, because a
/// generated binding that compiles can still be wrong about linkage, and a version
/// read back out of the sidecar catches a stale one beside the executable.
class WebGpuBindingTests
{
	/// The vendored sidecar, whose headers the generator's bindings came from.
	private const uint32 cExpectedVersion = 0x1D000101; // v29.0.1.1

	[Test]
	public static void TheSidecarLoadsAndReportsThePinnedVersion()
	{
		let version = WebGpuBackendInfo.NativeVersion;
		Test.Assert(version != 0, "wgpu-native answered, so the sidecar resolved");

		let spelled = scope String();
		WebGpuBackendInfo.NativeVersionString(spelled);
		Test.Assert(version == cExpectedVersion,
			scope $"linked wgpu-native {spelled}, expected v29.0.1.1");
	}

	/// An instance is the first object the standard header can make, and making one
	/// proves the descriptor layout agrees with the library's: a struct the generator
	/// got wrong shows up here as a null instance rather than as a compile error.
	[Test]
	public static void AnInstanceCreatesAndReleasesThroughTheStandardHeader()
	{
		let instance = wgpuCreateInstance(null);
		Test.Assert(instance != null, "the standard entry point built an instance");
		wgpuInstanceRelease(instance);
	}

	/// The wgpu-native EXTENSION surface, which is the desktop-only half and the part
	/// a browser build compiles out. Enumerating adapters has no standard counterpart,
	/// so this is what says the extension header's entry points linked too.
	[Test]
	public static void TheNativeExtensionEnumeratesAdapters()
	{
		let instance = wgpuCreateInstance(null);
		Test.Assert(instance != null);
		defer wgpuInstanceRelease(instance);

		// Count first with a null array, which is how the call reports how many there are.
		let count = wgpuInstanceEnumerateAdapters(instance, null, null);
		Test.Assert(count > 0, "the machine has at least one WebGPU adapter");

		let adapters = scope WGPUAdapter[count];
		let filled = wgpuInstanceEnumerateAdapters(instance, null, adapters.Ptr);
		Test.Assert(filled == count);

		for (let adapter in adapters)
		{
			Test.Assert(adapter != null, "every enumerated adapter is real");
			wgpuAdapterRelease(adapter);
		}
	}
}
