using System;
using Sedulous.Settings;

namespace Sedulous.Editor.Scene;

/// Reading and upserting a mesh's preview material in a settings store.
static class MeshPreviewPrefs
{
	/// The stored material for `asset`, nil when none was saved.
	public static Guid Load(Settings store, Guid asset)
	{
		if ((store == null) || asset.IsNil)
			return .();
		if (let section = store.Find<MeshPreviewSettings>())
		{
			for (let pref in section.Prefs)
			{
				if (pref.Asset == asset)
					return pref.Material;
			}
		}
		return .();
	}

	/// Upserts `asset`'s material; false, nothing written, for a null store or a nil asset.
	public static bool Save(Settings store, Guid asset, Guid material)
	{
		if ((store == null) || asset.IsNil)
			return false;
		let section = store.Section<MeshPreviewSettings>();
		for (let pref in section.Prefs)
		{
			if (pref.Asset == asset)
			{
				pref.Material = material;
				store.MarkChanged<MeshPreviewSettings>();
				return true;
			}
		}
		let pref = new MeshPreviewPref();
		pref.Asset = asset;
		pref.Material = material;
		section.Prefs.Add(pref);
		store.MarkChanged<MeshPreviewSettings>();
		return true;
	}
}
