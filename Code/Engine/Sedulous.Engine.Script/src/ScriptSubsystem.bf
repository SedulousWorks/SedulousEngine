using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Runtime;
using Sedulous.Engine.Scene;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Engine.Script;

/// Scripting at runtime: the run's host, wired into every scene's script system when the
/// scene composes.
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

	/// Wires a host a game instance owns the way this subsystem's own is wired: the same
	/// surface and services through Configure, so a run's scripts see what the default
	/// host's do, plus whatever the instance installs on top.
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

	/// A debugger on the default host: the editor's scenes. A game instance's run is
	/// debugged through its own host.
	public void RequestDebugger(delegate void(IScriptDebugger debugger) configurator) => mHost.RequestDebugger(configurator);
	public bool IsDebugPaused => mHost.IsDebugPaused;

	/// The default host's coroutines move with the context's time. An instance's host is
	/// advanced by the instance, with its own gameplay time.
	public override void Update(float deltaTime)
	{
		let scale = (Context != null) ? Context.TimeScale : 1.0f;
		mHost.Advance(deltaTime * scale);
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;
		mHost.Configure = new (runtime) =>
			{
				if (Configure != null)
					Configure(runtime);
			};
		mHost.TeardownCheck = new (h) => { MaybeTeardownRunHost(h); };
		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
	}

	protected override void OnShutdown()
	{
		if (Context != null)
		{
			if (let scenes = Context.GetSubsystem<SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}
		// A scene stopped after this must not call back into a subsystem that is gone.
		for (let system in mSystems)
			DeleteAndNullify!(system.OnRunStopped);
		mSystems.Clear();
		DeleteAndNullify!(mHost.TeardownCheck);
		mHost.Teardown();
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

	public void OnSystemsReady(Scene scene)
	{
		let system = scene.GetSystem<ScriptSceneSystem>();
		if (system == null)
			return;
		system.SetRunHost(mHost);
		// Each stop asks whether the system's CURRENT host can go: a game instance re-binds
		// its scenes to its own host after this.
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
