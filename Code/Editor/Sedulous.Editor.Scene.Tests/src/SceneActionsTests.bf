using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.Core.IO;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Scene.Tests;

/// The scene editor's actions over a headless scene page beside a page that is not one: every
/// action disabled off a scene page; simulate start, pause and stop with their enabled and
/// checked states; the markers toggle; the gizmo toggles disabled without a gizmo and while the
/// camera flies; the entity actions over the selection's primary (create, create child,
/// duplicate, delete, copy and paste through the editor's clipboard), locked while simulating;
/// the prefab flows and the instance actions reaching the page; the hierarchy's menu items from
/// the same declarations.
class SceneActionsTests
{
	class HeadlessScenePage : EditorPage, ISceneEditorPage
	{
		private Sedulous.Scene.Scene mScene = new .("headless") ~ delete _;
		private SceneEditContext mEdit ~ delete _;
		public bool Simulating = false;
		public bool Paused = false;
		public bool Markers = true;
		public bool Flying = false;
		/// BORROWED; null is a page without a viewport.
		public GizmoController GizmosSeen = null;
		public Guid PrefabFrom = .();
		public Guid SpawnParent = .();
		public int Spawns = 0;
		public Guid Applied = .();
		public Guid Reverted = .();

		public this()
		{
			mEdit = new .(mScene, Commands);
		}

		public override StringView Title => "Bistro";
		public override Result<void, ErrorCode> Save() => .Ok;
		public SceneEditContext EditContext => mEdit;
		public void StartSimulation()
		{
			Simulating = true;
			Commands.IsLocked = true;
		}
		public void StopSimulation()
		{
			Simulating = false;
			Paused = false;
			Commands.IsLocked = false;
		}
		public void PauseSimulation(bool paused) { Paused = paused; }
		public bool IsSimulating => Simulating;
		public bool IsPaused => Paused;
		public GizmoController Gizmos => GizmosSeen;
		public bool CameraOwnsInput => Flying;
		/// A viewport is pretended when HasViewport; FrameEntities records what it was asked.
		public bool HasViewport = false;
		private Sedulous.Editor.Camera.EditorCamera mCamera = new .() ~ delete _;
		public Sedulous.Editor.Camera.EditorCamera ViewportCamera => HasViewport ? mCamera : null;
		public List<Guid> Framed = new .() ~ delete _;
		public bool FramedEased = false;
		public bool FrameEntities(Span<Guid> entities, bool ease)
		{
			Framed.Clear();
			Framed.AddRange(entities);
			FramedEased = ease;
			return !entities.IsEmpty;
		}
		public Result<void, ErrorCode> RequestViewportCapture(StringView path) => .Err(.NotSupported);
		/// The project thumbnails asked for: a viewport takes them, none refuses.
		public int ThumbnailRequests = 0;
		public Result<void, ErrorCode> RequestProjectThumbnail()
		{
			if (!HasViewport)
				return .Err(.NotSupported);
			ThumbnailRequests++;
			return .Ok;
		}
		private ViewportCapture mCapture = new .() ~ delete _;
		public ViewportCapture LastViewportCapture => mCapture;
		public bool MarkersShown => Markers;
		public void SetMarkersShown(bool shown) { Markers = shown; }
		public bool Animation = false;
		public bool AnimationPanelShown => Animation;
		public void SetAnimationPanelShown(bool shown) { Animation = shown; }
		public void CreatePrefabFromEntity(Guid entity) { PrefabFrom = entity; }
		public void PickAndSpawnPrefab(Guid parent)
		{
			SpawnParent = parent;
			Spawns++;
		}
		public void ApplyInstanceToPrefab(Guid root) { Applied = root; }
		public void RevertInstance(Guid root) { Reverted = root; }
	}

	class PlainPage : EditorPage
	{
		public override StringView Title => "plain";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	[Test]
	public static void DisabledOffAScenePageAndSimulateMarkersAndGizmoOverThePagesState()
	{
		let context = scope EditorContext();
		SceneActions.Register(context);
		let actions = context.Actions;
		Test.Assert(actions.Find(SceneActionIds.SimulateStart).MenuPath == "Scene/Simulate/Play");
		Test.Assert(actions.Find(SceneActionIds.GizmoTranslate).Kind == .Toggle);
		Test.Assert(actions.Shortcut(SceneActionIds.GizmoTranslate).Key == .W);
		Test.Assert(actions.Shortcut(SceneActionIds.EntityDelete).Key == .Delete);

		let plain = context.AdoptPage(new PlainPage());
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage());

