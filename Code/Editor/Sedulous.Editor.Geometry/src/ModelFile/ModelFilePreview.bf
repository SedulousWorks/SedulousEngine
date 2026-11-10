using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Animation;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Engine.Model;
using Sedulous.GUI;
using Sedulous.Image.IO; // a texture part's picture, from the file beside the model
using Sedulous.Pipeline.Importer;
using Sedulous.ModelImporter;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;
using Sedulous.Editor.ModelPreview;
using Sedulous.Editor.Animation; // DrawSkeletonBones, FillBoneTree: the skeleton page's, shared

namespace Sedulous.Editor.Geometry;

// The import window's preview of a model file: the model live in
// a PreviewViewport (orbit, zoom, Frame), with its clips (a picker, play and pause) and its skeleton
// drawn over it on request; and the facts the file gives (meshes, triangles, materials, textures,
// bones, clips). It opens through Editor.ModelPreview's OpenModel into a cache folder under the
// project's cache: a model opened before binds from there, and one that must be read is read on the
// editor's task pool, then cooked and bound on the main thread, which owns the resources.
// Without a host (a test) there is no view, but the model still opens and its facts show. The window
// drives it each frame (IImportPreviewFrames).

class ModelFilePreview : IImportPreview, IImportPreviewFrames, IImportPartPreview
{
	/// The part the window asked to show alone (shown once the model is in), and what showing it
	/// changed, to undo for the whole file.
	private bool mShowsPart = false;
	private ImportResourceKind mPartKind = .Asset;
	private String mPartName = new .() ~ delete _;
	private EntityHandle mSphere = .Invalid;
	/// The sphere a material part is shown on, made the first time; ours.
	private Sedulous.Geometry.StaticMesh mSphereMesh = null ~ delete _;
	/// The skeleton part turned the bones on.
	private bool mBonesByPart = false;
	/// The model as read, for a texture part's picture: the importer's (borrowed: the window stops
	/// this before it changes or frees it), or the preview's own read (a reference of ours).
	private Model mImported = null;
	private Read mOwnRead = null;
	/// A texture part's picture, in place of the model's view, made the first time: the view a
	/// reference of ours (the root holds its own).
	private Node mPictureView = null;
	private ImagePreview mPicture = null ~ delete _;
	/// The model's bar; the tree's.
	private Node mBar = null;
	/// The skeleton's bones in a tree for its details, and the bone chosen there (drawn apart): the
	/// model ours, the tree last shown a reference of ours, let go of the model before it goes.
	private TreeModel mBoneModel = null;
	private List<int32> mBoneRows = new .() ~ delete _;
	private int32 mChosenBone = -1;
	private TreeView mBoneTree = null;
	/// The bones' rest, when no clip plays.
	private List<BoneTransform> mBindPoses = new .() ~ delete _;
	/// The file's import settings (borrowed: the window keeps them past this), and each mesh's own
	/// materials while the import leaves them out (it draws the default then).
	private ImportOptions mOptions = null;
	private List<(EntityHandle Entity, List<Sedulous.Resource.Ref<Sedulous.Materials.Material>> Materials)> mKeptMaterials = new .() ~ { for (let kept in _) delete kept.Materials; delete _; };
	/// A material drawn as the default, and one drawn without a texture.
	private bool mDefaultMaterial = false;
	private bool mWithoutTextures = false;
	/// What a material left out draws (made the first time), and the copies drawn without a texture
	/// left out, by the material each is of (null: it uses none of them): ours. A change's copies are
	/// kept, retired, until this goes after the GPU is done (the frames in flight may draw them).
	private Sedulous.Materials.Material mFallbackMaterial = null;
	private List<(Sedulous.Materials.Material From, Sedulous.Materials.Material Copy)> mStripped = new .() ~ delete _;
	private List<Sedulous.Materials.Material> mRetired = new .() ~ delete _;

	/// Where the import window's model previews cook, under a project's cache folder.
	public const String cCacheFolder = "ModelPreviews";

	/// What the worker reads, for the main thread to cook and bind: nothing else touches it until
	/// it is back.
	private class Read : RefCounted
	{
		public Model Model = new .() ~ delete _;
		/// Handed to OpenModel.Finish, which takes it.
		public ModelStats Stats = new .() ~ delete _;
		/// What the cook made, to bind.
		public Guid Guid = .();
		public OpenModel.Outcome Outcome = .NotFound;
	}

