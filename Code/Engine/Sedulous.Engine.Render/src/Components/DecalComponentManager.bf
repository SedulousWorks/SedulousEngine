namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Renderer.Renderers;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Core;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Manages decal components: resolves texture ResourceRefs, creates/caches
/// MaterialInstances from the shared decal Material template, and extracts
/// DecalRenderData each frame with world + inverse world matrices.
class DecalComponentManager : ComponentManager<DecalComponent>, IRenderDataProvider, IResourceChangeListener
{
	public RenderResourceResolver Resolver { get; set; }
	public RenderContext RenderContext { get; set; }

	private Dictionary<EntityHandle, DecalResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
			kv.value.Release();
		DeleteDictionaryAndValues!(_);
	};

	/// Texture view -> shared decal MaterialInstance cache.
	private Dictionary<ObjectKey<ITextureView>, MaterialInstance> mMaterialCache = new .() ~ {
		for (let kv in _)
			kv.value?.ReleaseRef();
		delete _;
	};

	/// Entity indices that need (re)resolving this frame. See
	/// MeshComponentManager for the same pattern.
	private List<int32> mResolveDirtyEntities = new .() ~ delete _;

	private bool mListenerRegistered;

	public override StringView SerializationTypeId => "Sedulous.DecalComponent";

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

	protected override void OnComponentCreated(DecalComponent comp)
	{
		comp.TextureChanged.Add(new (c) => MarkResolveDirty(c));
		MarkResolveDirty(comp);
	}

	public void MarkResolveDirty(DecalComponent comp)
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

		// Find the decal renderer so we can pull its material template.
		let renderers = RenderContext.GetRenderersFor(RenderCategories.Decal);
		if (renderers == null) return;
		DecalRenderer decalRenderer = null;
		for (let r in renderers)
		{
			if (let dr = r as DecalRenderer)
			{
				decalRenderer = dr;
				break;
			}
		}
		if (decalRenderer == null) return;

		let materialSystem = RenderContext.MaterialSystem;

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

			DecalResolveState state;
			if (!mResolveStates.TryGetValue(comp.Owner, var existing))
			{
				let newState = new DecalResolveState();
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

			let key = ObjectKey<ITextureView>(view);
			MaterialInstance matInstance;
			if (mMaterialCache.TryGetValue(key, let cached))
			{
				matInstance = cached;
			}
			else
			{
				matInstance = new MaterialInstance(decalRenderer.DecalMaterial);
				matInstance.SetTexture("DecalTexture", view);
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
		let scene = Scene;
		if (scene == null) return;

		let frameAlloc = context.RenderContext.FrameAllocator;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsVisible) continue;
			if (comp.Material == null) continue;

			if (context.LayerMask != 0xFFFFFFFF && (comp.LayerMask & context.LayerMask) == 0)
				continue;

			// Build world matrix with size applied as scale.
			let entityWorld = scene.GetWorldMatrix(comp.Owner);
			let scale = Matrix.CreateScale(comp.Size.X, comp.Size.Y, comp.Size.Z);
			let worldMatrix = scale * entityWorld;
			Matrix invWorld = .Identity;
			Matrix.Invert(worldMatrix, out invWorld);

			let worldPos = worldMatrix.Translation;

			let materialKey = (uint32)(int)Internal.UnsafeCastToPtr(comp.Material);

			let data = new:frameAlloc DecalRenderData();
			data.Position = worldPos;
			data.Bounds = .(worldPos - comp.Size * 0.5f, worldPos + comp.Size * 0.5f);
			data.MaterialSortKey = materialKey;
			data.SortOrder = 0;
			data.Flags = .None;
			data.WorldMatrix = worldMatrix;
			data.InvWorldMatrix = invWorld;
			data.Color = comp.Color;
			data.AngleFadeStart = comp.AngleFadeStart;
			data.AngleFadeEnd = comp.AngleFadeEnd;
			data.MaterialBindGroup = comp.Material.BindGroup;
			data.MaterialKey = materialKey;

			context.RenderData.Add(RenderCategories.Decal, data);
		}
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
		base.OnEntityDestroyed(entity);
	}
}

class DecalResolveState
{
	public ResolvedResource<TextureResource> Texture;

	public void Release()
	{
		Texture.Release();
	}
}
