using System;

namespace Sedulous.Editor.Scene;

/// What a scene (or prefab) page lets the rest of the editor act through, page by page: its
/// SceneEditContext (the live scene, the command stack, the entity selection) and the edit mode
/// Simulate control. A module holding an EditorPage reaches it with `page as ISceneEditorPage`,
/// knowing nothing of the page class.
///
/// This is the page level surface, the one the page gives its OWN tools. The framework level
/// one, ViewportToolHostContext, is what a domain's provider tools receive, limited to
/// framework types; it is not reachable from here on purpose. Simulation, the gizmo, the markers
/// overlay and the prefab flows are page concerns (they lock the command stack, drive the
/// toolbar, open the page's dialogs), so their control is part of this surface, not of the edit
/// context; the scene editor's actions bind through it.
interface ISceneEditorPage
{
	/// This page's scene mutation mediator: its live scene, its command stack, its entity
	/// selection. Every edit goes through it as an undoable command.
	SceneEditContext EditContext { get; }

	/// Edit mode Simulate: snapshot, run the live scene, restore on stop. Start and stop are
	/// no-ops when already in that state; pause holds a running simulation.
	void StartSimulation();
	void StopSimulation();
	void PauseSimulation(bool paused);
	bool IsSimulating { get; }
	bool IsPaused { get; }

	/// The select tool's gizmo (mode, space); null on a page without a viewport.
	GizmoController Gizmos { get; }

	/// True while the viewport camera owns the pointer and keys (the right button or Alt held,
	/// or a capture): W flies the camera then, so the gizmo mode actions and their chords refuse.
	bool CameraOwnsInput { get; }

	/// The entity markers overlay: every entity's marker in the viewport, not only the selected
	/// ones.
	bool MarkersShown { get; }
	void SetMarkersShown(bool shown);

	/// The prefab flows the page owns (they open the page's dialogs and write assets): a prefab
	/// asset from an entity subtree; an instance spawned under `parent` (nil is the scene root)
	/// through the asset picker; an instance's deltas written back to its prefab; an instance's
	/// deltas discarded.
	void CreatePrefabFromEntity(Guid entity);
	void PickAndSpawnPrefab(Guid parent);
	void ApplyInstanceToPrefab(Guid root);
	void RevertInstance(Guid root);
}
