using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;

namespace Sedulous.Editor.Project;

/// Plugin packages found on disk by their manifests' ids.
static class PluginPackages
{
	/// The package folder under `packagesRoot` whose Plugin.xml is plugin `id`'s.
	public static bool FindPackage(StringView packagesRoot, StringView id, String outDir)
	{
		if (packagesRoot.IsEmpty)
			return false;
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ListDirectory(packagesRoot, scope [&](name, isDirectory) =>
			{
				if (isDirectory)
					names.Add(new .(name));
			});
		for (let name in names)
		{
			let dir = PathJoin(packagesRoot, name, .. scope .());
			let manifest = scope PluginManifest();
			if ((PluginManifest.Load(dir, manifest) case .Ok) && (manifest.Id == id))
			{
				outDir.Set(dir);
				return true;
			}
		}
		return false;
	}
}