		// Off a scene page, or with no subject, every scene action is disabled.
		for (let action in actions.Actions)
		{
			Test.Assert(!actions.IsEnabled(action.Id, plain), action.Id);
			Test.Assert(!actions.IsEnabled(action.Id, null), action.Id);
		}

		// Simulate: start enables pause and stop; pause is a toggle over the page's pause state.
		Test.Assert(actions.IsEnabled(SceneActionIds.SimulateStart, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.SimulatePause, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.SimulateStop, page));
		Test.Assert(actions.Execute(SceneActionIds.SimulateStart, page) case .Ok);
		Test.Assert(page.Simulating);
		Test.Assert(!actions.IsEnabled(SceneActionIds.SimulateStart, page));
		Test.Assert(actions.IsEnabled(SceneActionIds.SimulatePause, page));
		Test.Assert(!actions.IsChecked(SceneActionIds.SimulatePause, page));
		Test.Assert(actions.Execute(SceneActionIds.SimulatePause, page) case .Ok);
		Test.Assert(page.Paused);
		Test.Assert(actions.IsChecked(SceneActionIds.SimulatePause, page));
		Test.Assert(actions.Execute(SceneActionIds.SimulatePause, page) case .Ok);
		Test.Assert(!page.Paused);
		Test.Assert(actions.Execute(SceneActionIds.SimulateStop, page) case .Ok);
		Test.Assert(!page.Simulating);
		Test.Assert(actions.Execute(SceneActionIds.SimulateStop, page) case .Err(.NotSupported));

		// Markers: a toggle over the page's flag.
		Test.Assert(actions.IsChecked(SceneActionIds.Markers, page));
		Test.Assert(actions.Execute(SceneActionIds.Markers, page) case .Ok);
		Test.Assert(!page.Markers);
		Test.Assert(!actions.IsChecked(SceneActionIds.Markers, page));

		// The animation panel: a toggle over the page's bottom panel, off to start.
		Test.Assert(!actions.IsChecked(SceneActionIds.AnimationPanel, page));
		Test.Assert(actions.Execute(SceneActionIds.AnimationPanel, page) case .Ok);
		Test.Assert(page.Animation && actions.IsChecked(SceneActionIds.AnimationPanel, page));
		Test.Assert(actions.Execute(SceneActionIds.AnimationPanel, page) case .Ok);
		Test.Assert(!page.Animation);

		// Gizmo: disabled without a gizmo (a headless page); with one, the mode toggles are
		// exclusive and the space toggle flips.
		Test.Assert(!actions.IsEnabled(SceneActionIds.GizmoTranslate, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.GizmoWorldSpace, page));
		let gizmos = scope GizmoController(page.EditContext);
		page.GizmosSeen = gizmos;
		Test.Assert(actions.IsEnabled(SceneActionIds.GizmoTranslate, page));
		Test.Assert(actions.Execute(SceneActionIds.GizmoRotate, page) case .Ok);
		Test.Assert(gizmos.Mode == .Rotate);
		Test.Assert(actions.IsChecked(SceneActionIds.GizmoRotate, page));
		Test.Assert(!actions.IsChecked(SceneActionIds.GizmoTranslate, page));
		let worldBefore = gizmos.Space == .World;
		Test.Assert(actions.IsChecked(SceneActionIds.GizmoWorldSpace, page) == worldBefore);
		Test.Assert(actions.Execute(SceneActionIds.GizmoWorldSpace, page) case .Ok);
		Test.Assert(actions.IsChecked(SceneActionIds.GizmoWorldSpace, page) != worldBefore);
		// Vertex snap: a toggle over the gizmo's mode, off to start.
		Test.Assert(actions.Find(SceneActionIds.GizmoVertexSnap).MenuPath == "Scene/Gizmo/Vertex Snap");
		Test.Assert(!actions.IsChecked(SceneActionIds.GizmoVertexSnap, page));
		Test.Assert(actions.Execute(SceneActionIds.GizmoVertexSnap, page) case .Ok);
		Test.Assert(gizmos.VertexSnapMode && actions.IsChecked(SceneActionIds.GizmoVertexSnap, page));
		Test.Assert(actions.Execute(SceneActionIds.GizmoVertexSnap, page) case .Ok);
		Test.Assert(!gizmos.VertexSnapMode);

