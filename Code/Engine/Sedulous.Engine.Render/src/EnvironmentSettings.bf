using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// The scene's environment: what lights it from all around, and what the sky looks like.
///
/// ONE per scene rather than a component, because there is only ever one environment.
[DisplayName("Environment")]
[Category("Rendering")]
[Scriptable(.AllPublic)]
struct EnvironmentSettings
{
	/// A flat ambient FILL added on top of the image based ambient in every sky mode, so an
	/// intensity of nought is pure IBL. Where IBL is unavailable this is the only ambient.
	public Color AmbientColor = .(0.10f, 0.12f, 0.16f, 1.0f);
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
	/// which means a dimmer horizon, a desaturated zenith and a near neutral ground.
	[VisibleWhen("SkyMode=0")]
	public Color SkyHorizon = .(0.52f, 0.60f, 0.70f, 1.0f);
	/// Also the colour the flat mode uses.
	[VisibleWhen("SkyMode=0,2")]
	[DisplayName("Sky Zenith / Color")]
	[Description("Zenith color (procedural sky); the flat color in Color mode")]
	public Color SkyZenith = .(0.20f, 0.36f, 0.58f, 1.0f);
	[VisibleWhen("SkyMode=0")]
	public Color SkyGround = .(0.26f, 0.26f, 0.26f, 1.0f);
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

	public this() {}
}
