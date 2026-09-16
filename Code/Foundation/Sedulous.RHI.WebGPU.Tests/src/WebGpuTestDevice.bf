using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// Brings a live device up on this machine, for the cases that need a real GPU.
///
/// Hands back null rather than failing when the machine has no usable WebGPU, so a
/// headless runner stays green: the cases that need a device skip, the way the Vulkan
/// suites do. The DEVICE belongs to the adapter behind it, which belongs to the backend,
/// so destroying the backend is all a case has to do.
static class WebGpuTestDevice
{
	public static IDevice TryCreate(WebGpuBackend backend)
	{
		if (backend.Initialize() case .Err)
			return null;

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return null;

		if (adapters[0].CreateDevice(.()) case .Ok(let device))
			return device;

		return null;
	}
}
