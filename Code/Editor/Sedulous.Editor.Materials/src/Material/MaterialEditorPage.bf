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
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.Texture.Resource;
using Sedulous.Engine.Render;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Materials;

/// The material page (Raptor's editor-gui spec, 5.4, layer 4), on the preview pages' markup
/// (Data/Editor/PreviewPage.xml): the material on a preview shape lit by a sun and the default sky
/// (its clock running, so a shader that moves with Time moves), beside its rows. The authored form
/// IS the runtime source (MaterialSource), so Save writes it back and asks for a cook; every live
/// proxy bound to the cooked product then hot-swaps.
///
/// The rows are the material's, not its fields' (a source in parallel arrays: names, offsets, a
/// uniform blob): under Material its shader (a shader asset, or a built-in, PBR, Unlit or Phong) and its
/// pipeline state (blend, depth, cull); under Properties each value its shader declares, by its type
/// (a number, with the shader's range; two, three or four; an integer; a colour; a colour that may
/// pass white, with its intensity); under Textures each texture slot, a slot taking what makes a
/// Texture; then a section per effect group the material carries (Wind: its Strength, Speed and
/// Height), its rows from the effect's table as a custom shader's are, its values the group's
/// (`Wind.Strength`), and none for a material whose shader declares no effect. A shader switched,
/// undone or recooked lays the rows out again. What the preview shows
/// the material on (a shape, or a mesh of the project) is on the preview's bar, not among the
/// material's rows, and kept per material with the project.
///
/// Edits are whole-source snapshot commands (EditMaterialCommand): the serialized MaterialSource
/// before and after (it is tiny), exact undo whatever the layout, consecutive edits of one row
/// merged. Every apply rebuilds the preview's material, so a scrub reads live on the shape.
class MaterialEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/PreviewPage.xml";

	private PreviewPane mPane = null ~ delete _;
	/// One reference each, the page's: the preview's bar holds its own.
	private ComboBox mShapeChoice = null ~ _?.ReleaseRef();
	private AssetPickerSlot mMeshSlot = null ~ _?.ReleaseRef();
	/// The rows' sections: the material's (shader, pipeline state), its properties, its textures.
	/// Made again with the layout; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mMaterialRows = null;
	private Sedulous.GUI.PropertyBag mPropertyRows = null;
	private Sedulous.GUI.PropertyBag mTextureRows = null;
	/// A section per effect group, in the source's order, and the group each shows.
	private List<Sedulous.GUI.PropertyBag> mEffectRows = new .() ~ delete _;
	private List<String> mEffectRowNames = new .() ~ DeleteContainerAndItems!(_);
	/// The layout changed: the rows made again on the next Refresh, never inside the grid's commit
	/// that caused it.
	private bool mRowsDirty = false;
	/// The values changed under the rows: shown again on the next Refresh.
	private bool mReshow = false;
	/// A gesture under way (a drag, a scrub, a picker open): its previews are written to the source
	/// as they go, so the preview shows them, with no undo step; the source as it was before them is
	/// what the gesture's one step starts from, or what a cancel puts back.
	private bool mPreviewing = false;
	private bool mInGesture = false;
	private List<uint8> mGestureBefore = new .() ~ delete _;

	/// The preview shape entity, in the preview scene.
	private EntityHandle mShape = .Invalid;
	/// Owned: runtime built, never an asset. Null while a mesh of the project is the preview's.
	private StaticMesh mPreviewMesh = null;
	/// Owned; the preview entity draws it directly.
	private Material mPreviewMaterial = null;
	/// Index into MaterialPreviewShapes.
	private uint32 mPreviewShape = 0;
	/// Nil: the shape.
	private Guid mPreviewMeshGuid = .();
	/// Retained proxies of the textures the preview material captured, and the views it captured
	/// them at; a view change (a late cook, a reload) rebuilds the material.
	private List<Proxy<Texture>> mPreviewTextures = new .() ~ delete _;
	private List<ITextureView> mPreviewTextureViews = new .() ~ delete _;

	/// The material's shader asset, when it is on one: its resource (the version says when it
	/// recooked) and its property table (the rows' ranges).
	private Proxy<ShaderResource> mShader = default;
	private uint64 mShaderVersion = 0;
	private List<ShaderProperty> mShaderTable = new .() ~ DeleteContainerAndItems!(_);
	/// What the shader asset's vertex stage declares: the effects its materials carry.
	private ShaderFlags mShaderVertexVariants = .None;
	/// The renderer's shader system (borrowed; null without a host): the effects' tables, for a
	/// group's ranges and the group of an effect the material's shader declares that the
	/// material does not carry yet.
	private ShaderSystem mEffectSystem = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(MaterialAsset), cMarkupPath)
	{
		// Its source holds arrays no one edits by hand: the rows are the material's own.
		HideAssetRows();
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "material.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			if (let preview = mPane.Viewport)
			{
				// The scene's clock runs only while it simulates: a material on a shader that
				// animates with Time() (a scrolling surface, moving vertices, wind) moves.
				preview.SetSimulationEnabled(true);
				preview.Camera.Position = .(0.0f, 0.9f, 2.6f);
				preview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));
			}
			AddPreviewControls();
		}
		if (let asset = Edited)
		{
			let missing = scope String();
			if (asset.Source.ShaderId.IsNil && !ForwardMaterialContract.IsComplete(asset.Source, missing))
				GlobalLog(.Error, "Editor: material '{}' is missing the forward shader property '{}' (a stale source); make it again, the runtime refuses to build it", Title, missing);
		}
		if (let host = Services.Host)
		{
			if (let render = host.Subsystems.GetSubsystem<RenderSubsystem>())
				mEffectSystem = render.Shaders;
		}
		BindShader(); // a material on a shader asset shows the shader's current properties
		BuildPreviewScene();
		LoadPreviewPref(); // the shape or mesh this material was last shown on
		if ((mPreviewShape != 0) || !mPreviewMeshGuid.IsNil)
			ApplyPreviewMesh();
		BuildRows();
		ShowNotices();
		RebuildPreviewMaterial();
		if ((mPane != null) && (Edited != null))
			mPane.Show();
	}

	public ~this()
	{
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		DeleteRows();
		// The preview entity draws the page's mesh and material directly; detach them before
		// they go, then the pane and its scene.
		ClearPreviewOverrides();
		ForgetPreviewTextures();
		mShader.Forget();
		DeleteAndNullify!(mPane);
		delete mPreviewMaterial;
		delete mPreviewMesh;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane != null)
			mPane.Update(dt);
		// A bound texture's live view no longer the one the material captured (a cook, a reload):
		// the preview's material made again.
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
		// The shader asset recooked (its properties may have changed): re-lay the material by it.
		if ((mShader.Get != null) && (mShader.Get.Version != mShaderVersion))
		{
			BindShader();
			ShowNotices();
			RebuildPreviewMaterial();
		}
	}

	/// The rows shown again from the source (after an undo), or laid out again (a shader switched).
	public override void Refresh()
	{
		base.Refresh();
		if (mRowsDirty)
			BuildRows();
		else if (mReshow)
			ShowValues();
		mRowsDirty = false;
		mReshow = false;
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	/// The preview's shape (an index into MaterialPreviewShapes), kept per material; a shape picked
	/// takes over from a mesh.
	public void SetPreviewShape(uint32 shape)
	{
		mPreviewShape = (shape < (uint32)MaterialPreviewShapes.Names.Count) ? shape : 0;
		mPreviewMeshGuid = .();
		ApplyPreviewMesh();
		SavePreviewPref();
		mReshow = true;
	}

	/// A mesh of the project to show the material on (nil: the shape), kept per material.
	public void SetPreviewMesh(Guid mesh)
	{
		mPreviewMeshGuid = mesh;
		ApplyPreviewMesh();
		SavePreviewPref();
		mReshow = true;
	}

	public uint32 PreviewShape => mPreviewShape;
	public Guid PreviewMesh => mPreviewMeshGuid;

	// === For tests ===

	/// The material's source; null when it did not read.
	public MaterialSource Source => (Edited != null) ? Edited.Source : null;
	public PreviewPane Pane => mPane;
	public ComboBox ShapeChoice => mShapeChoice;
	public Sedulous.GUI.PropertyBag MaterialRows => mMaterialRows;
	public Sedulous.GUI.PropertyBag PropertyRows => mPropertyRows;
	public Sedulous.GUI.PropertyBag TextureRows => mTextureRows;

	/// An effect group's section (`Wind`), or null when the material carries no such group.
	public Sedulous.GUI.PropertyBag EffectRows(StringView effect)
	{
		for (int g < mEffectRowNames.Count)
		{
			if (mEffectRowNames[g] == effect)
				return mEffectRows[g];
		}
		return null;
	}

	/// Writes `value` to row `path` of `rows` as the grid commits an edit (one undo step).
	public void EditRow(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		rows.SetValue(path, 0, value); // as the grid's commit leaves it
		Committed(rows, path, value);
	}

	// === Edits and undo ===

	/// Restores a source snapshot, the undo and redo path, and rebuilds the preview.
	public void ApplySourceBlob(List<uint8> blob)
	{
		let asset = Edited;
		if (asset == null)
			return;
		let shaderBefore = asset.Source.ShaderId;
		let layoutBefore = scope List<String>();
		defer { ClearAndDeleteItems!(layoutBefore); }
		RowLayoutOf(asset.Source, layoutBefore);
		MaterialSourceEdit.Apply(asset.Source, blob);
		// A shader switched (or its switch undone) changes the rows and what the preview binds.
		if (asset.Source.ShaderId != shaderBefore)
			BindShader();
		mRowsDirty |= !SameLayout(layoutBefore, asset.Source);
		mReshow = true;
		ShowNotices();
		RebuildPreviewMaterial();
	}

	public void SnapshotSource(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (let asset = Edited)
			MaterialSourceEdit.Snapshot(asset.Source, outBlob);
	}

	/// Runs `mutate` on the source and records the before and after as one command merged per
	/// `mergeKey` (the mutation already ran; its Execute puts back what is there).
	private void ApplyEdit(StringView mergeKey, delegate void(MaterialSource source) mutate)
	{
		let asset = Edited;
		if (asset == null)
			return;
		if (mPreviewing)
		{
			// A preview: written to the source and shown, the source before the gesture kept.
			if (!mInGesture)
			{
				SnapshotSource(mGestureBefore);
				mInGesture = true;
			}
			mutate(asset.Source);
			RebuildPreviewMaterial();
			return;
		}
		// The gesture's one step starts from the source before its previews.
		let before = scope List<uint8>();
		if (mInGesture)
			before.AddRange(mGestureBefore);
		else
			SnapshotSource(before);
		mInGesture = false;
		mGestureBefore.Clear();
		// The rows follow a change of what the material holds (a built-in switched): the command's
		// Execute below applies `after` over itself, so it cannot see that change.
		let layoutBefore = scope List<String>();
		defer { ClearAndDeleteItems!(layoutBefore); }
		RowLayoutOf(asset.Source, layoutBefore);
		mutate(asset.Source);
		mRowsDirty |= !SameLayout(layoutBefore, asset.Source);
		let after = scope List<uint8>();
		SnapshotSource(after);
		Commands.Execute(new EditMaterialCommand(this, mergeKey, before, after));
	}

	/// What the rows are laid out from: the shader's property names, then each effect group's
	/// `Effect.Property` names. A change of it (a shader switched, its undo) lays them out again.
	private static void RowLayoutOf(MaterialSource source, List<String> outNames)
	{
		for (let name in source.PropertyNames)
			outNames.Add(new String(name));
		for (let group in source.Effects)
		{
			for (let name in group.PropertyNames)
				outNames.Add(new String()..AppendF("{}.{}", group.Name, name));
		}
	}

	private static bool SameLayout(List<String> before, MaterialSource source)
	{
		let now = scope List<String>();
		defer { ClearAndDeleteItems!(now); }
		RowLayoutOf(source, now);
		if (now.Count != before.Count)
			return false;
		for (int i < now.Count)
		{
			if (now[i] != before[i])
				return false;
		}
		return true;
	}

	/// A gesture given up: the source as it was before its previews, the preview with it.
	private void CancelGesture()
	{
		if (!mInGesture)
			return;
		mInGesture = false;
		ApplySourceBlob(mGestureBefore);
		mGestureBefore.Clear();
	}

	private MaterialAsset Edited => ObjectAs<MaterialAsset>();

	/// The stale source and the shader that has not cooked, each a notice while it holds.
	private void ShowNotices()
	{
		let asset = Edited;
		if (asset == null)
			return;
		let missing = scope String();
		let complete = !asset.Source.ShaderId.IsNil || ForwardMaterialContract.IsComplete(asset.Source, missing);
		SetNotice("stale", complete ? "" : scope String()..AppendF("This material lacks the forward shader's {}: it was made by an older editor. Make it again; the game refuses to build it.", missing));
		SetNotice("shader", (!asset.Source.ShaderId.IsNil && mShaderTable.IsEmpty)
			? "Its shader has not cooked (or has errors): its rows are its own until it does." : "");
	}
}
