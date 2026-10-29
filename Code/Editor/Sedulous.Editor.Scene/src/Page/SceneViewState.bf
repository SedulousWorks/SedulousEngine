using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Settings;
using Sedulous.Editor.Camera;

namespace Sedulous.Editor.Scene;

// Where a scene was left, kept per scene in the project's editor settings (SceneViewPref): the
// overlays, the camera, the selection and the page's panes. The page reads it when it opens and
// writes the whole of it on a toggle and when it closes, so saving one part never brings back
// another's default. The panes are one splitter of three on the GUI (hierarchy, viewport,
// inspector) where the prefs keep the old page's nested ratios (hierarchy | the rest, then viewport
// | inspector), so the weights convert both ways and the prefs' format stands; the bottom dock's
// ratio is kept as it was. Out of the page's class (Raptor's editor-gui spec, 5.3, layer 2).

/// The page's three panes' shares of its width.
struct ScenePaneWeights
{
	public float Hierarchy = 0.2f;
	public float Viewport = 0.56f;
	public float Inspector = 0.24f;

	public this() {}

	public this(float hierarchy, float viewport, float inspector)
	{
		Hierarchy = hierarchy;
		Viewport = viewport;
		Inspector = inspector;
	}
}

static class SceneViewState
{
	/// The weights from the prefs' nested ratios: `hierarchy` of the whole, then `inspector` (the
	/// viewport's share) of the rest.
	public static ScenePaneWeights WeightsFromSplits(float hierarchy, float inspector)
	{
		let h = Math.Clamp(hierarchy, 0.0f, 1.0f);
		let i = Math.Clamp(inspector, 0.0f, 1.0f);
		return .(h, (1.0f - h) * i, (1.0f - h) * (1.0f - i));
	}

	/// The prefs' nested ratios from the weights (any scale).
	public static void SplitsFromWeights(ScenePaneWeights weights, out float hierarchy, out float inspector)
	{
		let total = weights.Hierarchy + weights.Viewport + weights.Inspector;
		hierarchy = (total > 0.0f) ? weights.Hierarchy / total : 0.2f;
		let rest = weights.Viewport + weights.Inspector;
		inspector = (rest > 0.0f) ? weights.Viewport / rest : 0.72f;
	}

	/// This scene's overlays as saved; `current` where nothing is (an unsaved scene, a nil id).
	public static SceneOverlaySettings LoadOverlays(Settings store, Guid scene, SceneOverlaySettings current)
		=> SceneViewPrefs.Load(store, scene, current);

	/// The whole pref as the page has it now: the overlays, the camera, the selection, where the
	/// tool panel was moved (null: under the chips) and, when given, the panes. False, nothing
	/// written, for a null store or a nil scene.
	public static bool Save(Settings store, Guid scene, SceneOverlaySettings overlays, EditorCamera camera,
		ScenePaneWeights? panes, Span<Guid> selection, Float2? toolPanelPlace = null)
	{
		if (!SceneViewPrefs.Save(store, scene, overlays))
			return false;
		SceneViewSplits? splits = null;
		if (panes.HasValue)
		{
			// The bottom dock's ratio as it was: the GUI page has no dock yet.
			let stored = SceneViewPrefs.Find(store, scene);
			var kept = ((stored != null) && stored.HasSplits) ? stored.Splits : SceneViewSplits();
			SplitsFromWeights(panes.Value, out kept.Hierarchy, out kept.Inspector);
			splits = kept;
		}
		let view = SceneViewCamera(camera.Position, camera.Yaw, camera.Pitch, camera.FocusDistance, camera.Orthographic);
		return SceneViewPrefs.SaveView(store, scene, view, selection, splits, toolPanelPlace);
	}

	/// The camera where the pref left it; false when no page saved one (the caller's framing stands).
	public static bool RestoreCamera(SceneViewPref pref, EditorCamera camera)
	{
		if ((pref == null) || !pref.HasCamera)
			return false;
		camera.Position = pref.Camera.Position;
		camera.Yaw = pref.Camera.Yaw;
		camera.Pitch = pref.Camera.Pitch;
		camera.FocusDistance = pref.Camera.FocusDistance;
		camera.SetOrthographic(pref.Camera.Orthographic);
		return true;
	}

	/// The saved selection's ids still in `scene`, appended to `outLive`: one deleted since, or
	/// spawned by a Simulate and selected at close, never comes back as a ghost.
	public static void LiveSelection(SceneViewPref pref, Sedulous.Scene.Scene scene, List<Guid> outLive)
	{
		if (pref == null)
			return;
		for (let id in pref.Selection)
		{
			if (scene.FindEntity(id).IsAssigned)
				outLive.Add(id);
		}
	}
}