	private String mPath = new .() ~ delete _;
	private IDevice mDevice = null;
	/// One reference, this one's.
	private Node mRoot ~ _.ReleaseRef();
	// The tree's.
	private ComboBox mClips = null;
	private ToolButton mPlay = null;
	private ToolButton mSkeleton = null;
	private Sedulous.GUI.Label mMessage = null;
	private Node mStage = null;
	/// Null without a host.
	private PreviewViewport mViewport = null;
	private OpenModel mOpen = new .();
	private ModelInstance mInstance = new .() ~ delete _;
	private ClipPlayback mPlayback = null;
	private List<String> mFacts = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mClipNames = new .() ~ DeleteContainerAndItems!(_);
	private List<Float4x4> mBonePoses = new .() ~ delete _;
	private Float3 mCenter = .Zero;
	private float mRadius = 1.0f;
	/// The read and cook it started, cancelled and waited for as it goes: a reference of ours.
	private TaskHandle mRead = null;
	/// What it runs on; borrowed: it outlives this.
	private TaskPool mPool = null;
	private delegate void() mOnChanged ~ delete _;

	/// Opens `path` with its cooked files under `cacheRoot`: bound at once when opened before, else
	/// cooked on `tasks` (borrowed: it outlives this) from `imported` (the model the importer read;
	/// borrowed: the window stops this before it changes or frees it, StopReading), else read and
	/// cooked there. `services` give the host and GUI the view needs
	/// (no host: no view); borrowed. `options` (the file's import settings, which outlive this) say
	/// what the import leaves out: materials left out draw the default.
	public this(StringView path, StringView cacheRoot, TaskPool tasks, AssetPageServices services, Model imported = null,
		ImportOptions options = null)
	{
		mPath.Set(path);
		mImported = imported; // kept whichever way it opens: a texture's picture comes from it
		mOptions = options;
		BuildView(services);
		Start(cacheRoot, tasks, imported);
	}

	public ~this()
	{
		if (mRead != null)
		{
			StopReading(); // what the cook reads, the importer's model, is not ours to outlive
			mRead.ReleaseRef();
		}
		// The frames in flight still draw the model's textures, so the GPU finishes them before the
		// model releases them.
		if (mDevice != null)
			mDevice.WaitIdle();
		DeleteAndNullify!(mPlayback);
		if (mViewport != null)
			mViewport.Shutdown();
		DeleteAndNullify!(mViewport);
		mOpen.Close();
		delete mOpen;
		if (mPictureView != null)
			mPictureView.ReleaseRef();
		if (mOwnRead != null)
			mOwnRead.ReleaseRef();
		// After the GPU is done (above): the materials it drew in place of the model's.
		for (let made in mStripped)
			delete made.Copy;
		ClearAndDeleteItems!(mRetired);
		delete mFallbackMaterial;
		DropBoneTree();
		delete mBoneModel;
	}

	public Node View => mRoot;
	public Span<String> Facts => mFacts;

	public void SetOnChanged(delegate void() onChanged)
	{
		delete mOnChanged;
		mOnChanged = onChanged;
	}

