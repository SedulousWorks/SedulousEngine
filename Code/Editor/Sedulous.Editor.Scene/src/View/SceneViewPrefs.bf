using System;
using Sedulous.Settings;

namespace Sedulous.Editor.Scene;

/// Reading and upserting a scene's view state in a settings store.
static class SceneViewPrefs
{
	/// The stored state for `scene`, or `fallback` (the page's current state) when nothing
	/// was saved, the store is absent, or the scene has no identity yet.
	public static SceneViewState Load(Settings store, Guid scene, SceneViewState fallback)
	{
		if ((store == null) || scene.IsNil)
			return fallback;
		if (let section = store.Find<SceneViewSettings>())
		{
			for (let pref in section.Prefs)
			{
				if (pref.Scene == scene)
					return pref.State;
			}
		}
		return fallback;
	}

	/// Upserts `scene`'s state; false, nothing written, for a null store or a nil scene.
	public static bool Save(Settings store, Guid scene, SceneViewState state)
	{
		if ((store == null) || scene.IsNil)
			return false;
		let section = store.Section<SceneViewSettings>();
		for (let pref in section.Prefs)
		{
			if (pref.Scene == scene)
			{
				pref.Set(scene, state);
				store.MarkChanged<SceneViewSettings>();
				return true;
			}
		}
		let pref = new SceneViewPref();
		pref.Set(scene, state);
		section.Prefs.Add(pref);
		store.MarkChanged<SceneViewSettings>();
		return true;
	}
}
