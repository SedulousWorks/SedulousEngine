using System;
using Sedulous.Settings;

namespace Sedulous.Editor.Scene;

/// Reading and upserting a material's preview choice in a settings store.
static class MaterialPreviewPrefs
{
	/// True, with the stored choice, when `asset` has one; false leaves the outs untouched.
	public static bool Load(Settings store, Guid asset, ref uint32 shape, ref Guid mesh)
	{
		if ((store == null) || asset.IsNil)
			return false;
		if (let section = store.Find<MaterialPreviewSettings>())
		{
			for (let pref in section.Prefs)
			{
				if (pref.Asset == asset)
				{
					shape = pref.Shape;
					mesh = pref.Mesh;
					return true;
				}
			}
		}
		return false;
	}

	/// Upserts `asset`'s choice; false, nothing written, for a null store or a nil asset.
	public static bool Save(Settings store, Guid asset, uint32 shape, Guid mesh)
	{
		if ((store == null) || asset.IsNil)
			return false;
		let section = store.Section<MaterialPreviewSettings>();
		for (let pref in section.Prefs)
		{
			if (pref.Asset == asset)
			{
				pref.Shape = shape;
				pref.Mesh = mesh;
				store.MarkChanged<MaterialPreviewSettings>();
				return true;
			}
		}
		let pref = new MaterialPreviewPref();
		pref.Asset = asset;
		pref.Shape = shape;
		pref.Mesh = mesh;
		section.Prefs.Add(pref);
		store.MarkChanged<MaterialPreviewSettings>();
		return true;
	}
}
