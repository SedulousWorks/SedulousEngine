using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// What the image based lighting precompute exposes to the forward pass.
///
/// The products are PER SCENE, since one frame may render several scenes each with their own
/// environment, and the generation is unique across all of them, so a bind group cache can
/// key on it alone rather than on which scene it came from.
///
/// The graph handles are declared as reads, which is what orders any precompute writes ahead
/// of the shading and barriers them readable.
struct IblBinding
{
	/// The spherical harmonic diffuse irradiance.
	public IBuffer ShBuffer = null;
	/// The prefiltered specular cube, whose mip level stands for roughness.
	public ITextureView PrefilterView = null;
	/// The split sum approximation's lookup table.
	public ITextureView BrdfView = null;
	public float MaxLod = 0.0f;
	public uint64 Generation = 0;

	public RGHandle PrefilterHandle = .Invalid;
	public RGHandle BrdfHandle = .Invalid;
	public RGHandle ShHandle = .Invalid;

	public bool Valid = false;

	public this() {}
}
