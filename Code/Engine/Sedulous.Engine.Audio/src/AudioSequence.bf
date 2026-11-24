using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Engine.Audio;

/// One sound on a sound track's timeline.
struct SoundSection
{
	public Ref<AudioClip> Clip = .(Guid());
	/// On the sequence's timeline.
	public float Start = 0.0f;
	/// 0: the clip once from its offset.
	public float Length = 0.0f;
	/// Into the clip, where the section starts it.
	public float Offset = 0.0f;
	public float Volume = 1.0f;
	public AudioBus Bus = .Effects;
	/// Repeat the clip over the section.
	public bool Loop = false;

	public this() {}

	/// The section's length on the timeline: Length, or the clip once from its offset.
	public float SectionLength
	{
		get
		{
			if (Length > 0.0f)
				return Length;
			let loaded = Clip.Get;
			return (loaded != null) ? Math.Max(0.0f, loaded.DurationSeconds - Offset) : 0.0f;
		}
	}
}

/// Plays sounds over the sequence, a section at a time (of two overlapping, the later one), each
/// a voice in the scene's group: at the bound entity, spatial, when the track is bound; flat when
/// not. A section entered part way starts its voice at that point, a voice that drifts from the
/// playhead is moved back to it, and a jump moves it at once; the voice pauses with the play, and
/// plays on at a hold (a line of dialogue finishes while the game waits).
[DisplayName("Sound")]
class SoundSequenceTrack : SequenceTrack
{
	/// With properties and animation, before cameras and events.
	public const int32 cOrder = 200;
	/// How far a voice may wander from the playhead before it is moved back (a streamed clip
	/// seeks only to a block, so it is wider than a frame).
	public const float cDriftSeconds = 0.1f;

	/// By start.
	public List<SoundSection> Sections = new .() ~ delete _;

	public override float Duration
	{
		get
		{
			var last = 0.0f;
			for (let section in Sections)
				last = Math.Max(last, section.Start + section.SectionLength);
			return last;
		}
	}

	public override int32 Order => cOrder;
	public override bool NeedsBinding => false;

	/// The section running at `time` (its end included); -1 between sections.
	public int SectionAt(float time)
	{
		var found = -1;
		for (int i < Sections.Count)
		{
			let section = Sections[i];
			if ((time >= section.Start) && (time <= section.Start + section.SectionLength) &&
				((found < 0) || (section.Start >= Sections[found].Start)))
				found = i;
		}
		return found;
	}

	public override SequenceTrackRunner Begin(SequenceTrackContext context) => new SoundRunner(this, context.Scene, context.Entity);

	public override void ResolveResources(ResourceManager manager)
	{
		for (var section in ref Sections)
			section.Clip.Bind(manager);
	}

