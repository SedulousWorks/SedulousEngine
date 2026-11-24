using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Engine.Animation;

/// One clip on a clip track's timeline.
struct ClipSection
{
	public Ref<AnimationClip> Clip = .(Guid());
	/// On the sequence's timeline.
	public float Start = 0.0f;
	/// 0: the clip once from its offset, at its speed.
	public float Length = 0.0f;
	/// Into the clip, where the section starts it.
	public float Offset = 0.0f;
	public float Speed = 1.0f;
	/// Seconds over the pose underneath.
	public float BlendIn = 0.2f;
	/// Seconds back to it before the section ends (0: holds to the end).
	public float BlendOut = 0.2f;
	/// Repeat the clip over the section; otherwise it stays on its last frame.
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
			if ((loaded == null) || (Speed <= 0.0f))
				return 0.0f;
			return Math.Max(0.0f, loaded.Duration - Offset) / Speed;
		}
	}
}

/// Plays skeletal clips on the bound entity over its own pose, a section at a time (of two
/// overlapping, the later one), each blended in and out through the entity's PoseOverlay. The
/// sequence drives the overlay (its clip time and weight each step), so a seek or a scrub lands
/// on the frame; the animation graph or clip underneath keeps running and shows again as a
/// section blends out.
[DisplayName("Clip")]
class ClipSequenceTrack : SequenceTrack
{
	/// After properties (an actor's transform keys), before cameras and events.
	public const int32 cOrder = 100;

	/// By start.
	public List<ClipSection> Sections = new .() ~ delete _;

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

	// === Editing: each clip a section ===

	public override int SectionCount => Sections.Count;

	/// Labelled by its clip's name ("Clip" until one is chosen).
	public override void GetSection(int index, out float start, out float length, String outLabel)
	{
		start = 0.0f;
		length = 0.0f;
		if (index >= Sections.Count)
			return;
		let section = Sections[index];
		start = section.Start;
		length = section.SectionLength;
		let clip = section.Clip.Get;
		outLabel.Append(((clip != null) && !clip.Name.IsEmpty) ? clip.Name : "Clip");
	}

	/// A start moved later moves the clip's offset with it (at its speed), so what plays stays put.
	public override void SetSection(int index, float start, float length)
	{
		if (index >= Sections.Count)
			return;
		var section = ref Sections[index];
		let at = Math.Max(0.0f, start);
		section.Offset = Math.Max(0.0f, section.Offset + (at - section.Start) * section.Speed);
		section.Start = at;
		section.Length = Math.Max(0.0f, length);
	}

	public override void RemoveSection(int index)
	{
		if (index < Sections.Count)
			Sections.RemoveAt(index);
	}

	public override int AddSection(float time)
	{
		int at = 0;
		while ((at < Sections.Count) && (Sections[at].Start <= time))
			at++;
		var section = ClipSection();
		section.Start = Math.Max(0.0f, time);
		section.Length = 1.0f;
		Sections.Insert(at, section);
		return at;
	}

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

