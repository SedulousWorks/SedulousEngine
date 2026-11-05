using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// A plugin's Pipeline part: an importer and a creator through the service, and a builder the
/// host has no registry for.
class ImportingPart : PluginPart
{
	public static bool BuilderRefused = false;

	public override StringView PluginId => "importing";
	public override PluginPartKind Kind => .Pipeline;

	public override void Load(PluginContext context)
	{
		let services = context.Find<PipelinePluginServices>();
		if (services == null)
			return;
		services.AddImporter(new FakeImporter("Plugin"));
		services.AddCreator(new AssetCreator("Plugin Thing", "", typeof(FakeImporter), new (at) => null));
		BuilderRefused = !services.AddBuilder(null);
	}
}

/// The registries give a key to each entry and take that entry back out by it; and what a plugin's
/// Pipeline part adds through PipelinePluginServices leaves when the plugin unloads, the host's own
/// entries staying.
class PipelinePluginServicesTests
{
	[Test]
	public static void EachRegistryRemovesByTheKeyItGave()
	{
		let importers = scope ImporterRegistry();
		Test.Assert(importers.Register(null) == 0, "nothing added, no key");
		let first = importers.Register(new FakeImporter("First"));
		let second = importers.Register(new FakeImporter("Second"));
		Test.Assert((first != 0) && (second != 0) && (first != second));
		Test.Assert(importers.Unregister(first));
		Test.Assert(!importers.Unregister(first), "removed already");
		Test.Assert((importers.Count == 1) && (importers.FindFor("fak").Label == "Second"));

		let creators = scope AssetCreatorRegistry();
		let key = creators.Register(new AssetCreator("Thing", "", typeof(FakeImporter), new (at) => null));
		Test.Assert(key != 0);
		Test.Assert(creators.Unregister(key));
		Test.Assert(creators.Count == 0);

		let builders = scope BuilderRegistry();
		Test.Assert(builders.Register(null) == 0);
		Test.Assert(!builders.Unregister(1));
	}

	[Test]
	public static void APipelinePartsAdditionsLeaveWithThePluginTheHostsStay()
	{
		let importers = scope ImporterRegistry();
		importers.Register(new FakeImporter("Host"));
		let creators = scope AssetCreatorRegistry();
		let services = scope PipelinePluginServices(.(null, importers, creators));
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Mcp, "0.1.0");
		Test.Assert(services.Attach(host));

		let manifest = scope PluginManifest();
		manifest.Id.Set("importing");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Pipeline");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let importing = scope ImportingPart();
		Test.Assert(host.AddLinked(manifest.Write(.. scope .()), scope PluginPart[](importing)) case .Ok);
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("importing"), report);
		Test.Assert(report.Loaded.Count == 1);
		Test.Assert(importers.Count == 2);
		Test.Assert(creators.FindByLabel("Plugin Thing") != null);
		Test.Assert(ImportingPart.BuilderRefused, "no builder registry: nothing added");

		host.Unload();
		Test.Assert(importers.Count == 1);
		Test.Assert(importers.FindFor("fak").Label == "Host");
		Test.Assert(creators.Count == 0);
	}
}
