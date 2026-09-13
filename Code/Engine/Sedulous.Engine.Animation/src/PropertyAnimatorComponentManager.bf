using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Profiler;
using Sedulous.PropertyAnimation;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every property animator in the animation phase, before extraction: advance the clock
/// under the loop mode, then write each track's sampled value through its binding.
///
/// The LIVE component is re-resolved for every write rather than held: a pool swaps its last
/// component into a hole on removal, so an address taken once would end up writing into
/// another entity's component.
///
/// SIMULATION GATED, for the same reason the skeletal manager is: a clip visibly animating in
/// an editor's edit mode is wrong. It does NOT gate an animation panel's preview, which writes
/// property values directly rather than through this tick.
class PropertyAnimatorComponentManager : ResourceBindingComponentManager<PropertyAnimatorComponent>
{
	/// The entity's local transform is not a reflected COMPONENT, being baked into the scene,
	/// so a track names it with this RESERVED type name and binds against the transform value
	/// instead. A real component may not take the name.
	public const String cTransformComponentName = "Transform";

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	public override bool IsSimulationOnly => true;

	protected override void OnComponentCreated(PropertyAnimatorComponent* component,
		EntityHandle entity)
	{
		component.Bindings = new List<PropertyTrackBinding>();
	}

	protected override void OnComponentDestroyed(PropertyAnimatorComponent* component,
		EntityHandle entity)
	{
		if (component.Bindings != null)
		{
			ClearAndDeleteItems!(component.Bindings);
			DeleteAndNullify!(component.Bindings);
		}
		component.BoundClip = null;
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;

		using (ProfileScope("PropertyAnimation.Update"))
		{
			ForEach(scope (component, owner) =>
				{
					Tick(component, owner, deltaTime);
				});
		}
	}

	private void Tick(PropertyAnimatorComponent* animator, EntityHandle owner, float deltaTime)
	{
		// Frozen: no advance and no writes.
		if (!mScene.IsEffectivelyActive(owner))
			return;

		let clip = animator.Clip.Get;
		if (clip == null)
			return;

		// (Re)build the bindings when the clip OBJECT changes: the first tick, an editor pick,
		// a hot reload. Automatic playback starts the new clip from the top.
		if (clip !== animator.BoundClip)
		{
			animator.BoundClip = clip;
			BuildBindings(animator, clip);
			if (animator.AutoPlay)
			{
				animator.Playing = true;
				animator.Time = 0.0f;
				animator.PingPongDirection = 1;
			}
		}

		if (!animator.Playing)
			return;

		let evalTime = Advance(animator, clip.Duration, deltaTime);
		let trackCount = Math.Min(animator.Bindings.Count, clip.Tracks.Count);

		for (int i < trackCount)
		{
			let bound = animator.Bindings[i];
			if (bound.Disabled || !bound.Binding.IsResolved)
				continue;

			let track = clip.Tracks[i];

			if (bound.IsTransform)
			{
				// Read, modify and write the scene transform through the scene's own setter,
				// which is what flags the world matrix dirty; writing the field directly would
				// leave the matrix stale. The merged sample keeps the LIVE value for a channel
				// the track does not drive, so a position only track does not teleport the
				// rotation to identity.
				var local = mScene.GetLocalTransform(owner);
				let current = PropertyBindingResolver.Read(bound.Binding, &local,
					typeof(Transform));
				let value = track.SampleMerged(evalTime, current);
				if (PropertyBindingResolver.Write(bound.Binding, &local, typeof(Transform), value)
					case .Ok)
					mScene.SetLocalTransform(owner, local);
				continue;
			}

			if (bound.Manager == null)
				continue;

			let address = bound.Manager.GetComponentAddress(owner);
			// Removed this frame: skip it and keep the binding, since the component may come
			// back before the clip ends.
			if (address == null)
				continue;

			let type = bound.Manager.ComponentType;
			let current = PropertyBindingResolver.Read(bound.Binding, address, type);
			let value = track.SampleMerged(evalTime, current);
			PropertyBindingResolver.Write(bound.Binding, address, type, value).IgnoreError();
		}
	}

