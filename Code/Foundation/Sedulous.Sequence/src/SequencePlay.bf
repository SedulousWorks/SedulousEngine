using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Scene;

namespace Sedulous.Sequence;

/// One running instance of a sequence on a scene: its time, which entity fills each name, and a
/// runner per track that applies the track at each step and releases what it did when the play
/// ends. The editor's preview and the game's player both go through a play, so a sequence looks the
/// same in both. The sequence and the scene are BORROWED and must outlive the play.
class SequencePlay
{
	private struct Running
	{
		public int Track;
		public SequenceTrackRunner Runner;
	}

	private Sedulous.Scene.Scene mScene;
	private Sequence mSequence;
	/// BORROWED.
	private ISequenceListener mListener = null;
	/// BORROWED: the play this one is nested in, or null.
	private SequencePlay mParent = null;
	/// Per binding.
	private List<EntityHandle> mBound = new .() ~ delete _;
	/// In evaluation order; the runners are OWNED.
	private List<Running> mRunners = new .() ~ { for (let r in _) delete r.Runner; delete _; };
	/// Per track: its missing binding was told this play.
	private List<bool> mWarned = new .() ~ delete _;
	private float mTime = 0.0f;
	/// The runners exist.
	private bool mBegun = false;
	/// Between Play (or Seek, Pose) and Stop.
	private bool mRunning = false;
	private bool mPaused = false;
	private bool mHeld = false;
	private bool mFinished = false;
	/// The next step starts before 0, so what is at 0 fires.
	private bool mFromStart = false;

	public SequenceFinish Finish = .Release;
	public bool Loop = false;
	/// 0 and up.
	public float Speed = 1.0f;

	public this(Sedulous.Scene.Scene scene, Sequence sequence)
	{
		mScene = scene;
		mSequence = sequence;
		mBound.Resize(sequence.Bindings.Count);
		mWarned.Resize(sequence.Tracks.Count);
	}

	public ~this()
	{
		if (mBegun)
			Release(Finish == .Restore);
	}

	public void SetListener(ISequenceListener listener) => mListener = listener;

	public bool IsPlaying => mRunning && !mFinished;
	public bool IsPaused => mPaused;
	public bool IsHeld => mHeld;
	public bool IsFinished => mFinished;
	public float Time => mTime;
	public float Duration => mSequence.Duration;
	public Sequence Played => mSequence;

	/// The play this one is nested in, or null.
	public SequencePlay Parent => mParent;
	public void SetParent(SequencePlay parent) => mParent = parent;

	/// Whether this play, or one it is nested in, plays `sequence`.
	public bool Plays(Sequence sequence)
	{
		for (var play = this; play != null; play = play.mParent)
		{
			if (play.mSequence == sequence)
				return true;
		}
		return false;
	}

	/// The entity that fills the binding `name`; unassigned when there is none.
	public EntityHandle BoundEntity(StringView name)
	{
		let index = mSequence.FindBinding(name);
		return (index >= 0) ? mBound[index] : EntityHandle();
	}

	/// Fills the binding `name` with `entity`. False when the sequence has no such binding. A play
	/// running takes it at once: the tracks bound to it begin again on the new entity.
	public bool Bind(StringView name, EntityHandle entity)
	{
		let index = mSequence.FindBinding(name);
		if (index < 0)
			return false;
		mBound[index] = entity;
		if (!mBegun)
			return true;
		// The tracks bound to it begin again on the new entity; what they did to the old one stays.
		for (int t < mSequence.Tracks.Count)
		{
			let track = mSequence.Tracks[t];
			if ((track == null) || (track.Binding != index))
				continue;
			for (int r < mRunners.Count)
			{
				if (mRunners[r].Track == t)
				{
					mRunners[r].Runner.Release(false);
					delete mRunners[r].Runner;
					mRunners.RemoveAt(r);
					break;
				}
			}
			mWarned[t] = false;
			BeginTrack(t);
		}
		return true;
	}

	/// Starts from the beginning and applies time 0 at once.
	public void Play()
	{
		if (mBegun)
			Release(false);
		Begin();
		mRunning = true;
		mPaused = false;
		mHeld = false;
		mFinished = false;
		mTime = 0.0f;
		mFromStart = true;
		if (!PlayTo(0.0f) && (mSequence.Duration <= 0.0f))
			Finished();
	}

	/// Ends the play: every runner lets go, and puts values back when the finish is Restore.
	public void Stop()
	{
		if (mBegun)
			Release(Finish == .Restore);
		mRunning = false;
		mPaused = false;
		mHeld = false;
		mFinished = false;
	}

	public void Pause() => mPaused = true;

	/// Continues after a pause, or from a hold.
	public void Resume()
	{
		mPaused = false;
		mHeld = false;
	}

	/// Moves the playhead to `time` without playing what lies between; a hold it was at is let go.
	/// Starts the play first when it is not running.
	public void Seek(float time) => Jump(time, false);

