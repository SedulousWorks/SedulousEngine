using System;
using System.Collections;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// The Context level navigation broker.
///
/// It owns NO cross scene state: the per scene tick is the scene system's. What this does is
/// watch the scenes so the persistent debug overlay has something to iterate, which follows
/// the physics debugging precedent.
class NavigationSubsystem : Subsystem, ISceneObserver
{
	/// One watched scene and its navigation system, both BORROWED.
	private struct SceneEntry
	{
		public Scene Scene;
		public NavigationSceneSystem System;

		public this(Scene scene, NavigationSceneSystem system)
		{
			Scene = scene;
			System = system;
		}
	}

	private List<SceneEntry> mScenes = new .() ~ delete _;

	/// Reactive: the scene's navigation system is tracked for the overlay's scan.
	public void OnSystemsReady(Scene scene)
	{
		mScenes.Add(SceneEntry(scene, scene.GetSystem<NavigationSceneSystem>()));
	}

	public void OnDestroying(Scene scene)
	{
		for (int i = mScenes.Count - 1; i >= 0; i--)
		{
			if (mScenes[i].Scene === scene)
			{
				mScenes.RemoveAt(i);
				return;
			}
		}
	}

	/// The persistent overlay: while a scene has its debug flag on, its loaded navmesh and
	/// agent paths are drawn into the renderer's per scene debug list each frame.
	public override void Update(float deltaTime)
	{
		if (Context == null)
			return;

		let render = Context.GetSubsystem<RenderSubsystem>();
		if (render == null)
			return;

		for (let entry in mScenes)
		{
			if ((entry.System == null) || (entry.Scene == null)
				|| !entry.System.Settings.DebugDraw)
				continue;

			using (ProfileScope("Navigation.DebugDraw"))
				NavigationDebugDraw.Draw(entry.Scene, *entry.System.Settings,
					render.DebugScene(entry.Scene));
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
