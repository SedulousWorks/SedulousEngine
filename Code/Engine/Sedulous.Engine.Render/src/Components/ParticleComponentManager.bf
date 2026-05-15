namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Materials.Resources;
using Sedulous.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Core.Memory;
using Sedulous.RHI;
using Sedulous.Particles;
using Sedulous.Particles.Render;
using Sedulous.Particles.Resources;

/// Manages particle components: resolves effect and texture resources,
/// creates MaterialInstances, simulates particle effects, and extracts
/// ParticleBatchRenderData each frame.
class ParticleComponentManager : ComponentManager<ParticleComponent>, IRenderDataProvider
{
	/// Shared resource resolver (set by RenderSubsystem).
	public RenderResourceResolver Resolver { get; set; }

	/// Shared renderer context.
	public RenderContext RenderContext { get; set; }

	/// Per-system render data (reusable across frames to avoid reallocation).
	/// Keyed by (entity index << 16 | system index) to support multi-system effects.
	private Dictionary<int64, ParticleRenderState> mRenderStates = new .() ~ {
		for (let kv in _)
			delete kv.value;
		delete _;
	};

	/// Per-component resource resolution tracking.
	private Dictionary<EntityHandle, ParticleResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
		{
			kv.value.Release();
			delete kv.value;
		}
		delete _;
	};

	/// Last known camera position (from extraction, used for LOD during simulation).
	private Vector3 mCameraPosition;

	/// Cache: texture view -> shared MaterialInstance.
	private Dictionary<ObjectKey<ITextureView>, MaterialInstance> mMaterialCache = new .() ~ {
		for (let kv in _)
			kv.value?.ReleaseRef();
		delete _;
	};

	public override StringView SerializationTypeId => "Sedulous.ParticleComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostTransform, new => SimulateParticles, simulationOnly: true);
		RegisterUpdate(.PostUpdate, new => ResolveResources);
	}

	/// Simulates all active particle effects.
	private void SimulateParticles(float deltaTime)
	{
		let scene = Scene;
		if (scene == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;
			let instance = comp.Instance;
			if (instance == null) continue;

			// Update position from entity transform
			let worldMatrix = scene.GetWorldMatrix(comp.Owner);
			instance.Position = worldMatrix.Translation;

			// Simulate (pass camera position for LOD - one-frame delay from extraction)
			instance.Update(deltaTime, mCameraPosition);
		}
	}

	/// Resolves effect and texture resources, creates material instances.
	private void ResolveResources(float deltaTime)
	{
		if (Resolver == null || RenderContext == null) return;

		// Find the ParticleRenderer to get its GPUResources
		ParticleRenderer particleRenderer = null;
		for (let renderer in RenderContext.GetRenderersFor(RenderCategories.Particle))
		{
			if (let pr = renderer as ParticleRenderer)
			{
				particleRenderer = pr;
				break;
			}
		}
		if (particleRenderer == null) return;
		let particleGPU = particleRenderer.GPUResources;
		if (particleGPU == null) return;

		let materialSystem = RenderContext.MaterialSystem;
		if (materialSystem == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			let state = GetOrCreateResolveState(comp.Owner);

			// --- Resolve effect resource ---
			if (comp.Instance == null && comp.EffectRef.IsValid)
			{
				if (state.Effect.Resolve(Resolver.ResourceSystem, comp.EffectRef))
				{
					// Effect resource changed - create a new runtime instance
					let effectResource = state.Effect.Handle.Resource;
					if (effectResource != null && effectResource.Effect != null)
					{
						comp.SetEffect(effectResource.Effect);
					}
				}
			}

			// Skip texture/material resolution if no effect instance yet
			if (comp.Instance == null) continue;
			let effect = comp.Effect;
			if (effect == null) continue;

			let systemCount = effect.SystemCount;

			// Grow the per-system slot list to match. Trimming happens after
			// the resolve loop so we release stale slots cleanly.
			while ((int32)state.Systems.Count < systemCount)
				state.Systems.Add(new ParticleSystemResolveState());

			// Resolve each system's resources. Billboards: texture -> shared
			// MaterialInstance keyed by texture view (mMaterialCache, dedup
			// across systems + components). Mesh particles: StaticMesh ref
			// -> GPUMeshHandle + Material ref -> MaterialInstance (both via
			// the engine's shared RenderResourceResolver, same caches the
			// regular mesh path uses).
			for (int32 i = 0; i < systemCount; i++)
			{
				let sysState = state.Systems[i];
				let system = effect.GetSystem(i);

				if (system.RenderMode == .Mesh)
				{
					// Mesh path: resolve mesh + material. Release any
					// stale billboard-side state (Texture/Material) so
					// flipping render mode at runtime doesn't leak.
					sysState.Texture.Release();
					if (sysState.Material != null)
					{
						sysState.Material.ReleaseRef();
						sysState.Material = null;
					}

					let meshRef = system.MeshRef;
					if (meshRef.IsValid)
					{
						GPUMeshHandle meshHandle;
						BoundingBox meshBounds;
						if (Resolver.ResolveMesh(ref sysState.Mesh, meshRef, out meshHandle, out meshBounds))
						{
							sysState.MeshHandle = meshHandle;
							sysState.MeshBounds = meshBounds;
						}
					}
					else
					{
						sysState.Mesh.Release();
						sysState.MeshHandle = .Invalid;
					}

					let matRef = system.MaterialRef;
					if (matRef.IsValid)
					{
						MaterialInstance matInstance;
						if (Resolver.ResolveMaterial(ref sysState.MeshMaterial, matRef, out matInstance))
						{
							if (sysState.MeshMaterialInstance != matInstance)
							{
								if (sysState.MeshMaterialInstance != null)
									sysState.MeshMaterialInstance.ReleaseRef();
								sysState.MeshMaterialInstance = matInstance; // ResolveMaterial AddRef'd
							}
							else
							{
								// Same instance returned - ResolveMaterial AddRef'd, balance with a release.
								matInstance.ReleaseRef();
							}
						}
					}
					else
					{
						sysState.MeshMaterial.Release();
						if (sysState.MeshMaterialInstance != null)
						{
							sysState.MeshMaterialInstance.ReleaseRef();
							sysState.MeshMaterialInstance = null;
						}
					}

					continue;
				}

				// Billboard path: release any stale mesh-side state, then
				// resolve the per-system texture.
				sysState.Mesh.Release();
				sysState.MeshHandle = .Invalid;
				sysState.MeshMaterial.Release();
				if (sysState.MeshMaterialInstance != null)
				{
					sysState.MeshMaterialInstance.ReleaseRef();
					sysState.MeshMaterialInstance = null;
				}

				let texRef = system.TextureRef;
				if (!texRef.IsValid)
				{
					sysState.Texture.Release();
					if (sysState.Material != null)
					{
						sysState.Material.ReleaseRef();
						sysState.Material = null;
					}
					continue;
				}

				ITextureView view = null;
				if (!Resolver.ResolveTexture(ref sysState.Texture, texRef, out view))
					continue;
				if (view == null) continue;

				let key = ObjectKey<ITextureView>(view);
				MaterialInstance matInstance;
				if (mMaterialCache.TryGetValue(key, let cached))
				{
					matInstance = cached;
				}
				else
				{
					matInstance = new MaterialInstance(particleGPU.ParticleMaterial);
					matInstance.SetTexture("ParticleTexture", view);
					materialSystem.PrepareInstance(matInstance);
					mMaterialCache[key] = matInstance;
				}

				if (sysState.Material != matInstance)
				{
					matInstance.AddRef();
					if (sysState.Material != null)
						sysState.Material.ReleaseRef();
					sysState.Material = matInstance;
				}
			}

			// Release per-system slots beyond the current SystemCount (e.g.
			// after the effect was edited and a system was removed).
			while ((int32)state.Systems.Count > systemCount)
			{
				let last = state.Systems.Count - 1;
				state.Systems[last].Release();
				delete state.Systems[last];
				state.Systems.RemoveAt(last);
			}
		}

		// Keep cached instances' bind groups fresh.
		for (let kv in mMaterialCache)
		{
			let mat = kv.value;
			if (mat != null && (mat.IsBindGroupDirty || mat.IsUniformDirty))
				Resolver.PrepareMaterial(mat);
		}
	}

	/// Extracts render data for all active particle effects.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null) return;

		// Store camera position for next frame's LOD calculation
		mCameraPosition = context.CameraPosition;

		let frameAlloc = context.RenderContext.FrameAllocator;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible) continue;
			let instance = comp.Instance;
			if (instance == null) continue;

			if (context.LayerMask != 0xFFFFFFFF && (comp.LayerMask & context.LayerMask) == 0)
				continue;

			let effect = comp.Effect;
			if (effect == null) continue;

			// Per-system resolve state, looked up once per component.
			mResolveStates.TryGetValue(comp.Owner, let resolveState);

			// Extract render data for each system in the effect
			for (int32 sysIdx = 0; sysIdx < effect.SystemCount; sysIdx++)
			{
				let system = effect.GetSystem(sysIdx);
				if (system.AliveCount == 0) continue;

				// Mesh particles produce MeshRenderData entries (one per
				// particle) that flow through the existing MeshRenderer.
				// This reuses static-mesh batching, pipeline state, lighting,
				// and shadow paths - no separate draw path.
				if (system.RenderMode == .Mesh)
				{
					ExtractMeshParticles(system, sysIdx, comp, resolveState, frameAlloc, context);
					continue;
				}

				// Get or create reusable render state for this system
				let renderState = GetOrCreateRenderState(comp.Owner, sysIdx, system.MaxParticles);

				// Extract vertices from streams
				ParticleRenderExtractor.Extract(system, renderState.RenderData, context.CameraPosition);

				// Extract trail vertices if trail mode
				if (system.RenderMode == .Trail)
					ParticleRenderExtractor.ExtractTrails(system, renderState.RenderData, context.CameraPosition);

				let hasBillboards = renderState.RenderData.VertexCount > 0;
				let hasTrails = renderState.RenderData.TrailVertexCount > 0;
				if (!hasBillboards && !hasTrails) continue;

				// Pull the per-system material from the resolve state. May be
				// null if the system has no texture set, or the texture is
				// still pending resolution; renderer falls back to the
				// engine's default 1x1 white sprite in that case.
				MaterialInstance material = null;
				if (resolveState != null && sysIdx < resolveState.Systems.Count)
					material = resolveState.Systems[sysIdx].Material;

				// Create frame-allocated batch entry
				let data = new:frameAlloc ParticleBatchRenderData();
				data.Position = instance.Position;
				data.Bounds = renderState.RenderData.Bounds;
				data.MaterialSortKey = (material != null)
					? (uint32)(int)Internal.UnsafeCastToPtr(material)
					: 0;
				data.Flags = .Dynamic;
				data.Vertices = renderState.RenderData.Vertices.CArray();
				data.VertexCount = renderState.RenderData.VertexCount;
				data.BlendMode = system.BlendMode;
				data.RenderMode = system.RenderMode;
				data.MaterialBindGroup = (material != null) ? material.BindGroup : null;
				data.MaterialKey = data.MaterialSortKey;

				// Trail data
				if (hasTrails)
				{
					data.TrailVertices = renderState.RenderData.TrailVertices.CArray();
					data.TrailVertexCount = renderState.RenderData.TrailVertexCount;
				}

				context.RenderData.Add(RenderCategories.Particle, data);
			}
		}
	}

	private ParticleResolveState GetOrCreateResolveState(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let existing))
			return existing;

		let state = new ParticleResolveState();
		mResolveStates[entity] = state;
		return state;
	}

	/// Emit one MeshRenderData per particle for a mesh-mode system. Each
	/// entry carries the resolved mesh handle, the system's material, and
	/// the per-particle WorldMatrix built from streams (Position, Axis,
	/// Rotation, Size). MeshRenderer batches them by (mesh, material,
	/// submesh) so this collapses to a single instanced draw at render time.
	private void ExtractMeshParticles(ParticleSystem system, int32 sysIdx,
		ParticleComponent comp, ParticleResolveState resolveState,
		FrameAllocator frameAlloc, in RenderExtractionContext context)
	{
		if (resolveState == null) return;
		if (sysIdx >= resolveState.Systems.Count) return;
		let sysState = resolveState.Systems[sysIdx];

		// Need both mesh + material resolved; skip until they're available.
		if (!sysState.MeshHandle.IsValid) return;
		let material = sysState.MeshMaterialInstance;
		if (material == null) return;

		let streams = system.Streams;
		let aliveCount = streams.AliveCount;
		if (aliveCount == 0) return;

		let positions = streams.Positions;
		let sizes = streams.Sizes;
		let rotations = streams.Rotations;
		let axes = streams.Axes;
		let colors = streams.Colors;
		if (positions == null) return;

		// Material's blend mode picks the render category. Mesh particles go
		// through Opaque / Masked / Transparent just like regular meshes,
		// inheriting depth-write, shadows, etc.
		let category = CategoryForBlendMode(material.BlendMode);
		let materialKey = (uint32)(int)Internal.UnsafeCastToPtr(material);

		// Material's pipeline config drives pipeline variant selection.
		let pipelineConfig = (material.Material != null)
			? material.Material.PipelineConfig
			: PipelineConfig();

		// Compute coarse bounds across all alive particles (camera frustum
		// culling happens per-entry; this lets each particle have its own
		// AABB centered at its position with a small mesh-bound expansion).
		let meshBoundsHalfExtent = (sysState.MeshBounds.Max - sysState.MeshBounds.Min) * 0.5f;
		let meshBoundsExtent = Vector3(
			Math.Max(Math.Max(Math.Abs(meshBoundsHalfExtent.X), Math.Abs(meshBoundsHalfExtent.Y)), Math.Abs(meshBoundsHalfExtent.Z)),
			0, 0);

		for (int32 i = 0; i < aliveCount; i++)
		{
			// Build axis-angle quaternion. When the Axis stream isn't
			// present (no MeshOrientationInitializer was added), the axis
			// defaults to world Y so a non-zero Rotation still produces a
			// sensible spin around the up axis rather than degenerating.
			Vector3 axis = (axes != null) ? axes[i] : .(0, 1, 0);
			let lenSq = axis.X * axis.X + axis.Y * axis.Y + axis.Z * axis.Z;
			if (lenSq < 0.0001f) axis = .(0, 1, 0);
			let angle = (rotations != null) ? rotations[i] : 0.0f;
			let quat = Quaternion.CreateFromAxisAngle(axis, angle);

			// Uniform scale: drive off the X component of the per-particle
			// Size (existing Vector2 stream) multiplied by the asset-side
			// MeshScale. Falls back to MeshScale when no Size stream.
			let sizeScalar = (sizes != null) ? sizes[i].X : 1.0f;
			let finalScale = sizeScalar * system.MeshScale;
			let scaleVec = Vector3(finalScale, finalScale, finalScale);

			let worldMatrix = Matrix.CreateFromTranslationRotationScale(
				positions[i], quat, scaleVec);

			let data = new:frameAlloc MeshRenderData();
			data.Position = positions[i];
			// Per-particle bounds = position +/- one mesh extent in each axis
			// (cheap conservative AABB; not tightly fit to the rotated mesh).
			let halfExtent = meshBoundsExtent.X * finalScale;
			let halfVec = Vector3(halfExtent, halfExtent, halfExtent);
			data.Bounds = .(positions[i] - halfVec, positions[i] + halfVec);
			data.SortOrder = 0;
			data.Flags = .Dynamic;
			data.WorldMatrix = worldMatrix;
			data.PrevWorldMatrix = worldMatrix;  // motion vectors: same as current for v1
			// Per-particle color from ColorInitializer / ColorOverLifetime.
			// Falls back to white when no Color stream exists (system has
			// no color-touching initializer/behavior). Mesh shader multiplies
			// this with the material's albedo, so HDR > 1 channels glow.
			data.InstanceColor = (colors != null) ? colors[i] : .(1, 1, 1, 1);
			data.MeshHandle = sysState.MeshHandle;
			data.SubMeshIndex = 0;
			data.MaterialBindGroup = material.BindGroup;
			data.MaterialBindGroupLayout = material.BindGroupLayout;
			data.MaterialPipelineConfig = pipelineConfig;
			data.MaterialSortKey = materialKey;
			data.MaterialKey = materialKey;
			data.EntityIndex = comp.Owner.Index;
			data.IsSkinned = false;

			context.RenderData.Add(category, data);
		}
	}

	private static RenderDataCategory CategoryForBlendMode(BlendMode blend)
	{
		switch (blend)
		{
		case .Masked:
			return RenderCategories.Masked;
		case .AlphaBlend, .Additive, .Multiply, .PremultipliedAlpha:
			return RenderCategories.Transparent;
		default:
			return RenderCategories.Opaque;
		}
	}

	private int64 MakeRenderStateKey(EntityHandle entity, int32 systemIndex)
	{
		return ((int64)entity.Index << 16) | (int64)systemIndex;
	}

	private ParticleRenderState GetOrCreateRenderState(EntityHandle entity, int32 systemIndex, int32 maxParticles)
	{
		let key = MakeRenderStateKey(entity, systemIndex);
		if (mRenderStates.TryGetValue(key, let existing))
			return existing;

		let state = new ParticleRenderState(maxParticles);
		mRenderStates[key] = state;
		return state;
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let state))
		{
			state.Release();
			delete state;
			mResolveStates.Remove(entity);
		}
		// Remove all render states for this entity (one per system in the effect)
		let keysToRemove = scope List<int64>();
		for (let kv in mRenderStates)
		{
			// Extract entity index from key (upper bits)
			if ((kv.key >> 16) == (int64)entity.Index)
				keysToRemove.Add(kv.key);
		}
		for (let key in keysToRemove)
		{
			if (mRenderStates.TryGetValue(key, let renderState))
			{
				delete renderState;
				mRenderStates.Remove(key);
			}
		}
		base.OnEntityDestroyed(entity);
	}
}

