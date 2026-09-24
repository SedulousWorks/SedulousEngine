using System;
using System.Collections;
using Sedulous.Settings;

namespace Sedulous.Editor.Scene;

/// Reading and upserting a scene's view state in a settings store.
static class SceneViewPrefs
{
	/// The stored pref for `scene`, or null when nothing was saved, the store is absent, or
	/// the scene has no identity yet.
	public static SceneViewPref Find(Settings store, Guid scene)
	{
		if ((store == null) || scene.IsNil)
			return null;
		if (let section = store.Find<SceneViewSettings>())
		{
			for (let pref in section.Prefs)
			{
				if (pref.Scene == scene)
					return pref;
			}
		}
		return null;
	}

	/// The stored state for `scene`, or `fallback` (the page's current state) when nothing
	/// was saved, the store is absent, or the scene has no identity yet.
	public static SceneViewState Load(Settings store, Guid scene, SceneViewState fallback)
	{
		if (let pref = Find(store, scene))
			return pref.State;
		return fallback;
	}

	/// Upserts `scene`'s state; false, nothing written, for a null store or a nil scene.
	public static bool Save(Settings store, Guid scene, SceneViewState state)
	{
		let pref = Upsert(store, scene);
		if (pref == null)
			return false;
		pref.Set(scene, state);
		store.MarkChanged<SceneViewSettings>();
		return true;
	}

	/// Upserts `scene`'s camera and selection, leaving the view toggles alone.
	///
	/// Written when a page closes, so the next open comes back where the scene was left.
	public static bool SaveView(Settings store, Guid scene, SceneViewCamera camera, Span<Guid> selection)
	{
		let pref = Upsert(store, scene);
		if (pref == null)
			return false;
		pref.Scene = scene;
		pref.HasCamera = true;
		pref.Camera = camera;
		pref.Selection.Clear();
		for (let id in selection)
			pref.Selection.Add(id);
		store.MarkChanged<SceneViewSettings>();
		return true;
	}

	/// The entry for `scene`, made if the section has none; null for a null store or a nil
	/// scene. The caller marks the section changed once it has written.
	private static SceneViewPref Upsert(Settings store, Guid scene)
	{
		if ((store == null) || scene.IsNil)
			return null;
		let section = store.Section<SceneViewSettings>();
		for (let pref in section.Prefs)
		{
			if (pref.Scene == scene)
				return pref;
		}
		let pref = new SceneViewPref();
		pref.Scene = scene;
		section.Prefs.Add(pref);
		return pref;
	}
}
