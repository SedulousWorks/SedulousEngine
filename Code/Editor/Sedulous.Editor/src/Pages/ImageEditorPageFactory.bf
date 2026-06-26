using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Images;
using Sedulous.Images.Resources;
using Sedulous.Resources;
namespace Sedulous.Editor.Pages;

/// Creates editor pages for `.image` files. Image preview + metadata,
/// mirroring `TextureEditorPageFactory` but for the simpler
/// `ImageResource` (no sampler / mipmap / wrap fields - it's raw pixel
/// data, no GPU-side knobs).
class ImageEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".image"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".image", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Image", "Path is not inside any mounted scheme.", context);

		ImageResource imgRes = null;
		if (context.ResourceSystem.LoadResource<ImageResource>(uri) case .Ok(let handle))
			imgRes = handle.Resource;

		let page = new ImageEditorPage(path, imgRes);
		page.SetContentView(BuildImageView(path, imgRes));
		return page;
	}

	private static View BuildImageView(StringView path, ImageResource imgRes)
	{
		let root = new SplitView(.Horizontal);

		// Left: image preview with dark background.
		let previewPanel = new Panel();
		previewPanel.SetStyle(.Background, new ColorDrawable(.(30, 30, 35, 255)));

		let imageView = new ImageView();
		imageView.ScaleType.Value = .FitCenter;

		// `Image` is itself `IImageData` now, so it goes straight into
		// the view - no wrapping ImageDataRef required (TextureEditorPage
		// still wraps because it predates Image-as-IImageData; the
		// behaviour is the same).
		if (imgRes?.Image != null)
			imageView.Image = imgRes.Image;

		previewPanel.AddView(imageView);

		// Right: metadata panel.
		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Image Properties");
		MeshEditorPageFactory.AddSeparator(infoPanel);

		if (imgRes?.Image != null)
		{
			let image = imgRes.Image;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Dimensions", scope $"{image.Width} x {image.Height}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Format", scope $"{image.Format}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Color Space", scope $"{image.ColorSpace}");
			let dataSize = image.DataSize;
			if (dataSize > 1024 * 1024)
				MeshEditorPageFactory.AddInfoRow(infoPanel, "Data Size", scope $"{dataSize / (1024 * 1024)} MB");
			else
				MeshEditorPageFactory.AddInfoRow(infoPanel, "Data Size", scope $"{dataSize / 1024} KB");
		}
		else
		{
			let errLabel = new Label();
			errLabel.SetText("Failed to load image");
			errLabel.TextColor.Value = .(220, 100, 100, 255);
			infoPanel.AddView(errLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		root.SetPanes(previewPanel, infoPanel);
		root.SplitRatio = 0.7f;

		return root;
	}
}
