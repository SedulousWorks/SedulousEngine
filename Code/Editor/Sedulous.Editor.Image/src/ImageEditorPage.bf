using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Image.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Image;

/// The image page: the decoded source shown fit to the pane over an info line, beside a
/// grid with the one authored setting, the colour space, and the source's read-only stats.
/// The colour space edit is a whole asset snapshot command.
class ImageEditorPage : UIEditorPage
{
	private static readonly StringView[2] cColorSpaceItems = .("sRGB", "Linear");

	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private ImageAsset mAsset = null ~ delete _;
	/// Owned: the ImageView borrows it.
	private OwnedImageData mPreview = null ~ delete _;
	private PixelFormat mSourceFormat = .RGBA8;
	private int mSourceBytes = 0;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private ImageView mImage = null;
	private Label mInfo = null;
	private PropertyGrid mGrid = null;
	private EnumEditor mColorSpaceRow = null;
	private List<uint8> mUndoBaseline = new .() ~ delete _;

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as ImageAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: image '{}' failed to read, page opens empty", mTitle);
		else
			LoadPreview();
		Snapshot(mUndoBaseline);

		mImage = new ImageView();
		mImage.ScaleType.Value = .FitCenter;
		mImage.SetImage(mPreview);
		mInfo = new Label("");
		mInfo.FontSize.Value = 12.0f;

		let previewColumn = new FlexLayout();
		previewColumn.Direction = .Vertical;
		previewColumn.Spacing = 6.0f;
		previewColumn.Padding = .(8, 6);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		previewColumn.AddView(mInfo, match);
		var growMatch = LayoutStyle();
		growMatch.Width = SizeSpec.Match();
		growMatch.FlexGrow = 1.0f;
		previewColumn.AddView(mImage, growMatch);

		mGrid = new PropertyGrid();
		BuildGrid();
		let gridColumn = new FlexLayout();
		gridColumn.Direction = .Vertical;
		gridColumn.Padding = .(8, 6);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		gridColumn.AddView(mGrid, grow);

		let split = new SplitView();
		split.SplitRatio = 0.6f;
		split.SetPanes(previewColumn, gridColumn);

		mToolbar = new PageToolbar(this);
		let pageColumn = new FlexLayout();
		pageColumn.Direction = .Vertical;
		pageColumn.AddView(mToolbar, match);
		pageColumn.AddView(split, growMatch);
		pageColumn.AddRef();
		mContent = pageColumn;
		RefreshInfo();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public ImageAsset Asset => mAsset;
	public bool HasPreview => mPreview != null;

	/// Keeps Save, Discard, Undo and Redo enabled to match the page.
	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mAsset == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved image '{}'", mTitle);
		}
		return saved;
	}

	/// Decodes the source file into an RGBA8 copy for display; nothing without a project or
	/// a readable file, and the info line says so.
	private void LoadPreview()
	{
		if ((mAsset == null) || mAsset.FileName.IsEmpty || (mContext.Project == null))
			return;
		let path = PathJoin(mContext.Project.SourcesRoot(.. scope .()), mAsset.FileName.Value, .. scope .());
		let source = scope Sedulous.Image.Image();
		if (!(ImageIO.LoadImage(path, source) case .Ok))
		{
			GlobalLog(.Warning, "Editor: image source missing or undecodable: {}", path);
			return;
		}
		mSourceFormat = source.Format;
		mSourceBytes = source.PixelData.Length;
		var display = source;
		Sedulous.Image.Image converted = null;
		if (source.Format != .RGBA8)
		{
			converted = source.ConvertFormat(.RGBA8);
			display = converted;
		}
		defer delete converted;
		if ((display.Width == 0) || (display.Height == 0))
			return;
		mPreview = new OwnedImageData(display.Width, display.Height, .RGBA8, display.PixelData, mAsset.ColorSpace);
	}

	private void RefreshInfo()
	{
		if (mAsset == null)
		{
			mInfo.SetText("Image failed to load.");
			return;
		}
		if (mPreview == null)
		{
			mInfo.SetText("No preview (source file missing or undecodable).");
			return;
		}
		mInfo.SetText(scope $"{mAsset.FileName.Value}  |  {mPreview.Width} x {mPreview.Height}  |  {ImageAssetEdit.PixelFormatLabel(mSourceFormat)}  |  {mSourceBytes / 1024} KiB");
	}

	private void BuildGrid()
	{
		mGrid.Clear();
		mColorSpaceRow = null;
		if (mAsset == null)
			return;
		mColorSpaceRow = new EnumEditor("Color Space", (int32)mAsset.ColorSpace, cColorSpaceItems, new [=this](v) =>
			{
				mAsset.ColorSpace = (ImageColorSpace)v;
				CommitEdit("color-space");
			}, "Import");
		mGrid.AddProperty(mColorSpaceRow);

		Stat("File", mAsset.FileName.Value);
		if (mPreview != null)
		{
			Stat("Dimensions", scope $"{mPreview.Width} x {mPreview.Height}");
			Stat("Pixel Format", ImageAssetEdit.PixelFormatLabel(mSourceFormat));
			Stat("Data Size", scope $"{mSourceBytes / 1024} KiB");
		}
	}

	private void Stat(StringView name, StringView value) => mGrid.AddProperty(new StringEditor(name, value, null, "Source"));

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			ImageAssetEdit.Snapshot(mAsset, outBlob);
	}

	/// Records the asset's current state against the undo baseline as one merged-per-key
	/// command.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditImageCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
	}

	/// Restores a snapshot, the undo and redo path; the colour space row follows.
	public void ApplyBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !ImageAssetEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		if (mColorSpaceRow != null)
			mColorSpaceRow.SetValue((int32)mAsset.ColorSpace);
		MarkDirty();
	}
}
