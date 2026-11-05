using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Run;

namespace Sedulous.Runtime;

/// Owns the engine's subsystems, finds them by type, and drives their lifecycle and frame
/// phases in UpdateOrder.
///
/// Subsystems are keyed by the STABLE type id hashed from the qualified name, not by a
/// runtime type handle. A plugin in a separate library asking for a subsystem by type has
/// its own copy of that type's runtime identity, so handles diverge across a library
/// boundary where a name hash does not.
class SubsystemManager
{
	private Dictionary<uint64, Subsystem> mByType = new .() ~ delete _;
	/// Non owning, kept in UpdateOrder.
	private List<Subsystem> mSorted = new .() ~ delete _;
	/// The subset this manager created and must destroy.
	private List<Subsystem> mOwned = new .() ~ delete _;

	private bool mRunning;
	private bool mDisposed;
	private float mFixedStep = 1.0f / 60.0f;
	private float mTimeScale = 1.0f;
	/// BORROWED: the live runs (SetRunManager); null is none.
	private IRunManager mRuns = null;
	/// BORROWED: the application's services by exact type (RegisterService).
	private Dictionary<Type, Object> mServices = new .() ~ delete _;

	public bool IsRunning => mRunning;
	public int SubsystemCount => mSorted.Count;

	/// The live runs (Raptor's run-context spec): whoever owns them (DefaultApplication) sets
	/// their manager here, so every subsystem, an engine one or a game plugin's, registered
	/// whenever, finds them through Manager.RunManager. Null: no game here (a tool, a test, the
	/// editor's outer runtime), so no runs. Borrowed.
	public void SetRunManager(IRunManager runs) => mRuns = runs;
	public IRunManager RunManager => mRuns;

	/// The application's services, by exact type: what its subsystems offer beyond themselves (the
	/// facades a script reaches, through its run host's lookup). A subsystem registers its own when
	/// it is registered and removes them when it leaves; a run's own services come first for that
	/// run's scripts. BORROWED: the owner keeps each alive while registered. One per type; a second
	/// replaces.
	public void RegisterService<T>(T service) where T : class
	{
		mServices[typeof(T)] = service;
	}

	public void UnregisterService<T>() where T : class
	{
		mServices.Remove(typeof(T));
	}

	public T GetService<T>() where T : class => (T)FindService(typeof(T));

	/// The application's service of exactly `type`, or null.
	public Object FindService(Type type) => mServices.TryGetValue(type, let found) ? found : null;

	public ~this()
	{
		Dispose();
	}

	/// Engine time scale: one is realtime, zero is paused, a half is slow motion.
	///
	/// Clamped at zero rather than allowing a negative, which would run accumulators
	/// backwards and is never what a caller means by pausing.
	public float TimeScale
	{
		get => mTimeScale;
		set => mTimeScale = (value < 0.0f) ? 0.0f : value;
	}

	/// The application's configured fixed step. Plain configuration, not an execution
	/// lane: nothing here drives a fixed update, and a scene reads this to seed its own
	/// stepper.
	public float FixedTimeStep
	{
		get => mFixedStep;
		set => mFixedStep = value;
	}

	/// Creates and registers a subsystem, one per type. THE CONTEXT OWNS what it returns.
	/// A manager that is already running brings it up immediately.
	public T AddSubsystem<T>() where T : Subsystem, new, delete
	{
		let subsystem = new T();
		mOwned.Add(subsystem);
		RegisterInternal(TypeKey<T>(), subsystem);
		return subsystem;
	}

	/// Registers a subsystem the CALLER owns, which is how a plugin registers its own. The
	/// manager drives it and looks it up but never destroys it.
	public T RegisterSubsystem<T>(T subsystem) where T : Subsystem
	{
		RegisterInternal(TypeKey<T>(), subsystem);
		return subsystem;
	}

