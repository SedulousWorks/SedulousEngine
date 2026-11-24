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
					mCameras.ClaimView(this, (mPlay != null) ? mPlay.StartOrder : 0, mCamera);
					mClaiming = true;
				}
			}
			else if (mClaiming)
			{
				mCameras.ReleaseView(this);
				mClaiming = false;
			}
		}

		/// The view is a claim: nothing to put back, whatever `restore` asks.
		public override void Release(bool restore)
		{
			if (!mClaiming)
				return;
			mCameras.ReleaseView(this);
			mClaiming = false;
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
	}
}
