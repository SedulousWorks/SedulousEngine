using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Messaging;
using Sedulous.Shell;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Runtime;
using Sedulous.UI.Viewport;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.PropertyAnimation;

namespace Sedulous.Editor.Scene;

/// A scene or prefab open for editing: the hierarchy, the viewport with its toolbar and
/// tools, the inspector, the bottom dock with the animation panel and the tool panel, and
/// the camera preview. The scene lives in the page's own SceneManager, registered with the
/// scene subsystem so the engine's systems see it; simulation stays off until Simulate.
///
/// The context, host and UI host are borrowed; the page owns its edit context, tools, gizmo
/// registry and views, and releases its content view on destruction.
class SceneEditorPage : UIEditorPage
{
	/// Must match OnRenderWindow's projection.
	private const float cFovY = 1.0472f;

	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private SceneSubsystem mScenes = null;
	/// This page's OWN scene group.
	private SceneManager mSceneManager = new .() ~ delete _;
	/// The page's run scope bus, for edit mode Simulate.
	private EventBus mPageEvents = new .() ~ delete _;
	private RenderSubsystem mRender = null;
	private UISubsystem mGameUI = null;

	private String mTitle = new .() ~ delete _;
	/// Owned by the page's scene manager.
	private Sedulous.Scene.Scene mScene = null;
	private SceneEditContext mEditContext = null ~ delete _;
	/// [hierarchy | viewport | inspector] over the bottom dock.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private SceneHierarchyView mHierarchy = null;
	private SceneInspectorView mInspector = null;
	private Toolbar mToolbar = null;
	/// The viewport's ephemeral post flags and debug view; neither is serialized.
	private ViewPostOverride mPostOverride = .();
	private ViewDebugView mDebugView = new .() ~ delete _;

	private ToolbarButton mPlayButton = null;
	private ToolbarToggle mPauseToggle = null;
	private ToolbarButton mStopButton = null;
	private Label mSimLabel = null;
	private SceneSnapshot mSimSnapshot = null ~ delete _;
	private bool mIsSimulating = false;
	private bool mIsPaused = false;
	private ToolbarToggle mTranslateToggle = null;
	private ToolbarToggle mRotateToggle = null;
	private ToolbarToggle mScaleToggle = null;
	private ToolbarToggle mSpaceToggle = null;
	/// One dropdown over the editor's debug draws: grid, entity markers, LOD overlay and
	/// the edit time collider wireframes. Borrowed; the toolbar owns it.
	private ToolbarMenuButton mOverlaysButton = null;
	private SceneViewState mView = .();
	private List<(ToolbarToggle toggle, String id)> mToolToggles = new .() ~ { for (var t in _) delete t.id; delete _; };
	/// A category's dropdown over the tools registered under it.
	private List<ToolMenu> mToolMenus = new .() ~ DeleteContainerAndItems!(_);

	private ViewportToolManager mViewportTools = new .() ~ delete _;
	/// Borrowed; the manager owns the default tool.
	private SelectTransformTool mSelectTool = null;

	/// The GPU pick seam the tools see: the render subsystem's RequestPick keyed by THIS
	/// page's viewport, the same key its RenderScene call carries, hits decoded to entity
	/// handles.
	private class ViewportPicker : IViewportPicker
	{
		private SceneEditorPage mPage;
		private PickResult mResult = new .() ~ delete _;

		public this(SceneEditorPage page) { mPage = page; }

		public uint32 RequestPick(int32 x, int32 y, uint32 width, uint32 height)
		{
			let render = mPage.mRender;
			if ((render == null) || !render.IsReady || (mPage.mViewport == null))
				return 0;
			return render.RequestPick(Internal.UnsafeCastToPtr(mPage.mViewport), x, y, width, height);
		}

