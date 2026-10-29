using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Messaging;
using Sedulous.Shell;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

// SceneEditorPage: the scene (and prefab) document editor, on the GUI from markup
// (Data/Editor/Scene.gml; Raptor's editor-gui spec, 5.3, layer 2). Each page owns its own live
// scene, in its own scene manager (several pages are open at once; everything scene scoped is per
// page), and is made of parts: its viewport (the renderer drawing the scene into it, the camera,
// picking, the capture), its overlays, Simulate, the prefab flows and the view state kept per scene,
// each a class of its own. The page holds them together: it loads the scene, edits it through its
// edit context and its tools, saves it, follows a change made elsewhere, and says on the page when
// the scene did not load (and then refuses to save over it). Its bar's Save, Undo and Redo act on
// this page; its hierarchy (layer 3) is the scene's tree in its left pane. The inspector takes its
// pane in the next layer.

/// What a page asks of the editor. Borrowed but the markup loader, the services' own.
class SceneEditorPageServices
{
	public IApplicationHost Host = null;
	/// What draws its viewport (null: none, a test).
	public GuiHost Gui = null;
	/// The page's markup by its path under the data root: a node with one reference, the caller's.
	public delegate Node(StringView path) LoadMarkup ~ delete _;
	/// The asset picker and the rest an asset slot asks (null: no picking, a test).
	public ResourceRefServices Refs = null;
	/// The type icons the hierarchy shows entities by (null: none).
	public EditorIcons Icons = null;
}

class SceneEditorPage : UIEditorPage, ISceneEditorPage
{
	public const String cPath = "Editor/Scene.gml";

	private EditorContext mContext;
	private SceneEditorPageServices mServices ~ delete _;
	/// The context's (registry and tick).
	private SceneSubsystem mScenes = null;
	/// This page's own scene group.
	private SceneManager mSceneManager = new .() ~ delete _;
	/// The page's run scope (edit mode Simulate).
	private EventBus mPageEvents = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	/// The scene manager's.
	private Sedulous.Scene.Scene mScene = null;
	private bool mLoadFailed = false;
	private bool mIsPrefab = false;
	/// Every edit, as this page's commands.
	private SceneEditContext mEditContext = null;
	private SceneViewport mViewport ~ delete _;
	private SceneOverlays mOverlays = new .() ~ delete _;
	private SceneSimulation mSimulation = new .() ~ delete _;
	private PrefabFlows mPrefabs = null ~ delete _;
	private SceneHierarchyView mHierarchy = null;
	/// After mEditContext (the tools borrow it), so deleted first.
	private ViewportToolManager mViewportTools = new .() ~ delete _;
	/// The manager's default tool.
	private SelectTransformTool mSelectTool = null;
	private GizmoRendererRegistry mComponentGizmos = new .() ~ delete _;
	/// A press that began on the orientation gizmo, until its release.
	private bool mViewGizmoPressed = false;
	/// The viewport's post show flags and debug view (not saved).
	private ViewPostOverride mPostOverride = .();
	private ViewDebugView mDebugView = new .() ~ delete _;
	/// One reference, the page's.
	private Node mContent = null;
	private PageActionBar mBar = null ~ delete _;
	private MessageBox mConfirm = null;
	// The launcher's picture of the project: the default scene's view, taken once it settled when
	// there is none yet, and on every save of it.
	private bool mThumbnailChecked = false;
	private float mThumbnailWait = 0.0f;

	/// Takes `services`; `context` borrowed.
	public this(EditorContext context, SceneEditorPageServices services, Instance instance)
	{
		mContext = context;
		mServices = services;
		mTitle.Set(instance.Name);
		// The id now, before the view state is read: the per scene prefs are keyed by it.
		InstanceId = instance.Id;
		mIsPrefab = AssetTypeNames.Matches(instance.TypeName, "PrefabDocument");
		Build(instance);
	}

