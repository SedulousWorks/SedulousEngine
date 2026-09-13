using Sedulous.RHI;

namespace Sedulous.Engine.Terrain;

/// The palette array views and the per layer tile scale buffer for one terrain.
///
/// Every map beyond the albedo is OPTIONAL: a null one means no layer supplied that map, and
/// the renderer binds a one by one stand in rather than branching in the shader.
struct PaletteGpu
{
	/// The ALBEDO array, one slice per palette layer.
	public ITextureView ArrayView = null;
	public ITextureView NormalArrayView = null;
	public ITextureView OrmArrayView = null;
	public ITextureView HeightArrayView = null;
	/// A coverage mask. Null means every layer is opaque.
	public ITextureView MaskArrayView = null;

	/// One tile scale per palette layer. The BASE tile rides the view's own constants, so
	/// editing it never rebuilds this buffer.
	public IBuffer TileScaleBuffer = null;

	/// Part of the renderer's bind group cache key, so a rebuild is noticed.
	public uint64 Generation = 0;

	public this() {}
}
