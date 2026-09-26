using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The ids, in one place: the toolbar and the hierarchy name what they show by these.
static class SceneActionIds
{
	public const String SimulateStart = "scene.simulate.start";
	public const String SimulatePause = "scene.simulate.pause";
	public const String SimulateStop = "scene.simulate.stop";
	public const String GizmoTranslate = "scene.gizmo.translate";
	public const String GizmoRotate = "scene.gizmo.rotate";
	public const String GizmoScale = "scene.gizmo.scale";
	public const String GizmoWorldSpace = "scene.gizmo.worldSpace";
	public const String Markers = "scene.view.markers";
	public const String EntityCreate = "scene.entity.create";
	public const String EntityCreateChild = "scene.entity.createChild";
	public const String EntityDuplicate = "scene.entity.duplicate";
	public const String EntityDelete = "scene.entity.delete";
	public const String EntityCopy = "scene.entity.copy";
	public const String EntityPaste = "scene.entity.paste";
	public const String EntityPasteAsChild = "scene.entity.pasteAsChild";
	public const String EntityCreatePrefab = "scene.entity.createPrefab";
	public const String EntitySpawnPrefab = "scene.entity.spawnPrefab";
	public const String EntitySpawnPrefabAsChild = "scene.entity.spawnPrefabAsChild";
	public const String PrefabApply = "scene.prefab.apply";
	public const String PrefabRevert = "scene.prefab.revert";
}

/// The scene editor's actions, declared once (Register, from SceneEditor.Register) and served
/// everywhere from the registry: the Scene menu and the chords come from these declarations,
/// the scene page's toolbar and the hierarchy's context menus execute through them, and the MCP
/// action bridge reads them. Every action binds through the interface the subject page
/// publishes (`page as ISceneEditorPage`): disabled on any other page, acting on THAT page's
/// simulation, gizmo, markers or entity selection. The entity actions act on the selection's
/// primary - what the hierarchy's right-click selected, what the viewport picked - so they are
/// nullary like every action.
static class SceneActions
{
	/// The scene page behind the subject, when it is one and is not simulating (edits are
	/// locked meanwhile); the entity actions bind through this.
	private static ISceneEditorPage EditablePage(EditorPage page)
	{
		let scene = page as ISceneEditorPage;
		return ((scene != null) && !scene.IsSimulating) ? scene : null;
	}

	/// The primary selected entity of an editable page; nil when none.
	private static Guid PrimaryOf(EditorPage page)
	{
		let scene = EditablePage(page);
		if ((scene == null) || scene.EditContext.EntitySelection.IsEmpty)
			return .();
		return scene.EditContext.EntitySelection.Primary;
	}

	/// The prefab instance root the primary selection belongs to; nil when it is no member of
	/// one (reachable from any member, acting on the whole owning instance).
	private static Guid InstanceRootOf(EditorPage page)
	{
		let scene = EditablePage(page);
		let primary = PrimaryOf(page);
		if ((scene == null) || (primary == .()))
			return .();
		PrefabMemberInfo member = ?;
		return PrefabOverrides.FindMember(scene.EditContext.Scene, primary, out member) ? member.State.RootEntityId : .();
	}