	public ~this()
	{
		// The tools borrow the edit context, the flows and the hierarchy too: they go first.
		DeleteAndNullify!(mHierarchy);
		DeleteAndNullify!(mPrefabs);
		DeleteAndNullify!(mViewportTools);
		delete mEditContext;
		if (mConfirm != null)
			mConfirm.ReleaseRef();
		if (mContent != null)
			mContent.ReleaseRef();
	}

	// === UIEditorPage ===
	public override Node Content => mContent;
	public override StringView Title => mTitle;

	// === ISceneEditorPage ===
	public SceneEditContext EditContext => mEditContext;
	public bool IsSimulating => mSimulation.IsRunning;
	public bool IsPaused => mSimulation.IsPaused;
	public GizmoController Gizmos => (mSelectTool != null) ? mSelectTool.Gizmos : null;
	public bool CameraOwnsInput => mViewport.CameraOwnsInput;
	public bool MarkersShown => mOverlays.Settings.ShowMarkers;
	/// The property animation panel comes back with its editor (X6): never shown until then.
	public bool AnimationPanelShown => false;
	public EditorCamera ViewportCamera => mViewport.Camera;
	public ViewportCapture LastViewportCapture => mViewport.LastCapture;
	public Result<void, ErrorCode> RequestViewportCapture(StringView path) => mViewport.RequestCapture(path, false);
	public void CreatePrefabFromEntity(Guid entity) { if (mPrefabs != null) mPrefabs.CreateFromEntity(entity); }
	public void PickAndSpawnPrefab(Guid parent) { if (mPrefabs != null) mPrefabs.PickAndSpawn(parent); }
	public void ApplyInstanceToPrefab(Guid root) { if (mPrefabs != null) mPrefabs.Apply(root); }
	public void RevertInstance(Guid root) { if (mPrefabs != null) mPrefabs.Revert(root); }

	// === For tests ===
	public Sedulous.Scene.Scene ScenePtr => mScene;
	/// Whether the scene failed to load (and what the page says).
	public bool LoadFailed => mLoadFailed;
	public bool IsPrefab => mIsPrefab;
	public SceneOverlays Overlays => mOverlays;
	public SceneViewport Viewport => mViewport;
	public SceneHierarchyView Hierarchy => mHierarchy;
	public MessageBox OpenConfirm => ((mConfirm != null) && mConfirm.IsOpen) ? mConfirm : null;

