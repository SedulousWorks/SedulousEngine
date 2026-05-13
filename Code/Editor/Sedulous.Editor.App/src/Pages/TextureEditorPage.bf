namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Images;
using Sedulous.Textures.Resources;
using Sedulous.Editor.Core;

/// Editor page for viewing texture resources.
/// Holds the TextureResource alive via ref counting and owns the ImageDataRef
/// used for preview display.
class TextureEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	// Resource (ref-counted, kept alive while page is open)
	private TextureResource mTexture;

	// Image data ref for the preview (owned, references mTexture.Image pixel data)
	private ImageDataRef mImageDataRef ~ delete _;

	public this(StringView filePath, TextureResource texture)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mTexture = texture;
		UpdateTitle();
	}

	public ~this()
	{
		if (mTexture != null)
			mTexture.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public TextureResource Texture => mTexture;

	/// Sets the ImageDataRef used for preview. Owned by this page.
	public void SetImageDataRef(ImageDataRef imageData) { mImageDataRef = imageData; }

	public void SetContentView(View view) { mContentView = view; }

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}
}
