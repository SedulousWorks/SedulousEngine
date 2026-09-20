using System;
using Sedulous.Settings;

namespace Sedulous.Editor.Scene;

/// Reading and upserting a clip's preview rig in a settings store.
static class ClipPreviewPrefs
{
	/// True, with the stored rig, when `asset` has one; false leaves the outs untouched.
	public static bool Load(Settings store, Guid asset, ref Guid skeleton, ref Guid mesh)
	{
		if ((store == null) || asset.IsNil)
			return false;
		if (let section = store.Find<ClipPreviewSettings>())
		{
			for (let pref in section.Prefs)
			{
				if (pref.Asset == asset)
				{
					skeleton = pref.Skeleton;
					mesh = pref.Mesh;
					return true;
				}
			}
		}
		return false;
	}

	/// Upserts `asset`'s rig; false, nothing written, for a null store or a nil asset.
	public static bool Save(Settings store, Guid asset, Guid skeleton, Guid mesh)
	{
		if ((store == null) || asset.IsNil)
			return false;
		let section = store.Section<ClipPreviewSettings>();
		for (let pref in section.Prefs)
		{
			if (pref.Asset == asset)
			{
				pref.Skeleton = skeleton;
				pref.Mesh = mesh;
				store.MarkChanged<ClipPreviewSettings>();
				return true;
			}
		}
		let pref = new ClipPreviewPref();
		pref.Asset = asset;
		pref.Skeleton = skeleton;
		pref.Mesh = mesh;
		section.Prefs.Add(pref);
		store.MarkChanged<ClipPreviewSettings>();
		return true;
	}
}
