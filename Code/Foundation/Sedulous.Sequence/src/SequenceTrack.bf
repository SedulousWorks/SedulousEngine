using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;

namespace Sedulous.Sequence;

/// What a play reports, for whoever started it to pass on (as entity events, or on the run's
/// event bus).
interface ISequenceListener
{
	/// An event key was passed. `target` is the event track's entity, unassigned when the track
	/// is bound to no one.
	void OnSequenceEvent(EntityHandle target, StringView name, StringView value);
	/// The playhead reached the hold marker `marker` and stopped there.
	void OnSequenceHeld(StringView marker);
	/// The playhead reached the end (not on a stop).
	void OnSequenceFinished();
}

/// One step of a play, as each track sees it. Events fire for keys in (PreviousTime, Time]; a
/// play's first step, and the step after a loop wraps, start before 0 so a key at 0 fires.
struct SequenceStep
{
	public float Time;
	public float PreviousTime;
	/// The playhead moved without playing what lies between (a seek, a scrub): nothing in between
	/// fires.
	public bool Jumped;
	/// The editor posing the scene: tracks apply their values but send no events and start no
	/// sounds.
	public bool Preview;
}

/// One track's work in one play: made when the play begins, told each step, released when the
/// play ends.
abstract class SequenceTrackRunner
{
	public abstract void Evaluate(SequenceStep step);
	/// The play ended or stopped: let go of what this runner holds (a voice, an override).
	/// `restore`: also put back every value it changed, as it was before its first change.
	public abstract void Release(bool restore);
	/// The play was paused or resumed (not held: at a hold the playhead waits while what plays, a
	/// line of dialogue, carries on). Most runners have nothing that runs on its own between
	/// steps; a sound's voice does.
	public virtual void SetPaused(bool paused) {}
}

/// What a track is given to begin in a play.
struct SequenceTrackContext
{
	/// BORROWED.
	public Sedulous.Scene.Scene Scene;
	/// The track's bound entity; unassigned when it is bound to no one.
	public EntityHandle Entity;
	/// BORROWED; may be null: nothing is reported.
	public ISequenceListener Listener;
	/// BORROWED: the play the track runs in (its cast, the plays it is nested in).
	public SequencePlay Play;
}

/// The base of every track kind. A kind adds its keys or sections, serializes them after the
/// base's fields, and makes a runner for each play. A kind is registered (SequenceTracks.Register),
/// so a sequence holding it reads and whatever lists the kinds (the editor's add-track menu) finds
/// it, with no list anywhere to edit.
abstract class SequenceTrack : ISerializable
{
	/// Shown in the editor.
	public String Name = new .() ~ delete _;
	/// Index into the sequence's bindings; -1: bound to no one.
	public int32 Binding = -1;
	public bool Muted = false;

	/// The time of the track's last key or the end of its last section.
	public abstract float Duration { get; }
	/// When the track runs within a step, lower first: properties, then what reads them
	/// (animation, cameras), events last.
	public virtual int32 Order => 0;
	/// Whether the track does nothing without an entity (a property track); an event track reports
	/// to the play instead.
	public virtual bool NeedsBinding => true;
	/// The track's runner for one play, OWNED by the caller; null when it has nothing to do there
	/// (a warning says why when that is a fault).
	public abstract SequenceTrackRunner Begin(SequenceTrackContext context);
	/// Binds the assets the track refers to (a clip, a sound, a nested sequence), after a
	/// sequence is loaded.
	public virtual void ResolveResources(ResourceManager manager) {}

	public virtual void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		SerializeValue(ar, "binding", ref Binding);
		SerializeValue(ar, "muted", ref Muted);
	}
}

/// Evaluation orders of the kinds here; a domain's kind picks its own between them.
static class SequenceTrackOrder
{
	public const int32 Property = 0;
	public const int32 Event = 1000;
}

/// Any reflected property of a component on the bound entity, or its transform, as property
/// animation's track (its keys, its target, its sampling).
[DisplayName("Property")]
class PropertySequenceTrack : SequenceTrack
{
	public PropertyTrack Property = new .() ~ delete _;

	public override float Duration => Property.Duration;
	public override int32 Order => SequenceTrackOrder.Property;

