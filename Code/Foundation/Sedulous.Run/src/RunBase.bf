using System;
using System.Collections;
using System.Threading;
using Sedulous.Messaging;

namespace Sedulous.Run;

/// IRun implemented once: the id, name, state machine, event bus and service table. A run derives
/// from it (the engine's GameInstance does). One that registers its own members as services calls
/// Dispose in its own destructor, so their stop hooks run while they still exist.
class RunBase : IRun
{
	private struct Entry
	{
		public Type Type;
		public Object Object;
		public IRunService Hooks;
		/// The run deletes it when it goes; false for a borrowed one.
		public bool Owned;
		/// Removed (and, owned, deleted) when the session ends.
		public bool Session;
	}

	/// Never reused in the process.
	private static int sLastRunId = 0;

	private RunId mId;
	private String mName = new .() ~ delete _;
	private RunState mState = .Idle;
	private EventBus mEvents = new .() ~ delete _;
	/// In registration order.
	private List<Entry> mServices = new .() ~ delete _;
	/// BORROWED: who hears this run's transitions (its manager); null for none.
	private IRunListener mListener = null;

	public this(StringView name)
	{
		mId = (RunId)Interlocked.Increment(ref sLastRunId);
		mName.Set(name);
	}

	public ~this()
	{
		Dispose();
	}

	public RunId Id => mId;
	public StringView Name => mName;
	public RunState State => mState;
	public EventBus Events => mEvents;
	public void SetName(StringView name) => mName.Set(name);

	/// The service of type `T` this run holds, or null.
	public T Get<T>() where T : class => (T)FindService(typeof(T));
	public bool Has<T>() where T : class => FindService(typeof(T)) != null;

	public Object FindService(Type type)
	{
		for (let entry in mServices)
		{
			if (entry.Type == type)
				return entry.Object;
		}
		return null;
	}

	/// Holds `service` for the run's life, taking OWNERSHIP. A type held already is replaced (an
	/// owned predecessor deleted).
	public T Add<T>(T service) where T : class => Insert(service, true, false);
	/// As Add, for this session only: removed (and deleted) at Stop.
	public T AddForSession<T>(T service) where T : class => Insert(service, true, true);
	/// Holds a service someone else owns, never deleted by the run.
	public T Register<T>(T service) where T : class => Insert(service, false, false);

	public void Remove<T>() where T : class => RemoveType(typeof(T));

	/// Who hears this run's transitions (its manager); null for none. BORROWED.
	public void SetLifecycleListener(IRunListener listener) => mListener = listener;

	/// A session starts (Idle to Running). Nothing when one is under way.
	public void Start()
	{
		if (mState != .Idle)
			return;
		mState = .Running;
		mListener?.OnRunStarted(this);
	}

	/// The host's pause (Running and Paused); repeating the same value does nothing.
	public void SetPaused(bool paused)
	{
		let now = mState == .Paused;
		if (((mState != .Running) && (mState != .Paused)) || (now == paused))
			return;
		mState = paused ? .Paused : .Running;
		for (int i = mServices.Count - 1; i >= 0; i--)
			mServices[i].Hooks?.OnRunPaused(this, paused);
		mListener?.OnRunPaused(this, paused);
	}

	/// The session ends: the services' stop hooks (reverse order), then the listener's, then the
	/// per-session services go. Back to Idle. Nothing when no session is under way.
	public void Stop()
	{
		if ((mState != .Running) && (mState != .Paused))
			return;
		mState = .Stopping;
		for (int i = mServices.Count - 1; i >= 0; i--)
			mServices[i].Hooks?.OnRunStopping(this);
		mListener?.OnRunStopping(this);
		// This session's services go, last added first.
		for (int i = mServices.Count - 1; i >= 0; i--)
		{
			if (mServices[i].Session)
			{
				Destroy(mServices[i]);
				mServices.RemoveAt(i);
			}
		}
		mState = .Idle;
	}

	/// Stops a session under way, deletes the owned services, announces the destruction.
	/// Idempotent; the destructor calls it.
	public void Dispose()
	{
		if (mState == .Disposed)
			return;
		Stop();
		for (int i = mServices.Count - 1; i >= 0; i--)
			Destroy(mServices[i]);
		mServices.Clear();
		mState = .Disposed;
		let listener = mListener;
		if (listener != null)
		{
			mListener = null;
			listener.OnRunDestroyed(this);
		}
	}

	private T Insert<T>(T service, bool owned, bool session) where T : class
	{
		// One per type: the new one replaces.
		RemoveType(typeof(T));
		Entry entry;
		entry.Type = typeof(T);
		entry.Object = service;
		entry.Hooks = service as IRunService;
		entry.Owned = owned;
		entry.Session = session;
		mServices.Add(entry);
		return service;
	}

	private void RemoveType(Type type)
	{
		for (int i < mServices.Count)
		{
			if (mServices[i].Type == type)
			{
				Destroy(mServices[i]);
				mServices.RemoveAt(i);
				return;
			}
		}
	}

	private static void Destroy(Entry entry)
	{
		if (entry.Owned)
			delete entry.Object;
	}
}
