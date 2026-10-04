using System;
using Sedulous.Scene;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Render;

namespace Sedulous.Engine.Render;

/// A light on an entity, which extraction packs into the renderer's shading inputs.
[SerializableComponent("light", 2, 1)]
[DisplayName("Light")]
[Category("Rendering")]
[Scriptable]
struct LightComponent : ISerializable
{
	[Scriptable]
	public LightType Type = .Directional;
	[Scriptable]
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	[Scriptable]
	[Range(0.0f, 50.0f, 0.1f)]
	public float Intensity = 1.0f;
	/// Falloff distance, for a point or a spot.
	[Scriptable]
	[Range(0.0f, 500.0f, 0.5f)]
	[VisibleWhen("Type=1,2")]
	[Description("Falloff distance (point/spot lights)")]
	public float Range = 10.0f;
	/// Spot cone inner half angle, in radians.
	[Scriptable]
	[Range(0.0f, 1.55f, 0.01f)]
	[VisibleWhen("Type=2")]
	[Description("Spot cone inner half-angle (radians)")]
	public float InnerAngle = 0.5f;
	/// Spot cone outer half angle, in radians.
	[Scriptable]
	[Range(0.0f, 1.55f, 0.01f)]
	[VisibleWhen("Type=2")]
	[Description("Spot cone outer half-angle (radians)")]
	public float OuterAngle = 0.6f;
	[Scriptable]
	[VisibleWhen("CastsShadows")]
	public ShadowUpdateMode ShadowUpdate = .Realtime;
	[Scriptable]
	public bool Enabled = true;
	[Scriptable]
	public bool CastsShadows = false;
	/// The shadow's tuning, shown while it casts shadows: how dark the shadow gets, the normal
	/// offset in shadow texels (what keeps a wall the light grazes from shadowing itself), and
	/// the depth compare bias as a scale of the light type's default (the sun's and a local
	/// light's depths are in different spaces).
	[Scriptable]
	[Range(0.0f, 1.0f, 0.01f)]
	[VisibleWhen("CastsShadows")]
	[Description("How dark the shadow gets: 1 = full, 0 = none")]
	public float ShadowStrength = 1.0f;
	[Scriptable]
	[Range(0.0f, 4.0f, 0.05f)]
	[VisibleWhen("CastsShadows")]
	[Description("Normal offset in shadow texels: raise it if a surface the light grazes shadows itself (acne), lower it if a shadow parts from its caster")]
	public float ShadowNormalBias = ShadowBiasDefaults.NormalBias;
	[Scriptable]
	[Range(0.0f, 4.0f, 0.05f)]
	[VisibleWhen("CastsShadows")]
	[Description("Depth-compare bias, as a scale of the default for the light's type (1 = default)")]
	public float ShadowDepthBiasScale = 1.0f;

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
		// Version 1 had no shadow controls: the defaults, which are what it rendered with. The
		// scene re-saves as the current version.
		if ((ar.Mode == .Read) && (ar.Version == 1))
			return;
		SerializeValue(ar, "shadowStrength", ref ShadowStrength);
		SerializeValue(ar, "shadowNormalBias", ref ShadowNormalBias);
		SerializeValue(ar, "shadowDepthBiasScale", ref ShadowDepthBiasScale);
	}
}
