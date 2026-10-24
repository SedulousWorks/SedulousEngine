using System;
using System.Collections;

namespace Sedulous.GUI;

// Values that update what depends on them (after AUI's property system: dependency tracking, no
// manual subscriptions). A Property holds a value and records who reads it; a Computed is a value
// derived from others, re-evaluated lazily when one of them changes; an Effect runs a function
// and runs it again when something it read changes. Nothing subscribes by hand: what an
// evaluation reads is what it depends on, found again on every run, so a branch that stops
// reading a value stops depending on it.
//
// Changes push invalidation and pull values: a Property's change marks Computeds stale (they
// recompute when next read) and queues Effects on their scheduler, which a SceneRoot flushes
// once a frame, so a burst of changes costs one run per effect. An effect without a scheduler
// (a node outside any scene, a test) runs at once.
//
// The evaluation in progress is per thread, not per GUI: two GUIs never share an observer, and
// an evaluation never spans threads. Single-threaded otherwise, like the tree.

/// Something that may be read and may change: links itself to whoever read it, and tells them
/// when it changes.
class Observable
{
	private List<Observer> mObservers = new .() ~ delete _;

	public ~this()
	{
		DetachAll();
	}

	/// Records a read by the evaluating observer, if any (once per evaluation).
	public void Track()
	{
		let observer = Observer.[Friend]sCurrent;
		if (observer == null)
			return;
		if (observer.[Friend]mSources.Contains(this))
			return;
		observer.[Friend]mSources.Add(this);
		mObservers.Add(observer);
	}

	/// Everything that read this is told it changed (Computeds go stale, Effects queue).
	public void Notify()
	{
		if (mObservers.IsEmpty)
			return;
		// A copy: an observer told may re-evaluate at once (no scheduler) and relink.
		let observers = scope List<Observer>(mObservers.Count);
		observers.AddRange(mObservers);
		for (let observer in observers)
			observer.Invalidate();
	}

	public int ObserverCount => mObservers.Count;

	private void DetachAll()
	{
		for (let observer in mObservers)
			observer.[Friend]mSources.Remove(this);
		mObservers.Clear();
	}
}

/// Something that reads: a Computed or an Effect. Its sources are what its last evaluation read.
abstract class Observer
{
	/// The observer evaluating on this thread (the one a read is recorded for), or null.
	[ThreadStatic]
	private static Observer sCurrent;

	private List<Observable> mSources = new .() ~ delete _;

	public ~this()
	{
		ClearSources();
	}

	/// A source changed.
	public abstract void Invalidate();

	public int SourceCount => mSources.Count;

	/// Runs `fn` as this observer: the sources of the last run are dropped, and what `fn` reads
	/// becomes the new ones.
	protected T Evaluate<T>(delegate T() fn)
	{
		ClearSources();
		let previous = sCurrent;
		sCurrent = this;
		defer { sCurrent = previous; }
		return fn();
	}

	protected void Evaluate(delegate void() fn)
	{
		ClearSources();
		let previous = sCurrent;
		sCurrent = this;
		defer { sCurrent = previous; }
		fn();
	}

	protected void ClearSources()
	{
		for (let source in mSources)
			source.[Friend]mObservers.Remove(this);
		mSources.Clear();
	}

	/// Runs `fn` with no observer: what it reads is not recorded (an effect's writes that read a
	/// value first, a native handler called from inside an evaluation).
	public static T Untracked<T>(delegate T() fn)
	{
		let previous = sCurrent;
		sCurrent = null;
		defer { sCurrent = previous; }
		return fn();
	}

	public static void Untracked(delegate void() fn)
	{
		let previous = sCurrent;
		sCurrent = null;
		defer { sCurrent = previous; }
		fn();
	}
}

/// A value that records its readers and tells them when it changes. Setting it to what it is
/// changes nothing. For a value type; text is StringProperty.
class Property<T> where bool : operator T == T
{
	private T mValue;
	private Observable mChanged = new .() ~ delete _;

	public this()
	{
		mValue = default;
	}

	public this(T value)
	{
		mValue = value;
	}

	public T Get()
	{
		mChanged.Track();
		return mValue;
	}

	/// The value without recording the read.
	public T Peek() => mValue;

	/// Whether the value changed (and its readers were told).
	public bool Set(T value)
	{
		if (mValue == value)
			return false;
		mValue = value;
		mChanged.Notify();
		return true;
	}

	public Observable Changed => mChanged;
}

/// Property for text: it owns its string, and a read is a view of it, valid until the next set.
class StringProperty
{
	private String mValue = new .() ~ delete _;
	private Observable mChanged = new .() ~ delete _;

	public this()
	{
	}

	public this(StringView value)
	{
		mValue.Set(value);
	}

