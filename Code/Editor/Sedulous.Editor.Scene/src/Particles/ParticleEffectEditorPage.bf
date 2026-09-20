using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Particles.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// The particle effect page: the effect's tree on the left (systems, emitters, module
/// folders), a simulating preview with a transport in the middle, and an inspector for the
/// selected row on the right. Every edit is a whole effect snapshot command; a structural
/// one (a module added, removed or moved) re-attaches the preview and rebuilds the tree.
class ParticleEffectEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;

	/// Owned; null when the read failed and the page opened empty.
	private ParticleEffectAsset mAsset = null ~ delete _;

	private PreviewViewport mPreview = null;
	/// The preview's own resolved resource, which the component borrows.
	private ParticleEffectResource mPreviewResource = null;
	/// Cloning an effect is a serialization round trip, so the page carries the factory.
	private SerializerFactory mSerializers = (new (stream, mode) => new BinarySerializerContext(stream, mode)) ~ delete _;
	/// The emitter entity, in the preview scene.
	private EntityHandle mEmitter = .Invalid;

	/// Borrowed: the content owns them.
	private DraggableTreeView mTree = null;
	private PropertyGrid mGrid = null;
	/// The live overlay text.
	private Label mStatsLabel = null;
	/// The inspector header ("Systems: N").
	private Label mTitleLabel = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };

	private ParticleTreeSnapshot mSnapshot = new .() ~ delete _;
	private ParticleTreeAdapter mAdapter = null ~ delete _;
	/// The row being inspected.
	private ParticleNodeRef mSelected = .Root;

	private float mSimSpeed = 1.0f;
	private bool mPaused = false;
	/// The last committed effect blob, the undo anchor.
	private List<uint8> mUndoBaseline = new .() ~ delete _;
	/// What the in place rows report through; borrowed by every row.
	private InPlaceRows.Commit mCommit = new => CommitEdit ~ delete _;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);

		mPreview = new PreviewViewport(host, uiHost, "particle.preview");
		mPreview.SetClearColor(.(0.06f, 0.06f, 0.08f, 1.0f)); // a darker field shows particles
		mPreview.Camera.Position = .(0.0f, 2.0f, 6.0f);
		mPreview.Camera.LookAt(.(0.0f, 1.0f, 0.0f));

		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as ParticleEffectAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: particle effect '{}' failed to read, page opens empty", mTitle);

		BuildPreviewScene();
		SnapshotEffect(mUndoBaseline);

		let transport = BuildTransport();

		let centerColumn = new FlexLayout();
		centerColumn.Direction = .Vertical;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		centerColumn.AddView(transport, match);
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		centerColumn.AddView(mPreview.View, growMatch);

		mAdapter = new ParticleTreeAdapter(this, mSnapshot);
		mTree = new DraggableTreeView();
		mTree.ItemHeight = 22.0f;
		mAdapter.SetTree(mTree.InternalTreeView);
		mTree.SetAdapter(mAdapter);
		mTree.InternalTreeView.OnItemClick.Add(new [=this](info) =>
			{
				if (mSnapshot.InRange(info.NodeId))
					SelectNode(mSnapshot.Nodes[info.NodeId].Ref);
			});
		mTree.InternalTreeView.OnItemRightClick.Add(new [=this](nodeId, x, y) =>
			{
				let s = mTree.InternalTreeView.InternalListView.LocalToScreen(.(x, y));
				ShowNodeContextMenu(nodeId, s.X, s.Y);
			});

		mGrid = new PropertyGrid();
		mTitleLabel = new Label();
		mTitleLabel.FontSize.Value = 12.0f;
		let inspectorColumn = new FlexLayout();
		inspectorColumn.Direction = .Vertical;
		inspectorColumn.Spacing = 4.0f;
		inspectorColumn.Padding = .(6, 4);
		inspectorColumn.AddView(mTitleLabel, match);
		inspectorColumn.AddView(mGrid, growMatch);

		let leftSplit = new SplitView();
		leftSplit.SplitRatio = 0.22f;
		leftSplit.SetPanes(mTree, centerColumn);
		let rightSplit = new SplitView();
		rightSplit.AddRef();
		rightSplit.SplitRatio = 0.72f;
		rightSplit.SetPanes(leftSplit, inspectorColumn);
		mContent = rightSplit;

		RebuildTree();
		SelectNode(.Root);
	}

	public ~this()
	{
		if (mTree != null)
			mTree.SetAdapter(null);
		DetachPreview();
		delete mPreview;
		delete mPreviewResource;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public ParticleEffectAsset Asset => mAsset;
	public PreviewViewport Preview => mPreview;
	public ParticleTreeSnapshot Tree => mSnapshot;
	public ParticleNodeRef Selected => mSelected;
	public bool IsPaused => mPaused;

	/// The context every menu and dialog opens against; null until the content is attached.
	private UIContext Ctx => ((mTree != null) && (mTree.InternalTreeView != null)) ? mTree.InternalTreeView.Context : null;

	private ParticleSystem SelectedSystem => ((mAsset != null) && (mSelected.SystemIndex >= 0)) ? mAsset.Effect.GetSystem(mSelected.SystemIndex) : null;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if ((mStatsLabel != null) && (mAsset != null))
		{
			int32 total = 0;
			int32 cap = 0;
			let count = mAsset.Effect.SystemCount;
			for (int32 i < count)
			{
				let s = mAsset.Effect.GetSystem(i);
				total += s.AliveCount;
				cap += s.MaxParticles;
			}
			mStatsLabel.SetText(scope $"{count} systems | {total}/{cap} particles{mPaused ? " | PAUSED" : ""}");
		}

		DrawEmissionGizmo();

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
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved particle effect '{}'", mTitle);
		}
		return saved;
	}

	public override void OnClose()
	{
		if (mTree != null)
			mTree.SetAdapter(null);
		if (mPreview != null)
			mPreview.Shutdown();
	}

	private void SnapshotEffect(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			ParticleEffectEdit.Snapshot(mAsset.Effect, outBlob);
	}

	/// Restores a snapshot, the undo and redo path: the effect is rebuilt, so the preview
	/// re-attaches and the tree and inspector rebuild, deferred.
	public void ApplyEffectBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !ParticleEffectEdit.Apply(mAsset.Effect, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		AttachPreviewEffect();
		RebuildPreviewResources(); // undo or redo may have changed refs or the system set
		if (let ctx = Ctx)
		{
			ctx.MutationQueue.QueueAction(new [=this]() =>
				{
					RebuildTree();
					RebuildInspector();
				});
		}
		else
		{
			RebuildTree();
			RebuildInspector();
		}
		MarkDirty();
	}

	/// Records the effect's current state against the undo baseline as one merged-per-key
	/// command; the rows call it after writing the effect in place.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		SnapshotEffect(after);
		Commands.Execute(new EditParticleCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
	}

	/// A shape change: runs `mutate` off the tree's own event, re-attaches the preview since
	/// the system set may have changed, commits, then rebuilds the tree and inspector with
	/// `reselect` chosen. `mutate` is consumed.
	private void QueueStructural(StringView undoKey, delegate void() mutate, ParticleNodeRef reselect)
	{
		let key = new String(undoKey);
		delegate void() run = new [=this, =mutate, =key, =reselect]() =>
			{
				mutate();
				mSelected = reselect;
				AttachPreviewEffect();
				RebuildPreviewResources();
				CommitEdit(key);
				RebuildTree();
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

	/// The tree's rename: a system's name, committed and reflected in the row.
	public void RenameSystem(int32 systemIndex, StringView newName)
	{
		let s = (mAsset != null) ? mAsset.Effect.GetSystem(systemIndex) : null;
		if (s == null)
			return;
		s.Name.Set(newName);
		CommitEdit("rename-system");
		RebuildTree();
	}

	/// The tree's drag: a module to another slot of the same folder.
	public void MoveModule(ParticleNodeKind kind, int32 systemIndex, int32 from, int32 to)
	{
		let init = kind == .Initializer;
		QueueStructural("reorder", new [=this, =systemIndex, =from, =to, =init]() =>
			{
				if (let s = mAsset.Effect.GetSystem(systemIndex))
				{
					if (init)
						s.MoveInitializer(from, to);
					else
						s.MoveBehavior(from, to);
				}
			}, .(kind, systemIndex, to));
	}
}
