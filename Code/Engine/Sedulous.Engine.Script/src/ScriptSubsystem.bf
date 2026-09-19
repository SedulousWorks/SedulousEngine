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
/// find, through Configure; the subsystem owns the host and tears it down when the last
/// scene that used it goes, so a run that never scripts pays nothing.
class ScriptSubsystem : Subsystem, ISceneObserver
{
	/// Wires a fresh runtime: binds the surface, registers services. Set by the application
	/// before any scene composes. Forwarded to the host.
	public delegate void(ScriptRuntime runtime) Configure = null ~ delete _;

	private ScriptRunHost mHost = new .() ~ delete _;
	private List<ScriptSceneSystem> mSystems = new .() ~ delete _;

	public ScriptRunHost Host => mHost;

	protected override void OnReady()
	{
		if (Context == null)
			return;
		mHost.Configure = new (runtime) =>
			{
				if (Configure != null)
					Configure(runtime);
			};
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
		mSystems.Clear();
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
		mSystems.Add(system);
	}

	/// The scene's teardown released its instances (the scene stops before it is
	/// destroyed); when no scene is left on the host, the host goes too.
	public void OnDestroying(Scene scene)
	{
		let system = scene.GetSystem<ScriptSceneSystem>();
		if (system != null)
		{
			mSystems.Remove(system);
			system.SetRunHost(null);
		}
		if (mSystems.IsEmpty)
			mHost.Teardown();
	}
}
