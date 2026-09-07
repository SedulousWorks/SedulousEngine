namespace Sedulous.RHI;

/// Which planes of a texture a view or a copy touches.
///
/// A depth stencil format has two, and most operations must name ONE of them rather than
/// both: sampling a combined format reads depth or stencil, never the pair.
enum TextureAspect : uint32
{
	All = 0,
	DepthOnly = 1,
	StencilOnly = 2
}
