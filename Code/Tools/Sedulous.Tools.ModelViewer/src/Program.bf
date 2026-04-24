namespace Sedulous.Tools.ModelViewer;

using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.UI;
using Sedulous.UI.Shell;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Textures;
using Sedulous.Textures.Resources;
using Sedulous.Resources;
using Sedulous.Images;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
using Sedulous.Models;
using Sedulous.Models.GLTF;
using Sedulous.Models.FBX;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Profiler;
using Sedulous.Serialization.OpenDDL;
using Sedulous.Renderer.Debug;

class ModelViewerApp : Application
{
	/// Files to load on startup (from command line args).
	public String[] InitialFiles;
	// UI -- deleted explicitly in OnShutdown in safe order
	private ShaderSystem mShaderSystem;
	private FontService mFontService ~ delete _;
	private VGContext mVGContext ~ delete _;
	private VGRenderer mVGRenderer;
	private UIContext mUIContext;
	private RootView mMainRoot;
	private UIInputHelper mInputHelper ~ delete _;
	private ShellClipboardAdapter mClipboard ~ delete _;

	// Runtime context (embedded engine for 3D rendering)
	private Context mRuntimeContext;
	private VGExternalTextureCache mExternalTextureCache = new .() ~ delete _;

	// Tabs
	private List<ModelTab> mTabs = new .() ~ DeleteContainerAndItems!(_);
	private int32 mActiveTabIndex = -1;
	private TabView mTabView;
	private Panel mViewportContainer; // Holds drop indicator or active tab's ContentPanel
	private Label mDropIndicator;

	// Info labels (updated when tab changes)
	private Label mNameLabel;
	private Label mMeshCountLabel;
	private Label mVertexCountLabel;
	private Label mTriangleCountLabel;
	private Label mMaterialCountLabel;
	private Label mBoneCountLabel;
	private Label mAnimCountLabel;


	// Sky texture (shared across tabs)
	private ITexture mSkyTexture;
	private ITextureView mSkyTextureView;

	protected override void OnInitialize(Context context)
	{
		SDLImageLoader.Initialize();
		STBImageLoader.Initialize();
		GltfModels.Initialize();
		FbxModels.Initialize();

		// Shader system
		mShaderSystem = new ShaderSystem();
		let shaderDir = scope String();
		GetAssetPath("shaders", shaderDir);
		let shaderCacheDir = scope String();
		GetAssetCachePath("shaders", shaderCacheDir);
		mShaderSystem.Initialize(Device, .(scope StringView[](shaderDir)), mSettings.EnableShaderCache ? shaderCacheDir : default);

		// Font service
		mFontService = new FontService();
		let fontPath = scope String();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);
		if (File.Exists(fontPath))
		{
			for (let size in float[](12, 14, 16, 18, 20))
				mFontService.LoadFont("Roboto", fontPath, .() { PixelHeight = size });
		}

		// VG renderer
		mVGContext = new VGContext(mFontService);
		mVGRenderer = new VGRenderer();
		mVGRenderer.Initialize(Device, SwapChain.Format, (int32)SwapChain.BufferCount, mShaderSystem);
		mVGRenderer.SetExternalCache(mExternalTextureCache);

		// Clipboard
		mClipboard = new ShellClipboardAdapter(Shell.Clipboard);

		// UI context
		Theme.RegisterExtension(new ToolkitThemeExtension());
		mUIContext = new UIContext();
		mUIContext.FontService = mFontService;
		mUIContext.Clipboard = mClipboard;
		mUIContext.SetTheme(DarkTheme.Create(), true);

		mMainRoot = new RootView();
		mUIContext.AddRootView(mMainRoot);

		// Input helper
		mInputHelper = new UIInputHelper();

		// Runtime context (embedded engine)
		mRuntimeContext = new Context();
		mRuntimeContext.RegisterSubsystem(new SceneSubsystem());

		let renderSub = new RenderSubsystem(ResourceSystem);
		renderSub.Device = Device;
		renderSub.Window = Window;
		renderSub.ShaderSystem = mShaderSystem;
		mRuntimeContext.RegisterSubsystem(renderSub);

		let animSub = new AnimationSubsystem(ResourceSystem);
		mRuntimeContext.RegisterSubsystem(animSub);

		mRuntimeContext.Startup();

		// Build UI
		BuildUI();

		// Load sky texture (shared by all tabs)
		LoadSkyTexture();

