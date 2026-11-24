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

/// What the track kinds' key edits share. A kind's keys are its own type, so the move sorts their
/// times and says the order; the kind puts its keys in it.
static class SequenceKeys
{
	/// The keys at `indices` of keys timed `times` (sorted) moved by `delta`, never before 0, then
	/// sorted again (a moved key keeps its place among equals): `times` becomes the new times in
	/// order, `order` the old index of the key now at each place, and `moved` each moved key's new
	/// index, in the order of `indices`.
	public static void MoveInTime(List<float> times, Span<int> indices, float delta, List<int> order, List<int> moved)
	{
		order.Clear();
		for (int i < times.Count)
		{
			order.Add(i);
			for (let at in indices)
			{
				if (at == i)
					times[i] = Math.Max(0.0f, times[i] + delta);
			}
		}
		// Insertion sort: stable, and the keys are few.
		for (int i = 1; i < order.Count; i++)
		{
			let index = order[i];
			var j = i;
			while ((j > 0) && (times[order[j - 1]] > times[index]))
			{
				order[j] = order[j - 1];
				j--;
			}
			order[j] = index;
		}
		let sorted = scope List<float>(times.Count);
		for (let index in order)
			sorted.Add(times[index]);
		times.Clear();
		times.AddRange(sorted);
		moved.Clear();
		for (let at in indices)
		{
			for (int i < order.Count)
			{
				if (order[i] == at)
					moved.Add(i);
			}
		}
	}

	/// `keys` put in `order` (the old index of the key at each place).
	public static void Reorder<T>(List<T> keys, List<int> order)
	{
		let old = scope List<T>(keys.Count);
		old.AddRange(keys);
		for (int i < order.Count)
			keys[i] = old[order[i]];
	}

	/// Whether `index` is among `indices`.
	public static bool Contains(Span<int> indices, int index)
	{
		for (let at in indices)
		{
			if (at == index)
				return true;
		}
		return false;
	}

	/// The index of the key at `time` among `times`; -1 when none.
	public static int IndexAt(List<float> times, float time)
	{
		for (int i < times.Count)
		{
			if (Math.Abs(times[i] - time) < 1e-5f)
				return i;
		}
		return -1;
	}
}

/// The base of every track kind. What an author sets on a track shows in the editor's inspector:
/// its name and muted flag here, a kind's own fields after them (reflected); the binding is the
/// panel's. A kind adds its keys or sections, serializes them after the
/// base's fields, and makes a runner for each play. A kind is registered (SequenceTracks.Register),
/// so a sequence holding it reads and whatever lists the kinds (the editor's add-track menu) finds
/// it, with no list anywhere to edit.
[Reflect(.All)]
abstract class SequenceTrack : ISerializable
{
	/// Shown in the editor.
	[DisplayName("Name")]
	public String Name = new .() ~ delete _;
	/// Index into the sequence's bindings; -1: bound to no one.
	[Hidden]
	public int32 Binding = -1;
	[DisplayName("Muted")]
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

	// === Editing, whatever the kind (the editor's panel and its tools) ===
	// A kind shows what it holds as key channels (a property's x, y and z; an event track's events;
	// a fade's amount) or as sections (a clip, a sound, a shot). Keys stay sorted by time in each
	// channel; a move says where each moved key went. A kind holding neither keeps the defaults.

	public virtual int KeyChannelCount => 0;
	/// The channel's name under the track ("x", "events", "amount"), appended to `outName`.
	public virtual void GetKeyChannelName(int channel, String outName) {}
	/// Its key times, sorted, into `outTimes` (emptied first).
	public virtual void GetKeyTimes(int channel, List<float> outTimes) { outTimes.Clear(); }
	/// Moves the keys at `keys` (indices in the channel) by `delta` seconds, never before 0, sorts
	/// the channel again and fills `moved` with each one's new index, in order.
	public virtual void MoveKeys(int channel, Span<int> keys, float delta, List<int> moved) { moved.Clear(); }
	public virtual void DeleteKeys(int channel, Span<int> keys) {}
	/// Adds a key at `time` holding the channel's value there (or a new key's default); its index,
	/// or -1 when the channel takes none.
	public virtual int InsertKey(int channel, float time) => -1;
	/// The channel's keys as a curve, when they are one (a property's part, a fade's amount): the
	/// editor's curve view edits it. BORROWED; null otherwise.
	public virtual Curve KeyCurve(int channel) => null;

	public virtual int SectionCount => 0;
	/// The section's span, and what its bar says appended to `outLabel`.
	public virtual void GetSection(int index, out float start, out float length, String outLabel)
	{
		start = 0.0f;
		length = 0.0f;
	}
	/// Sets the section's span. A start moved later trims what it plays from (a clip's or a sound's
	/// offset moves with it), so what plays stays where it was.
	public virtual void SetSection(int index, float start, float length) {}
	public virtual void RemoveSection(int index) {}
	/// Adds a section at `time` (what it plays is chosen in the inspector); its index, or -1 when
	/// the kind takes no more.
	public virtual int AddSection(float time) => -1;

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
[Reflect(.All)]
class PropertySequenceTrack : SequenceTrack
{
	/// Edited in the panel (its keys, its curves), not the inspector.
	[Hidden]
	public PropertyTrack Property = new .() ~ delete _;

