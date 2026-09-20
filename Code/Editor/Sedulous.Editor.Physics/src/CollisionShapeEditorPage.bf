using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Physics.Resource;
using Sedulous.Physics.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Physics;

/// The collision shape page: the cooked outline drawn as a wireframe in a preview, beside
/// the source mesh pick, the cook mode toggle, the hull tolerance and a Cook now button
/// that saves, which is what triggers the cook. Two fields with no undo: Discard reloads.
class CollisionShapeEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private CollisionShapeAsset mAsset = null ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private Label mMeshLabel = null;
	private Button mCookButton = null;
	private FloatEditor mToleranceRow = null;
	private Label mStatus = null;
	private PreviewViewport mPreview = null ~ delete _;
	/// The cooked product, retained.
	private Proxy<CollisionShape> mShape = default;
	private int mFramedCount = 0;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as CollisionShapeAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: collision shape '{}' failed to read, page opens empty", mTitle);

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8.0f;
		column.Padding = .(10, 8);

		{
			let row = AddLabeledRow(column, "Source mesh");
			mMeshLabel = new Label("");
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(mMeshLabel, grow);
			let pick = new Button("Pick...");
			pick.OnClick.Add(new [=this](btn) => { PickMesh(); });
			row.AddView(pick);
		}
		{
			let row = AddLabeledRow(column, "Cook");
			mCookButton = new Button((mAsset != null) ? CookLabel(mAsset.Cook) : "-");
			mCookButton.OnClick.Add(new [=this](btn) =>
				{
					if (mAsset == null)
						return;
					mAsset.Cook = (mAsset.Cook == .ConvexHull) ? .TriangleMesh : .ConvexHull;
					mCookButton.SetText(CookLabel(mAsset.Cook));
					RefreshTolerance();
					MarkDirty();
				});
			row.AddView(mCookButton);
		}
		{
			// The hull's one knob, in a grid of its own so it reads like the other pages.
			let grid = new PropertyGrid();
			mToleranceRow = new FloatEditor("Hull Tolerance", (mAsset != null) ? mAsset.HullTolerance : 0.0, 0.0, 0.1, 0.0001, 4, new [=this](v) =>
				{
					if (mAsset == null)
						return;
					mAsset.HullTolerance = (float)v;
					MarkDirty();
				}, "Cook");
			grid.AddProperty(mToleranceRow);
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			column.AddView(grid, match);
		}
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 8.0f;
			let cook = new Button("Cook now");
			cook.OnClick.Add(new [=this](btn) => { Save().IgnoreError(); });
			row.AddView(cook);
			mStatus = new Label("");
			mStatus.FontSize.Value = 12.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(mStatus, grow);
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			column.AddView(row, match);
		}

		mPreview = new PreviewViewport(host, uiHost, "collision.preview");
		let split = new SplitView();
		split.SplitRatio = 0.62f;
		split.SetPanes(mPreview.View, column);

		mToolbar = new PageToolbar(this);
		let pageColumn = new FlexLayout();
		pageColumn.Direction = .Vertical;
		var matchTop = LayoutStyle();
		matchTop.Width = SizeSpec.Match();
		pageColumn.AddView(mToolbar, matchTop);
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		pageColumn.AddView(split, growMatch);
		mContent = pageColumn;

		if (mContext.Resources != null)
		{
			mShape = mContext.Resources.Bind<CollisionShape>(InstanceId);
			mShape.Retain();
		}
		RefreshTolerance();
		RefreshStatus();
	}

	public ~this()
	{
		mShape.Forget();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public CollisionShapeAsset Asset => mAsset;

	public static StringView CookLabel(CollisionCookKind kind) => (kind == .ConvexHull) ? "Convex hull (dynamic)" : "Triangle mesh (static)";

	private void MeshName(Guid id, String outName)
	{
		if (id.IsNil || (mContext.Project == null))
		{
			outName.Set("(none - pick a mesh)");
			return;
		}
		let inst = mContext.Project.SourceDb.GetInstance(id);
		if (inst != null)
			inst.GetPath(outName);
		else
			outName.Set("(missing mesh)");
	}

	private static FlexLayout AddLabeledRow(FlexLayout column, StringView labelText)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 6.0f;
		let label = new Label(labelText);
		var labelStyle = LayoutStyle();
		labelStyle.Width = SizeSpec.Fixed(Unit.Dp(90.0f));
		labelStyle.AlignSelf = .Center;
		row.AddView(label, labelStyle);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(row, match);
		return row;
	}

	private void PickMesh()
	{
		if ((mAsset == null) || (mContent.Context == null) || (mContext.Project == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("StaticMeshAsset", "SkinnedMeshAsset"));
		dialog.OnPicked = new [=this](picked) =>
			{
				mAsset.SourceMesh = picked;
				MarkDirty();
				RefreshStatus();
			};
		dialog.Show(mContent.Context);
	}

	/// Reloads the asset from the source database.
	public override void DiscardChanges()
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance != null)
		{
			let object = instance.ReadObject();
			if (let asset = object as CollisionShapeAsset)
			{
				delete mAsset;
				mAsset = asset;
				if (mCookButton != null)
					mCookButton.SetText(CookLabel(mAsset.Cook));
				RefreshTolerance();
				RefreshStatus();
			}
			else
				delete object;
		}
		Commands.Clear();
		ClearDirty();
	}

	/// The tolerance only means something for a hull.
	private void RefreshTolerance()
	{
		if ((mToleranceRow == null) || (mAsset == null))
			return;
		mToleranceRow.SetValue(mAsset.HullTolerance);
		mToleranceRow.SetRowVisible(mAsset.Cook == .ConvexHull);
	}

	private void RefreshStatus()
	{
		if (mAsset == null)
			return;
		let name = MeshName(mAsset.SourceMesh, .. scope .());
		mMeshLabel.SetText(name);
		if (mAsset.SourceMesh.IsNil)
			mStatus.SetText("No source mesh - pick one, then Cook now.");
		else
			mStatus.SetText(scope $"Cooks a collider from {name}.");
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
			mContext.RequestCook(false); // re-cook, so a body on the cooked shape gets its collider
			RefreshStatus();
			GlobalLog(.Information, "Editor: saved collision shape '{}'", mTitle);
		}
		return saved;
	}

	/// The outline triangles as a wireframe, framed once per cooked product.
	private void DrawOutline()
	{
		if ((mPreview == null) || !mPreview.IsValid)
			return;
		let shape = mShape.Get;
		if ((shape == null) || (shape.Outline.Count < 3))
			return;
		let tris = shape.Outline;
		if (tris.Count != mFramedCount)
		{
			var lo = tris[0];
			var hi = tris[0];
			for (let v in tris)
			{
				lo = .(Math.Min(lo.X, v.X), Math.Min(lo.Y, v.Y), Math.Min(lo.Z, v.Z));
				hi = .(Math.Max(hi.X, v.X), Math.Max(hi.Y, v.Y), Math.Max(hi.Z, v.Z));
			}
			mPreview.Camera.FrameBounds((lo + hi) * 0.5f, Length((hi - lo) * 0.5f));
			mFramedCount = tris.Count;
		}
		let draw = mPreview.SceneDebugDraw;
		let color = Color(0.30f, 0.95f, 0.55f, 1.0f);
		for (int i = 0; i + 2 < tris.Count; i += 3)
		{
			draw.DrawLine(tris[i], tris[i + 1], color);
			draw.DrawLine(tris[i + 1], tris[i + 2], color);
			draw.DrawLine(tris[i + 2], tris[i], color);
		}
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
		if (mPreview != null)
			mPreview.Update(dt);
		DrawOutline();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPreview != null)
			mPreview.RenderFrame(ref frame);
	}

	public override void OnClose()
	{
		if (mPreview != null)
			mPreview.Shutdown();
	}
}