	private void Build(Instance instance)
	{
		let context = mContext;
		let host = mServices.Host;
		var view = SceneViewportServices();
		if (host != null)
		{
			mScenes = host.Context.GetSubsystem<SceneSubsystem>();
			view.Render = host.Context.GetSubsystem<RenderSubsystem>();
			view.GameUI = host.Context.GetSubsystem<UISubsystem>();
			view.GameGui = host.Context.GetSubsystem<Sedulous.Engine.GUI.GuiSubsystem>();
		}
		mViewport = new SceneViewport(view);

		// Its own live scene in its own scene manager, registered with the subsystem so it ticks.
		if (mScenes != null)
		{
			mScenes.RegisterManager(mSceneManager);
			// The page is edit mode Simulate's run scope: its bus is set before the scene is made,
			// so systems binding as it is assembled see it; OnUpdate drains it once a frame.
			mSceneManager.SetSceneEventBus(mPageEvents);
			mScene = mSceneManager.CreateScene(instance.Name);
			mScene.SetSimulationEnabled(false); // edit mode is frozen; Simulate unfreezes it
			let loaded = SceneLoading.LoadEditorScene(context, instance, mScene);
			if (loaded case .Ok)
				GlobalLog(.Information, "Editor: opened scene '{}'", mTitle);
			else if (loaded case .Err(.NotFound))
				GlobalLog(.Information, "Editor: new scene '{}' (no scene stream yet)", mTitle);
			else
			{
				GlobalLog(.Error, "Editor: scene '{}' failed to load", mTitle);
				mLoadFailed = true;
			}
		}

		if (mScene != null)
		{
			mEditContext = new SceneEditContext(mScene, Commands);
			mEditContext.SetResources(context.Resources);
			// A settings edit that lands in a profile (the block's source is a profile) is written
			// to the profile's asset by the save flow, like any live asset edit.
			let profileEdit = mEditContext;
			mEditContext.OnSettingsProfileEdited = new [=context, =profileEdit](type, profile) =>
				{
					if (let system = profileEdit.FindSystemBySettingsType(type))
						SettingsProfiles.QueueEdit(context, system, profile);
				};
			mEditContext.SetPrefabResolver(SceneLoading.ProjectPrefabResolver(context));
			BuildTools(context);
			BuiltinGizmoRenderers.Register(mComponentGizmos);

			let flows = new PrefabFlowServices();
			flows.Context = context;
			flows.Edit = mEditContext;
			flows.Scenes = mScenes;
			flows.PageAsset = new [=this]() => InstanceId;
			flows.Confirm = new [=this](title, text, verb, yes) => { Confirm(title, text, verb, yes); };
			flows.Later = new [=this](work) => { Later(work); };
			if ((mServices.Refs != null) && (mServices.Refs.Pick != null))
			{
				let refs = mServices.Refs;
				flows.PickAsset = new [=refs](types, chosen) => { refs.Pick(types, .(), null, chosen); };
			}
			mPrefabs = new PrefabFlows(flows);
		}

		// The page from its markup: the bar over the hierarchy, the viewport and the inspector.
		mContent = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(cPath) : null;
		if (mContent == null)
			mContent = new Panel(); // no markup: still a page, with its viewport
		let pane = Find<Node>("scene-viewport");
		((pane != null) ? pane : mContent).AddChildAt(mViewport.View, 0);
		mViewport.HostIn(mServices.Gui);
		mBar = new PageActionBar(context.Actions, this);
		mBar.Bind(Find<ButtonBase>("scene-save"), "file.save");
		mBar.Bind(Find<ButtonBase>("scene-undo"), "edit.undo");
		mBar.Bind(Find<ButtonBase>("scene-redo"), "edit.redo");
		// A prefab is marked as one: the same page edits both.
		if (let kind = Find<UIWidget>("scene-kind"))
			kind.Displayed = mIsPrefab;
		// A scene that did not load says so where it would show, not only in the log.
		if (let state = Find<UIWidget>("scene-state"))
			state.Displayed = mLoadFailed || (mScene == null);
		if (mScene == null)
		{
			if (let text = Find<Sedulous.GUI.Label>("scene-state-text"))
				text.Text = "The editor has no scenes to show it in.";
		}

		// The hierarchy in its pane: the scene's tree, the page's selection.
		if (mEditContext != null)
		{
			if (let pane = Find<Node>("scene-hierarchy"))
			{
				let tree = new SceneHierarchyServices();
				tree.Context = context;
				tree.Page = this;
				tree.Icons = mServices.Icons;
				tree.SceneIcon.Set(mIsPrefab ? "Editor/Icons/Types/PrefabDocument.svg" : "Editor/Icons/Types/SceneDocument.svg");
				tree.SceneName = new [=this]() => mTitle;
				tree.Frame = new [=this](entity) => { var one = entity; FrameEntities(.(&one, 1), true); };
				tree.SpawnPrefab = new [=this](prefab, parent) => (mPrefabs != null) && mPrefabs.Spawn(prefab, parent);
				mHierarchy = new SceneHierarchyView(mEditContext, tree, pane);
			}
		}

		mOverlays.Settings = SceneViewState.LoadOverlays(context.ProjectEditorSettings, InstanceId, mOverlays.Settings);
		RestoreViewState();
	}

