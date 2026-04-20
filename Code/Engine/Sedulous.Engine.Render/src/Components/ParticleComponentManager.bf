namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Core;
using Sedulous.Core.Mathematics;
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
		RegisterUpdate(.Update, new => SimulateParticles);
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

			// --- Resolve texture resource ---
			let texRef = comp.TextureRef;
			if (!texRef.IsValid) continue;

			ITextureView view = null;
			if (!Resolver.ResolveTexture(ref state.Texture, texRef, out view))
				continue;
			if (view == null) continue;

			// Look up (or create) the shared MaterialInstance for this texture.
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

			comp.SetMaterial(matInstance);
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

			// Extract render data for each system in the effect
			for (int32 sysIdx = 0; sysIdx < effect.SystemCount; sysIdx++)
			{
				let system = effect.GetSystem(sysIdx);
				if (system.AliveCount == 0) continue;

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

				// Create frame-allocated batch entry
				let data = new:frameAlloc ParticleBatchRenderData();
				data.Position = instance.Position;
				data.Bounds = renderState.RenderData.Bounds;
				data.MaterialSortKey = (comp.Material != null)
					? (uint32)(int)Internal.UnsafeCastToPtr(comp.Material)
					: 0;
				data.Flags = .Dynamic;
				data.Vertices = renderState.RenderData.Vertices.CArray();
				data.VertexCount = renderState.RenderData.VertexCount;
				data.BlendMode = system.BlendMode;
				data.RenderMode = system.RenderMode;
				data.MaterialBindGroup = (comp.Material != null) ? comp.Material.BindGroup : null;
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
		if (let comp = GetForEntity(entity))
		{
			if (comp.Material != null)
			{
				comp.Material.ReleaseRef();
				comp.Material = null;
			}
		}
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

/// Per-component resource resolution tracking for particles.
class ParticleResolveState
{
	/// Resolved particle effect resource.
	public ResolvedResource<ParticleEffectResource> Effect;

	/// Resolved particle texture.
	public ResolvedResource<TextureResource> Texture;

	public void Release()
	{
		Effect.Release();
		Texture.Release();
	}
}
