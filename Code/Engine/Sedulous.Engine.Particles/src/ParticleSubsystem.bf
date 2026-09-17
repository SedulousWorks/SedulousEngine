using System;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Particles;

/// The Context level particle broker.
///
/// It owns the ONE renderer, hands each scene's manager its dispatch id, and registers that
/// manager as the scene's render data provider. The simulation and the packing are the
/// manager's; this only wires them to the renderer.
class ParticleSubsystem : Subsystem, ISceneObserver
{
	/// BORROWED: the render subsystem outlives this one.
	private RenderSubsystem mRender = null;
	private ParticleRenderer mRenderer = null ~ delete _;
	private uint16 mBillboardRendererId = 0;

	public void OnSystemsReady(Scene scene)
	{
		EnsureRenderer();

		let manager = scene.GetSystem<ParticleEffectComponentManager>();
		if (manager == null)
			return;

		manager.SetBillboardRendererId(mBillboardRendererId);
		if (mRender != null)
		{
			manager.SetMeshRendererId(mRender.MeshRendererId);
			mRender.RegisterProvider(scene, manager);
		}
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
			scenes.RegisterObserver(this, .SystemsReady);

		mRender = Context.GetSubsystem<RenderSubsystem>();
		// The GPU systems are up by now, the render subsystem having initialised first.
		EnsureRenderer();
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

		let renderer = new ParticleRenderer(device, shaders, mRender.FramesInFlight);
		if (renderer.Initialize() case .Err)
		{
			delete renderer;
			return;
		}

		mRenderer = renderer;
		mBillboardRendererId = mRender.RegisterRenderer(mRenderer);
		// The rings then RETIRE on a grow rather than idling the GPU mid frame.
		mRenderer.SetRetireQueue(mRender.RetireQueue);
	}
}
