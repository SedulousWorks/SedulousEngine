using System;
using System.IO;
using Sedulous.Core;
using Sedulous.VFS;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.Vulkan;
using Sedulous.RHI.WebGPU;
#if BF_PLATFORM_WINDOWS
// The namespace itself does not exist off Windows: every file in the backend is guarded out.
using Sedulous.RHI.DX12;
#endif
using Sedulous.Shaders;

namespace Sedulous.VG.Backend.Tests;

/// A real device and the engine's own vector shaders.
///
/// SKIPS rather than fails where there is no device or no shader directory: a machine that
/// cannot answer the question has not answered it wrongly.
class VGProbeFixture
{
	/// The data root mounted for this fixture, which is where the shaders come from.
	public NativeFileSystem DataMount ~ delete _;
	public IBackend Backend;
	public IDevice Device;
	public ShaderSystemHost Host ~ delete _;

	public bool Ready { get; private set; }

	/// Which backend this fixture was asked for, so an assertion can name it.
	public ProbeBackend Kind { get; private set; }

	public this(ProbeBackend kind = .Vulkan)
	{
		Kind = kind;

		switch (kind)
		{
		case .Vulkan:
			if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
				return;
			Backend = backend;
		case .WebGpu:
			if (!(WebGpuRhi.CreateBackend() case .Ok(let backend)))
				return;
			Backend = backend;
		case .Dx12:
#if BF_PLATFORM_WINDOWS
			if (!(DxRhi.CreateBackend() case .Ok(let backend)))
				return;
			Backend = backend;
#else
			return; // no DX12 off Windows, so this fixture is simply not ready
#endif
		}

		Device = RhiTestSupport.MakeTestDevice(Backend);
		if (Device == null)
			return;

		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		if (dataRoot.IsEmpty)
			return;
		DataMount = new NativeFileSystem(dataRoot);

		Host = new ShaderSystemHost();
		if (Host.Initialize(Device, DataMount) case .Err)
			return;

		Ready = true;
	}

	public ~this()
	{
		if (Host != null)
			Host.Shutdown();

		if (Device != null)
			Device.Destroy();
		if (Backend != null)
		{
			Backend.Destroy();
			delete Backend;
		}
	}

}
