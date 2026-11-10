using System;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Engine.Input;

/// The runtime hookup: it owns the action runtime and the device source, and evaluates once
/// per frame before scenes tick.
///
/// The provider seam is the play in editor story. The player hands over the shell's devices;
/// an editor's game tab hands over its viewport's gated facades, so an unfocused viewport
/// forwards nothing and the same map evaluates either way.
class InputSubsystem : Subsystem, IRunListener
{
	private ShellInputSource mShellSource ~ delete _;
	/// BORROWED: whoever installed it owns it, and clears it before it goes.
	private IInputSourceProvider mOverride = null;
	/// The override's scene binding. Compared, never dereferenced.
	private void* mBoundSceneKey = null;
	private UnboundInputScenePolicy mUnboundScenePolicy = .AllScenes;
	private ActionRuntime mRuntime = new .() ~ delete _;
	/// The kind of input in use (the pointer, the keyboard or a pad), from the active source each
	/// frame: the one the GUI's prompts and a script's `Input.Describe` follow.
	private InputKindTracker mInputKinds = new .() ~ delete _;
	/// BORROWED: the runs whose `Input` names controls by this subsystem's input kind, from OnReady
	/// to OnShutdown.
	private IRunManager mRunManager = null;
	/// `Input` to scripts outside every run (the editor's Simulate), on the application's services:
	/// every action released and at rest rather than a fault on a missing service. A run's own (a
	/// GameInstance's, over its action runtime) comes first for its scripts. OWNED.
	private InputFacade mScriptFacade = new .(null) ~ delete _;
	/// What ForEachActionRuntime calls with each runtime.
	public typealias ActionRuntimeVisitor = delegate void(ActionRuntime runtime);


	/// A null device hub is tolerated: a headless run reads every device as released.
	public this(IInputManager input)
	{
		mShellSource = new ShellInputSource(input);
		mScriptFacade.InputKinds = mInputKinds;
	}

	public ActionRuntime Runtime => mRuntime;
	/// The kind of input in use, from the active source's devices each frame.
	public InputKindTracker InputKinds => mInputKinds;
	/// The idle `Input` offered on the application's services.
	public InputFacade ScriptFacade => mScriptFacade;

	public override void OnRegister(SubsystemManager manager)
	{
		base.OnRegister(manager);
		manager.RegisterService(mScriptFacade);
		manager.RegisterService(mInputKinds);
	}

	public override void OnUnregister()
	{
		if (Manager != null)
		{
			Manager.UnregisterService<InputFacade>();
			Manager.UnregisterService<InputKindTracker>();
		}
		base.OnUnregister();
	}

	protected override void OnReady()
	{
		if (Manager == null)
			return;
		mRunManager = Manager.RunManager;
		if (mRunManager != null)
		{
			mRunManager.Subscribe(this);
			// The runs made before this was ready name their controls by it too.
			mRunManager.ForEachRun(scope (run) => { PointRunInput(run, mInputKinds); });
		}
	}

	protected override void OnShutdown()
	{
		if (mRunManager != null)
		{
			// The runs still alive let go of the tracker, which goes with this subsystem.
			mRunManager.ForEachRun(scope (run) => { PointRunInput(run, null); });
			mRunManager.Unsubscribe(this);
			mRunManager = null;
		}
	}

	// IRunListener: a run's `Input` names its controls by the input kind tracked here.
	public void OnRunCreated(IRun run) => PointRunInput(run, mInputKinds);

	/// Points `run`'s own `Input` (a game instance's) at `kinds`; null: none.
	private static void PointRunInput(IRun run, InputKindTracker kinds)
	{
		if (let facade = RunServices.Get<InputFacade>(run))
			facade.InputKinds = kinds;
	}

	/// This subsystem's runtime, then each run's (the player's, the editor's Game tabs': the
	/// ActionRuntime a run holds as a service): the UI marks what it
	/// takes on every one (else a tap on a menu also reached the game's actions) and shows their
	/// touch controls. No runs here: this subsystem's runtime alone.
	public void ForEachActionRuntime(ActionRuntimeVisitor visit)
	{
		visit(mRuntime);
		let runs = (Manager != null) ? Manager.RunManager : null;
		if (runs != null)
		{
			runs.ForEachRun(scope (run) =>
				{
					if (let runtime = RunServices.Get<ActionRuntime>(run))
						visit(runtime);
				});
		}
	}

	/// The raw shell devices as a source, for a host with no gated viewport to point at.
	public IInputSourceProvider ShellSource => mShellSource;

	/// Installs a COPY of a map, from a cooked resource, a test, or written by hand.
	public void SetMap(InputMap map) => mRuntime.SetMap(map);

	/// Overrides the device source. Null restores the shell devices.
	///
	/// `boundSceneKey` is the PER SURFACE SCENE BINDING: the opaque identity of the scene
	/// this source represents, compared and never dereferenced, which is what keeps this
	/// module free of Scene. Bound, the UI pump routes pointer, keyboard and gamepad
	/// navigation to that scene's root alone, so two interactive scenes on overlapping
	/// coordinates can no longer cross route. Null leaves it to the policy.
	///
	/// The binding RIDES the override, so clearing the provider clears it.
	public void SetSourceProvider(IInputSourceProvider provider, void* boundSceneKey = null)
	{
		mOverride = provider;
		mBoundSceneKey = (provider != null) ? boundSceneKey : null;
	}

	/// Clears the override only if it currently points at `source`.
	///
	/// A source about to be destroyed, a closing tab's viewport, calls this so the next pump
	/// cannot read freed memory. Guarded, so it never clears a DIFFERENT still open tab's
	/// active source.
	public void ClearSourceProviderIf(IInputSourceProvider source)
	{
		if (mOverride === source)
		{
			mOverride = null;
			mBoundSceneKey = null;
		}
	}

	/// The active source's scene binding, or null when it is un-bound.
	public void* BoundSceneKey => mBoundSceneKey;

	/// How an un-bound source routes. An editor sets this once at startup; the player keeps
	/// the default.
	public UnboundInputScenePolicy UnboundScenePolicy
	{
		get => mUnboundScenePolicy;
		set => mUnboundScenePolicy = value;
	}

	/// What actions evaluate against. The UI subsystem reads the SAME facades, so game UI
	/// sees viewport coordinates in an editor and window coordinates in the player without
	/// knowing which it is.
	public IInputSourceProvider ActiveSource => (mOverride != null) ? mOverride : mShellSource;

	public override void Update(float deltaTime)
	{
		if (Manager != null)
			mRuntime.SetTimeScale(Manager.TimeScale);

		let devices = ActiveSource;
		mInputKinds.Update(devices);
		mRuntime.Update(devices, deltaTime);
	}
}