/// Per-entity reusable render state (avoids reallocating vertex arrays each frame).
class ParticleRenderState
{
	public ParticleRenderData RenderData ~ delete _;

	public this(int32 maxParticles)
	{
		RenderData = new ParticleRenderData(maxParticles);
	}
}

/// Per-(component, system) resolution state. For billboard particles:
/// resolved texture handle + AddRef'd MaterialInstance (cached by the
/// manager keyed on ITextureView). For mesh particles: resolved
/// StaticMeshResource handle + GPUMeshHandle + AddRef'd MaterialInstance
/// (cached by the engine's RenderResourceResolver keyed on MaterialResource).
/// Lives as a heap-allocated slot in ParticleResolveState.Systems so the
/// contained struct fields can be passed by ref into the resolver without
/// copying.
class ParticleSystemResolveState
{
	// Billboard path
	public ResolvedResource<TextureResource> Texture;
	public MaterialInstance Material;

	// Mesh path
	public ResolvedResource<StaticMeshResource> Mesh;
	public ResolvedResource<MaterialResource> MeshMaterial;
	public GPUMeshHandle MeshHandle = .Invalid;
	public Sedulous.Core.Mathematics.BoundingBox MeshBounds;
	public MaterialInstance MeshMaterialInstance;

	public void Release()
	{
		Texture.Release();
		if (Material != null) { Material.ReleaseRef(); Material = null; }
		Mesh.Release();
		MeshMaterial.Release();
		MeshHandle = .Invalid;
		if (MeshMaterialInstance != null) { MeshMaterialInstance.ReleaseRef(); MeshMaterialInstance = null; }
	}
}

/// Per-component resource resolution tracking for particles.
class ParticleResolveState
{
	/// Resolved particle effect resource.
	public ResolvedResource<ParticleEffectResource> Effect;

	/// Per-system resolution state, indexed by system index. Grown/trimmed
	/// by the manager each frame to match the effect's current SystemCount.
	public System.Collections.List<ParticleSystemResolveState> Systems = new .() ~ {
		for (let s in _) { s.Release(); delete s; }
		delete _;
	};

	public void Release()
	{
		Effect.Release();
		for (let s in Systems)
		{
			s.Release();
			delete s;
		}
		Systems.Clear();
	}
}
