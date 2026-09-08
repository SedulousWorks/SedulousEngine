namespace Sedulous.Scene;

/// Something that reacts to ONE stage of a scene's lifecycle.
///
/// Registered against a stage on a SceneRegistry. Order breaks ties within a stage, lower
/// first: the data driven replacement for the injection flow this supersedes.
interface ISceneObserver
{
	void OnComposing(Scene scene) {}
	void OnSystemsReady(Scene scene) {}
	void OnDestroying(Scene scene) {}

	int32 Order => 0;
}