	private void BuildTools(EditorContext context)
	{
		mSelectTool = (SelectTransformTool)mViewportTools.Add(new SelectTransformTool(mEditContext)); // the default
		mSelectTool.SetPicker(mViewport.Picker); // the GPU pick over this page's viewport
		var toolHost = ViewportToolHostContext();
		toolHost.Scene = mScene;
		toolHost.Commands = Commands;
		toolHost.EntitySelection = mEditContext.EntitySelection;
		toolHost.Picker = mViewport.Picker;
		// A tool that edits a cooked product live (terrain sculpt) registers its write back to the
		// source on the context; the save flow drains it.
		toolHost.AssetEdits = context;
		toolHost.EditorContext = context;
		ViewportToolProviderRegistry.CreateAll(mViewportTools, toolHost);
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		mViewport.CompleteCapture(host); // a capture recorded last frame: the GPU finished the copy
		// A project with no launcher picture gets one from its default scene, once the view has been
		// up a moment with nothing left loading (content pops in asynchronously).
		if (!mThumbnailChecked && IsProjectDefaultScene)
		{
			mThumbnailWait += dt;
			let settled = (mContext.Resources == null) || (mContext.Resources.PendingCount == 0);
			if ((mThumbnailWait > 1.5f) && settled && mViewport.IsShown)
			{
				mThumbnailChecked = true;
				if (!FileExists(EditorProject.ThumbnailPath(mContext.Project.Directory, .. scope .())))
					RequestProjectThumbnail();
			}
		}

		// A modal tool (a brush) owns Shift + wheel to size itself, so the camera leaves that wheel
		// to it; the bare wheel stays the camera's under a brush too.
		let modalTool = (mViewportTools.ActiveTool != null) && (mViewportTools.ActiveTool != mSelectTool);
		let keyboard = mViewport.Keyboard;
		let shift = (keyboard != null) && (keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift));
		let active = mViewport.UpdateCamera(dt, !(modalTool && shift));
		if (active && mViewport.ZoomedThisFrame)
			mOverlays.Zoomed();
		if (mEditContext != null)
			UpdateTools(active, dt);
		// The page is this scene's run scope: its bus drains once a frame (events a Simulate tick
		// emitted last frame arrive now).
		mPageEvents.Drain();

