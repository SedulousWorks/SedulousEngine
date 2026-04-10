namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;

/// Light type.
public enum LightType : uint8
{
	Directional,
	Point,
	Spot
}

/// Render data for a light. Not drawn — consumed by the lighting system.
///
/// Allocated from RenderContext.FrameAllocator — trivially destructible.
public class LightRenderData : RenderData
{
	/// Light type.
	public LightType Type;

	/// Light color (linear RGB).
	public Vector3 Color;

	/// Light intensity.
	public float Intensity;

	/// Direction (for directional and spot lights).
	public Vector3 Direction;

	/// Range (for point and spot lights). 0 = infinite (directional).
	public float Range;

	/// Spot light inner cone angle (radians).
	public float InnerConeAngle;

	/// Spot light outer cone angle (radians).
	public float OuterConeAngle;

	/// Whether this light casts shadows.
	public bool CastsShadows;

	/// Shadow bias.
	public float ShadowBias;

	/// Shadow normal bias.
	public float ShadowNormalBias;
}