		public bool TryTakePick(uint32 request, List<EntityHandle> hits)
		{
			let render = mPage.mRender;
			if ((render == null) || !render.TryTakePickResult(request, mResult))
				return false;
			hits.Clear();
			for (let hit in mResult.Hits)
				hits.Add(.(hit.EntityIndex, hit.Generation));
			return true;
		}
	}
	private ViewportPicker mPicker = new .(this) ~ delete _;
	private GizmoRendererRegistry mComponentGizmos = new .() ~ delete _;

	/// The dock BORROWS a tab's content and takes a reference of its own, unlike AddView,
	/// so these two keep the page's reference and give it back in the destructor.
	private PropertyAnimationPanel mPropAnimPanel = null ~ { if (_ != null) _.ReleaseRef(); };
	private FlexLayout mToolPanelSlot = null ~ { if (_ != null) _.ReleaseRef(); };
	private Panel mToolOverlay = null;
	private AbsoluteLayout mToolFloatLayer = null;
	private FloatingPanel mToolFloat = null;
	private ViewportToolPanelHost mToolPanelHost = null ~ delete _;
	private BottomDock mBottomDock = null;
	private SplitView mViewportColumn = null;
	/// The clip open claim, removed on close.
	private uint64 mOpenAssetInterceptorId = 0;
	private ViewportView mViewport = null;

	private ViewportView mPreviewViewport = null;
	/// The overlay, gone when nothing is previewed.
	private View mPreviewContainer = null;
	private Button mPreviewPin = null;
	private EntityHandle mPinnedCamera = .Invalid;
	private EntityHandle mPreviewTarget = .Invalid;
	private const uint32 cPreviewHeight = 180;
	private InputRouter mRouter = null ~ delete _;
	private EditorCamera mCamera = new .() ~ delete _;
	/// Borrowed; tracks dock and float moves.
	private RenderWindow mHostWindow = null;
	private bool mRenderedOnce = false;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		mScenes = host.Context.GetSubsystem<SceneSubsystem>();
		mRender = host.Context.GetSubsystem<RenderSubsystem>();
		mGameUI = host.Context.GetSubsystem<UISubsystem>();

		if (mScenes != null)
		{
			mScenes.RegisterManager(mSceneManager);
			mSceneManager.SetSceneEventBus(mPageEvents);
			mScene = mSceneManager.CreateScene(instance.Name);
			mScene.SetSimulationEnabled(false); // edit mode is frozen; Simulate unfreezes
			LoadSceneContent(instance);
		}

		mViewport = new ViewportView();
		mViewport.ClearColor = .(0.10f, 0.11f, 0.13f, 1.0f);

		if (mScene != null)
		{
			mEditContext = new SceneEditContext(mScene, Commands);
			mEditContext.SetResources(context.Resources);
			mEditContext.SetPrefabResolver(GameEditorPage.ProjectPrefabResolver(context));
			mHierarchy = new SceneHierarchyView(mEditContext);
			mHierarchy.SetEditorContext(context);
			mHierarchy.OnCreatePrefab = new [=this](entity) => { CreatePrefabFromEntity(entity); };
			mHierarchy.OnSpawnPrefab = new [=this](parent) => { PickAndSpawnPrefab(parent); };
			mHierarchy.OnApplyPrefab = new [=this](root) => { ApplyInstanceToPrefab(root); };
			mHierarchy.OnRevertPrefab = new [=this](root) => { RevertInstance(root); };
			mInspector = new SceneInspectorView(context, mEditContext);

			mSelectTool = (SelectTransformTool)mViewportTools.Add(new SelectTransformTool(mEditContext)); // the default
			mSelectTool.SetPicker(mPicker); // GPU pick over this page's viewport
			var toolHost = ViewportToolHostContext();
			toolHost.Scene = mScene;
			toolHost.Commands = Commands;
			toolHost.EntitySelection = mEditContext.EntitySelection;
			toolHost.AssetEdits = context;
			toolHost.EditorContext = context;
			toolHost.Picker = mPicker;
			ViewportToolProviderRegistry.CreateAll(mViewportTools, toolHost);
			BuiltinGizmoRenderers.Register(mComponentGizmos);
		}

