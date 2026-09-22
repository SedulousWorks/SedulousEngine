using System;
using System.Collections;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Terrain;

/// The Context level terrain broker.
///
/// It owns the ONE renderer, hands each scene's manager the device and the dispatch id, and
/// registers that manager as the scene's render data provider. No terrain code lives in the
/// render subsystem, so attaching a terrain component is all an app has to do.
///
/// The manager itself is injected by scene composition rather than here.
class TerrainSubsystem : Subsystem, ISceneObserver
{
	/// BORROWED: the render subsystem outlives this one.
	private RenderSubsystem mRender = null;
	private TerrainRenderer mRenderer = null ~ delete _;
	private uint16 mRendererId = 0;

	/// BORROWED, and pruned as scenes die: what still needs its GPU state freed while the
	/// device is alive.
	private List<TerrainComponentManager> mManagers = new .() ~ delete _;

	public void OnSystemsReady(Scene scene)
	{
		EnsureRenderer();

		let manager = scene.GetSystem<TerrainComponentManager>();
		if ((manager == null) || (mRender == null))
			return;

		manager.SetRenderContext(mRender.Device, mRendererId, mRender.RetireQueue);
		mRender.RegisterProvider(scene, manager);
		mManagers.Add(manager);
	}

	public void OnDestroying(Scene scene)
	{
		// The scene dies while the device is still alive, so free its manager's GPU state NOW:
		// the manager's own destructor may well run after the device has gone.
		let manager = scene.GetSystem<TerrainComponentManager>();
		if (manager == null)
			return;

		manager.ClearGpu();

		let at = mManagers.IndexOf(manager);
		if (at >= 0)
			mManagers.RemoveAt(at);
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

		mRender = Context.GetSubsystem<RenderSubsystem>();
		// The GPU systems are up by now, the render subsystem having initialised first.
		EnsureRenderer();
	}

	protected override void OnPrepareShutdown()
	{
		// A scene still alive at shutdown clears its GPU state HERE, in the prepare phase:
		// every subsystem prepares before any shuts down, so the caches' retired textures land
		// in the render subsystem's queue before it flushes. Shutdown runs in reverse update
		// order, render first, so clearing in OnShutdown retired into a queue already flushed
		// and the images leaked.
		for (let manager in mManagers)
			manager.ClearGpu();
		mManagers.Clear();
	}

	protected override void OnShutdown()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
			scenes.UnregisterObserver(this);
	}

	/// Creates and registers the renderer once the render systems exist. IDEMPOTENT, because
	/// it is called both when this becomes ready and when each scene does, and which comes
	/// first depends on when the scene was created.
	private void EnsureRenderer()
	{
		if ((mRenderer != null) || (mRender == null))
			return;

		let device = mRender.Device;
		let shaders = mRender.Shaders;
		if ((device == null) || (shaders == null))
			return;

		let renderer = new TerrainRenderer(device, shaders, mRender.FramesInFlight);
		if (renderer.Initialize() case .Err)
		{
			delete renderer;
			return;
		}

		mRenderer = renderer;
		mRendererId = mRender.RegisterRenderer(mRenderer);
		// The rings then RETIRE on a grow rather than idling the GPU mid frame.
		mRenderer.SetRetireQueue(mRender.RetireQueue);
	}
}
