using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.PropertyAnimation;
using Sedulous.Resource;
using Sedulous.Scene;

using Sedulous.Core;

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
[DisplayName("Property Animator")]
[Category("Animation")]
[Scriptable]
struct PropertyAnimatorComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public Ref<PropertyAnimationClip> Clip = .(Guid());
	[Scriptable]
	public bool AutoPlay = true;
	[Scriptable]
	public float Speed = 1.0f;
	[Scriptable]
	public PropertyLoopMode LoopMode = .Loop;

	// ---- runtime state ----

	[Scriptable]
	public bool Playing = false;
	[Scriptable]
	public float Time = 0.0f;
	public int8 PingPongDirection = 1;
	/// The clip the bindings were built for, BORROWED and compared by reference.
	public PropertyAnimationClip BoundClip = null;
	/// OWNED BY THE MANAGER, like every other list a component points at.
	public List<PropertyTrackBinding> Bindings = null;

	public this() {}

	/// Playback, which mutates only the clock and the state: the manager's tick applies it.
	[Scriptable]
	public void Play() mut
	{
		Playing = true;
		Time = 0.0f;
		PingPongDirection = 1;
	}

	[Scriptable]
	public void Stop() mut
	{
		Playing = false;
		Time = 0.0f;
	}

	[Scriptable]
	public void Pause() mut => Playing = false;

	[Scriptable]
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
