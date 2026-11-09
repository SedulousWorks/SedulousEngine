using System;

namespace Sedulous.Scene.Resource;

/// Gives a scene every manager the application knows, for a scratch scene that has to read an
/// arbitrary stream: what a resource factory asks its host for (IResourceServices) when it reads
/// scene data it does not own. The application composes it from its whole composition, plugins
/// included; a host without one (a headless tool) offers none.
class SceneComposer
{
	private delegate void(Scene scene) mInstall ~ delete _;

	/// TAKES OWNERSHIP of `install`.
	public this(delegate void(Scene scene) install)
	{
		mInstall = install;
	}

	/// Adds every manager to `scene`, which should be empty.
	public void Install(Scene scene) => mInstall(scene);
}
