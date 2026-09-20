using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// The skeleton page: the bone tree on the left, the bind pose as a wireframe in the
/// preview, a read-only pane for the selected bone on the right. Read only: a skeleton is
/// edited by re-importing its source.
class SkeletonEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;

	/// The cooked product, retained.
	private Proxy<Skeleton> mSkeleton = default;
	/// Watchdog on product identity.
	private Skeleton mLastSkeleton = null;

	private PreviewViewport mPreview = null;

	/// Borrowed: the content owns them.
	private DraggableTreeView mTree = null;
	private PropertyGrid mGrid = null;
	private Label mStatsLabel = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };

	private SkeletonTreeSnapshot mSnapshot = new .() ~ delete _;
	private SkeletonTreeAdapter mAdapter = null ~ delete _;
	private int32 mSelectedBone = -1;
	private List<BoneTransform> mPoseScratch = new .() ~ delete _;
	private List<Float4x4> mWorldScratch = new .() ~ delete _;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);

		mPreview = new PreviewViewport(host, uiHost, "skeleton.preview");
		mPreview.SetClearColor(.(0.05f, 0.05f, 0.07f, 1.0f));
		mPreview.Camera.Position = .(0.0f, 1.4f, 3.2f);
		mPreview.Camera.LookAt(.(0.0f, 0.9f, 0.0f));

		InstanceId = instance.Id;
		if (mContext.Resources != null)
		{
			mSkeleton = mContext.Resources.Bind<Skeleton>(InstanceId);
			mSkeleton.Retain();
		}

		mAdapter = new SkeletonTreeAdapter(mSnapshot);
		mTree = new DraggableTreeView();
		mTree.ItemHeight = 22.0f;
		mTree.DragEnabled = false;
		mAdapter.SetTree(mTree.InternalTreeView);
		mTree.SetAdapter(mAdapter);
		mTree.InternalTreeView.OnItemClick.Add(new [=this](info) =>
			{
				if (!mSnapshot.InRange(info.NodeId))
					return;
				mSelectedBone = mSnapshot.Nodes[info.NodeId].BoneIndex;
				if (let ctx = Ctx)
					ctx.MutationQueue.QueueAction(new () => { RebuildInfoPane(); });
				else
					RebuildInfoPane();
			});

		mStatsLabel = new Label();
		mStatsLabel.FontSize.Value = 12.0f;
		let leftColumn = new FlexLayout();
		leftColumn.Direction = .Vertical;
		leftColumn.Spacing = 4.0f;
		leftColumn.Padding = .(6, 4);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		leftColumn.AddView(mStatsLabel, match);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Width = SizeSpec.Match();
		leftColumn.AddView(mTree, grow);

		mGrid = new PropertyGrid();

		let centerSplit = new SplitView();
		centerSplit.SplitRatio = 0.26f;
		centerSplit.SetPanes(leftColumn, mPreview.View);
		let outerSplit = new SplitView();
		outerSplit.AddRef();
		outerSplit.SplitRatio = 0.78f;
		outerSplit.SetPanes(centerSplit, mGrid);
		mContent = outerSplit;

		RebuildTree();
		RebuildInfoPane();
	}

	public ~this()
	{
		if (mTree != null)
			mTree.SetAdapter(null);
		mSkeleton.Forget();
		delete mPreview;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public override Result<void, ErrorCode> Save() => .Ok;
	public PreviewViewport Preview => mPreview;
	public SkeletonTreeSnapshot Tree => mSnapshot;
	public int32 SelectedBone => mSelectedBone;

	private UIContext Ctx => ((mTree != null) && (mTree.InternalTreeView != null)) ? mTree.InternalTreeView.Context : null;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mSkeleton.Get !== mLastSkeleton)
		{
			mLastSkeleton = mSkeleton.Get;
			mSelectedBone = -1;
			RebuildTree();
			RebuildInfoPane();
		}
		UpdatePreview();
		if (mPreview != null)
			mPreview.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPreview != null)
			mPreview.RenderFrame(ref frame);
	}

	public override void OnClose()
	{
		if (mTree != null)
			mTree.SetAdapter(null);
		if (mPreview != null)
			mPreview.Shutdown();
	}

	/// The node table from the cooked skeleton's hierarchy, every node expanded.
	private void RebuildTree()
	{
		let skeleton = mSkeleton.Get;
		mSnapshot.Rebuild(skeleton);
		mAdapter.SetSkeleton(skeleton);
		if (skeleton != null)
		{
			let stats = scope List<String>();
			defer { ClearAndDeleteItems!(stats); }
			SkeletonStats.Lines(skeleton, stats);
			let text = scope String();
			for (int i < stats.Count)
			{
				if (i > 0)
					text.Append("  |  ");
				text.Append(stats[i]);
			}
			mStatsLabel.SetText(text);
		}
		else
			mStatsLabel.SetText("(skeleton not cooked yet)");
		mTree.SetAdapter(mAdapter);
		if (let flat = mTree.InternalTreeView.FlatAdapter)
		{
			for (int32 i < (int32)mSnapshot.Nodes.Count)
			{
				if (!mSnapshot.Nodes[i].Children.IsEmpty)
					flat.Expand(i);
			}
		}
		mTree.InternalTreeView.InternalListView.NotifyDataChanged();
	}

	/// Read-only rows for the selected bone.
	private void RebuildInfoPane()
	{
		mGrid.Clear();
		let skeleton = mSkeleton.Get;
		let bone = (skeleton != null) ? skeleton.GetBone(mSelectedBone) : null;
		if (bone == null)
			return;
		Stat("Name", bone.Name);
		Stat("Index", scope $"{bone.Index}");
		let parent = (bone.ParentIndex >= 0) ? skeleton.GetBone(bone.ParentIndex) : null;
		Stat("Parent", (parent != null) ? parent.Name : "(root)");
		Stat("Children", scope $"{bone.Children.Count}");
		let bind = bone.LocalBindPose;
		Stat("Bind Position", scope $"{bind.Position.X}, {bind.Position.Y}, {bind.Position.Z}");
		Stat("Bind Rotation", scope $"{bind.Rotation.X}, {bind.Rotation.Y}, {bind.Rotation.Z}, {bind.Rotation.W}");
		Stat("Bind Scale", scope $"{bind.Scale.X}, {bind.Scale.Y}, {bind.Scale.Z}");
	}

	private void Stat(StringView name, StringView value) => mGrid.AddProperty(new StringEditor(name, value, null, "Bone"));

	/// The bind pose wireframe plus the selected bone's emphasis.
	private void UpdatePreview()
	{
		let skeleton = mSkeleton.Get;
		if ((skeleton == null) || (skeleton.BoneCount <= 0) || (mPreview == null) || !mPreview.IsValid)
			return;
		let boneCount = skeleton.BoneCount;
		mPoseScratch.Count = boneCount;
		for (int32 b < boneCount)
		{
			let bone = skeleton.GetBone(b);
			mPoseScratch[b] = (bone != null) ? bone.LocalBindPose : BoneTransform();
		}
		let draw = mPreview.SceneDebugDraw;
		draw.DrawGrid(.(0.0f, 0.0f, 0.0f), 4.0f, 8, .(0.25f, 0.25f, 0.28f, 1.0f));
		SkeletonWireframe.Draw(draw, skeleton, mPoseScratch, mWorldScratch);

		if ((mSelectedBone >= 0) && (mSelectedBone < mWorldScratch.Count))
		{
			let pos = SkeletonWireframe.JointPosition(mWorldScratch[mSelectedBone]);
			draw.DrawCross(pos, 0.06f, .(1.0f, 0.65f, 0.2f, 1.0f));
			draw.DrawWireSphere(pos, 0.03f, .(1.0f, 0.65f, 0.2f, 1.0f), 12);
		}
	}
}
