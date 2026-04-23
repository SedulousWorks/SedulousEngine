namespace Sedulous.Renderer.Renderers;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Shaders;

/// Renders MeshRenderData entries: static and skinned meshes.
/// Participates in the Opaque, Masked, and Transparent categories.
///
/// Static meshes sharing the same GPU mesh + material are batched into
/// instanced draws using a StructuredBuffer<InstanceData> at set 3.
/// Skinned meshes are drawn individually (unique bone matrices per entity).
public class MeshRenderer : Renderer
{
	private RenderDataCategory[3] mCategories;

	/// Per-instance data written to the StructuredBuffer.
	/// Must match the InstanceData struct in forward.vert.hlsl.
	[CRepr]
	private struct InstanceData
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
	}

	/// Key for grouping meshes by (GPUMesh + Material + SubMesh).
	private struct BatchKey : IHashable
	{
		public uint32 MeshIndex;
		public int MaterialPtr;
		public uint32 SubMeshIndex;

		public int GetHashCode()
		{
			var hash = (int)MeshIndex;
			hash = hash * 397 ^ MaterialPtr;
			hash = hash * 397 ^ (int)SubMeshIndex;
			return hash;
		}

		public static bool operator==(Self a, Self b) =>
			a.MeshIndex == b.MeshIndex && a.MaterialPtr == b.MaterialPtr && a.SubMeshIndex == b.SubMeshIndex;
	}

	/// Info for one batch group.
	private struct BatchGroup
	{
		public GPUMeshHandle MeshHandle;
		public IBindGroup MaterialBindGroup;
		public uint32 SubMeshIndex;
		public int32 InstanceStart;
		public int32 InstanceCount;
	}

	// Per-frame batch caches - built once on first use, reused across passes.
	// Two caches: material-aware (forward passes group by mesh+material+submesh)
	// and material-agnostic (depth/shadow passes group by mesh+submesh only,
	// collapsing unique materials into single instanced draws).

	// Material-aware cache (forward opaque, forward transparent)
	private Dictionary<BatchKey, int32> mMatGroupCache = new .() ~ delete _;
	private List<BatchGroup> mMatCachedGroups = new .() ~ delete _;
	private List<InstanceData> mMatCachedInstanceData = new .() ~ delete _;
	private int mMatCachedBatchIdentity = 0;
	private Dictionary<int, int32> mMatUploadOffsets = new .() ~ delete _;

	// Material-agnostic cache (depth prepass, shadow passes)
	private Dictionary<BatchKey, int32> mNoMatGroupCache = new .() ~ delete _;
	private List<BatchGroup> mNoMatCachedGroups = new .() ~ delete _;
	private List<InstanceData> mNoMatCachedInstanceData = new .() ~ delete _;
	private int mNoMatCachedBatchIdentity = 0;
	private Dictionary<int, int32> mNoMatUploadOffsets = new .() ~ delete _;

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
		RenderBatchFlags flags,
		PipelineConfig passConfig)
	{
		if (batch == null || batch.Count == 0)
			return;

		// Separate skinned meshes (individual draws) from static meshes (batched)
		let skinnedEntries = scope List<MeshRenderData>();
		let staticEntries = scope List<MeshRenderData>();

		for (let entry in batch)
		{
			let mesh = entry as MeshRenderData;
			if (mesh == null) continue;

			if (mesh.IsSkinned)
				skinnedEntries.Add(mesh);
			else
				staticEntries.Add(mesh);
		}

		// Instanced static mesh rendering (works for any pipeline with instance buffer)
		if (staticEntries.Count > 0 && frame.InstanceBuffer != null)
			RenderStaticInstanced(encoder, staticEntries, renderContext, pipeline, frame, view, flags, passConfig);

		// Individual skinned mesh rendering
		if (skinnedEntries.Count > 0)
			RenderSkinnedIndividual(encoder, skinnedEntries, renderContext, pipeline, frame, view, flags, passConfig);
	}

	/// Groups static mesh entries by (mesh + material + submesh), packs instance data,
	/// and issues one DrawIndexedInstanced per group.
	/// Batch groups are cached per frame - the first call builds them, subsequent
	/// calls (depth prepass, forward, shadow views) reuse the cached grouping and
	/// only re-upload instance data to the current pipeline's buffer.
	private void RenderStaticInstanced(
		IRenderPassEncoder encoder,
		List<MeshRenderData> entries,
		RenderContext renderContext,
		IRenderingPipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags,
		PipelineConfig passConfig)
	{
		let gpuResources = renderContext.GPUResources;
		let cache = renderContext.PipelineStateCache;
		let bindMaterial = flags.HasFlag(.BindMaterial);

		// Select cache set based on whether materials matter for grouping.
		// Depth/shadow passes don't bind materials, so all meshes sharing the same
		// geometry collapse into one instanced draw regardless of material.
		// Forward passes need material-aware grouping for correct bind group switches.
		Dictionary<BatchKey, int32> groupCache;
		List<BatchGroup> cachedGroups;
		List<InstanceData> cachedInstanceData;
		Dictionary<int, int32> uploadOffsets;

		if (bindMaterial)
		{
			groupCache = mMatGroupCache;
			cachedGroups = mMatCachedGroups;
			cachedInstanceData = mMatCachedInstanceData;
			uploadOffsets = mMatUploadOffsets;
		}
		else
		{
			groupCache = mNoMatGroupCache;
			cachedGroups = mNoMatCachedGroups;
			cachedInstanceData = mNoMatCachedInstanceData;
			uploadOffsets = mNoMatUploadOffsets;
		}

		// Check if we can reuse cached batch groups. Identity is based on the
		// first entry's address + count - same entries from the same extraction
		// produce the same identity across all passes and shadow views.
		let batchIdentity = (entries.Count > 0)
			? ((int)Internal.UnsafeCastToPtr(entries[0]) * 397 ^ entries.Count)
			: 0;

		let cachedIdentity = bindMaterial ? mMatCachedBatchIdentity : mNoMatCachedBatchIdentity;

		if (batchIdentity != cachedIdentity || cachedGroups.Count == 0)
		{
			// Cache miss - rebuild batch groups.
			// Pass 1: count instances per group to determine grouping structure.
			groupCache.Clear();
			cachedGroups.Clear();
			cachedInstanceData.Clear();

			for (let mesh in entries)
			{
				let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
				if (gpuMesh == null) continue;

				let key = BatchKey()
				{
					MeshIndex = mesh.MeshHandle.Index,
					MaterialPtr = bindMaterial ? (int)Internal.UnsafeCastToPtr(mesh.MaterialBindGroup) : 0,
					SubMeshIndex = mesh.SubMeshIndex
				};

				if (groupCache.TryGetValue(key, let groupIdx))
				{
					var group = cachedGroups[groupIdx];
					group.InstanceCount++;
					cachedGroups[groupIdx] = group;
				}
				else
				{
					groupCache[key] = (int32)cachedGroups.Count;
					cachedGroups.Add(.()
					{
						MeshHandle = mesh.MeshHandle,
						MaterialBindGroup = mesh.MaterialBindGroup,
						SubMeshIndex = mesh.SubMeshIndex,
						InstanceStart = 0,
						InstanceCount = 1
					});
				}
			}

			// Compute contiguous InstanceStart offsets from the counts
			int32 offset = 0;
			for (int32 g = 0; g < cachedGroups.Count; g++)
			{
				var group = cachedGroups[g];
				group.InstanceStart = offset;
				offset += group.InstanceCount;
				cachedGroups[g] = group;
			}

			cachedInstanceData.Count = offset;

			if (bindMaterial)
				mMatCachedBatchIdentity = batchIdentity;
			else
				mNoMatCachedBatchIdentity = batchIdentity;
		}

		// Always re-fill instance data with current world matrices.
		// Grouping structure is cached but transforms change every frame.
		{
			// Reset instance counts for filling
			for (int32 g = 0; g < cachedGroups.Count; g++)
			{
				var group = cachedGroups[g];
				group.InstanceCount = 0;
				cachedGroups[g] = group;
			}

			for (let mesh in entries)
			{
				let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
				if (gpuMesh == null) continue;

				let key = BatchKey()
				{
					MeshIndex = mesh.MeshHandle.Index,
					MaterialPtr = bindMaterial ? (int)Internal.UnsafeCastToPtr(mesh.MaterialBindGroup) : 0,
					SubMeshIndex = mesh.SubMeshIndex
				};

				if (!groupCache.TryGetValue(key, let groupIdx))
					continue;

				var group = cachedGroups[groupIdx];
				let slot = group.InstanceStart + group.InstanceCount;
				group.InstanceCount++;
				cachedGroups[groupIdx] = group;

				cachedInstanceData[slot] = .()
				{
					WorldMatrix = mesh.WorldMatrix,
					PrevWorldMatrix = mesh.PrevWorldMatrix
				};
			}

			// Force re-upload since matrices changed
			uploadOffsets.Clear();
		}

		if (cachedGroups.Count == 0) return;

		// Reuse previous upload if this buffer already has the cached data.
		// Each pipeline (main, shadow) has its own instance buffer - upload once
		// per buffer, then all passes sharing that buffer reuse the same offset.
		let bufferKey = (int)Internal.UnsafeCastToPtr(frame.InstanceBuffer);
		int32 startOffset;

		if (uploadOffsets.TryGetValue(bufferKey, let cachedOffset))
		{
			startOffset = cachedOffset;
		}
		else
		{
			startOffset = frame.InstanceOffset;
			let totalInstances = (int32)cachedInstanceData.Count;

			if (startOffset + totalInstances > PerFrameResources.MaxInstances)
				return; // buffer full

			let byteOffset = (uint64)(startOffset * PerFrameResources.InstanceStride);
			TransferHelper.WriteMappedBuffer(
				frame.InstanceBuffer, byteOffset,
				Span<uint8>((uint8*)cachedInstanceData.Ptr, totalInstances * PerFrameResources.InstanceStride));

			frame.InstanceOffset += totalInstances;
			uploadOffsets[bufferKey] = startOffset;
		}

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		// Build instanced pipeline variant from the pass config.
		// The pass already provides the correct shader, blend, depth, and MRT state -
		// we just add the INSTANCED flag for StructuredBuffer reads.
		var config = passConfig;
		config.ShaderFlags |= .Instanced;

		let colorFormat = pipeline.OutputFormat;
		let depthFormat = config.DepthFormat;

		let instancedPipelineResult = cache.GetPipeline(config, vertexBuffers, null,
			colorFormat, depthFormat);
		if (instancedPipelineResult case .Err)
			return;

		encoder.SetPipeline(instancedPipelineResult.Value);

		pipeline.BindFrameGroup(encoder, frame);

		// Bind instance buffer at set 3
		if (frame.InstanceBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.InstanceBindGroup, default);

		// Bind shadow data if available
		let shadowSystem = renderContext.ShadowSystem;
		if (shadowSystem != null)
		{
			let shadowBg = shadowSystem.GetBindGroup(view.FrameIndex);
			if (shadowBg != null)
				encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg, default);
		}

		// Draw each group
		IBindGroup lastMaterialBg = null;

		for (let group in cachedGroups)
		{
			let gpuMesh = gpuResources.GetMesh(group.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[group.SubMeshIndex];

			// Bind material
			if (bindMaterial)
			{
				let materialBg = (group.MaterialBindGroup != null) ? group.MaterialBindGroup : renderContext.DefaultMaterialBindGroup;
				if (materialBg != null && materialBg != lastMaterialBg)
				{
					encoder.SetBindGroup(BindGroupFrequency.Material, materialBg, default);
					lastMaterialBg = materialBg;
				}
			}

			encoder.SetVertexBuffer(0, gpuMesh.VertexBuffer, 0);

			if (gpuMesh.IndexBuffer != null)
			{
				encoder.SetIndexBuffer(gpuMesh.IndexBuffer, gpuMesh.IndexFormat);
				encoder.DrawIndexed(
					subMesh.IndexCount,
					(uint32)group.InstanceCount,
					subMesh.IndexStart,
					subMesh.BaseVertex,
					(uint32)(startOffset + group.InstanceStart));
			}
			else
			{
				let vertCount = subMesh.IndexCount > 0 ? subMesh.IndexCount : gpuMesh.VertexCount;
				encoder.Draw(vertCount, (uint32)group.InstanceCount, 0, (uint32)(startOffset + group.InstanceStart));
			}
		}
	}

	/// Draws skinned meshes individually (each has unique bone matrices).
	/// Sets its own non-instanced pipeline because RenderStaticInstanced may
	/// have left the instanced pipeline active (incompatible layout at set 3).
	private void RenderSkinnedIndividual(
		IRenderPassEncoder encoder,
		List<MeshRenderData> entries,
		RenderContext renderContext,
		IRenderingPipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags,
		PipelineConfig passConfig)
	{
		let gpuResources = renderContext.GPUResources;
		let skinningSystem = renderContext.SkinningSystem;
		let cache = renderContext.PipelineStateCache;
		let bindMaterial = flags.HasFlag(.BindMaterial);

		// Set the non-instanced pipeline (DrawCall UBO at set 3).
		// RenderStaticInstanced may have left the instanced pipeline active,
		// which uses StorageBuffer at set 3 - incompatible with DrawCallBindGroup.
		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let colorFormat = pipeline.OutputFormat;
		let depthFormat = passConfig.DepthFormat;

		let skinnedPipelineResult = cache.GetPipeline(passConfig, vertexBuffers, null,
			colorFormat, depthFormat);
		if (skinnedPipelineResult case .Err)
			return;

		encoder.SetPipeline(skinnedPipelineResult.Value);

		pipeline.BindFrameGroup(encoder, frame);

		// Bind shadow data if available
		let shadowSystem = renderContext.ShadowSystem;
		if (shadowSystem != null)
		{
			let shadowBg = shadowSystem.GetBindGroup(view.FrameIndex);
			if (shadowBg != null)
				encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg, default);
		}

		IBindGroup lastMaterialBindGroup = null;

		for (let mesh in entries)
		{
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			// Object uniforms via dynamic offset (non-instanced path)
			let objOffset = pipeline.WriteObjectUniforms(view.FrameIndex, mesh.WorldMatrix, mesh.PrevWorldMatrix);
			if (objOffset == uint32.MaxValue) continue;

			uint32[1] dynamicOffsets = .(objOffset);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

			if (bindMaterial)
			{
				let materialBg = (mesh.MaterialBindGroup != null) ? mesh.MaterialBindGroup : renderContext.DefaultMaterialBindGroup;
				if (materialBg != null && materialBg != lastMaterialBindGroup)
				{
					encoder.SetBindGroup(BindGroupFrequency.Material, materialBg, default);
					lastMaterialBindGroup = materialBg;
				}
			}

			// Use compute-skinned vertex buffer if available, otherwise skip
			// skinned meshes that haven't been processed yet (wrong vertex format).
			IBuffer vertexBuffer = gpuMesh.VertexBuffer;
			if (mesh.IsSkinned && skinningSystem != null)
			{
				let key = SkinningKey() { MeshHandle = mesh.MeshHandle, EntityId = mesh.MaterialKey };
				let skinnedVB = skinningSystem.GetSkinnedVertexBuffer(key);
				if (skinnedVB != null)
					vertexBuffer = skinnedVB;
				else
					continue;
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
