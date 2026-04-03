namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IMeshShaderExt.
class VulkanMeshShaderExt : IMeshShaderExt
{
	private VulkanDevice mDevice;

	public this(VulkanDevice device)
	{
		mDevice = device;
	}

	public Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc)
	{
		let pipeline = new VulkanMeshPipeline();
		if (pipeline.Init(mDevice, desc) case .Err)
		{
			delete pipeline;
			return .Err;
		}
		return .Ok(pipeline);
	}

	public void DestroyMeshPipeline(ref IMeshPipeline pipeline)
	{
		if (let vk = pipeline as VulkanMeshPipeline)
		{
			vk.Cleanup(mDevice);
			delete vk;
		}
		pipeline = null;
	}
}