		BuildViewportToolbar();
		let viewportPane = new FlexLayout();
		viewportPane.Direction = .Vertical;
		var toolbarStyle = LayoutStyle();
		toolbarStyle.Width = SizeSpec.Match();
		toolbarStyle.Height = SizeSpec.Fixed(Unit.Dp(30));
		viewportPane.AddView(mToolbar, toolbarStyle);
		{
			BuildCameraPreview();
			let viewportFrame = new FrameLayout();
			var fill = LayoutStyle();
			fill.Gravity = .Fill;
			viewportFrame.AddView(mViewport, fill);
			var corner = LayoutStyle();
			corner.Gravity = .Bottom | .Right;
			corner.Margin = Thickness(12.0f, 12.0f, 12.0f, 12.0f);
			viewportFrame.AddView(mPreviewContainer, corner);

			mToolOverlay = new Panel();
			mToolOverlay.StyleClasses.Add(new String("panel")); // the theme's panel background
			mToolOverlay.Visibility = .Gone;
			mToolOverlay.Padding = .(8.0f, 8.0f, 8.0f, 8.0f);
			var overlayStyle = LayoutStyle();
			overlayStyle.Gravity = .Top | .Right;
			overlayStyle.Margin = Thickness(12.0f, 12.0f, 12.0f, 12.0f);
			overlayStyle.Width = SizeSpec.Fixed(Unit.Dp(260.0f));
			viewportFrame.AddView(mToolOverlay, overlayStyle);

			BuildToolFloat();
			mToolFloatLayer = new AbsoluteLayout();
			mToolFloatLayer.IsHitTestVisible = false;
			var layerStyle = LayoutStyle();
			layerStyle.Gravity = .Fill;
			layerStyle.Width = SizeSpec.Match();
			layerStyle.Height = SizeSpec.Match();
			viewportFrame.AddView(mToolFloatLayer, layerStyle);
			var floatStyle = LayoutStyle();
			floatStyle.Left = 16.0f;
			floatStyle.Top = 16.0f;
			mToolFloatLayer.AddView(mToolFloat, floatStyle);

			var frameStyle = LayoutStyle();
			frameStyle.Width = SizeSpec.Match();
			frameStyle.FlexGrow = 1.0f;
			viewportPane.AddView(viewportFrame, frameStyle);
		}

		mPropAnimPanel = new PropertyAnimationPanel(context, mScene, Commands, mEditContext.EntitySelection);
		mBottomDock = new BottomDock();
		mBottomDock.AddTab("animation", "Animation", mPropAnimPanel);

		mToolPanelSlot = new FlexLayout();
		mToolPanelSlot.Direction = .Vertical;
		mBottomDock.AddTab("tool", "Brush", mToolPanelSlot);
		{
			var panelCtx = ViewportToolHostContext();
			panelCtx.Scene = mScene;
			panelCtx.Commands = Commands;
			panelCtx.EntitySelection = mEditContext.EntitySelection;
			panelCtx.AssetEdits = context;
			panelCtx.EditorContext = context;
			mToolPanelHost = new ViewportToolPanelHost(mViewportTools, ViewportToolPanelRegistry.Global, panelCtx,
				new [=this](view, placement) => { MountToolPanel(view, placement); },
				new [=this](placement) => { MountToolPanel(null, placement); });
		}

		mViewportColumn = new SplitView(.Vertical);
		mViewportColumn.SplitRatio = 0.72f;
		mViewportColumn.SetPanes(viewportPane, mBottomDock);
		mViewportColumn.SetPaneCollapsed(.Second, true);
		mBottomDock.OnExpandedChanged.Add(new [=this](expanded) =>
		{
			mViewportColumn.SetPaneCollapsed(.Second, !expanded);
		});