	/// Removes the subsystem of this type, shutting it down first, and destroys it if this
	/// manager owns it. Does nothing when there is none.
	public void RemoveSubsystem<T>() where T : Subsystem
	{
		RemoveByKey(TypeKey<T>());
	}

	public T GetSubsystem<T>() where T : Subsystem
	{
		if (mByType.TryGetValue(TypeKey<T>(), let found))
			return (T)found;
		return null;
	}

	public bool HasSubsystem<T>() where T : Subsystem => mByType.ContainsKey(TypeKey<T>());

	/// Init then Ready, both in UpdateOrder, and the manager is running afterwards.
	///
	/// Two passes rather than one: every subsystem exists and is initialised before any of
	/// them starts looking for its peers in Ready.
	public void Startup()
	{
		for (let subsystem in mSorted)
			subsystem.Init();
		for (let subsystem in mSorted)
			subsystem.Ready();
		mRunning = true;
	}

	public void BeginFrame(float deltaTime)
	{
		for (let subsystem in mSorted)
			subsystem.BeginFrame(deltaTime);
	}

	public void Update(float deltaTime)
	{
		for (let subsystem in mSorted)
			subsystem.Update(deltaTime);
	}

	public void PostUpdate(float deltaTime)
	{
		for (let subsystem in mSorted)
			subsystem.PostUpdate(deltaTime);
	}

	public void EndFrame()
	{
		for (let subsystem in mSorted)
			subsystem.EndFrame();
	}

	/// PrepareShutdown then Shutdown, both in REVERSE UpdateOrder, so a subsystem is torn
	/// down before whatever it was built on top of.
	public void Shutdown()
	{
		mRunning = false;
		for (int i = mSorted.Count - 1; i >= 0; i--)
			mSorted[i].PrepareShutdown();
		for (int i = mSorted.Count - 1; i >= 0; i--)
			mSorted[i].Shutdown();
	}

	/// Shuts down if running and destroys everything this manager owns. Idempotent, so the
	/// destructor and an explicit call do not both tear down.
	public void Dispose()
	{
		if (mDisposed)
			return;
		mDisposed = true;

		if (mRunning)
			Shutdown();

		for (let subsystem in mSorted)
			subsystem.OnUnregister();

		mServices.Clear();
		mSorted.Clear();
		mByType.Clear();

		for (let subsystem in mOwned)
			delete subsystem;
		mOwned.Clear();
	}

	private static uint64 TypeKey<T>()
	{
		let name = scope String();
		typeof(T).GetFullName(name);
		return TypeIdOf(name);
	}

	private void RegisterInternal(uint64 key, Subsystem subsystem)
	{
		mByType[key] = subsystem;
		InsertSorted(subsystem);
		subsystem.OnRegister(this);

		// Added to a manager that is already running, so it joins mid flight rather than
		// sitting uninitialised until a Startup that has already happened.
		if (mRunning)
		{
			subsystem.Init();
			subsystem.Ready();
		}
	}

	private void RemoveByKey(uint64 key)
	{
		if (!mByType.TryGetValue(key, let subsystem))
			return;

		if (mRunning)
			subsystem.PrepareShutdown();
		subsystem.Shutdown();
		subsystem.OnUnregister();

		mSorted.Remove(subsystem);
		mByType.Remove(key);

		if (mOwned.Remove(subsystem))
			delete subsystem;
	}

	/// Insertion sort, ascending by UpdateOrder and STABLE, so two subsystems sharing an
	/// order keep the sequence they were registered in rather than depending on the sort.
	private void InsertSorted(Subsystem subsystem)
	{
		mSorted.Add(subsystem);
		var i = mSorted.Count - 1;
		while ((i > 0) && (mSorted[i - 1].UpdateOrder > subsystem.UpdateOrder))
		{
			let previous = mSorted[i - 1];
			mSorted[i - 1] = mSorted[i];
			mSorted[i] = previous;
			i--;
		}
	}
}
