namespace Sedulous.Engine.Render;

using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;

/// Component for a light source.
class LightComponent : Component
{
	/// Light type (directional, point, spot).
	public LightType Type = .Directional;

	/// Light color (linear RGB).
	public Vector3 Color = .(1, 1, 1);

	/// Light intensity multiplier.
	public float Intensity = 1.0f;

	/// Range for point/spot lights. 0 = infinite (directional).
	public float Range = 10.0f;

	/// Spot light inner cone angle (degrees).
	public float InnerConeAngle = 30.0f;

	/// Spot light outer cone angle (degrees).
	public float OuterConeAngle = 45.0f;

	/// Whether this light casts shadows.
	public bool CastsShadows = false;

	/// Shadow bias.
	public float ShadowBias = 0.001f;

	/// Shadow normal bias.
	public float ShadowNormalBias = 0.02f;

	/// Render layer mask.
	public uint32 LayerMask = 0xFFFFFFFF;
}
