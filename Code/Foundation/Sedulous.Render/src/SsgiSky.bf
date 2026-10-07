using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// The ambient the forward lit a view's scene with, which a GI hit replaces: the scene's SH sky
/// (when its environment lighting is active; else none) scaled by its diffuse dimmer, plus the
/// flat fill, and the camera's world matrix to take the G-buffer's view space normal to world
/// space, where the SH sky is.
struct SsgiSky
{
	/// The scene's SH9 irradiance; null is none.
	public IBuffer ShBuffer = null;
	/// Read by the composite, which orders the SH bake ahead of it.
	public RGHandle ShHandle = .Invalid;
	/// The environment context's, a key of the composite's bind group.
	public uint64 Generation = 0;
	/// The environment's sky lighting dimmer.
	public float IblDiffuse = 1.0f;
	/// The flat fill, linear.
	public Float3 Ambient = .(0.0f, 0.0f, 0.0f);
	public Float4x4 ViewToWorld = .Identity();

	public this() {}
}