	/// Declares the scene editor's actions on the context's registry. `context` is captured for
	/// the cross-page entity clipboard.
	public static void Register(EditorContext context)
	{
		let actions = context.Actions;

		// ---- Simulate: snapshot, run, restore ----
		{
			let d = new EditorActionDeclaration(SceneActionIds.SimulateStart, "Play", "Start the page's edit-mode Simulate from a snapshot (Stop restores it)", "Scene/Simulate/Play", 100);
			d.Enabled = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && !scene.IsSimulating;
				};
			d.Execute = new (page) => { (page as ISceneEditorPage).StartSimulation(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.SimulatePause, "Pause", "Hold the running Simulate; again resumes", "Scene/Simulate/Pause", 101);
			d.Kind = .Toggle;
			d.Enabled = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && scene.IsSimulating;
				};
			d.Checked = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && scene.IsPaused;
				};
			d.Execute = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					scene.PauseSimulation(!scene.IsPaused);
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.SimulateStop, "Stop", "Stop the Simulate and restore the snapshot", "Scene/Simulate/Stop", 102);
			d.Enabled = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && scene.IsSimulating;
				};
			d.Execute = new (page) => { (page as ISceneEditorPage).StopSimulation(); };
			actions.Register(d);
		}

		// ---- Gizmo: the transform mode as three toggles, the space as one ----
		GizmoMode(actions, SceneActionIds.GizmoTranslate, "Translate", "Move the selection with the gizmo", "Scene/Gizmo/Translate", 100, .Translate, .W);
		GizmoMode(actions, SceneActionIds.GizmoRotate, "Rotate", "Rotate the selection with the gizmo", "Scene/Gizmo/Rotate", 101, .Rotate, .E);
		GizmoMode(actions, SceneActionIds.GizmoScale, "Scale", "Scale the selection with the gizmo", "Scene/Gizmo/Scale", 102, .Scale, .R);
		{
			let d = new EditorActionDeclaration(SceneActionIds.GizmoWorldSpace, "World Space", "The gizmo's axes in world space (off: the selection's local space)", "Scene/Gizmo/World Space", 200);
			d.Kind = .Toggle;
			d.Enabled = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && (scene.Gizmos != null);
				};
			d.Checked = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && (scene.Gizmos != null) && (scene.Gizmos.Space == .World);
				};
			d.Execute = new (page) =>
				{
					let gizmos = (page as ISceneEditorPage).Gizmos;
					gizmos.SetSpace((gizmos.Space == .World) ? .Local : .World);
				};
			actions.Register(d);
		}

		// ---- View ----
		{
			let d = new EditorActionDeclaration(SceneActionIds.Markers, "Entity Markers", "Show every entity's marker in the viewport, not only the selected ones", "Scene/Entity Markers", 300);
			d.Kind = .Toggle;
			d.Enabled = new (page) => (page as ISceneEditorPage) != null;
			d.Checked = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					return (scene != null) && scene.MarkersShown;
				};
			d.Execute = new (page) =>
				{
					let scene = page as ISceneEditorPage;
					scene.SetMarkersShown(!scene.MarkersShown);
				};
			actions.Register(d);
		}

		// ---- Entities, over the selection's primary; edits are locked while simulating ----
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityCreate, "Create Entity", "A new entity at the scene root", "Scene/Entity/Create Entity", 100);
			d.Enabled = new (page) => EditablePage(page) != null;
			d.Execute = new (page) => { EditablePage(page).EditContext.CreateEntity("Entity"); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityCreateChild, "Create Child", "A new entity under the selected one", "Scene/Entity/Create Child", 101);
			d.Enabled = new (page) => PrimaryOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).EditContext.CreateEntity("Entity", PrimaryOf(page)); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityDuplicate, "Duplicate", "Duplicate the selected entity's subtree beside it", "Scene/Entity/Duplicate", 200);
			d.Shortcut = .(.D, .Ctrl);
			d.Enabled = new (page) => PrimaryOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).EditContext.DuplicateEntity(PrimaryOf(page)); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityDelete, "Delete", "Delete the selected entity and its subtree", "Scene/Entity/Delete", 201);
			d.Shortcut = .(.Delete);
			d.Enabled = new (page) => PrimaryOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).EditContext.DestroyEntity(PrimaryOf(page)); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityCopy, "Copy", "Copy the selected entity's subtree to the editor's clipboard", "Scene/Entity/Copy", 300);
			d.Enabled = new (page) => PrimaryOf(page) != .();
			d.Execute = new [=context](page) =>
				{
					let blob = scope List<uint8>();
					EditablePage(page).EditContext.CopyEntity(PrimaryOf(page), blob);
					if (!blob.IsEmpty)
						context.SetClipboard("entities", blob);
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityPaste, "Paste", "Paste the clipboard's entities at the scene root", "Scene/Entity/Paste", 301);
			d.Enabled = new [=context](page) => (EditablePage(page) != null) && !context.ClipboardData("entities").IsEmpty;
			d.Execute = new [=context](page) => { EditablePage(page).EditContext.PasteEntities(context.ClipboardData("entities")); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityPasteAsChild, "Paste as Child", "Paste the clipboard's entities under the selected one", "Scene/Entity/Paste as Child", 302);
			d.Enabled = new [=context](page) => (PrimaryOf(page) != .()) && !context.ClipboardData("entities").IsEmpty;
			d.Execute = new [=context](page) => { EditablePage(page).EditContext.PasteEntities(context.ClipboardData("entities"), PrimaryOf(page)); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntityCreatePrefab, "Create Prefab from Selection", "A prefab asset from the selected entity's subtree, the subtree its first instance", "Scene/Entity/Create Prefab from Selection", 400);
			d.Enabled = new (page) => PrimaryOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).CreatePrefabFromEntity(PrimaryOf(page)); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntitySpawnPrefab, "Spawn Prefab...", "Pick a prefab and spawn an instance at the scene root", "Scene/Entity/Spawn Prefab...", 401);
			d.Enabled = new (page) => EditablePage(page) != null;
			d.Execute = new (page) => { EditablePage(page).PickAndSpawnPrefab(.()); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.EntitySpawnPrefabAsChild, "Spawn Prefab as Child", "Pick a prefab and spawn an instance under the selected entity", "Scene/Entity/Spawn Prefab as Child", 402);
			d.Enabled = new (page) => PrimaryOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).PickAndSpawnPrefab(PrimaryOf(page)); };
			actions.Register(d);
		}

		// ---- Prefab instances, from any member of one ----
		{
			let d = new EditorActionDeclaration(SceneActionIds.PrefabApply, "Apply to Prefab", "Write the selected instance's changes back to its prefab asset", "Scene/Prefab/Apply to Prefab", 100);
			d.Enabled = new (page) => InstanceRootOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).ApplyInstanceToPrefab(InstanceRootOf(page)); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration(SceneActionIds.PrefabRevert, "Revert Instance", "Discard the selected instance's changes, back to its prefab", "Scene/Prefab/Revert Instance", 101);
			d.Enabled = new (page) => InstanceRootOf(page) != .();
			d.Execute = new (page) => { EditablePage(page).RevertInstance(InstanceRootOf(page)); };
			actions.Register(d);
		}
	}

	private static void GizmoMode(EditorActionRegistry actions, StringView id, StringView label, StringView description, StringView menuPath, int32 order, Sedulous.Editor.Scene.GizmoMode mode, Sedulous.UI.KeyCode key)
	{
		let d = new EditorActionDeclaration(id, label, description, menuPath, order);
		d.Kind = .Toggle;
		d.Shortcut = .(key);
		// Not while the camera flies: W is the camera's then, and a mode switch mid-flight
		// would surprise.
		d.Enabled = new (page) =>
			{
				let scene = page as ISceneEditorPage;
				return (scene != null) && (scene.Gizmos != null) && !scene.CameraOwnsInput;
			};
		d.Checked = new [=mode](page) =>
			{
				let scene = page as ISceneEditorPage;
				return (scene != null) && (scene.Gizmos != null) && (scene.Gizmos.Mode == mode);
			};
		d.Execute = new [=mode](page) => { (page as ISceneEditorPage).Gizmos.SetMode(mode); };
		actions.Register(d);
	}
}
