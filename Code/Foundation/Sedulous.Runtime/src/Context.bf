namespace Sedulous.Runtime;

using System;
using System.Collections;
using Sedulous.Profiler;

/// Central access point for all subsystems.
/// Manages subsystem registration, lifecycle, and update ordering.
/// Does NOT own ResourceSystem or JobSystem — those are application concerns.
/// Subsystems that need resources receive them as constructor parameters.
public class Context : IDisposable
{
	private Dictionary<Type, Subsystem> mSubsystems = new .() ~ delete _;
	private List<Subsystem> mSortedSubsystems = new .() ~ delete _;
	private bool mIsRunning = false;
	private bool mDisposed = false;

	/// Returns true if the context is running.
	public bool IsRunning => mIsRunning;

	/// Gets all registered subsystems in update order.
	public List<Subsystem> Subsystems => mSortedSubsystems;

	public this() { }

	/// Destructor - ensures Dispose is called.
	public ~this()
	{
		Dispose();
	}

	/// Registers a subsystem with the context.
	/// Subsystems are type-keyed and must extend Subsystem.
	/// Subsystems are updated in order based on their UpdateOrder property.
	public void RegisterSubsystem<T>(T subsystem) where T : Subsystem
	{
		let type = typeof(T);
		if (mSubsystems.ContainsKey(type))
			return;

		mSubsystems[type] = subsystem;
		RebuildSortedList();
		subsystem.OnRegister(this);

		if (mIsRunning)
			subsystem.Init();
	}

	/// Unregisters a subsystem from the context.
	public void UnregisterSubsystem<T>() where T : Subsystem
	{
		let type = typeof(T);
		if (mSubsystems.TryGetValue(type, let subsystem))
		{
			if (mIsRunning)
				subsystem.Shutdown();
			subsystem.OnUnregister();
			mSubsystems.Remove(type);
			RebuildSortedList();
		}
	}

	/// Gets a registered subsystem by type.
	/// Returns null if the subsystem is not registered.
	public T GetSubsystem<T>() where T : Subsystem
	{
		if (mSubsystems.TryGetValue(typeof(T), let subsystem))
			return (T)subsystem;
		return null;
	}

	/// Checks if a subsystem is registered.
	public bool HasSubsystem<T>() where T : Subsystem
	{
		return mSubsystems.ContainsKey(typeof(T));
	}

	/// Gets the first registered subsystem implementing interface T.
	/// Searches in update order (lowest UpdateOrder first).
	/// Callers should cache the result at startup for hot paths.
	public T GetSubsystemByInterface<T>() where T : class
	{
		for (let subsystem in mSortedSubsystems)
			if (let match = subsystem as T)
				return match;
		return null;
	}

	/// Gets all registered subsystems implementing interface T, in update order.
	/// Results are appended to the provided list.
	public void GetSubsystemsByInterface<T>(List<T> results) where T : class
	{
		for (let subsystem in mSortedSubsystems)
			if (let match = subsystem as T)
				results.Add(match);
	}

	/// Starts up the context and all registered subsystems.
	public virtual void Startup()
	{
		if (mIsRunning)
			return;

		// Initialize all subsystems in UpdateOrder
		for (let subsystem in mSortedSubsystems)
			subsystem.Init();

		// Signal all subsystems that initialization is complete.
		// Safe to wire cross-subsystem references here.
		for (let subsystem in mSortedSubsystems)
			subsystem.Ready();

		mIsRunning = true;
	}

	/// Called at the beginning of each frame.
	public virtual void BeginFrame(float deltaTime)
	{
		if (!mIsRunning)
			return;

		for (let subsystem in mSortedSubsystems)
			subsystem.BeginFrame(deltaTime);
	}

	/// Calls FixedUpdate on all subsystems for deterministic simulation.
	/// Should be called from a fixed timestep loop (may be called multiple times per frame).
	public virtual void FixedUpdate(float fixedDeltaTime)
	{
		if (!mIsRunning)
			return;

		for (let subsystem in mSortedSubsystems)
		{
			let name = scope String()..AppendF("{0}.FixedUpdate", subsystem.GetType().GetName(.. scope .()));
			using (SProfiler.Begin(name))
				subsystem.FixedUpdate(fixedDeltaTime);
		}
	}

	/// Updates all subsystems.
	public virtual void Update(float deltaTime)
	{
		if (!mIsRunning)
			return;

		for (let subsystem in mSortedSubsystems)
		{
			let name = scope String()..AppendF("{0}.Update", subsystem.GetType().GetName(.. scope .()));
			using (SProfiler.Begin(name))
				subsystem.Update(deltaTime);
		}
	}

	/// Calls PostUpdate on all subsystems.
	/// Called after Update, before EndFrame.
	public virtual void PostUpdate(float deltaTime)
	{
		if (!mIsRunning)
			return;

		for (let subsystem in mSortedSubsystems)
			subsystem.PostUpdate(deltaTime);
	}

	/// Called at the end of each frame.
	public virtual void EndFrame()
	{
		if (!mIsRunning)
			return;

		for (let subsystem in mSortedSubsystems)
			subsystem.EndFrame();
	}

	/// Shuts down all subsystems and the context.
	public virtual void Shutdown()
	{
		if (!mIsRunning)
			return;

		// PrepareShutdown: let subsystems detach cross-references while
		// the world is still alive (e.g., null physics world refs on managers).
		for (int i = mSortedSubsystems.Count - 1; i >= 0; i--)
			mSortedSubsystems[i].PrepareShutdown();

		// Shutdown subsystems in reverse UpdateOrder (higher values first)
		for (int i = mSortedSubsystems.Count - 1; i >= 0; i--)
			mSortedSubsystems[i].Shutdown();

		mIsRunning = false;
	}

	/// Disposes the context and all owned subsystems.
	public virtual void Dispose()
	{
		if (mDisposed)
			return;
		mDisposed = true;

		Shutdown();

		// Dispose all subsystems in reverse order
		for (int i = mSortedSubsystems.Count - 1; i >= 0; i--)
		{
			let subsystem = mSortedSubsystems[i];
			subsystem.OnUnregister();
			subsystem.Dispose();
			delete subsystem;
		}

		mSubsystems.Clear();
		mSortedSubsystems.Clear();
	}

	/// Rebuilds the sorted subsystem list after registration changes.
	private void RebuildSortedList()
	{
		mSortedSubsystems.Clear();
		for (let subsystem in mSubsystems.Values)
			mSortedSubsystems.Add(subsystem);

		// Sort by UpdateOrder (lower values first)
		mSortedSubsystems.Sort(scope (a, b) => a.UpdateOrder <=> b.UpdateOrder);
	}
}
