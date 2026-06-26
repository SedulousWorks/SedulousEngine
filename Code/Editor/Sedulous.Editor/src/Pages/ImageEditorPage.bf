namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.Images;
using Sedulous.Images.Resources;
using Sedulous.Editor.Core;

/// Editor page for viewing image resources. Holds the `ImageResource`
/// alive via ref counting and renders its `Image` directly through
/// `ImageView` (now that `Image` implements `IImageData`).
class ImageEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	// Resource (ref-counted, kept alive while page is open).
	private ImageResource mImage;

	public this(StringView filePath, ImageResource image)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mImage = image;
		UpdateTitle();
	}

	public ~this()
	{
		if (mImage != null)
			mImage.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public ImageResource ImageResource => mImage;

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
