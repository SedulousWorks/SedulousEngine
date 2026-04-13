namespace Sedulous.Runtime;

using System;

/// Base class for all engine subsystems.
/// Subsystems are managed by Context and provide application-level services.
public abstract class Subsystem : IDisposable
{
	private Context mContext;
	private bool mInitialized = false;

	/// Gets the context this subsystem is registered with.
	public Context Context => mContext;

	/// Gets whether this subsystem has been initialized.
	public bool IsInitialized => mInitialized;

	/// Update order priority. Lower values update first.
	/// Default is 0. Use negative values for early updates (e.g., input),
	/// positive values for late updates (e.g., rendering).
	///
	/// Suggested ranges:
	///   -1000 to -100: Input, early systems
	///       0 to  100: Game logic, physics
	///     100 to  500: Audio, animation
	///     500 to 1000: Rendering, debug visualization
	public virtual int32 UpdateOrder => 0;

	/// Called when the subsystem is registered with a context.
	/// Override to store references or perform early setup.
	public virtual void OnRegister(Context context)
	{
		mContext = context;
	}

	/// Called when the subsystem is unregistered from the context.
	/// Override to clean up references.
	public virtual void OnUnregister()
	{
		mContext = null;
	}

	/// Initializes the subsystem. Called during Context.Startup().
	public void Init()
	{
		if (!mInitialized)
		{
			OnInit();
			mInitialized = true;
		}
	}

	/// Prepares the subsystem for shutdown while the world is still alive.
	/// Called on all subsystems before any Shutdown() calls, giving subsystems
	/// a chance to detach cross-references (e.g., null physics world refs on
	/// component managers) so component cleanup during Shutdown doesn't
	/// access destroyed resources.
	public void PrepareShutdown()
	{
		if (mInitialized)
			OnPrepareShutdown();
	}

	/// Shuts down the subsystem. Called during Context.Shutdown().
	public void Shutdown()
	{
		if (mInitialized)
		{
			OnShutdown();
			mInitialized = false;
		}
	}

	/// Called at the beginning of each frame.
	public virtual void BeginFrame(float deltaTime) { }

	/// Called at a fixed timestep for deterministic simulation.
	/// May be called multiple times per frame (or not at all) depending on framerate.
	/// Use this for physics, AI, or anything requiring consistent timing.
	public virtual void FixedUpdate(float fixedDeltaTime) { }

	/// Called during the main update phase.
	public virtual void Update(float deltaTime) { }

	/// Called after Update, before EndFrame.
	/// Use this for late updates that depend on Update results.
	public virtual void PostUpdate(float deltaTime) { }

	/// Called at the end of each frame.
	public virtual void EndFrame() { }

	/// Override to perform subsystem initialization.
	protected virtual void OnInit() { }

	/// Override to detach cross-references before shutdown.
	/// Called while the world is still alive — safe to access other subsystems,
	/// scenes, and component managers. Use this to null external references so
	/// component cleanup during Shutdown doesn't use-after-free.
	protected virtual void OnPrepareShutdown() { }

	/// Override to perform subsystem shutdown.
	protected virtual void OnShutdown() { }

	/// Disposes the subsystem.
	public virtual void Dispose()
	{
		Shutdown();
	}
}