	public override SequenceTrackRunner Begin(SequenceTrackContext context)
	{
		let target = new TrackTarget();
		TrackTargets.Resolve(context.Scene, Property, target);
		switch (target.Status)
		{
		case .Resolved:
			return new PropertyRunner(context.Scene, context.Entity, Property, target);
		case .UnknownComponent:
			GlobalLog(.Warning, "Sequence: track '{}' targets unknown component type '{}' - skipped", Name, Property.ComponentType);
		case .UnknownProperty:
			GlobalLog(.Warning, "Sequence: track '{}': property '{}' not found on '{}' - skipped", Name, Property.PropertyPath,
				Property.ComponentType);
		case .KindMismatch:
			GlobalLog(.Warning, "Sequence: track '{}': '{}.{}' is not of the track's kind - skipped", Name, Property.ComponentType,
				Property.PropertyPath);
		}
		delete target;
		return null;
	}

	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		PropertyTrackSerialization.Serialize(ar, Property);
	}

	/// Writes a property track on its entity each step. The value it found there before its first
	/// write is kept, so a Restore finish (and the editor's preview) can put it back.
	private class PropertyRunner : SequenceTrackRunner
	{
		/// BORROWED, both.
		private Sedulous.Scene.Scene mScene;
		private PropertyTrack mTrack;
		private EntityHandle mEntity;
		private TrackTarget mTarget ~ delete _;
		private PropertyValue mOriginal = .Empty;
		private bool mChanged = false;

		/// Takes `target` (OWNED).
		public this(Sedulous.Scene.Scene scene, EntityHandle entity, PropertyTrack track, TrackTarget target)
		{
			mScene = scene;
			mEntity = entity;
			mTrack = track;
			mTarget = target;
		}

		public override void Evaluate(SequenceStep step)
		{
			if (!mScene.IsValid(mEntity))
				return;
			if (!mChanged)
			{
				mOriginal = TrackTargets.Read(mScene, mTarget, mEntity);
				mChanged = true;
			}
			TrackTargets.Apply(mScene, mTarget, mEntity, mTrack, step.Time);
		}

		public override void Release(bool restore)
		{
			if (restore && mChanged && mOriginal.HasValue && mScene.IsValid(mEntity))
				TrackTargets.Write(mScene, mTarget, mEntity, mOriginal);
			mChanged = false;
		}
	}
}

/// A named event at a time, with a text value (a cue the game hears).
class SequenceEventKey
{
	public float Time = 0.0f;
	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;

	public this() {}

	public this(float time, StringView name, StringView value = "")
	{
		Time = time;
		Name.Set(name);
		Value.Set(value);
	}
}

/// Events at times, reported to the play's listener with the track's entity when it is bound.
/// Fired only when played through: never on a seek, a scrub or in the editor's preview.
[DisplayName("Event")]
class EventSequenceTrack : SequenceTrack
{
	/// By time.
	public List<SequenceEventKey> Keys = new .() ~ DeleteContainerAndItems!(_);

	public override float Duration
	{
		get
		{
			float last = 0.0f;
			for (let key in Keys)
				last = Math.Max(last, key.Time);
			return last;
		}
	}

	public override int32 Order => SequenceTrackOrder.Event;
	public override bool NeedsBinding => false;

	public override SequenceTrackRunner Begin(SequenceTrackContext context) => new EventRunner(this, context.Entity, context.Listener);

	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		let reading = ar.Mode == .Read;
		let times = scope List<float>();
		let names = scope List<String>();
		let values = scope List<String>();
		defer { ClearAndDeleteItems!(names); ClearAndDeleteItems!(values); }
		if (!reading)
		{
			for (let key in Keys)
			{
				times.Add(key.Time);
				names.Add(new .(key.Name));
				values.Add(new .(key.Value));
			}
		}
		ar.Key("keyTime");
		SerializeList(ar, times);
		ar.Key("keyName");
		SerializeList(ar, names);
		ar.Key("keyValue");
		SerializeList(ar, values);
		if (reading)
		{
			ClearAndDeleteItems!(Keys);
			for (int i < Math.Min(times.Count, Math.Min(names.Count, values.Count)))
				Keys.Add(new .(times[i], names[i], values[i]));
		}
	}

	/// Reports each key the playhead passes while playing.
	private class EventRunner : SequenceTrackRunner
	{
		/// BORROWED, both.
		private EventSequenceTrack mTrack;
		private ISequenceListener mListener;
		private EntityHandle mEntity;

		public this(EventSequenceTrack track, EntityHandle entity, ISequenceListener listener)
		{
			mTrack = track;
			mEntity = entity;
			mListener = listener;
		}

		public override void Evaluate(SequenceStep step)
		{
			if (step.Jumped || step.Preview || (mListener == null))
				return;
			for (let key in mTrack.Keys)
			{
				if ((key.Time > step.PreviousTime) && (key.Time <= step.Time))
					mListener.OnSequenceEvent(mEntity, key.Name, key.Value);
			}
		}

		public override void Release(bool restore)
		{
		}
	}
}
