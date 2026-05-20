using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Images;
using Sedulous.Textures;
using Sedulous.Textures.Resources;
using Sedulous.Resources;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .texture files.
/// Displays image preview (FitCenter) and metadata properties.
class TextureEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".texture"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".texture", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		// LoadResource requires a scheme://locator URI; the asset browser hands
		// us an absolute filesystem path. Resolve via the editor's mount table.
		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Texture", "Path is not inside any mounted scheme.", context);

		TextureResource texRes = null;
		if (context.ResourceSystem.LoadResource<TextureResource>(uri) case .Ok(let handle))
			texRes = handle.Resource;

		let page = new TextureEditorPage(path, texRes);
		page.SetContentView(BuildTextureView(path, texRes, page));
		return page;
	}

	private static View BuildTextureView(StringView path, TextureResource texRes, TextureEditorPage page)
	{
		let root = new SplitView(.Horizontal);

		// Left: image preview with dark background
		let previewPanel = new Panel();
		previewPanel.Background = new ColorDrawable(.(30, 30, 35, 255));

		let imageView = new ImageView();
		imageView.ScaleType = .FitCenter;

		if (texRes?.Image != null)
		{
			let image = texRes.Image;
			let colorSpace = IsHdrFormat(image.Format) ? ImageColorSpace.Linear : ImageColorSpace.Srgb;
			let imageData = new ImageDataRef(image.Width, image.Height, image.Format,
				image.Data.Ptr, image.Data.Length, colorSpace);
			imageView.Image = imageData;
			page.SetImageDataRef(imageData);
		}

		previewPanel.AddView(imageView);

		// Right: metadata panel
		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Texture Properties");
		MeshEditorPageFactory.AddSeparator(infoPanel);

		if (texRes != null)
		{
			let image = texRes.Image;
			if (image != null)
			{
				MeshEditorPageFactory.AddInfoRow(infoPanel, "Dimensions", scope $"{image.Width} x {image.Height}");
				MeshEditorPageFactory.AddInfoRow(infoPanel, "Format", scope $"{image.Format}");
				let dataSize = image.DataSize;
				if (dataSize > 1024 * 1024)
					MeshEditorPageFactory.AddInfoRow(infoPanel, "Data Size", scope $"{dataSize / (1024 * 1024)} MB");
				else
					MeshEditorPageFactory.AddInfoRow(infoPanel, "Data Size", scope $"{dataSize / 1024} KB");
			}

			MeshEditorPageFactory.AddInfoRow(infoPanel, "Shape", scope $"{texRes.Shape}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Min Filter", scope $"{texRes.MinFilter}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Mag Filter", scope $"{texRes.MagFilter}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Wrap U", scope $"{texRes.WrapU}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Wrap V", scope $"{texRes.WrapV}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Mipmaps", texRes.GenerateMipmaps ? "Yes" : "No");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Anisotropy", scope $"{texRes.Anisotropy:F1}");
		}
		else
		{
			let errLabel = new Label();
			errLabel.SetText("Failed to load texture");
			errLabel.TextColor = .(220, 100, 100, 255);
			infoPanel.AddView(errLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		root.SetPanes(previewPanel, infoPanel);
		root.SplitRatio = 0.7f;

		return root;
	}

	private static bool IsHdrFormat(PixelFormat format)
	{
		switch (format)
		{
		case .R16F, .RG16F, .RGB16F, .RGBA16F,
			 .R32F, .RG32F, .RGB32F, .RGBA32F:
			return true;
		default:
			return false;
		}
	}

	/// Legacy placeholder builder used by the AnimGraph / PropAnim stub
	/// factories until those pages get real implementations.
	public static View BuildPlaceholder(StringView resourceType, StringView path)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Padding = .(16);

		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(path, name);

		let titleLabel = new Label();
		titleLabel.SetText(scope $"{resourceType}: {name}");
		titleLabel.FontSize = 16;
		titleLabel.HAlign = .Center;
		titleLabel.VAlign = .Middle;
		container.AddView(titleLabel, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		return container;
	}
}
