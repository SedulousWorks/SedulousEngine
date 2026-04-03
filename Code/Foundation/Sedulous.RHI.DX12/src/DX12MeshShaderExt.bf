namespace Sedulous.RHI.DX12;

using System;
using Sedulous.RHI;

/// DX12 implementation of IMeshShaderExt.
class DX12MeshShaderExt : IMeshShaderExt
{
	private DX12Device mDevice;

	public this(DX12Device device)
	{
		mDevice = device;
	}

	public Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc)
	{
		let pipeline = new DX12MeshPipeline();
		if (pipeline.Init(mDevice, desc) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12MeshShaderExt: mesh pipeline Init failed");
			delete pipeline;
			return .Err;
		}
		return .Ok(pipeline);
	}

	public void DestroyMeshPipeline(ref IMeshPipeline pipeline)
	{
		if (let dx = pipeline as DX12MeshPipeline)
		{
			dx.Cleanup(mDevice);
			delete dx;
		}
		pipeline = null;
	}
}
