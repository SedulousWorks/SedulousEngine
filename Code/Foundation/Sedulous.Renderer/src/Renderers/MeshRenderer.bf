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

	// Per-category cache state. MeshRenderer handles three categories (Opaque,
	// Masked, Transparent), and each pass (depth, forward) renders all of them
	// in turn. The cache must be per-category - otherwise category 2's fill
	// identity matches category 1's (same view, same frame, same buffer) and
	// category 2's draws use the cached groups/offsets from category 1.
	//
	// Keyed on the per-category batch list pointer from ExtractedRenderData
	// (which is stable across frames per (view, category) pair, since
	// ExtractedRenderData.mCategories is allocated once per view and never
	// re-allocated).
	//
	// Each CategoryCache has its own two-level identity:
	// 1. Group structure (GroupCache + Groups + EntityToGroup): keyed on
	//    scene.Revision. Survives across frames when the scene is structurally
	//    unchanged.
	// 2. Per-frame fill (InstanceData + Offsets): keyed on (view.FrameIndex,
	//    frame.InstanceBuffer ptr). Refills every frame; second pass within
	//    a frame (e.g. forward after depth on the same category) hits cache.
	private class CategoryCache
	{
		public Dictionary<BatchKey, int32> GroupCache = new .() ~ delete _;
		public List<BatchGroup> Groups = new .() ~ delete _;
		public List<InstanceData> InstanceData = new .() ~ delete _;
		public List<DataOffsets> Offsets = new .() ~ delete _;
		public List<DataOffsets> RebaseScratch = new .() ~ delete _;
		public List<int32> GroupFillCounters = new .() ~ delete _;
		/// Per-call annotation: entries[i] -> group index. Populated as a side
		/// effect of the count walk's BatchKey hash; consumed by the placement
		/// walk to skip the second hash. Sentinel -1 = entry was skipped
		/// (e.g. null gpuMesh). Resized per call to entries.Count, so this is
		/// not cross-call state - safe with multi-submesh entities since each
		/// entry position is unique within a single call.
		public List<int32> EntryToGroup = new .() ~ delete _;
		public uint64 SceneRevision = uint64.MaxValue;
		public int FillIdentity = 0;
		public Dictionary<int, int32> InstancesUploadOffsets = new .() ~ delete _;
		public Dictionary<int, int32> OffsetsUploadOffsets = new .() ~ delete _;
	}

	private Dictionary<int, CategoryCache> mCategoryCaches = new .() ~ DeleteDictionaryAndValues!(_);

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

		// Instanced static mesh rendering (works for any pipeline with instance buffer).
		// Pass the original batch list pointer through so the renderer can key its
		// per-category cache state on it (stable across frames per (view, category)).
		if (staticEntries.Count > 0 && frame.InstanceBuffer != null)
			RenderStaticInstanced(encoder, staticEntries, batch, renderContext, pipeline, frame, view, flags, passConfig);

		// Individual skinned mesh rendering
		if (skinnedEntries.Count > 0)
			RenderSkinnedIndividual(encoder, skinnedEntries, renderContext, pipeline, frame, view, flags, passConfig);
	}

	/// Per-category two-level cache, keyed on the batch list pointer (stable
	/// across frames per (view, category)):
	///   1. Group structure (state.GroupCache + state.Groups + state.EntityToGroup):
	///      keyed on view.SceneRevision. Built by hashing BatchKeys + populating
	///      entity->group annotations. Survives across frames when the scene is
	///      structurally unchanged.
	///   2. Per-frame fill (state.InstanceData + state.Offsets): keyed on
	///      (view.FrameIndex, frame.InstanceBuffer ptr). Recomputed using the
	///      annotation map - no BatchKey hashing per entry on stable frames.
	///
	/// The shader fetches `Instances[input.DataOffsets.x]` per vertex; DataOffsets
	/// arrives as a per-instance vertex attribute via slot 1.
	private void RenderStaticInstanced(
		IRenderPassEncoder encoder,
		List<MeshRenderData> entries,
		List<RenderData> batch,
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
		let pipelineCache = renderContext.PipelineStateCache;
		let bindMaterial = flags.HasFlag(.BindMaterial);

		// Per-category cache lookup. batch is the ExtractedRenderData per-category
		// list, stable across frames for the same (view, category).
		let cacheKey = (int)Internal.UnsafeCastToPtr(batch);
		CategoryCache state;
		if (!mCategoryCaches.TryGetValue(cacheKey, out state))
		{
			state = new CategoryCache();
			mCategoryCaches[cacheKey] = state;
		}

		let sceneRev = view.SceneRevision;
		let fillIdentity = view.FrameIndex ^ (int)Internal.UnsafeCastToPtr(frame.InstanceBuffer);

		// Two-attempt loop guards against stale group cache (false-positive
		// identity hit). Attempt 1: trust the cache. If an entry's BatchKey
		// isn't in the cache, invalidate and retry with a fresh build.
		for (int attempt = 0; attempt < 2; attempt++)
		{
			// Level 1: scene-structural rebuild - populate the BatchKey -> group
			// index map. Survives across frames when scene.Revision is stable.
			if (sceneRev != state.SceneRevision || state.Groups.Count == 0)
			{
				using (Profiler.Begin("Mesh.BuildBatchGroups"))
				{
					state.GroupCache.Clear();
					state.Groups.Clear();

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

						if (state.GroupCache.ContainsKey(key))
							continue;

						state.GroupCache[key] = (int32)state.Groups.Count;
						state.Groups.Add(.()
						{
							MeshHandle = mesh.MeshHandle,
							MaterialBindGroup = mesh.MaterialBindGroup,
							MaterialBindGroupLayout = mesh.MaterialBindGroupLayout,
							MaterialConfig = mesh.MaterialPipelineConfig,
							SubMeshIndex = mesh.SubMeshIndex,
							InstanceStart = 0,
							InstanceCount = 0
						});
					}
				}

				state.SceneRevision = sceneRev;
				// Group structure changed - any cached fill+upload state is stale.
				state.FillIdentity = 0;
				state.InstancesUploadOffsets.Clear();
				state.OffsetsUploadOffsets.Clear();
			}

			if (state.Groups.Count == 0) return;

			// Level 2: per-frame fill (counts + InstanceStart + offsets + InstanceData).
			// The count walk hashes BatchKey per entry and stores the resulting
			// group index in state.EntryToGroup[i] as a side effect. The placement
			// walk reads the annotation back, skipping the second hash.
			// Annotation is per-call (size = entries.Count, repopulated each call),
			// so it's safe for multi-submesh entities - each entry position is
			// unique within a single call.
			if (fillIdentity != state.FillIdentity)
			{
				bool needRebuild = false;
				using (Profiler.Begin("Mesh.BuildInstanceOffsets"))
				{
					// Reset per-group counts; recount per frame because culling
					// can change which entities are visible.
					for (int32 g = 0; g < state.Groups.Count; g++)
					{
						var group = state.Groups[g];
						group.InstanceCount = 0;
						state.Groups[g] = group;
					}

					// Count walk. Annotate mEntryToGroup[i] as a side effect so
					// the placement walk can skip the BatchKey hash.
					state.EntryToGroup.Count = entries.Count;
					for (int i = 0; i < entries.Count; i++)
					{
						let mesh = entries[i];
						let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
						if (gpuMesh == null)
						{
							state.EntryToGroup[i] = -1;
							continue;
						}

						let key = BatchKey()
						{
							MeshIndex = mesh.MeshHandle.Index,
							MaterialPtr = (int)Internal.UnsafeCastToPtr(mesh.MaterialBindGroup),
							SubMeshIndex = mesh.SubMeshIndex
						};

						if (!state.GroupCache.TryGetValue(key, let groupIdx))
						{
							needRebuild = true;
							break;
						}
						state.EntryToGroup[i] = groupIdx;
						var group = state.Groups[groupIdx];
						group.InstanceCount++;
						state.Groups[groupIdx] = group;
					}

					if (needRebuild)
					{
						// Stale group cache (false-positive identity hit). Invalidate
						// and retry on next attempt with a full rebuild.
						state.SceneRevision = uint64.MaxValue;
						state.Groups.Clear();
					}
					else
					{
						// Compute contiguous InstanceStart offsets
						int32 offset = 0;
						for (int32 g = 0; g < state.Groups.Count; g++)
						{
							var group = state.Groups[g];
							group.InstanceStart = offset;
							offset += group.InstanceCount;
							state.Groups[g] = group;
						}
						state.Offsets.Count = offset;

						// Reset fill counters for the placement walk.
						state.GroupFillCounters.Count = state.Groups.Count;
						for (int g = 0; g < state.GroupFillCounters.Count; g++)
							state.GroupFillCounters[g] = 0;

						// Placement walk: use the annotations from the count walk to
						// skip the BatchKey hash. Writes offsets + InstanceData together.
						state.InstanceData.Count = entries.Count;
						for (int i = 0; i < entries.Count; i++)
						{
							let groupIdx = state.EntryToGroup[i];
							if (groupIdx < 0) continue;  // skipped (null gpuMesh)

							let mesh = entries[i];
							var group = state.Groups[groupIdx];
							let slot = group.InstanceStart + state.GroupFillCounters[groupIdx];
							state.GroupFillCounters[groupIdx]++;

							state.Offsets[slot] = .() { X = (uint32)i, Y = 0, Z = 0, W = 0 };
							state.InstanceData[i] = .()
							{
								WorldMatrix = mesh.WorldMatrix,
								PrevWorldMatrix = mesh.PrevWorldMatrix,
								InstanceColor = mesh.InstanceColor
							};
						}
					}
				}

				if (needRebuild)
					continue;  // retry from the top of the attempt loop

				// Per-frame fill done - upload offsets cleared since the data changed.
				state.InstancesUploadOffsets.Clear();
				state.OffsetsUploadOffsets.Clear();
				state.FillIdentity = fillIdentity;
			}

			break;  // success
		}

		if (state.Groups.Count == 0 || state.Offsets.Count == 0) return;

		// Upload (once per (frame.InstanceBuffer, frame.InstanceOffsetsBuffer) pair).
		// If both buffers already have this frame's data, reuse the offsets.
		let instanceBufKey = (int)Internal.UnsafeCastToPtr(frame.InstanceBuffer);
		let offsetsBufKey = (int)Internal.UnsafeCastToPtr(frame.InstanceOffsetsBuffer);
		int32 startInstance;
		int32 startOffsets;

		if (state.InstancesUploadOffsets.TryGetValue(instanceBufKey, let cachedInst) &&
			state.OffsetsUploadOffsets.TryGetValue(offsetsBufKey, let cachedOff))
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

				let totalInstances = (int32)state.InstanceData.Count;
				let totalOffsets = (int32)state.Offsets.Count;

				if (startInstance + totalInstances > PerFrameResources.MaxInstances)
					return;
				if (startOffsets + totalOffsets > PerFrameResources.MaxInstances)
					return;

				// Upload InstanceData verbatim - indices are entry-relative (0..N-1)
				// and we'll rebase the offsets buffer below to point at the absolute slot.
				let instByteOff = (uint64)(startInstance * PerFrameResources.InstanceStride);
				TransferHelper.WriteMappedBuffer(
					frame.InstanceBuffer, instByteOff,
					Span<uint8>((uint8*)state.InstanceData.Ptr, totalInstances * PerFrameResources.InstanceStride));
				frame.InstanceOffset += totalInstances;
				state.InstancesUploadOffsets[instanceBufKey] = startInstance;

				// Rebase offsets and upload. Each cached uint4 holds a local entry index;
				// the GPU needs (startInstance + i) so its shader fetch lands in the
				// right Instances[] slot.
				state.RebaseScratch.Count = totalOffsets;
				for (int slot = 0; slot < totalOffsets; slot++)
				{
					let local = state.Offsets[slot];
					state.RebaseScratch[slot] = .() { X = (uint32)startInstance + local.X, Y = local.Y, Z = local.Z, W = local.W };
				}
				let offsetsByteOff = (uint64)(startOffsets * PerFrameResources.DataOffsetsStride);
				TransferHelper.WriteMappedBuffer(
					frame.InstanceOffsetsBuffer, offsetsByteOff,
					Span<uint8>((uint8*)state.RebaseScratch.Ptr, totalOffsets * PerFrameResources.DataOffsetsStride));
				frame.InstanceOffsetsCount += totalOffsets;
				state.OffsetsUploadOffsets[offsetsBufKey] = startOffsets;
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
			for (let group in state.Groups)
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

				let pipelineResult = pipelineCache.GetPipeline(config, vertexBuffers, group.MaterialBindGroupLayout, colorFormat, depthFormat);
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