	/// The editor's preview: applies `time` with no events and no sounds.
	public void Pose(float time) => Jump(time, true);

	/// Advances by `deltaTime` seconds (times speed): stops at a hold, wraps or ends at the end.
	public void Advance(float deltaTime)
	{
		if (!mRunning || mFinished || mPaused || mHeld)
			return;
		let duration = mSequence.Duration;
		var target = mTime + Math.Max(0.0f, deltaTime * Speed);
		// A step longer than the sequence wraps at most a few times; what it would skip beyond that
		// is not played.
		for (int wraps = 0; ; wraps++)
		{
			if (PlayTo(Math.Min(target, duration)))
				return; // held
			if (target < duration)
				return;
			if (!Loop || (duration <= 0.0f))
			{
				Finished();
				return;
			}
			target -= duration;
			if (wraps >= 3)
			{
				while (target >= duration)
					target -= duration;
			}
			mTime = 0.0f;
			mFromStart = true;
		}
	}

	/// Applies `step` as given, holds and the end left to whoever steps it: a nested sequence
	/// follows its parent's playhead this way. Begins the runners first when needed.
	public void EvaluateStep(SequenceStep step)
	{
		if (!mBegun)
			Begin();
		mRunning = true;
		mTime = step.Time;
		Evaluate(step);
	}

	private void Jump(float time, bool preview)
	{
		if (!mBegun)
			Begin();
		mRunning = true;
		mHeld = false;
		mFinished = false;
		mFromStart = false;
		mTime = Math.Clamp(time, 0.0f, mSequence.Duration);
		var step = SequenceStep();
		step.Time = mTime;
		step.PreviousTime = mTime;
		step.Jumped = true;
		step.Preview = preview;
		Evaluate(step);
	}

	private void Begin()
	{
		ClearRunners();
		for (int t < mWarned.Count)
			mWarned[t] = false;
		for (int t < mSequence.Tracks.Count)
			BeginTrack(t);
		mBegun = true;
	}

	private void BeginTrack(int index)
	{
		let track = mSequence.Tracks[index];
		if ((track == null) || track.Muted)
			return;
		var entity = EntityHandle();
		let bound = (track.Binding >= 0) && (track.Binding < mBound.Count);
		if (bound)
			entity = mBound[track.Binding];
		if (track.NeedsBinding && !mScene.IsValid(entity))
		{
			if (!mWarned[index])
			{
				mWarned[index] = true;
				let bindingName = bound ? StringView(mSequence.Bindings[track.Binding].Name) : "(none)";
				GlobalLog(.Warning, "Sequence: track '{}' has no entity for '{}' - skipped", track.Name, bindingName);
			}
			return;
		}
		var context = SequenceTrackContext();
		context.Scene = mScene;
		context.Entity = entity;
		context.Listener = mListener;
		context.Play = this;
		let runner = track.Begin(context);
		if (runner == null)
			return;
		// Kept in evaluation order: by the kind's order, then by the track's place.
		int at = 0;
		while (at < mRunners.Count)
		{
			let other = mSequence.Tracks[mRunners[at].Track];
			if ((other.Order > track.Order) || ((other.Order == track.Order) && (mRunners[at].Track > index)))
				break;
			at++;
		}
		var running = Running();
		running.Track = index;
		running.Runner = runner;
		mRunners.Insert(at, running);
	}

	private void Release(bool restore)
	{
		// Last first, so a value two tracks changed is restored to what was there before both.
		for (int r = mRunners.Count - 1; r >= 0; r--)
			mRunners[r].Runner.Release(restore);
		ClearRunners();
		mBegun = false;
	}

	private void ClearRunners()
	{
		for (let running in mRunners)
			delete running.Runner;
		mRunners.Clear();
	}

	private void Evaluate(SequenceStep step)
	{
		for (let running in mRunners)
			running.Runner.Evaluate(step);
	}

	/// Plays from the playhead to `to`, stopping at the first hold on the way. True when it stopped
	/// at one.
	private bool PlayTo(float to)
	{
		var to;
		let previous = mFromStart ? -1.0f : mTime;
		// The first hold on the way, if any, ends the step there.
		SequenceMarker hold = null;
		for (let marker in mSequence.Markers)
		{
			if (marker.Hold && (marker.Time > previous) && (marker.Time <= to) && ((hold == null) || (marker.Time < hold.Time)))
				hold = marker;
		}
		if (hold != null)
			to = hold.Time;
		var step = SequenceStep();
		step.Time = to;
		step.PreviousTime = previous;
		mTime = to;
		mFromStart = false;
		Evaluate(step);
		if (hold == null)
			return false;
		mHeld = true;
		if (mListener != null)
			mListener.OnSequenceHeld(hold.Name);
		return true;
	}

	private void Finished()
	{
		mFinished = true;
		if (mListener != null)
			mListener.OnSequenceFinished();
		switch (Finish)
		{
		case .Release: Release(false);
		case .Restore: Release(true);
		case .Hold:
		}
	}
}
