using System;
using System.Collections;

namespace Sedulous.Run;

/// IRunManager implemented once: the runs added to it, the focus, the subscribers. Each run added
/// announces its transitions here, and they go to every subscriber in subscription order; a run's
/// destruction removes it, clearing the focus when it held it. Owned by whatever owns the runs
/// (the engine's DefaultApplication); the runs and listeners are BORROWED.
class RunRegistry : IRunManager, IRunListener
{
	private List<RunBase> mRuns = new .() ~ delete _;
	private List<IRunListener> mListeners = new .() ~ delete _;
	private IRun mFocused = null;

	public ~this()
	{
		// Runs still here outlive the registry: they stop telling it anything.
		for (let run in mRuns)
			run.SetLifecycleListener(null);
	}

	public int Count => mRuns.Count;
	public IRun Focused => mFocused;

	/// `run` joins the live runs (announced as created, and started when it is); it leaves when it
	/// is disposed.
	public void Add(RunBase run)
	{
		if (mRuns.Contains(run))
			return;
		mRuns.Add(run);
		run.SetLifecycleListener(this);
		Announce(scope (l) => l.OnRunCreated(run));
		if ((run.State == .Running) || (run.State == .Paused))
			Announce(scope (l) => l.OnRunStarted(run));
	}

	public void ForEachRun(delegate void(IRun run) visit)
	{
		// A visit may dispose one.
		let runs = scope List<RunBase>();
		runs.AddRange(mRuns);
		for (let run in runs)
			visit(run);
	}

	public IRun Find(RunId id)
	{
		for (let run in mRuns)
		{
			if (run.Id == id)
				return run;
		}
		return null;
	}

	public void SetFocused(IRun run)
	{
		if ((Object)run == (Object)mFocused)
			return;
		mFocused = run;
		Announce(scope (l) => l.OnFocusChanged(run));
	}

	public void Subscribe(IRunListener listener)
	{
		if (!mListeners.Contains(listener))
			mListeners.Add(listener);
	}

	public void Unsubscribe(IRunListener listener) => mListeners.Remove(listener);

	public void OnRunStarted(IRun run) => Announce(scope (l) => l.OnRunStarted(run));
	public void OnRunPaused(IRun run, bool paused) => Announce(scope (l) => l.OnRunPaused(run, paused));
	public void OnRunStopping(IRun run) => Announce(scope (l) => l.OnRunStopping(run));

	public void OnRunDestroyed(IRun run)
	{
		if ((Object)mFocused == (Object)run)
			SetFocused(null);
		Announce(scope (l) => l.OnRunDestroyed(run));
		for (int i < mRuns.Count)
		{
			if ((Object)mRuns[i] == (Object)run)
			{
				mRuns.RemoveAt(i);
				return;
			}
		}
	}

	/// To the listeners as they are now: one may unsubscribe while it is being told.
	private void Announce(delegate void(IRunListener listener) tell)
	{
		let listeners = scope List<IRunListener>();
		listeners.AddRange(mListeners);
		for (let listener in listeners)
			tell(listener);
	}
}
