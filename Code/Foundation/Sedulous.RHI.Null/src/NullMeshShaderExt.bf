namespace Sedulous.RHI.Null;

using System;

class NullMeshShaderExt : IMeshShaderExt
{
	public Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc)
	{
		return .Ok(new NullMeshPipeline(desc.Layout));
	}

	public void DestroyMeshPipeline(ref IMeshPipeline pipeline)
	{
		delete pipeline;
		pipeline = null;
	}
}

class NullMeshPipeline : IMeshPipeline
{
	private IPipelineLayout mLayout;
	public this(IPipelineLayout layout) { mLayout = layout; }
	public IPipelineLayout Layout => mLayout;
}
