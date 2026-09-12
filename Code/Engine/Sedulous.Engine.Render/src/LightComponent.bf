using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// A light on an entity, which extraction packs into the renderer's shading inputs.
[SerializableComponent("light")]
struct LightComponent : ISerializable
{
	public LightType Type = .Directional;
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	public float Intensity = 1.0f;
	/// Falloff distance, for a point or a spot.
	public float Range = 10.0f;
	/// Spot cone inner half angle, in radians.
	public float InnerAngle = 0.5f;
	/// Spot cone outer half angle, in radians.
	public float OuterAngle = 0.6f;
	public ShadowUpdateMode ShadowUpdate = .Realtime;
	public bool Enabled = true;
	public bool CastsShadows = false;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		var type = (uint32)Type;
		SerializeValue(ar, "type", ref type);
		Type = (LightType)type;

		ar.Key("color");
		Sedulous.Core.Serialization.Serialize(ar, ref Color);
		SerializeValue(ar, "intensity", ref Intensity);
		SerializeValue(ar, "range", ref Range);
		SerializeValue(ar, "innerAngle", ref InnerAngle);
		SerializeValue(ar, "outerAngle", ref OuterAngle);

		var shadowUpdate = (uint32)ShadowUpdate;
		SerializeValue(ar, "shadowUpdate", ref shadowUpdate);
		ShadowUpdate = (ShadowUpdateMode)shadowUpdate;

		SerializeValue(ar, "enabled", ref Enabled);
		SerializeValue(ar, "castsShadows", ref CastsShadows);
	}
}
