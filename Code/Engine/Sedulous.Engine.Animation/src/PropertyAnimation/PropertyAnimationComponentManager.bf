namespace Sedulous.Engine.Animation;

using System;
using System.Collections;
using Sedulous.Scenes;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;

/// Manages property animation components: resolves clip resources,
/// creates PropertyAnimationPlayers, evaluates tracks each frame.
///
/// Updates at Update phase with priority 0 — applies property changes
/// during main game logic phase so they're visible to PostUpdate.
class PropertyAnimationComponentManager : ComponentManager<PropertyAnimationComponent>
{
	/// Resource system for resolving clip refs.
	public ResourceSystem ResourceSystem { get; set; }

	/// Shared property binder registry (owned by AnimationSubsystem).
	public PropertyBinderRegistry BinderRegistry { get; set; }

	/// Per-component resource resolution tracking.
	private Dictionary<EntityHandle, PropAnimResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
		{
			kv.value.Release();
			delete kv.value;
		}
		delete _;
	};

	public override StringView SerializationTypeId => "Sedulous.PropertyAnimationComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.Update, new => UpdatePropertyAnimations);
	}

	private void UpdatePropertyAnimations(float deltaTime)
	{
		if (ResourceSystem == null || BinderRegistry == null) return;
		let scene = Scene;
		if (scene == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			// Resolve resources if needed
			ResolveResources(comp);

			// Create player once clip is ready
			if (comp.Player == null && comp.CurrentClip != null)
			{
				comp.Player = new PropertyAnimationPlayer(scene, comp.Owner, BinderRegistry);
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

	private void ResolveResources(PropertyAnimationComponent comp)
	{
		let state = GetOrCreateResolveState(comp.Owner);

		if (comp.CurrentClip == null && comp.ClipRef.IsValid)
		{
			if (!state.ClipHandle.IsValid)
			{
				if (ResourceSystem.LoadByRef<PropertyAnimationClipResource>(comp.ClipRef) case .Ok(let handle))
					state.ClipHandle = handle;
			}
			if (state.ClipHandle.IsValid)
			{
				let res = state.ClipHandle.Resource;
				if (res != null)
					comp.CurrentClip = res.Clip;
			}
		}
	}

	private PropAnimResolveState GetOrCreateResolveState(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let existing))
			return existing;
		let state = new PropAnimResolveState();
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

/// Per-component resource resolution tracking for property animation.
class PropAnimResolveState
{
	public ResourceHandle<PropertyAnimationClipResource> ClipHandle;

	public void Release()
	{
		if (ClipHandle.IsValid) ClipHandle.Release();
	}
}
