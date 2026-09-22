using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Vegetation;

/// The Context level vegetation broker: it registers each scene's layer manager as that
/// scene's render data provider.
///
/// The manager itself is injected by scene composition rather than here, and it owns no GPU
/// state of its own: the instanced sets live in the mesh renderer's pool, which evicts them
/// once they stop being extracted.
class VegetationSubsystem : Subsystem, ISceneObserver
{
	/// BORROWED: the render subsystem outlives this one.
	private RenderSubsystem mRender = null;

	public void OnSystemsReady(Scene scene)
	{
		let manager = scene.GetSystem<VegetationLayerComponentManager>();
		if ((manager == null) || (mRender == null))
			return;

		mRender.RegisterProvider(scene, manager);
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
			scenes.RegisterObserver(this, .SystemsReady);

		mRender = Context.GetSubsystem<RenderSubsystem>();
	}

	protected override void OnShutdown()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
			scenes.UnregisterObserver(this);
	}
}