	public StringView Get()
	{
		mChanged.Track();
		return mValue;
	}

	/// The value without recording the read.
	public StringView Peek() => mValue;

	/// Whether the value changed (and its readers were told).
	public bool Set(StringView value)
	{
		if (mValue == value)
			return false;
		mValue.Set(value);
		mChanged.Notify();
		return true;
	}

	public Observable Changed => mChanged;
}

/// A value derived from others: evaluated when first read, then again only when read after one
/// of the values it read changed. It records its own readers, as a Property does.
class Computed<T> : Observer
{
	private delegate T() mExpression ~ delete _;
	private T mValue = default;
	private bool mStale = true;
	private Observable mChanged = new .() ~ delete _;

	/// OWNERSHIP of `expression` transfers.
	public this(delegate T() expression)
	{
		mExpression = expression;
	}

	public T Get()
	{
		mChanged.Track();
		if (mStale)
		{
			mValue = Evaluate(mExpression);
			mStale = false;
		}
		return mValue;
	}

	public bool IsStale => mStale;

	public override void Invalidate()
	{
		if (mStale)
			return; // its readers were told already
		mStale = true;
		mChanged.Notify();
	}
}

/// Where effects wait to run: a GUIContext holds one and flushes it once a frame, for all its
/// roots, so changes in between cost one run of each effect they reach.
class EffectScheduler
{
	private List<Effect> mQueue = new .() ~ delete _;
	/// The round being run (an effect destroyed meanwhile is nulled here).
	private List<Effect> mBatch = new .() ~ delete _;

	public ~this()
	{
		for (let effect in mQueue)
			effect.[Friend]mQueuedOn = null;
		for (let effect in mBatch)
		{
			if (effect != null)
				effect.[Friend]mQueuedOn = null;
		}
	}

	public void Queue(Effect effect) => mQueue.Add(effect);

	public void Forget(Effect effect)
	{
		mQueue.Remove(effect);
		for (int i < mBatch.Count)
		{
			if (mBatch[i] == effect)
				mBatch[i] = null;
		}
	}

	/// Runs the queued effects, and those their runs queue, at most a few rounds (an effect that
	/// changes what it reads would never settle). How many ran.
	public uint32 Flush()
	{
		uint32 ran = 0;
		for (int round = 0; (round < 16) && !mQueue.IsEmpty; round++)
		{
			Swap!(mBatch, mQueue);
			mQueue.Clear();
			for (int i < mBatch.Count)
			{
				let effect = mBatch[i];
				if ((effect == null) || (effect.[Friend]mQueuedOn != this))
					continue; // destroyed, or run since
				effect.Run();
				ran++;
			}
			mBatch.Clear();
		}
		return ran;
	}

	public bool HasPending => !mQueue.IsEmpty;
}

/// A function run once at creation and again whenever something it read changed: on its
/// scheduler's next flush, or at once when it has none.
class Effect : Observer
{
	private delegate void() mBody ~ delete _;
	private delegate EffectScheduler() mScheduler ~ delete _;
	private EffectScheduler mQueuedOn = null;
	private uint32 mRuns = 0;
	/// Inside the body.
	private bool mRunning = false;
	/// Told to run again meanwhile.
	private bool mRerun = false;

	/// `scheduler` names where it waits; asked at each change, so an effect owned by a node finds
	/// the scheduler of the scene the node is in now. OWNERSHIP of both delegates transfers.
	public this(delegate void() body, delegate EffectScheduler() scheduler = null)
	{
		mBody = body;
		mScheduler = scheduler;
		Run();
	}

	public ~this()
	{
		if (mQueuedOn != null)
			mQueuedOn.Forget(this);
	}

	/// Runs the body. An effect told to run again while it runs (its body changed what it read,
	/// with no scheduler to wait on) runs again after it finishes, not inside itself, a few times
	/// at most: one that never settles is cut off rather than recursing without end.
	public void Run()
	{
		mQueuedOn = null;
		if (mRunning)
		{
			mRerun = true;
			return;
		}
		mRunning = true;
		for (int round < 16)
		{
			mRerun = false;
			mRuns++;
			Evaluate(mBody);
			if (!mRerun)
				break;
		}
		mRunning = false;
	}

	public uint32 RunCount => mRuns;
	public bool IsQueued => mQueuedOn != null;

	public override void Invalidate()
	{
		if (mRunning)
		{
			mRerun = true; // after this run, not inside it
			return;
		}
		if (mQueuedOn != null)
			return;
		let scheduler = (mScheduler != null) ? mScheduler() : null;
		if (scheduler == null)
		{
			Run();
			return;
		}
		mQueuedOn = scheduler;
		scheduler.Queue(this);
	}
}