	/// The sections as parallel lists. A damaged record (lists of different lengths) reads as no
	/// sections rather than wrong ones.
	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		let reading = ar.Mode == .Read;
		let clips = scope List<Guid>();
		let starts = scope List<float>();
		let lengths = scope List<float>();
		let offsets = scope List<float>();
		let volumes = scope List<float>();
		let buses = scope List<uint8>();
		let loops = scope List<uint8>();
		if (!reading)
		{
			for (let section in Sections)
			{
				clips.Add(section.Clip.Id);
				starts.Add(section.Start);
				lengths.Add(section.Length);
				offsets.Add(section.Offset);
				volumes.Add(section.Volume);
				buses.Add((uint8)section.Bus);
				loops.Add(section.Loop ? 1 : 0);
			}
		}
		ar.Key("sectionClip");
		SerializeList(ar, clips);
		ar.Key("sectionStart");
		SerializeList(ar, starts);
		ar.Key("sectionLength");
		SerializeList(ar, lengths);
		ar.Key("sectionOffset");
		SerializeList(ar, offsets);
		ar.Key("sectionVolume");
		SerializeList(ar, volumes);
		ar.Key("sectionBus");
		SerializeList(ar, buses);
		ar.Key("sectionLoop");
		SerializeList(ar, loops);
		if (!reading)
			return;
		Sections.Clear();
		let count = clips.Count;
		if ((starts.Count < count) || (lengths.Count < count) || (offsets.Count < count) || (volumes.Count < count) ||
			(buses.Count < count) || (loops.Count < count))
			return;
		for (int i < count)
		{
			var section = SoundSection();
			section.Clip.SetId(clips[i]);
			section.Start = starts[i];
			section.Length = lengths[i];
			section.Offset = offsets[i];
			section.Volume = volumes[i];
			section.Bus = (buses[i] < (uint8)AudioBus.Count) ? (AudioBus)buses[i] : .Effects;
			section.Loop = loops[i] != 0;
			Sections.Add(section);
		}
	}

	/// Keeps one voice on the playhead while a section runs; stops it between sections and when
	/// the play lets go.
	private class SoundRunner : SequenceTrackRunner
	{
		/// BORROWED, all three.
		private SoundSequenceTrack mTrack;
		private Sedulous.Scene.Scene mScene;
		/// The engine the voice is on.
		private AudioEngine mEngine = null;
		private EntityHandle mEntity;
		private VoiceHandle mVoice = .();
		/// Whose voice it is; -1: none.
		private int mSection = -1;

		public this(SoundSequenceTrack track, Sedulous.Scene.Scene scene, EntityHandle entity)
		{
			mTrack = track;
			mScene = scene;
			mEntity = entity;
		}

		public override void Evaluate(SequenceStep step)
		{
			let audio = mScene.GetSystem<AudioSceneSystem>();
			let engine = (audio != null) ? audio.Engine : null;
			// No scene audio, or the editor posing: silence.
			if ((engine == null) || (audio.SceneGroup == 0) || step.Preview)
			{
				StopVoice();
				return;
			}
			let index = mTrack.SectionAt(step.Time);
			let clip = (index >= 0) ? mTrack.Sections[index].Clip.Get : null;
			if (clip == null)
			{
				StopVoice();
				mSection = -1;
				return;
			}
			let section = mTrack.Sections[index];
			// Where in the clip the playhead says the voice is; past the end of a clip played
			// once, nothing more to hear.
			var expected = section.Offset + (step.Time - section.Start);
			let clipSeconds = clip.DurationSeconds;
			if (section.Loop && (clipSeconds > 0.0f))
				expected -= Math.Floor(expected / clipSeconds) * clipSeconds;
			let audible = section.Loop || (expected < clipSeconds);
			mEngine = engine;
			if (index != mSection)
			{
				StopVoice();
				mSection = index;
				if (audible)
					Start(audio, clip, section, expected);
				return;
			}
			if (!engine.IsValidHandle(mVoice))
			{
				// It played out, or was taken for another: a jump back into the clip brings it
				// back; plain play does not repeat it.
				if (step.Jumped && audible)
					Start(audio, clip, section, expected);
				return;
			}
			// Ending on its own.
			if (!audible)
				return;
			if (engine.GetVoiceStatus(mVoice, let status) &&
				(step.Jumped || (Math.Abs(status.CursorSeconds - expected) > cDriftSeconds)))
				engine.SeekVoice(mVoice, expected);
			if (mEntity.IsAssigned && mScene.IsValid(mEntity))
				engine.SetVoicePosition(mVoice, EntityPosition(), .(0, 0, 0));
		}

		/// A sound: nothing to put back, whatever `restore` asks.
		public override void Release(bool restore)
		{
			StopVoice();
			mSection = -1;
		}

		public override void SetPaused(bool paused)
		{
			if ((mEngine != null) && mEngine.IsValidHandle(mVoice))
				mEngine.SetPaused(mVoice, paused);
		}

		private void Start(AudioSceneSystem audio, AudioClip clip, SoundSection section, float at)
		{
			var parameters = AudioPlayParams();
			parameters.Bus = section.Bus;
			parameters.Volume = section.Volume;
			parameters.Loop = section.Loop;
			parameters.SceneGroup = audio.SceneGroup;
			// A timeline's sound is its own, never merged.
			parameters.AllowDedupe = false;
			parameters.StartSeconds = at;
			if (mEntity.IsAssigned && mScene.IsValid(mEntity))
			{
				parameters.Spatial = true;
				parameters.Position = EntityPosition();
			}
			mVoice = audio.Engine.Play(clip, parameters);
		}

		private void StopVoice()
		{
			if ((mEngine != null) && mEngine.IsValidHandle(mVoice))
				mEngine.Stop(mVoice);
			mVoice = .();
		}

		private Float3 EntityPosition() => TransformPoint(.(0, 0, 0), mScene.GetWorldMatrix(mEntity));
	}
}

/// The audio's sequence track kinds, as a resource module so every composition that reads
/// sequences with the audio knows them; the sequence libraries know nothing of audio.
static class AudioSequenceTracks
{
	public static ResourceModule Module => sModule ?? (sModule = new .("audio.sequence", () => Register(), null));
	private static ResourceModule sModule ~ delete _;

	/// Idempotent; call before reading a sequence that may hold one.
	public static void Register()
	{
		SequenceTracks.RegisterTypes();
		SequenceTracks.Register<SoundSequenceTrack>();
	}
}
