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
		// Priority 10: run before SkinnedMeshComponentManager (priority 0)
		// so bone matrices are computed before GPU upload.
		RegisterUpdate(.PostUpdate, new => UpdateAnimations, 10);
	}

	private void UpdateAnimations(float deltaTime)
	{
		if (ResourceSystem == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			// Resolve resources if needed
			ResolveResources(comp);

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

			// Update playback
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

		// Resolve skeleton
		if (state.Skeleton.Resolve(ResourceSystem, comp.SkeletonRef))
		{
			let res = state.Skeleton.Handle.Resource;
			comp.Skeleton = (res != null) ? res.Skeleton : null;
		}
		else if (!comp.SkeletonRef.IsValid && comp.Skeleton != null)
			comp.Skeleton = null;

		// Resolve clip
		if (state.Clip.Resolve(ResourceSystem, comp.ClipRef))
		{
			let res = state.Clip.Handle.Resource;
			comp.CurrentClip = (res != null) ? res.Clip : null;
		}
		else if (!comp.ClipRef.IsValid && comp.CurrentClip != null)
			comp.CurrentClip = null;
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
