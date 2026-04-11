namespace Sedulous.Renderer.Renderers;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Renderer;

/// Renders MeshRenderData entries: static and skinned meshes.
/// Participates in the Opaque, Masked, and Transparent categories.
///
/// Owns the consolidated draw loop previously duplicated across DepthPrepass,
/// ForwardOpaquePass, and ForwardTransparentPass. Per-pass differences are
/// conveyed via RenderBatchFlags:
///   - BindMaterial: forward passes bind material bind groups; depth prepass doesn't.
///
/// Skinned meshes automatically use the vertex buffer produced by SkinningSystem.
public class MeshRenderer : Renderer
{
	private RenderDataCategory[3] mCategories;

	public this()
	{
		mCategories = .(
			RenderCategories.Opaque,
			RenderCategories.Masked,
			RenderCategories.Transparent
		);
	}

	public override Span<RenderDataCategory> GetSupportedCategories()
	{
		return .(&mCategories[0], 3);
	}

	public override void RenderBatch(
		IRenderPassEncoder encoder,
		List<RenderData> batch,
		RenderContext renderContext,
		IRenderingPipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags)
	{
		if (batch == null || batch.Count == 0)
			return;

		let gpuResources = renderContext.GPUResources;
		let skinningSystem = renderContext.SkinningSystem;
		let bindMaterial = flags.HasFlag(.BindMaterial);
		IBindGroup lastMaterialBindGroup = null;

		for (let entry in batch)
		{
			let mesh = entry as MeshRenderData;
			if (mesh == null) continue;

			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			// Object uniforms (world + prev world matrices) via dynamic offset.
			let objOffset = pipeline.WriteObjectUniforms(view.FrameIndex, mesh.WorldMatrix, mesh.PrevWorldMatrix);
			if (objOffset == uint32.MaxValue) continue;

			uint32[1] dynamicOffsets = .(objOffset);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

			// Material bind group — forward passes only.
			if (bindMaterial)
			{
				let materialBg = (mesh.MaterialBindGroup != null) ? mesh.MaterialBindGroup : renderContext.DefaultMaterialBindGroup;
				if (materialBg != null && materialBg != lastMaterialBindGroup)
				{
					encoder.SetBindGroup(BindGroupFrequency.Material, materialBg, default);
					lastMaterialBindGroup = materialBg;
				}
			}

			// Vertex buffer: use compute-skinned output for skinned meshes.
			IBuffer vertexBuffer = gpuMesh.VertexBuffer;
			if (mesh.IsSkinned && skinningSystem != null)
			{
				let key = SkinningKey() { MeshHandle = mesh.MeshHandle, EntityId = mesh.MaterialKey };
				let skinnedVB = skinningSystem.GetSkinnedVertexBuffer(key);
				if (skinnedVB != null)
					vertexBuffer = skinnedVB;
			}

			encoder.SetVertexBuffer(0, vertexBuffer, 0);

			if (gpuMesh.IndexBuffer != null)
			{
				encoder.SetIndexBuffer(gpuMesh.IndexBuffer, gpuMesh.IndexFormat);
				encoder.DrawIndexed(subMesh.IndexCount, 1, subMesh.IndexStart, subMesh.BaseVertex, 0);
			}
			else
			{
				let vertCount = subMesh.IndexCount > 0 ? subMesh.IndexCount : gpuMesh.VertexCount;
				encoder.Draw(vertCount, 1, 0, 0);
			}
		}
	}
}
