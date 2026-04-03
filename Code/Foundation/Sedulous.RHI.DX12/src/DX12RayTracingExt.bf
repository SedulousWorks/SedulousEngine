namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IRayTracingExt.
class DX12RayTracingExt : IRayTracingExt
{
	private DX12Device mDevice;

	// DXR shader identifiers are always 32 bytes (D3D12_SHADER_IDENTIFIER_SIZE_IN_BYTES)
	public uint32 ShaderGroupHandleSize => 32;
	// D3D12_RAYTRACING_SHADER_RECORD_BYTE_ALIGNMENT
	public uint32 ShaderGroupHandleAlignment => 32;
	// D3D12_RAYTRACING_SHADER_TABLE_BYTE_ALIGNMENT
	public uint32 ShaderGroupBaseAlignment => 64;

	public this(DX12Device device)
	{
		mDevice = device;
	}

	public Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc)
	{
		// Use a default size — same approach as Vulkan backend.
		// A more complete implementation would expose GetAccelStructBuildSizes().
		uint64 defaultSize = 256 * 1024;

		let accelStruct = new DX12AccelStruct();
		if (accelStruct.Init(mDevice, desc, defaultSize) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12RayTracingExt: acceleration structure Init failed");
			delete accelStruct;
			return .Err;
		}
		return .Ok(accelStruct);
	}

	public void DestroyAccelStruct(ref IAccelStruct accelStruct)
	{
		if (let dx = accelStruct as DX12AccelStruct)
		{
			dx.Cleanup(mDevice);
			delete dx;
		}
		accelStruct = null;
	}

	public Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc)
	{
		let pipeline = new DX12RayTracingPipeline();
		if (pipeline.Init(mDevice, desc) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12RayTracingExt: ray tracing pipeline Init failed");
			delete pipeline;
			return .Err;
		}
		return .Ok(pipeline);
	}

	public void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline)
	{
		if (let dx = pipeline as DX12RayTracingPipeline)
		{
			dx.Cleanup(mDevice);
			delete dx;
		}
		pipeline = null;
	}

	public Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline,
		uint32 firstGroup, uint32 groupCount, Span<uint8> outData)
	{
		let dxPipeline = pipeline as DX12RayTracingPipeline;
		if (dxPipeline == null || dxPipeline.Properties == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12RayTracingExt: pipeline or properties is null");
			return .Err;
		}

		uint32 handleSize = ShaderGroupHandleSize; // 32 bytes
		if ((int)outData.Length < (int)(groupCount * handleSize))
		{
			System.Diagnostics.Debug.WriteLine("DX12RayTracingExt: output buffer too small for shader group handles");
			return .Err;
		}

		for (uint32 i = 0; i < groupCount; i++)
		{
			uint32 groupIdx = firstGroup + i;
			if ((int)groupIdx >= dxPipeline.GroupExportNames.Count)
			{
				System.Diagnostics.Debug.WriteLine("DX12RayTracingExt: shader group index out of range");
				return .Err;
			}

			let exportName = dxPipeline.GroupExportNames[(int)groupIdx];
			let wideName = scope String(exportName).ToScopedNativeWChar!();
			void* identifier = dxPipeline.Properties.GetShaderIdentifier(wideName);
			if (identifier == null)
			{
				System.Diagnostics.Debug.WriteLine("DX12RayTracingExt: GetShaderIdentifier returned null");
				return .Err;
			}

			Internal.MemCpy(&outData[(int)(i * handleSize)], identifier, (int)handleSize);
		}

		return .Ok;
	}
}
