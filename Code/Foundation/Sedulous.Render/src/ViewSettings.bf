using Sedulous.RHI;

namespace Sedulous.Render;

/// The per view settings a render is driven with.
struct ViewSettings
{
	public ClearColor Clear = .CornflowerBlue;

	/// The viewport sub rectangle within the target, in pixels. A width of zero means the
	/// whole target.
	public int32 ViewportX = 0;
	public int32 ViewportY = 0;
	public uint32 ViewportWidth = 0;
	public uint32 ViewportHeight = 0;

	/// The imported colour target's state handling. The texture is what the graph barriers,
	/// and null means the host manages it, in which case the graph touches no barrier at all.
	/// The final state is where the graph leaves it: the render target state to present from,
	/// or a read state for an offscreen target the caller then samples or blits.
	public ITexture TargetTexture = null;
	public ResourceState TargetCurrentState = .RenderTarget;
	public ResourceState TargetFinalState = .RenderTarget;

	/// The RESOLVED post processing for this view, which the subsystem fills in from the
	/// scene's authored settings and the compose passes read back per view.
	public ViewPostConfig Post = .();

	/// What to show instead of the final image. Null is the final image.
	public ViewDebugView Debug = null;

	public this() {}
}
