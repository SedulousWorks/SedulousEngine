namespace Sedulous.Engine.Animation;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Core.Mathematics;

/// Manages animation graph components: resolves skeleton + graph resources,
/// creates AnimationGraphPlayers, evaluates graph each frame.
///
/// Updates at PostUpdate with priority 11 - before SkeletalAnimationComponentManager
/// (priority 10) so graph output can override simple clip playback.
class AnimationGraphComponentManager : ComponentManager<AnimationGraphComponent>, IResourceChangeListener
{
	/// Resource system for resolving skeleton/graph refs.
	public ResourceSystem ResourceSystem { get; set; }

	/// Per-component resource resolution tracking.
	private Dictionary<EntityHandle, AnimGraphResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
		{
			kv.value.Release();
			delete kv.value;
		}
		delete _;
	};

	/// Entity indices that need (re)resolving this frame. See
	/// MeshComponentManager for the same pattern.
	private List<int32> mResolveDirtyEntities = new .() ~ delete _;

	private bool mListenerRegistered;

	public override StringView SerializationTypeId => "Sedulous.AnimationGraphComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		// Resource resolution always runs (presentation).
		// Priority 13: run before simulation (priority 11) so resources are ready.
		RegisterUpdate(.PostUpdate, new => ResolveGraphResources, 13);

		// Graph evaluation advances animation state (simulation only).
		// Priority 11: run before SkeletalAnimationComponentManager (priority 10)
		RegisterUpdate(.PostUpdate, new => UpdateGraphs, 11, simulationOnly: true);
	}

	public override void OnSceneCreate(Scene scene)
	{
		base.OnSceneCreate(scene);
		if (ResourceSystem != null)
		{
			ResourceSystem.AddChangeListener(this);
			mListenerRegistered = true;
		}
	}

	public override void OnSceneDestroy()
	{
		if (mListenerRegistered && ResourceSystem != null)
		{
			ResourceSystem.RemoveChangeListener(this);
			mListenerRegistered = false;
		}
		base.OnSceneDestroy();
	}

	protected override void OnComponentCreated(AnimationGraphComponent comp)
	{
		comp.SkeletonChanged.Add(new (c) => MarkResolveDirty(c));
		comp.GraphChanged.Add(new (c) => MarkResolveDirty(c));
		MarkResolveDirty(comp);
	}

	public void MarkResolveDirty(AnimationGraphComponent comp)
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

	/// Resolves skeleton and graph resources. Always runs (presentation).
	/// Resolution runs regardless of Active flag - resources should be ready
	/// when the user hits Play in the editor.
	private void ResolveGraphResources(float deltaTime)
	{
		if (ResourceSystem == null) return;

		// Drain dirty queue. Hot-reload flows through OnResourceReloaded
		// (marks all components dirty), so the generation comparison below
		// only fires for legitimate work.
		for (let entityIdx in mResolveDirtyEntities)
		{
			let comp = GetByEntityIndex(entityIdx);
			if (comp == null || !comp.IsActive || !comp.ResolveDirty) continue;

			let state = GetOrCreateResolveState(comp.Owner);
			ResolveResources(comp, state);

			// Create graph player once resources are ready
			if (comp.GraphPlayer == null && comp.Skeleton != null && comp.Graph != null)
			{
				comp.GraphPlayer = new AnimationGraphPlayer(comp.Graph, comp.Skeleton);
				if (state.Graph.Handle.IsValid && state.Graph.Handle.Resource != null)
					state.BoundGraphGeneration = state.Graph.Handle.Resource.Generation;
			}
			else if (comp.GraphPlayer != null && state.Graph.Handle.IsValid)
			{
				// Detect hot-reload via generation counter (matches material pattern).
				let res = state.Graph.Handle.Resource;
				if (res != null && res.Generation != state.BoundGraphGeneration)
				{
					state.BoundGraphGeneration = res.Generation;
					delete comp.GraphPlayer;
					comp.GraphPlayer = new AnimationGraphPlayer(comp.Graph, comp.Skeleton);
				}
			}

			comp.ResolveDirty = false;
		}
		mResolveDirtyEntities.Clear();
	}

	/// Evaluates animation graphs. Simulation only.
	private void UpdateGraphs(float deltaTime)
	{
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.Active) continue;

			if (comp.GraphPlayer != null)
				comp.GraphPlayer.Update(deltaTime);
		}
	}

	private void ResolveResources(AnimationGraphComponent comp, AnimGraphResolveState state)
	{
		// Resolve skeleton from resource ref. Skip if no ref is set - the
		// skeleton may have been assigned directly (programmatic setup).
		if (comp.SkeletonRef.IsValid)
		{
			if (state.Skeleton.Resolve(ResourceSystem, comp.SkeletonRef))
			{
				let res = state.Skeleton.Handle.Resource;
				comp.Skeleton = (res != null) ? res.Skeleton : null;
			}
		}

		// Resolve graph from resource ref. Same logic - skip if no ref.
		if (comp.GraphRef.IsValid)
		{
			if (state.Graph.Resolve(ResourceSystem, comp.GraphRef))
			{
				let res = state.Graph.Handle.Resource;
				if (res != null)
				{
					res.ResolveClips(ResourceSystem);
					comp.Graph = res.Graph;
				}
				else
					comp.Graph = null;
			}
		}
	}

	private AnimGraphResolveState GetOrCreateResolveState(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let existing))
			return existing;
		let state = new AnimGraphResolveState();
		mResolveStates[entity] = state;
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
		base.OnEntityDestroyed(entity);
	}
}

/// Per-component resource resolution tracking for animation graphs.
class AnimGraphResolveState
{
	public ResolvedResource<SkeletonResource> Skeleton;
	public ResolvedResource<AnimationGraphResource> Graph;

	/// Generation of the graph resource when the player was last created.
	/// Used to detect hot-reloads and recreate the player.
	public uint32 BoundGraphGeneration;

	public void Release()
	{
		Skeleton.Release();
		Graph.Release();
	}
}
