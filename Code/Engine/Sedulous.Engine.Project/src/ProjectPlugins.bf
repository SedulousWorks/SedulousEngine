using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;

namespace Sedulous.Engine.Project;

/// A project's plugins into a host: the one step every host (the player, the editor, the tools)
/// takes when it opens a project.
static class ProjectPlugins
{
	/// Enables the plugins `settings` enables into `host`, the process's plugin host for its role,
	/// after adding `parts`, the plugin parts this binary links (PluginRegistry.Parts in a host).
	/// What loaded is logged, and what did not, each with why; the report, appended to `outReport`,
	/// says the same. A plugin that does not load leaves its entry as it is.
	public static void Load(PluginHost host, Span<PluginPart> parts, ProjectSettings settings, PluginLoadReport outReport)
	{
		if (host.AddParts(parts) case .Err)
			GlobalLog(.Error, "Plugins: a plugin part linked into this build has a manifest that does not read");
		let report = scope PluginLoadReport();
		host.Load((Span<EnabledPlugin>)settings.Plugins, report);
		for (let id in report.Loaded)
			GlobalLog(.Information, "Plugins: plugin '{}' loaded ({})", id, host.Role);
		for (let refusal in report.Refused)
			GlobalLog(.Warning, "Plugins: {}; its entry and settings are kept", refusal.Reason);
		report.CopyTo(outReport);
	}

	/// The same over the parts this binary links.
	public static void Load(PluginHost host, ProjectSettings settings, PluginLoadReport outReport) =>
		Load(host, PluginRegistry.Parts, settings, outReport);
}
