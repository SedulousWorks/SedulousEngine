using Sedulous.Core;

namespace Sedulous.Render;

/// An explicit camera for one render, in place of the scene's own.
///
/// What an editor viewport or a camera preview renders through: the scene has one primary
/// camera, and a second view of it needs its own without changing the scene.
struct CameraOverride
{
	public ViewCamera Camera = .();
	/// The view's backdrop, LINEAR like all render data (an authored colour is decoded with
	/// ToLinear before it lands here); cornflower blue's sRGB, decoded.
	public Color ClearColor = .(0.127f, 0.300f, 0.846f, 1.0f);

	public this() {}
}
