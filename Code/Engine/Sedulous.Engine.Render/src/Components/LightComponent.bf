namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;

/// Component for a light source.
[Component]
class LightComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		var type = (uint8)Type;
		s.UInt8("Type", ref type);
		if (s.IsReading) Type = (LightType)type;

		s.Float("ColorR", ref Color.X);
		s.Float("ColorG", ref Color.Y);
		s.Float("ColorB", ref Color.Z);
		s.Float("Intensity", ref Intensity);
		s.Float("Range", ref Range);
		s.Float("InnerConeAngle", ref InnerConeAngle);
		s.Float("OuterConeAngle", ref OuterConeAngle);
		s.Bool("CastsShadows", ref CastsShadows);
		s.Float("ShadowBias", ref ShadowBias);
		s.Float("ShadowNormalBias", ref ShadowNormalBias);
	}

	/// Light type (directional, point, spot).
	[Property]
	public LightType Type = .Directional;

	/// Light color (linear RGB).
	[Property(.Color)]
	public Vector3 Color = .(1, 1, 1);

	/// Light intensity multiplier.
	[Property]
	[Range(0.0f, 100.0f)]
	public float Intensity = 1.0f;

	/// Range for point/spot lights. 0 = infinite (directional).
	[Property]
	[Range(0.0f, 10000.0f)]
	public float Range = 10.0f;

	/// Spot light inner cone angle (degrees).
	[Property]
	[Range(0.0f, 180.0f)]
	public float InnerConeAngle = 30.0f;

	/// Spot light outer cone angle (degrees).
	[Property]
	[Range(0.0f, 180.0f)]
	public float OuterConeAngle = 45.0f;

	/// Whether this light casts shadows.
	[Property]
	public bool CastsShadows = false;

	/// Shadow bias.
	[Property]
	public float ShadowBias = 0.001f;

	/// Shadow normal bias.
	[Property]
	public float ShadowNormalBias = 0.02f;

	/// Render layer mask.
	[Property]
	public uint32 LayerMask = 0xFFFFFFFF;
}
