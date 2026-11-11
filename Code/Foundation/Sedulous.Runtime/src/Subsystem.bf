using System;

namespace Sedulous.Runtime;

/// The unit of engine functionality a SubsystemManager owns and drives.
///
/// Lifecycle: OnRegister, then Init and Ready, then frames, then PrepareShutdown and
/// Shutdown. Init and Shutdown are guarded so calling either twice does nothing, because a
/// subsystem added to an already running manager is brought up immediately and must not be
/// brought up again by the next Startup.
///
/// PrepareShutdown exists separately from Shutdown so a subsystem can drop references to
/// its peers while they are all still alive. Tearing down in one pass means the first
/// subsystem out is unreachable to the rest halfway through their own teardown.
abstract class Subsystem
{
	private SubsystemManager mManager;
	private bool mInitialized;

	public SubsystemManager Manager => mManager;
	public bool IsInitialized => mInitialized;

	/// Lower runs earlier, in every frame phase and in startup order.
	public virtual int32 UpdateOrder => 0;

	public virtual void OnRegister(SubsystemManager manager)
	{
		mManager = manager;
	}

	public virtual void OnUnregister()
	{
		mManager = null;
	}

	public void Init()
	{
		if (mInitialized)
			return;
		OnInit();
		mInitialized = true;
	}

	public void Ready() => OnReady();

	public void PrepareShutdown() => OnPrepareShutdown();

	public void Shutdown()
	{
		if (!mInitialized)
			return;
		OnShutdown();
		mInitialized = false;
	}

	public virtual void BeginFrame(float deltaTime) {}
	public virtual void Update(float deltaTime) {}
	public virtual void PostUpdate(float deltaTime) {}
	public virtual void EndFrame() {}

	/// The app taken out of view and given back (a phone's home button, another app in front): no
	/// frames come between the two, and the platform may end the app in between without asking,
	/// so what must last is saved in OnEnterBackground.
	public virtual void OnEnterBackground() {}
	public virtual void OnEnterForeground() {}

	protected virtual void OnInit() {}
	protected virtual void OnReady() {}
	protected virtual void OnPrepareShutdown() {}
	protected virtual void OnShutdown() {}
}
