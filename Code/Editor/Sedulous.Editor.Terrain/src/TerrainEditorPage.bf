using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Terrain.Pipeline;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Terrain;

/// The terrain page: the cooked product on a preview entity under a shadowing sun,
/// following reloads by product identity, beside a pane of the authored references, the
/// base and paint layers, the blend knobs and the stats. Every edit is a whole asset
/// snapshot command; the preview shows the product as last cooked, so Save cooks.
class TerrainEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private TerrainAsset mAsset = null ~ delete _;

	private PreviewViewport mPreview = null;
	/// The preview terrain entity, in the preview scene.
	private EntityHandle mEntity = .Invalid;
	/// The cooked product, retained; follows reloads.
	private Proxy<TerrainResource> mTerrainProxy = default;
	/// Product identity, so a hot reload re-points the component.
	private TerrainResource mLastProduct = null;

	/// Borrowed: the content owns them.
	private FlexLayout mFields = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private List<uint8> mUndoBaseline = new .() ~ delete _;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as TerrainAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: terrain '{}' failed to read, page opens empty", mTitle);

		mPreview = new PreviewViewport(host, uiHost, "terrain.preview");
		mPreview.Camera.Position = .(180.0f, 140.0f, 180.0f);
		mPreview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));
		BuildPreviewScene();

		mFields = new FlexLayout();
		mFields.Direction = .Vertical;
		mFields.Spacing = 4.0f;
		mFields.Padding = .(8, 6);

		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		scroll.AddView(mFields, match);

		let split = new SplitView();
		split.SplitRatio = 0.62f;
		split.SetPanes(mPreview.View, scroll);
		mContent = split;

		Snapshot(mUndoBaseline);
		BindTerrain();
		RebuildFields();
	}

	public ~this()
	{
		PointComponentAtTerrain(null);
		mTerrainProxy.Forget();
		delete mPreview;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public TerrainAsset Asset => mAsset;
	public PreviewViewport Preview => mPreview;
	/// The cooked product the preview shows, or null while it is not cooked.
	public TerrainResource Product => mTerrainProxy.Get;

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
			mContext.RequestCook(false); // hot swaps the bound TerrainResource
			GlobalLog(.Information, "Editor: saved terrain '{}'", mTitle);
		}
		return saved;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mPreview != null)
			mPreview.Update(dt);
		let product = mTerrainProxy.Get;
		if (product !== mLastProduct)
		{
			PointComponentAtTerrain(product);
			mLastProduct = product;
			FramePreview(product);
			RebuildFields();
		}
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

	/// One TerrainComponent entity plus a seeded sun that casts, so the preview shows the
	/// terrain's self shadowing.
	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if (scene == null)
			return;
		if (scene.GetSystem<TerrainComponentManager>() == null)
			TerrainScene.AddTerrainSceneManagers(scene);

		mEntity = scene.CreateEntity("PreviewTerrain");
		if (let terrains = scene.GetSystem<TerrainComponentManager>())
			terrains.Add(mEntity); // the terrain lands in BindTerrain once the product resolves

		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.5f) * Quaternion.FromAxisAngle(.(1, 0, 0), -0.9f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.Type = .Directional;
			light.CastsShadows = true;
		}
	}

	/// (Re)binds the cooked product by the asset's guid, reframes and refreshes the stats.
	private void BindTerrain()
	{
		if (mContext.Resources != null)
		{
			mTerrainProxy.Forget();
			mTerrainProxy = mContext.Resources.Bind<TerrainResource>(InstanceId);
			mTerrainProxy.Retain();
		}
		let product = mTerrainProxy.Get;
		PointComponentAtTerrain(product);
		mLastProduct = product;
		FramePreview(product);
	}

	private TerrainComponent* PreviewComponent()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		let terrains = (scene != null) ? scene.GetSystem<TerrainComponentManager>() : null;
		return ((terrains != null) && mEntity.IsAssigned) ? terrains.Get(mEntity) : null;
	}

	private void PointComponentAtTerrain(TerrainResource product)
	{
		let tc = PreviewComponent();
		if (tc == null)
			return;
		tc.Terrain.SetId(.());
		tc.Terrain.SetDirect(product); // the cooked product, or null while it is not cooked yet
	}

	private void FramePreview(TerrainResource product)
	{
		if (mPreview == null)
			return;
		var worldSize = 256.0f;
		var midY = 0.0f;
		let grid = (product != null) ? product.Heightfield.Get : null;
		if (grid != null)
		{
			let ws = grid.WorldSize;
			worldSize = Math.Max(ws.X, ws.Y);
			midY = 0.5f * (grid.MinY + grid.MaxY);
		}
		let dist = worldSize * 0.85f;
		mPreview.Camera.Position = .(dist * 0.7f, dist * 0.6f + midY, dist * 0.7f);
		mPreview.Camera.LookAt(.(0.0f, midY, 0.0f));
	}

	// ---- edits ----

	public void AddLayer()
	{
		if (mAsset == null)
			return;
		TerrainAssetEdit.AddLayer(mAsset);
		CommitEdit("addLayer");
		RebuildFieldsDeferred();
	}

	public void RemoveLayer(int index)
	{
		if ((mAsset == null) || !TerrainAssetEdit.RemoveLayer(mAsset, index))
			return;
		RemapWeightsOnRemove((uint32)index);
		CommitEdit("removeLayer");
		mContext.RequestCook(false);
		RebuildFieldsDeferred();
	}

	public void SetPaletteMap(PaletteMap map, int index, Guid id)
	{
		if (mAsset != null)
			TerrainAssetEdit.SetPaletteMap(mAsset, map, index, id);
	}

	/// Frees the removed layer's slots in the live raster and decrements the indices above
	/// it, registering the rewritten rasters against the splatmap source. Nothing to do
	/// while there is no live raster: nothing references the palette indices yet.
	private void RemapWeightsOnRemove(uint32 removedIndex)
	{
		let product = mTerrainProxy.Get;
		let weights = (product != null) ? product.Weights.Get : null;
		if ((weights == null) || weights.IsEmpty)
			return;
		if (!SplatBrush.RemapOnPaletteRemove(weights, removedIndex))
			return;
		let id = product.Weights.Id;
		if (id.IsSet)
			mContext.RegisterAssetEdit(id, TerrainPersist.ForSplat(weights, id));
	}

	/// Authors a blank splatmap asset beside the terrain and assigns it as the weights.
	public void CreateSplatmap(int32 size)
	{
		if ((mAsset == null) || (mContext.Project == null))
			return;
		let root = mContext.Project.SourceDb.RootGroup;
		if (root == null)
			return;
		let dim = (size > 0) ? size : 1024;
		let name = scope $"{AssetName(InstanceId, .. scope .())}_splat";
		let inst = root.CreateInstance(name, typeof(SplatmapAsset).GetFullName(.. scope .()));
		if (inst == null)
		{
			mContext.Notify(.Error, "Splatmap create FAILED (name in use?).");
			return;
		}
		let sa = scope SplatmapAsset();
		sa.Width = dim;
		sa.Height = dim;
		inst.WriteObject(sa).IgnoreError();
		mAsset.WeightsId = inst.Id;
		CommitEdit("createSplatmap");
		mContext.RequestCook(false); // cooks the new SplatmapAsset into its product
		PointComponentAtTerrain(mTerrainProxy.Get);
		RebuildFieldsDeferred();
		mContext.Notify(.Success, "Created splatmap.");
	}

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			TerrainAssetEdit.Snapshot(mAsset, outBlob);
	}

	/// Records the asset's current state against the undo baseline as one merged-per-key
	/// command.
	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditTerrainCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
	}

	/// Restores a snapshot, the undo and redo path, outside a live UI event so the pane
	/// rebuilds directly.
	public void ApplyBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !TerrainAssetEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		PointComponentAtTerrain(mTerrainProxy.Get);
		RebuildFields();
		MarkDirty();
	}

	/// The source asset's name for a label: "(none)" for an unset id, "(missing)" for one
	/// the project does not hold.
	private void AssetName(Guid id, String outName)
	{
		if (id.IsNil)
		{
			outName.Append("(none)");
			return;
		}
		if (mContext.Project != null)
		{
			if (let inst = mContext.Project.SourceDb.GetInstance(id))
			{
				outName.Append(inst.Name);
				return;
			}
		}
		outName.Append("(missing)");
	}
}
