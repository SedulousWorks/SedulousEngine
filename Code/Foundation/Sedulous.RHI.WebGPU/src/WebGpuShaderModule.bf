using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A compiled shader, ingested as either SPIR-V or WGSL.
///
/// Which one is decided by LOOKING at the code rather than by being told, because the
/// same descriptor carries both: the desktop DXC loop hands over SPIR-V, and the cook
/// time path hands over WGSL text, which is also all a browser will ever accept.
class WebGpuShaderModule : IShaderModule
{
	/// The SPIR-V magic number, first word of every module.
	private const uint32 cSpirvMagic = 0x07230203;

	private WGPUShaderModule mHandle;

	public WGPUShaderModule Handle => mHandle;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuShaderModuleRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, ShaderModuleDesc desc)
	{
		WGPUShaderModuleDescriptor module = .();
		module.label = WebGpuConversions.ToWgpuStringView(desc.Label);

		if (IsSpirv(desc.Code))
		{
			// A browser never ingests SPIR-V, so this fails rather than handing the
			// bytes over as if they were WGSL.
			if (!WebGpuApi.SpirvIngestion)
				return .Err;

			WGPUShaderSourceSPIRV spirv = .();
			spirv.chain.sType = .WGPUSType_ShaderSourceSPIRV;
			spirv.codeSize = (uint32)(desc.Code.Length / 4);
			spirv.code = (uint32*)desc.Code.Ptr;
			module.nextInChain = &spirv.chain;

			mHandle = wgpuDeviceCreateShaderModule(device, &module);
			return (mHandle != null) ? .Ok : .Err;
		}

		WGPUShaderSourceWGSL wgsl = .();
		wgsl.chain.sType = .WGPUSType_ShaderSourceWGSL;
		wgsl.code = .() { data = (char8*)desc.Code.Ptr, length = (uint)desc.Code.Length };
		module.nextInChain = &wgsl.chain;

		mHandle = wgpuDeviceCreateShaderModule(device, &module);
		return (mHandle != null) ? .Ok : .Err;
	}

	private static bool IsSpirv(Span<uint8> code)
	{
		if (code.Length < 4)
			return false;

		return *(uint32*)code.Ptr == cSpirvMagic;
	}
}
