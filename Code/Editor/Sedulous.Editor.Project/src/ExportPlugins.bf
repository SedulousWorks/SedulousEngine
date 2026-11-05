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

/// Which player a preset's dist runs, and whether the project's plugins let the export go ahead.
class PlayerChoice
{
	/// The project's own player (ProjectBuild's), not the template's.
	public bool OwnPlayer = false;
	/// Which player and why, for the result and the log.
	public String Reason = new .() ~ delete _;
	/// Why the export cannot go ahead (empty when it can).
	public String Refusal = new .() ~ delete _;
	/// The plugins the project enables on the preset's platform.
	public List<String> Enabled = new .() ~ DeleteContainerAndItems!(_);
}

/// What the project's plugins mean for an export: the player it ships, the refusals, the plugins'
/// deploy files beside it, and the scripts that cannot run where a plugin is not enabled.
static class ExportPlugins
{
	/// The manifest of the plugin `entry` names: its project package's, else the copy the template
	/// carries (plugins/<id>/ in an imported one, the checkout's package for the host template).
	/// False when there is none.
	public static bool FindManifest(EditorProject project, ExportTemplate template, EnabledPlugin entry, PluginManifest outManifest)
	{
		let dir = PackageDir(project, template, entry, .. scope .());
		if (dir.IsEmpty)
			return false;
		return (PluginManifest.Load(dir, outManifest) case .Ok) && (outManifest.Id == entry.Id);
	}

	/// Where `entry`'s plugin's files are for an export with `template`: the project's package, the
	/// template's plugins/<id>/, or for the host template the checkout's package. Empty for none.
	public static void PackageDir(EditorProject project, ExportTemplate template, EnabledPlugin entry, String outDir)
	{
		outDir.Clear();
		if (!entry.Path.IsEmpty)
		{
			PathJoin(project.Directory, entry.Path, outDir);
			return;
		}
		if (template.IsHost)
		{
			ExportTemplates.FindPackage(template.PackagesRoot, entry.Id, outDir);
			return;
		}
		let carried = PathJoin(PathJoin(template.Directory, ExportTemplates.cPluginsDir, .. scope .()), entry.Id, .. scope .());
		if (DirectoryExists(carried))
			outDir.Set(carried);
	}

	/// The player for `platform`'s dist, or why there is none: the project's own when a package of
	/// its own is enabled there (a host platform's preset only: another platform's export takes a
	/// template, and no template carries a project's package); else the template's, when it carries
	/// every plugin enabled there at a version at least the one the plugin's manifest names. Refused
	/// for an entry enabled on a platform its plugin does not support, a plugin in no package the
	/// export can find, and a plugin the template lacks or carries older, each named.
	public static void ChoosePlayer(EditorProject project, ExportTemplate template, StringView platform, PlayerChoice outChoice)
	{
		for (let entry in project.Settings.Plugins)
		{
			let manifest = scope PluginManifest();
			if (!FindManifest(project, template, entry, manifest))
			{
				outChoice.Refusal.AppendF("plugin '{}' is in no package the export can find (the project's or the template's)", entry.Id);
				return;
			}
			let enablement = entry.EnablementOn(manifest, platform);
			if (enablement == .NotEnabled)
				continue;
			if (enablement == .Unsupported)
			{
				outChoice.Refusal.AppendF("plugin '{}' is enabled on {}, which it does not support", entry.Id, platform);
				return;
			}
			outChoice.Enabled.Add(new .(entry.Id));
			if (!entry.Path.IsEmpty)
			{
				if (platform != BuildLayout.HostPlatformName)
				{
					outChoice.Refusal.AppendF("the project's own package '{}' is enabled on {}, whose export takes a template, and a template carries no project package", entry.Id, platform);
					return;
				}
				if (!outChoice.OwnPlayer)
				{
					outChoice.OwnPlayer = true;
					outChoice.Reason.Set(scope $"the project's own package '{entry.Id}' is enabled on {platform}");
				}
				continue;
			}
			let carried = template.FindPlugin(entry.Id);
			if (carried == null)
			{
				outChoice.Refusal.AppendF("template '{}' does not carry plugin '{}' (make the template from a player that links it)", template.Id, entry.Id);
				return;
			}
			let have = PluginVersion.Parse(carried.Version);
			let want = PluginVersion.Parse(manifest.Version);
			if ((have case .Err) || (want case .Err) || !PluginVersion.AtLeast(have.Get(), want.Get()))
			{
				outChoice.Refusal.AppendF("template '{}' carries plugin '{}' {}, older than {}", template.Id, entry.Id, carried.Version, manifest.Version);
				return;
			}
		}
		if (!outChoice.OwnPlayer)
			outChoice.Reason.Set(scope $"template '{template.Id}' carries every plugin enabled on {platform}");
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
			if (cook.Check(StringView((char8*)bytes.Ptr, bytes.Count), script.FileName.Value, className, problems, (Span<StringView>)views))
				continue;
			outWhy.AppendF("script '{}' cannot run on {}, where plugin(s) {} are not enabled", script.FileName.Value, platform, absent);
			if (!problems.IsEmpty)
				outWhy.AppendF(": {}", problems[0]);
			return;
		}
	}

	/// The deploy files of the plugins `choice` enables for `platform`, beside the player in
	/// `outDir`, from where each plugin's files are (PackageDir). False (logged) when a deploy file a
	/// manifest lists is missing.
	public static bool StageDeployFiles(EditorProject project, ExportTemplate template, PlayerChoice choice, StringView platform,
		StringView outDir, ref int staged)
	{
		for (let entry in project.Settings.Plugins)
		{
			if (!choice.Enabled.Contains(entry.Id))
				continue;
			let dir = PackageDir(project, template, entry, .. scope .());
			let manifest = scope PluginManifest();
			if (dir.IsEmpty || (PluginManifest.Load(dir, manifest) case .Err))
				continue;
			let target = manifest.FindPlatform(platform);
			if (target == null)
				continue;
			for (let file in target.Deploy)
			{
				if (!ExportTemplates.CopyFile(dir, file, outDir, PathFilename(file, .. scope .())))
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
