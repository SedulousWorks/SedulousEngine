using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Render;

/// The scene a profile is previewed on (nil: the built-in scene).
[Serializable(1)]
class ProfilePreviewPref
{
	public Guid Profile = .();
	public Guid Scene = .();
}

/// The profile pages' preview choices, a section of the per project editor store: page local,
/// not the profiles' data.
[Serializable(1)]
class ProfilePreviewSettings
{
	public List<ProfilePreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);

	/// The scene `profile` is previewed on; nil when it has none (the built-in scene).
	public Guid SceneFor(Guid profile)
	{
		for (let pref in Prefs)
		{
			if (pref.Profile == profile)
				return pref.Scene;
		}
		return .();
	}

	/// Remembers `scene` as the one `profile` is previewed on.
	public void Set(Guid profile, Guid scene)
	{
		for (let pref in Prefs)
		{
			if (pref.Profile == profile)
			{
				pref.Scene = scene;
				return;
			}
		}
		let pref = new ProfilePreviewPref();
		pref.Profile = profile;
		pref.Scene = scene;
		Prefs.Add(pref);
	}
}
