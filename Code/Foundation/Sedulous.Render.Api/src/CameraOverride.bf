using Sedulous.Core;

namespace Sedulous.Render;

/// An explicit camera for one render, in place of the scene's own.
///
/// What an editor viewport or a camera preview renders through: the scene has one primary
/// camera, and a second view of it needs its own without changing the scene.
struct CameraOverride
{
	public ViewCamera Camera = .();
	/// The view's backdrop.
	public Color ClearColor = .(0.392f, 0.584f, 0.929f, 1.0f);

	public this() {}
}