	public override float Duration => Property.Duration;
	public override int32 Order => SequenceTrackOrder.Property;

	// === Editing: a channel per curve (x, y, z; r, g, b, a), or the rotation's keys ===

	private bool IsRotation => Property.Kind == .Quat;

	public override int KeyChannelCount => IsRotation ? 1 : (int)Property.Kind.ChannelCount;

	public override void GetKeyChannelName(int channel, String outName)
	{
		switch (Property.Kind)
		{
		case .Float3: if (channel < 3) outName.Append("xyz"[channel]);
		case .Color: if (channel < 4) outName.Append("rgba"[channel]);
		case .Quat: outName.Append("rotation");
		default: outName.Append("value");
		}
	}

	public override void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		if (IsRotation)
		{
			for (let key in Property.QuatKeys)
				outTimes.Add(key.Time);
		}
		else if (channel < KeyChannelCount)
		{
			for (let key in Property.Channels[channel].Keys)
				outTimes.Add(key.Time);
		}
	}

	public override void MoveKeys(int channel, Span<int> keys, float delta, List<int> moved)
	{
		moved.Clear();
		if (!IsRotation && (channel >= KeyChannelCount))
			return;
		let times = scope List<float>();
		GetKeyTimes(channel, times);
		let order = scope List<int>();
		SequenceKeys.MoveInTime(times, keys, delta, order, moved);
		if (IsRotation)
		{
			SequenceKeys.Reorder(Property.QuatKeys, order);
			for (int i < times.Count)
				Property.QuatKeys[i].Time = times[i];
			return;
		}
		let curve = Property.Channels[channel];
		SequenceKeys.Reorder(curve.Keys, order);
		for (int i < times.Count)
			curve.Keys[i].Time = times[i];
		curve.ApplyTangentModes();
	}

	public override void DeleteKeys(int channel, Span<int> keys)
	{
		if (IsRotation)
		{
			for (int i = Property.QuatKeys.Count - 1; i >= 0; i--)
			{
				if (SequenceKeys.Contains(keys, i))
					Property.QuatKeys.RemoveAt(i);
			}
			return;
		}
		if (channel >= KeyChannelCount)
			return;
		let curve = Property.Channels[channel];
		for (int i = curve.Keys.Count - 1; i >= 0; i--)
		{
			if (SequenceKeys.Contains(keys, i))
				curve.Keys.RemoveAt(i);
		}
		curve.ApplyTangentModes();
	}

	public override int InsertKey(int channel, float time)
	{
		let at = Math.Max(0.0f, time);
		if (IsRotation)
		{
			let value = Property.QuatKeys.IsEmpty ? Quaternion.Identity : Property.SampleQuat(at);
			int index = 0;
			while ((index < Property.QuatKeys.Count) && (Property.QuatKeys[index].Time < at))
				index++;
			var key = QuatKey();
			key.Time = at;
			key.Value = value;
			Property.QuatKeys.Insert(index, key);
			return index;
		}
		if (channel >= KeyChannelCount)
			return -1;
		let curve = Property.Channels[channel];
		let times = scope List<float>();
		GetKeyTimes(channel, times);
		let existing = SequenceKeys.IndexAt(times, at);
		// A key is already there.
		if (existing >= 0)
			return existing;
		var key = CurveKey(at, curve.IsEmpty ? 0.0f : curve.Evaluate(at), .Cubic);
		key.TangentMode = .Auto;
		curve.AddKey(key);
		curve.ApplyTangentModes();
		GetKeyTimes(channel, times);
		return SequenceKeys.IndexAt(times, at);
	}

	public override Curve KeyCurve(int channel) => (!IsRotation && (channel < KeyChannelCount)) ? Property.Channels[channel] : null;

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
[Reflect(.All)]
class SequenceEventKey
{
	[DisplayName("Time")]
	public float Time = 0.0f;
	[DisplayName("Name")]
	public String Name = new .() ~ delete _;
	[DisplayName("Value")]
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
[Reflect(.All)]
class EventSequenceTrack : SequenceTrack
{
	/// By time.
	[DisplayName("Events")]
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

	// === Editing: one channel of events ===

	public override int KeyChannelCount => 1;

	public override void GetKeyChannelName(int channel, String outName) => outName.Append("events");

	public override void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		for (let key in Keys)
			outTimes.Add(key.Time);
	}

	public override void MoveKeys(int channel, Span<int> keys, float delta, List<int> moved)
	{
		let times = scope List<float>();
		GetKeyTimes(channel, times);
		let order = scope List<int>();
		SequenceKeys.MoveInTime(times, keys, delta, order, moved);
		SequenceKeys.Reorder(Keys, order);
		for (int i < times.Count)
			Keys[i].Time = times[i];
	}

	public override void DeleteKeys(int channel, Span<int> keys)
	{
		for (int i = Keys.Count - 1; i >= 0; i--)
		{
			if (!SequenceKeys.Contains(keys, i))
				continue;
			delete Keys[i];
			Keys.RemoveAt(i);
		}
	}

	/// A new event is named "event", with no value: the inspector names it.
	public override int InsertKey(int channel, float time)
	{
		let at = Math.Max(0.0f, time);
		int index = 0;
		while ((index < Keys.Count) && (Keys[index].Time <= at))
			index++;
		Keys.Insert(index, new .(at, "event"));
		return index;
	}
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
