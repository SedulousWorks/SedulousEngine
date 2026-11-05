using System;
using System.Collections;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// The fixture packages' manifests, as their parts compile them in.
static class ProbeManifests
{
	public const String cProbeBase = """
		<root>
			<array name="dataVersions" count="1">
				<u64 name="type">17008328439509122599</u64>
				<u32 name="version">1</u32>
			</array>
			<object>
				<string name="id">probe_base</string>
				<string name="name">Probe Base</string>
				<string name="version">0.1.0</string>
				<string name="engineVersion">0.1</string>
				<array name="dependsOn" count="0"/>
				<array name="provides" count="0"/>
				<array name="parts" count="1">
					<object>
						<string name="kind">Engine</string>
					</object>
				</array>
				<array name="platforms" count="3">
					<object>
						<string name="platform">Linux64</string>
						<array name="deploy" count="0"/>
					</object>
					<object>
						<string name="platform">Win64</string>
						<array name="deploy" count="0"/>
					</object>
					<object>
						<string name="platform">Web</string>
						<array name="deploy" count="0"/>
					</object>
				</array>
			</object>
		</root>
		""";

	public const String cProbe = """
		<root>
			<array name="dataVersions" count="1">
				<u64 name="type">17008328439509122599</u64>
				<u32 name="version">1</u32>
			</array>
			<object>
				<string name="id">probe</string>
				<string name="name">Probe</string>
				<string name="version">0.1.0</string>
				<string name="engineVersion">0.1</string>
				<array name="dependsOn" count="1">
					<object>
						<string name="id">probe_base</string>
						<string name="version">0.1</string>
					</object>
				</array>
				<array name="provides" count="0"/>
				<array name="parts" count="3">
					<object>
						<string name="kind">Engine</string>
					</object>
					<object>
						<string name="kind">Pipeline</string>
					</object>
					<object>
						<string name="kind">Editor</string>
					</object>
				</array>
				<array name="platforms" count="3">
					<object>
						<string name="platform">Linux64</string>
						<array name="deploy" count="0"/>
					</object>
					<object>
						<string name="platform">Win64</string>
						<array name="deploy" count="0"/>
					</object>
					<object>
						<string name="platform">Web</string>
						<array name="deploy" count="0"/>
					</object>
				</array>
			</object>
		</root>
		""";
}

/// A fixture part: registers itself, and counts its loads.
abstract class ProbePart : PluginPart
{
	public int Loads;

	public override void Load(PluginContext context) => Loads++;
	public override void Unload(PluginContext context) => Loads--;

	/// The registered part of `id` and `kind`, or null.
	public static ProbePart Of(StringView id, PluginPartKind kind)
	{
		for (let part in PluginRegistry.Parts)
		{
			if ((part.PluginId == id) && (part.Kind == kind))
				return part as ProbePart;
		}
		return null;
	}
}

[AlwaysInclude]
class ProbeBaseEnginePart : ProbePart
{
	static this() { PluginRegistry.Register(new ProbeBaseEnginePart()); }
	public override StringView PluginId => "probe_base";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => ProbeManifests.cProbeBase;
}

[AlwaysInclude]
class ProbeEnginePart : ProbePart
{
	static this() { PluginRegistry.Register(new ProbeEnginePart()); }
	public override StringView PluginId => "probe";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => ProbeManifests.cProbe;
}

[AlwaysInclude]
class ProbePipelinePart : ProbePart
{
	static this() { PluginRegistry.Register(new ProbePipelinePart()); }
	public override StringView PluginId => "probe";
	public override PluginPartKind Kind => .Pipeline;
	public override StringView ManifestXml => ProbeManifests.cProbe;
}

[AlwaysInclude]
class ProbeEditorPart : ProbePart
{
	static this() { PluginRegistry.Register(new ProbeEditorPart()); }
	public override StringView PluginId => "probe";
	public override PluginPartKind Kind => .Editor;
	public override StringView ManifestXml => ProbeManifests.cProbe;
}

/// The parts compiled into a binary register themselves: Runtime.Tests holds two fixture
/// packages, probe (Engine, Pipeline, Editor) and the probe_base it depends on. The host reads
/// their compiled-in manifests, sorts what registered, and enables the parts its role takes
/// through the parts themselves; a registered part does nothing until enabled.
class PluginRegistryTests
{
	private static int CountOf(StringView id)
	{
		int count = 0;
		for (let part in PluginRegistry.Parts)
		{
			if (part.PluginId == id)
				count++;
		}
		return count;
	}

	[Test]
	public static void EachPartCompiledInRegisteredItselfOnce()
	{
		Test.Assert(CountOf("probe_base") == 1);
		Test.Assert(CountOf("probe") == 3, "Engine, Pipeline and Editor");
		Test.Assert(ProbePart.Of("probe_base", .Engine) != null);
		Test.Assert(ProbePart.Of("probe", .Engine) != null);
		Test.Assert(ProbePart.Of("probe", .Pipeline) != null);
		Test.Assert(ProbePart.Of("probe", .Editor) != null);
		Test.Assert(ProbePart.Of("probe", .Tooling) == null);
		// Each part's compiled-in manifest is its own plugin's.
		for (let part in PluginRegistry.Parts)
		{
			let manifest = scope PluginManifest();
			Test.Assert(PluginManifest.Read(part.ManifestXml, manifest) case .Ok);
			Test.Assert(manifest.Id == part.PluginId);
			Test.Assert(manifest.HasPart(part.Kind));
		}
	}