	public void OnUpdate(IApplicationHost host, float dt)
	{
		if (mOpen.IsLoading)
			UpdateLoading(); // its parts finish a few a frame; it binds once they are in
		else if (mOpen.Resources != null)
			mOpen.Resources.Pump(); // the model's textures finish loading
		if (mViewport == null)
			return;
		if (mViewport.Update(dt))
			Frame(); // F over the view
		DrawSkeleton();
		ShowPlay();
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mViewport != null)
			mViewport.RenderFrame(ref frame);
	}

	// For tests.
	/// Whether the model opened (cooked or from the cache, and bound).
	public bool IsOpen => mOpen.IsOpen;
	/// Whether a texture's picture shows in place of the model.
	public bool ShowsPicture => (mPictureView != null) && mPictureView.Displayed;
	/// Whether the model draws the default material for a material left out of the import.
	public bool DrawsDefaultMaterial => mDefaultMaterial;
	/// Whether the model draws a material without a texture left out of the import.
	public bool DrawsWithoutTextures => mWithoutTextures;

	/// The file's settings changed: the model drawn as it will import (materials left out draw the
	/// default material).
	public void OnSettingsChanged()
	{
		ShowAsImported();
	}
	/// The clips the picker lists, by name.
	public Span<String> Clips => mClipNames;

	private void BuildView(AssetPageServices services)
	{
		let panel = new Sedulous.GUI.Panel();
		panel.AddClass("import-model");
		let bar = new Sedulous.GUI.Panel();
		bar.AddClass("panel-toolbar");
		mBar = bar;
		let frame = Tool("Editor/Icons/frame-selection.svg", "Frame it (F)");
		frame.SetOnClick(new [=this] () => { Frame(); });
		let clipChoice = new ComboBox();
		clipChoice.AddClass("import-model-clip");
		clipChoice.Tooltip = "The clip it plays";
		clipChoice.SetOnSelectionChanged(new [=this] (index) =>
			{
				if ((mPlayback != null) && (index >= 0))
					mPlayback.Select(index);
				ShowPlay();
			});
		let playButton = Tool("Editor/Icons/pause.svg", "Play or pause the clip");
		playButton.SetOnClick(new [=this] () =>
			{
				if (mPlayback != null)
					mPlayback.SetPlaying(!mPlayback.Playing);
				ShowPlay();
			});
		let bones = Tool("Editor/Icons/character.svg", "Draw the bones over the model");
		bones.IsToggle = true;
		mClips = clipChoice;
		mPlay = playButton;
		mSkeleton = bones;
		Add(bar, frame);
		Add(bar, clipChoice);
		Add(bar, playButton);
		Add(bar, bones);
		let stagePanel = new Sedulous.GUI.Panel();
		stagePanel.AddClass("import-model-stage");
		mStage = stagePanel;
		let text = new Sedulous.GUI.Label();
		text.AddClasses("state-text import-model-message");
		mMessage = text;
		Add(panel, bar);
		Add(panel, stagePanel);
		Add(panel, text);
		mRoot = panel;
		ShowClips(); // none until it opens

		if (services.Host == null)
			return; // a test: no view, the model still opens
		if (services.Host.Graphics != null)
			mDevice = services.Host.Graphics.Raw;
		mViewport = new PreviewViewport(services.Host, services.Gui, "import.model.preview");
		mViewport.SetSimulationEnabled(true); // so its clip plays
		mStage.AddChild(mViewport.View);
		Light();
	}

	/// A sun from the side, down at about fifty degrees (the render subsystem gives the scene its
	/// default sky).
	private void Light()
	{
		let level = (mViewport != null) ? mViewport.Scene : null;
		if (level == null)
			return;
		if (let lights = level.GetSystem<LightComponentManager>())
		{
			let sun = level.CreateEntity("sun");
			var t = Transform();
			t.Rotation = FromYawPitchRoll(0.6f, -0.9f, 0.0f);
			level.SetLocalTransform(sun, t);
			let light = lights.Add(sun);
			light.Type = .Directional;
			light.Intensity = 2.5f;
			light.CastsShadows = true;
		}
	}

	private void Start(StringView cacheRoot, TaskPool tasks, Model imported)
	{
		mMessage.Text = scope $"Reading {ImportPaths.FileNameOf(mPath)}...";
		// As the importer reads it: without the viewer's loose texture rule, which the import does
		// not apply either, so the preview shows what will come in.
		mOpen.LooseTextures = false;
		mPool = tasks;
		mOpen.SetTasks(tasks); // its parts decode there, and OnUpdate binds it once they are in
		let begun = mOpen.Begin(mPath, cacheRoot, mDevice, let outcome);
		if (begun == .Bound)
		{
			Opened();
			return;
		}
		if (begun == .Loading)
		{
			ShowLoading();
			return;
		}
		if (begun == .Failed)
		{
			Failed(outcome);
			return;
		}
		// Read (unless the importer has) and cooked on the worker, bound here. The task holds the
		// cache by reference, so a preview that goes first frees nothing under it; the importer's read
		// is the window's, which stops the task (StopReading) before it changes or frees that.
		let result = new Read(); // the done's reference
		result.AddRef(); // the work's
		if (imported != null)
			ModelLibrary.CountModel(imported, result.Stats); // here: this thread reads the model too
		let cache = mOpen.Cache;
		cache.AddRef(); // the work's
		let file = new String(mPath);
		mRead = tasks.Submit(scope $"Previewing {ImportPaths.FileNameOf(mPath)}",
			// On the worker: only the file, `result`, the cache and the importer's model.
			new [=file, =result, =cache, =imported] (context) =>
			{
				var model = imported;
				if (model == null)
				{
					result.Outcome = OpenModel.LoadFile(file, false, result.Model, result.Stats);
					if (result.Outcome != .Opened)
						return Result<void, ErrorCode>.Ok; // Arrived says why
					model = result.Model;
				}
				result.Outcome = OpenModel.Cook(cache, model, result.Stats, out result.Guid, context.Token);
				return (result.Outcome == .Cancelled) ? Result<void, ErrorCode>.Err(.Cancelled) : Result<void, ErrorCode>.Ok;
			} ~ { delete file; result.ReleaseRef(); cache.ReleaseRef(); },
			// On the main thread, which owns the cache's resources, and only while this preview lives
			// (it cancels its task as it goes).
			new [=this, =result] (status) => { Arrived(result); } ~ { result.ReleaseRef(); });
		mRead.AddRef(); // ours
	}

	/// Before the import changes the importer's model, or another importer frees it: the cook stops
	/// at its next item, and is waited for. It then never opens.
	public void StopReading()
	{
		if ((mRead != null) && (mPool != null))
		{
			mRead.Cancel();
			mPool.Wait(mRead);
		}
	}

	private void Arrived(Read result)
	{
		if (result.Outcome != .Opened)
		{
			Failed(result.Outcome);
			return;
		}
		if (mImported == null)
		{
			result.AddRef(); // the model it read itself, for a texture's picture
			mOwnRead = result;
		}
		let stats = result.Stats;
		result.Stats = null; // Bind takes it
		let bound = mOpen.Bind(result.Guid, stats);
		if (bound == .Loading)
			ShowLoading();
		else if (bound == .Opened)
			Opened();
		else
			Failed(bound);
	}

	/// While its parts load: how many are in.
	private void ShowLoading()
	{
		let asked = mOpen.PartsAsked;
		let pending = mOpen.PartsPending;
		mMessage.Text = scope $"Loading {(asked > pending) ? (asked - pending) : 0} of {asked} parts...";
		mMessage.Displayed = true;
	}

	/// Once a frame while it loads: binds it when its parts are in.
	private void UpdateLoading()
	{
		if (!mOpen.IsLoading)
			return;
		let outcome = mOpen.Update();
		if (outcome == .Loading)
			ShowLoading();
		else if ((outcome == .Opened) || (outcome == .FromCache))
			Opened();
		else
			Failed(outcome);
	}

	/// Whether its parts are loading (it binds once they are in).
	public bool IsLoading => mOpen.IsLoading;

	/// Runs its pool and its loading to the end, as frames would, without a host (tests).
	public void FinishLoading()
	{
		for (int frame < 100000)
		{
			if (mPool != null)
				mPool.Finish();
			if (!mOpen.IsLoading)
				break;
			UpdateLoading();
		}
	}

	private void Failed(OpenModel.Outcome outcome)
	{
		switch (outcome)
		{
		case .LoadFailed: mMessage.Text = "The model loaders could not read this file.";
		case .NotFound: mMessage.Text = "This file is missing.";
		default: mMessage.Text = "This model did not cook for the preview; the Console says why.";
		}
		mMessage.Displayed = true;
		if (mOnChanged != null)
			mOnChanged();
	}

	private void Opened()
	{
		let stats = mOpen.Stats;
		mFacts.Add(new String()..AppendF("Meshes {}", stats.Meshes));
		mFacts.Add(new String()..AppendF("Triangles {}", stats.Triangles));
		mFacts.Add(new String()..AppendF("Materials {}", stats.Materials));
		mFacts.Add(new String()..AppendF("Textures {}", stats.Textures));
		if (stats.Bones > 0)
			mFacts.Add(new String()..AppendF("Bones {}", stats.Bones));
		if (!stats.Clips.IsEmpty)
			mFacts.Add(new String()..AppendF("Clips {}", stats.Clips.Count));
		for (let clip in stats.Clips)
		{
			mClipNames.Add(new String(clip));
			mClips.AddItem(clip);
		}
		mMessage.Text = "";
		mMessage.Displayed = false;
		Place();
		ShowClips();
		ShowAsImported();
		if (mShowsPart)
			ApplyPart();
		if (mOnChanged != null)
			mOnChanged();
	}

	/// Puts the bound model in the view, playing its first clip, framed.
	private void Place()
	{
		let level = (mViewport != null) ? mViewport.Scene : null;
		if ((level == null) || (mOpen.Model == null))
			return;
		ModelInstances.Instantiate(level, mOpen.Model, ImportPaths.FileNameOf(mPath), .(), mInstance);
		mPlayback = new ClipPlayback(level, mInstance.Root, mOpen.Model);
		mPlayback.SetLooping(true);
		MeasureBounds(level);
		Frame();
		mViewport.Camera.Advance(1000.0f); // there at once, with no glide on opening
	}

	private void MeasureBounds(Sedulous.Scene.Scene level)
	{
		mCenter = .Zero;
		mRadius = 1.0f;
		let meshes = level.GetSystem<MeshComponentManager>();
		if ((meshes == null) || !level.IsValid(mInstance.Root))
			return;
		var bounds = AABB.Empty();
		meshes.ForEach(scope [&] (component, entity) =>
			{
				let mesh = component.Mesh.Get;
				if ((mesh == null) || !mesh.Bounds.IsValid() || !Under(level, entity, mInstance.Root))
					return;
				bounds = Merge(bounds, TransformAABB(mesh.Bounds, level.ComposeWorldMatrix(entity)));
			});
		if (!bounds.IsValid())
			return;
		mCenter = (bounds.Min + bounds.Max) * 0.5f;
		mRadius = Math.Max(Length(bounds.Max - bounds.Min) * 0.5f, 0.01f);
	}

	/// The framing: the clip range follows the model, so a small prop and a large building are both
	/// in reach.
	private void Frame()
	{
		if (mViewport == null)
			return;
		let camera = mViewport.Camera;
		camera.NearZ = Math.Max(mRadius * 0.05f, 0.0001f);
		camera.FarZ = Math.Max(mRadius * 100.0f, 50.0f);
		mViewport.Frame(mCenter, mRadius);
	}

	private void ShowClips()
	{
		let any = !mClipNames.IsEmpty && (mPlayback != null) && mPlayback.HasClips;
		if (any)
			mClips.SelectedIndex = Math.Max(mPlayback.Selected, 0);
		mClips.Displayed = any;
		mPlay.Displayed = any;
		mSkeleton.Displayed = !mInstance.Skinned.IsEmpty;
		ShowPlay();
	}

	private void ShowPlay()
	{
		let playing = (mPlayback != null) && mPlayback.Playing;
		mPlay.Icon = playing ? "Editor/Icons/pause.svg" : "Editor/Icons/play.svg";
	}

	/// The skeleton: a line from each bone to its parent, in the current pose.
	private void DrawSkeleton()
	{
		if (!mSkeleton.Checked || (mViewport == null) || !mViewport.IsValid || mInstance.Skinned.IsEmpty || (mOpen.Model == null))
			return;
		let bones = mOpen.Model.Skeleton.Get;
		if (bones == null)
			return;
		let count = (int)bones.BoneCount;
		let player = (mPlayback != null) ? mPlayback.Player : null;
		Span<BoneTransform> poses = (player != null) ? player.GetFinalPoses() : default;
		if (poses.Length < count)
		{
			mBindPoses.Count = count;
			for (int b < count)
				mBindPoses[b] = bones.GetBone((int32)b).LocalBindPose;
			poses = mBindPoses;
		}
		let model = mViewport.Scene.ComposeWorldMatrix(mInstance.Skinned[0]);
		AnimationPreview.DrawSkeletonBones(mViewport.SceneDebugDraw, bones, poses, mBonePoses, model, mChosenBone, true); // over the mesh
	}

	/// The skeleton's bones in a tree, for its details: choosing one draws it apart, the bones on. A
	/// node with one reference, the caller's; null before the model is in, or with no bones.
	private Node BoneView()
	{
		let bones = (mOpen.Model != null) ? mOpen.Model.Skeleton.Get : null;
		if ((bones == null) || (bones.BoneCount == 0))
			return null;
		DropBoneTree(); // the one shown before, in a detail gone or going
		if (mBoneModel == null)
			mBoneModel = new TreeModel();
		AnimationPreview.FillBoneTree(mBoneModel, mBoneRows, bones);
		let panel = new Sedulous.GUI.Panel();
		panel.AddClass("import-part-view");
		let heading = new Sedulous.GUI.Label();
		heading.Text = "Its bones";
		heading.AddClass("import-part-kind");
		let tree = new TreeView();
		tree.AddClasses("tree import-bone-tree");
		tree.Model = mBoneModel;
		for (int node < mBoneRows.Count)
			tree.SetIdExpanded((ItemId)node, true);
		for (int node < mBoneRows.Count)
		{
			if (mBoneRows[node] == mChosenBone)
			{
				ItemId[1] id = .((ItemId)node);
				tree.SetSelectedIds(id);
			}
		}
		tree.SetOnSelectionChanged(new [=this] (index) =>
			{
				let node = index.IsValid ? (int)index.InternalId : mBoneRows.Count;
				ChooseBone(((node >= 0) && (node < mBoneRows.Count)) ? mBoneRows[node] : -1);
			});
		tree.AddRef(); // ours
		mBoneTree = tree;
		Add(panel, heading);
		Add(panel, tree);
		return panel;
	}

	/// The bone tree last shown lets go of the model and of this.
	private void DropBoneTree()
	{
		if (mBoneTree == null)
			return;
		mBoneTree.SetOnSelectionChanged(null);
		mBoneTree.Model = null;
		mBoneTree.ReleaseRef();
		mBoneTree = null;
	}

	/// The skeleton's bones in a tree; choosing one draws the bones with it apart.
	public Node PartView(ImportPlanEntry part) => (part.Kind == .Skeleton) ? BoneView() : null;

	/// The bone chosen in the skeleton's tree (-1: none).
	public int32 ChosenBone => mChosenBone;

	/// Chooses `bone` as the tree does: drawn apart, the bones turned on to see it.
	public void ChooseBone(int32 bone)
	{
		mChosenBone = bone;
		if ((bone >= 0) && !mSkeleton.Checked)
		{
			mSkeleton.Checked = true; // to see it
			mBonesByPart = true;
		}
	}

	/// A part alone: a mesh by itself, a material on a sphere, the skeleton's bones over the model, a
	/// clip playing on it, a texture's picture in place of the model. False for a collision shape (the
	/// preview's cook makes none), and for a texture when the model was not read here (bound from the
	/// preview's cache). Asked before the model is in, it is shown once it is.
	public bool ShowPart(ImportPlanEntry part)
	{
		if (part.Kind == .Texture)
		{
			// Its picture, from the model as read: shown now, or not at all (nothing read here).
			ShowWholeModel();
			mShowsPart = ShowTexture(part.SourceName);
			if (mShowsPart)
			{
				mPartKind = part.Kind;
				mPartName.Set(part.SourceName);
			}
			return mShowsPart;
		}
		if ((part.Kind != .Mesh) && (part.Kind != .Material) && (part.Kind != .Skeleton) && (part.Kind != .AnimationClip))
		{
			ShowWhole();
			return false; // a collision shape: the preview's cook makes none, so the whole model stays
		}
		mPartKind = part.Kind;
		mPartName.Set(part.SourceName);
		mShowsPart = true;
		ApplyPart(); // or once the model is in (Opened)
		return true;
	}

	public void ShowWhole()
	{
		mShowsPart = false;
		ShowWholeModel();
	}

	/// Draws the model as the import will make it, from the file's settings and the plan as the
	/// review stands (the settings' selection): a material left out (all of them, or one) draws the
	/// default material, and a texture left out (all, or one) is drawn without, on a copy of each
	/// material that uses it, the bound materials untouched. Undone and done again on each change.
	private void ShowAsImported()
	{
		let level = (mViewport != null) ? mViewport.Scene : null;
		let meshes = (level != null) ? level.GetSystem<MeshComponentManager>() : null;
		if (meshes != null)
		{
			for (let kept in mKeptMaterials)
			{
				let component = meshes.Get(kept.Entity);
				if (component != null)
				{
					component.Materials.Clear();
					for (let reference in kept.Materials)
						component.Materials.Add(reference);
					component.MaterialCache.Clear();
				}
			}
		}
		ForgetKeptMaterials();
		for (let made in mStripped)
		{
			if (made.Copy != null)
				mRetired.Add(made.Copy);
		}
		mStripped.Clear();
		mDefaultMaterial = false;
		mWithoutTextures = false;
		let model = mOptions as ModelImportOptions;
		if ((model == null) || !mOpen.IsOpen)
			return;
		let allMaterials = !model.ImportMaterials;
		let allTextures = !model.ImportTextures;
		let droppedMaterials = scope List<Object>();
		let droppedTextures = scope List<ITextureView>();
		int texturesFound = 0; // left out and found, drawn on the GPU or not (a test has no device)
		for (let entry in model.Selection.Entries)
		{
			if (entry.Enabled)
				continue;
			if (entry.Kind == .Material)
			{
				if (let found = mOpen.FindPart(entry.SourceName, typeof(Sedulous.Materials.Material)))
					droppedMaterials.Add(found.Product);
			}
			else if (entry.Kind == .Texture)
			{
				if (let found = mOpen.FindPart(entry.SourceName, typeof(Sedulous.Texture.Resource.Texture)))
				{
					texturesFound++;
					let texture = found.Product as Sedulous.Texture.Resource.Texture;
					if ((texture != null) && (texture.View != null))
						droppedTextures.Add(texture.View);
				}
			}
		}
		if (!allMaterials && !allTextures && droppedMaterials.IsEmpty && (texturesFound == 0))
			return;
		if ((meshes == null) || !level.IsValid(mInstance.Root))
		{
			mDefaultMaterial = allMaterials || !droppedMaterials.IsEmpty; // no view (a test): what it would draw
			mWithoutTextures = !mDefaultMaterial && (allTextures || (texturesFound > 0));
			return;
		}
		if (mFallbackMaterial == null)
			mFallbackMaterial = Sedulous.Materials.MaterialPresets.CreatePbr("preview.default"); // as the renderer draws a mesh with none
		meshes.ForEach(scope [&] (component, entity) =>
			{
				if (!Under(level, entity, mInstance.Root))
					return;
				let drawn = scope List<Sedulous.Resource.Ref<Sedulous.Materials.Material>>();
				bool changed = false;
				for (let slot in component.Materials)
				{
					let material = slot.Get;
					if ((material != null) && (allMaterials || Holds(droppedMaterials, material)))
					{
						var reference = Sedulous.Resource.Ref<Sedulous.Materials.Material>(Guid());
						reference.SetDirect(mFallbackMaterial); // ours, borrowed
						drawn.Add(reference);
						mDefaultMaterial = changed = true;
						continue;
					}
					if ((material != null) && (allTextures || !droppedTextures.IsEmpty))
					{
						if (let without = Without(material, allTextures, droppedTextures))
						{
							var reference = Sedulous.Resource.Ref<Sedulous.Materials.Material>(Guid());
							reference.SetDirect(without); // ours, borrowed
							drawn.Add(reference);
							mWithoutTextures = changed = true;
							continue;
						}
					}
					drawn.Add(slot);
				}
				if (!changed)
					return;
				let own = new List<Sedulous.Resource.Ref<Sedulous.Materials.Material>>();
				for (let reference in component.Materials)
					own.Add(reference);
				mKeptMaterials.Add((entity, own));
				component.Materials.Clear();
				for (let reference in drawn)
					component.Materials.Add(reference);
				component.MaterialCache.Clear();
			});
	}

	/// Whether `list` holds `item`, by reference.
	private static bool Holds(List<Object> list, Object item)
	{
		for (let each in list)
		{
			if (each === item)
				return true;
		}
		return false;
	}

	/// `material` without the textures the import leaves out (every one when `all`), as a copy made
	/// once per change (ours); null when it uses none of them.
	private Sedulous.Materials.Material Without(Sedulous.Materials.Material material, bool all, List<ITextureView> dropped)
	{
		for (let made in mStripped)
		{
			if (made.From === material)
				return made.Copy;
		}
		Sedulous.Materials.Material copy = null;
		for (int i < material.PropertyCount)
		{
			let property = material.GetProperty(i);
			let texture = property.IsTexture ? material.GetDefaultTexture(i) : null;
			if (texture == null)
				continue;
			bool drop = all;
			for (let each in dropped)
				drop = drop || (each === texture);
			if (!drop)
				continue;
			if (copy == null)
				copy = material.Clone();
			copy.SetDefaultTexture(property.Name, null); // drawn with the renderer's plain fallback
		}
		mStripped.Add((material, copy));
		return copy;
	}

	private void ForgetKeptMaterials()
	{
		for (let kept in mKeptMaterials)
			delete kept.Materials;
		mKeptMaterials.Clear();
	}

	/// The model as read (the importer's, or the preview's own read), or null when neither is here
	/// (the model came from the preview's cache with nothing read).
	private Model ModelAsRead => (mImported != null) ? mImported : ((mOwnRead != null) ? mOwnRead.Model : null);

	/// The picture of texture part `name` (the plan's name for it), from the model as read: its
	/// decoded pixels, or the file beside the model it names. False when there is none to show.
	private bool ShowTexture(StringView name)
	{
		let model = ModelAsRead;
		if (model == null)
			return false;
		let textures = model.Textures;
		let textureName = scope String();
		for (int i < textures.Length)
		{
			let texture = textures[i];
			textureName.Clear();
			ImportedNames.ForTexture(texture, i, textureName);
			if (textureName != name)
				continue;
			Sedulous.Image.Image pixels = null;
			if (texture.HasEmbeddedData && (texture.Width > 0) && (texture.Height > 0)
				&& (texture.DataSize == (int)texture.Width * texture.Height * 4))
			{
				pixels = new .((uint32)texture.Width, (uint32)texture.Height, .RGBA8, texture.Data); // a copy
			}
			else if (!texture.SourceFile.IsEmpty)
			{
				let source = new Sedulous.Image.Image();
				if (!(ImageIO.LoadImage(texture.SourceFile, source) case .Ok) || (source.Width == 0))
				{
					delete source;
					return false;
				}
				if (source.Format == .RGBA8)
					pixels = source;
				else
				{
					pixels = source.ConvertFormat(.RGBA8);
					delete source;
				}
			}
			else
				return false;
			if (mPictureView == null)
			{
				mPictureView = ImageFilePreview.BuildImageView(); // one reference, ours
				mPicture = new ImagePreview(mPictureView);
				mRoot.AddChild(mPictureView);
			}
			mPicture.Show(pixels); // it takes them
			ShowPicture(true);
			return true;
		}
		return false;
	}

	/// The model's view, or a texture's picture in its place.
	private void ShowPicture(bool shown)
	{
		if (mPictureView != null)
			mPictureView.Displayed = shown;
		if (mBar != null)
			mBar.Displayed = !shown;
		if (mStage != null)
			mStage.Displayed = !shown;
	}

	/// Undoes what showing a part changed: every mesh drawn, the sphere gone, the bones as they were,
	/// the model's view in place of a picture.
	private void ShowWholeModel()
	{
		ShowPicture(false);
		let level = (mViewport != null) ? mViewport.Scene : null;
		if (level != null)
		{
			if (let meshes = level.GetSystem<MeshComponentManager>())
			{
				if (level.IsValid(mInstance.Root))
				{
					meshes.ForEach(scope [&] (component, entity) =>
						{
							if (Under(level, entity, mInstance.Root))
								component.Visible = true;
						});
				}
			}
			if (level.IsValid(mSphere))
				level.DestroyEntity(mSphere);
		}
		mSphere = .Invalid;
		if (mBonesByPart)
			mSkeleton.Checked = false;
		mBonesByPart = false;
	}

	/// Draws only the model's meshes `keep` says to.
	private void ShowMeshes(delegate bool(Sedulous.Geometry.StaticMesh mesh) keep)
	{
		let level = (mViewport != null) ? mViewport.Scene : null;
		let meshes = (level != null) ? level.GetSystem<MeshComponentManager>() : null;
		if ((meshes == null) || !level.IsValid(mInstance.Root))
			return;
		meshes.ForEach(scope [&] (component, entity) =>
			{
				if (Under(level, entity, mInstance.Root))
					component.Visible = keep(component.Mesh.Get);
			});
	}

	/// Shows the part asked for in place of the whole model, as far as the bound model has it.
	private void ApplyPart()
	{
		ShowWholeModel();
		let level = (mViewport != null) ? mViewport.Scene : null;
		if (!mOpen.IsOpen)
			return;
		switch (mPartKind)
		{
		case .Mesh:
			if (let found = mOpen.FindPart(mPartName, typeof(Sedulous.Geometry.StaticMesh)))
			{
				let mesh = found.Product;
				ShowMeshes(scope (drawn) => (Object)drawn === mesh);
				if (mPlayback != null)
					mPlayback.SetPlaying(false); // still, as it is
				ShowPlay();
			}
		case .Material:
			if (let found = mOpen.FindPart(mPartName, typeof(Sedulous.Materials.Material)))
			{
				let material = found.Product as Sedulous.Materials.Material;
				let meshes = (level != null) ? level.GetSystem<MeshComponentManager>() : null;
				if ((material == null) || (meshes == null))
					return;
				ShowMeshes(scope (drawn) => false);
				if (mSphereMesh == null)
					mSphereMesh = Sedulous.Geometry.Primitives.Sphere(0.5f, 48, 24);
				mSphere = level.CreateEntity("material.sphere");
				var at = Transform();
				at.Position = mCenter;
				at.Scale = .(mRadius * 1.2f, mRadius * 1.2f, mRadius * 1.2f); // about the model's size, so the framing holds
				level.SetLocalTransform(mSphere, at);
				let drawn = meshes.Add(mSphere);
				drawn.Mesh.SetDirect(mSphereMesh); // runtime built, not an asset
				drawn.SetMaterial(material); // the cache's, borrowed
			}
		case .Skeleton:
			if (!mInstance.Skinned.IsEmpty && !mSkeleton.Checked)
			{
				mSkeleton.Checked = true;
				mBonesByPart = true;
			}
		case .Texture:
			ShowTexture(mPartName);
		case .AnimationClip:
			let name = scope String();
			for (int a < mClipNames.Count)
			{
				name.Clear();
				ImportedNames.ForAsset(mClipNames[a], "anim", a, name);
				if (name != mPartName)
					continue;
				if (mPlayback != null)
				{
					mPlayback.Select((int32)a);
					mPlayback.SetPlaying(true);
				}
				mClips.SelectedIndex = (int32)a;
				ShowPlay();
				break;
			}
		default:
		}
	}

	/// Whether `entity` is `root` or under it.
	private static bool Under(Sedulous.Scene.Scene level, EntityHandle entity, EntityHandle root)
	{
		for (var e = entity; level.IsValid(e); e = level.GetParent(e))
		{
			if (e == root)
				return true;
		}
		return false;
	}

	/// A tool button of `icon`, said by `tooltip`: a node with one reference, the caller's.
	private static ToolButton Tool(StringView icon, StringView tooltip)
	{
		let button = new ToolButton();
		button.Icon = icon;
		button.Tooltip = tooltip;
		return button;
	}

	/// `child` into `into`, whose reference keeps it: the caller's one goes.
	private static void Add(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}
}