	public override SequenceTrackRunner Begin(SequenceTrackContext context) => new ClipRunner(this, context.Scene, context.Entity);

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
		let speeds = scope List<float>();
		let blendIns = scope List<float>();
		let blendOuts = scope List<float>();
		let loops = scope List<uint8>();
		if (!reading)
		{
			for (let section in Sections)
			{
				clips.Add(section.Clip.Id);
				starts.Add(section.Start);
				lengths.Add(section.Length);
				offsets.Add(section.Offset);
				speeds.Add(section.Speed);
				blendIns.Add(section.BlendIn);
				blendOuts.Add(section.BlendOut);
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
		ar.Key("sectionSpeed");
		SerializeList(ar, speeds);
		ar.Key("sectionBlendIn");
		SerializeList(ar, blendIns);
		ar.Key("sectionBlendOut");
		SerializeList(ar, blendOuts);
		ar.Key("sectionLoop");
		SerializeList(ar, loops);
		if (!reading)
			return;
		Sections.Clear();
		let count = clips.Count;
		if ((starts.Count < count) || (lengths.Count < count) || (offsets.Count < count) || (speeds.Count < count) ||
			(blendIns.Count < count) || (blendOuts.Count < count) || (loops.Count < count))
			return;
		for (int i < count)
		{
			var section = ClipSection();
			section.Clip.SetId(clips[i]);
			section.Start = starts[i];
			section.Length = lengths[i];
			section.Offset = offsets[i];
			section.Speed = speeds[i];
			section.BlendIn = blendIns[i];
			section.BlendOut = blendOuts[i];
			section.Loop = loops[i] != 0;
			Sections.Add(section);
		}
	}

	/// Drives the entity's overlay while a section runs; between sections, and when the play lets
	/// go, the overlay blends back to the pose underneath. The overlay is found each step, never
	/// kept: a player is rebuilt when its skeleton changes.
	private class ClipRunner : SequenceTrackRunner
	{
		/// BORROWED, both.
		private ClipSequenceTrack mTrack;
		private Sedulous.Scene.Scene mScene;
		private EntityHandle mEntity;
		/// The section driving the overlay; -1: none.
		private int mSection = -1;

		public this(ClipSequenceTrack track, Sedulous.Scene.Scene scene, EntityHandle entity)
		{
			mTrack = track;
			mScene = scene;
			mEntity = entity;
		}

		public override void Evaluate(SequenceStep step)
		{
			let overlay = AnimationOverlays.Of(mScene, mEntity);
			// No player yet: nothing to show it on.
			if (overlay == null)
				return;
			let index = mTrack.SectionAt(step.Time);
			let clip = (index >= 0) ? mTrack.Sections[index].Clip.Get : null;
			if (clip == null)
			{
				// The section blended itself out.
				if ((mSection >= 0) && overlay.IsDriven)
					overlay.StopOneShot(0.0f);
				mSection = -1;
				return;
			}
			let section = mTrack.Sections[index];
			let local = step.Time - section.Start;
			var clipTime = section.Offset + local * section.Speed;
			if (section.Loop && (clip.Duration > 0.0f))
				clipTime = clipTime - Math.Floor(clipTime / clip.Duration) * clip.Duration;
			else
				clipTime = Math.Min(clipTime, clip.Duration);
			var weight = 1.0f;
			if (section.BlendIn > 0.0f)
				weight = Math.Min(weight, local / section.BlendIn);
			if (section.BlendOut > 0.0f)
				weight = Math.Min(weight, (section.SectionLength - local) / section.BlendOut);
			overlay.DriveOneShot(clip, clipTime, weight);
			mSection = index;
		}

		/// A pose laid over the entity: nothing to put back, whatever `restore` asks. Stopped
		/// mid-section, it eases back over the section's blend out.
		public override void Release(bool restore)
		{
			if (mSection < 0)
				return;
			let overlay = AnimationOverlays.Of(mScene, mEntity);
			if ((overlay != null) && overlay.IsDriven && (mSection < mTrack.Sections.Count))
				overlay.StopOneShot(mTrack.Sections[mSection].BlendOut);
			mSection = -1;
		}
	}
}

/// The overlay over an entity's pose: its animation graph's, else its skeletal animation's.
static class AnimationOverlays
{
	/// Null when it has neither (or its player is not built yet). Ask again rather than keep it: a
	/// player is rebuilt when its skeleton changes.
	public static PoseOverlay Of(Sedulous.Scene.Scene scene, EntityHandle entity)
	{
		if (let graphs = scene.GetSystem<AnimationGraphComponentManager>())
		{
			let component = graphs.Get(entity);
			if ((component != null) && (component.Player != null))
				return component.Player.Overlay;
		}
		if (let skeletal = scene.GetSystem<SkeletalAnimationComponentManager>())
		{
			let component = skeletal.Get(entity);
			if ((component != null) && (component.Player != null))
				return component.Player.Overlay;
		}
		return null;
	}
}

/// The animation's sequence track kinds, as a resource module so every composition that reads
/// sequences with the animation knows them; the sequence libraries know nothing of animation.
static class AnimationSequenceTracks
{
	public static ResourceModule Module => sModule ?? (sModule = new .("animation.sequence", () => Register(), null));
	private static ResourceModule sModule ~ delete _;

	/// Idempotent; call before reading a sequence that may hold one.
	public static void Register()
	{
		SequenceTracks.RegisterTypes();
		SequenceTracks.Register<ClipSequenceTrack>();
	}
}
