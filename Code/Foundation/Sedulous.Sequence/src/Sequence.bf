using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Sequence;

/// A named point on a sequence's timeline. A hold stops the playhead there until the play is
/// resumed (a line of dialogue waiting for a press).
class SequenceMarker
{
	public float Time = 0.0f;
	public String Name = new .() ~ delete _;
	public bool Hold = false;

	public this() {}

	public this(float time, StringView name, bool hold)
	{
		Time = time;
		Name.Set(name);
		Hold = hold;
	}
}

/// One name in a sequence's cast ("Mentor", "Camera"). Whoever starts a play fills it with an
/// entity; tracks refer to it by its index.
class SequenceBinding
{
	public String Name = new .() ~ delete _;

	public this() {}

	public this(StringView name)
	{
		Name.Set(name);
	}
}

/// A timeline that drives several entities at once: tracks of keys or sections, each bound by
/// name to one of the sequence's cast, and markers, some of which hold the playhead until the game
/// says go on. Authored or cooked; shared, unchanged, by every play of it.
class Sequence
{
	public float Duration = 0.0f;
	/// The editor's snapping and display only; evaluation is continuous.
	public float FrameRate = 30.0f;
	public List<SequenceBinding> Bindings = new .() ~ DeleteContainerAndItems!(_);
	public List<SequenceTrack> Tracks = new .() ~ DeleteContainerAndItems!(_);
	/// By time.
	public List<SequenceMarker> Markers = new .() ~ DeleteContainerAndItems!(_);

	/// The binding named `name`, or -1.
	public int32 FindBinding(StringView name)
	{
		for (int i < Bindings.Count)
		{
			if (Bindings[i].Name == name)
				return (int32)i;
		}
		return -1;
	}

	/// The longest of its tracks and its last marker.
	public float ComputeDuration()
	{
		float d = 0.0f;
		for (let track in Tracks)
		{
			if (track != null)
				d = Math.Max(d, track.Duration);
		}
		for (let marker in Markers)
			d = Math.Max(d, marker.Time);
		return d;
	}

	/// Reads or writes the sequence: its duration, frame rate, bindings, markers, and each track as
	/// its kind's type name followed by its fields. A track kind this build cannot make fails the
	/// payload: its fields cannot be skipped, and reading on would read out of step.
	public void Serialize(ISerializer ar)
	{
		let reading = ar.Mode == .Read;
		SerializeValue(ar, "duration", ref Duration);
		SerializeValue(ar, "frameRate", ref FrameRate);

		let bindingNames = scope List<String>();
		let markerTime = scope List<float>();
		let markerName = scope List<String>();
		let markerHold = scope List<uint8>();
		defer { ClearAndDeleteItems!(bindingNames); ClearAndDeleteItems!(markerName); }
		if (!reading)
		{
			for (let binding in Bindings)
				bindingNames.Add(new .(binding.Name));
			for (let marker in Markers)
			{
				markerTime.Add(marker.Time);
				markerName.Add(new .(marker.Name));
				markerHold.Add(marker.Hold ? 1 : 0);
			}
		}
		ar.Key("bindings");
		SerializeList(ar, bindingNames);
		ar.Key("markerTime");
		SerializeList(ar, markerTime);
		ar.Key("markerName");
		SerializeList(ar, markerName);
		ar.Key("markerHold");
		SerializeList(ar, markerHold);
		if (reading)
		{
			ClearAndDeleteItems!(Bindings);
			for (let name in bindingNames)
				Bindings.Add(new .(name));
			ClearAndDeleteItems!(Markers);
			for (int i < Math.Min(markerTime.Count, Math.Min(markerName.Count, markerHold.Count)))
				Markers.Add(new .(markerTime[i], markerName[i], markerHold[i] != 0));
		}

		uint32 count = reading ? 0 : (uint32)Tracks.Count;
		ar.Key("tracks");
		ar.BeginArray(ref count);
		if (reading)
			ClearAndDeleteItems!(Tracks);
		let typeName = scope String();
		for (uint32 i < count)
		{
			ar.BeginObject();
			SequenceTrack track = reading ? null : Tracks[(int)i];
			typeName.Clear();
			if (!reading)
				track.GetType().GetFullName(typeName);
			Sedulous.Core.Serialization.Serialize(ar, "type", typeName);
			if (reading)
			{
				// The registry hands ownership over: a type that makes something other than a
				// track is freed here.
				let made = (Object)GlobalSerializableRegistry.Create(TypeIdOf(typeName));
				track = made as SequenceTrack;
				if ((made != null) && (track == null))
					delete made;
				if (track == null)
				{
					// A kind this build cannot make: its fields cannot be skipped, so the whole
					// payload is refused rather than read out of step.
					ar.FailPayload(.NotSupported);
					ar.EndObject();
					break;
				}
			}
			track.Serialize(ar);
			ar.EndObject();
			if (reading)
			{
				// A binding index outside the cast is bound to no one.
				if (track.Binding >= (int32)Bindings.Count)
					track.Binding = -1;
				Tracks.Add(track);
			}
		}
		ar.EndArray();
	}
}

/// How a play ends when it reaches the end. Its cases reflected, so an inspector and the scene
/// format reference name them.
[Reflect(.StaticFields)]
enum SequenceFinish
{
	/// Let go of side effects (camera, sounds, fades); what moved stays where it is.
	Release,
	/// Keep everything as the last frame left it, until Stop.
	Hold,
	/// Put every value back as it was before the play, and let go.
	Restore
}

/// The track kinds: each registered with the serializable registry (so a sequence that holds it
/// reads) and listed (so the editor's add-track menu offers it). A domain, a plugin or a game adds
/// its own with Register; nothing keeps a list to edit.
static class SequenceTracks
{
	private static List<Type> sKinds = new .() ~ delete _;

	/// Registers a track kind. Idempotent. Its reader is registered each time, so a kind whose
	/// reader a plugin host took back (its plugin unloaded) reads again when it registers again.
	public static void Register<T>() where T : SequenceTrack, new, delete
	{
		let type = typeof(T);
		if (!sKinds.Contains(type))
			sKinds.Add(type);
		GlobalSerializableRegistry.Register(TypeIdOf(type.GetFullName(.. scope .())), () => new T());
	}

	/// Takes a track kind back (a plugin unloading): out of the list the editor offers, and its
	/// reader out of the registry.
	public static void Unregister<T>() where T : SequenceTrack
	{
		let type = typeof(T);
		sKinds.Remove(type);
		GlobalSerializableRegistry.Unregister(TypeIdOf(type.GetFullName(.. scope .())));
	}

	/// The kinds here: property and event tracks. Idempotent; call before reading a sequence.
	public static void RegisterTypes()
	{
		Register<PropertySequenceTrack>();
		Register<EventSequenceTrack>();
	}

	/// Every registered track kind.
	public static Span<Type> Kinds => sKinds;
	/// Whether `type` is a registered track kind.
	public static bool IsRegistered(Type type) => sKinds.Contains(type);
}
