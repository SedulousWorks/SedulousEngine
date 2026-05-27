namespace Sedulous.Renderer.Renderers;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Shaders;
using Sedulous.Profiler;

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
	/// Layout: 2 matrices (128 bytes) + Vector4 InstanceColor (16 bytes) = 144.
	[CRepr]
	private struct InstanceData
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public Vector4 InstanceColor;
	}

	/// Per-instance DataOffsets vertex attribute (uint4). Delivered to the
	/// vertex shader as TEXCOORD5 in the instanced path. .x = entity index into
	/// Instances[]; .y/.z/.w reserved for future per-instance buffers.
	[CRepr]
	private struct DataOffsets
	{
		public uint32 X, Y, Z, W;
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
		public IBindGroupLayout MaterialBindGroupLayout;
		public PipelineConfig MaterialConfig;
		public uint32 SubMeshIndex;
		public int32 InstanceStart;
		public int32 InstanceCount;
	}

	// Per-frame batch cache. Material-aware grouping is used for ALL passes —
	// depth/shadow paths just skip the material bind group binding. Both passes
	// within a view (e.g. DepthPrepass + ForwardOpaque) hit the same identity
	// → second pass runs only RecordDraws.
	private Dictionary<BatchKey, int32> mGroupCache = new .() ~ delete _;
	private List<BatchGroup> mCachedGroups = new .() ~ delete _;
	// Per-frame instance data, indexed by entry index (extraction order). Stable
	// across a frame; uploaded once per (PerFrameResources.InstanceBuffer) pointer.
	private List<InstanceData> mCachedInstanceData = new .() ~ delete _;
	// Per-frame DataOffsets in group-major order. Holds LOCAL entry indices
	// (0..N-1); rebased to absolute Instances[] slot at upload time.
	private List<DataOffsets> mCachedOffsets = new .() ~ delete _;
	// Scratch buffer used when rebasing offsets for upload. Reused across calls.
	private List<DataOffsets> mRebaseScratch = new .() ~ delete _;
	// Parallel list of per-group fill counters, used during BuildInstanceOffsets
	// to write each entry into its group's next free slot.
	private List<int32> mGroupFillCounters = new .() ~ delete _;
	private int mCachedBatchIdentity = 0;
	// Per-buffer-pointer cache of "this buffer already has the current frame's
	// data uploaded — start at this offset." Cleared whenever batch identity changes.
	private Dictionary<int, int32> mInstancesUploadOffsets = new .() ~ delete _;
	private Dictionary<int, int32> mOffsetsUploadOffsets = new .() ~ delete _;

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

	/// Groups static mesh entries by (mesh + material + submesh), packs instance
	/// data into a per-frame StructuredBuffer indexed by entry order, and emits
	/// per-instance DataOffsets via a second vertex buffer. The shader fetches
	/// `Instances[input.DataOffsets.x]` per vertex.
	///
	/// Cache is keyed on (entries[0] ptr, count, frame.InstanceBuffer ptr) — so
	/// DepthPrepass and ForwardOpaque within the same view hit the same cache
	/// and the second pass runs only RecordDraws. Material-aware grouping is
	/// used for ALL passes (depth/shadow simply skip the material bind group
	/// binding via the `bindMaterial` flag).
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
		if (entries.Count == 0 || frame.InstanceBuffer == null || frame.InstanceOffsetsBuffer == null)
			return;

		let gpuResources = renderContext.GPUResources;
		let cache = renderContext.PipelineStateCache;
		let bindMaterial = flags.HasFlag(.BindMaterial);

		// Identity includes the instance buffer pointer so different views (with
		// different PerFrameResources) never collide. Same view's depth + forward
		// share the buffer and hit the cache.
		//
		// entries[0]'s pointer is from the per-frame FrameAllocator and can
		// recycle across renders. The post-fill validation loop below catches
		// false-positive hits and forces a rebuild.
		let batchIdentity = ((int)Internal.UnsafeCastToPtr(entries[0]) * 397)
			^ entries.Count
			^ (int)Internal.UnsafeCastToPtr(frame.InstanceBuffer);

		bool rebuild = batchIdentity != mCachedBatchIdentity || mCachedGroups.Count == 0;

		// Up to two attempts: false-positive cache hit -> force rebuild on second pass.
		for (int attempt = 0; attempt < 2; attempt++)
		{
			if (rebuild)
			{
				using (Profiler.Begin("Mesh.BuildBatchGroups"))
				{
					mGroupCache.Clear();
					mCachedGroups.Clear();

					for (let mesh in entries)
					{
						let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
						if (gpuMesh == null) continue;

						let key = BatchKey()
						{
							MeshIndex = mesh.MeshHandle.Index,
							MaterialPtr = (int)Internal.UnsafeCastToPtr(mesh.MaterialBindGroup),
							SubMeshIndex = mesh.SubMeshIndex
						};

						if (mGroupCache.TryGetValue(key, let groupIdx))
						{
							var group = mCachedGroups[groupIdx];
							group.InstanceCount++;
							mCachedGroups[groupIdx] = group;
						}
						else
						{
							mGroupCache[key] = (int32)mCachedGroups.Count;
							mCachedGroups.Add(.()
							{
								MeshHandle = mesh.MeshHandle,
								MaterialBindGroup = mesh.MaterialBindGroup,
								MaterialBindGroupLayout = mesh.MaterialBindGroupLayout,
								MaterialConfig = mesh.MaterialPipelineConfig,
								SubMeshIndex = mesh.SubMeshIndex,
								InstanceStart = 0,
								InstanceCount = 1
							});
						}
					}

					// Compute contiguous InstanceStart offsets from the counts
					int32 offset = 0;
					for (int32 g = 0; g < mCachedGroups.Count; g++)
					{
						var group = mCachedGroups[g];
						group.InstanceStart = offset;
						offset += group.InstanceCount;
						mCachedGroups[g] = group;
					}
					mCachedOffsets.Count = offset;
				}

				using (Profiler.Begin("Mesh.FillInstanceData"))
				{
					// InstanceData is indexed by ENTRY index (extraction order) — stable
					// per-frame, shared across DepthPrepass and ForwardOpaque.
					mCachedInstanceData.Count = entries.Count;
					for (int i = 0; i < entries.Count; i++)
					{
						let mesh = entries[i];
						mCachedInstanceData[i] = .()
						{
							WorldMatrix = mesh.WorldMatrix,
							PrevWorldMatrix = mesh.PrevWorldMatrix,
							InstanceColor = mesh.InstanceColor
						};
					}
				}

				bool needsRebuild = false;
				using (Profiler.Begin("Mesh.BuildInstanceOffsets"))
				{
					// Per-group fill counters track where the next entry goes within
					// each group's contiguous offsets slice.
					mGroupFillCounters.Count = mCachedGroups.Count;
					for (int g = 0; g < mGroupFillCounters.Count; g++)
						mGroupFillCounters[g] = 0;

					for (int i = 0; i < entries.Count; i++)
					{
						let mesh = entries[i];
						let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
						if (gpuMesh == null) continue;

						let key = BatchKey()
						{
							MeshIndex = mesh.MeshHandle.Index,
							MaterialPtr = (int)Internal.UnsafeCastToPtr(mesh.MaterialBindGroup),
							SubMeshIndex = mesh.SubMeshIndex
						};

						if (!mGroupCache.TryGetValue(key, let groupIdx))
						{
							needsRebuild = true;
							break;
						}

						let group = mCachedGroups[groupIdx];
						let slot = group.InstanceStart + mGroupFillCounters[groupIdx];
						mGroupFillCounters[groupIdx]++;

						// Store LOCAL entry index; rebased to absolute Instances[] slot at upload.
						mCachedOffsets[slot] = .() { X = (uint32)i, Y = 0, Z = 0, W = 0 };
					}
				}

				if (!needsRebuild)
				{
					mCachedBatchIdentity = batchIdentity;
					// Cache rebuilt with new data; any previous upload offsets are stale.
					mInstancesUploadOffsets.Clear();
					mOffsetsUploadOffsets.Clear();
					break;
				}

				// Stale cache (false-positive identity match). Invalidate and retry.
				mCachedBatchIdentity = 0;
				mCachedGroups.Clear();
				continue;
			}
			else
			{
				break;
			}
		}

		if (mCachedGroups.Count == 0) return;

		// Upload (once per (frame.InstanceBuffer, frame.InstanceOffsetsBuffer) pair).
		// If both buffers already have this frame's data, reuse the offsets.
		let instanceBufKey = (int)Internal.UnsafeCastToPtr(frame.InstanceBuffer);
		let offsetsBufKey = (int)Internal.UnsafeCastToPtr(frame.InstanceOffsetsBuffer);
		int32 startInstance;
		int32 startOffsets;

		if (mInstancesUploadOffsets.TryGetValue(instanceBufKey, let cachedInst) &&
			mOffsetsUploadOffsets.TryGetValue(offsetsBufKey, let cachedOff))
		{
			startInstance = cachedInst;
			startOffsets = cachedOff;
		}
		else
		{
			using (Profiler.Begin("Mesh.UploadInstanceBuffer"))
			{
				startInstance = frame.InstanceOffset;
				startOffsets = frame.InstanceOffsetsCount;

				let totalInstances = (int32)mCachedInstanceData.Count;
				let totalOffsets = (int32)mCachedOffsets.Count;

				if (startInstance + totalInstances > PerFrameResources.MaxInstances)
					return;
				if (startOffsets + totalOffsets > PerFrameResources.MaxInstances)
					return;

				// Upload InstanceData verbatim — indices are entry-relative (0..N-1)
				// and we'll rebase the offsets buffer below to point at the absolute slot.
				let instByteOff = (uint64)(startInstance * PerFrameResources.InstanceStride);
				TransferHelper.WriteMappedBuffer(
					frame.InstanceBuffer, instByteOff,
					Span<uint8>((uint8*)mCachedInstanceData.Ptr, totalInstances * PerFrameResources.InstanceStride));
				frame.InstanceOffset += totalInstances;
				mInstancesUploadOffsets[instanceBufKey] = startInstance;

				// Rebase offsets and upload. Each cached uint4 holds a local entry index;
				// the GPU needs (startInstance + i) so its shader fetch lands in the
				// right Instances[] slot.
				mRebaseScratch.Count = totalOffsets;
				for (int slot = 0; slot < totalOffsets; slot++)
				{
					let local = mCachedOffsets[slot];
					mRebaseScratch[slot] = .() { X = (uint32)startInstance + local.X, Y = local.Y, Z = local.Z, W = local.W };
				}
				let offsetsByteOff = (uint64)(startOffsets * PerFrameResources.DataOffsetsStride);
				TransferHelper.WriteMappedBuffer(
					frame.InstanceOffsetsBuffer, offsetsByteOff,
					Span<uint8>((uint8*)mRebaseScratch.Ptr, totalOffsets * PerFrameResources.DataOffsetsStride));
				frame.InstanceOffsetsCount += totalOffsets;
				mOffsetsUploadOffsets[offsetsBufKey] = startOffsets;
			}
		}

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		let offsetsLayout = VertexLayoutHelper.CreateDataOffsetsBufferLayout();
		VertexBufferLayout[2] vertexBuffers = .(vertexLayout, offsetsLayout);

		let colorFormat = pipeline.OutputFormat;
		let depthFormat = passConfig.DepthFormat;
		let shadowSystem = renderContext.ShadowSystem;

		IBindGroup lastMaterialBg = null;
		IRenderPipeline currentPipeline = null;

		using (Profiler.Begin("Mesh.RecordDraws"))
		{
			for (let group in mCachedGroups)
			{
				let gpuMesh = gpuResources.GetMesh(group.MeshHandle);
				if (gpuMesh == null) continue;

				let subMesh = gpuMesh.SubMeshes[group.SubMeshIndex];

				var config = passConfig;
				config.ShaderFlags |= .Instanced;
				config.ShaderFlags |= group.MaterialConfig.ShaderFlags;
				config.CullMode = group.MaterialConfig.CullMode;
				config.BlendMode = group.MaterialConfig.BlendMode;
				config.FillMode = group.MaterialConfig.FillMode;
				config.FrontFace = group.MaterialConfig.FrontFace;
				if (!group.MaterialConfig.ShaderName.IsEmpty)
					config.ShaderName = group.MaterialConfig.ShaderName;

				let pipelineResult = cache.GetPipeline(config, vertexBuffers, group.MaterialBindGroupLayout, colorFormat, depthFormat);
				if (pipelineResult case .Err) continue;

				let groupPipeline = pipelineResult.Value;
				if (groupPipeline != currentPipeline)
				{
					encoder.SetPipeline(groupPipeline);
					currentPipeline = groupPipeline;

					pipeline.BindFrameGroup(encoder, frame);
					if (shadowSystem != null)
					{
						let shadowBg2 = shadowSystem.GetBindGroup(view.FrameIndex);
						if (shadowBg2 != null)
							encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg2, default);
					}
					// Rebind InstanceBindGroup after pipeline switch (layout change
					// invalidates set bindings).
					if (frame.InstanceBindGroup != null)
						encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.InstanceBindGroup, default);
					lastMaterialBg = null;
				}

				if (bindMaterial)
				{
					let materialBg = (group.MaterialBindGroup != null) ? group.MaterialBindGroup : renderContext.DefaultMaterialBindGroup;
					if (materialBg != null && materialBg != lastMaterialBg)
					{
						encoder.SetBindGroup(BindGroupFrequency.Material, materialBg, default);
						lastMaterialBg = materialBg;
					}
				}

				// Per-instance offsets vertex buffer slice for this group.
				let offsetsByteOff = (uint64)((startOffsets + group.InstanceStart) * PerFrameResources.DataOffsetsStride);
				encoder.SetVertexBuffer(0, gpuMesh.VertexBuffer, 0);
				encoder.SetVertexBuffer(1, frame.InstanceOffsetsBuffer, offsetsByteOff);

				if (gpuMesh.IndexBuffer != null)
				{
					encoder.SetIndexBuffer(gpuMesh.IndexBuffer, gpuMesh.IndexFormat);
					encoder.DrawIndexed(
						subMesh.IndexCount,
						(uint32)group.InstanceCount,
						subMesh.IndexStart,
						subMesh.BaseVertex,
						0);
				}
				else
				{
					let vertCount = subMesh.IndexCount > 0 ? subMesh.IndexCount : gpuMesh.VertexCount;
					encoder.Draw(vertCount, (uint32)group.InstanceCount, 0, 0);
				}
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

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let colorFormat = pipeline.OutputFormat;
		let depthFormat = passConfig.DepthFormat;

		// Bind shadow data if available
		let shadowSystem = renderContext.ShadowSystem;
		if (shadowSystem != null)
		{
			let shadowBg = shadowSystem.GetBindGroup(view.FrameIndex);
			if (shadowBg != null)
				encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg, default);
		}

		IBindGroup lastMaterialBindGroup = null;
		IRenderPipeline currentPipeline = null;

		for (let mesh in entries)
		{
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			// Start from pass config, overlay material-specific state
			var config = passConfig;
			config.ShaderFlags |= mesh.MaterialPipelineConfig.ShaderFlags;
			config.CullMode = mesh.MaterialPipelineConfig.CullMode;
			config.BlendMode = mesh.MaterialPipelineConfig.BlendMode;
			config.FillMode = mesh.MaterialPipelineConfig.FillMode;
			config.FrontFace = mesh.MaterialPipelineConfig.FrontFace;
			if (!mesh.MaterialPipelineConfig.ShaderName.IsEmpty)
				config.ShaderName = mesh.MaterialPipelineConfig.ShaderName;

			let pipelineResult = cache.GetPipeline(config, vertexBuffers, mesh.MaterialBindGroupLayout, colorFormat, depthFormat);
			if (pipelineResult case .Err) continue;

			let meshPipeline = pipelineResult.Value;
			if (meshPipeline != currentPipeline)
			{
				encoder.SetPipeline(meshPipeline);
				currentPipeline = meshPipeline;
				pipeline.BindFrameGroup(encoder, frame);
				if (shadowSystem != null)
				{
					let shadowBg2 = shadowSystem.GetBindGroup(view.FrameIndex);
					if (shadowBg2 != null)
						encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg2, default);
				}
				lastMaterialBindGroup = null;
			}

			// Object uniforms via dynamic offset (non-instanced path)
			let objOffset = pipeline.WriteObjectUniforms(view.FrameIndex, mesh.WorldMatrix, mesh.PrevWorldMatrix, mesh.InstanceColor);
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