		// While the camera flies, W is the camera's: the mode chords refuse and the mode stays.
		page.Flying = true;
		Test.Assert(!actions.IsEnabled(SceneActionIds.GizmoTranslate, page));
		Test.Assert(actions.Execute(SceneActionIds.GizmoTranslate, page) case .Err(.NotSupported));
		Test.Assert(gizmos.Mode == .Rotate);
		page.Flying = false;
		Test.Assert(actions.Execute(SceneActionIds.GizmoTranslate, page) case .Ok);
		Test.Assert(gizmos.Mode == .Translate);
		page.GizmosSeen = null;
	}

	/// F frames the selection, eased, on a page with a viewport, and not while the camera
	/// flies (its keys are its own then).
	[Test]
	public static void FFramesTheSelectionEasedOnAPageWithAViewport()
	{
		let context = scope EditorContext();
		SceneActions.Register(context);
		let actions = context.Actions;
		Test.Assert(actions.Find(SceneActionIds.FrameSelection).MenuPath == "Scene/Frame Selection");
		Test.Assert(actions.Shortcut(SceneActionIds.FrameSelection).Key == .F);
		Test.Assert(actions.Shortcut(SceneActionIds.FrameSelection).Modifiers == .None);

		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage());
		// No viewport, or nothing selected: nothing to frame.
		Test.Assert(!actions.IsEnabled(SceneActionIds.FrameSelection, page));
		page.HasViewport = true;
		Test.Assert(!actions.IsEnabled(SceneActionIds.FrameSelection, page));

		let a = Guid.Create();
		let b = Guid.Create();
		page.EditContext.EntitySelection.Set(a);
		page.EditContext.EntitySelection.Add(b);
		Test.Assert(actions.IsEnabled(SceneActionIds.FrameSelection, page));

		page.Flying = true;
		Test.Assert(!actions.IsEnabled(SceneActionIds.FrameSelection, page));
		page.Flying = false;

