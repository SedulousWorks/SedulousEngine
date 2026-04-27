using System;
using Sedulous.Slug;
using Sedulous.RHI;

namespace Sedulous.Slug.Renderer;

/// GPU resources for Slug text rendering.
/// Created once per font, reused for all draw calls with that font.
public class SlugRenderResources : IDisposable
{
	// Textures
	public ITexture CurveTexture ~ delete _;
	public ITexture BandTexture ~ delete _;
	public ITextureView CurveTextureView ~ delete _;
	public ITextureView BandTextureView ~ delete _;

	// Shaders
	public IShaderModule VertexShader ~ delete _;
	public IShaderModule PixelShader ~ delete _;

	// Pipeline
	public IRenderPipeline Pipeline ~ delete _;
	public IPipelineLayout PipelineLayout ~ delete _;
	public IBindGroupLayout TextureBindGroupLayout ~ delete _;
	public IBindGroupLayout UniformBindGroupLayout ~ delete _;
	public IBindGroup TextureBindGroup ~ delete _;

	// Uniform buffer
	public IBuffer UniformBuffer ~ delete _;

	// Metadata
	public Integer2D CurveTextureSize;
	public Integer2D BandTextureSize;

	public void Dispose() { }
}

/*/// Uniform data for the Slug vertex shader constant buffer.
/// Matches the cbuffer ParamStruct in the HLSL shader.
[CRepr]
public struct SlugUniforms
{
	/// MVP matrix: 4 rows of float4, row-major, transforms column vectors.
	public float[16] matrix;
	/// Viewport: (width, height, 0, 0) in pixels.
	public float[4] viewport;

	/// Create uniforms for 2D orthographic rendering.
	/// Maps [0,width] x [0,height] to clip space with Y pointing down (screen coords).
	public static SlugUniforms Ortho2D(float width, float height)
	{
		SlugUniforms u = default;
		// Row 0: 2/w, 0, 0, -1
		u.matrix[0]  = 2.0f / width;
		u.matrix[3]  = -1.0f;
		// Row 1: 0, -2/h, 0, 1  (flip Y for screen coords: top=0, bottom=height)
		u.matrix[5]  = -2.0f / height;
		u.matrix[7]  = 1.0f;
		// Row 2: 0, 0, 1, 0
		u.matrix[10] = 1.0f;
		// Row 3: 0, 0, 0, 1
		u.matrix[15] = 1.0f;
		u.viewport[0] = width;
		u.viewport[1] = height;
		return u;
	}
}*/
