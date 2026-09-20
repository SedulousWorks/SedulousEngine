using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.Pipeline;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Fonts;

/// The font page: the atlas the settings would bake, rebaked on a light job after every
/// edit (latest wins while one is in flight), beside a grid of the bake settings, each a
/// whole asset snapshot command. A mode change rebuilds the grid, since the ramp and the
/// distance field show different rows.
class FontEditorPage : UIEditorPage
{
	private static readonly StringView[2] cModeItems = .("Raster Ramp", "Distance Field (MSDF)");

	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private FontAsset mAsset = null ~ delete _;
	/// Owned: the ImageView borrows it.
	private OwnedImageData mPreview = null ~ delete _;
	private int mPreviewGlyphs = 0;
	private float mPreviewSize = 0.0f;
	private bool mBakeBusy = false;
	private uint64 mBakeGeneration = 0;
	/// The newest request stashed while a bake is in flight.
	private FontBakeRequest mPendingRequest = null ~ delete _;
	/// The in flight slot, borrowed: the completion closure owns and deletes it.
	private FontBakeSlot mActiveSlot = null;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private ImageView mImage = null;
	private Label mInfo = null;
	private PropertyGrid mGrid = null;
	private StringEditor mFamilyRow = null;
	private EnumEditor mModeRow = null;
	private StringEditor mSizesRow = null;
	private FloatEditor mDistanceFieldSizeRow = null;
	private IntEditor mFirstRow = null;
	private IntEditor mLastRow = null;
	private IntEditor mAtlasWidthRow = null;
	private IntEditor mAtlasHeightRow = null;
	private StringEditor mFileRow = null;
	/// The mode the grid was built for.
	private FontBakeMode mGridMode = .RasterRamp;
	private List<uint8> mUndoBaseline = new .() ~ delete _;

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as FontAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: font '{}' failed to read, page opens empty", mTitle);
		Snapshot(mUndoBaseline);