		// The overlays into this viewport's own debug list (the lists clear each frame, so they are
		// drawn again every frame); none on the frame a project picture is captured.
		let dd = mViewport.Overlay;
		if ((dd != null) && (mScene != null) && !mViewport.CleanCaptureFrame)
		{
			var frame = SceneOverlayFrame();
			frame.Scene = mScene;
			frame.Selection = (mEditContext != null) ? mEditContext.EntitySelection : null;
			frame.Camera = mViewport.Camera;
			frame.Width = mViewport.View.RenderWidth;
			frame.Height = mViewport.View.RenderHeight;
			let mouse = mViewport.Mouse;
			frame.PointerOver = mViewport.IsHovered && (mouse != null);
			frame.PointerX = (mouse != null) ? mouse.X : 0.0f;
			frame.PointerY = (mouse != null) ? mouse.Y : 0.0f;
			frame.Tools = mViewportTools;
			frame.ComponentGizmos = mComponentGizmos;
			frame.DeltaSeconds = dt;
			mOverlays.Draw(dd, frame);
		}
		if (mHierarchy != null)
			mHierarchy.Refresh(); // the scene changed: built again
		if (mBar != null)
			mBar.Sync();
	}

	/// The viewport tools' frame of input (picking lives in the select tool). Runs every frame so
	/// the active tool follows selections and undo while the mouse is elsewhere (the pointer then
	/// flagged invalid). The page keeps the camera's policy: no buttons and no keyboard for the
	/// tools while the camera has the mouse; Simulate is editing locked.
	private void UpdateTools(bool viewportActive, float deltaSeconds)
	{
		let camera = mViewport.Camera;
		var input = ViewportToolInput();
		input.DeltaSeconds = deltaSeconds;
		// The draw eye: under orthographic what lies behind the eye's own plane is in view too, and
		// the gizmo's size and the marquee take a depth from here (the eye in perspective).
		input.CameraPosition = camera.DrawEye;
		input.CameraForward = camera.Forward;
		input.CameraUp = camera.Up;
		input.FovY = camera.FovY;
		input.OrthoHeight = camera.Orthographic ? camera.OrthoHeight : 0.0f;
		// Simulate: edits are refused (the select tool's read only gizmo); selecting still works.
		input.EditingLocked = mSimulation.IsRunning;
		GizmoRay ray = ?;
		input.PointerValid = viewportActive && mViewport.MouseRay(out ray);
		input.Ray.Origin = ray.Origin;
		input.Ray.Direction = ray.Direction;
		input.PointerOver = mViewport.IsHovered;
		if (!input.PointerValid)
		{
			mViewportTools.Update(input);
			return;
		}
		let mouse = mViewport.Mouse;
		let keyboard = mViewport.Keyboard;
		// The pointer's pixel and the view's size: the GPU pick's input, in the render target's space.
		input.PointerX = (int32)mouse.X;
		input.PointerY = (int32)mouse.Y;
		input.ViewportWidth = mViewport.View.RenderWidth;
		input.ViewportHeight = mViewport.View.RenderHeight;
		let cameraOwnsMouse = mViewport.CameraOwnsInput;
		if (!cameraOwnsMouse)
		{
			input.LeftPressed = mouse.IsButtonPressed(.Left);
			input.LeftDown = mouse.IsButtonDown(.Left);
		}
		// A release always reaches the tool, so a gesture can finish when a modifier goes down mid drag.
		input.LeftReleased = mouse.IsButtonReleased(.Left) || !mouse.IsButtonDown(.Left);
		if (keyboard != null)
		{
			input.Ctrl = keyboard.IsKeyDown(.LeftCtrl) || keyboard.IsKeyDown(.RightCtrl);
			input.Shift = keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift);
		}
		input.WheelDelta = mouse.ScrollY;
		// A press on the orientation gizmo is its, and the rest of that press: the select tool
		// neither picks nor box selects under it (Alt+drag still orbits: the camera owns that press).
		if (input.LeftPressed && mViewport.IsHovered && PressViewGizmo((float)input.PointerX, (float)input.PointerY, input.ViewportWidth))
			mViewGizmoPressed = true;
		if (mViewGizmoPressed)
		{
			let released = input.LeftReleased;
			input.LeftPressed = false;
			input.LeftDown = false;
			input.LeftReleased = false;
			mViewGizmoPressed = !released;
		}
		// The tools' keys (the select tool's W/E/R/X) belong to the camera while it owns the input.
		input.Keyboard = cameraOwnsMouse ? null : keyboard;
		mViewportTools.Update(input);
	}

	/// The orientation gizmo takes a press on a knob (or its centre) before any tool sees it.
	private bool PressViewGizmo(float x, float y, uint32 width)
	{
		let camera = mViewport.Camera;
		let gizmo = ViewGizmo.LayoutFor(camera.Right, camera.Up, camera.Forward, (float)width);
		let hit = ViewGizmo.Hit(gizmo, x, y);
		if (hit >= 0)
		{
			ViewGizmo.SnapAngles(gizmo.Poles[hit].Axis, camera.Yaw, let yaw, let pitch);
			camera.AutoOrthographic = EditorUiSettings.AutoOrthographicViews(mContext.UserEditorSettings);
			camera.SnapToAxis(yaw, pitch);
			return true;
		}
		if (ViewGizmo.HitCentre(gizmo, x, y))
		{
			camera.SetOrthographic(!camera.Orthographic);
			return true;
		}
		return false;
	}

	/// Inside the app's one renderer bracket, before the GUI draws.
	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mScene != null)
			mViewport.Render(ref frame, mScene, &mPostOverride, mViewport.CleanCaptureFrame ? null : mDebugView);
	}

	/// A requested capture, recorded once the renderer composed the frame.
	public override void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame)
	{
		mViewport.AfterRender(host, ref frame);
	}

	public override void OnClose()
	{
		DeleteAndNullify!(mHierarchy); // it lets the selection and the tree go before the scene does
		// Where the scene was left: the camera, the selection, the panes, for the next open.
		if (mScene != null)
			SaveViewState();
		mViewport.Close(mServices.Host);
		if (mScene != null)
		{
			mSceneManager.DestroyScene(mScene); // aware subsystems are told OnSceneDestroyed
			mScene = null;
		}
		if (mScenes != null)
			mScenes.UnregisterManager(mSceneManager);
	}

	/// Saves the scene, or the prefab once it has one root and does not hold itself; a saved
	/// prefab rebuilds its instances in every other open scene. A scene that did not load is never
	/// saved over.
	public override Result<void, ErrorCode> Save()
	{
		if ((mScene == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		// A scene that did not load is empty here: saving would write that over its source.
		if (mLoadFailed)
		{
			mContext.Notify(.Warning, scope $"'{mTitle}' did not load, so it is not saved over: the Console says why.");
			return .Err(.NotSupported);
		}
		let isPrefab = AssetTypeNames.Matches(instance.TypeName, "PrefabDocument");
		if (isPrefab)
		{
			let refused = scope String();
			if (PrefabFlows.SaveRefusal(mScene, InstanceId, refused))
			{
				mContext.Notify(.Warning, refused);
				return .Err(.InvalidArgument);
			}
		}
		let saved = isPrefab ? SceneStorage.SavePrefab(mScene, instance) : SceneStorage.SaveScene(mScene, instance);
		if (saved case .Err)
			return saved;
		ClearDirty();
		GlobalLog(.Information, "Editor: saved {} '{}'", isPrefab ? "prefab" : "scene", mTitle);
		// The launcher's picture of the project follows its default scene as it is saved.
		if (!isPrefab && IsProjectDefaultScene)
			RequestProjectThumbnail();
		// The template changed: its instances in every other open scene rebuild, their overrides kept.
		if (isPrefab && (mPrefabs != null))
			mPrefabs.RebuildOtherInstances(instance);
		return saved;
	}

	public override void OnSavedAs(Instance instance)
	{
		base.OnSavedAs(instance);
		mTitle.Set(instance.Name);
		// SavePrefab stamps the document's name from the scene, so the fork gets its own.
		if (mScene != null)
			mScene.SetName(instance.Name);
	}

	/// The asset changed under this page (apply to prefab from another page): read again, its
	/// history gone; unsaved edits are never clobbered, the page warns instead.
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
		// The same entities come back from the stream; the history predates the reload and would
		// replay onto the old content, so it goes.
		while (mScene.FirstRoot.IsAssigned)
			mScene.DestroyEntity(mScene.FirstRoot);
		mScene.ClearPrefabInstances();
		mEditContext.EntitySelection.Clear();
		Commands.Clear();
		let loaded = SceneLoading.LoadEditorScene(mContext, instance, mScene);
		mLoadFailed = (loaded case .Err(let error)) && (error != .NotFound);
		if (let state = Find<UIWidget>("scene-state"))
			state.Displayed = mLoadFailed;
		ClearDirty(); // Commands.Clear told OnChanged, which marks it dirty
	}

	public void StartSimulation()
	{
		if ((mScene == null) || !mSimulation.Start(mScene, Commands))
			return;
		// Modal edit tools (terrain sculpt) share runtime state with the simulation (the collider):
		// back to the default select tool for the run.
		mViewportTools.ActivateDefault();
	}

	public void PauseSimulation(bool paused)
	{
		if (mScene != null)
			mSimulation.Pause(mScene, paused);
	}

	public void StopSimulation()
	{
		if (mScene != null)
			mSimulation.Stop(mScene, Commands, mContext.Resources);
	}

	public void SetMarkersShown(bool shown)
	{
		mOverlays.Settings.ShowMarkers = shown;
		SaveViewState();
	}

	public void SetAnimationPanelShown(bool shown)
	{
		if (shown)
			mContext.Notify(.Info, "The animation panel is not on the new editor yet: it comes with the property animation editor.");
	}

	public bool FrameEntities(Span<Guid> entities, bool ease) => (mScene != null) && mViewport.Frame(mScene, entities, ease);

	public Result<void, ErrorCode> RequestProjectThumbnail()
	{
		if (mContext.Project == null)
			return .Err(.NotSupported);
		let path = EditorProject.ThumbnailPath(mContext.Project.Directory, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		return mViewport.RequestCapture(path, true);
	}

	private bool IsProjectDefaultScene
	{
		get
		{
			let project = mContext.Project;
			return (project != null) && !InstanceId.IsNil && (project.Settings.DefaultSceneId == InstanceId);
		}
	}

	/// The whole pref (overlays, camera, selection, panes), so saving one never brings back
	/// another's default.
	private void SaveViewState()
	{
		ScenePaneWeights? panes = null;
		if (let body = Find<Splitter>("scene-body"))
		{
			let weights = scope List<float>();
			body.GetWeights(weights);
			if (weights.Count == 3)
				panes = ScenePaneWeights(weights[0], weights[1], weights[2]);
		}
		let selection = (mEditContext != null) ? mEditContext.EntitySelection.Items : Span<Guid>();
		if (SceneViewState.Save(mContext.ProjectEditorSettings, InstanceId, mOverlays.Settings, mViewport.Camera, panes, selection))
			mContext.RequestProjectEditorSettingsSave();
	}

	/// The panes, the camera and the selection as this scene was left; a pref with no camera leaves
	/// the origin's framing standing.
	private void RestoreViewState()
	{
		let pref = SceneViewPrefs.Find(mContext.ProjectEditorSettings, InstanceId);
		if (pref == null)
			return;
		if (pref.HasSplits)
		{
			if (let body = Find<Splitter>("scene-body"))
			{
				let panes = SceneViewState.WeightsFromSplits(pref.Splits.Hierarchy, pref.Splits.Inspector);
				var weights = float[3](panes.Hierarchy, panes.Viewport, panes.Inspector);
				body.SetWeights(weights);
			}
		}
		if (!SceneViewState.RestoreCamera(pref, mViewport.Camera))
			return; // never saved by a page: the origin's framing stands
		if ((mEditContext != null) && (mScene != null))
		{
			let live = scope List<Guid>();
			SceneViewState.LiveSelection(pref, mScene, live);
			if (!live.IsEmpty)
				mEditContext.EntitySelection.Set(live);
		}
	}

	/// Asks `text` under `title`; `yes` (taken) runs when the user takes `verb`.
	private void Confirm(StringView title, StringView text, StringView verb, delegate void() yes)
	{
		let root = (mContent != null) ? mContent.RootNode : null;
		if (root == null)
		{
			delete yes;
			return;
		}
		if (mConfirm != null)
			mConfirm.ReleaseRef();
		let question = new MessageBox();
		mConfirm = question;
		question.Configure(title, text, .Ok);
		question.ClearButtons();
		question.AddButton("Cancel", "cancel", .Cancel);
		question.AddButton(verb, "yes", .Destructive);
		question.AddEventListener(.Changed, new [=question, =yes](e) =>
			{
				if (question.ResultName == "yes")
					yes();
			} ~ delete yes);
		question.OpenModal(root);
	}

	/// Runs `work` (taken) after the event that asked for it: on the GUI's mutation queue, or now
	/// with no GUI around the page.
	private void Later(delegate void() work)
	{
		let queue = (mContent != null) ? mContent.MutationQueue : null;
		if (queue != null)
		{
			queue.Enqueue(work);
			return;
		}
		work();
		delete work;
	}

	/// The page's widget with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		if (mContent == null)
			return null;
		let pending = scope List<Node>();
		pending.Add(mContent);
		while (!pending.IsEmpty)
		{
			let node = pending.PopBack();
			if (let widget = node as UIWidget)
			{
				if (widget.Id == id)
					return node as T;
			}
			for (int i < node.ChildCount)
				pending.Add(node.GetChildAt(i));
		}
		return null;
	}
}
