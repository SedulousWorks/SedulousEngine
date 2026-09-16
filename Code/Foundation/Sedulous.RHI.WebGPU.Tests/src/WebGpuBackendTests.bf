using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The backend standing itself up on a real machine: an instance, the adapters behind
/// it, and what they say about themselves.
class WebGpuBackendTests
{
	/// Brings a backend up, or reports that this machine has no usable WebGPU. Every
	/// case skips rather than fails in that event, the way the Vulkan suites do, so a
	/// headless runner without a GPU stays green.
	private static bool TryStart(WebGpuBackend backend)
	{
		if (backend.Initialize() case .Err)
			return false;

		return backend.IsInitialized;
	}

	[Test]
	public static void TheBackendStartsAndTearsDown()
	{
		let backend = scope WebGpuBackend();
		if (!TryStart(backend))
			return;

		Test.Assert(backend.Instance != null, "an instance came up");

		backend.Destroy();
		Test.Assert(!backend.IsInitialized, "and went away again");
		Test.Assert(backend.Instance == null);
	}

	/// The instance keeps GL out deliberately, so every adapter it lists is one of the
	/// primary backends. A GL adapter here would mean the InstanceExtras chain was
	/// dropped, which is the shape of bug that only shows up as a crash on Windows.
	[Test]
	public static void EveryAdapterReportsItself()
	{
		let backend = scope WebGpuBackend();
		if (!TryStart(backend))
			return;
		defer backend.Destroy();

		let adapters = backend.EnumerateAdapters();
		Test.Assert(!adapters.IsEmpty, "the machine has at least one adapter");

		for (let adapter in adapters)
		{
			let info = scope AdapterInfo();
			adapter.GetInfo(info);

			Test.Assert(!info.Name.IsEmpty, "an adapter names itself");
			Test.Assert(info.Type != .Unknown, scope $"{info.Name} says what kind it is");

			// Read back from the adapter's own limits, so a zero means the limits call
			// failed rather than that the GPU is peculiar.
			Test.Assert(info.SupportedFeatures.MaxTextureDimension2D >= 2048,
				scope $"{info.Name} reports a usable 2D texture limit");
			Test.Assert(info.SupportedFeatures.MaxBindGroups > 0,
				scope $"{info.Name} reports its bind group limit");

			// Guaranteed by the spec rather than probed, so these are a check on the
			// port rather than on the driver.
			Test.Assert(info.SupportedFeatures.IndependentBlend);
			Test.Assert(info.SupportedFeatures.OcclusionQueries);
		}
	}

	/// The name has to OUTLIVE the call that produced it. WebGPU owns those bytes until
	/// FreeMembers runs, so a binding that referenced them instead of copying would
	/// read freed memory here rather than at the call.
	[Test]
	public static void AnAdaptersNameSurvivesTheCallThatReadIt()
	{
		let backend = scope WebGpuBackend();
		if (!TryStart(backend))
			return;
		defer backend.Destroy();

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return;

		let first = scope AdapterInfo();
		adapters[0].GetInfo(first);
		let captured = scope String(first.Name);

		// Read every other adapter, which frees and reallocates wgpu's own strings.
		for (let adapter in adapters)
		{
			let info = scope AdapterInfo();
			adapter.GetInfo(info);
		}

		Test.Assert(first.Name == captured, "the first name is still what it was");
	}

	/// The host takes adapters[0], and wgpu's enumeration order is arbitrary: on Windows
	/// it routinely leads with an entry that cannot PRESENT, and the swapchain then dies
	/// at configure. So a software adapter must never sort ahead of a real GPU.
	///
	/// This pins the ORDER rather than the ranking arithmetic, because the ranking is
	/// only worth anything through what ends up first.
	[Test]
	public static void RealGpusSortAheadOfSoftware()
	{
		let backend = scope WebGpuBackend();
		if (!TryStart(backend))
			return;
		defer backend.Destroy();

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return;

		var sawSoftware = false;
		for (let adapter in adapters)
		{
			let info = scope AdapterInfo();
			adapter.GetInfo(info);

			let isSoftware = info.Type == .Cpu;
			if (isSoftware)
				sawSoftware = true;
			else
				Test.Assert(!sawSoftware,
					scope $"'{info.Name}' is a real GPU but sorted after a software one");
		}

		// Whatever else it is, the head of the list is the one that has to be able to
		// present, so it must not be the software entry.
		let first = scope AdapterInfo();
		adapters[0].GetInfo(first);
		Test.Assert(first.Type != .Cpu, "the host's default adapter is not a software one");
	}
}
