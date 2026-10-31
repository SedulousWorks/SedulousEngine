using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Image.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Image;

/// The image page (Raptor's editor-gui spec, 5.4, layer 2), on the image pages' markup
/// (Data/Editor/ImagePage.xml): the decoded source in the picture, which zooms, pans, shows a
/// channel and reads the pixel under the pointer, beside the asset's fields (its colour space) and
/// what it says of its source (its size, its format), read only. What every asset page does is
/// AssetObjectPage's.
class ImageEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/ImagePage.xml";

	private ImagePreview mPreview = null ~ delete _;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(ImageAsset), cMarkupPath)
	{
		if (Content != null)
			mPreview = new ImagePreview(Content);
		LoadPreview();
	}

	// === For tests ===

	public ImagePreview Preview => mPreview;

	/// Decodes the source file and shows it, with its facts.
	private void LoadPreview()
	{
		let asset = ObjectAs<ImageAsset>();
		if (asset == null)
			return;
		if (asset.FileName.IsEmpty || (Context.Project == null))
		{
			if (mPreview != null)
				mPreview.ShowNone("This image names no source file.");
			return;
		}
		let path = PathJoin(Context.Project.SourcesRoot(.. scope .()), asset.FileName.Value, .. scope .());
		let source = scope Sedulous.Image.Image();
		if (!(ImageIO.LoadImage(path, source) case .Ok) || (source.Width == 0) || (source.Height == 0))
		{
			GlobalLog(.Warning, "Editor: image source missing or undecodable: {}", path);
			if (mPreview != null)
				mPreview.ShowNone(scope String()..AppendF("{} is missing or did not decode.", asset.FileName.Value));
			return;
		}
		SetFact("Dimensions", scope String()..AppendF("{} x {}", source.Width, source.Height));
		SetFact("Pixel Format", ImageAssetEdit.PixelFormatLabel(source.Format));
		SetFact("Data Size", scope String()..AppendF("{} KiB", source.PixelData.Length / 1024));
		// The display is 8-bit: converted through the image library (floats clamp).
		if (mPreview != null)
			mPreview.Show(source.ConvertFormat(.RGBA8));
	}
}
