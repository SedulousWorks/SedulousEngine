using Sedulous.Core;

namespace Sedulous.Render;

/// The active directional shadow caster, as extraction leaves it: the direction, and whether
/// there is one at all.
///
/// The cascade matrices are NOT here. Fitting them needs the camera frustum, which extraction
/// does not have, so they are derived later where it does.
struct DirectionalShadow
{
	public Float3 Direction = .(0, -1, 0);
	public bool Valid = false;
	/// The caster light's own biases and strength, carried to its cascades.
	public float NormalBias = ShadowBiasDefaults.NormalBias; // texels
	public float DepthBias = ShadowBiasDefaults.DepthBias;
	public float Strength = 1.0f;

	public this() {}
}