		// Load files from command line
		if (InitialFiles != null)
		{
			for (let file in InitialFiles)
				LoadModel(file);
		}
	}

	// ==================== UI ====================

	private void BuildUI()
	{
		let root = mMainRoot;

		// Main layout: tabs on top, split view below
		let mainLayout = new LinearLayout();
		mainLayout.Orientation = .Vertical;
		root.AddView(mainLayout, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		// Tab bar (closable tabs) - hidden until a model is loaded
		mTabView = new TabView();
		mTabView.TabHeight = 28;
		mTabView.TabFontSize = 12;
		mTabView.Visibility = .Gone;
		mTabView.OnTabChanged.Add(new (tv, idx) => OnTabChanged(idx));
		mTabView.OnTabCloseRequested.Add(new (tv, idx) => CloseTab(idx));
		mainLayout.AddView(mTabView, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });

		// Split view: viewport container (left) + side panel (right)
		let splitView = new SplitView(.Horizontal);
		splitView.SplitRatio = 0.75f;

		// Viewport container: holds drop indicator or active tab's ContentPanel
		mViewportContainer = new Panel();

		mDropIndicator = new Label();
		mDropIndicator.SetText("Drop a model here\n\nSupported: glTF, GLB, OBJ, FBX");
		mDropIndicator.FontSize = 20;
		mDropIndicator.TextColor = .(150, 150, 160);
		mDropIndicator.HAlign = .Center;
		mDropIndicator.VAlign = .Middle;
		mDropIndicator.WordWrap = true;
		mViewportContainer.AddView(mDropIndicator, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		// Side panel
		let sidePanel = BuildSidePanel();

		splitView.SetPanes(mViewportContainer, sidePanel);
		mainLayout.AddView(splitView, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Weight = 1 });
	}

	private ScrollView BuildSidePanel()
	{
		let scroll = new ScrollView();
		scroll.VScrollPolicy = .Auto;
		scroll.HScrollPolicy = .Never;

		let panel = new LinearLayout();
		panel.Orientation = .Vertical;
		panel.Padding = .(10);
		panel.Spacing = 6;

		// Title
		let title = new Label();
		title.SetText("Model Viewer");
		title.FontSize = 18;
		panel.AddView(title);

		// Separator
		panel.AddView(new Separator());

		// Model info
		AddInfoRow(panel, "Name:", out mNameLabel);
		AddInfoRow(panel, "Meshes:", out mMeshCountLabel);
		AddInfoRow(panel, "Vertices:", out mVertexCountLabel);
		AddInfoRow(panel, "Triangles:", out mTriangleCountLabel);
		AddInfoRow(panel, "Materials:", out mMaterialCountLabel);
		AddInfoRow(panel, "Bones:", out mBoneCountLabel);
		AddInfoRow(panel, "Animations:", out mAnimCountLabel);

		panel.AddView(new Separator());

		// Help text
		let help = new Label();
		help.SetText("Controls:\nLMB: Orbit\nRMB: Fly Look\nWASD: Move\nMMB: Pan\nScroll: Zoom\nR: Focus Model\n\nDrop .gltf/.glb files to load models.");
		help.FontSize = 12;
		help.TextColor = .(150, 150, 160);
		help.WordWrap = true;
		panel.AddView(help, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });

		scroll.AddView(panel, new LayoutParams() { Width = LayoutParams.MatchParent });
		return scroll;
	}

	private void AddInfoRow(LinearLayout parent, StringView label, out Label valueLabel)
	{
		let row = new LinearLayout();
		row.Orientation = .Horizontal;
		row.Spacing = 8;

		let lbl = new Label();
		lbl.SetText(label);
		lbl.FontSize = 12;
		lbl.TextColor = .(180, 180, 190);
		row.AddView(lbl, new LinearLayout.LayoutParams() { Width = 75 });

		valueLabel = new Label();
		valueLabel.SetText("-");
		valueLabel.FontSize = 12;
		row.AddView(valueLabel, new LinearLayout.LayoutParams() { Weight = 1 });

		parent.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });
	}

	/// Builds the per-tab content panel: top toolbar + viewport + animation toolbar.
	private void BuildTabContent(ModelTab tab)
	{
		let content = new LinearLayout();
		content.Orientation = .Vertical;
		tab.ContentPanel = content;

		// Top toolbar
		let topBar = BuildTopToolbar(tab);
		content.AddView(topBar, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });

		// Viewport
		let viewport = new ViewportView();
		viewport.Initialize(Device, mVGRenderer);
		viewport.OnRender.Add(new (vp, encoder, frameIndex) => {
			RenderTabViewport(tab, vp, encoder, frameIndex);
		});
		tab.Viewport = viewport;
		content.AddView(viewport, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Weight = 1 });

		// Animation toolbar (skinned only)
		if (tab.IsSkinned && tab.AnimClipResources.Count > 0)
		{
			let animBar = BuildAnimToolbar(tab);
			content.AddView(animBar, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });
		}
	}

	private LinearLayout BuildTopToolbar(ModelTab tab)
	{
		let bar = new LinearLayout();
		bar.Orientation = .Horizontal;
		bar.Spacing = 8;
		bar.Padding = .(8, 4, 8, 4);

		// Bounding box toggle
		let boundsCheck = new CheckBox();
		boundsCheck.SetText("Bounds");
		boundsCheck.IsChecked = tab.ShowBoundingBox;
		boundsCheck.FontSize = 12;
		boundsCheck.OnCheckedChanged.Add(new (cb, val) => { if (ActiveTab != null) ActiveTab.ShowBoundingBox = val; });
		bar.AddView(boundsCheck, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		// Grid toggle
		let gridCheck = new CheckBox();
		gridCheck.SetText("Grid");
		gridCheck.IsChecked = tab.ShowGrid;
		gridCheck.FontSize = 12;
		gridCheck.OnCheckedChanged.Add(new (cb, val) => { if (ActiveTab != null) ActiveTab.ShowGrid = val; });
		bar.AddView(gridCheck, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		// Skeleton toggle (visible for skinned models)
		if (tab.IsSkinned)
		{
			let skelCheck = new CheckBox();
			skelCheck.SetText("Skeleton");
			skelCheck.IsChecked = tab.ShowSkeleton;
			skelCheck.FontSize = 12;
			skelCheck.OnCheckedChanged.Add(new (cb, val) => { if (ActiveTab != null) ActiveTab.ShowSkeleton = val; });
			bar.AddView(skelCheck, new LinearLayout.LayoutParams() { Gravity = .CenterV });
		}

		// Focus button
		let focusBtn = new Button();
		focusBtn.Text = new .("Focus");
		focusBtn.Padding = .(8, 4, 8, 4);
		focusBtn.FontSize = 12;
		focusBtn.OnClick.Add(new (btn) => { let t = ActiveTab; t?.CameraController?.FitToBounds(t.Bounds); });
		bar.AddView(focusBtn, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		// Scale label + slider + value
		let scaleTitle = new Label();
		scaleTitle.SetText("Scale:");
		scaleTitle.FontSize = 12;
		bar.AddView(scaleTitle, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		let scaleSlider = new Slider();
		scaleSlider.Min = 0.1f;
		scaleSlider.Max = 10.0f;
		scaleSlider.Value = tab.ModelScale;
		scaleSlider.Step = 0.1f;
		scaleSlider.OnValueChanged.Add(new (s, v) => OnScaleChanged(v));
		bar.AddView(scaleSlider, new LinearLayout.LayoutParams() { Width = 120, Gravity = .CenterV });

		let scaleLabel = new Label();
		scaleLabel.SetText("1.0x");
		scaleLabel.FontSize = 12;
		bar.AddView(scaleLabel, new LinearLayout.LayoutParams() { Width = 40, Gravity = .CenterV });
		tab.ScaleValueLabel = scaleLabel;

		// Exposure slider
		let expTitle = new Label();
		expTitle.SetText("Exp:");
		expTitle.FontSize = 12;
		bar.AddView(expTitle, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		let expSlider = new Slider();
		expSlider.Min = 0.1f;
		expSlider.Max = 3.0f;
		expSlider.Value = tab.Exposure;
		expSlider.Step = 0.1f;
		expSlider.OnValueChanged.Add(new (s, v) => OnExposureChanged(v));
		bar.AddView(expSlider, new LinearLayout.LayoutParams() { Width = 80, Gravity = .CenterV });

		// Ambient slider
		let ambTitle = new Label();
		ambTitle.SetText("Amb:");
		ambTitle.FontSize = 12;
		bar.AddView(ambTitle, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		let ambSlider = new Slider();
		ambSlider.Min = 0.0f;
		ambSlider.Max = 1.0f;
		ambSlider.Value = tab.AmbientIntensity;
		ambSlider.Step = 0.05f;
		ambSlider.OnValueChanged.Add(new (s, v) => OnAmbientChanged(v));
		bar.AddView(ambSlider, new LinearLayout.LayoutParams() { Width = 80, Gravity = .CenterV });

		return bar;
	}

	private LinearLayout BuildAnimToolbar(ModelTab tab)
	{
		let bar = new LinearLayout();
		bar.Orientation = .Horizontal;
		bar.Spacing = 6;
		bar.Padding = .(8, 4, 8, 4);

		// Animation clip selector
		let animLabel = new Label();
		animLabel.SetText("Animation:");
		animLabel.FontSize = 12;
		bar.AddView(animLabel, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		let comboBox = new ComboBox();
		comboBox.FontSize = 12;
		comboBox.OnSelectionChanged.Add(new (cb, idx) => OnAnimClipChanged(idx));
		bar.AddView(comboBox, new LinearLayout.LayoutParams() { Width = 120, Gravity = .CenterV });
		tab.AnimComboBox = comboBox;

		// Populate clips
		for (let name in tab.AnimClipNames)
			comboBox.AddItem(name);
		if (tab.CurrentAnimIndex >= 0)
			comboBox.SelectedIndex = tab.CurrentAnimIndex;

		// Play/Pause
		let playPauseBtn = new Button();
		playPauseBtn.Text = new .(tab.AnimPlaying ? "Pause" : "Play");
		playPauseBtn.Padding = .(8, 4, 8, 4);
		playPauseBtn.FontSize = 12;
		playPauseBtn.OnClick.Add(new (btn) => OnPlayPause());
		bar.AddView(playPauseBtn, new LinearLayout.LayoutParams() { Gravity = .CenterV });
		tab.PlayPauseBtn = playPauseBtn;

		// Stop
		let stopBtn = new Button();
		stopBtn.Text = new .("Stop");
		stopBtn.Padding = .(8, 4, 8, 4);
		stopBtn.FontSize = 12;
		stopBtn.OnClick.Add(new (btn) => OnStop());
		bar.AddView(stopBtn, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		// Step back
		let stepBackBtn = new Button();
		stepBackBtn.Text = new .("<");
		stepBackBtn.Padding = .(6, 4, 6, 4);
		stepBackBtn.FontSize = 12;
		stepBackBtn.OnClick.Add(new (btn) => OnStep(-1.0f / 30.0f));
		bar.AddView(stepBackBtn, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		// Step forward
		let stepFwdBtn = new Button();
		stepFwdBtn.Text = new .(">");
		stepFwdBtn.Padding = .(6, 4, 6, 4);
		stepFwdBtn.FontSize = 12;
		stepFwdBtn.OnClick.Add(new (btn) => OnStep(1.0f / 30.0f));
		bar.AddView(stepFwdBtn, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		// Loop checkbox
		let loopCheck = new CheckBox();
		loopCheck.SetText("Loop");
		loopCheck.IsChecked = tab.AnimLoop;
		loopCheck.FontSize = 12;
		loopCheck.OnCheckedChanged.Add(new (cb, val) => OnLoopChanged(val));
		bar.AddView(loopCheck, new LinearLayout.LayoutParams() { Gravity = .CenterV });

		return bar;
	}

	// ==================== Animation Controls ====================

	private SkeletalAnimationComponent GetAnimComponent(ModelTab tab)
	{
		if (tab == null || !tab.IsSkinned || tab.Scene == null || tab.ModelEntity == .Invalid) return null;
		let mgr = tab.Scene.GetModule<SkeletalAnimationComponentManager>();
		if (mgr == null) return null;
		for (let comp in mgr.ActiveComponents)
			if (comp.Owner == tab.ModelEntity)
				return comp;
		return null;
	}

	private void OnPlayPause()
	{
		let tab = ActiveTab;
		let anim = GetAnimComponent(tab);
		if (anim == null) return;

		tab.AnimPlaying = !tab.AnimPlaying;
		anim.Playing = tab.AnimPlaying;
		anim.Speed = tab.AnimPlaying ? 1.0f : 0.0f;
		if (tab.PlayPauseBtn != null)
		{
			tab.PlayPauseBtn.Text.Set(tab.AnimPlaying ? "Pause" : "Play");
			tab.PlayPauseBtn.InvalidateLayout();
		}
	}

	private void OnStop()
	{
		let tab = ActiveTab;
		let anim = GetAnimComponent(tab);
		if (anim == null) return;

		tab.AnimPlaying = false;
		anim.Playing = false;
		anim.Speed = 0;
		if (anim.Player != null)
			anim.Player.CurrentTime = 0;
		if (tab.PlayPauseBtn != null)
		{
			tab.PlayPauseBtn.Text.Set("Play");
			tab.PlayPauseBtn.InvalidateLayout();
		}
	}

	private void OnStep(float deltaSeconds)
	{
		let tab = ActiveTab;
		let anim = GetAnimComponent(tab);
		if (anim == null || anim.Player == null) return;

		tab.AnimPlaying = false;
		anim.Playing = false;
		anim.Speed = 0;
		anim.Player.CurrentTime = Math.Max(0, anim.Player.CurrentTime + deltaSeconds);
		if (tab.PlayPauseBtn != null)
		{
			tab.PlayPauseBtn.Text.Set("Play");
			tab.PlayPauseBtn.InvalidateLayout();
		}
	}

	private void OnLoopChanged(bool loop)
	{
		let tab = ActiveTab;
		if (tab == null) return;
		tab.AnimLoop = loop;
		let anim = GetAnimComponent(tab);
		if (anim != null)
			anim.Loop = loop;
	}

	private void OnAnimClipChanged(int index)
	{
		let tab = ActiveTab;
		if (tab == null || index < 0 || index >= tab.AnimClipResources.Count) return;

		tab.CurrentAnimIndex = (int32)index;
		let anim = GetAnimComponent(tab);
		if (anim != null)
		{
			// Update the ref for re-resolution
			var clipRef = ResourceRef(tab.AnimClipResources[index].Id, .());
			defer clipRef.Dispose();
			anim.SetClipRef(clipRef);

			// Clear CurrentClip to force re-resolution by the manager
			anim.CurrentClip = null;

			// If player already exists, load and play the new clip directly
			if (anim.Player != null)
			{
				if (ResourceSystem.LoadByRef<AnimationClipResource>(clipRef) case .Ok(var handle))
				{
					let clipRes = handle.Resource;
					if (clipRes?.Clip != null)
					{
						anim.CurrentClip = clipRes.Clip;
						anim.CurrentClip.IsLooping = tab.AnimLoop;
						anim.Player.Play(clipRes.Clip);
						anim.Playing = tab.AnimPlaying;
						anim.Speed = tab.AnimPlaying ? 1.0f : 0.0f;
					}
					handle.Release();
				}
			}
		}
	}


	// ==================== Model Loading ====================

	private ModelTab ActiveTab => (mActiveTabIndex >= 0 && mActiveTabIndex < mTabs.Count) ? mTabs[mActiveTabIndex] : null;

	public void LoadModel(StringView filePath)
	{
		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(filePath, model) != .Ok)
		{
			Console.WriteLine("ERROR: Could not load model: {}", filePath);
			return;
		}

		// Determine import options based on model content
		let hasSkins = model.Skins.Count > 0;
		let importOpts = hasSkins ? ModelImportOptions.SkinnedWithAnimations() : ModelImportOptions.StaticMeshOnly();

		// Set base path for texture resolution
		let basePath = scope String();
		System.IO.Path.GetDirectoryPath(filePath, basePath);
		importOpts.BasePath.Set(basePath);
		importOpts.ModelPath.Set(filePath);

		let importer = scope ModelImporter(importOpts);
		let importResult = importer.Import(model);
		defer delete importResult;

		if (importResult.StaticMeshes.Count == 0 && importResult.SkinnedMeshes.Count == 0)
		{
			Console.WriteLine("ERROR: No meshes found in: {}", filePath);
			return;
		}

		// Create tab
		let tab = new ModelTab();
		let fileName = scope String();
		System.IO.Path.GetFileName(filePath, fileName);
		tab.Name = new String(fileName);
		tab.IsSkinned = hasSkins && importResult.SkinnedMeshes.Count > 0;

		// Convert to resources with dedup
		let resResult = ResourceImportResult.ConvertFrom(importResult, tab.DedupContext, filePath);
		defer delete resResult;

		// Register new resources
		for (let texRes in resResult.Textures)
			ResourceSystem.AddResource<TextureResource>(texRes);
		for (let matRes in resResult.Materials)
			ResourceSystem.AddResource<MaterialResource>(matRes);
		resResult.Textures.Clear();
		resResult.Materials.Clear();

		// Create scene
		let sceneSub = mRuntimeContext.GetSubsystem<SceneSubsystem>();
		let scene = sceneSub.CreateScene(tab.Name);
		tab.Scene = scene;

		// Camera
		let camEntity = scene.CreateEntity("Camera");
		scene.SetLocalTransform(camEntity, .() { Position = .(0, 2, 5), Rotation = .Identity, Scale = .One });
		let camMgr = scene.GetModule<CameraComponentManager>();
		let camHandle = camMgr.CreateComponent(camEntity);
		if (let cam = camMgr.Get(camHandle))
		{
			cam.FieldOfView = 45.0f;
			cam.NearPlane = 0.1f;
			cam.FarPlane = 1000.0f;
		}
		tab.CameraEntity = camEntity;

		// Directional light
		let lightEntity = scene.CreateEntity("Sun");
		scene.SetLocalTransform(lightEntity, Transform.CreateLookAt(.(5, 8, 5), .Zero));
		let lightMgr = scene.GetModule<LightComponentManager>();
		lightMgr.DebugDrawEnabled = false;
		let lightHandle = lightMgr.CreateComponent(lightEntity);
		if (let light = lightMgr.Get(lightHandle))
		{
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.85f);
			light.Intensity = 1.5f;
			light.CastsShadows = true;
			light.ShadowBias = 0.0005f;
			light.ShadowNormalBias = 3.0f;
		}

		// Fill point light
		let fillEntity = scene.CreateEntity("FillLight");
		scene.SetLocalTransform(fillEntity, .() { Position = .(0, 30, 30), Rotation = .Identity, Scale = .One });
		let fillHandle = lightMgr.CreateComponent(fillEntity);
		if (let fill = lightMgr.Get(fillHandle))
		{
			fill.Type = .Point;
			fill.Color = .(0.6f, 0.7f, 1.0f);
			fill.Intensity = 1.5f;
			fill.Range = 60.0f;
			fill.CastsShadows = false;
		}

		// Set up sky
		let renderSub = mRuntimeContext.GetSubsystem<RenderSubsystem>();
		if (mSkyTextureView != null)
		{
			if (let skyPass = renderSub.GetPipeline(scene)?.GetPass<SkyPass>())
			{
				skyPass.SkyTexture = mSkyTextureView;
				skyPass.Intensity = 1.0f;
			}
		}

		// Load mesh
		if (tab.IsSkinned)
			SetupSkinnedMesh(tab, importResult, resResult, scene);
		else
			SetupStaticMesh(tab, importResult, resResult, scene);

		// Add tab to UI
		mTabs.Add(tab);
		mActiveTabIndex = (int32)(mTabs.Count - 1);
		mTabView.AddTab(tab.Name, new Label(), true); // content unused, viewport is shared
		mTabView.SelectedIndex = mActiveTabIndex;

		// Build per-tab content (top toolbar + viewport + anim toolbar)
		BuildTabContent(tab);

		// Attach camera controller to this tab's viewport
		let camController = new ViewportCameraController(scene, mShell.InputManager.Keyboard);
		camController.FitToBounds(tab.Bounds);
		tab.CameraController = camController;
		camController.Attach(tab.Viewport);

		UpdateEmptyState();
		UpdateInfoLabels();

		Console.WriteLine("Loaded: {} ({} verts, {} tris, {} mats, {} bones, {} anims)",
			tab.Name, tab.VertexCount, tab.TriangleCount, tab.MaterialCount, tab.BoneCount, tab.AnimationCount);
	}

	private void SetupStaticMesh(ModelTab tab, ModelImportResult importResult,
		ResourceImportResult resResult, Scene scene)
	{
		if (importResult.StaticMeshes.Count == 0) return;

		let staticMesh = importResult.StaticMeshes[0];
		let meshRes = new StaticMeshResource(staticMesh, true);
		importResult.StaticMeshes[0] = null;
		meshRes.Name.Set(tab.Name);
		ResourceSystem.AddResource<StaticMeshResource>(meshRes);
		tab.MeshResource = meshRes;

		tab.Bounds = staticMesh.GetBounds();
		tab.MeshCount = 1;
		tab.VertexCount = (int32)staticMesh.VertexCount;
		tab.TriangleCount = (int32)(staticMesh.Indices != null ? staticMesh.Indices.IndexCount / 3 : 0);
		tab.MaterialCount = (int32)importResult.Materials.Count;

		var meshRef = ResourceRef(meshRes.Id, .());
		defer meshRef.Dispose();

		let modelEntity = scene.CreateEntity("Model");
		scene.SetLocalTransform(modelEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });
		tab.ModelEntity = modelEntity;

		let meshMgr = scene.GetModule<MeshComponentManager>();
		let compHandle = meshMgr.CreateComponent(modelEntity);
		if (let comp = meshMgr.Get(compHandle))
		{
			comp.SetMeshRef(meshRef);
			for (int32 slot = 0; slot < importResult.Materials.Count; slot++)
			{
				let matRes = tab.DedupContext.FindMaterial(importResult.Materials[slot].Name);
				if (matRes != null)
				{
					var matRef = ResourceRef(matRes.Id, matRes.Name);
					comp.SetMaterialRef(slot, matRef);
					matRef.Dispose();
				}
			}
		}
	}

	private void SetupSkinnedMesh(ModelTab tab, ModelImportResult importResult,
		ResourceImportResult resResult, Scene scene)
	{
		if (importResult.SkinnedMeshes.Count == 0) return;

		// Skeleton
		if (importResult.Skeletons.Count > 0)
		{
			let skeleton = importResult.Skeletons[0];
			importResult.Skeletons[0] = null;
			let skelRes = new SkeletonResource(skeleton, true);
			ResourceSystem.AddResource<SkeletonResource>(skelRes);
			tab.SkeletonRes = skelRes;
			tab.BoneCount = (int32)skeleton.BoneCount;
		}

		// Animation clips
		for (int i = 0; i < importResult.Animations.Count; i++)
		{
			let clip = importResult.Animations[i];
			importResult.Animations[i] = null;
			let clipRes = new AnimationClipResource(clip, true);
			ResourceSystem.AddResource<AnimationClipResource>(clipRes);
			tab.AnimClipResources.Add(clipRes);

			let clipName = new String();
			if (clip.Name != null && clip.Name.Length > 0)
				clipName.Set(clip.Name);
			else
				clipName.AppendF("Clip {}", i);
			tab.AnimClipNames.Add(clipName);
		}
		tab.AnimationCount = (int32)tab.AnimClipResources.Count;

		// Skinned mesh
		let skinnedMesh = importResult.SkinnedMeshes[0];
		importResult.SkinnedMeshes[0] = null;
		let meshRes = new SkinnedMeshResource(skinnedMesh, true);
		ResourceSystem.AddResource<SkinnedMeshResource>(meshRes);
		tab.SkinnedMeshRes = meshRes;

		tab.Bounds = skinnedMesh.Bounds;
		tab.MeshCount = 1;
		tab.VertexCount = (int32)skinnedMesh.VertexCount;
		tab.TriangleCount = (int32)(skinnedMesh.Indices != null ? skinnedMesh.Indices.IndexCount / 3 : 0);
		tab.MaterialCount = (int32)importResult.Materials.Count;

		var meshRef = ResourceRef(meshRes.Id, .());
		defer meshRef.Dispose();

		let modelEntity = scene.CreateEntity("Model");
		scene.SetLocalTransform(modelEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });
		tab.ModelEntity = modelEntity;

		// Skinned mesh component
		let skinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
		let compHandle = skinnedMgr.CreateComponent(modelEntity);
		if (let comp = skinnedMgr.Get(compHandle))
		{
			comp.SetMeshRef(meshRef);
			for (int32 slot = 0; slot < importResult.Materials.Count; slot++)
			{
				let matRes = tab.DedupContext.FindMaterial(importResult.Materials[slot].Name);
				if (matRes != null)
				{
					var matRef = ResourceRef(matRes.Id, matRes.Name);
					comp.SetMaterialRef(slot, matRef);
					matRef.Dispose();
				}
			}
		}

		// Skeletal animation component
		if (tab.SkeletonRes != null)
		{
			let skelAnimMgr = scene.GetModule<SkeletalAnimationComponentManager>();
			let animHandle = skelAnimMgr.CreateComponent(modelEntity);
			if (let animComp = skelAnimMgr.Get(animHandle))
			{
				var skelRef = ResourceRef(tab.SkeletonRes.Id, .());
				defer skelRef.Dispose();
				animComp.SetSkeletonRef(skelRef);

				if (tab.AnimClipResources.Count > 0)
				{
					var clipRef = ResourceRef(tab.AnimClipResources[0].Id, .());
					defer clipRef.Dispose();
					animComp.SetClipRef(clipRef);
					animComp.Loop = true;
					animComp.AutoPlay = true;
					tab.CurrentAnimIndex = 0;
					tab.AnimPlaying = true;
				}
			}
		}

	}

	// ==================== Sky ====================

	private void LoadSkyTexture()
	{
		let skyPath = scope String();
		GetAssetPath("textures/environment/BlueSky.hdr", skyPath);

		let device = Device;
		let queue = device.GetQueue(.Graphics);

		if (ImageLoaderFactory.LoadImage(skyPath) case .Ok(var image))
		{
			TextureDesc skyTexDesc = .()
			{
				Label = "Sky HDR", Width = image.Width, Height = image.Height, Depth = 1,
				Format = .RGBA32Float, Usage = .Sampled | .CopyDst,
				Dimension = .Texture2D, MipLevelCount = 1, ArrayLayerCount = 1, SampleCount = 1
			};

			if (device.CreateTexture(skyTexDesc) case .Ok(let tex))
			{
				mSkyTexture = tex;
				var layout = TextureDataLayout() { BytesPerRow = image.Width * 16, RowsPerImage = image.Height };
				var writeSize = Extent3D(image.Width, image.Height, 1);

				if (queue.CreateTransferBatch() case .Ok(let tb))
				{
					tb.WriteTexture(mSkyTexture, Span<uint8>(image.Data.Ptr, image.Data.Length), layout, writeSize);
					tb.Submit();
					device.WaitIdle();
					var tbRef = tb;
					queue.DestroyTransferBatch(ref tbRef);
				}

				if (device.CreateTextureView(mSkyTexture, .() { Format = .RGBA32Float, Dimension = .Texture2D }) case .Ok(let view))
					mSkyTextureView = view;
			}
			delete image;
		}
	}

	// ==================== Tab Management ====================

	private void OnTabChanged(int index)
	{
		// Detach old tab's content
		HideActiveTabContent();

		mActiveTabIndex = (int32)index;

		// Show new tab's content
		ShowActiveTabContent();
		UpdateInfoLabels();
	}

	private void CloseTab(int index)
	{
		if (index < 0 || index >= mTabs.Count) return;

		let tab = mTabs[index];

		// Detach content panel from container
		if (tab.ContentPanel?.Parent != null)
			mViewportContainer.DetachView(tab.ContentPanel);

		// Destroy scene
		let sceneSub = mRuntimeContext.GetSubsystem<SceneSubsystem>();
		if (tab.Scene != null)
			sceneSub.DestroyScene(tab.Scene);

		// Delete content panel (cascades to viewport, toolbars)
		if (tab.ContentPanel != null && tab.ContentPanel.Parent == null)
			delete tab.ContentPanel;
		tab.ContentPanel = null;
		tab.Viewport = null;

		tab.ReleaseRefs();
		delete tab.CameraController;
		mTabs.RemoveAt(index);
		delete tab;

		mTabView.RemoveTab(index);

		if (mActiveTabIndex >= mTabs.Count)
			mActiveTabIndex = (int32)(mTabs.Count - 1);
		if (mActiveTabIndex >= 0)
		{
			mTabView.SelectedIndex = mActiveTabIndex;
			OnTabChanged(mActiveTabIndex);
		}
		else
		{
			UpdateInfoLabels();
		}

		UpdateEmptyState();
	}

	private void UpdateEmptyState()
	{
		let hasModels = mTabs.Count > 0;

		// Show/hide tab bar
		mTabView.Visibility = hasModels ? .Visible : .Gone;

		if (hasModels)
		{
			mDropIndicator.Visibility = .Gone;
			ShowActiveTabContent();
		}
		else
		{
			// Detach any active tab's content
			HideActiveTabContent();
			mDropIndicator.Visibility = .Visible;
		}
	}

	private void ShowActiveTabContent()
	{
		let tab = ActiveTab;
		if (tab?.ContentPanel == null) return;

		if (tab.ContentPanel.Parent == null)
			mViewportContainer.AddView(tab.ContentPanel, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
	}

	private void HideActiveTabContent()
	{
		// Detach all tab content panels from the container
		for (let tab in mTabs)
		{
			if (tab.ContentPanel?.Parent == mViewportContainer)
				mViewportContainer.DetachView(tab.ContentPanel);
		}
	}

	private void UpdateInfoLabels()
	{
		let tab = ActiveTab;
		if (tab != null)
		{
			mNameLabel.SetText(tab.Name);
			SetIntLabel(mMeshCountLabel, tab.MeshCount);
			SetIntLabel(mVertexCountLabel, tab.VertexCount);
			SetIntLabel(mTriangleCountLabel, tab.TriangleCount);
			SetIntLabel(mMaterialCountLabel, tab.MaterialCount);
			SetIntLabel(mBoneCountLabel, tab.BoneCount);
			SetIntLabel(mAnimCountLabel, tab.AnimationCount);
		}
		else
		{
			mNameLabel.SetText("-");
			mMeshCountLabel.SetText("-");
			mVertexCountLabel.SetText("-");
			mTriangleCountLabel.SetText("-");
			mMaterialCountLabel.SetText("-");
			mBoneCountLabel.SetText("-");
			mAnimCountLabel.SetText("-");
		}
	}

	private void SetIntLabel(Label label, int32 value)
	{
		let text = scope String();
		text.AppendF("{}", value);
		label.SetText(text);
	}

	private void OnScaleChanged(float value)
	{
		let tab = ActiveTab;
		if (tab == null) return;
		tab.ModelScale = value;

		if (tab.ScaleValueLabel != null)
		{
			let text = scope String();
			text.AppendF("{0:F1}x", value);
			tab.ScaleValueLabel.SetText(text);
		}

		if (tab.ModelEntity != .Invalid && tab.Scene != null)
		{
			var transform = tab.Scene.GetLocalTransform(tab.ModelEntity);
			transform.Scale = .(value, value, value);
			tab.Scene.SetLocalTransform(tab.ModelEntity, transform);
			Console.WriteLine("Scale set to {0:F1} on entity {1} (skinned={2})", value, tab.ModelEntity.Index, tab.IsSkinned);
		}
		else
		{
			Console.WriteLine("Scale: entity invalid={}, scene null={}", tab.ModelEntity == .Invalid, tab.Scene == null);
		}
	}

	private void OnExposureChanged(float value)
	{
		let tab = ActiveTab;
		if (tab == null) return;
		tab.Exposure = value;

		let renderSub = mRuntimeContext.GetSubsystem<RenderSubsystem>();
		if (renderSub != null && tab.Scene != null)
		{
			let pipeline = renderSub.GetPipeline(tab.Scene);
			if (pipeline?.PostProcessStack != null)
			{
				let tonemap = pipeline.PostProcessStack.GetEffect<TonemapEffect>();
				if (tonemap != null)
					tonemap.Exposure = value;
			}
		}
	}

	private void OnAmbientChanged(float value)
	{
		let tab = ActiveTab;
		if (tab == null) return;
		tab.AmbientIntensity = value;

		let renderSub = mRuntimeContext.GetSubsystem<RenderSubsystem>();
		if (renderSub?.RenderContext?.LightBuffer != null)
			renderSub.RenderContext.LightBuffer.AmbientColor = .(value, value, value);
	}

	// ==================== Rendering ====================

	private void RenderTabViewport(ModelTab tab, ViewportView viewport, ICommandEncoder encoder, int32 frameIndex)
	{
		if (tab == null || tab.Scene == null) return;

		let renderSub = mRuntimeContext.GetSubsystem<RenderSubsystem>();
		if (renderSub == null) return;

		// Draw debug overlays
		if (let dbg = renderSub.RenderContext?.DebugDraw)
		{
			if (tab.ShowGrid)
				DrawGrid(dbg, tab);
			if (tab.ShowBoundingBox)
			{
				let s = tab.ModelScale;
				let scaledBounds = BoundingBox(tab.Bounds.Min * s, tab.Bounds.Max * s);
				dbg.DrawWireBox(scaledBounds, .(255, 200, 50));
			}
			if (tab.ShowSkeleton && tab.IsSkinned)
				DrawSkeleton(dbg, tab);
		}

		encoder.TransitionTexture(viewport.ColorTexture, .Undefined, .RenderTarget);

		renderSub.RenderScene(tab.Scene, encoder, viewport.ColorTexture, viewport.ColorTargetView,
			viewport.RenderWidth, viewport.RenderHeight, frameIndex);
	}

	private void DrawGrid(DebugDraw dbg, ModelTab tab)
	{
		//let extents = tab.Bounds.Max - tab.Bounds.Min;
		let s = tab.ModelScale;
		let extents = (tab.Bounds.Max - tab.Bounds.Min) * s;

		let maxExtent = Math.Max(extents.X, Math.Max(extents.Y, extents.Z));
		let gridSize = Math.Max(2.0f, Math.Ceiling(maxExtent * 1.5f));
		let gridColor = Color(80, 80, 80);
		let gridStep = Math.Max(0.5f, Math.Floor(gridSize / 10.0f));

		var x = -gridSize;
		while (x <= gridSize)
		{
			dbg.DrawLine(.(x, 0, -gridSize), .(x, 0, gridSize), gridColor);
			x += gridStep;
		}
		var z = -gridSize;
		while (z <= gridSize)
		{
			dbg.DrawLine(.(-gridSize, 0, z), .(gridSize, 0, z), gridColor);
			z += gridStep;
		}
	}

	private void DrawSkeleton(DebugDraw dbg, ModelTab tab)
	{
		let anim = GetAnimComponent(tab);
		if (anim == null || anim.Skeleton == null || anim.Player == null) return;

		let skeleton = anim.Skeleton;
		let localPoses = anim.Player.GetLocalPoses();
		if (localPoses.Length == 0) return;

		let boneCount = (int32)skeleton.Bones.Count;
		let worldPoses = scope Matrix[boneCount];
		skeleton.ComputeWorldPoses(localPoses, worldPoses);

		let s = tab.ModelScale;
		let boneColor = Color(255, 200, 100);
		let jointColor = Color(255, 100, 100);
		let jointSize = Math.Max(0.5f, s * 1.0f);

		for (int32 i = 0; i < boneCount; i++)
		{
			let bone = skeleton.Bones[i];
			if (bone == null) continue;

			let bonePos = worldPoses[i].Translation * s;
			dbg.DrawWireSphereOverlay(bonePos, jointSize, jointColor, 8);

			// Draw line to parent
			if (bone.ParentIndex >= 0 && bone.ParentIndex < boneCount)
			{
				let parentPos = worldPoses[bone.ParentIndex].Translation * s;
				dbg.DrawLineOverlay(parentPos, bonePos, boneColor);
			}
		}
	}

	// ==================== Frame Loop ====================

	protected override void OnInput(FrameContext frame)
	{
		if (mInputHelper != null && mUIContext != null)
		{
			mInputHelper.ProcessMouseInput(mShell.InputManager.Mouse, mUIContext);
			mInputHelper.ProcessKeyboardInput(mShell.InputManager.Keyboard, mUIContext, frame.DeltaTime);
		}
	}

	protected override void OnUpdate(FrameContext frame)
	{
		// UI frame first -- slider/button events update transforms before scene extraction
		mMainRoot.ViewportSize = .((float)Window.Width, (float)Window.Height);
		mUIContext.BeginFrame(frame.DeltaTime);
		mUIContext.UpdateRootView(mMainRoot);

		// Update camera controller
		let tab = ActiveTab;
		tab?.CameraController?.Update(frame.DeltaTime);

		// Focus model on R key
		if (mShell.InputManager.Keyboard.IsKeyPressed(.R) && tab != null)
			tab.CameraController?.FitToBounds(tab.Bounds);

		// Debug: print current camera state
		if (mShell.InputManager.Keyboard.IsKeyPressed(.O) && tab != null)
			tab.CameraController?.PrintState();

		// File drop
		let inputMgr = mShell.InputManager;
		for (int i = 0; i < inputMgr.DroppedFileCount; i++)
		{
			let file = inputMgr.GetDroppedFile(i);
			let ext = scope String();
			System.IO.Path.GetExtension(file, ext);
			ext.ToLower();
			if (ext == ".gltf" || ext == ".glb" || ext == ".obj" || ext == ".fbx")
				LoadModel(file);
		}

		// Update runtime context -- processes transforms set by UI/camera this frame
		mRuntimeContext.BeginFrame(frame.DeltaTime);
		mRuntimeContext.Update(frame.DeltaTime);
		mRuntimeContext.PostUpdate(frame.DeltaTime);
		mRuntimeContext.EndFrame();
	}

	protected override void OnPrepareFrame(FrameContext frame)
	{
		if (mVGContext == null || mVGRenderer == null) return;

		mVGContext.Clear();
		mUIContext.DrawRootView(mMainRoot, mVGContext);

		mVGRenderer.UpdateProjection(SwapChain.Width, SwapChain.Height, frame.FrameIndex);
		let batch = mVGContext.GetBatch();
		if (batch != null)
			mVGRenderer.Prepare(batch, frame.FrameIndex);
	}

	protected override bool OnRenderFrame(Sedulous.Runtime.Client.RenderContext render)
	{
		let encoder = render.Encoder;
		let frame = render.Frame;

		// Render 3D viewport before UI
		ActiveTab?.Viewport?.RenderContent(encoder, frame.FrameIndex);

		// UI render pass
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0.12f, 0.12f, 0.15f, 1)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);
		if (renderPass != null)
		{
			mVGRenderer.Render(renderPass, SwapChain.Width, SwapChain.Height, frame.FrameIndex);
			renderPass.End();
		}

		return true;
	}

	// ==================== Shutdown ====================

	protected override void OnShutdown()
	{
		// Clear sky references from all pipelines
		let renderSub = mRuntimeContext?.GetSubsystem<RenderSubsystem>();
		for (let tab in mTabs)
		{
			if (renderSub != null && tab.Scene != null)
			{
				if (let skyPass = renderSub.GetPipeline(tab.Scene)?.GetPass<SkyPass>())
					skyPass.SkyTexture = null;
			}
		}

		// Close all tabs
		let sceneSub = mRuntimeContext?.GetSubsystem<SceneSubsystem>();
		for (let tab in mTabs)
		{
			if (tab.ContentPanel?.Parent != null)
				mViewportContainer.DetachView(tab.ContentPanel);
			if (tab.Scene != null && sceneSub != null)
				sceneSub.DestroyScene(tab.Scene);
			if (tab.ContentPanel != null && tab.ContentPanel.Parent == null)
				delete tab.ContentPanel;
			tab.ContentPanel = null;
			tab.Viewport = null;
			tab.ReleaseRefs();
			delete tab.CameraController;
		}

		// Runtime context must be deleted before Device
		if (mRuntimeContext != null)
		{
			mRuntimeContext.Shutdown();
			delete mRuntimeContext;
			mRuntimeContext = null;
		}

		// Sky texture
		if (mSkyTextureView != null)
			Device.DestroyTextureView(ref mSkyTextureView);
		if (mSkyTexture != null)
			Device.DestroyTexture(ref mSkyTexture);

		// UI cleanup in safe order
		if (mUIContext != null)
		{
			mUIContext.RemoveRootView(mMainRoot);
			delete mUIContext;
			mUIContext = null;
		}

		delete mMainRoot;
		mMainRoot = null;

		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
			mVGRenderer = null;
		}

		mShaderSystem?.Dispose();
		delete mShaderSystem;
		mShaderSystem = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ModelViewerApp();
		app.InitialFiles = args;
		return app.Run(.()
		{
			Title = "Sedulous Model Viewer",
			Width = 1280, Height = 800,
			EnableShaderCache = true
		});
	}
}