	/// The plugins linked, once each however many parts they have, sorted by id with the version
	/// their manifest names: a player's --plugins.
	[Test]
	public static void TheLinkedListNamesEachPluginOnceWithItsVersionSorted()
	{
		let lines = PluginRegistry.Linked(.. scope .());
		let probe = scope PluginManifest();
		Test.Assert(PluginManifest.Read(ProbePart.Of("probe", .Engine).ManifestXml, probe) case .Ok);
		let probeBase = scope PluginManifest();
		Test.Assert(PluginManifest.Read(ProbePart.Of("probe_base", .Engine).ManifestXml, probeBase) case .Ok);
		let probeLine = scope $"probe|{probe.Version}\n";
		let baseLine = scope $"probe_base|{probeBase.Version}\n";
		Test.Assert(lines.Contains(probeLine) && lines.Contains(baseLine), lines);
		Test.Assert(lines.IndexOf(probeLine) < lines.IndexOf(baseLine), "sorted by id");
		Test.Assert(lines.IndexOf(probeLine, lines.IndexOf(probeLine) + 1) == -1, "once, for three parts");
		for (let line in lines.Split('\n', .RemoveEmptyEntries))
			Test.Assert(line.Contains('|'), scope String(line));
	}

	[Test]
	public static void TheHostReadsTheCompiledInManifestsAndEnablesTheRolesPartsThroughThem()
	{
		let probeBase = ProbePart.Of("probe_base", .Engine);
		let probeEngine = ProbePart.Of("probe", .Engine);
		let probePipeline = ProbePart.Of("probe", .Pipeline);
		let probeEditor = ProbePart.Of("probe", .Editor);
		let subsystems = scope SubsystemManager();
		{
			let host = scope PluginHost(subsystems, .Cook, "0.1.0");
			Test.Assert(host.AddRegistered() case .Ok);
			Test.Assert(host.Knows("probe") && host.Knows("probe_base"));
			Test.Assert(probeEngine.Loads == 0, "registered, not enabled: nothing ran");

			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("probe", "probe_base"), report);
			Test.Assert(report.Refused.IsEmpty);
			Test.Assert((report.Loaded.Count == 2) && (report.Loaded[0] == "probe_base"), "dependencies first");
			Test.Assert(probeBase.Loads == 1);
			Test.Assert(probeEngine.Loads == 1);
			Test.Assert(probePipeline.Loads == 1);
			Test.Assert(probeEditor.Loads == 0, "a cook does not take an Editor part");
		}
		Test.Assert(probeEngine.Loads == 0, "the host's destruction unloaded everything");
		Test.Assert(probePipeline.Loads == 0);
		Test.Assert(probeBase.Loads == 0);
	}

	/// What registered is sorted before anything is enabled: the parts' order in the registry
	/// (their static constructors') changes nothing.
	[Test]
	public static void TheRegistrationOrderChangesNothing()
	{
		let forward = scope List<PluginPart>();
		for (let part in PluginRegistry.Parts)
			forward.Add(part);
		let backward = scope List<PluginPart>();
		for (int i = forward.Count - 1; i >= 0; i--)
			backward.Add(forward[i]);

		let subsystems = scope SubsystemManager();
		let first = scope PluginHost(subsystems, .Editor, "0.1.0");
		Test.Assert(first.AddParts((Span<PluginPart>)forward) case .Ok);
		let firstReport = scope PluginLoadReport();
		first.Load(scope StringView[]("probe", "probe_base"), firstReport);
		first.Unload();
		let second = scope PluginHost(subsystems, .Editor, "0.1.0");
		Test.Assert(second.AddParts((Span<PluginPart>)backward) case .Ok);
		let secondReport = scope PluginLoadReport();
		second.Load(scope StringView[]("probe", "probe_base"), secondReport);
		second.Unload();
		Test.Assert(firstReport.Loaded.Count == secondReport.Loaded.Count);
		for (int i < firstReport.Loaded.Count)
			Test.Assert(firstReport.Loaded[i] == secondReport.Loaded[i]);
		Test.Assert(first.KnownIds(.. scope .()) == second.KnownIds(.. scope .()));
		Test.Assert(first.KnownIds(.. scope .()) == "probe,probe_base", "sorted by id");
	}

	/// A part with no manifest, or one that does not read, is a build defect: nothing of the set
	/// is added.
	[Test]
	public static void APartWithoutAReadableManifestAddsNothing()
	{
		let unreadable = scope UnreadablePart();
		let parts = scope List<PluginPart>();
		parts.Add(ProbePart.Of("probe_base", .Engine));
		parts.Add(unreadable);
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		Test.Assert(host.AddParts((Span<PluginPart>)parts) case .Err(.Internal));
		Test.Assert(!host.Knows("probe_base"));
	}
}

/// A part (not registered) whose manifest is not one.
class UnreadablePart : PluginPart
{
	public override StringView PluginId => "unreadable";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => "<root>no";
	public override void Load(PluginContext context) {}
}