		mPropAnimPanel.RequestEntityPick = new [=this](current, onPicked) =>
		{
			let ctx = mPropAnimPanel.Context;
			if (ctx == null)
			{
				delete onPicked;
				return;
			}
			let dialog = new EntityPickerDialog(mEditContext.Scene, current);
			dialog.OnPicked = new [=onPicked](picked) =>
			{
				if (!picked.IsNil) // Clear means keep the binding
					onPicked(picked);
			} ~ delete onPicked;
			dialog.Show(ctx);
		};
		mOpenAssetInterceptorId = mContext.AddOpenAssetInterceptor(new [=this](inst) =>
		{
			if (!AssetTypeNames.Matches(inst.TypeName, "PropertyAnimationClipAsset"))
				return false; // not ours
			if ((mContent == null) || !mContent.IsEffectivelyVisible())
				return false;
			mBottomDock.ActivateTab("animation"); // expand the bar
			let selection = mEditContext.EntitySelection;
			mPropAnimPanel.RequestEditClip(inst.Id, selection.IsEmpty ? Guid() : selection.Primary);
			return true;
		});

		let inner = new SplitView();
		inner.SplitRatio = 0.72f;
		inner.SetPanes(mViewportColumn, mInspector);
		let topContent = new SplitView();
		topContent.SplitRatio = 0.2f;
		topContent.SetPanes(mHierarchy, inner);
		mContent = topContent;

