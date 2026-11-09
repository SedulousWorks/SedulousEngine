using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Runtime;
using Sedulous.Script;
using Sedulous.Script.Pipeline;

namespace Sedulous.Editor.Project;

/// What the project's plugins mean for an export: the refusals, the plugins' deploy files beside
/// the player, and the scripts that cannot run where a plugin is not enabled.
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

	/// The script types of the plugins `plugins` loaded that the project does not enable on
	/// `platform`, by full name (appended to `outHidden`, from the process's script surfaces), and
	/// their ids, quoted and comma separated (appended to `outNames`): what a script there cannot use.
	public static void AbsentPluginTypes(EditorProject project, PluginHost plugins, StringView platform, List<String> outHidden, String outNames)
	{
		for (let id in plugins.Loaded)
		{
			let entry = project.Settings.FindPlugin(id);
			let manifest = plugins.Manifest(id);
			if ((entry == null) || (manifest == null) || (entry.EnablementOn(manifest, platform) == .Enabled))
				continue;
			let names = scope List<String>();
			defer { ClearAndDeleteItems!(names); }
			for (let surface in ScriptSurfaces.All)
				surface.PluginTypes(id, names);
			for (let name in names)
			{
				bool listed = false;
				for (let have in outHidden)
					listed |= have == name;
				if (!listed)
					outHidden.Add(new .(name));
			}
			outNames.AppendF(outNames.IsEmpty ? "'{}'" : ", '{}'", id);
		}
	}

	/// Why `platform` cannot run the project's scripts, appended to `outWhy` (nothing when it can):
	/// the plugins `plugins` loaded that the project does not enable there are absent, so every
	/// script asset is checked against the surfaces without their types, and the first that fails
	/// is named with the plugins and its first problem. Nothing is checked when the platform has
	/// every plugin loaded (or there is no host).
	public static void CheckScriptsOn(EditorProject project, PluginHost plugins, StringView platform, String outWhy)
	{
		if (plugins == null)
			return;
		let hidden = scope List<String>();
		defer { ClearAndDeleteItems!(hidden); }
		let absent = scope String();
		AbsentPluginTypes(project, plugins, platform, hidden, absent);
		if (hidden.IsEmpty)
			return;
		let views = scope List<StringView>();
		for (let name in hidden)
			views.Add(name);
		let instances = scope List<Instance>();
		ExportStaging.CollectAllInstances(project.SourceDb.RootGroup, instances);
		let scriptType = typeof(ScriptClassAsset).GetFullName(.. scope .());
		let sources = project.SourcesRoot(.. scope .());
		for (let instance in instances)
		{
			if (instance.TypeName != scriptType)
				continue;
			let object = instance.ReadObject();
			defer delete object;
			let script = object as ScriptClassAsset;
			if (script == null)
				continue;
			let cook = ScriptLanguageCooks.Find(script.Language.IsEmpty ? "angelscript" : StringView(script.Language));
			let bytes = scope List<uint8>();
			if ((cook == null) || (ReadFile(PathJoin(sources, script.FileName.Value, .. scope .()), bytes) case .Err))
				continue; // the cook reports a script it cannot read or has no cook for
			let problems = scope List<String>();
			defer { ClearAndDeleteItems!(problems); }
			let className = scope String();
			let preferred = ScriptClasses.Preferred(script, .. scope .());
			if (cook.Check(StringView((char8*)bytes.Ptr, bytes.Count), script.FileName.Value, preferred, className, problems, (Span<StringView>)views))
				continue;
			outWhy.AppendF("script '{}' cannot run on {}, where plugin(s) {} are not enabled", script.FileName.Value, platform, absent);
			if (!problems.IsEmpty)
				outWhy.AppendF(": {}", problems[0]);
			return;
		}
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
