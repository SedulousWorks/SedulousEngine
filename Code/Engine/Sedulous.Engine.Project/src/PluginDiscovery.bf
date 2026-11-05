using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;

namespace Sedulous.Engine.Project;

/// A plugin a project could enable and does not: a package in its Plugins folder that no entry
/// names, or a plugin the binary links that no entry enables. `Problem` says why one is not
/// offered (its manifest does not read or does not suit this engine, or its id is taken), empty
/// when it is.
class AvailablePlugin
{
	public String Id = new .() ~ delete _;
	/// The package's folder from the project ("Plugins/<Name>"); empty for a linked plugin.
	public String Path = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	public String Version = new .() ~ delete _;
	/// The part kinds its manifest lists.
	public List<String> Parts = new .() ~ DeleteContainerAndItems!(_);
	/// The platforms it supports.
	public List<String> Platforms = new .() ~ DeleteContainerAndItems!(_);
	public String Problem = new .() ~ delete _;

	public void Describe(PluginManifest manifest)
	{
		Id.Set(manifest.Id);
		Name.Set(manifest.Name);
		Version.Set(manifest.Version);
		for (let part in manifest.Parts)
			Parts.Add(new .(part.Kind));
		for (let platform in manifest.Platforms)
			Platforms.Add(new .(platform.Platform));
	}
}

/// What a project could enable, read off its Plugins folder and the plugins this binary links. It
/// enables nothing: enabling is an entry the project adds (plugin_enable, Project Settings).
static class PluginDiscovery
{
	/// The project's packages no entry names (by folder name), then the plugins in `linked` no
	/// entry enables (by id), appended.
	public static void Discover(StringView projectDir, ProjectSettings settings, Span<PluginPart> linked, List<AvailablePlugin> outFound)
	{
		// The linked plugins' manifests, once a plugin.
		let linkedManifests = scope List<PluginManifest>();
		defer { ClearAndDeleteItems!(linkedManifests); }
		for (let part in linked)
		{
			bool seen = false;
			for (let manifest in linkedManifests)
				seen |= manifest.Id == part.PluginId;
			if (seen)
				continue;
			let manifest = new PluginManifest();
			if (PluginManifest.Read(part.ManifestXml, manifest) case .Ok)
				linkedManifests.Add(manifest);
			else
				delete manifest;
		}
		linkedManifests.Sort(scope (a, b) => a.Id <=> b.Id);

		// The packages: each folder of Plugins/ holding a Plugin.xml, by name.
		let folders = scope List<String>();
		defer { ClearAndDeleteItems!(folders); }
		ListDirectory(PathJoin(projectDir, ProjectLayout.PluginsDir, .. scope .()), scope [&](name, isDirectory) =>
			{
				if (isDirectory)
					folders.Add(new .(name));
			});
		folders.Sort(scope (a, b) => a <=> b);
		for (let folder in folders)
		{
			let path = scope $"{ProjectLayout.PluginsDir}/{folder}";
			bool named = false;
			for (let entry in settings.Plugins)
				named |= entry.Path == path;
			let packageDir = PathJoin(projectDir, path, .. scope .());
			if (named || !FileExists(PathJoin(packageDir, PluginManifest.cFileName, .. scope .())))
				continue; // an entry's package, or a folder that is no package
			let plugin = new AvailablePlugin();
			plugin.Path.Set(path);
			outFound.Add(plugin);
			let manifest = scope PluginManifest();
			if (PluginManifest.Load(packageDir, manifest) case .Err)
			{
				plugin.Problem.AppendF("'{}': its Plugin.xml does not read", path);
				continue;
			}
			plugin.Describe(manifest);
			let whyNot = scope String();
			if (!manifest.Check(EngineVersion.String, whyNot))
			{
				plugin.Problem.Set(whyNot);
				continue;
			}
			if (let entry = settings.FindPlugin(manifest.Id))
			{
				if (entry.Path.IsEmpty)
					plugin.Problem.AppendF("plugin '{}' is already enabled, as the engine's", manifest.Id);
				else
					plugin.Problem.AppendF("plugin '{}' is already enabled from '{}'", manifest.Id, entry.Path);
				continue;
			}
			for (let other in linkedManifests)
			{
				if (other.Id == manifest.Id)
					plugin.Problem.AppendF("plugin '{}' is linked into this build", manifest.Id);
			}
			for (let earlier in outFound)
			{
				if (plugin.Problem.IsEmpty && (earlier !== plugin) && (earlier.Id == manifest.Id))
					plugin.Problem.AppendF("plugin '{}' is also in '{}'", manifest.Id, earlier.Path);
			}
		}

		// The plugins this binary links that no entry enables.
		for (let manifest in linkedManifests)
		{
			if (settings.FindPlugin(manifest.Id) != null)
				continue;
			let plugin = new AvailablePlugin();
			plugin.Describe(manifest);
			outFound.Add(plugin);
		}
	}
}
