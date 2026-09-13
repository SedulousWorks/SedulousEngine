using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.Vulkan;
using Sedulous.Shaders;

namespace Sedulous.VG.Backend.Tests;

/// A real device and the engine's own vector shaders.
///
/// SKIPS rather than fails where there is no device or no shader directory: a machine that
/// cannot answer the question has not answered it wrongly.
class VGProbeFixture
{
	public IBackend Backend;
	public IDevice Device;
	public ShaderSystemHost Host ~ delete _;

	public bool Ready { get; private set; }

	public this()
	{
		if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
			return;
		Backend = backend;

		Device = RhiTestSupport.MakeTestDevice(Backend);
		if (Device == null)
			return;

		let root = scope String();
		if (!FindShaderRoot(root))
			return;

		Host = new ShaderSystemHost();
		if (Host.Initialize(Device, root) case .Err)
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

	private static bool FindShaderRoot(String outPath)
	{
		let current = scope String();
		GetCurrentDirectory(current);

		for (int depth < 8)
		{
			let candidate = scope:: String();
			PathJoin(current, "Data/Shaders", candidate);
			if (Directory.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}

			let parent = scope:: String();
			PathParent(current, parent);
			if (parent.IsEmpty || (parent == current))
				break;
			current.Set(parent);
		}
		return false;
	}
}
