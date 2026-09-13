using System;
using System.Collections;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The Context level physics broker.
///
/// It holds the shared contact listener list, and drives each scene's render frame
/// interpolation and debug drawing. The stepping itself is the scene system's.
class PhysicsSubsystem : Subsystem, ISceneObserver
{
	/// One watched scene and its physics system, both BORROWED.
	private struct SceneEntry
	{
		public Scene Scene;
		public PhysicsSceneSystem System;

		public this(Scene scene, PhysicsSceneSystem system)
		{
			Scene = scene;
			System = system;
		}
	}

	private List<SceneEntry> mSystems = new .() ~ delete _;
	/// BORROWED consumers of resolved contacts. The list's address is stable, which is what
	/// each scene system holds.
	private List<IContactListener> mContactListeners = new .() ~ delete _;

	/// BEFORE the scene subsystem: the interpolation's local writes must land before the
	/// scene recomputes its world matrices, or extraction would draw poses a frame behind.
	public override int32 UpdateOrder => -600;

	/// Registers a consumer of resolved contacts. A duplicate is ignored, so registering
	/// twice does not deliver twice.
	public void RegisterContactListener(IContactListener listener)
	{
		if (listener == null)
			return;

		for (let existing in mContactListeners)
		{
			if (existing === listener)
				return;
		}

		mContactListeners.Add(listener);
	}

	public void UnregisterContactListener(IContactListener listener)
	{
		for (int i = mContactListeners.Count - 1; i >= 0; i--)
		{
			if (mContactListeners[i] === listener)
			{
				mContactListeners.RemoveAt(i);
				return;
			}
		}
	}

	public void OnSystemsReady(Scene scene)
	{
		let system = scene.GetSystem<PhysicsSceneSystem>();
		if (system == null)
			return;

		system.SetContactListeners(mContactListeners);
		mSystems.Add(SceneEntry(scene, system));
	}

	public void OnDestroying(Scene scene)
	{
		for (int i = mSystems.Count - 1; i >= 0; i--)
		{
			if (mSystems[i].Scene === scene)
			{
				mSystems.RemoveAt(i);
				return;
			}
		}
	}

	public override void Update(float deltaTime)
	{
		if (Context == null)
			return;

		let render = Context.GetSubsystem<RenderSubsystem>();

		using (ProfileScope("Physics.Interpolate"))
		{
			for (let entry in mSystems)
			{
				if ((entry.System == null) || (entry.Scene == null))
					continue;

				// PER SCENE: each steps on its own accumulator and its own time scale, so one
				// scene's alpha says nothing about another's.
				entry.System.ApplyInterpolation(entry.Scene.FixedAlpha);

				if ((render != null) && entry.System.Settings.DebugDraw)
					PhysicsDebugDraw.Draw(entry.System, render.DebugScene(entry.Scene));
			}
		}
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
	}

	protected override void OnShutdown()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
			scenes.UnregisterObserver(this);
	}
}
