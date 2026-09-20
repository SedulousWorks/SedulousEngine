using System;
using Sedulous.Settings;

namespace Sedulous.Editor.Scene;

/// Reading and upserting a graph's preview rig in a settings store.
static class GraphPreviewPrefs
{
	/// True, with the stored rig, when `asset` has one; false leaves the outs untouched.
	public static bool Load(Settings store, Guid asset, ref Guid skeleton, ref Guid mesh)
	{
		if ((store == null) || asset.IsNil)
			return false;
		if (let section = store.Find<GraphPreviewSettings>())
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
		let section = store.Section<GraphPreviewSettings>();
		for (let pref in section.Prefs)
		{
			if (pref.Asset == asset)
			{
				pref.Skeleton = skeleton;
				pref.Mesh = mesh;
				store.MarkChanged<GraphPreviewSettings>();
				return true;
			}
		}
		let pref = new GraphPreviewPref();
		pref.Asset = asset;
		pref.Skeleton = skeleton;
		pref.Mesh = mesh;
		section.Prefs.Add(pref);
		store.MarkChanged<GraphPreviewSettings>();
		return true;
	}
}
