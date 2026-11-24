using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Engine.Render;

/// A span of a camera cut track's timeline: its camera is the view from Start for Duration
/// seconds.
struct CameraCutSection
{
	public float Start;
	public float Duration;

	public this(float start, float duration)
	{
		Start = start;
		Duration = duration;
	}
}

/// Cuts the scene's view to the bound camera for each of its sections; between sections, and once
/// the play lets go, the view goes back to whoever had it. A claim on the CameraComponentManager,
/// which the camera pick reads before the primary camera. The camera knows nothing of it; the
/// render starts the view's history fresh when the camera it is drawn from changes.
[DisplayName("Camera Cut")]
class CameraCutSequenceTrack : SequenceTrack
{
	/// After properties (a camera's own transform keys) and animation, before events.
	public const int32 cOrder = 500;

	/// By start.
	public List<CameraCutSection> Sections = new .() ~ delete _;

	public override float Duration
	{
		get
		{
			var last = 0.0f;
			for (let section in Sections)
				last = Math.Max(last, section.Start + section.Duration);
			return last;
		}
	}

	public override int32 Order => cOrder;

	// === Editing: each shot a section ===

	public override int SectionCount => Sections.Count;

	public override void GetSection(int index, out float start, out float length, String outLabel)
	{
		start = (index < Sections.Count) ? Sections[index].Start : 0.0f;
		length = (index < Sections.Count) ? Sections[index].Duration : 0.0f;
		outLabel.Append(Name.IsEmpty ? "Shot" : Name);
	}

	public override void SetSection(int index, float start, float length)
	{
		if (index < Sections.Count)
			Sections[index] = .(Math.Max(0.0f, start), Math.Max(0.0f, length));
	}

	public override void RemoveSection(int index)
	{
		if (index < Sections.Count)
			Sections.RemoveAt(index);
	}

	/// A second's shot at `time`.
	public override int AddSection(float time)
	{
		int at = 0;
		while ((at < Sections.Count) && (Sections[at].Start <= time))
			at++;
		Sections.Insert(at, CameraCutSection(Math.Max(0.0f, time), 1.0f));
		return at;
	}

	/// Whether a section runs at `time`: its end included, so a play that ends on a cut and holds
	/// keeps it.
	public bool CutsAt(float time)
	{
		for (let section in Sections)
		{
			if ((time >= section.Start) && (time <= section.Start + section.Duration))
				return true;
		}
		return false;
	}

	public override SequenceTrackRunner Begin(SequenceTrackContext context)
	{
		let cameras = context.Scene.GetSystem<CameraComponentManager>();
		if ((cameras == null) || !cameras.Has(context.Entity))
		{
			GlobalLog(.Warning, "Sequence: camera cut track '{}' is bound to an entity with no camera - skipped", Name);
			return null;
		}
		return new CameraCutRunner(this, cameras, context.Entity, context.Play);
	}

	/// The sections as parallel lists (start, duration).
	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		let reading = ar.Mode == .Read;
		let starts = scope List<float>();
		let durations = scope List<float>();
		if (!reading)
		{
			for (let section in Sections)
			{
				starts.Add(section.Start);
				durations.Add(section.Duration);
			}
		}
		ar.Key("sectionStart");
		SerializeList(ar, starts);
		ar.Key("sectionDuration");
		SerializeList(ar, durations);
		if (reading)
		{
			Sections.Clear();
			for (int i < Math.Min(starts.Count, durations.Count))
				Sections.Add(.(starts[i], durations[i]));
		}
	}

	/// Holds the view while a section runs, and lets go between sections and at the end.
	private class CameraCutRunner : SequenceTrackRunner
	{
		/// BORROWED, all three.
		private CameraCutSequenceTrack mTrack;
		private CameraComponentManager mCameras;
		private SequencePlay mPlay;
		private EntityHandle mCamera;
		private bool mClaiming = false;

		public this(CameraCutSequenceTrack track, CameraComponentManager cameras, EntityHandle camera, SequencePlay play)
		{
			mTrack = track;
			mCameras = cameras;
			mCamera = camera;
			mPlay = play;
		}

		public override void Evaluate(SequenceStep step)
		{
			if (mTrack.CutsAt(step.Time))
			{
				if (!mClaiming)
				{
					mCameras.ViewClaims.Claim(this, (mPlay != null) ? mPlay.StartOrder : 0, mCamera);
					mClaiming = true;
				}
			}
			else if (mClaiming)
			{
				mCameras.ViewClaims.Release(this);
				mClaiming = false;
			}
		}

		/// The view is a claim: nothing to put back, whatever `restore` asks.
		public override void Release(bool restore)
		{
			if (!mClaiming)
				return;
			mCameras.ViewClaims.Release(this);
			mClaiming = false;
		}
	}
}

/// Fades the scene's view to Color by Amount (keys, 0 none to 1 all) for as long as the play runs:
/// from its first step to its release, the last key's amount holding after it. A claim on the
/// scene's PostProcessSystem, which the tonemap mixes over the graded image, under the HUD, so a
/// fade to black keeps the subtitles. Bound to no one.
[DisplayName("Fade")]
class FadeSequenceTrack : SequenceTrack
{
	/// After the camera cuts, before events.
	public const int32 cOrder = 600;

	public Curve Amount = new .() ~ delete _;
	/// As authored (display values).
	public Color Color = .(0.0f, 0.0f, 0.0f, 1.0f);

	public override float Duration => Amount.Duration;
	public override int32 Order => cOrder;
	public override bool NeedsBinding => false;

