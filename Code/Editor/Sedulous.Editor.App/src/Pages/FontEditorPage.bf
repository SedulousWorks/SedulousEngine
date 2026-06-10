namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Fonts;
using Sedulous.Fonts.Resources;
using Sedulous.Images;
using Sedulous.Editor.Core;

/// Editor page for inspecting a font resource. Read-only. Holds the
/// FontResource alive via ref counting and renders a preview of the font's
/// rasterized atlas alongside metadata (family name, glyph count, metrics).
/// The atlas is single-channel alpha so we expand to RGBA8 white-on-
/// transparent once at construction time and wrap with an ImageDrawable.
class FontEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private FontResource mFontResource;

	/// Owns the RGBA8 expansion of the atlas; freed with the page.
	private OwnedImageData mAtlasImage ~ if (_ != null) delete _;
	/// Drawable wrapping mAtlasImage. The page owns it (DrawableView /
	/// custom view consumers take a non-owning reference). Destructed
	/// before mAtlasImage, but ImageDrawable doesn't touch its IImageData
	/// at destruction so the order is incidental.
	private ImageDrawable mAtlasDrawable ~ if (_ != null) _.ReleaseRef();

	public this(StringView filePath, FontResource fontResource)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mFontResource = fontResource;
		UpdateTitle();
	}

	public ~this()
	{
		if (mFontResource != null)
			mFontResource.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public FontResource FontResource => mFontResource;
	public OwnedImageData AtlasImage => mAtlasImage;
	public ImageDrawable AtlasDrawable => mAtlasDrawable;

	public void SetContentView(View view) { mContentView = view; }

	/// Builds the RGBA8 atlas image (white-on-transparent) and an
	/// ImageDrawable around it. Called once by the factory after page
	/// construction, before the content view is built.
	public void PrepareAtlasDrawable()
	{
		if (mFontResource == null || mFontResource.Atlas == null) return;

		let atlas = mFontResource.Atlas;
		let w = (int32)atlas.Width;
		let h = (int32)atlas.Height;
		if (w <= 0 || h <= 0) return;

		let pixels = atlas.PixelData;
		if (pixels.Length < (int)w * (int)h) return;

		// Expand single-channel alpha -> RGBA8 (white pixels with the alpha
		// channel carrying the glyph coverage). This is what we'd render at
		// runtime if we composed text from the atlas, so the preview matches
		// the actual look.
		let rgba = new uint8[w * h * 4];
		for (int i = 0; i < (int)w * (int)h; i++)
		{
			let a = pixels[i];
			let di = i * 4;
			rgba[di + 0] = 255;
			rgba[di + 1] = 255;
			rgba[di + 2] = 255;
			rgba[di + 3] = a;
		}

		mAtlasImage = new OwnedImageData((uint32)w, (uint32)h, .RGBA8, rgba);
		mAtlasDrawable = new ImageDrawable(mAtlasImage);
	}

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
		// mAtlasDrawable belonged to the view tree if the factory wired it
		// in; either way the destructor frees mAtlasImage.
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}
}
