using System;
using Sedulous.Image;
using Sedulous.Resource;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Editor.GameUI;

/// What the theme page's preview stylesheet reads as it parses, the edited text not being
/// cooked yet: an @icon names a vector image asset, read through the editor's resource manager
/// (its cooked product, as the theme's cook embeds it); an image is a texture, which the game
/// UI's own provider resolves.
class ThemePreviewResources : IResourceProvider
{
	/// BORROWED, both, and either may be null.
	private ResourceManager mResources;
	private IResourceProvider mImages;

	public this(ResourceManager resources, IResourceProvider images)
	{
		mResources = resources;
		mImages = images;
	}

	public bool LoadText(StringView path, String outText)
	{
		if (mResources == null)
			return false;
		// "{guid}" or the bare guid, as an image source is written.
		if (!(Guid.Parse(path) case .Ok(let id)) || id.IsNil)
			return false;
		let image = mResources.Bind<UIVectorImage>(id).Get;
		if ((image == null) || image.Svg.IsEmpty)
			return false;
		outText.Set(image.Svg);
		return true;
	}

	public ImageData LoadImage(StringView path) => (mImages != null) ? mImages.LoadImage(path) : null;
}
