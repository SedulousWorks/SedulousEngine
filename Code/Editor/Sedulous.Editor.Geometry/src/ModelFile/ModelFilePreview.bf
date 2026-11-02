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
using Sedulous.Pipeline.Importer;
using Sedulous.ModelImporter;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;
using Sedulous.Editor.ModelPreview;

namespace Sedulous.Editor.Geometry;

// The import window's preview of a model file (Raptor's import-window spec, W4): the model live in
// a PreviewViewport (orbit, zoom, Frame), with its clips (a picker, play and pause) and its skeleton
// drawn over it on request; and the facts the file gives (meshes, triangles, materials, textures,
// bones, clips). It opens through Editor.ModelPreview's OpenModel into a cache folder under the
// project's cache: a model opened before binds from there, and one that must be read is read on the
// ImportPreviewReader's worker, then cooked and bound on the main thread, which owns the resources.
// Without a host (a test) there is no view, but the model still opens and its facts show. The window
// drives it each frame (IImportPreviewFrames).

class ModelFilePreview : IImportPreview, IImportPreviewFrames
{
	/// Where the import window's model previews cook, under a project's cache folder.
	public const String cCacheFolder = "ModelPreviews";

	/// What the worker reads, for the main thread to cook and bind: nothing else touches it until
	/// it is back.
	private class Read : RefCounted
	{
		public Model Model = new .() ~ delete _;
		/// Handed to OpenModel.Finish, which takes it.
		public ModelStats Stats = new .() ~ delete _;
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
	/// The read it started, cancelled as it goes: a reference of ours.
	private ImportPreviewRead mRead = null;
	private delegate void() mOnChanged ~ delete _;

	/// Opens `path` with its cooked files under `cacheRoot`: bound at once when opened before, else
	/// read on `reader` (borrowed: it outlives this). `services` give the host and GUI the view
	/// needs (no host: no view); borrowed.
	public this(StringView path, StringView cacheRoot, ImportPreviewReader reader, AssetPageServices services)
	{
		mPath.Set(path);
		BuildView(services);
		Start(cacheRoot, reader);
	}

	public ~this()
	{
		if (mRead != null)
		{
			mRead.Cancel();
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
		if (mOpen.Resources != null)
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
	/// The clips the picker lists, by name.
	public Span<String> Clips => mClipNames;

	private void BuildView(AssetPageServices services)
	{
		let panel = new Sedulous.GUI.Panel();
		panel.AddClass("import-model");
		let bar = new Sedulous.GUI.Panel();
		bar.AddClass("panel-toolbar");
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

	private void Start(StringView cacheRoot, ImportPreviewReader reader)
	{
		mMessage.Text = scope $"Reading {ImportPaths.FileNameOf(mPath)}...";
		let begun = mOpen.Begin(mPath, cacheRoot, mDevice, let outcome);
		if (begun == .Bound)
		{
			Opened();
			return;
		}
		if (begun == .Failed)
		{
			Failed(outcome);
			return;
		}
		let result = new Read(); // the done's reference
		result.AddRef(); // the read's
		let file = new String(mPath);
		mRead = reader.Read(
			// On the worker: only the file and `result` (LoadFile makes its own loaders).
			new [=file, =result] () => { result.Outcome = OpenModel.LoadFile(file, true, result.Model, result.Stats); }
				~ { delete file; result.ReleaseRef(); },
			// On the main thread, which owns the cache's database and resources, and only while this
			// preview lives (it cancels the read as it goes).
			new [=this, =result] () => { Arrived(result); } ~ { result.ReleaseRef(); });
	}

	private void Arrived(Read result)
	{
		if (result.Outcome != .Opened)
		{
			Failed(result.Outcome);
			return;
		}
		let stats = result.Stats;
		result.Stats = null; // Finish takes it
		let finished = mOpen.Finish(result.Model, stats);
		if (finished == .Opened)
			Opened();
		else
			Failed(finished);
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
		let player = (mPlayback != null) ? mPlayback.Player : null;
		let bones = mOpen.Model.Skeleton.Get;
		if (bones == null)
			return;
		let count = (int)bones.BoneCount;
		mBonePoses.Count = count;
		bones.ComputeWorldPoses((player != null) ? player.GetFinalPoses() : default, mBonePoses);
		let model = mViewport.Scene.ComposeWorldMatrix(mInstance.Skinned[0]);
		let color = Color(0.35f, 0.85f, 1.0f, 1.0f);
		let draw = mViewport.SceneDebugDraw;
		for (int i < count)
		{
			let parent = bones.GetBone((int32)i).ParentIndex;
			if ((parent < 0) || (parent >= count))
				continue;
			let a = mBonePoses[parent];
			let b = mBonePoses[i];
			draw.DrawLineOverlay(TransformPoint(.(a.M[3][0], a.M[3][1], a.M[3][2]), model),
				TransformPoint(.(b.M[3][0], b.M[3][1], b.M[3][2]), model), color);
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

	public IImportPreview Create(StringView path, ImportPreviewReader reader)
	{
		if (mContext.Project == null)
			return null;
		let cacheRoot = PathJoin(mContext.Project.CacheRoot(.. scope .()), ModelFilePreview.cCacheFolder, .. scope .());
		CreateDirectory(mContext.Project.CacheRoot(.. scope .()));
		CreateDirectory(cacheRoot);
		let services = (mServices != null) ? mServices.Make() : new AssetPageServices();
		defer delete services;
		return new ModelFilePreview(path, cacheRoot, reader, services);
	}

	/// Registers the model preview for the files the model importer lists (its manifests).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		context.ImportPreviews.Register(new ModelFilePreviewFactory(typeof(ModelManifestAsset), context, services));
	}
}
