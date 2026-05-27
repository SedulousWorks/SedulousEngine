namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Core;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Profiler;

/// Manages sprite components: resolves texture ResourceRefs, creates a
/// MaterialInstance from SpriteSystem's shared sprite material template,
/// and extracts SpriteRenderData each frame.
///
/// Textures shared across multiple SpriteComponents produce shared
/// MaterialInstances (via an internal cache) so sprites with the same
/// texture batch into a single instanced draw call.
class SpriteComponentManager : ComponentManager<SpriteComponent>, IRenderDataProvider, IResourceChangeListener
{
	/// Shared resource resolver (set by RenderSubsystem).
	public RenderResourceResolver Resolver { get; set; }

	/// Shared renderer context (needed for the sprite material template + MaterialSystem).
	public RenderContext RenderContext { get; set; }

	private Dictionary<EntityHandle, SpriteResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
			kv.value.Release();
		DeleteDictionaryAndValues!(_);
	};

	/// Cache: texture view -> shared MaterialInstance. Sprites using the same
	/// texture share the same instance (and therefore the same bind group) so
	/// they can be batched into a single DrawInstanced.
	private Dictionary<ObjectKey<ITextureView>, MaterialInstance> mMaterialCache = new .() ~ {
		for (let kv in _)
			kv.value?.ReleaseRef();
		delete _;
	};

	/// Entity indices that need (re)resolving this frame. See
	/// MeshComponentManager for the same pattern.
	private List<int32> mResolveDirtyEntities = new .() ~ delete _;

	private bool mListenerRegistered;

	public override StringView SerializationTypeId => "Sedulous.SpriteComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => ResolveResources);
	}

	public override void OnSceneCreate(Scene scene)
	{
		base.OnSceneCreate(scene);
		if (Resolver?.ResourceSystem != null)
		{
			Resolver.ResourceSystem.AddChangeListener(this);
			mListenerRegistered = true;
		}
	}

	public override void OnSceneDestroy()
	{
		if (mListenerRegistered && Resolver?.ResourceSystem != null)
		{
			Resolver.ResourceSystem.RemoveChangeListener(this);
			mListenerRegistered = false;
		}
		base.OnSceneDestroy();
	}

	protected override void OnComponentCreated(SpriteComponent comp)
	{
		comp.TextureChanged.Add(new (c) => MarkResolveDirty(c));
		// Manually-created MaterialInstances - see MeshComponentManager.
		comp.MaterialInstanceAttached.Add(new (mat) => OnMaterialInstanceAttached(mat));
		MarkResolveDirty(comp);
	}

	private void OnMaterialInstanceAttached(MaterialInstance material)
	{
		if (material == null || Resolver == null)
			return;
		Resolver.MaterialSystem.PrepareInstance(material);
	}

	public void MarkResolveDirty(SpriteComponent comp)
	{
		if (comp.ResolveDirty)
			return;
		comp.ResolveDirty = true;
		mResolveDirtyEntities.Add((int32)comp.Owner.Index);
	}

	public void OnResourceReloaded(StringView uri, Type resourceType, IResource resource)
	{
		for (let comp in ActiveComponents)
			MarkResolveDirty(comp);
	}

	private void ResolveResources(float deltaTime)
	{
		if (Resolver == null || RenderContext == null) return;

		let spriteSystem = RenderContext.SpriteSystem;
		let materialSystem = RenderContext.MaterialSystem;
		if (spriteSystem == null || materialSystem == null) return;

		// Pass 1: drain resolve-dirty queue.
		for (let entityIdx in mResolveDirtyEntities)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null || !comp.IsActive || !comp.ResolveDirty) continue;
			let texRef = comp.TextureRef;
			if (!texRef.IsValid)
			{
				comp.ResolveDirty = false;
				continue;
			}

			SpriteResolveState state;
			if (!mResolveStates.TryGetValue(comp.Owner, var existing))
			{
				let newState = new SpriteResolveState();
				mResolveStates[comp.Owner] = newState;
				state = newState;
			}
			else
			{
				state = existing;
			}

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
				matInstance = new MaterialInstance(spriteSystem.SpriteMaterial);
				matInstance.SetTexture("SpriteTexture", view);
				materialSystem.PrepareInstance(matInstance);
				mMaterialCache[key] = matInstance;
			}

			comp.SetMaterial(matInstance);
			comp.ResolveDirty = false;
		}
		mResolveDirtyEntities.Clear();

		// Pass 2: drain the global MaterialSystem dirty list. See
		// MeshComponentManager.ResolveResources for the same pattern.
		Resolver.MaterialSystem.PrepareDirtyInstances();
	}

	public void ExtractRenderData(in RenderExtractionContext context)
	{
		using (Profiler.Begin("Sprite.Extract"))
		{
		let scene = Scene;
		if (scene == null) return;

		let frameAlloc = context.RenderContext.FrameAllocator;
		let viewMatrix = context.ViewMatrix;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible) continue;
			if (comp.Material == null) continue;

			if (context.LayerMask != 0xFFFFFFFF && (comp.LayerMask & context.LayerMask) == 0)
				continue;

			let worldMatrix = scene.GetWorldMatrix(comp.Owner);
			let worldPos = worldMatrix.Translation;

			let materialKey = (uint32)(int)Internal.UnsafeCastToPtr(comp.Material);

			let data = new:frameAlloc SpriteRenderData();
			data.Position = worldPos;
			data.Bounds = .(worldPos, worldPos);
			data.MaterialSortKey = materialKey;
			data.SortOrder = 0;
			data.Flags = .None;
			// Sprites go in the Transparent category - inline back-to-front sort key.
			data.SortKey = ExtractedRenderData.ComputeBackToFrontSortKey(worldPos, viewMatrix);
			data.Size = comp.Size;
			data.Tint = comp.Tint;
			data.UVRect = comp.UVRect;
			data.Orientation = comp.Orientation;
			data.MaterialBindGroup = comp.Material.BindGroup;
			data.MaterialKey = materialKey;

			context.RenderData.Add(RenderCategories.Transparent, data);
		}
		}
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		if (let comp = GetForEntity(entity))
		{
			// Sprite component's Material is a shared instance owned by the cache -
			// the component just holds a ref. Releasing the ref here drops the
			// component's hold; the cache still keeps a ref until Dispose.
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
		base.OnEntityDestroyed(entity);
	}
}

/// Per-component resource resolution tracking for sprites.
class SpriteResolveState
{
	public ResolvedResource<TextureResource> Texture;

	public void Release()
	{
		Texture.Release();
	}
}