	/// Resolves each track's target manager, by component type name, and its property chain,
	/// ONCE. A track whose type or path will not resolve is disabled with one warning.
	private void BuildBindings(PropertyAnimatorComponent* animator, PropertyAnimationClip clip)
	{
		ClearAndDeleteItems!(animator.Bindings);

		for (let track in clip.Tracks)
		{
			let bound = new PropertyTrackBinding();
			animator.Bindings.Add(bound);

			// The built in transform target binds against the transform value itself.
			if (track.ComponentType == cTransformComponentName)
			{
				bound.IsTransform = true;
				PropertyBindingResolver.Resolve(typeof(Transform), track.PropertyPath,
					bound.Binding);
				if (!bound.Binding.IsResolved)
				{
					GlobalLog(.Warning,
						"PropertyAnimation: the track property 'Transform.{}' was not found, so it is disabled",
						track.PropertyPath);
					bound.Disabled = true;
				}
				CheckKind(bound, track);
				continue;
			}

			let manager = FindManagerByComponentTypeName(track.ComponentType);
			if ((manager == null) || (manager.ComponentType == null))
			{
				GlobalLog(.Warning,
					"PropertyAnimation: the track targets the unknown component type '{}', so it is disabled",
					track.ComponentType);
				bound.Disabled = true;
				continue;
			}

			bound.Manager = manager;
			PropertyBindingResolver.Resolve(manager.ComponentType, track.PropertyPath,
				bound.Binding);
			if (!bound.Binding.IsResolved)
			{
				GlobalLog(.Warning,
					"PropertyAnimation: the track property '{}' was not found on '{}', so it is disabled",
					track.PropertyPath, track.ComponentType);
				bound.Disabled = true;
			}
			CheckKind(bound, track);
		}
	}

	/// The reflected leaf type a kind writes as.
	private static Type ExpectedLeafType(TrackValueKind kind)
	{
		switch (kind)
		{
		case .Float: return typeof(float);
		case .Float3: return typeof(Float3);
		case .Color: return typeof(Color);
		case .Quat: return typeof(Quaternion);
		}
	}

	/// A track whose kind does not match its resolved leaf would be a silent write failure
	/// every frame. Disable it once, with a warning, exactly as a failed resolve is.
	private void CheckKind(PropertyTrackBinding bound, PropertyTrack track)
	{
		if (bound.Disabled || !bound.Binding.IsResolved)
			return;

		let chain = bound.Binding.Chain;
		let leaf = chain[chain.Length - 1];
		if (leaf.FieldType != ExpectedLeafType(track.Kind))
		{
			GlobalLog(.Warning,
				"PropertyAnimation: the track '{}.{}' does not match the property's type, so it is disabled",
				track.ComponentType, track.PropertyPath);
			bound.Disabled = true;
		}
	}

	/// The scene's manager whose reflected component type carries this name, or null.
	private ComponentManagerBase FindManagerByComponentTypeName(StringView name)
	{
		ComponentManagerBase found = null;
		mScene.ForEachManager(scope [&] (manager) =>
			{
				if (found != null)
					return;
				let type = manager.ComponentType;
				if (type == null)
					return;

				let typeName = scope String();
				type.GetName(typeName);
				if (typeName == name)
					found = manager;
			});
		return found;
	}

	/// Advances the clock under the loop mode, answering the evaluation time. The speed may be
	/// negative, which is what plays a clip backwards.
	private static float Advance(PropertyAnimatorComponent* animator, float duration,
		float deltaTime)
	{
		if (duration <= 0.0f)
			return 0.0f;

		let direction = (animator.LoopMode == .PingPong)
			? (float)animator.PingPongDirection : 1.0f;
		animator.Time += deltaTime * animator.Speed * direction;

		switch (animator.LoopMode)
		{
		case .Once:
			if (animator.Time >= duration)
			{
				animator.Time = duration;
				animator.Playing = false;
			}
			else if (animator.Time < 0.0f)
			{
				animator.Time = 0.0f;
				animator.Playing = false;
			}

		case .Loop:
			// The floor wraps a negative clock as well as an overrun one.
			animator.Time -= duration * Math.Floor(animator.Time / duration);

		case .PingPong:
			// Fold back into the clip, flipping at each end. BOUNDED, so an enormous delta
			// settles rather than spinning.
			for (int guard = 0;
				((animator.Time > duration) || (animator.Time < 0.0f)) && (guard < 64);
				guard++)
			{
				if (animator.Time > duration)
				{
					animator.Time = 2.0f * duration - animator.Time;
					animator.PingPongDirection = -1;
				}
				else if (animator.Time < 0.0f)
				{
					animator.Time = -animator.Time;
					animator.PingPongDirection = 1;
				}
			}
		}

		return animator.Time;
	}
}
