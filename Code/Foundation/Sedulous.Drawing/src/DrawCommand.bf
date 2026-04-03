using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A single draw command representing a batch of geometry with shared state
public struct DrawCommand
{
	/// Index into the texture list (-1 for no texture/solid color)
	public int32 TextureIndex;
	/// Starting index in the index buffer
	public int32 StartIndex;
	/// Number of indices to draw
	public int32 IndexCount;
	/// Clip rectangle in screen coordinates
	public RectangleF ClipRect;
	/// Blend mode for this command
	public BlendMode BlendMode;
	/// Clipping mode
	public ClipMode ClipMode;
	/// Stencil reference value (for stencil clipping)
	public int32 StencilRef;

	public this()
	{
		TextureIndex = -1;
		StartIndex = 0;
		IndexCount = 0;
		ClipRect = default;
		BlendMode = .Normal;
		ClipMode = .None;
		StencilRef = 0;
	}

	public this(int32 textureIndex, int32 startIndex, int32 indexCount, RectangleF clipRect, BlendMode blendMode, ClipMode clipMode, int32 stencilRef)
	{
		TextureIndex = textureIndex;
		StartIndex = startIndex;
		IndexCount = indexCount;
		ClipRect = clipRect;
		BlendMode = blendMode;
		ClipMode = clipMode;
		StencilRef = stencilRef;
	}
}
