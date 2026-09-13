using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.PropertyAnimation;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Plays ONE property animation clip on its entity, whose tracks drive reflected properties on
/// that entity's own components.
///
/// The serialized shape is the clip reference and the playback tunables. The clock, the
/// bindings and the bound clip are runtime state the manager owns.
///
/// PHYSICS: the animator writes the transform like any other property, and on an entity with a
/// DYNAMIC body physics is authoritative, its own pose sync running in a different phase and
/// overwriting this. Animate the transform of a KINEMATIC or non physical entity; a dynamic
/// body's other properties animate perfectly well.
[SerializableComponent("property_animator")]
struct PropertyAnimatorComponent : ISerializable, IComponentResources
{
	public Ref<PropertyAnimationClip> Clip = .(Guid());
	public bool AutoPlay = true;
	public float Speed = 1.0f;
	public PropertyLoopMode LoopMode = .Loop;

	// ---- runtime state ----

	public bool Playing = false;
	public float Time = 0.0f;
	public int8 PingPongDirection = 1;
	/// The clip the bindings were built for, BORROWED and compared by reference.
	public PropertyAnimationClip BoundClip = null;
	/// OWNED BY THE MANAGER, like every other list a component points at.
	public List<PropertyTrackBinding> Bindings = null;

	public this() {}

	/// Playback, which mutates only the clock and the state: the manager's tick applies it.
	public void Play() mut
	{
		Playing = true;
		Time = 0.0f;
		PingPongDirection = 1;
	}

	public void Stop() mut
	{
		Playing = false;
		Time = 0.0f;
	}

	public void Pause() mut => Playing = false;

	public void Resume() mut => Playing = true;

	public void ResolveResources(ResourceManager manager) mut
	{
		Clip.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "clip", ref Clip.Id);
		SerializeValue(ar, "autoplay", ref AutoPlay);
		SerializeValue(ar, "speed", ref Speed);

		var mode = (uint8)LoopMode;
		SerializeValue(ar, "loopMode", ref mode);
		LoopMode = (PropertyLoopMode)mode;
	}
}