	// === Editing: the amount, one curve channel ===

	public override int KeyChannelCount => 1;

	public override void GetKeyChannelName(int channel, String outName) => outName.Append("amount");

	public override void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		for (let key in Amount.Keys)
			outTimes.Add(key.Time);
	}

	public override void MoveKeys(int channel, Span<int> keys, float delta, List<int> moved)
	{
		let times = scope List<float>();
		GetKeyTimes(channel, times);
		let order = scope List<int>();
		SequenceKeys.MoveInTime(times, keys, delta, order, moved);
		SequenceKeys.Reorder(Amount.Keys, order);
		for (int i < times.Count)
			Amount.Keys[i].Time = times[i];
		Amount.ApplyTangentModes();
	}

	public override void DeleteKeys(int channel, Span<int> keys)
	{
		for (int i = Amount.Keys.Count - 1; i >= 0; i--)
		{
			if (SequenceKeys.Contains(keys, i))
				Amount.Keys.RemoveAt(i);
		}
		Amount.ApplyTangentModes();
	}

	public override int InsertKey(int channel, float time)
	{
		let at = Math.Max(0.0f, time);
		let times = scope List<float>();
		GetKeyTimes(channel, times);
		let existing = SequenceKeys.IndexAt(times, at);
		if (existing >= 0)
			return existing;
		var key = CurveKey(at, Amount.IsEmpty ? 0.0f : Math.Clamp(Amount.Evaluate(at), 0.0f, 1.0f), .Linear);
		key.TangentMode = .Auto;
		Amount.AddKey(key);
		Amount.ApplyTangentModes();
		GetKeyTimes(channel, times);
		return SequenceKeys.IndexAt(times, at);
	}

	public override Curve KeyCurve(int channel) => Amount;

	public override SequenceTrackRunner Begin(SequenceTrackContext context)
	{
		let post = context.Scene.GetSystem<PostProcessSystem>();
		if (post == null)
			return null; // a scene nothing renders: no view to fade
		return new FadeRunner(this, post, context.Play);
	}

	/// The colour, then the amount's keys as parallel lists.
	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		SerializeValue(ar, "color", ref Color);
		let reading = ar.Mode == .Read;
		let times = scope List<float>();
		let values = scope List<float>();
		let tangentsIn = scope List<float>();
		let tangentsOut = scope List<float>();
		let interpolations = scope List<uint8>();
		let tangentModes = scope List<uint8>();
		if (!reading)
		{
			for (let key in Amount.Keys)
			{
				times.Add(key.Time);
				values.Add(key.Value);
				tangentsIn.Add(key.TangentIn);
				tangentsOut.Add(key.TangentOut);
				interpolations.Add((uint8)key.Interpolation);
				tangentModes.Add((uint8)key.TangentMode);
			}
		}
		ar.Key("keyTime");
		SerializeList(ar, times);
		ar.Key("keyValue");
		SerializeList(ar, values);
		ar.Key("keyTangentIn");
		SerializeList(ar, tangentsIn);
		ar.Key("keyTangentOut");
		SerializeList(ar, tangentsOut);
		ar.Key("keyInterpolation");
		SerializeList(ar, interpolations);
		ar.Key("keyTangentMode");
		SerializeList(ar, tangentModes);
		if (reading)
		{
			Amount.Clear();
			let count = Math.Min(Math.Min(times.Count, values.Count), Math.Min(tangentsIn.Count, tangentsOut.Count));
			for (int i < count)
			{
				var key = CurveKey();
				key.Time = times[i];
				key.Value = values[i];
				key.TangentIn = tangentsIn[i];
				key.TangentOut = tangentsOut[i];
				if (i < interpolations.Count)
					key.Interpolation = (CurveKeyInterpolation)interpolations[i];
				if (i < tangentModes.Count)
					key.TangentMode = (CurveTangentMode)tangentModes[i];
				Amount.AddKey(key);
			}
		}
	}

	/// Holds the fade from the play's first step until it lets go, at the amount the keys give.
	private class FadeRunner : SequenceTrackRunner
	{
		/// BORROWED, all three.
		private FadeSequenceTrack mTrack;
		private PostProcessSystem mPost;
		private SequencePlay mPlay;

		public this(FadeSequenceTrack track, PostProcessSystem post, SequencePlay play)
		{
			mTrack = track;
			mPost = post;
			mPlay = play;
		}

		public override void Evaluate(SequenceStep step)
		{
			let fade = ScreenFade(mTrack.Color, Math.Clamp(mTrack.Amount.Evaluate(step.Time), 0.0f, 1.0f));
			mPost.FadeClaims.Claim(this, (mPlay != null) ? mPlay.StartOrder : 0, fade);
		}

		/// The fade is a claim: nothing to put back, whatever `restore` asks.
		public override void Release(bool restore)
		{
			mPost.FadeClaims.Release(this);
		}
	}
}

/// The render's sequence track kinds, as a resource module so every composition that reads
/// sequences with the render knows them; the sequence libraries know nothing of rendering.
static class RenderSequenceTracks
{
	public static ResourceModule Module => sModule ?? (sModule = new .("render.sequence", () => Register(), null));
	private static ResourceModule sModule ~ delete _;

	/// Idempotent; call before reading a sequence that may hold one.
	public static void Register()
	{
		SequenceTracks.RegisterTypes();
		SequenceTracks.Register<CameraCutSequenceTrack>();
		SequenceTracks.Register<FadeSequenceTrack>();
	}
}
