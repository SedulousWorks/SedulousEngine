using System;

namespace Sedulous.Graphics;

/// The shared command line backend scan.
///
/// ONE implementation for every executable, samples, sandboxes and tools alike, so a
/// built binary can be pointed at whichever backend a machine has rather than needing a
/// build per backend. Anything unrecognised passes through untouched: this owns no
/// arguments but its own.
static class BackendSelection
{
	public static BackendType FromArguments(String[] args, BackendType fallback = .Vulkan)
	{
		if (args == null)
			return fallback;

		for (let argument in args)
		{
			switch (argument)
			{
			case "--vulkan", "--vk": return .Vulkan;
			case "--dx12", "--d3d12": return .DX12;
			case "--webgpu", "--wgpu": return .WebGPU;
			case "--null-gpu": return .Null;
			default:
			}
		}
		return fallback;
	}
}
