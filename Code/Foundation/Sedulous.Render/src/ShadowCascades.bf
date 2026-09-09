using Sedulous.Core;

namespace Sedulous.Render;

/// The cascaded shadow maps for the directional caster, fitted per frame to the primary
/// view's frustum.
///
/// Shared by every view, because they are fitted to the primary camera: a second view of the
/// same scene reuses them rather than refitting, which would double the shadow rendering for
/// a difference nobody sees.
struct ShadowCascades
{
	public const int Count = 4;

	/// World into each cascade's light clip space.
	public Float4x4[Count] ViewProjection = .(.Identity(), .Identity(), .Identity(), .Identity());
	/// The view space depth each cascade ends at, which is what selects one.
	public float[Count] SplitFar = .(0.0f, 0.0f, 0.0f, 0.0f);
	/// World units per shadow texel, which the normal offset bias is measured in: a fixed
	/// bias is either useless in the near cascade or peters out in the far one.
	public float[Count] TexelWorldSize = .(0.0f, 0.0f, 0.0f, 0.0f);

	public bool Valid = false;

	public this() {}
}
