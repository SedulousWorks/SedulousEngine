using Sedulous.Render;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// One target camera to render: the texture it draws into, and the camera to draw with (its
/// projection at the texture's aspect, its clear colour).
struct TargetCameraView
{
	/// BORROWED: the camera's Ref holds it.
	public Texture Target = null;
	public CameraOverride Camera = .();

	public this() {}
}