		mImage = new ImageView();
		mImage.ScaleType.Value = .FitCenter;
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
		RebakePreview();
	}

	public ~this()
	{
		if (mActiveSlot != null)
		{
			mActiveSlot.PageAlive = false; // the completion closure still owns and deletes it
			mActiveSlot = null;
		}
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public FontAsset Asset => mAsset;
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
			GlobalLog(.Information, "Editor: saved font '{}'", mTitle);
		}
		return saved;
	}

	/// The bake parameters from the asset, on the UI thread; the largest ramp size stands
	/// in for the ramp. The caller owns the request.
	private FontBakeRequest CaptureBakeRequest()
	{
		let request = new FontBakeRequest();
		if ((mAsset == null) || mAsset.FileName.IsEmpty || (mContext.Project == null))
			return request;
		request.Valid = true;
		PathJoin(mContext.Project.SourcesRoot(.. scope .()), mAsset.FileName.Value, request.Path);
		request.DistanceField = mAsset.Mode == .DistanceField;
		request.Size = mAsset.DistanceFieldSize;
		if (!request.DistanceField)
		{
			request.Size = 14.0f;
			for (let s in mAsset.Sizes)
				request.Size = Math.Max(request.Size, s);
		}
		request.FirstCodepoint = mAsset.FirstCodepoint;
		request.LastCodepoint = mAsset.LastCodepoint;
		request.AtlasWidth = mAsset.AtlasWidth;
		request.AtlasHeight = mAsset.AtlasHeight;
		if (request.DistanceField)
			DistanceFieldFonts.Initialize(); // idempotent; the registration happens on the UI thread
		return request;
	}

	/// Bakes now without a job service, else on a light job with the newest request winning.
	private void RebakePreview()
	{
		let request = CaptureBakeRequest();
		request.Generation = ++mBakeGeneration;
		let jobs = mContext.Jobs;
		if (jobs == null)
		{
			let outcome = scope FontBakeOutcome();
			FontBake.Run(request, outcome);
			delete request;
			ApplyBakeOutcome(outcome);
			return;
		}
		if (mBakeBusy)
		{
			delete mPendingRequest;
			mPendingRequest = request; // latest wins; submitted when the flight lands
			return;
		}
		StartBake(request);
	}

	/// `request` is consumed.
	private void StartBake(FontBakeRequest request)
	{
		let jobs = mContext.Jobs;
		let slot = new FontBakeSlot();
		delete slot.Request;
		slot.Request = request;
		mActiveSlot = slot;
		mBakeBusy = true;
		if (mInfo != null)
			mInfo.SetText("Baking preview...");
		jobs.SubmitLight(new [=slot]() => { FontBake.Run(slot.Request, slot.Outcome); },
			new [=this, =slot]() =>
			{
				if (slot.PageAlive)
				{
					mActiveSlot = null;
					mBakeBusy = false;
					ApplyBakeOutcome(slot.Outcome);
					if (mPendingRequest != null)
					{
						let next = mPendingRequest;
						mPendingRequest = null;
						StartBake(next);
					}
				}
				delete slot;
			});
	}

	/// Installs a bake's atlas as the preview, unless a newer request has since been made.
	private void ApplyBakeOutcome(FontBakeOutcome outcome)
	{
		if (outcome.Generation != mBakeGeneration)
			return;
		delete mPreview;
		mPreview = outcome.TakeImage();
		mPreviewGlyphs = outcome.Glyphs;
		mPreviewSize = outcome.Size;
		mImage.SetImage(mPreview);
		if (mAsset == null)
			mInfo.SetText("Font failed to load.");
		else if (mPreview == null)
			mInfo.SetText("No preview (source file missing, unparseable, or the atlas is too small for the range).");
		else
			mInfo.SetText(scope $"{mAsset.FileName.Value}  |  {mPreviewGlyphs} glyphs @ {(int32)mPreviewSize}px  |  atlas {mPreview.Width} x {mPreview.Height}");
	}

	/// Records the asset's current state against the undo baseline as one merged-per-key
	/// command, rebakes, and rebuilds the grid when the mode changed.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditFontCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
		RebakePreview();
		if (mAsset.Mode != mGridMode)
			QueueGridRebuild();
	}

	private void QueueGridRebuild()
	{
		let ctx = (mGrid != null) ? mGrid.Context : null;
		if (ctx != null)
			ctx.MutationQueue.QueueAction(new [=this]() => { BuildGrid(); });
		else
			BuildGrid();
	}

	private void BuildGrid()
	{
		mGrid.Clear();
		mFamilyRow = null;
		mModeRow = null;
		mSizesRow = null;
		mDistanceFieldSizeRow = null;
		mFirstRow = null;
		mLastRow = null;
		mAtlasWidthRow = null;
		mAtlasHeightRow = null;
		mFileRow = null;
		if (mAsset == null)
			return;
		mGridMode = mAsset.Mode;

		mFamilyRow = new StringEditor("Family", mAsset.Family, new [=this](v) =>
			{
				mAsset.Family.Set(v);
				CommitEdit("family");
			}, "Font");
		mGrid.AddProperty(mFamilyRow);
		mModeRow = new EnumEditor("Bake Mode", (int32)mAsset.Mode, cModeItems, new [=this](v) =>
			{
				mAsset.Mode = (FontBakeMode)v;
				CommitEdit("mode");
			}, "Font");
		mGrid.AddProperty(mModeRow);
		if (mAsset.Mode == .RasterRamp)
		{
			mSizesRow = new StringEditor("Sizes (px)", FontSizes.Format(mAsset.Sizes, .. scope .()), new [=this](v) =>
				{
					let parsed = scope List<float>();
					if (!FontSizes.Parse(v, parsed))
					{
						RefreshRows(); // the old list comes back
						return;
					}
					mAsset.Sizes.Clear();
					mAsset.Sizes.AddRange(parsed);
					CommitEdit("sizes");
				}, "Raster Ramp");
			mGrid.AddProperty(mSizesRow);
		}
		if (mAsset.Mode == .DistanceField)
		{
			mDistanceFieldSizeRow = new FloatEditor("MSDF Size (px)", mAsset.DistanceFieldSize, 8.0, 128.0, 1.0, 0, new [=this](v) =>
				{
					mAsset.DistanceFieldSize = (float)v;
					CommitEdit("df-size");
				}, "Distance Field");
			mGrid.AddProperty(mDistanceFieldSizeRow);
		}
		mFirstRow = new IntEditor("First Codepoint", mAsset.FirstCodepoint, 0, 0x10FFFF, new [=this](v) =>
			{
				mAsset.FirstCodepoint = (int32)v;
				CommitEdit("first-cp");
			}, "Glyph Range");
		mGrid.AddProperty(mFirstRow);
		mLastRow = new IntEditor("Last Codepoint", mAsset.LastCodepoint, 0, 0x10FFFF, new [=this](v) =>
			{
				mAsset.LastCodepoint = (int32)v;
				CommitEdit("last-cp");
			}, "Glyph Range");
		mGrid.AddProperty(mLastRow);
		mAtlasWidthRow = new IntEditor("Atlas Width", mAsset.AtlasWidth, 64, 8192, new [=this](v) =>
			{
				mAsset.AtlasWidth = (uint32)v;
				CommitEdit("atlas-w");
			}, "Atlas");
		mGrid.AddProperty(mAtlasWidthRow);
		mAtlasHeightRow = new IntEditor("Atlas Height", mAsset.AtlasHeight, 64, 8192, new [=this](v) =>
			{
				mAsset.AtlasHeight = (uint32)v;
				CommitEdit("atlas-h");
			}, "Atlas");
		mGrid.AddProperty(mAtlasHeightRow);
		mFileRow = new StringEditor("File", mAsset.FileName.Value, null, "Source");
		mGrid.AddProperty(mFileRow);
		mGrid.AddProperty(new ButtonEditor("Browse...", new [=this]() =>
			{
				let ctx = (mGrid != null) ? mGrid.Context : null;
				if ((ctx == null) || (mContext.Project == null))
					return;
				let dialog = new PathPickerDialog("Select font file", mContext.Project.SourcesRoot(.. scope .()), scope StringView[](".ttf", ".otf", ".ttc"));
				dialog.OnPicked = new [=this](picked) =>
					{
						mAsset.FileName.Set(picked);
						CommitEdit("file");
						RefreshRows();
					};
				dialog.Show(ctx);
			}, "Source"));
	}

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			FontAssetEdit.Snapshot(mAsset, outBlob);
	}

	/// Restores a snapshot, the undo and redo path: the rows re-pull, the preview rebakes,
	/// and the grid rebuilds when the mode changed.
	public void ApplyBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !FontAssetEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		RefreshRows();
		MarkDirty();
		RebakePreview();
		if (mAsset.Mode != mGridMode)
			QueueGridRebuild();
	}

	/// Re-pulls every row from the asset; never rebuilds the grid.
	private void RefreshRows()
	{
		if (mAsset == null)
			return;
		if (mFamilyRow != null)
			mFamilyRow.SetValue(mAsset.Family);
		if (mModeRow != null)
			mModeRow.SetValue((int32)mAsset.Mode);
		if (mSizesRow != null)
			mSizesRow.SetValue(FontSizes.Format(mAsset.Sizes, .. scope .()));
		if (mDistanceFieldSizeRow != null)
			mDistanceFieldSizeRow.SetValue(mAsset.DistanceFieldSize);
		if (mFirstRow != null)
			mFirstRow.SetValue(mAsset.FirstCodepoint);
		if (mLastRow != null)
			mLastRow.SetValue(mAsset.LastCodepoint);
		if (mAtlasWidthRow != null)
			mAtlasWidthRow.SetValue(mAsset.AtlasWidth);
		if (mAtlasHeightRow != null)
			mAtlasHeightRow.SetValue(mAsset.AtlasHeight);
		if (mFileRow != null)
			mFileRow.SetValue(mAsset.FileName.Value);
	}
}
