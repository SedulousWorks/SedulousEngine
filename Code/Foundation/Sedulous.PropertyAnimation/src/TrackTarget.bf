using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.PropertyAnimation;

/// Why a track target is not resolved.
enum TrackTargetStatus
{
	Resolved,
	/// No component type of that name in the scene.
	UnknownComponent,
	/// The path names no property of it.
	UnknownProperty,
	/// The property's type is not the one the track's kind writes.
	KindMismatch
}

/// A track's component and property path bound on one scene: the component's manager (stable for
/// the scene's life; null for the transform) and the property chain. The component itself is found
/// again on every read and write, never kept, since its pool moves components.
class TrackTarget
{
	/// BORROWED; null for the transform.
	public ComponentManagerBase Manager = null;
	public PropertyBinding Binding = new .() ~ delete _;
	/// Targets the entity's own transform, which belongs to the scene rather than a component.
	public bool IsTransform = false;
	public TrackTargetStatus Status = .UnknownProperty;

	public bool IsResolved => Status == .Resolved;
}

/// A track's target on a scene: bound once (Resolve), then read and written on any entity there.
/// What every player of tracks needs (the animator, the sequencer, the editor's preview), so none
/// of them keeps its own copy.
static class TrackTargets
{
	/// The component type under which a track animates the entity's own transform (position,
	/// rotation, scale). The transform belongs to the scene, not to a component, so it is read and
	/// written through Get/SetLocalTransform, which keeps the world matrix in step. Reserved: a real
	/// component may not take this name.
	public const String cTransform = "Transform";

	/// The reflected type a track of `kind` writes.
	public static Type LeafTypeOf(TrackValueKind kind)
	{
		switch (kind)
		{
		case .Float: return typeof(float);
		case .Float3: return typeof(Float3);
		case .Color: return typeof(Color);
		case .Quat: return typeof(Quaternion);
		}
	}

	/// Binds `componentType` and `propertyPath` on `scene` into `outTarget`. Not resolved when
	/// either is unknown.
	public static void Resolve(Sedulous.Scene.Scene scene, StringView componentType, StringView propertyPath, TrackTarget outTarget)
	{
		outTarget.Binding.Clear();
		outTarget.Manager = null;
		outTarget.IsTransform = componentType == cTransform;
		Type type;
		if (outTarget.IsTransform)
			type = typeof(Transform);
		else
		{
			outTarget.Manager = scene.FindManagerByComponentName(componentType);
			if ((outTarget.Manager == null) || (outTarget.Manager.ComponentType == null))
			{
				outTarget.Manager = null;
				outTarget.Status = .UnknownComponent;
				return;
			}
			type = outTarget.Manager.ComponentType;
		}
		PropertyBindingResolver.Resolve(type, propertyPath, outTarget.Binding);
		outTarget.Status = outTarget.Binding.IsResolved ? .Resolved : .UnknownProperty;
	}

	/// Binds `track`'s target on `scene`, and checks that its property's type is the one its kind
	/// writes (KindMismatch otherwise, since every write would fail).
	public static void Resolve(Sedulous.Scene.Scene scene, PropertyTrack track, TrackTarget outTarget)
	{
		Resolve(scene, track.ComponentType, track.PropertyPath, outTarget);
		if (!outTarget.IsResolved)
			return;
		let chain = outTarget.Binding.Chain;
		if (chain[chain.Length - 1].FieldType != LeafTypeOf(track.Kind))
			outTarget.Status = .KindMismatch;
	}

	/// The target's value on `entity`; empty when it is not resolved, or the entity has no such
	/// component.
	public static PropertyValue Read(Sedulous.Scene.Scene scene, TrackTarget target, EntityHandle entity)
	{
		if (target.Status == .UnknownComponent || !target.Binding.IsResolved)
			return .Empty;
		if (target.IsTransform)
		{
			var local = scene.GetLocalTransform(entity);
			return PropertyBindingResolver.Read(target.Binding, &local, typeof(Transform));
		}
		let address = target.Manager.GetComponentAddress(entity);
		if (address == null)
			return .Empty;
		return PropertyBindingResolver.Read(target.Binding, address, target.Manager.ComponentType);
	}

	/// Writes `value` to the target on `entity`; false when nothing was written. The transform goes
	/// through SetLocalTransform, so its world matrix follows.
	public static bool Write(Sedulous.Scene.Scene scene, TrackTarget target, EntityHandle entity, PropertyValue value)
	{
		if (target.Status == .UnknownComponent || !target.Binding.IsResolved)
			return false;
		if (target.IsTransform)
		{
			var local = scene.GetLocalTransform(entity);
			if (!(PropertyBindingResolver.Write(target.Binding, &local, typeof(Transform), value) case .Ok))
				return false;
			scene.SetLocalTransform(entity, local);
			return true;
		}
		let address = target.Manager.GetComponentAddress(entity);
		if (address == null)
			return false;
		return PropertyBindingResolver.Write(target.Binding, address, target.Manager.ComponentType, value) case .Ok;
	}

	/// Samples `track` at `time` over the target's live value (channels without keys keep it) and
	/// writes it: one track's step for a player. False when nothing was written.
	public static bool Apply(Sedulous.Scene.Scene scene, TrackTarget target, EntityHandle entity, PropertyTrack track, float time)
	{
		if (!target.IsResolved)
			return false;
		let current = Read(scene, target, entity);
		return Write(scene, target, entity, track.SampleMerged(time, current));
	}
}