/// Previews the model files an importer lists by one asset type, cooking each into a folder under
/// the open project's cache.
class ModelFilePreviewFactory : IImportPreviewFactory
{
	private Type mType;
	/// BORROWED: the editor's (or a test's), which outlive it.
	private EditorContext mContext;
	private AssetPageServicesSource mServices;

	public this(Type type, EditorContext context, AssetPageServicesSource services)
	{
		mType = type;
		mContext = context;
		mServices = services;
	}

	public Type AssetType => mType;

	public IImportPreview Create(ImportPreviewSource file, TaskPool tasks)
	{
		if (mContext.Project == null)
			return null;
		let cacheRoot = PathJoin(mContext.Project.CacheRoot(.. scope .()), ModelFilePreview.cCacheFolder, .. scope .());
		CreateDirectory(mContext.Project.CacheRoot(.. scope .()));
		CreateDirectory(cacheRoot);
		let services = (mServices != null) ? mServices.Make() : new AssetPageServices();
		defer delete services;
		let loaded = file.Prepared as LoadedModel;
		return new ModelFilePreview(file.Path, cacheRoot, tasks, services, (loaded != null) ? loaded.Model : null, file.Options);
	}

	/// Registers the model preview for the files the model importer lists (its manifests).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		context.ImportPreviews.Register(new ModelFilePreviewFactory(typeof(ModelManifestAsset), context, services));
	}
}
