using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Animation;
using Sedulous.Animation.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.Engine.Render;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// The animation graph page: layers and parameters on the left, the selected layer's
/// state machine on a node canvas over a preview that plays the graph on a picked skeleton,
/// and an inspector for the selection on the right. The page edits a nested GraphDocument
/// and stores it over the flat source around every snapshot, so undo carries the wire form.
class AnimationGraphEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;

	/// Owned; null when the read failed and the page opened empty.
	private AnimationGraphAsset mAsset = null ~ delete _;
	/// The nested edit model, loaded from the asset's flat source.
	private GraphDocument mDoc = new .() ~ delete _;

	/// Borrowed: the content owns them.
	private NodeGraphCanvas mCanvas = null;
	/// The layer and parameter rows.
	private FlexLayout mLeftRows = null;
	private PropertyGrid mGrid = null;
	private Label mInspectorTitle = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };

	/// The layer shown on the canvas.
	private int32 mSelectedLayer = 0;
	private GraphSel mSelected = .None;
	private List<uint8> mUndoBaseline = new .() ~ delete _;
	/// Canvas events are ignored while the canvas is being rebuilt.
	private bool mSyncingCanvas = false;
	/// What the in place rows report through; borrowed by every row.
	private InPlaceRows.Commit mCommit = new => CommitEdit ~ delete _;

	private PreviewViewport mPreview = null;
	private Button mSkeletonButton = null;
	private Button mMeshButton = null;
	private Button mSkeletonToggle = null;
	private Button mMeshToggle = null;
	private Button mPlayButton = null;
	/// The current state and transition readout.
	private Label mPreviewStatus = null;

	private Guid mSkeletonGuid = .();
	private Proxy<Skeleton> mSkeleton = default;
	/// Owned; the player borrows it.
	private AnimationGraph mPreviewGraph = null;
	private AnimationGraphPlayer mPlayer = null;
	/// The skeleton the player was built for, so a reload rebuilds it.
	private Skeleton mPlayerSkeleton = null;
	private List<Float4x4> mWorldScratch = new .() ~ delete _;

	private Guid mPreviewMeshId = .();
	private EntityHandle mMeshEntity = .Invalid;
	private bool mShowSkeleton = true;
	private bool mShowMesh = true;
	private bool mPreviewPlaying = true;
	/// The canvas node wearing the active state ring.
	private int32 mLastHighlightedNode = -1;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);

		mPreview = new PreviewViewport(host, uiHost, "animgraph.preview");
		mPreview.SetClearColor(.(0.05f, 0.05f, 0.07f, 1.0f));
		mPreview.Camera.Position = .(0.0f, 1.4f, 3.2f);
		mPreview.Camera.LookAt(.(0.0f, 0.9f, 0.0f));
		BuildPreviewScene();

		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as AnimationGraphAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: animation graph '{}' failed to read, page opens empty", mTitle);
		else
		{
			mDoc.Load(mAsset.Source);
			AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
		}
		SnapshotAsset(mUndoBaseline);

		mCanvas = new NodeGraphCanvas();
		mCanvas.EdgeStyle = .StraightNodeToNode;
		WireCanvas();

		mLeftRows = new FlexLayout();
		mLeftRows.Direction = .Vertical;
		mLeftRows.Spacing = 2.0f;
		mLeftRows.Padding = .(6, 6);
		let leftScroll = new ScrollView();
		leftScroll.VScrollBarPolicy.Value = .Auto;
		leftScroll.HScrollBarPolicy.Value = .Never;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		leftScroll.AddView(mLeftRows, match);

		mGrid = new PropertyGrid();
		mInspectorTitle = new Label();
		mInspectorTitle.FontSize.Value = 12.0f;
		let inspectorColumn = new FlexLayout();
		inspectorColumn.Direction = .Vertical;
		inspectorColumn.Spacing = 4.0f;
		inspectorColumn.Padding = .(6, 4);
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		inspectorColumn.AddView(mInspectorTitle, match);
		inspectorColumn.AddView(mGrid, growMatch);

		let previewColumn = new FlexLayout();
		previewColumn.Direction = .Vertical;
		previewColumn.AddView(BuildTransport(), match);
		previewColumn.AddView(mPreview.View, growMatch);

		let centerSplit = new SplitView(.Vertical);
		centerSplit.SplitRatio = 0.62f;
		centerSplit.SetPanes(mCanvas, previewColumn);
		let leftSplit = new SplitView();
		leftSplit.SplitRatio = 0.18f;
		leftSplit.SetPanes(leftScroll, centerSplit);
		let rightSplit = new SplitView();
		rightSplit.SplitRatio = 0.74f;
		rightSplit.SetPanes(leftSplit, inspectorColumn);
		mContent = rightSplit;

		RebuildLeftPanel();
		RebuildCanvas();
		LoadPreviewPref(); // the skeleton and mesh come back before the player builds
		RebuildPreviewGraph();
		Select(.(.Layer, 0, 0));
	}

	public ~this()
	{
		ClearPreviewOverrides();
		DeletePlayer();
		mSkeleton.Forget();
		delete mPreview;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public AnimationGraphAsset Asset => mAsset;
	public GraphDocument Document => mDoc;
	public PreviewViewport Preview => mPreview;
	public int32 SelectedLayer => mSelectedLayer;
	public GraphSel Selected => mSelected;

	/// The context every menu and dialog opens against; null until the content is attached.
	private UIContext Ctx => (mCanvas != null) ? mCanvas.Context : null;

	private GraphLayer CurrentLayer => mDoc.Layer(mSelectedLayer);

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		UpdatePreview(dt);
		if (mPreview != null)
			mPreview.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPreview != null)
			mPreview.RenderFrame(ref frame);
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mAsset == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		mDoc.Store(mAsset.Source);
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved animation graph '{}'", mTitle);
		}
		return saved;
	}

	public override void OnClose()
	{
		ClearPreviewOverrides();
		DeletePlayer();
		if (mPreview != null)
			mPreview.Shutdown();
	}

	/// Stores the model over the source, then the whole asset as bytes.
	private void SnapshotAsset(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset == null)
			return;
		mDoc.Store(mAsset.Source);
		AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
		AnimationGraphEdit.Snapshot(mAsset, outBlob);
	}

	/// Restores a snapshot, the undo and redo path: the asset is rebuilt, the model reloaded
	/// from it, and every panel rebuilds, deferred.
	public void ApplyAssetBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !AnimationGraphEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		mDoc.Load(mAsset.Source);
		AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
		mSelectedLayer = Math.Clamp(mSelectedLayer, 0, Math.Max((int32)mDoc.Layers.Count - 1, 0));
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(new [=this]() => { RebuildAll(); });
		else
			RebuildAll();
		MarkDirty();
	}

	private void RebuildAll()
	{
		RebuildLeftPanel();
		RebuildCanvas();
		RebuildInspector();
		RebuildPreviewGraph();
	}

	/// Records the model's current state against the undo baseline as one merged-per-key
	/// command and rebuilds the preview graph; the rows call it after writing in place.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		SnapshotAsset(after);
		Commands.Execute(new EditGraphCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		RebuildPreviewGraph();
		MarkDirty();
	}

	/// A shape change: runs `mutate` off the canvas's own event, commits it, then rebuilds
	/// every panel with `reselect` chosen (GraphSel.Last resolving to the newest item).
	/// `mutate` is consumed.
	private void QueueStructural(StringView undoKey, delegate void() mutate, GraphSel reselect)
	{
		let key = new String(undoKey);
		delegate void() run = new [=this, =mutate, =key, =reselect]() =>
			{
				mutate();
				AnimationGraphEdit.SyncLayouts(mAsset, mDoc);
				mSelectedLayer = Math.Clamp(mSelectedLayer, 0, Math.Max((int32)mDoc.Layers.Count - 1, 0));
				var sel = reselect;
				if (sel.Index == GraphSel.Last)
				{
					let layer = mDoc.Layer(sel.Layer);
					if (sel.Kind == .Parameter)
						sel.Index = (int32)mDoc.Params.Count - 1;
					else if ((sel.Kind == .State) && (layer != null))
						sel.Index = (int32)layer.States.Count - 1;
					else if ((sel.Kind == .Transition) && (layer != null))
						sel.Index = (int32)layer.Transitions.Count - 1;
				}
				mSelected = sel;
				CommitEdit(key);
				RebuildLeftPanel();
				RebuildCanvas();
				RebuildInspector();
			} ~ { delete mutate; delete key; };
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(run);
		else
		{
			run();
			delete run;
		}
	}

	/// Sets the selection and rebuilds the inspector, deferred.
	private void Select(GraphSel sel)
	{
		mSelected = sel;
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(new [=this]() => { RebuildInspector(); });
		else
			RebuildInspector();
	}
}
