using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;
using Sedulous.Image;

namespace Sedulous.Fonts.Resource;

/// One baked size of a loaded font: the rasterizer-free font, its atlas, and the atlas as
/// an image a renderer can upload.
///
/// The image is built once at load rather than on demand, because the two encodings reach
/// it differently: a distance field atlas already holds RGBA8, while a coverage atlas holds
/// one byte per texel and has to be expanded. Doing it here is what lets the draw path
/// treat both the same.
class FontEntry
{
	public float PixelHeight;
	public BakedFont Font ~ delete _;
	public IFontAtlas Atlas ~ delete _;
	public OwnedImageData AtlasImage ~ delete _;
}
