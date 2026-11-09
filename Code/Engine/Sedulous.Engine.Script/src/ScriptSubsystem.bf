using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Runtime;
using Sedulous.Engine.Scene;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Engine.Script;

/// Scripting at runtime: the run's host, wired into every scene's script system when the
/// scene composes: the host its run holds, or the subsystem's own default one for a scene
/// outside every run.
///
/// The application supplies the surface the run may reach and the services a script may
/// find, through Configure. A host is torn down whenever nothing pins it (no game script
/// holding it, no scene bound to it simulating, no live instances): after every scene stop
/// and destroy, and when a game script ends. So every play starts from a fresh runtime, its
/// globals and its random numbers new, and a run that never scripts pays nothing.
class ScriptSubsystem : Subsystem, ISceneObserver
{
	/// Wires a fresh runtime: binds the surface, registers services. Set by the application
	/// before any scene composes. Forwarded to the host.
	public delegate void(ScriptRuntime runtime) Configure = null ~ delete _;

	private ScriptRunHost mHost = new .() ~ delete _;
	private List<ScriptSceneSystem> mSystems = new .() ~ delete _;

	public ScriptRunHost Host => mHost;

	/// Wires a host a run owns (a game instance's, a scene page's) the way this subsystem's own
	/// is wired: the same surface and services through Configure, so a run's scripts see what
	/// the default host's do, plus whatever the run installs on top.
	public void ConfigureHost(ScriptRunHost host)
	{
		if (host == null)
			return;
		delete host.Configure;
		host.Configure = new (runtime) =>
			{
				if (Configure != null)
					Configure(runtime);
			};
		delete host.TeardownCheck;
		host.TeardownCheck = new (h) => { MaybeTeardownRunHost(h); };
		host.Subsystems = Manager; // the application's services, after the host's and its run's
	}

	/// Tears `host` down when nothing pins it: no game script holding it, no scene bound to
	/// it started and simulating, no live instances in those scenes. Per host, so a game
	/// instance's host and the default one go independently.
	public void MaybeTeardownRunHost(ScriptRunHost host)
	{
		if ((host == null) || !host.IsActive || host.HasGameScriptHold)
			return;
		for (let system in mSystems)
		{
			if (system.Host !== host)
				continue;
			let scene = system.OwningScene;
			if (system.Started && (scene != null) && scene.SimulationEnabled)
				return;
			if (system.InstanceCount > 0)
				return;
		}
		host.Teardown();
	}

	/// A debugger on the default host: the scenes outside every run. A run (a game instance's)
	/// is debugged through its own host.
	public void RequestDebugger(delegate void(IScriptDebugger debugger) configurator) => mHost.RequestDebugger(configurator);
	public bool IsDebugPaused => mHost.IsDebugPaused;

	/// The default host's coroutines move with the context's time: `deltaTime` is already
	/// scaled by it (the host passes the scaled delta), so it is not scaled again. A run's host
	/// is advanced by its run, with that run's own gameplay time.
	public override void Update(float deltaTime)
	{
		mHost.Advance(deltaTime);
	}

	protected override void OnReady()
	{
		if (Manager == null)
			return;
		mHost.Configure = new (runtime) =>
			{
				if (Configure != null)
					Configure(runtime);
			};
		mHost.TeardownCheck = new (h) => { MaybeTeardownRunHost(h); };
		mHost.Subsystems = Manager;
		if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
	}

	protected override void OnShutdown()
	{
		if (Manager != null)
		{
			if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}
		// A scene stopped after this must not call back into a subsystem that is gone.
		for (let system in mSystems)
			DeleteAndNullify!(system.OnRunStopped);
		mSystems.Clear();
		DeleteAndNullify!(mHost.TeardownCheck);
		mHost.Teardown();
		// The hosts may outlive the manager (a run goes with its application, after the host's
		// subsystems): none asks it again.
		mHost.Subsystems = null;
		if ((Manager != null) && (Manager.RunManager != null))
		{
			Manager.RunManager.ForEachRun(scope (run) =>
				{
					if (let host = RunServices.Get<ScriptRunHost>(run))
						host.Subsystems = null;
				});
		}
	}

	// ---- contact events, the neutral ingress ----

	/// Delivers a resolved contact to BOTH entities' declared handlers, each seeing the
	/// OTHER as the entity. Physics agnostic: the host bridges physics contacts to this. Only
	/// ENQUEUES onto the owning scene's deferred queue, drained at the scene tick's top
	/// level, so there is no re-entrancy even though physics stepped this frame.
	public void DeliverContact(Scene scene, EntityHandle a, EntityHandle b, ScriptContactKind kind,
		Float3 point, Float3 normal, float speed)
	{
		if (scene == null)
			return;
		if (let system = scene.GetSystem<ScriptSceneSystem>())
			system.DeliverContact(a, b, kind, point, normal, speed);
	}

	/// An engine event for an entity's behaviours: `handler` (the final `on<Event>` name, such
	/// as "onAnimationFinished") called with `args` on each of the entity's behaviours that has
	/// it. As DeliverContact, it only ENQUEUES onto the scene's deferred queue, drained at the
	/// scene tick's top level; a host bridges a subsystem's events to it, so the subsystem stays
	/// script agnostic.
	public void DeliverEvent(Scene scene, EntityHandle target, StringView handler, Span<ScriptValue> args)
	{
		if ((scene == null) || !target.IsAssigned)
			return;
		if (let system = scene.GetSystem<ScriptSceneSystem>())
			system.EnqueueHandler(target, handler, args);
	}

	/// The host `scene`'s scripts run on: the one its run holds (a run registers its
	/// ScriptRunHost among its services), else the default host.
	public ScriptRunHost RunHostFor(Scene scene)
	{
		if (let host = RunServices.Get<ScriptRunHost>(scene?.Run))
			return host;
		return mHost;
	}

	public void OnSystemsReady(Scene scene)
	{
		let system = scene.GetSystem<ScriptSceneSystem>();
		if (system == null)
			return;
		// The scene's run's host, so its behaviours and its Level share that run's context (a
		// game's); a scene outside every run uses the default host. A scene's run is set before
		// its systems assemble.
		system.SetRunHost(RunHostFor(scene));
		// Each stop asks whether the system's CURRENT host can go.
		delete system.OnRunStopped;
		system.OnRunStopped = new [=this, =system]() => { MaybeTeardownRunHost(system.Host); };
		mSystems.Add(system);
	}

	/// The scene's teardown released its instances (the scene stops before it is
	/// destroyed); the host it was bound to goes too when nothing else pins it.
	public void OnDestroying(Scene scene)
	{
		let system = scene.GetSystem<ScriptSceneSystem>();
		if (system == null)
			return;
		let host = system.Host;
		mSystems.Remove(system);
		system.SetRunHost(null);
		MaybeTeardownRunHost(host);
	}
}
