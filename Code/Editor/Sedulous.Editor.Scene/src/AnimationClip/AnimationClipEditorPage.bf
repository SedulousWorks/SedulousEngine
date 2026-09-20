using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Animation;
using Sedulous.Animation.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// The animation clip page: a transport (skeleton and mesh pickers, play, a scrub slider)
/// over a preview that samples the cooked clip on the chosen skeleton, drawn as a wireframe
/// and, when a skinned mesh is picked, skinned onto it; a grid with the stats, the loop
/// flag and the event table. Edits snapshot the whole asset per undo step.
class AnimationClipEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;

	/// Owned; null when the read failed and the page opened empty.
	private AnimationClipAsset mAsset = null ~ delete _;
	/// The cooked product, retained; hot swaps.
	private Proxy<AnimationClip> mClip = default;

	private PreviewViewport mPreview = null;

	/// Borrowed: the content owns them.
	private Button mSkeletonButton = null;
	private Button mMeshButton = null;
	private Button mPlayButton = null;
	/// Normalised [0..1] scrub.
	private Slider mTimeSlider = null;
	private Label mTimeLabel = null;
	private PropertyGrid mGrid = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };

	private Guid mSkeletonGuid = .();
	private Proxy<Skeleton> mSkeleton = default;
	private List<BoneTransform> mPoseScratch = new .() ~ delete _;

	private Guid mPreviewMeshId = .();
	private EntityHandle mMeshEntity = .Invalid;
	/// Owned; rebuilt when the skeleton changes.
	private AnimationPlayer mPreviewPlayer = null;
	/// The skeleton the player was built for, and the clip last handed to it.
	private Skeleton mPlayerSkeleton = null;
	private AnimationClip mPlayerClip = null;
	private List<Float4x4> mWorldScratch = new .() ~ delete _;
	private List<uint8> mUndoBaseline = new .() ~ delete _;
	/// Seconds into the clip.
	private float mTime = 0.0f;
	private bool mPlaying = true;
	/// The slider writes mTime; playback writes the slider.
	private bool mScrubbing = false;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);

		mPreview = new PreviewViewport(host, uiHost, "animclip.preview");
		mPreview.SetClearColor(.(0.05f, 0.05f, 0.07f, 1.0f));
		mPreview.Camera.Position = .(0.0f, 1.4f, 3.2f);
		mPreview.Camera.LookAt(.(0.0f, 0.9f, 0.0f));

		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as AnimationClipAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: animation clip '{}' failed to read, page opens empty", mTitle);
		SnapshotAsset(mUndoBaseline);
		if (mContext.Resources != null)
		{
			mClip = mContext.Resources.Bind<AnimationClip>(InstanceId);
			mClip.Retain();
		}

		BuildPreviewScene();

		let transport = new FlexLayout();
		transport.Direction = .Horizontal;
		transport.Spacing = 6.0f;
		transport.Padding = .(6, 4);
		mSkeletonButton = new Button("Skeleton: (none)");
		mSkeletonButton.OnClick.Add(new [=this](btn) => { PickPreviewSkeleton(); });
		transport.AddView(mSkeletonButton);
		mMeshButton = new Button("Mesh: (none)");
		mMeshButton.OnClick.Add(new [=this](btn) => { PickPreviewMesh(); });
		transport.AddView(mMeshButton);
		mPlayButton = new Button("Pause");
		mPlayButton.OnClick.Add(new [=this](btn) =>
			{
				mPlaying = !mPlaying;
				mPlayButton.SetText(mPlaying ? "Pause" : "Play");
			});
		transport.AddView(mPlayButton);

		mTimeSlider = new Slider(0.0f, 1.0f);
		mTimeSlider.OnValueChanged.Add(new [=this](slider, v) =>
			{
				if (mScrubbing)
					return; // playback echo
				let clip = mClip.Get;
				if ((clip != null) && (clip.Duration > 0.0f))
				{
					mTime = v * clip.Duration;
					mPlaying = false;
					mPlayButton.SetText("Play");
				}
			});
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		transport.AddView(mTimeSlider, grow);

		mTimeLabel = new Label();
		mTimeLabel.FontSize.Value = 12.0f;
		mTimeLabel.VAlign.Value = .Middle;
		var timeWidth = LayoutStyle();
		timeWidth.Width = SizeSpec.Fixed(Unit.Dp(110.0f));
		transport.AddView(mTimeLabel, timeWidth);

		let previewColumn = new FlexLayout();
		previewColumn.Direction = .Vertical;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		previewColumn.AddView(transport, match);
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		previewColumn.AddView(mPreview.View, growMatch);

		mGrid = new PropertyGrid();
		RebuildGrid();

		let split = new SplitView();
		split.AddRef();
		split.SplitRatio = 0.66f;
		split.SetPanes(previewColumn, mGrid);
		mContent = split;

		LoadPreviewPref();
	}

	public ~this()
	{
		ClearPreviewOverrides();
		mSkeleton.Forget();
		mClip.Forget();
		delete mPreview;
		delete mPreviewPlayer;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public AnimationClipAsset Asset => mAsset;
	public PreviewViewport Preview => mPreview;
	public Guid SkeletonGuid => mSkeletonGuid;
	public Guid PreviewMeshId => mPreviewMeshId;
	public float Time => mTime;
	public bool IsPlaying => mPlaying;

	/// The context every dialog opens against; null until the content is attached.
	private UIContext Ctx => (mGrid != null) ? mGrid.Context : null;

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
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved animation clip '{}'", mTitle);
		}
		return saved;
	}

	public override void OnClose()
	{
		if (mPreview != null)
			mPreview.Shutdown();
	}

	private void SnapshotAsset(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			ClipSourceEdit.Snapshot(mAsset, outBlob);
	}

	/// Restores a snapshot, the undo and redo path; a no-op when the asset already matches.
	public void ApplyAssetBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !ClipSourceEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(new () => { RebuildGrid(); });
		else
			RebuildGrid();
		MarkDirty();
	}

	/// Records the asset's current state against the undo baseline as one merged-per-key
	/// command; the rows call it after writing the source in place.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		SnapshotAsset(after);
		Commands.Execute(new EditClipCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
	}

	/// A shape change (an event added or removed): runs `mutate` off the grid's own event,
	/// commits it, then rebuilds the rows. `mutate` is consumed.
	private void QueueStructural(StringView undoKey, delegate void() mutate)
	{
		let key = new String(undoKey);
		delegate void() run = new [=this, =mutate, =key]() =>
			{
				mutate();
				CommitEdit(key);
				RebuildGrid();
			} ~ { delete mutate; delete key; };
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(run);
		else
		{
			run();
			delete run;
		}
	}
}
