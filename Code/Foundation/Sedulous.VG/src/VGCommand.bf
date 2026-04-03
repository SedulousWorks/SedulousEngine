using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// A single draw command representing a batch of geometry with shared state
public struct VGCommand
{
	/// Starting index in the index buffer
	public int32 StartIndex;
	/// Number of indices to draw
	public int32 IndexCount;
	/// Index into texture list (-1 for no texture)
	public int32 TextureIndex;
	/// Clip rectangle in screen coordinates
	public RectangleF ClipRect;
	/// Clipping mode
	public VGClipMode ClipMode;
	/// Blend mode
	public VGBlendMode BlendMode;
	/// Stencil reference value (for stencil clipping)
	public int32 StencilRef;

	public this()
	{
		StartIndex = 0;
		IndexCount = 0;
		TextureIndex = -1;
		ClipRect = default;
		ClipMode = .None;
		BlendMode = .Normal;
		StencilRef = 0;
	}
}
