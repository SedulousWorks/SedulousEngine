using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Fonts;
using Sedulous.Fonts.Resources;
namespace Sedulous.Editor.App.Pages;

/// View that draws a Drawable letterboxed to preserve aspect ratio.
/// Used by FontEditorPage's atlas preview so a 512x512 atlas inside a
/// wide content area doesn't get stretched to fill the entire rect.
/// Non-owning - the page owns the drawable.
class AtlasPreviewView : View
{
	public Drawable Drawable;
	public uint32 ContentWidth;
	public uint32 ContentHeight;

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Drawable == null || ContentWidth == 0 || ContentHeight == 0) return;

		let aspect = (float)ContentWidth / (float)ContentHeight;
		var w = Width;
		var h = w / aspect;
		if (h > Height)
		{
			h = Height;
			w = h * aspect;
		}
		let x = (Width - w) * 0.5f;
		let y = (Height - h) * 0.5f;
		Drawable.Draw(ctx, RectangleF(x, y, w, h));
	}
}

/// Creates editor pages for `.font` files: read-only metadata panel +
/// rasterized atlas preview. The atlas image is materialized once on page
/// creation and lives until the page is disposed.
class FontEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".font"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".font", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Font", "Path is not inside any mounted scheme.", context);

		FontResource fontRes = null;
		if (context.ResourceSystem.LoadResource<FontResource>(uri) case .Ok(let handle))
			fontRes = handle.Resource;
		if (fontRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Font", "Failed to load font resource.", context);

		let page = new FontEditorPage(path, fontRes);
		page.PrepareAtlasDrawable();
		page.SetContentView(BuildFontView(fontRes, page));
		return page;
	}

	private static View BuildFontView(FontResource fontRes, FontEditorPage page)
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;
		root.Padding = .(16);
		root.Spacing = 12;

		// Title
		let displayName = scope String();
		System.IO.Path.GetFileNameWithoutExtension(page.FilePath, displayName);
		let titleLabel = new Label();
		titleLabel.SetText(scope $"Font: {displayName}");
		titleLabel.FontSize.Value = 16;
		titleLabel.TextColor.Value = .(220, 225, 235, 255);
		root.AddView(titleLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });

		AddSeparator(root);

		// Metadata
		let font = fontRes.Font;
		let atlas = fontRes.Atlas;
		let opts = fontRes.Options;

		AddInfoRow(root, "Family", (font?.FamilyName != null && !font.FamilyName.IsEmpty) ? StringView(font.FamilyName) : "unnamed");
		AddInfoRow(root, "Pixel Height", scope $"{opts.PixelHeight}");
		AddInfoRow(root, "Codepoint Range", scope $"U+{opts.FirstCodepoint:X4} - U+{opts.LastCodepoint:X4} ({opts.CharacterCount} glyphs)");
		if (atlas != null)
			AddInfoRow(root, "Atlas", scope $"{atlas.Width} x {atlas.Height}");

		AddSeparator(root);

		// Atlas preview - the rasterized glyph atlas, expanded to RGBA8
		// white-on-transparent. Sits inside a dark Panel so the white-on-
		// transparent glyphs are visible. Uses an aspect-fit wrapper so
		// the atlas (usually square) doesn't get stretched to fill the
		// available rectangle.
		if (page.AtlasDrawable != null && page.AtlasImage != null)
		{
			let preview = new Panel();
			preview.SetStyle(.Background, new ColorDrawable(.(30, 32, 38, 255)));

			let atlasView = new AtlasPreviewView();
			atlasView.Drawable = page.AtlasDrawable;
			atlasView.ContentWidth = page.AtlasImage.Width;
			atlasView.ContentHeight = page.AtlasImage.Height;
			preview.AddView(atlasView);

			root.AddView(preview, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });
		}
		else
		{
			let errorLabel = new Label();
			errorLabel.SetText("Atlas not available");
			errorLabel.TextColor.Value = .(220, 100, 100, 255);
			root.AddView(errorLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		return root;
	}

	private static void AddSeparator(FlexLayout container)
	{
		let sep = new Panel();
		sep.SetStyle(.Background, new ColorDrawable(.(60, 65, 80, 255)));
		container.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });
	}

	private static void AddInfoRow(FlexLayout container, StringView name, StringView value)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;

		let nameLabel = new Label();
		nameLabel.SetText(scope $"{name}:");
		nameLabel.TextColor.Value = .(140, 145, 165, 255);
		row.AddView(nameLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(140)), Height = .Match });

		let valueLabel = new Label();
		valueLabel.SetText(value);
		valueLabel.TextColor.Value = .(220, 220, 230, 255);
		row.AddView(valueLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		container.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
	}
}
