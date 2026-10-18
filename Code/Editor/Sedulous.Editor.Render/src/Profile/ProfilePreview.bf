using System;
using Sedulous.Render.Pipeline;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Editor.Render;

/// A profile's values shown on a scene: the profile page's preview, on its built-in scene or on
/// one of the project's.
static class ProfilePreview
{
	/// Gives `scene`'s settings block the values of `asset`, the block being the one whose
	/// settings type is the profile's values type, and binds its references through `resources`
	/// when given. False when there is no such block.
	public static bool ApplyToScene(SettingsProfileAsset asset, Sedulous.Scene.Scene scene, ResourceManager resources)
	{
		for (let system in scene.Systems)
		{
			if ((system.SettingsType == null) || (system.SettingsType != asset.ValuesType))
				continue;
			asset.CopyValuesInto(system.SettingsInstance);
			if (resources != null)
				system.ResolveResources(resources); // the sky texture, the grading LUT
			return true;
		}
		return false;
	}

	/// As ApplyToScene, on a scene loaded to preview the profile on: the block first goes back to
	/// its own values, so a scene that takes this profile (or another) by reference shows the
	/// values being edited rather than the cooked ones.
	public static bool PreviewInScene(SettingsProfileAsset asset, Sedulous.Scene.Scene scene, ResourceManager resources)
	{
		for (let system in scene.Systems)
		{
			if ((system.SettingsType != null) && (system.SettingsType == asset.ValuesType))
				system.UseSettingsProfile(Guid.Empty);
		}
		return ApplyToScene(asset, scene, resources);
	}
}
