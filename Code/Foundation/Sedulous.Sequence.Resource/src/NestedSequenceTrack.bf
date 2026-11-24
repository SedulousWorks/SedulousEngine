using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Sequence.Resource;

/// Another sequence, played inside this one over a section of its timeline, on the same cast:
/// each of its names is filled by this play's entity of that name. Its events reach this play's
/// listener; its holds are not kept (the outer timeline holds).
[DisplayName("Sequence")]
class NestedSequenceTrack : SequenceTrack
{
	/// The sequence played.
	public Ref<SequenceResource> Nested = .(Guid());
	public float Start = 0.0f;
	/// 0: the nested sequence's own duration.
	public float Length = 0.0f;
	/// Repeat it over the section; otherwise it stays at its end.
	public bool Loop = false;

	public override float Duration => Start + SectionLength;
	public override int32 Order => SequenceTrackOrder.Property;
	public override bool NeedsBinding => false;

	// === Editing: the one section it plays over ===

	public override int SectionCount => 1;

	public override void GetSection(int index, out float start, out float length, String outLabel)
	{
		start = Start;
		length = SectionLength;
		outLabel.Append(Name.IsEmpty ? "Sequence" : Name);
	}

	public override void SetSection(int index, float start, float length)
	{
		Start = Math.Max(0.0f, start);
		Length = Math.Max(0.0f, length);
	}

	/// The section's length: Length, or the nested sequence's duration.
	public float SectionLength
	{
		get
		{
			if (Length > 0.0f)
				return Length;
			let nested = Nested.Get;
			return (nested != null) ? nested.Sequence.Duration : 0.0f;
		}
	}

	public override SequenceTrackRunner Begin(SequenceTrackContext context)
	{
		let nested = Nested.Get;
		if (nested == null)
		{
			GlobalLog(.Warning, "Sequence: track '{}' has no sequence to play - skipped", Name);
			return null;
		}
		// A sequence inside itself, directly or through others, would nest without end.
		if ((context.Play != null) && context.Play.Plays(nested.Sequence))
		{
			GlobalLog(.Warning, "Sequence: track '{}' plays a sequence it is already inside - skipped", Name);
			return null;
		}
		return new NestedRunner(context.Scene, this, nested, context.Play, context.Listener);
	}

	public override void ResolveResources(ResourceManager manager) => Nested.Bind(manager);

	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		ar.Key("sequence");
		Nested.Serialize(ar);
		SerializeValue(ar, "start", ref Start);
		SerializeValue(ar, "length", ref Length);
		SerializeValue(ar, "loop", ref Loop);
	}

	/// Plays the nested sequence as a play of its own, stepped by the outer playhead mapped into
	/// the section.
	private class NestedRunner : SequenceTrackRunner
	{
		/// BORROWED, both.
		private NestedSequenceTrack mTrack;
		private SequenceResource mNested;
		/// Keeps the nested sequence loaded while it plays.
		private ResourceHold mHold;
		private SequencePlay mPlay ~ delete _;
		private bool mApplied = false;

		public this(Sedulous.Scene.Scene scene, NestedSequenceTrack track, SequenceResource nested, SequencePlay parent,
			ISequenceListener listener)
		{
			mTrack = track;
			mNested = nested;
			mHold = new .(track.Nested.Handle);
			mPlay = new .(scene, nested.Sequence);
			mPlay.SetParent(parent);
			mPlay.SetListener(listener);
			// The same cast: each name the nested sequence has is filled by the outer play's
			// entity of that name.
			if (parent != null)
			{
				for (let binding in nested.Sequence.Bindings)
					mPlay.Bind(binding.Name, parent.BoundEntity(binding.Name));
			}
		}

		public ~this()
		{
			// The play lets go before the hold on what it plays does.
			DeleteAndNullify!(mPlay);
			mHold.Release();
		}

		public override void Evaluate(SequenceStep step)
		{
			let duration = mNested.Sequence.Duration;
			let length = mTrack.SectionLength;
			let now = Math.Min(step.Time - mTrack.Start, length);
			let previous = Math.Min(step.PreviousTime - mTrack.Start, length);
			if ((now < 0.0f) && (previous < 0.0f))
				return; // the section is not reached
			var inner = step;
			if (!mTrack.Loop || (duration <= 0.0f))
			{
				if (mApplied && !step.Jumped && (previous >= Math.Min(length, duration)))
					return; // past its end, already applied there
				inner.Time = Math.Clamp(now, 0.0f, duration);
				inner.PreviousTime = (previous < 0.0f) ? -1.0f : Math.Min(previous, duration);
				mPlay.EvaluateStep(inner);
				mApplied = true;
				return;
			}
			// Looping: a step that crosses the nested sequence's end plays to it, then from its
			// start again.
			let nowWrapped = Wrap(Math.Max(now, 0.0f), duration);
			if (!step.Jumped && (previous >= 0.0f) && (Math.Floor(previous / duration) != Math.Floor(Math.Max(now, 0.0f) / duration)))
			{
				var toEnd = step;
				toEnd.PreviousTime = Wrap(previous, duration);
				toEnd.Time = duration;
				mPlay.EvaluateStep(toEnd);
				inner.PreviousTime = -1.0f;
			}
			else
			{
				inner.PreviousTime = (previous < 0.0f) ? -1.0f : Wrap(previous, duration);
			}
			inner.Time = nowWrapped;
			mPlay.EvaluateStep(inner);
			mApplied = true;
		}

		/// The nested play's runners pause with the outer play.
		public override void SetPaused(bool paused)
		{
			if (paused)
				mPlay.Pause();
			else
				mPlay.Resume();
		}

		public override void Release(bool restore)
		{
			mPlay.Finish = restore ? .Restore : .Release;
			mPlay.Stop();
			mApplied = false;
		}

		private static float Wrap(float time, float duration) => time - Math.Floor(time / duration) * duration;
	}
}
