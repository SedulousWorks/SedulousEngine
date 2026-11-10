using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Runtime;

namespace Sedulous.Editor.Project;

/// What the project's plugins mean for an export: the refusals, and the plugins' deploy files
/// beside the player.
static class ExportPlugins
{
	/// The manifest of the plugin `entry` names, from where its files are (PackageDir). False when
	/// there is none.
	public static bool FindManifest(EditorProject project, StringView sdk, EnabledPlugin entry, PluginManifest outManifest)
	{
		let dir = PackageDir(project, sdk, entry, .. scope .());
		if (dir.IsEmpty)
			return false;
		return (PluginManifest.Load(dir, outManifest) case .Ok) && (outManifest.Id == entry.Id);
	}

	/// Where `entry`'s plugin's files are: the project's package for an entry with a path, else the
	/// package of the engine SDK `sdk` (its Code/Plugins) whose manifest is the plugin's. Empty for
	/// none.
	public static void PackageDir(EditorProject project, StringView sdk, EnabledPlugin entry, String outDir)
	{
		outDir.Clear();
		if (!entry.Path.IsEmpty)
		{
			PathJoin(project.Directory, entry.Path, outDir);
			return;
		}
		if (sdk.IsEmpty)
			return;
		PluginPackages.FindPackage(PathJoin(sdk, ProjectBuild.cSdkPluginsDir, .. scope .()), entry.Id, outDir);
	}

	/// Whether the project's plugins let an export to `platform` go ahead, the ids of those
	/// enabled there appended to `outEnabled`; false, with why in `outRefusal`, for a plugin in no
	/// package the export can find (the project's, or the engine SDK `sdk`'s) and for one enabled
	/// on a platform it does not support, each named. What is enabled there is linked into the
	/// player the export builds, so nothing more is asked of it.
	public static bool Check(EditorProject project, StringView sdk, StringView platform, List<String> outEnabled, String outRefusal)
	{
		for (let entry in project.Settings.Plugins)
		{
			let manifest = scope PluginManifest();
			if (!FindManifest(project, sdk, entry, manifest))
			{
				if (entry.Path.IsEmpty)
					outRefusal.AppendF("plugin '{}' is in no package of the engine SDK's {}", entry.Id, ProjectBuild.cSdkPluginsDir);
				else
					outRefusal.AppendF("plugin '{}' has no manifest in the project's package '{}'", entry.Id, entry.Path);
				return false;
			}
			let enablement = entry.EnablementOn(manifest, platform);
			if (enablement == .NotEnabled)
				continue;
			if (enablement == .Unsupported)
			{
				outRefusal.AppendF("plugin '{}' is enabled on {}, which it does not support", entry.Id, platform);
				return false;
			}
			outEnabled.Add(new .(entry.Id));
		}
		return true;
	}

	/// The deploy files of the plugins `enabled` (by id) for `platform`, beside the player in
	/// `outDir`, from where each plugin's files are (PackageDir: the project's package or the
	/// engine SDK `sdk`'s). False (logged) when a deploy file a manifest lists is missing.
	public static bool StageDeployFiles(EditorProject project, StringView sdk, List<String> enabled, StringView platform,
		StringView outDir, ref int staged)
	{
		for (let entry in project.Settings.Plugins)
		{
			if (!enabled.Contains(entry.Id))
				continue;
			let dir = PackageDir(project, sdk, entry, .. scope .());
			let manifest = scope PluginManifest();
			if (dir.IsEmpty || (PluginManifest.Load(dir, manifest) case .Err))
				continue;
			let target = manifest.FindPlatform(platform);
			if (target == null)
				continue;
			for (let file in target.Deploy)
			{
				if (!FileCopy.CopyFile(dir, file, outDir, PathFilename(file, .. scope .())))
				{
					GlobalLog(.Error, "Export: plugin '{}': its deploy file '{}' for {} is missing", entry.Id, file, platform);
					return false;
				}
				staged++;
			}
		}
		return true;
	}
}
