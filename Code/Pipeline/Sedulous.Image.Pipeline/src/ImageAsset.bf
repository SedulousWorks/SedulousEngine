using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Pipeline.Core;

namespace Sedulous.Image.Pipeline;

/// An image file, with the colour space that says how to read it.
[Serializable]
class ImageAsset : Asset
{
	public ImageColorSpace ColorSpace = .Srgb;
}
