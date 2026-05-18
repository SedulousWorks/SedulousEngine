namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

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

		s.BeginObject("Color");
		s.Float("X", ref Color.X);
		s.Float("Y", ref Color.Y);
		s.Float("Z", ref Color.Z);
		s.EndObject();
		s.Float("Intensity", ref Intensity);
		s.Float("Range", ref Range);
		s.Float("InnerConeAngle", ref InnerConeAngle);
		s.Float("OuterConeAngle", ref OuterConeAngle);
		s.Bool("CastsShadows", ref CastsShadows);
		s.Float("ShadowBias", ref ShadowBias);
		s.Float("ShadowNormalBias", ref ShadowNormalBias);
		s.UInt32("LayerMask", ref LayerMask);
	}

	/// Light type (directional, point, spot).
	[Property(.Default, "Type", "Type")]
	public LightType Type = .Directional;

	/// Light color (linear RGB).
	[Property(.Color, "Color", "Color")]
	public Vector3 Color = .(1, 1, 1);

	/// Light intensity multiplier.
	[Property(.Default, "Intensity", "Intensity")]
	[Range(0.0f, 100.0f)]
	public float Intensity = 1.0f;

	/// Range for point/spot lights. 0 = infinite (directional).
	[Property(.Default, "Range", "Range")]
	[Range(0.0f, 10000.0f)]
	public float Range = 10.0f;

	/// Spot light inner cone angle (degrees).
	[Property(.Default, "Inner Cone Angle", "InnerConeAngle")]
	[Range(0.0f, 180.0f)]
	public float InnerConeAngle = 30.0f;

	/// Spot light outer cone angle (degrees).
	[Property(.Default, "Outer Cone Angle", "OuterConeAngle")]
	[Range(0.0f, 180.0f)]
	public float OuterConeAngle = 45.0f;

	/// Whether this light casts shadows.
	[Property(.Default, "Casts Shadows", "CastsShadows")]
	public bool CastsShadows = false;

	/// Shadow bias.
	[Property(.Default, "Shadow Bias", "ShadowBias")]
	public float ShadowBias = 0.001f;

	/// Shadow normal bias.
	[Property(.Default, "Shadow Normal Bias", "ShadowNormalBias")]
	public float ShadowNormalBias = 0.02f;

	/// Render layer mask.
	[Property(.Default, "Layer Mask", "LayerMask")]
	public uint32 LayerMask = 0xFFFFFFFF;
}
