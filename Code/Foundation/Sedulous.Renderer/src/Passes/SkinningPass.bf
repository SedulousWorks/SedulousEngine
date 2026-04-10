namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Profiler;

/// Compute skinning pass — transforms skinned vertices into standard Mesh layout.
/// Runs before all render passes. Dispatches one compute job per visible skinned mesh.
/// Output buffers are reused by DepthPrepass, ForwardOpaquePass, etc.
class SkinningPass : PipelinePass
{
	public override StringView Name => "Skinning";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		let renderer = pipeline.RenderContext;
		if (renderer.SkinningSystem == null)
			return;

		// Check if any skinned meshes exist
		bool hasSkinnedMeshes = HasSkinnedInCategory(data, RenderCategories.Opaque)
			|| HasSkinnedInCategory(data, RenderCategories.Masked)
			|| HasSkinnedInCategory(data, RenderCategories.Transparent);

		if (!hasSkinnedMeshes)
			return;

		graph.AddComputePass("GPUSkinning", scope (builder) => {
			builder
				.NeverCull()
				.SetComputeExecute(new [=] (encoder) => {
					ExecuteSkinning(encoder, view, pipeline);
				});
		});
	}

	private void ExecuteSkinning(IComputePassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		using (Profiler.Begin("GPUSkinning"))
		{
		let renderer = pipeline.RenderContext;
		let data = view.RenderData;

		DispatchCategory(encoder, data, RenderCategories.Opaque, renderer);
		DispatchCategory(encoder, data, RenderCategories.Masked, renderer);
		DispatchCategory(encoder, data, RenderCategories.Transparent, renderer);
		}
	}

	private void DispatchCategory(IComputePassEncoder encoder, ExtractedRenderData data,
		RenderDataCategory category, RenderContext renderContext)
	{
		let skinningSystem = renderContext.SkinningSystem;
		let gpuResources = renderContext.GPUResources;
		let batch = data.GetBatch(category);
		if (batch == null) return;

		for (let entry in batch)
		{
			let mesh = entry as MeshRenderData;
			if (mesh == null || !mesh.IsSkinned) continue;

			let boneBuffer = gpuResources.GetBoneBuffer(mesh.BoneBufferHandle);
			if (boneBuffer == null) continue;

			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let key = SkinningKey()
			{
				MeshHandle = mesh.MeshHandle,
				EntityId = mesh.MaterialKey
			};

			let instance = skinningSystem.GetOrCreateInstance(
				key, gpuMesh.VertexBuffer, mesh.BoneBufferHandle,
				(int32)gpuMesh.VertexCount, boneBuffer.BoneCount);

			skinningSystem.DispatchSkinning(encoder, instance, boneBuffer.Buffer);
		}
	}

	private static bool HasSkinnedInCategory(ExtractedRenderData data, RenderDataCategory category)
	{
		let batch = data.GetBatch(category);
		if (batch == null) return false;
		for (let entry in batch)
		{
			if (let mesh = entry as MeshRenderData)
			{
				if (mesh.IsSkinned)
					return true;
			}
		}
		return false;
	}
}