		Test.Assert(actions.Execute(SceneActionIds.FrameSelection, page) case .Ok);
		Test.Assert((page.Framed.Count == 2) && (page.Framed[0] == a) && (page.Framed[1] == b));
		Test.Assert(page.FramedEased);
	}

	[Test]
	public static void TheEntityActionsActOnThePrimaryLockWhileSimulatingAndReachThePrefabFlows()
	{
		let context = scope EditorContext();
		SceneActions.Register(context);
		let actions = context.Actions;
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage());
		let edit = page.EditContext;

		// No selection: create at the root is the one entity action on; the rest need a primary.
		Test.Assert(actions.IsEnabled(SceneActionIds.EntityCreate, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityCreateChild, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityDuplicate, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityDelete, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityCopy, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityCreatePrefab, page));
		Test.Assert(actions.IsEnabled(SceneActionIds.EntitySpawnPrefab, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntitySpawnPrefabAsChild, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.PrefabApply, page));
		Test.Assert(actions.Execute(SceneActionIds.EntityCreate, page) case .Ok);
		Test.Assert(edit.Scene.EntityCount == 1);
		// CreateEntity selects what it made: the primary is the new root.
		Test.Assert(!edit.EntitySelection.IsEmpty);
		let root = edit.EntitySelection.Primary;
		Test.Assert(actions.IsEnabled(SceneActionIds.EntityCreateChild, page));
		Test.Assert(actions.Execute(SceneActionIds.EntityCreateChild, page) case .Ok);
		Test.Assert(edit.Scene.EntityCount == 2);
		let child = edit.EntitySelection.Primary;
		Test.Assert(edit.Scene.GetParent(edit.Resolve(child)) == edit.Resolve(root));

		// Duplicate the root's subtree beside it.
		edit.EntitySelection.Set(root);
		Test.Assert(actions.Execute(SceneActionIds.EntityDuplicate, page) case .Ok);
		Test.Assert(edit.Scene.EntityCount == 4);

		// Copy and paste ride the editor's clipboard: paste at the root and as a child.
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityPaste, page), "nothing on the clipboard yet");
		edit.EntitySelection.Set(child);
		Test.Assert(actions.Execute(SceneActionIds.EntityCopy, page) case .Ok);
		Test.Assert(!context.ClipboardData("entities").IsEmpty);
		Test.Assert(actions.IsEnabled(SceneActionIds.EntityPaste, page));
		Test.Assert(actions.Execute(SceneActionIds.EntityPaste, page) case .Ok);
		Test.Assert(edit.Scene.EntityCount == 5);
		edit.EntitySelection.Set(root);
		Test.Assert(actions.Execute(SceneActionIds.EntityPasteAsChild, page) case .Ok);
		Test.Assert(edit.Scene.EntityCount == 6);

		// The prefab flows reach the page with the primary (or its parent role). A paste selects
		// what it pasted, so the root is selected again first.
		edit.EntitySelection.Set(root);
		Test.Assert(actions.Execute(SceneActionIds.EntityCreatePrefab, page) case .Ok);
		Test.Assert(page.PrefabFrom == root);
		Test.Assert(actions.Execute(SceneActionIds.EntitySpawnPrefabAsChild, page) case .Ok);
		Test.Assert(page.SpawnParent == root);
		Test.Assert(actions.Execute(SceneActionIds.EntitySpawnPrefab, page) case .Ok);
		Test.Assert(page.SpawnParent == .());
		Test.Assert(page.Spawns == 2);
		// A plain entity is no prefab instance member: the instance actions stay off.
		Test.Assert(!actions.IsEnabled(SceneActionIds.PrefabApply, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.PrefabRevert, page));

		// Delete removes the primary's subtree: the root and its two children go.
		edit.EntitySelection.Set(root);
		Test.Assert(actions.Execute(SceneActionIds.EntityDelete, page) case .Ok);
		Test.Assert(edit.Scene.EntityCount == 3);

		// Simulating locks every edit: the entity actions are off, the simulate ones on.
		Test.Assert(actions.Execute(SceneActionIds.SimulateStart, page) case .Ok);
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntityCreate, page));
		Test.Assert(!actions.IsEnabled(SceneActionIds.EntitySpawnPrefab, page));
		Test.Assert(actions.IsEnabled(SceneActionIds.SimulateStop, page));
		Test.Assert(actions.Execute(SceneActionIds.EntityCreate, page) case .Err(.NotSupported));
		Test.Assert(actions.Execute(SceneActionIds.SimulateStop, page) case .Ok);
		Test.Assert(actions.IsEnabled(SceneActionIds.EntityCreate, page));

		// The hierarchy builds its menu items from the same declarations over the page.
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		Test.Assert(actions.AppendActionItems(menu, page, SceneActionIds.EntityCreate, SceneActionIds.EntityDelete, "nobody.home") == 2);
		Test.Assert(menu.ItemCount == 2);
		Test.Assert(menu.ItemAt(0).Label == "Create Entity");
		Test.Assert(menu.ItemAt(0).Enabled);
		Test.Assert(menu.ItemAt(1).Label == "Delete");
		Test.Assert(!menu.ItemAt(1).Enabled, "nothing selected after the delete");
		let before = edit.Scene.EntityCount;
		menu.ItemAt(0).Action();
		Test.Assert(edit.Scene.EntityCount == before + 1);
	}

	/// Set as Project Thumbnail asks the page for its clean thumbnail capture (the scene
	/// without the editor's overlays), and needs a project for the launcher to show it in.
	[Test]
	public static void SetAsProjectThumbnailAsksThePageForItsCleanCapture()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_scene_actions_thumbnail_project", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		SceneActions.Register(context);
		let actions = context.Actions;
		Test.Assert(actions.Find(SceneActionIds.SetProjectThumbnail) != null);
		Test.Assert(actions.Find(SceneActionIds.SetProjectThumbnail).ReadOnly);
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage());
		page.HasViewport = true;

		// No project: no launcher to show the picture.
		Test.Assert(!actions.IsEnabled(SceneActionIds.SetProjectThumbnail, page));

		// With one, the page takes the capture, not a plain viewport capture of what the
		// viewport shows.
		context.SetProject(project);
		defer context.SetProject(null);
		Test.Assert(actions.IsEnabled(SceneActionIds.SetProjectThumbnail, page));
		Test.Assert(actions.Execute(SceneActionIds.SetProjectThumbnail, page) case .Ok);
		Test.Assert(page.ThumbnailRequests == 1);
	}
}
