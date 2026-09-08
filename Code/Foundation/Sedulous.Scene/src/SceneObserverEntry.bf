namespace Sedulous.Scene;

/// One observer's registration against one stage.
struct SceneObserverEntry
{
	public ISceneObserver Observer;
	public SceneLifecycleStage Stage;

	public this(ISceneObserver observer, SceneLifecycleStage stage)
	{
		Observer = observer;
		Stage = stage;
	}
}
