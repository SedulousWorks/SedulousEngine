using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// A part of the four-part plugin: records its kind as it loads and unloads.
class FourPartsPart : PluginPart
{
	public static List<String> Log = new .() ~ DeleteContainerAndItems!(_);
	private PluginPartKind mKind;

	public this(PluginPartKind kind) { mKind = kind; }

	public override StringView PluginId => "four_parts";
	public override PluginPartKind Kind => mKind;
	public override StringView ManifestXml => ToolPluginsTests.sManifest;
	public override void Load(PluginContext context) => Log.Add(new $"load:{mKind}");
	public override void Unload(PluginContext context) => Log.Add(new $"unload:{mKind}");
}

/// A headless tool has no application: its plugins run over a subsystem manager of its own, and
/// each tool enables exactly the parts its role takes of the plugins the project enables,
/// unloading them when it goes.
class ToolPluginsTests
{
	public static String sManifest = new .() ~ delete _;

	private static void WriteManifest()
	{
		if (!sManifest.IsEmpty)
			return;
		let manifest = scope PluginManifest();
		manifest.Id.Set("four_parts");
		manifest.Name.Set("Four parts");
		manifest.Version.Set("1.0");
		manifest.EngineVersion.Set(EngineVersion.String);
		for (int i < PluginPartKind.Count)
		{
			let part = new PluginManifestPart();
			((PluginPartKind)i).ToString(part.Kind);
			manifest.Parts.Add(part);
		}
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		Test.Assert(manifest.Write(sManifest) case .Ok);
	}

	/// The kinds a tool of `role` enabled, comma separated, appended.
	private static String LoadsFor(HostRole role, EditorProject project, List<PluginPart> parts, String outKinds)
	{
		ClearAndDeleteItems!(FourPartsPart.Log);
		{
			let plugins = scope ToolPlugins(role, project, (Span<PluginPart>)parts);
			Test.Assert(plugins.Report.Loaded.Count == 1);
			Test.Assert(plugins.Host.IsLoaded("four_parts"));
			Test.Assert(plugins.Host.Role == role);
		}
		bool unloaded = false;
		for (let line in FourPartsPart.Log)
		{
			if (line.StartsWith("load:"))
			{
				if (!outKinds.IsEmpty)
					outKinds.Append(',');
				outKinds.Append(StringView(line, 5));
			}
			unloaded |= line.StartsWith("unload:");
		}
		Test.Assert(unloaded, "the tool's plugins went with it");
		return outKinds;
	}

	[Test]
	public static void TheCookTheExporterAndTheMcpHostEachEnableThePartsTheirRoleTakes()
	{
		WriteManifest();
		let dir = "scratch_project_tool_plugins";
		RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Tools") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer { delete project; RemoveDirectoryRecursive(dir); }
		let entry = new EnabledPlugin();
		entry.Id.Set("four_parts");
		project.Settings.Plugins.Add(entry);
		let parts = scope List<PluginPart>();
		defer { ClearAndDeleteItems!(parts); }
		for (int i < PluginPartKind.Count)
			parts.Add(new FourPartsPart((PluginPartKind)i));

		Test.Assert(LoadsFor(.Cook, project, parts, .. scope .()) == "Engine,Pipeline");
		Test.Assert(LoadsFor(.Export, project, parts, .. scope .()) == "Engine,Pipeline,Tooling");
		Test.Assert(LoadsFor(.Mcp, project, parts, .. scope .()) == "Engine,Pipeline,Tooling");

		// A plugin this tool does not link stays missing; the project keeps its entry.
		{
			let plugins = scope ToolPlugins(.Cook, project, .());
			Test.Assert(plugins.Report.FindRefusal("four_parts") != null);
			Test.Assert(project.Settings.FindPlugin("four_parts") != null);
		}
		ClearAndDeleteItems!(FourPartsPart.Log);
	}
}
