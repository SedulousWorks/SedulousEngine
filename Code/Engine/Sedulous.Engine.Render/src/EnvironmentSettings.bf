using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// The scene's environment: what lights it from all around, and what the sky looks like.
///
/// ONE per scene rather than a component, because there is only ever one environment.
// The inspector writes a field through RUNTIME reflection, so every field needs its
// data emitted; an attribute on a field forces that, a bare field has nothing to.
[Reflect(.Type | .NonStaticFields)]
[DisplayName("Environment")]
[Category("Rendering")]
[Scriptable(.AllPublic)]
struct EnvironmentSettings
{
	/// Where the values come from: the scene's own below, or Profile's while the source is
	/// Profile. The scene's alone: a profile carries no source.
	[SceneOnly]
	[Description("Where the values come from: this scene's own, or a shared Environment Profile asset")]
	public SettingsSource Source = .Scene;
	[SceneOnly]
	[VisibleWhen("Source=1")]
	[Description("The shared Environment Profile whose values this scene uses")]
	public Ref<EnvironmentProfile> Profile = .(Guid());

	/// A flat ambient FILL added on top of the image based ambient in every sky mode, so an
	/// intensity of nought is pure IBL. Where IBL is unavailable this is the only ambient. sRGB,
	/// like every colour (the default is the look it had when colours were read raw).
	public Color AmbientColor = .(0.349f, 0.381f, 0.437f, 1.0f);
	[Range(0.0f, 2.0f, 0.01f)]
	[Description("Flat ambient fill added on top of the image-based ambient (0 = pure IBL)")]
	public float AmbientIntensity = 0.3f;

	public SkyMode SkyMode = .Procedural;
	/// The environment radiance MASTER, baked once into the environment cube, so it scales
	/// the visible sky AND the lighting derived from that cube together. Dim it to lower the
	/// whole environment at once.
	[Range(0.0f, 10.0f, 0.05f)]
	[Description("Environment radiance master: scales the sky AND the IBL lighting")]
	public float SkyIntensity = 1.0f;
	/// A display only dimmer on the VISIBLE sky, layered on top of the master. It does not
	/// touch the lighting, which is what makes it the lever for calming a too bright sky
	/// while keeping the scene lit.
	[Range(0.0f, 4.0f, 0.05f)]
	[DisplayName("Sky Background Intensity")]
	[Description("Dims only the VISIBLE sky backdrop; leaves the IBL lighting")]
	public float SkyBackgroundIntensity = 0.5f;
	/// Yaw in radians, for an image based sky.
	[Range(0.0f, 6.2832f, 0.01f)]
	[VisibleWhen("SkyMode=3,4")]
	[Description("Sky yaw (radians)")]
	public float SkyRotation = 0.0f;
	/// The textured modes' source: an equirectangular HDR, or a cube shaped texture. The
	/// untextured modes ignore it.
	[VisibleWhen("SkyMode=3,4")]
	[Description("HDR (equirect) or cube texture for the textured sky modes")]
	public Ref<Texture> SkyTexture = .(Guid());

	/// The procedural sky: a soft, hazy, low saturation daytime blue rather than a vivid one,
	/// which means a dimmer horizon, a desaturated zenith and a near neutral ground. sRGB.
	[VisibleWhen("SkyMode=0")]
	public Color SkyHorizon = .(0.748f, 0.798f, 0.854f, 1.0f);
	/// Also the colour the flat mode uses.
	[VisibleWhen("SkyMode=0,2")]
	[DisplayName("Sky Zenith / Color")]
	[Description("Zenith color (procedural sky); the flat color in Color mode")]
	public Color SkyZenith = .(0.485f, 0.634f, 0.786f, 1.0f);
	[VisibleWhen("SkyMode=0")]
	public Color SkyGround = .(0.547f, 0.547f, 0.547f, 1.0f);
	[Range(0.0f, 10.0f, 0.05f)]
	[VisibleWhen("SkyMode=0,1,2")]
	public float SunIntensity = 1.0f;
	/// The sun disc size, in degrees.
	[Range(0.05f, 10.0f, 0.05f)]
	[VisibleWhen("SkyMode=0,1,2")]
	[Description("Sun disc size (degrees)")]
	public float SunAngularSize = 0.5f;
	/// Analytic haze, roughly two to ten.
	[Range(2.0f, 10.0f, 0.1f)]
	[VisibleWhen("SkyMode=1")]
	[Description("Preetham haze (2 = clear, 10 = hazy)")]
	public float Turbidity = 3.0f;

	/// Dimmers on the sky's LIGHTING contribution alone, split by term: diffuse scales the
	/// irradiance, specular the prefiltered reflections. One is full physical strength, where
	/// a blue sky legitimately blue lights an unlit scene. Turn the diffuse down to calm that
	/// cast without touching the sky or its reflections.
	[DisplayName("IBL Diffuse Intensity")]
	[Range(0.0f, 2.0f, 0.01f)]
	[Description("Sky lighting (diffuse) strength - dims the sky's color cast on surfaces without changing the visible sky")]
	public float IblDiffuseIntensity = 1.0f;
	[DisplayName("IBL Specular Intensity")]
	[Range(0.0f, 2.0f, 0.01f)]
	[Description("Sky reflection strength on surfaces (probes keep their own intensity)")]
	public float IblSpecularIntensity = 1.0f;

	/// The sun's shadow reach: how far from the camera its cascades cover (clamped to the
	/// camera's far plane, but independent of it: a street scale scene keeps its near shadows
	/// sharp with a short reach while the camera sees far), how the cascade splits blend
	/// (nought even, one more of the map near the camera) and the width it fades out over at
	/// the reach.
	[Range(5.0f, 1000.0f, 1.0f)]
	[Description("How far from the camera the sun's shadows reach. Shorter keeps near shadows sharp (a roof's shadow on a wall); longer covers more ground")]
	public float ShadowDistance = 300.0f;
	[Range(0.0f, 1.0f, 0.01f)]
	[Description("How the shadow map is shared out over the reach: 0 = evenly, 1 = most of it near the camera")]
	public float ShadowCascadeSplit = 0.5f;
	[Range(0.0f, 200.0f, 1.0f)]
	[Description("The width shadows fade out over at the reach")]
	public float ShadowFadeDistance = 40.0f;

	public this() {}
}
