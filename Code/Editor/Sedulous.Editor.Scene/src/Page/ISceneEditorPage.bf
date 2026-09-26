namespace Sedulous.Editor.Scene;

/// What a scene (or prefab) page lets the rest of the editor act through, page by page: its
/// SceneEditContext (the live scene, the command stack, the entity selection) and the edit mode
/// Simulate control. A module holding an EditorPage reaches it with `page as ISceneEditorPage`,
/// knowing nothing of the page class.
///
/// This is the page level surface, the one the page gives its OWN tools. The framework level
/// one, ViewportToolHostContext, is what a domain's provider tools receive, limited to
/// framework types; it is not reachable from here on purpose. Simulation is a page concern (it
/// locks the command stack and drives the toolbar), so its control is part of this surface, not
/// of the edit context.
interface ISceneEditorPage
{
	/// This page's scene mutation mediator: its live scene, its command stack, its entity
	/// selection. Every edit goes through it as an undoable command.
	SceneEditContext EditContext { get; }

	/// Edit mode Simulate: snapshot, run the live scene, restore on stop. Start and stop are
	/// no-ops when already in that state.
	void StartSimulation();
	void StopSimulation();
	void PauseSimulation(bool paused);
	bool IsSimulating { get; }
}
