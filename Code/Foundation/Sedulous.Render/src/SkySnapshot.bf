using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// The per frame environment snapshot driving the image based lighting and the sky.
///
/// Plain types throughout, so the snapshot layer carries no authoring dependency.
struct SkySnapshot
{
	public SkyMode Mode = .Procedural;

	/// The environment radiance master, baked into the cube and so into BOTH the visible
	/// backdrop and the lighting.
	public float Intensity = 1.0f;
	/// A DISPLAY ONLY multiplier on the visible sky and on probe reflections of it. NOT baked
	/// into the environment cube, so it never touches the lighting: a bright backdrop behind
	/// a dim scene is a look rather than a light.
	public float BackgroundIntensity = 1.0f;
	/// The yaw applied to an image or cubemap sky, in radians.
	public float Rotation = 0.0f;

	/// The resolved sky texture for the image modes, or null for the programmatic ones.
	/// Change detection keys on the identity below, NEVER the pointer: a reload reuses freed
	/// addresses.
	public ITextureView Texture = null;
	public uint64 TextureUid = 0;
	public bool TextureIsCube = false;

	public Float3 Horizon = .(0.60f, 0.70f, 0.85f);
	/// Also the flat colour mode's colour.
	public Float3 Zenith = .(0.15f, 0.30f, 0.65f);
	public Float3 Ground = .(0.30f, 0.28f, 0.25f);

	public float SunIntensity = 1.0f;
	/// The sun disc's angular size, in degrees.
	public float SunAngularSize = 0.5f;
	/// The analytic model's atmospheric turbidity.
	public float Turbidity = 3.0f;

	/// Render time dimmers on the sky's LIGHTING, never on the visible sky: the spherical
	/// harmonic irradiance and the prefiltered specular, applied in the forward shading.
	public float IblDiffuseIntensity = 1.0f;
	public float IblSpecularIntensity = 1.0f;

	public this() {}
}
