using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// A render data provider bound to ONE scene.
///
/// The provider interface itself is scene free, which is what keeps the renderer free of
/// Scene; this pairing is where the binding lives instead. Both halves are BORROWED, and the
/// pairing is dropped when the scene goes.
struct SceneProvider
{
	public Scene Scene;
	public IRenderDataProvider Provider;

	public this(Scene scene, IRenderDataProvider provider)
	{
		Scene = scene;
		Provider = provider;
	}
}