		mRouter = new InputRouter(host.Shell.Input);
		// Framed on the origin, the orbit pivot there and the horizon level - then where this
		// scene was last left, if a page saved that.
		mCamera.LookAt(.Zero);
		RestoreViewState();
	}

	public ~this()
	{
		if (mOpenAssetInterceptorId != 0)
		{
			mContext.RemoveOpenAssetInterceptor(mOpenAssetInterceptorId);
			mOpenAssetInterceptorId = 0;
		}
	}

	public override View ContentView => mContent;
	public override StringView Title => mTitle;

	public Sedulous.Scene.Scene ScenePtr => mScene;
	public EditorCamera Camera => mCamera;
	public SceneEditContext EditContext => mEditContext;
	public bool IsSimulating => mIsSimulating;

	/// Loads the instance's scene stream, then binds and spawns; a missing stream is a new
	/// scene.
	private void LoadSceneContent(Instance instance)
	{
		let loaded = SceneStorage.LoadScene(instance, mScene);
		if (loaded case .Ok)
		{
			ResolveAll();
			GlobalLog(.Information, "Editor: opened scene '{}'", mTitle);
		}
		else if (loaded case .Err(.NotFound))
		{
			GlobalLog(.Information, "Editor: new scene '{}' (no scene stream yet)", mTitle);
		}
		else
		{
			GlobalLog(.Error, "Editor: scene '{}' failed to load", mTitle);
		}
	}

	/// Binds the scene's references on the async path, spawns any parked prefab instances,
	/// and binds what they brought.
	private void ResolveAll()
	{
		let resources = mContext.Resources;
		if (resources != null)
		{
			let async = AsyncBindScope(resources);
			defer async.Dispose();
			SceneResolve.ResolveSceneResources(mScene, resources);
		}
		if ((mScene.PendingPrefabInstanceCount > 0) && (mContext.Project != null))
		{
			let resolver = GameEditorPage.ProjectPrefabResolver(mContext);
			defer delete resolver;
			ScenePrefabs.ResolveScenePrefabs(mScene, resolver);
			if (resources != null)
			{
				let async = AsyncBindScope(resources);
				defer async.Dispose();
				SceneResolve.ResolveSceneResources(mScene, resources);
			}
		}
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		EnsureViewportBound();
		if (mHostWindow == null)
			return;

		if (mHierarchy != null)
			mHierarchy.Refresh(); // the scene revision rebuilds the tree
		if (mInspector != null)
			mInspector.Refresh(); // the selection or structure rebuilds the grid

		mViewport.SyncInputRegion();
		mRouter.SetExternalCapture(false, mViewport.HostKeyboardFocusElsewhere);
		mRouter.Update();
		let viewportActive = mViewport.IsHovered() || mViewport.IsFocused();
		if (viewportActive)
		{
			// The first consumer rule: a modal tool owns SHIFT and the wheel to resize itself,
			// so the camera must not dolly on that same scroll. The bare wheel stays the
			// camera's even under a brush, which is what zooming while painting needs.
			let modalToolActive = (mViewportTools.ActiveTool != null) && (mViewportTools.ActiveTool != mSelectTool);
			let keyboard = mViewport.Keyboard;
			let shiftDown = (keyboard != null)
				&& (keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift));
			mCamera.Update(keyboard, mViewport.Mouse, dt, !(modalToolActive && shiftDown));
		}
		else
		{
			mCamera.ReleaseCapture(mViewport.Mouse);
		}
		UpdateViewportTools(viewportActive, dt); // picking lives inside the select tool
		if (mToolPanelHost != null)
			mToolPanelHost.Sync();
		if (mPropAnimPanel != null)
			mPropAnimPanel.Tick(dt, mIsSimulating);
		mPageEvents.Drain();

		if ((mRender != null) && (mScene != null))
		{
			let dd = mRender.DebugView(Internal.UnsafeCastToPtr(mViewport));
			if (mView.ShowGrid)
			{
				dd.DrawGrid(.Zero, 20.0f, 20, .(0.35f, 0.35f, 0.38f, 1.0f));
				dd.DrawLine(.Zero, .(1, 0, 0), .(0.9f, 0.2f, 0.2f, 1.0f));
				dd.DrawLine(.Zero, .(0, 1, 0), .(0.2f, 0.9f, 0.2f, 1.0f));
				dd.DrawLine(.Zero, .(0, 0, 1), .(0.2f, 0.4f, 0.95f, 1.0f));
			}
			DrawEntityMarkers(dd);
			DrawGizmos(dd);
			if (mPropAnimPanel != null)
				mPropAnimPanel.DrawOverlay(dd); // the live preview entity marker
		}
		UpdateCameraPreview();
		SyncToolbar();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (!mViewport.IsReady || !frame.Valid)
			return;
		if ((mRender == null) || !mRender.IsReady || (mScene == null))
			return;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0) || !mViewport.IsEffectivelyVisible())
			return;

		if (!mRenderedOnce)
		{
			mRenderedOnce = true;
			GlobalLog(.Debug, "Editor: scene page '{}' first frame ({}x{})", mTitle, w, h);
		}

		if (mGameUI != null)
			mGameUI.RenderCanvasTextures(frame.Encoder, (int32)frame.FrameIndex);

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(mCamera.Position, mCamera.Position + mCamera.Forward, mCamera.Up);
		camera.Projection = Float4x4.PerspectiveFovRH(cFovY, (float)w / (float)h, 0.1f, 1000.0f);
		camera.Position = mCamera.Position;
		camera.FarZ = 1000.0f;

		var cameraOverride = CameraOverride();
		cameraOverride.Camera = camera;
		cameraOverride.ClearColor = .(mViewport.ClearColor.R, mViewport.ClearColor.G, mViewport.ClearColor.B, mViewport.ClearColor.A);

		let targetState = TargetState(mViewport.ColorTexture, mViewport.ColorState, .ShaderRead);
		mRender.RenderScene(mScene, mViewport.ColorTargetView, mViewport.ColorFormat, w, h, .(0, 0, w, h),
			&cameraOverride, targetState, &mPostOverride, Internal.UnsafeCastToPtr(mViewport), mDebugView);
		mViewport.ColorState = .ShaderRead;

		RenderCameraPreview(); // a second RenderScene through the previewed camera
	}

	/// A change on disk replaces the scene, unless there are unsaved edits here.
	public override void OnAssetExternallyModified()
	{
		if ((mScene == null) || (mContext.Project == null))
			return;
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return;
		if (IsDirty)
		{
			mContext.Notify(.Warning, scope $"'{mTitle}' changed on disk but has unsaved edits here - not refreshed.");
			return;
		}

		while (mScene.FirstRoot.IsAssigned)
			mScene.DestroyEntity(mScene.FirstRoot);
		mScene.ClearPrefabInstances();
		mEditContext.EntitySelection.Clear();
		Commands.Clear();

		if (SceneStorage.LoadScene(instance, mScene) case .Ok)
			ResolveAll();
		ClearDirty(); // Commands.Clear notifies OnChanged, which marks dirty
	}

	public override void OnSavedAs(Instance instance)
	{
		base.OnSavedAs(instance);
		mTitle.Set(instance.Name);
		if (mScene != null)
			mScene.SetName(instance.Name);
	}

	/// Saves the scene, or the prefab after checking it has one root and does not contain
	/// itself; a saved prefab rebuilds its instances in every other open scene.
	public override Result<void, ErrorCode> Save()
	{
		if ((mScene == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);

		let isPrefab = AssetTypeNames.Matches(instance.TypeName, "PrefabDocument");
		if (isPrefab)
		{
			var rootCount = 0;
			for (var r = mScene.FirstRoot; r.IsAssigned; r = mScene.GetNextSibling(r))
				rootCount++;
			if (rootCount > 1)
			{
				mContext.Notify(.Warning, "A prefab needs exactly one root entity - parent everything under a single root, then save.");
				return .Err(.InvalidArgument);
			}
			var selfReference = false;
			mScene.ForEachPrefabInstance(scope [&](state) =>
			{
				if (state.PrefabId == InstanceId)
					selfReference = true;
			});
			if (selfReference)
			{
				mContext.Notify(.Warning, "A prefab cannot contain an instance of itself - remove it, then save.");
				return .Err(.InvalidArgument);
			}
		}
		let saved = isPrefab ? SceneStorage.SavePrefab(mScene, instance) : SceneStorage.SaveScene(mScene, instance);
		if (saved case .Ok)
		{
			ClearDirty();
			GlobalLog(.Information, "Editor: saved {} '{}'", isPrefab ? "prefab" : "scene", mTitle);
			if (isPrefab && (mScenes != null))
			{
				let payload = instance.ReadData("scene");
				if (payload != null)
				{
					defer delete payload;
					let bytes = scope List<uint8>();
					ReadAll(payload, bytes);
					let prefabId = InstanceId;
					mScenes.ForEachScene(scope [&](other) =>
					{
						if (other == mScene)
							return;
						let rebuilt = PrefabRebuild.Rebuild(other, prefabId, bytes, mEditContext.PrefabResolver);
						if ((rebuilt > 0) && (mContext.Resources != null))
							SceneResolve.ResolveSceneResources(other, mContext.Resources);
					});
				}
			}
		}
		return saved;
	}

	public override void OnClose()
	{
		if (mScene != null)
			SaveViewState(); // where the scene was left, for the next open
		if (mOpenAssetInterceptorId != 0)
		{
			mContext.RemoveOpenAssetInterceptor(mOpenAssetInterceptorId);
			mOpenAssetInterceptorId = 0;
		}
		mCamera.ReleaseCapture((mViewport != null) ? mViewport.Mouse : null); // never close captured
		if (mRender != null)
			mRender.CancelPicks(Internal.UnsafeCastToPtr(mViewport)); // the key dies with the viewport
		mViewport.Shutdown();
		if (mPreviewViewport != null)
			mPreviewViewport.Shutdown();
		if (mScene != null)
		{
			mSceneManager.DestroyScene(mScene); // aware subsystems get OnSceneDestroyed
			mScene = null;
		}
		if (mScenes != null)
			mScenes.UnregisterManager(mSceneManager);
	}

	/// The whole of a stream into a list.
	public static void ReadAll(IStream stream, List<uint8> outBytes)
	{
		outBytes.Clear();
		let size = (int)stream.Size();
		if (size <= 0)
			return;
		outBytes.Resize(size);
		stream.Seek(0, .Begin);
		let read = stream.Read(Span<uint8>(outBytes.Ptr, size));
		if (read < size)
			outBytes.Resize(Math.Max(read, 0));
	}
}
