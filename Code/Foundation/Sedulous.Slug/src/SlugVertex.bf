using System;

namespace Sedulous.Slug;

/// Vertex with 8-bit unsigned integer color (68 bytes).
///
/// GPU attribute layout:
///   [0] position  (offset  0): 4x float32 - xy = object pos, zw = dilation normal
///   [1] texcoord  (offset 16): 4x float32 - xy = em-space coords, zw = packed glyph data
///   [2] jacobian  (offset 32): 4x float32 - 2x2 inverse Jacobian
///   [3] banding   (offset 48): 4x float32 - band scale + offset
///   [4] color     (offset 64): 4x uint8   - linear RGBA
[CRepr]
public struct Vertex4U
{
	public Vector4D position;
	public Vector4D texcoord;
	public Vector4D jacobian;
	public Vector4D banding;
	public Color4U color;
}

/// Vertex with 32-bit floating-point color (80 bytes).
[CRepr]
public struct VertexRGBA
{
	public Vector4D position;
	public Vector4D texcoord;
	public Vector4D jacobian;
	public Vector4D banding;
	public ColorRGBA color;
}

/// Triangle with 16-bit vertex indices.
[CRepr]
public struct Triangle16
{
	public uint16[3] index;

	public this() { index = .(0, 0, 0); }
	public this(uint16 i0, uint16 i1, uint16 i2) { index = .(i0, i1, i2); }
}

/// Triangle with 32-bit vertex indices.
[CRepr]
public struct Triangle32
{
	public uint32[3] index;

	public this() { index = .(0, 0, 0); }
	public this(uint32 i0, uint32 i1, uint32 i2) { index = .(i0, i1, i2); }
}

/// Buffer descriptor for generated vertex and triangle data.
[CRepr]
public struct GeometryBuffer
{
	public Vertex4U* vertexData;
	public Triangle16* triangleData;
	public uint32 vertexIndex;
	public VertexType vertexType;
	public IndexType indexType;

	public this()
	{
		vertexData = null;
		triangleData = null;
		vertexIndex = 0;
		vertexType = .Vertex4U;
		indexType = .Index16;
	}
}

/// Uniform data for the Slug vertex shader constant buffer.
/// Matches cbuffer ParamStruct { float4 slug_matrix[4]; float4 slug_viewport; }
[CRepr]
public struct SlugUniforms
{
	/// MVP matrix: 4 rows of float4, row-major.
	public float[16] matrix;
	/// Viewport: (width, height, 0, 0) in pixels.
	public float[4] viewport;

	/// Create uniforms for 2D orthographic rendering.
	/// Maps screen coords [0,width] x [0,height] (Y-down) to clip space.
	/// flipY: set to Device.FlipProjectionRequired (true for Vulkan).
	public static SlugUniforms Ortho2D(float width, float height, bool flipY = false)
	{
		SlugUniforms u = default;

		// Same approach as DrawingRenderer:
		// Normal (DX12):  CreateOrthographicOffCenter(0, width, height, 0, -1, 1)
		//   → Y: maps 0→+1 (top), height→-1 (bottom), clip Y-up
		// Vulkan flip:    CreateOrthographicOffCenter(0, width, 0, height, -1, 1)
		//   → Y: maps 0→-1 (top in Vulkan), height→+1 (bottom in Vulkan)

		// Row 0: X maps [0, width] → [-1, +1]
		u.matrix[0]  = 2.0f / width;
		u.matrix[3]  = -1.0f;

		if (flipY)
		{
			// Vulkan: bottom=0, top=height → scale=2/h, translate=-1
			u.matrix[5]  = 2.0f / height;
			u.matrix[7]  = -1.0f;
		}
		else
		{
			// DX12: bottom=height, top=0 → scale=-2/h, translate=+1
			u.matrix[5]  = -2.0f / height;
			u.matrix[7]  = 1.0f;
		}

		u.matrix[10] = 1.0f;
		u.matrix[15] = 1.0f;
		u.viewport[0] = width;
		u.viewport[1] = height;
		return u;
	}
}
