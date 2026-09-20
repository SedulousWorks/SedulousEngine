using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Heightfield.Pipeline;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Heightfield;

/// The heightfield page: the 16 bit source as a grey preview over an info line with the
/// sampled height range, beside a grid of the grid size, world extent and height range,
/// each edit a whole asset snapshot command. A blank heightfield, one with no source
/// image, previews nothing and says so.
class HeightfieldEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private HeightfieldAsset mAsset = null ~ delete _;
	/// Owned: the ImageView borrows it.
	private OwnedImageData mPreview = null ~ delete _;
	private uint32 mSourceWidth = 0;
	private uint32 mSourceHeight = 0;
	private uint16 mMinSample = 0;
	private uint16 mMaxSample = 0;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private ImageView mImage = null;
	private Label mInfo = null;
	private PropertyGrid mGrid = null;
	private List<uint8> mUndoBaseline = new .() ~ delete _;

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as HeightfieldAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: heightfield '{}' failed to read, page opens empty", mTitle);
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
		split.AddRef();
		split.SplitRatio = 0.6f;
		split.SetPanes(previewColumn, gridColumn);
		mContent = split;
		RefreshInfo();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public HeightfieldAsset Asset => mAsset;
	public bool HasPreview => mPreview != null;

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
			GlobalLog(.Information, "Editor: saved heightfield '{}'", mTitle);
		}
		return saved;
	}

	/// Decodes the 16 bit source into an 8 bit grey preview, noting the sample range.
	private void LoadPreview()
	{
		DeleteAndNullify!(mPreview);
		mSourceWidth = 0;
		mSourceHeight = 0;
		mMinSample = 0;
		mMaxSample = 0;
		if ((mAsset == null) || mAsset.FileName.IsEmpty || (mContext.Project == null))
			return; // a blank heightfield: no source image to preview
		let path = PathJoin(mContext.Project.SourcesRoot(.. scope .()), mAsset.FileName.Value, .. scope .());
		let source = scope Sedulous.Image.Image();
		if (!(ImageIO.LoadImage16(path, source) case .Ok) || (source.Width == 0) || (source.Height == 0))
		{
			GlobalLog(.Warning, "Editor: heightfield source missing or undecodable: {}", path);
			return;
		}
		mSourceWidth = source.Width;
		mSourceHeight = source.Height;
		let count = (int)mSourceWidth * (int)mSourceHeight;
		let samples = (uint16*)source.PixelData.Ptr;
		mMinSample = 65535;
		mMaxSample = 0;
		let rgba = new List<uint8>(); // handed to the image
		rgba.Resize(count * 4);
		for (int i < count)
		{
			let s = samples[i];
			mMinSample = Math.Min(s, mMinSample);
			mMaxSample = Math.Max(s, mMaxSample);
			let g = (uint8)(s >> 8); // 16 bit height to 8 bit grey
			rgba[i * 4 + 0] = g;
			rgba[i * 4 + 1] = g;
			rgba[i * 4 + 2] = g;
			rgba[i * 4 + 3] = 255;
		}
		mPreview = new OwnedImageData(mSourceWidth, mSourceHeight, .RGBA8, rgba, .Linear);
	}

	private void RefreshInfo()
	{
		if (mAsset == null)
		{
			mInfo.SetText("Heightfield failed to load.");
			return;
		}
		let ws = mAsset.WorldSize;
		if (mPreview == null)
		{
			mInfo.SetText(scope $"Blank heightfield (flat)  |  {mAsset.Size} x {mAsset.Size} grid  |  extent {ws.X} x {ws.Y} m");
			return;
		}
		let range = mAsset.MaxY - mAsset.MinY;
		let loY = mAsset.MinY + range * ((float)mMinSample / 65535.0f);
		let hiY = mAsset.MinY + range * ((float)mMaxSample / 65535.0f);
		mInfo.SetText(scope $"{mAsset.FileName.Value}  |  source {mSourceWidth} x {mSourceHeight}  |  extent {ws.X} x {ws.Y} m  |  height {loY} .. {hiY} m");
	}

	private void BuildGrid()
	{
		mGrid.Clear();
		if (mAsset == null)
			return;
		let cat = "Heightfield";
		mGrid.AddProperty(new IntEditor("Grid Size (64k+1)", mAsset.Size, 65, 100000, new [=this](v) =>
			{
				mAsset.Size = (int32)v;
				CommitEdit("size");
			}, cat));
		mGrid.AddProperty(new Float2Editor("World Size (XZ)", mAsset.WorldSize, 1.0f, 100000.0f, 1.0f, new [=this](v) =>
			{
				mAsset.WorldSize = v;
				CommitEdit("worldSize");
			}, cat));
		mGrid.AddProperty(new FloatEditor("Min Height", mAsset.MinY, -100000.0, 100000.0, 0.5, 2, new [=this](v) =>
			{
				mAsset.MinY = (float)v;
				CommitEdit("minY");
			}, cat));
		mGrid.AddProperty(new FloatEditor("Max Height", mAsset.MaxY, -100000.0, 100000.0, 0.5, 2, new [=this](v) =>
			{
				mAsset.MaxY = (float)v;
				CommitEdit("maxY");
			}, cat));

		Stat("File", mAsset.FileName.IsEmpty ? "(blank)" : mAsset.FileName.Value);
		if (mPreview != null)
			Stat("Source Size", scope $"{mSourceWidth} x {mSourceHeight}");
	}

	private void Stat(StringView name, StringView value) => mGrid.AddProperty(new StringEditor(name, value, null, "Source"));

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			HeightfieldAssetEdit.Snapshot(mAsset, outBlob);
	}

	/// Records the asset's current state against the undo baseline as one merged-per-key
	/// command; the info line follows the new range.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditHeightfieldCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		RefreshInfo();
		MarkDirty();
	}

	/// Restores a snapshot, the undo and redo path; every editable row re-pulls.
	public void ApplyBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !HeightfieldAssetEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		BuildGrid();
		RefreshInfo();
		MarkDirty();
	}
}
