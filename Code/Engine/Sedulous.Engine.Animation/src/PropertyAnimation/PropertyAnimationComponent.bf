namespace Sedulous.Engine.Animation;

using System;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Animation;

/// Component for property-based animation (animating entity transforms,
/// component properties, etc. via string-identified tracks).
///
/// Used for doors, platforms, UI animations, color fades - anything that
/// isn't skeletal animation. Tracks are evaluated against the entity via
/// the PropertyBinderRegistry.
class PropertyAnimationComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("ClipRef", ref mClipRef);
		s.Float("Speed", ref Speed);
		s.Bool("Loop", ref Loop);
		s.Bool("AutoPlay", ref AutoPlay);
	}

	// --- Resource ref (serializable) ---

	/// Property animation clip resource reference.
	private ResourceRef mClipRef ~ _.Dispose();

	// --- Configuration ---

	/// Playback speed multiplier.
	public float Speed = 1.0f;

	/// Whether the animation loops.
	public bool Loop = true;

	/// Whether to start playing automatically on initialization.
	public bool AutoPlay = true;

	/// Whether the animation is currently playing.
	public bool Playing = false;

	// --- Runtime state (managed by PropertyAnimationComponentManager) ---

	/// Resolved animation clip (not owned - owned by resource system).
	public PropertyAnimationClip CurrentClip;

	/// Property animation player (owned by this component, created by manager).
	public PropertyAnimationPlayer Player ~ delete _;

	/// Whether the clip has been resolved and the player created.
	public bool IsReady => Player != null;

	// --- Resource ref accessors ---

	public ResourceRef ClipRef => mClipRef;

	public void SetClipRef(ResourceRef @ref)
	{
		mClipRef.Dispose();
		mClipRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}
}
