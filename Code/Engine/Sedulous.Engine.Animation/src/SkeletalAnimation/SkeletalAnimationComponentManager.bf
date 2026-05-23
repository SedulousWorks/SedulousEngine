namespace Sedulous.Engine.Animation;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Core.Mathematics;

/// Manages skeletal animation components: resolves skeleton + clip resources,
/// creates AnimationPlayers, evaluates animation each frame.
///
/// Updates at PostUpdate with priority 10 - before SkinnedMeshComponentManager
/// (priority 0) so bone matrices are ready for GPU skinning upload.
class SkeletalAnimationComponentManager : ComponentManager<SkeletalAnimationComponent>
{
	/// Resource system for resolving skeleton/clip refs.
	public ResourceSystem ResourceSystem { get; set; }

	/// Per-component resource resolution tracking.
	private Dictionary<EntityHandle, SkeletalAnimResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
		{
			kv.value.Release();
			delete kv.value;
		}
		delete _;
	};

	public override StringView SerializationTypeId => "Sedulous.SkeletalAnimationComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		// Resource resolution always runs (presentation).
		// Priority 12: run before simulation (priority 10) so resources are ready.
		RegisterUpdate(.PostUpdate, new => ResolveAnimationResources, 12);

		// Animation playback advances time (simulation only).
		// Priority 10: run before SkinnedMeshComponentManager (priority 0)
		// so bone matrices are computed before GPU upload.
		RegisterUpdate(.PostUpdate, new => UpdateAnimations, 10, simulationOnly: true);
	}

	/// Resolves skeleton and clip resources. Always runs (presentation).
	private void ResolveAnimationResources(float deltaTime)
	{
		if (ResourceSystem == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;
			ResolveResources(comp);

			// Skeleton swap: tear down the player so it gets rebuilt
			// below against the new skeleton. AnimationPlayer captures
			// its Skeleton at construction; mutating refs without this
			// would leave the player driving the wrong bone hierarchy.
			if (comp.Player != null && comp.Skeleton != null && comp.Player.Skeleton !== comp.Skeleton)
			{
				delete comp.Player;
				comp.Player = null;
			}

			// Create player once resources are ready
			if (comp.Player == null && comp.Skeleton != null && comp.CurrentClip != null)
			{
				comp.Player = new AnimationPlayer(comp.Skeleton);
				if (comp.AutoPlay)
				{
					comp.CurrentClip.IsLooping = comp.Loop;
					comp.Player.Play(comp.CurrentClip);
					comp.Playing = true;
				}
			}
			// Clip swap on an existing player: rebind to the new clip.
			// Without this, ClipRef changes propagate to CurrentClip
			// but the player keeps animating its original Play(clip)
			// argument - editor "pick a different animation" would
			// silently do nothing.
			else if (comp.Player != null && comp.CurrentClip != null
				&& comp.Player.CurrentClip !== comp.CurrentClip)
			{
				comp.CurrentClip.IsLooping = comp.Loop;
				comp.Player.Play(comp.CurrentClip);
				comp.Playing = true;
			}
		}
	}

	/// Advances animation playback. Simulation only.
	private void UpdateAnimations(float deltaTime)
	{
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			if (comp.Player != null && comp.Playing)
			{
				comp.Player.Speed = comp.Speed;
				if (comp.CurrentClip != null)
					comp.CurrentClip.IsLooping = comp.Loop;
				comp.Player.Update(deltaTime);
			}
		}
	}

	private void ResolveResources(SkeletalAnimationComponent comp)
	{
		let state = GetOrCreateResolveState(comp.Owner);

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

		// Resolve clip from resource ref. Same logic - skip if no ref.
		if (comp.ClipRef.IsValid)
		{
			if (state.Clip.Resolve(ResourceSystem, comp.ClipRef))
			{
				let res = state.Clip.Handle.Resource;
				comp.CurrentClip = (res != null) ? res.Clip : null;
			}
		}
	}

	private SkeletalAnimResolveState GetOrCreateResolveState(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let existing))
			return existing;
		let state = new SkeletalAnimResolveState();
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

/// Per-component resource resolution tracking.
class SkeletalAnimResolveState
{
	public ResolvedResource<SkeletonResource> Skeleton;
	public ResolvedResource<AnimationClipResource> Clip;

	public void Release()
	{
		Skeleton.Release();
		Clip.Release();
	}
}
