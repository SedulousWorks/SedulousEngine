using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Materials.Pipeline;
using Sedulous.Texture.Resource;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// The material page: a live preview of the material on a primitive or a mesh asset on
/// the left, the property grid on the right. Every edit is a whole-source snapshot command
/// (EditMaterialCommand), merged per row, and the preview material is rebuilt from the
/// source after each one, so undo shows too.
class MaterialEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;

	/// Owned; null when the read failed and the page opened empty.
	private MaterialAsset mAsset = null ~ delete _;

	private PreviewViewport mPreview = null;
	/// The preview shape entity, in the preview scene.
	private EntityHandle mSphere = .Invalid;
	/// Owned: runtime built, never an asset. Null while a mesh asset is the preview shape.
	private StaticMesh mPreviewMesh = null;
	/// Owned; the preview entity draws it directly.
	private Material mPreviewMaterial = null;
	/// Index into MaterialPreviewShapes.
	private uint32 mPreviewShape = 0;
	/// Nil = primitive shape.
	private Guid mPreviewMeshGuid = .();
	/// Retained proxies of the textures the preview material captured, and the views it
	/// captured them at; a view change (a late cook, a reload) rebuilds the material.
	private List<Proxy<Texture>> mPreviewTextures = new .() ~ delete _;
	private List<ITextureView> mPreviewTextureViews = new .() ~ delete _;

	/// Borrowed: the content owns it.
	private PropertyGrid mGrid = null;
	private SplitView mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private List<delegate void()> mRefreshers = new .() ~ DeleteContainerAndItems!(_);
	private List<Object> mOwned = new .() ~ DeleteContainerAndItems!(_);

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);

		let object = instance.ReadObject();
		mAsset = object as MaterialAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: material '{}' failed to read, page opens empty", mTitle);
		else
		{
			let missing = scope String();
			if (!ForwardMaterialContract.IsComplete(mAsset.Source, missing))
				GlobalLog(.Error, "Editor: material '{}' is missing the forward shader property '{}' (a stale source); re-create it, the runtime refuses to build it", mTitle, missing);
		}

		mPreview = new PreviewViewport(host, uiHost, "material.preview");
		mPreview.Camera.Position = .(0.0f, 0.9f, 2.6f);
		mPreview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));

		BuildPreviewScene();

		InstanceId = instance.Id;

		LoadPreviewPref();
		if ((mPreviewShape != 0) || !mPreviewMeshGuid.IsNil)
			ApplyPreviewMesh();

		mGrid = new PropertyGrid();
		RebuildGrid();

		let gridColumn = new FlexLayout();
		gridColumn.Direction = .Vertical;
		gridColumn.Padding = .(8, 6);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		gridColumn.AddView(mGrid, grow);

		mContent = new SplitView();
		mContent.AddRef();
		mContent.SplitRatio = 0.62f;
		mContent.SetPanes(mPreview.View, gridColumn);

		RebuildPreviewMaterial();
	}

	public ~this()
	{
		// The preview entity draws the page's mesh and material directly; detach them before
		// they go, then the viewport and its scene.
		ClearPreviewOverrides();
		ForgetPreviewTextures();
		delete mPreview;
		delete mPreviewMaterial;
		delete mPreviewMesh;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public MaterialAsset Asset => mAsset;
	public PreviewViewport Preview => mPreview;
	public uint32 PreviewShape => mPreviewShape;
	public Guid PreviewMeshGuid => mPreviewMeshGuid;
	public PropertyGrid Grid => mGrid;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mPreview != null)
			mPreview.Update(dt);

		for (int i < mPreviewTextures.Count)
		{
			let texture = mPreviewTextures[i].Get;
			let live = (texture != null) ? texture.View : null;
			if (live !== mPreviewTextureViews[i])
			{
				RebuildPreviewMaterial();
				break;
			}
		}

		for (let refresher in mRefreshers)
			refresher();
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
			GlobalLog(.Information, "Editor: saved material '{}'", mTitle);
		}
		return saved;
	}

	public override void OnClose()
	{
		if (mPreview != null)
			mPreview.Shutdown();
	}

	/// Restores a source snapshot, the undo and redo path, and rebuilds the preview.
	public void ApplySourceBlob(List<uint8> blob)
	{
		if (mAsset == null)
			return;
		MaterialSourceEdit.Apply(mAsset.Source, blob);
		RebuildPreviewMaterial();
	}

	public void SnapshotSource(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			MaterialSourceEdit.Snapshot(mAsset.Source, outBlob);
	}

	/// Runs `mutate` on the source and records the before and after as one merged-per-key
	/// command. `mutate` is consumed.
	public void ApplyEdit(StringView mergeKey, delegate void(MaterialSource source) mutate)
	{
		defer delete mutate;
		if (mAsset == null)
			return;
		let before = scope List<uint8>();
		SnapshotSource(before);
		mutate(mAsset.Source);
		let after = scope List<uint8>();
		SnapshotSource(after);
		Commands.Execute(new EditMaterialCommand(this, mergeKey, before, after));
	}

	/// The context every dialog opens against; null until the content is attached.
	private UIContext Ctx => (mGrid != null) ? mGrid.Context : null;

	private StringView AssetNameFor(Guid target)
	{
		if (target.IsNil)
			return "(none)";
		if (mContext.Project != null)
		{
			if (let inst = mContext.Project.SourceDb.GetInstance(target))
				return inst.Name;
		}
		return "(missing)";
	}

	/// Adds `editor` to the grid, which owns it, and keeps `refresher` to pull the shown value
	/// each frame while the row is not being edited. `refresher` is consumed.
	private void AddEditor(PropertyEditor editor, delegate void() refresher)
	{
		mGrid.AddProperty(editor);
		mRefreshers.Add(new [=editor, =refresher]() =>
			{
				if (!editor.IsEditing)
					refresher();
			} ~ delete refresher);
	}

	/// Keeps a helper object alive for the page's lifetime.
	private T Own<T>(T object) where T : class
	{
		mOwned.Add(object);
		return object;
	}
}
